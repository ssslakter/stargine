import time
from sys import sizeof
from sdl import InitFlags, WindowFlags, Event, CommonEvent, EventType
from playground import *
from opengl import *


alias Vec3 = Tuple[Float32, Float32, Float32]
alias Vec4 = Tuple[Float32, Float32, Float32, Float32]


alias win_width = 1024
alias win_height = 768


@fieldwise_init
struct Vertex(Writable, Copyable & Movable):
    var position: Vec3
    var color: Vec4

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(
            "Vertex(position=(",
            self.position[0],
            ", ",
            self.position[1],
            ", ",
            self.position[2],
            ")",
        )
        writer.write(
            ", color=(",
            self.color[0],
            ", ",
            self.color[1],
            ", ",
            self.color[2],
            ", ",
            self.color[3],
            "))",
        )


alias vertices = List[Vertex](
    Vertex(position=Vec3(0.0, 0.5, 0.0), color=Vec4(1.0, 0.0, 0.0, 1.0)),
    Vertex(position=Vec3(0.5, -0.5, 0.0), color=Vec4(0.0, 1.0, 0.0, 1.0)),
    Vertex(position=Vec3(-0.5, -0.5, 0.0), color=Vec4(0.0, 0.0, 1.0, 1.0)),
)


fn app_init(window: Window, gl: opengl.GL) raises:
    gl.viewport(0, 0, win_width-100, win_height-100)


fn app_iterate(window: Window, gl: opengl.GL) raises:
    gl.clearColor(0.1, 0.2, 0.5, 1.0)
    gl.clear(ClearBufferMask.COLOR_BUFFER_BIT)
    sdl.gl_swap_window(window._handle)


def main_loop(window: Window, gl: opengl.GL):
    var running = True
    while running:
        var event = Event(UInt32(0))
        while sdl.poll_event(Ptr(to=event)):
            if event[CommonEvent].type == Int(EventType.EVENT_QUIT):
                running = False
                break  # Exit event polling loop

        if not running:  # If quit event was processed
            break
        app_iterate(window, gl)


def main():
    sdl.init(InitFlags.INIT_VIDEO | InitFlags.INIT_EVENTS)

    sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_PROFILE_MASK, Int(sdl.GLProfile.GL_CONTEXT_PROFILE_CORE))
    sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_MAJOR_VERSION, 4)
    sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_MINOR_VERSION, 2)
    sdl.gl_set_attribute(sdl.GLAttr.GL_DOUBLEBUFFER, 1)

    window = Window("SDL Window", win_width, win_height, WindowFlags.WINDOW_RESIZABLE | WindowFlags.WINDOW_OPENGL)
    context = sdl.gl_create_context(window._handle)
    if not context:
        raise Error("Failed to create OpenGL context. Unsupported OpenGL version.")
    
    sdl.gl_make_current(window._handle, context)
    gl = GL(sdl.gl_get_proc_address)

    app_init(window, gl)
    
    main_loop(window, gl)
    sdl.quit()
