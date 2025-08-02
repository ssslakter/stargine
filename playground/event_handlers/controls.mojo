from ..app import AppState
from ..ecs import *
from ..core import *
from ..core.events import *

struct ControlsHandler[origin: Origin[True]](EventHandler):
    alias move_speed = 5.0
    alias rot_speed = 5.0
    alias mouse_sensivity = 0.1
    var mouse_position: Vec2f
    # var camera: Pointer[Camera, origin=origin]
    var game_state: Pointer[AppState, origin=origin]

    fn __init__(out self, ref [origin] game_state: AppState):
        # self.camera = Pointer(to=camera)
        self.game_state = Pointer(to=game_state)
        self.mouse_position = Vec2f(0)

    fn handle(mut self, event: Event) raises -> Bool:
        if event[CommonEvent].type == Int(EventType.EVENT_KEY_DOWN): 
            self.handle_key_event(event[KeyboardEvent])
        elif event[CommonEvent].type == Int(EventType.EVENT_MOUSE_MOTION):
            self.handle_mouse_event(event[MouseMotionEvent])
            print('mouse motion')
        return True

    fn handle_key_event(mut self, event: KeyboardEvent):
        ref cam = self.game_state[].camera
        delta_time = self.game_state[].delta_time
        pos_delta = Float32(delta_time * Self.move_speed)
        if Int(event.scancode) == Int(Scancode.SCANCODE_W):
            cam.transform.translate(cam.get_forward() * pos_delta)
        elif Int(event.scancode) == Int(Scancode.SCANCODE_S):
            cam.transform.translate(cam.get_forward() * -pos_delta)
        elif Int(event.scancode) == Int(Scancode.SCANCODE_A):
            cam.transform.translate(cam.get_right() * -pos_delta)
        elif Int(event.scancode) == Int(Scancode.SCANCODE_D):
            cam.transform.translate(cam.get_right() * pos_delta)
        elif Int(event.scancode) == Int(Scancode.SCANCODE_SPACE):
            cam.transform.translate(Vec3f(0.0, 1.0, 0.0) * pos_delta)
        elif Int(event.scancode) == Int(Scancode.SCANCODE_LSHIFT):
            cam.transform.translate(Vec3f(0.0, -1.0, 0.0) * pos_delta)
            

    fn handle_mouse_event(mut self, event: MouseMotionEvent):
        mouse_pos = Vec2f(event.xrel, event.yrel)
        print(mouse_pos)
        offset = self.mouse_position - mouse_pos
        self.mouse_position = mouse_pos
        ref cam = self.game_state[].camera
        offset *= Self.mouse_sensivity
        cam.rotate_deg(offset.x(), offset.y())
