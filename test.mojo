from sdl import *
from memory import UnsafePointer
from sys.info import sizeof
from time import sleep

alias GRID_WIDTH = 300
alias GRID_HEIGHT = 300

@always_inline
fn to_rgba8888(rgba: SIMD[DType.uint8, 4]) -> UInt32:
    var res =  UInt32(rgba[3]) | UInt32(rgba[2]) << 8 | UInt32(rgba[1]) << 16 | UInt32(rgba[0]) << 24
    # print('COLOR ', res)
    return res

fn gradient_black_to_white_rgba32(steps: UInt32) -> List[SIMD[DType.uint8, 4]]:
    var pixels = List[SIMD[DType.uint8, 4]]()
    for i in range(steps):
        var intensity = UInt32(255 * i / (steps - 1))  # 0..255 grayscale
        var rgba = SIMD[DType.uint8, 4](UInt8(intensity), UInt8(intensity), UInt8(intensity), 20)
        pixels.append(rgba)
    return pixels

def main():
    sdl_init(SDL_InitFlags.SDL_INIT_VIDEO | SDL_InitFlags.SDL_INIT_EVENTS)
    var window = sdl_create_window(
        "Mandelbrot Set Visualization", GRID_WIDTH, GRID_HEIGHT, 
        SDL_WindowFlags.SDL_WINDOW_RESIZABLE)
    
    print(sdl_get_window_flags(window).value)

    # var renderer = sdl_create_renderer(window, 'vulkan')
    # var pixels = gradient_black_to_white_rgba32(GRID_WIDTH * GRID_HEIGHT)
    # var running = True
    # var texture = sdl_create_texture(
    #     renderer, SDL_PixelFormat(SDL_PixelFormat.SDL_PIXELFORMAT_RGBA32), SDL_TextureAccess(SDL_TextureAccess.SDL_TEXTUREACCESS_STREAMING), GRID_WIDTH, GRID_HEIGHT
    # )
    # sdl_update_texture(texture, Ptr[SDL_Rect](), pixels.unsafe_ptr().bitcast[NoneType]().origin_cast[mut=False](), GRID_WIDTH * sizeof[UInt32]())

    # while running:
    #     # Handle events
    #     var event = SDL_Event(UInt32(0))
    #     while sdl_poll_event(Ptr(to=event)):
    #         if event[SDL_CommonEvent].type == SDL_EventType.SDL_EVENT_QUIT:
    #             running = False
    #         var arr_len = Int32(0)
    #         var keyboard_state = sdl_get_keyboard_state(Ptr(to=arr_len))
    #         for i in range(arr_len):
    #             if keyboard_state[i]:
    #                 print(keyboard_state[i])
    #     # sleep(Float64(1))
    #     sdl_render_clear(renderer)
    #     sdl_render_texture(renderer, texture, Ptr[SDL_FRect](), Ptr[SDL_FRect]())
    #     sdl_render_present(renderer)

    # sdl_destroy_texture(texture)
    # sdl_destroy_renderer(renderer)
    sdl_destroy_window(window)

    sdl_quit()
