from sdl import *
from sys.ffi import OpaquePointer
from sys.info import sizeof
from math import ceildiv, log
from gpu import global_idx
from gpu.host import DeviceContext, DeviceBuffer
from layout import Layout, LayoutTensor
from complex import ComplexSIMD
from memory import UnsafePointer

alias GRID_WIDTH = 1920
alias GRID_HEIGHT = 1080

alias float_dtype = DType.float64
alias uint_dtype = DType.uint32

alias MIN_X: Scalar[float_dtype] = -2.0
alias MAX_X: Scalar[float_dtype] = 1
alias MIN_Y: Scalar[float_dtype] = -1.5
alias MAX_Y: Scalar[float_dtype] = 1.5

alias MAX_ITERATIONS: Scalar[uint_dtype] = 200

alias layout = Layout.row_major(GRID_HEIGHT, GRID_WIDTH)

fn mandelbrot(
    tensor: LayoutTensor[uint_dtype, layout, MutableAnyOrigin],
    max_x: Scalar[float_dtype],
    min_x: Scalar[float_dtype],
    max_y: Scalar[float_dtype],
    min_y: Scalar[float_dtype],
    max_iter: Scalar[uint_dtype],
):
    """The per-element calculation of iterations to escape in the Mandelbrot set.
    """
    # Obtain the position in the grid from the X, Y thread locations.
    var row = global_idx.y
    var col = global_idx.x

    var SCALE_X = (max_x - min_x) / GRID_WIDTH
    var SCALE_Y = (max_y - min_y) / GRID_HEIGHT

    # Calculate the complex C corresponding to that grid location.
    var cx = min_x + col * SCALE_X
    var cy = min_y + row * SCALE_Y
    var c = ComplexSIMD[float_dtype, 1](cx, cy)

    # Perform the Mandelbrot iteration loop calculation.
    var z = ComplexSIMD[float_dtype, 1](0, 0)
    var iters = Scalar[uint_dtype](0)

    var in_set_mask: Scalar[DType.bool] = True
    for _ in range(max_iter):
        if not any(in_set_mask):
            break
        in_set_mask = z.squared_norm() <= 4
        iters = in_set_mask.select(iters + 1, iters)
        z = z.squared_add(c)

    # Write out the resulting iterations to escape.
    tensor[row, col] = to_rgba8888(map_to_color(iters))

@always_inline
fn map_to_color(iter_count: Scalar[uint_dtype]) -> SIMD[DType.uint8, 4]:
    if iter_count == MAX_ITERATIONS:
        return SIMD[DType.uint8, 4](UInt8(0), UInt8(0), UInt8(0), 255)
   
    var log_scaled = log(Float64(iter_count + 1)) / log(Float64(MAX_ITERATIONS))
    var blue_intensity = UInt8(255 * log_scaled)
    return SIMD[DType.uint8, 4](0, 0, blue_intensity, 255)

@always_inline
fn to_rgba8888(rgba: SIMD[DType.uint8, 4]) -> UInt32:
    var res =  UInt32(rgba[3]) | UInt32(rgba[2]) << 8 | UInt32(rgba[1]) << 16 | UInt32(rgba[0]) << 24
    return res

fn gradient_black_to_white_rgba32(steps: UInt32) -> List[UInt32]:
    var pixels = List[UInt32]()
    for i in range(steps):
        var intensity = UInt32(255 * i / (steps - 1))  # 0..255 grayscale
        var rgba = SIMD[DType.uint8, 4](UInt8(intensity), UInt8(intensity), UInt8(intensity), 255)
        pixels.append(to_rgba8888(rgba))
    return pixels

def generate_mandelbrot_set(
    ref dev_buf: DeviceBuffer[uint_dtype],
    ref ctx: DeviceContext,
    zoom: Scalar[float_dtype],
    centerX: Scalar[float_dtype],
    centerY: Scalar[float_dtype],
):
    # Allocate a tensor on the target device to hold the resulting set.
    var out_tensor = LayoutTensor[uint_dtype, layout](dev_buf)

    # Compute how many blocks are needed in each dimension to fully cover the grid,
    # rounding up to ensure even partially filled blocks are launched.
    alias BLOCK_SIZE = 32
    alias COL_BLOCKS = ceildiv(GRID_WIDTH, BLOCK_SIZE)
    alias ROW_BLOCKS = ceildiv(GRID_HEIGHT, BLOCK_SIZE)

    var min_x = MIN_X / zoom + centerX
    var max_x = MAX_X / zoom + centerX
    var min_y = MIN_Y / zoom + centerY
    var max_y = MAX_Y / zoom + centerY

    var max_iter = UInt32(min(Float64(MAX_ITERATIONS) * zoom, 1000))

    # Launch the Mandelbrot kernel on the GPU with a 2D grid of thread blocks.
    ctx.enqueue_function[mandelbrot](
        out_tensor,
        max_x, min_x, max_y, min_y, max_iter,
        grid_dim=(COL_BLOCKS, ROW_BLOCKS),
        block_dim=(BLOCK_SIZE, BLOCK_SIZE),
    )
    ctx.synchronize()



