import sdl
from sdl import CommonEvent, Event, KeyboardEvent, MouseMotionEvent, Scancode
from ..app import AppState
from ..core.events import EventHandler
from ..core.linalg import Vec2f, Vec3f


struct ControlsState(Copyable, Movable):
    comptime move_speed = 5.0
    comptime mouse_sensitivity = 0.1

    var offset: Vec2f
    var forward: Bool
    var backward: Bool
    var left: Bool
    var right: Bool
    var up: Bool
    var down: Bool

    def __init__(out self):
        self.offset = Vec2f(0)
        self.forward = False
        self.backward = False
        self.left = False
        self.right = False
        self.up = False
        self.down = False


struct ControlsHandler[origin: MutOrigin](EventHandler):
    var game_state: Pointer[AppState, origin= Self.origin]
    var controls_state: ControlsState

    def __init__(out self, ref [Self.origin] game_state: AppState):
        self.game_state = Pointer(to=game_state)
        self.controls_state = ControlsState()

    def handle(mut self, event: Event) raises -> Bool:
        var event_type = Int(event.unsafe_get[CommonEvent]().type)
        if event_type == Int(sdl.EventType.EVENT_WINDOW_FOCUS_GAINED):
            sdl.set_window_relative_mouse_mode(self.game_state[].window.handle(), True)
        elif event_type == Int(sdl.EventType.EVENT_WINDOW_FOCUS_LOST):
            sdl.set_window_relative_mouse_mode(self.game_state[].window.handle(), False)
        elif event_type == Int(sdl.EventType.EVENT_MOUSE_MOTION):
            self.handle_mouse_event(event.unsafe_get[MouseMotionEvent]())
        elif event_type in [Int(sdl.EventType.EVENT_KEY_DOWN), Int(sdl.EventType.EVENT_KEY_UP)]:
            self.handle_key_event(event.unsafe_get[KeyboardEvent]())
        return True

    def handle_key_event(mut self, event: KeyboardEvent):
        ref controls = self.controls_state
        var is_pressed = event.down
        var scancode = Int(event.scancode)
        if scancode == Int(Scancode.SCANCODE_W):
            controls.forward = is_pressed
        elif scancode == Int(Scancode.SCANCODE_S):
            controls.backward = is_pressed
        elif scancode == Int(Scancode.SCANCODE_A):
            controls.left = is_pressed
        elif scancode == Int(Scancode.SCANCODE_D):
            controls.right = is_pressed
        elif scancode == Int(Scancode.SCANCODE_SPACE):
            controls.up = is_pressed
        elif scancode == Int(Scancode.SCANCODE_LSHIFT):
            controls.down = is_pressed

        ref cube_transform = self.game_state[].cubes[0].transform
        if scancode == Int(Scancode.SCANCODE_UP):
            cube_transform[].rotate(0.05)
        elif scancode == Int(Scancode.SCANCODE_DOWN):
            cube_transform[].rotate(-0.05)
        elif scancode == Int(Scancode.SCANCODE_LEFT):
            cube_transform[].rotate(0, 0.05)
        elif scancode == Int(Scancode.SCANCODE_RIGHT):
            cube_transform[].rotate(0, -0.05)

    def handle_mouse_event(mut self, event: MouseMotionEvent):
        self.controls_state.offset -= Vec2f(event.xrel, event.yrel) * ControlsState.mouse_sensitivity

    def update_movement(mut self):
        ref cam = self.game_state[].camera
        ref controls = self.controls_state
        var pos_delta = Float32(self.game_state[].delta_time * ControlsState.move_speed)

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
