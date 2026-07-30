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
            # TODO(upstream-sdl): destruction should not expose a fallible API.
            print("Failed to destroy OpenGL context:", err)


def init_opengl(mut window: Window) raises -> OpenGLContext:
    sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_PROFILE_MASK, Int32(Int(sdl.GLProfile.GL_CONTEXT_PROFILE_CORE)))
    sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_MAJOR_VERSION, 4)
    sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_MINOR_VERSION, 2)
    sdl.gl_set_attribute(sdl.GLAttr.GL_DOUBLEBUFFER, 1)

    context = sdl.gl_create_context(window._handle[])
    # TODO(upstream-sdl): expose GLContext ownership. The binding has
    # gl_destroy_context but provides no resource-owning context wrapper.
    # Keeping the current raw handle here would leak it on every application exit.

    sdl.gl_make_current(window._handle[], context)
    gl.init_opengl(load_gl_proc)
    var stored_create_shader = gl.func_table.get_or_create_ptr()[]["glCreateShader"]
    print("Stored glCreateShader:", stored_create_shader)
    var raw_stored_shader = UnsafePointer(to=stored_create_shader).bitcast[def() thin abi("C") -> None]()[]
    print("Reconstructed raw shader address:", UnsafePointer(to=raw_stored_shader).bitcast[UInt]()[])
    var reconstructed_create_shader = UnsafePointer(to=raw_stored_shader).bitcast[def(gl.ShaderType) thin abi("C") -> UInt32]()[]
    print("Reconstructed glCreateShader:", reconstructed_create_shader(gl.ShaderType.GL_VERTEX_SHADER))
    var raw_create_shader = load_gl_proc("glCreateShader")
    var create_shader = UnsafePointer(to=raw_create_shader).bitcast[def(gl.ShaderType) thin abi("C") -> UInt32]()[]
    print("Direct glCreateShader:", create_shader(gl.ShaderType.GL_VERTEX_SHADER))
    return OpenGLContext(context)


def load_gl_proc(name: String) raises -> def() thin abi("C") -> None:
    var mutable_name = name.copy()
    var proc = sdl.gl_get_proc_address(mutable_name)
    if name == "glCreateShader":
        print("glCreateShader loader address:", UnsafePointer(to=proc).bitcast[UInt]()[ ])
    return proc
