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
    dispatcher.append(ControlsHandler(state))

    while running:
        running = dispatcher.poll_events()
        if not running:
            break
        update(state)


def main():
    sdl.init(InitFlags.INIT_VIDEO | InitFlags.INIT_EVENTS)

    window = Window(
        "SDL Window",
        win_width,
        win_height,
        WindowFlags.WINDOW_RESIZABLE | WindowFlags.WINDOW_OPENGL,
    )
    init_opengl(window)
    res = String(unsafe_from_utf8_ptr=sdl.get_current_video_driver())
    print(res)
    state = AppState(window)
    print("Relative mode: ", sdl.get_window_relative_mouse_mode(window._handle[]))

    main_loop(state)

    sdl.quit()
