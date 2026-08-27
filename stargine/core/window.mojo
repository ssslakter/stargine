import opengl as gl
import sdl
import sdl.sdl_video as video
from std.memory import ArcPointer
from .utils import Ptr

comptime WindowHandle = Ptr[video.Window, MutUntrackedOrigin]


struct _WindowInner(Movable):
    """Owns the SDL window and destroys it exactly once."""

    var handle: WindowHandle

    def __init__(
        out self,
        var title: String,
        width: Int32,
        height: Int32,
        flags: video.WindowFlags,
        depth_bits: Int32,
        stencil_bits: Int32,
        samples: Int32,
    ) raises:
        # SDL reads these when it picks the window's pixel format, so they have
        # to be set before the window exists, not before the context.
        sdl.gl_set_attribute(sdl.GLAttr.GL_DEPTH_SIZE, depth_bits)
        sdl.gl_set_attribute(sdl.GLAttr.GL_STENCIL_SIZE, stencil_bits)
        sdl.gl_set_attribute(sdl.GLAttr.GL_MULTISAMPLEBUFFERS, Int32(1) if samples > 1 else Int32(0))
        sdl.gl_set_attribute(sdl.GLAttr.GL_MULTISAMPLESAMPLES, samples if samples > 1 else Int32(0))
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

    def __init__(
        out self,
        var title: String,
        width: Int32,
        height: Int32,
        flags: video.WindowFlags,
        depth_bits: Int32 = 24,
        stencil_bits: Int32 = 8,
        samples: Int32 = 4,
    ) raises:
        self.fullscreen = False
        self.width = width
        self.height = height
        self._inner = ArcPointer(
            _WindowInner(title^, width, height, flags, depth_bits, stencil_bits, samples)
        )

    def handle(self) -> WindowHandle:
        return self._inner[].handle

    def swap(self) raises:
        sdl.gl_swap_window(self.handle())

    def toggle_fullscreen(mut self) raises:
        video.set_window_fullscreen(self.handle(), not self.fullscreen)
        if self.fullscreen:
            gl.viewport(0, 0, self.width, self.height)
        self.fullscreen = not self.fullscreen
