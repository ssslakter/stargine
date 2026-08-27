import sdl
from sdl import CommonEvent, Event, KeyboardEvent, MouseMotionEvent, Scancode
from ..core.events import EventHandler
from ..core.linalg import Vec2f, Vec3f
from ..core.window import Window
from ..scene.camera import Camera


struct ControlsState(Copyable, Movable):
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
    """WASD plus mouse look, driving a camera the caller still owns."""

    comptime move_speed = 5.0
    comptime mouse_sensitivity = 0.1

    var camera: Pointer[Camera, origin= Self.origin]
    var window: Window
    var state: ControlsState

    def __init__(out self, ref [Self.origin] camera: Camera, var window: Window):
        self.camera = Pointer(to=camera)
        self.window = window^
        self.state = ControlsState()

    def handle(mut self, event: Event) raises -> Bool:
        var event_type = Int(event.unsafe_get[CommonEvent]().type)
        if event_type == Int(sdl.EventType.EVENT_WINDOW_RESIZED):
            var resized = event.unsafe_get[sdl.WindowEvent]()
            if resized.data2:
                self.camera[].aspect_ratio = Float32(resized.data1) / Float32(resized.data2)
        elif event_type == Int(sdl.EventType.EVENT_WINDOW_FOCUS_GAINED):
            sdl.set_window_relative_mouse_mode(self.window.handle(), True)
        elif event_type == Int(sdl.EventType.EVENT_WINDOW_FOCUS_LOST):
            sdl.set_window_relative_mouse_mode(self.window.handle(), False)
        elif event_type == Int(sdl.EventType.EVENT_MOUSE_MOTION):
            self.state.offset += (
                Vec2f(event.unsafe_get[MouseMotionEvent]().xrel, -event.unsafe_get[MouseMotionEvent]().yrel)
                * Self.mouse_sensitivity
            )
        elif event_type in [Int(sdl.EventType.EVENT_KEY_DOWN), Int(sdl.EventType.EVENT_KEY_UP)]:
            self.handle_key_event(event.unsafe_get[KeyboardEvent]())
        return True

    def handle_key_event(mut self, event: KeyboardEvent):
        ref state = self.state
        var pressed = event.down
        var scancode = Int(event.scancode)
        if scancode == Int(Scancode.SCANCODE_W):
            state.forward = pressed
        elif scancode == Int(Scancode.SCANCODE_S):
            state.backward = pressed
        elif scancode == Int(Scancode.SCANCODE_A):
            state.left = pressed
        elif scancode == Int(Scancode.SCANCODE_D):
            state.right = pressed
        elif scancode == Int(Scancode.SCANCODE_SPACE):
            state.up = pressed
        elif scancode == Int(Scancode.SCANCODE_LSHIFT):
            state.down = pressed

    def update(mut self, delta_time: Float64):
        ref camera = self.camera[]
        ref state = self.state
        var step = Float32(delta_time * Self.move_speed)

        if state.forward:
            camera.transform.translate(camera.get_forward() * step)
        if state.backward:
            camera.transform.translate(camera.get_forward() * -step)
        if state.left:
            camera.transform.translate(camera.get_right() * -step)
        if state.right:
            camera.transform.translate(camera.get_right() * step)
        if state.up:
            camera.transform.translate(Vec3f(0.0, 1.0, 0.0) * step)
        if state.down:
            camera.transform.translate(Vec3f(0.0, -1.0, 0.0) * step)

        camera.rotate_deg(state.offset.x(), state.offset.y())
        state.offset = Vec2f(0)
