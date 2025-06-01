from sdl import Ptr
import sdl.video as video

struct Window:
    var window: Ptr[video.SDL_Window]

    fn __init__(out self: Self, window_title: String, width: Int32, height: Int32, window_flags: video.SDL_WindowFlags) raises:
        self.window = video.sdl_create_window(window_title, width, height, window_flags)

    fn __moveinit__(out self, owned other: Self):
        self.window = other.window

    fn __del__(owned self):
        video.sdl_destroy_window(self.window)