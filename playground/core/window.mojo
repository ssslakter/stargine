from .imports import *
import sdl.sdl_video as video


struct Window(Movable):
    var fullscreen: Bool
    var width: Int32
    var height: Int32
    var _handle: Ptr[video.Window]

    fn __init__(out self, window_title: String, width: Int32, height: Int32, window_flags: video.WindowFlags) raises:
        self.fullscreen = False
        self.width = width
        self.height = height
        self._handle = video.create_window(window_title, width, height, window_flags)

    fn __del__(owned self):
        print("releasing window")
        video.destroy_window(self._handle)

    fn swap(self) raises:
        sdl.gl_swap_window(self._handle)

    fn toggle_fullscreen(mut self) raises:
        if self.fullscreen:
            video.set_window_fullscreen(self._handle, False)
            gl.viewport(0, 0, self.width, self.height)
        else:
            video.set_window_fullscreen(self._handle, True)
        self.fullscreen = not self.fullscreen