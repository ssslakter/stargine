from ..ecs import *
from ..core import *
from ..core.events import *

struct ControlsHandler[origin: Origin[True]](EventHandler):
    alias move_dist = 1.0
    alias rot_angle = 5.0
    var camera: Pointer[Camera, origin=origin]

    fn __init__(out self, ref [origin] camera: Camera):
        self.camera = Pointer(to=camera)

    fn handle(mut self, event: Event) raises -> Bool:
        if event[CommonEvent].type != Int(EventType.EVENT_KEY_DOWN): 
            return True
        self.handle_key_event(event[KeyboardEvent])
        return True

    fn handle_key_event(mut self, event: KeyboardEvent):
        ref cam = self.camera[]
        if Int(event.scancode) == Int(Scancode.SCANCODE_W):
            cam.move(cam.get_forward() * Self.move_dist)
        elif Int(event.scancode) == Int(Scancode.SCANCODE_S):
            cam.move(cam.get_forward() * -Self.move_dist)
        elif Int(event.scancode) == Int(Scancode.SCANCODE_A):
            cam.move(cam.get_right() * Self.move_dist)
        elif Int(event.scancode) == Int(Scancode.SCANCODE_D):
            cam.move(cam.get_right() * -Self.move_dist)
        elif Int(event.scancode) == Int(Scancode.SCANCODE_SPACE):
            cam.move(Vec3f(0.0, 1.0, 0.0) * Self.move_dist)
        elif Int(event.scancode) == Int(Scancode.SCANCODE_LSHIFT):
            cam.move(Vec3f(0.0, -1.0, 0.0) * Self.move_dist)
        elif Int(event.scancode) == Int(Scancode.SCANCODE_UP):
            cam.rotate(0.0, Self.rot_angle)
        elif Int(event.scancode) == Int(Scancode.SCANCODE_DOWN):
            cam.rotate(0.0, -Self.rot_angle)
        elif Int(event.scancode) == Int(Scancode.SCANCODE_LEFT):
            cam.rotate(Self.rot_angle, 0.0)
        elif Int(event.scancode) == Int(Scancode.SCANCODE_RIGHT):
            cam.rotate(-Self.rot_angle, 0.0)