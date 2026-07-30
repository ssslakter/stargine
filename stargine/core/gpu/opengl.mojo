from ..window import Window
import sdl
import opengl as gl

struct OpenGLContext(Movable):
    var handle: sdl.GLContext

    def __init__(out self, handle: sdl.GLContext):
        self.handle = handle

    def __del__(deinit self):
        try:
            sdl.gl_destroy_context(self.handle)
        except err:
            print("Failed to destroy OpenGL context:", err)


def init_opengl(mut window: Window) raises -> OpenGLContext:
    sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_PROFILE_MASK, Int32(Int(sdl.GLProfile.GL_CONTEXT_PROFILE_CORE)))
    sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_MAJOR_VERSION, 4)
    sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_MINOR_VERSION, 2)
    sdl.gl_set_attribute(sdl.GLAttr.GL_DOUBLEBUFFER, 1)

    context = sdl.gl_create_context(window._handle[])

    sdl.gl_make_current(window._handle[], context)
    gl.init_opengl(load_gl_proc)
    return OpenGLContext(context)


def load_gl_proc(name: String) raises -> def() thin abi("C") -> None:
    var mutable_name = name.copy()
    return sdl.gl_get_proc_address(mutable_name)
