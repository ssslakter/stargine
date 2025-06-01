from sdl import Ptr
import sdl.video as video
import sdl.gpu as gpu

struct GPUContext:
    '''Claims a window for a GPU device.
    '''

    var window: Window
    var device: GPUDevice

    fn __init__(
        out self,
        owned window: Window,
        owned device: GPUDevice,
    ) raises:
        self.window = window^
        self.device = device^
        gpu.sdl_claim_window_for_gpu_device(self.device.device, self.window.window)

    fn __del__(owned self):
        gpu.sdl_release_window_from_gpu_device(self.device.device, self.window.window)
