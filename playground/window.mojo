from sdl import Ptr
import sdl.sdl_video as video


struct Window:
    var _handle: Ptr[video.Window]

    fn __init__(out self, window_title: String, width: Int32, height: Int32, window_flags: video.WindowFlags) raises:
        self._handle = video.create_window(window_title, width, height, window_flags)

    fn __moveinit__(out self, owned other: Self):
        self._handle = other._handle

    fn __del__(owned self):
        print("releasing window")
        video.destroy_window(self._handle)
