from ..app import AppState
from ..ecs import *
from ..core import *
from ..core.events import *


struct ControlsHandler[origin: Origin[True]](EventHandler):
    alias rot_speed = 5.0
    alias mouse_sensivity = 0.1
    # var camera: Pointer[Camera, origin=origin]
    var game_state: Pointer[AppState, origin=origin]

    fn __init__(out self, ref [origin] game_state: AppState):
        # self.camera = Pointer(to=camera)
        self.game_state = Pointer(to=game_state)

    fn handle(mut self, event: Event) raises -> Bool:
        var event_type = event[CommonEvent].type
        if event_type == Int(EventType.EVENT_WINDOW_FOCUS_GAINED):
            sdl.set_window_relative_mouse_mode(self.game_state[].window._handle[], True)
        elif event_type == Int(EventType.EVENT_WINDOW_FOCUS_LOST):
            sdl.set_window_relative_mouse_mode(self.game_state[].window._handle[], False)
        elif event_type == Int(EventType.EVENT_MOUSE_MOTION):
            self.handle_mouse_event(event[MouseMotionEvent])
        if event_type == Int(EventType.EVENT_KEY_DOWN) or event_type == Int(EventType.EVENT_KEY_UP):
            self.handle_key_event(event[KeyboardEvent])
        return True

    fn handle_key_event(mut self, event: KeyboardEvent):
        ref controls = self.game_state[].controls_state
        var is_pressed = event.down
        if Int(event.scancode) == Int(Scancode.SCANCODE_W):
            controls.forward = is_pressed
        elif Int(event.scancode) == Int(Scancode.SCANCODE_S):
            controls.backward = is_pressed
        elif Int(event.scancode) == Int(Scancode.SCANCODE_A):
            controls.left = is_pressed
        elif Int(event.scancode) == Int(Scancode.SCANCODE_D):
            controls.right = is_pressed
        elif Int(event.scancode) == Int(Scancode.SCANCODE_SPACE):
            controls.up = is_pressed
        elif Int(event.scancode) == Int(Scancode.SCANCODE_LSHIFT):
            controls.down = is_pressed


    fn handle_mouse_event(mut self, event: MouseMotionEvent):
        offset = Vec2f(event.xrel, event.yrel)
        ref cam = self.game_state[].camera
        offset *= Self.mouse_sensivity
        cam.rotate_deg(offset.x(), offset.y())
