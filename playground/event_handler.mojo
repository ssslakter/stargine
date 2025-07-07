from .imports import *
from sdl import Event, poll_event, get_window_position, set_window_position, Scancode
from sdl.sdl_events import EventType, KeyboardEvent, WindowEvent, MouseMotionEvent, CommonEvent
from .app import AppState

struct EventHandler:
    var dragging: Bool
    var drag_offset_x: Float32
    var drag_offset_y: Float32

    fn __init__(out self):
        self.dragging = False
        self.drag_offset_x = 0.0
        self.drag_offset_y = 0.0

    fn handle_key_down(mut self, app_state: AppState, event: KeyboardEvent) raises -> Bool:
        if Int(event.scancode) == Int(Scancode.SCANCODE_ESCAPE):
            return False
        if Int(event.scancode) == Int(Scancode.SCANCODE_R):
            app_state.shaders[0].reload()
        return True

    fn handle_window_resized(mut self, event: WindowEvent):
        gl.viewport(0, 0, event.data1, event.data2)

    fn handle_mouse_button_down(mut self, event: MouseMotionEvent):
        self.dragging = True
        self.drag_offset_x = event.x
        self.drag_offset_y = event.y

    fn handle_mouse_button_up(mut self):
        self.dragging = False

    fn handle_mouse_motion(self, app_state: AppState, event: MouseMotionEvent) raises:
        if not self.dragging:
            return

        var mouse_x = event.x
        var mouse_y = event.y
        var win_x, win_y = Int32(0), Int32(0)
        get_window_position(app_state.window._handle, Ptr(to=win_x), Ptr(to=win_y))
        set_window_position(
            app_state.window._handle, 
            Int32(Float32(win_x) + (mouse_x - self.drag_offset_x)), 
            Int32(Float32(win_y) + (mouse_y - self.drag_offset_y)))

    fn poll_events(mut self, app_state: AppState) raises -> Bool:
        var event = Event(UInt32(0))
        while poll_event(Ptr(to=event)):
            var event_type = event[CommonEvent].type

            if event_type == Int(EventType.EVENT_QUIT):
                return False

            if event_type == Int(EventType.EVENT_KEY_DOWN):
                if not self.handle_key_down(app_state, event[KeyboardEvent]):
                    return False
            
            if event_type == Int(EventType.EVENT_WINDOW_RESIZED):
                self.handle_window_resized(event[WindowEvent])

            if event_type == Int(EventType.EVENT_MOUSE_BUTTON_DOWN):
                self.handle_mouse_button_down(event[MouseMotionEvent])
            elif event_type == Int(EventType.EVENT_MOUSE_BUTTON_UP):
                self.handle_mouse_button_up()
            elif event_type == Int(EventType.EVENT_MOUSE_MOTION):
                self.handle_mouse_motion(app_state, event[MouseMotionEvent])
        
        return True 