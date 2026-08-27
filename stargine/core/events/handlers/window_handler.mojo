import opengl as gl
import sdl
from sdl import Event, Scancode
from ...window import Window
from .base_handler import EventHandler


struct WindowHandler(EventHandler):
    var window: Window

    def __init__(out self, var window: Window):
        self.window = window^

    def handle(mut self, event: Event) raises -> Bool:
        var event_type = Int(event.unsafe_get[sdl.CommonEvent]().type)
        if event_type == Int(sdl.EventType.EVENT_QUIT):
            return False
        if event_type == Int(sdl.EventType.EVENT_WINDOW_RESIZED):
            self.handle_window_resized(event.unsafe_get[sdl.WindowEvent]())
        if event_type != Int(sdl.EventType.EVENT_KEY_DOWN):
            return True

        var key_event = event.unsafe_get[sdl.KeyboardEvent]()
        if Int(key_event.scancode) == Int(Scancode.SCANCODE_F11):
            self.window.toggle_fullscreen()
        elif Int(key_event.scancode) == Int(Scancode.SCANCODE_ESCAPE):
            return False
        return True

    def handle_window_resized(mut self, event: sdl.WindowEvent) raises:
        self.window.width = event.data1
        self.window.height = event.data2
        gl.viewport(0, 0, event.data1, event.data2)
