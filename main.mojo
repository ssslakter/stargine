from sdl import InitFlags, WindowFlags
from sdl.sdl_events import *
import opengl as gl
from stargine.core.events import *
from stargine.event_handlers import *
from stargine import *
from stargine.app import *


def main_loop(mut state: AppState) raises:
    var running = True
    var controls_handler = ControlsHandler(state)
    var window_handler = WindowHandler(state.window.copy())
    var event = Event(UInt32(0))

    while running:
        while sdl.poll_event(Ptr(to=event)):
            running &= window_handler.handle(event)
            running &= controls_handler.handle(event)
        if not running:
            break
        controls_handler.update_movement()
        update(state)


def run() raises:
    window = Window(
        "SDL Window",
        win_width,
        win_height,
        WindowFlags.WINDOW_RESIZABLE | WindowFlags.WINDOW_OPENGL,
    )
    context = init_opengl(window)
    state = AppState(window)

    main_loop(state)


def main() raises:
    sdl.init(InitFlags.INIT_VIDEO | InitFlags.INIT_EVENTS)
    run()
    sdl.quit()
