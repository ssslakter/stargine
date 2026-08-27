import sdl
from sdl import Event, InitFlags, WindowFlags
from stargine.app import AppState, update, win_height, win_width
from stargine.core.events import WindowHandler
from stargine.core.window import Window
from stargine.event_handlers import ControlsHandler


def main_loop(mut state: AppState) raises:
    var controls_handler = ControlsHandler(state)
    var window_handler = WindowHandler(state.window.copy())
    var event = Event(UInt32(0))
    var running = True

    while running:
        while sdl.poll_event(Pointer(to=event)):
            running &= window_handler.handle(event)
            running &= controls_handler.handle(event)
        if not running:
            break
        controls_handler.update_movement()
        update(state)


def main() raises:
    sdl.init(InitFlags.INIT_VIDEO | InitFlags.INIT_EVENTS)
    var state = AppState(
        Window(
            "Stargine",
            win_width,
            win_height,
            WindowFlags.WINDOW_RESIZABLE | WindowFlags.WINDOW_OPENGL,
        )
    )
    main_loop(state)
    sdl.quit()
