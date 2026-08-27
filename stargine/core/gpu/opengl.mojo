import opengl as gl
import sdl
from ..window import Window


def load_gl_proc(name: String) raises -> def () thin abi("C") -> None:
    return sdl.gl_get_proc_address(name.copy())


def report_gl_message(
    source: UInt32,
    type: UInt32,
    id: UInt32,
    severity: UInt32,
    length: Int32,
    message: Pointer[Int8, ImmutAnyOrigin],
    user_param: Pointer[NoneType, MutUntrackedOrigin],
) abi("C") -> None:
    if severity == UInt32(Int(gl.DebugSeverity.GL_DEBUG_SEVERITY_NOTIFICATION)):
        return
    var text = Span(unsafe_ptr=message.unsafe_bitcast[Byte](), length=Int(length))
    print("[gl]", String(unsafe_from_utf8=text))


struct OpenGLContext(Movable):
    """Owns the SDL OpenGL context.

    The context is current only while this value is alive, so it must outlive
    every GL call; keep it in the application state rather than a temporary.
    """

    var handle: sdl.GLContext

    def __init__(
        out self,
        window: Window,
        major: Int32 = 4,
        minor: Int32 = 5,
        debug: Bool = True,
    ) raises:
        sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_PROFILE_MASK, Int32(sdl.GLProfile.GL_CONTEXT_PROFILE_CORE))
        sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_MAJOR_VERSION, major)
        sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_MINOR_VERSION, minor)
        sdl.gl_set_attribute(sdl.GLAttr.GL_DOUBLEBUFFER, 1)
        if debug:
            sdl.gl_set_attribute(
                sdl.GLAttr.GL_CONTEXT_FLAGS, Int32(sdl.GLContextFlag.GL_CONTEXT_DEBUG_FLAG)
            )

        self.handle = sdl.gl_create_context(window.handle())
        sdl.gl_make_current(window.handle(), self.handle)
        gl.init_opengl(load_gl_proc)

        if debug:
            gl.enable(gl.EnableCap.GL_DEBUG_OUTPUT)
            gl.enable(gl.EnableCap.GL_DEBUG_OUTPUT_SYNCHRONOUS)
            var no_user_param: Optional[Pointer[NoneType, ImmutAnyOrigin]] = None
            gl.debug_message_callback(report_gl_message, no_user_param)
        # A no-op when the window has no sample buffers; `Window` asks for them.
        gl.enable(gl.EnableCap.GL_MULTISAMPLE)
        # Textures are uploaded as sRGB, so the driver converts back on write.
        gl.enable(gl.EnableCap.GL_FRAMEBUFFER_SRGB)

    def __deinit__(deinit self):
        try:
            sdl.gl_destroy_context(self.handle)
        except err:
            print("Failed to destroy OpenGL context:", err)
