from ..window import Window
import sdl
import opengl as gl

fn init_opengl(mut window: Window) raises:
    sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_PROFILE_MASK, Int(sdl.GLProfile.GL_CONTEXT_PROFILE_CORE))
    sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_MAJOR_VERSION, 4)
    sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_MINOR_VERSION, 2)
    sdl.gl_set_attribute(sdl.GLAttr.GL_DOUBLEBUFFER, 1)

    context = sdl.gl_create_context(window._handle[])
    if not context:
        raise Error("Failed to create OpenGL context. Unsupported OpenGL version.")

    sdl.gl_make_current(window._handle[], context)
    gl.init_opengl(sdl.gl_get_proc_address)
