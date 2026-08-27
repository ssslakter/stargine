import opengl as gl
import sdl
import sdl.sdl_video as video
from std.memory import ArcPointer
from .utils import Ptr

comptime WindowHandle = Ptr[video.Window, MutUntrackedOrigin]


struct _WindowInner(Movable):
    """Owns the SDL window and destroys it exactly once."""

    var handle: WindowHandle

    def __init__(out self, var title: String, width: Int32, height: Int32, flags: video.WindowFlags) raises:
        self.handle = video.create_window(title^, width, height, flags)

    def __deinit__(deinit self):
        try:
            video.destroy_window(self.handle)
        except err:
            print("Failed to destroy SDL window:", err)


struct Window(Copyable, Movable):
    var fullscreen: Bool
    var width: Int32
    var height: Int32
    var _inner: ArcPointer[_WindowInner]

    def __init__(out self, var title: String, width: Int32, height: Int32, flags: video.WindowFlags) raises:
        self.fullscreen = False
        self.width = width
        self.height = height
        self._inner = ArcPointer(_WindowInner(title^, width, height, flags))

    def handle(self) -> WindowHandle:
        return self._inner[].handle

    def swap(self) raises:
        sdl.gl_swap_window(self.handle())

    def toggle_fullscreen(mut self) raises:
        video.set_window_fullscreen(self.handle(), not self.fullscreen)
        if self.fullscreen:
            gl.viewport(0, 0, self.width, self.height)
        self.fullscreen = not self.fullscreen
