import opengl as gl
import sdl
from ..window import Window


def load_gl_proc(name: String) raises -> def () thin abi("C") -> None:
    return sdl.gl_get_proc_address(name.copy())


struct OpenGLContext(Movable):
    """Owns the SDL OpenGL context.

    The context is current only while this value is alive, so it must outlive
    every GL call; keep it in the application state rather than a temporary.
    """

    var handle: sdl.GLContext

    def __init__(out self, window: Window, major: Int32 = 4, minor: Int32 = 2) raises:
        sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_PROFILE_MASK, Int32(sdl.GLProfile.GL_CONTEXT_PROFILE_CORE))
        sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_MAJOR_VERSION, major)
        sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_MINOR_VERSION, minor)
        sdl.gl_set_attribute(sdl.GLAttr.GL_DOUBLEBUFFER, 1)

        self.handle = sdl.gl_create_context(window.handle())
        sdl.gl_make_current(window.handle(), self.handle)
        gl.init_opengl(load_gl_proc)

    def __deinit__(deinit self):
        try:
            sdl.gl_destroy_context(self.handle)
        except err:
            print("Failed to destroy OpenGL context:", err)
