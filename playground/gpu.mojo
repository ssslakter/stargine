from sdl import Ptr
import sdl.gpu as gpu

struct GPUDevice:
    var device: Ptr[gpu.SDL_GPUDevice]

    fn __init__(out self: Self, format_flags: gpu.SDL_GPUShaderFormat, debug_mode: Bool, name: String) raises:
        self.device = gpu.sdl_create_gpu_device(format_flags, debug_mode, name)

    fn __moveinit__(out self, owned other: Self):
        self.device = other.device

    fn __del__(owned self):
        gpu.sdl_destroy_gpu_device(self.device)