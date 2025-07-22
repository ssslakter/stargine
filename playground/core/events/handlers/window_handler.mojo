from sdl import Scancode
from ...imports import *
from ...window import *
from .base_handler import *


struct WindowHandler(EventHandler):
    # var active: Bool
    var window: Window

    # fn enable(mut self):
    #     self.active = True

    # fn disable(mut self):
    #     self.active = False

    fn __init__(out self, window: Window):
        self.window = window

    fn handle(mut self, event: Event) raises -> Bool:
        var event_type = event[CommonEvent].type
        if event_type == Int(EventType.EVENT_QUIT):
            return False
        elif event_type == Int(EventType.EVENT_WINDOW_RESIZED):
            self.handle_window_resized(event[WindowEvent])
        if event_type != Int(EventType.EVENT_KEY_DOWN):
            return True

        var key_event = event[KeyboardEvent]
        if Int(key_event.scancode) == Int(Scancode.SCANCODE_F11):
            self.window.toggle_fullscreen()
        elif Int(key_event.scancode) == Int(Scancode.SCANCODE_ESCAPE):
            return False
        return True

    fn handle_window_resized(mut self, event: WindowEvent):
        self.window.width = event.data1
        self.window.height = event.data2
        gl.viewport(0, 0, event.data1, event.data2)
