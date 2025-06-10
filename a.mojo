from sdl import *
from sys.ffi import OpaquePointer # For Ptr if not in sdl
from sys import exit
from memory import UnsafePointer # May be needed for Ptr definition or similar constructs
from sys.info import sizeof # For potential size calculations if needed

# Constants from the C example
alias WINDOW_WIDTH = 800
alias WINDOW_HEIGHT = 600


alias Ptr = UnsafePointer 

fn main() raises:
    alias WINDOW_WIDTH = 1920
    alias WINDOW_HEIGHT = 1080

    sdl_init(SDL_InitFlags.SDL_INIT_VIDEO | SDL_InitFlags.SDL_INIT_EVENTS)
    var window = Ptr[SDL_Window]()
    var renderer = Ptr[SDL_Renderer]()
    sdl_create_window_and_renderer(
        "Mandelbrot Set Visualization", WINDOW_WIDTH, WINDOW_HEIGHT, SDL_WindowFlags.SDL_WINDOW_RESIZABLE, Ptr(to=window), Ptr(to=renderer)
    )

    var gpu = sdl_create_gpu_device(SDL_GPUShaderFormat.SDL_GPU_SHADERFORMAT_SPIRV, True, "GPU Device")
    if not gpu:
        print("SDL_CreateGPUDevice Error")
        sdl_destroy_window(window)
        sdl_quit()
        exit(1) 

    sdl_claim_window_for_gpu_device(gpu, window)

    var running = True
    while running:
        var event = SDL_Event(UInt32(0))
        while sdl_poll_event(Ptr(to=event)):
            if event[SDL_CommonEvent].type == SDL_EventType.SDL_EVENT_QUIT:
                running = False
                break # Exit event polling loop
        
        if not running: # If quit event was processed
            break

        # 4. Acquire a command buffer
        var cmd = sdl_acquire_gpu_command_buffer(gpu)
        if not cmd:
            print("SDL_AcquireGPUCommandBuffer Error")
            running = False
            continue

        var swap_tex = Ptr[SDL_GPUTexture]()
        var swap_tex_width = UInt32(0)
        var swap_tex_height = UInt32(0)
        sdl_wait_and_acquire_gpu_swapchain_texture(cmd, window, Ptr(to=swap_tex), Ptr(to=swap_tex_width), Ptr(to=swap_tex_height))
        if not swap_tex:
            print("SDL_WaitAndAcquireGPUSwapchainTexture Error")
            running = False
            continue
            
        #    The C example: SDL_BeginGPURenderPass(cmd, swapTex, &(SDL_Color){255, 255, 255, 255});
        #    This implies a version of BeginGPURenderPass taking SDL_Color* for clear.
        #    Assuming SDL_Color is a struct {r, g, b, a: UInt8}
        var clear_color = SDL_Color(r=255, g=255, b=255, a=255)
        
        # Passing Ptr(to=clear_color)
        sdl_begin_gpu_render_pass(cmd, swap_tex, Ptr[SDL_Color](UnsafePointer.address_of(clear_color)))

        # 6. End the pass immediately (no draw calls)
        sdl_end_gpu_render_pass(cmd)

        # 7. Submit the commands to the GPU
        # The C example: SDL_SubmitGPUCommandBuffer(cmd);
        # Assuming this binding exists.
        sdl_submit_gpucommand_buffer(cmd)

        # 8. Present the cleared frame
        # The C example: SDL_PresentWindow(window);
        # This is SDL2 style. If this is the exact function from the C example's SDL3 context,
        # then `sdl_present_window(window)` is the translation.
        sdl_present_window(window)

    # 9. Clean up
    sdl_destroy_gpu_device(gpu)
    sdl_destroy_window(window)
    sdl_quit()
    # Mojo main function implicitly returns/exits successfully if no error is raised.
