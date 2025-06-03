import time
from playground import *


alias Vec3 = SIMD[DType.float32, 3]
alias Vec4 = SIMD[DType.float32, 4]

@value
struct Vertex:
    var position: Vec3
    var color: Vec4


alias vertices = [
    Vertex(position=Vec3(0.0, 0.5, 0.0), color=Vec4(1.0, 0.0, 0.0, 1.0)),
    Vertex(position=Vec3(0.5, -0.5, 0.0), color=Vec4(0.0, 1.0, 0.0, 1.0)),
    Vertex(position=Vec3(-0.5, -0.5, 0.0), color=Vec4(0.0, 0.0, 1.0, 1.0)),
]

fn app_iterate(context: GPUContext) raises:
    cmd = CommandBuffer.acquire(context.device)

    var swapchain_texture = cmd.wait_and_acquire_gpu_swapchain_texture(context.window)
    if not swapchain_texture:
        cmd^.submit()
        return
    
    var color_target_info = GPUColorTargetInfo(
        texture=swapchain_texture.value(),
        clear_color=SDL_FColor(r=0.8, g=0.4, b=0.5, a=1.0),
        load_op=SDL_GPULoadOp(SDL_GPULoadOp.SDL_GPU_LOADOP_CLEAR),
        store_op=SDL_GPUStoreOp(SDL_GPUStoreOp.SDL_GPU_STOREOP_STORE),
    )

    var render_pass = GPURenderPass.begin(cmd, color_target_info, 1)
    render_pass.end()
    
    cmd^.submit()



def main():
    sdl_init(SDL_InitFlags.SDL_INIT_VIDEO | SDL_InitFlags.SDL_INIT_EVENTS)
    window = Window("SDL Window", 1024, 768, SDL_WindowFlags.SDL_WINDOW_RESIZABLE)
    device = GPUDevice(SDL_GPUShaderFormat.SDL_GPU_SHADERFORMAT_SPIRV, True, 'vulkan')
    context = GPUContext(window^, device^)
    
    var running = True
    while running:
        var event = SDL_Event(UInt32(0))
        while sdl_poll_event(Ptr(to=event)):
            if event[SDL_CommonEvent].type == SDL_EventType.SDL_EVENT_QUIT:
                running = False
                break # Exit event polling loop
        
        if not running: # If quit event was processed
            break
        app_iterate(context)
    sdl_quit()
    # time.sleep(10.0)
