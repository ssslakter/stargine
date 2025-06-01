import time
from playground import *


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
    
    sdl_quit()
    # time.sleep(10.0)
