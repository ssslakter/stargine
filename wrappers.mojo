from sdl import *

fn acquire_swapchain_texture(command_buffer: Ptr[SDL_GPUCommandBuffer], window: Ptr[SDL_Window]) raises -> (Ptr[SDL_GPUTexture], UInt32, UInt32):
    """Blocks the thread until a swapchain texture is available to be acquired,
    and then acquires it.

    When a swapchain texture is acquired on a command buffer, it will
    automatically be submitted for presentation when the command buffer is
    submitted. The swapchain texture should only be referenced by the command
    buffer used to acquire it. It is an error to call
    SDL_CancelGPUCommandBuffer() after a swapchain texture is acquired.

    This function can fill the swapchain texture handle with NULL in certain
    cases, for example if the window is minimized. This is not an error. You
    should always make sure to check whether the pointer is NULL before
    actually using it.
    """
    var gpu_texture = Ptr[SDL_GPUTexture]()
    var width: UInt32 = 0
    var height: UInt32 = 0
    sdl_wait_and_acquire_gpu_swapchain_texture(command_buffer, window, Ptr(to=gpu_texture), Ptr(to=width), Ptr(to=height))
    return (gpu_texture, width, height)