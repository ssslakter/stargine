from sdl import InitFlags, WindowFlags
from sdl.sdl_events import *
import opengl as gl
from stargine.core.events import *
from stargine.event_handlers import *
from stargine import *
from stargine.app import *


def main_loop(mut state: AppState):
    var running = True
    var dispatcher = EventDispatcher()
    var controls_handler = ArcPointer(ControlsHandler(state))
    dispatcher.append(WindowHandler(state.window))
    dispatcher.append(controls_handler)

    while running:
        running = dispatcher.poll_events()
        if not running:
            break
        controls_handler[].update_movement()
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
    state = AppState(window)

    main_loop(state)

    sdl.quit()
