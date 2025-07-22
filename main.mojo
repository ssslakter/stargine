from sdl import InitFlags, WindowFlags
from sdl.sdl_events import *
import opengl as gl
from playground.core.events import *
from playground.event_handlers import *
from playground import *
from playground.app import *


def main_loop(mut state: AppState):
    var running = True
    var dispatcher = EventDispatcher()
    dispatcher.append(WindowHandler(state.window))
    dispatcher.append(ControlsHandler(state.camera))

    while running:
        running = dispatcher.poll_events()
        if not running:
            break
        update(state)


def main():
    sdl.init(InitFlags.INIT_VIDEO | InitFlags.INIT_EVENTS)

    sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_PROFILE_MASK, Int(sdl.GLProfile.GL_CONTEXT_PROFILE_CORE))
    sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_MAJOR_VERSION, 4)
    sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_MINOR_VERSION, 2)
    sdl.gl_set_attribute(sdl.GLAttr.GL_DOUBLEBUFFER, 1)

    window = Window(
        "SDL Window",
        win_width,
        win_height,
        WindowFlags.WINDOW_RESIZABLE | WindowFlags.WINDOW_OPENGL,
    )
    context = sdl.gl_create_context(window._handle[])
    if not context:
        raise Error("Failed to create OpenGL context. Unsupported OpenGL version.")

    sdl.gl_make_current(window._handle[], context)
    gl.init_opengl(sdl.gl_get_proc_address)
    state = AppState(window^)

    main_loop(state)

    sdl.quit()
