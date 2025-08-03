from ..app import AppState
from ..ecs import *
from ..core import *
from ..core.events import *

struct ControlsState(Copyable & Movable):
    alias move_speed = 5.0
    alias mouse_sensivity = 0.1

    var offset: Vec2f
    var forward: Bool
    var backward: Bool
    var left: Bool
    var right: Bool
    var up: Bool
    var down: Bool

    fn __init__(out self):
        self.offset = Vec2f(0)
        self.forward = False
        self.backward = False
        self.left = False
        self.right = False
        self.up = False
        self.down = False


struct ControlsHandler[origin: Origin[True]](EventHandler):
    # var camera: Pointer[Camera, origin=origin]
    var game_state: Pointer[AppState, origin=origin]
    var controls_state: ControlsState

    fn __init__(out self, ref [origin] game_state: AppState):
        # self.camera = Pointer(to=camera)
        self.game_state = Pointer(to=game_state)
        self.controls_state = ControlsState()

    fn handle(mut self, event: Event) raises -> Bool:
        var event_type = event[CommonEvent].type
        if event_type == Int(EventType.EVENT_WINDOW_FOCUS_GAINED):
            sdl.set_window_relative_mouse_mode(self.game_state[].window._handle[], True)
            res = sdl.get_error()
            print(String(unsafe_from_utf8_ptr=res))
        elif event_type == Int(EventType.EVENT_WINDOW_FOCUS_LOST):
            sdl.set_window_relative_mouse_mode(self.game_state[].window._handle[], False)
        elif event_type == Int(EventType.EVENT_MOUSE_MOTION):
            self.handle_mouse_event(event[MouseMotionEvent])
        if event_type == Int(EventType.EVENT_KEY_DOWN) or event_type == Int(EventType.EVENT_KEY_UP):
            self.handle_key_event(event[KeyboardEvent])
        return True

    fn handle_key_event(mut self, event: KeyboardEvent):
        ref controls = self.controls_state
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
        self.controls_state.offset -= offset*ControlsState.mouse_sensivity

    fn update_movement(mut self):
        ref cam = self.game_state[].camera
        delta_time = self.game_state[].delta_time
        pos_delta = Float32(delta_time * ControlsState.move_speed)

        ref controls = self.controls_state
        if controls.forward:
            cam.transform.translate(cam.get_forward() * pos_delta)
        if controls.backward:
            cam.transform.translate(cam.get_forward() * -pos_delta)
        if controls.left:
            cam.transform.translate(cam.get_right() * -pos_delta)
        if controls.right:
            cam.transform.translate(cam.get_right() * pos_delta)
        if controls.up:
            cam.transform.translate(Vec3f(0.0, 1.0, 0.0) * pos_delta)
        if controls.down:
            cam.transform.translate(Vec3f(0.0, -1.0, 0.0) * pos_delta)

        cam.rotate_deg(controls.offset.x(), controls.offset.y())
        controls.offset = Vec2f(0)