def main():
    print("Press + or - to zoom in and out")

    alias WINDOW_WIDTH = 1920
    alias WINDOW_HEIGHT = 1080

    sdl_init(SDL_InitFlags.SDL_INIT_VIDEO | SDL_InitFlags.SDL_INIT_EVENTS)
    var window = Ptr[SDL_Window]()
    var renderer = Ptr[SDL_Renderer]()
    sdl_create_window_and_renderer(
        "Mandelbrot Set Visualization", WINDOW_WIDTH, WINDOW_HEIGHT, SDL_WindowFlags.SDL_WINDOW_RESIZABLE, Ptr(to=window), Ptr(to=renderer)
    )

    # Get the context for the attached GPU
    var ctx = DeviceContext()
    var dev_buf = ctx.enqueue_create_buffer[uint_dtype](layout.size())

    var running = True
    var zoom: Scalar[float_dtype] = 1.0
    var centerX: Scalar[float_dtype] = 0.0
    var centerY: Scalar[float_dtype] = 0.0

    var texture = sdl_create_texture(
                renderer,
                SDL_PixelFormat(SDL_PixelFormat.SDL_PIXELFORMAT_RGBA8888),
                SDL_TextureAccess(SDL_TextureAccess.SDL_TEXTUREACCESS_STREAMING),
                GRID_WIDTH, GRID_HEIGHT)

    while running:
        # Handle events
        var event = SDL_Event(UInt32(0))
        var needs_redraw = False # Flag to check if redraw is needed
        while sdl_poll_event(Ptr(to=event)):
            if event[SDL_CommonEvent].type == SDL_EventType.SDL_EVENT_QUIT:
                running = False
                break # Exit event polling loop
        
        if not running: # Check if quit event was processed
            break

        # Check keyboard state after processing all events for the frame
        var state_len = Int32(0)
        var keyboard_state = sdl_get_keyboard_state(Ptr(to=state_len))

        if keyboard_state[SDL_Scancode.SDL_SCANCODE_KP_PLUS]:
            needs_redraw = True
            zoom *= 1.01
        elif keyboard_state[SDL_Scancode.SDL_SCANCODE_KP_MINUS]:
            needs_redraw = True
            zoom /= 1.01
        elif keyboard_state[SDL_Scancode.SDL_SCANCODE_LEFT]:
            needs_redraw = True
            centerX -= 0.01 / zoom
        elif keyboard_state[SDL_Scancode.SDL_SCANCODE_RIGHT]:
            needs_redraw = True
            centerX += 0.01 / zoom
        elif keyboard_state[SDL_Scancode.SDL_SCANCODE_UP]:
            needs_redraw = True
            centerY -= 0.01 / zoom
        elif keyboard_state[SDL_Scancode.SDL_SCANCODE_DOWN]:
            needs_redraw = True
            centerY += 0.01 / zoom
        
        # Generate Mandelbrot set only if an update occurred
        if needs_redraw:
            generate_mandelbrot_set(dev_buf, ctx, zoom, centerX, centerY)

        with dev_buf.map_to_host() as host_buf:
            var host_tensor = LayoutTensor[uint_dtype, layout](host_buf)
            sdl_update_texture(texture, UnsafePointer[SDL_Rect](), host_tensor.ptr.bitcast[NoneType]().origin_cast[mut=False](), GRID_WIDTH * sizeof[UInt32]())

        sdl_render_clear(renderer)
        sdl_render_texture(renderer, texture, UnsafePointer[SDL_FRect](), UnsafePointer[SDL_FRect]())
        sdl_render_present(renderer)

    sdl_destroy_texture(texture)

    sdl_quit()
