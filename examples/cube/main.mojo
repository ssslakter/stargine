"""The engine's original demo: a textured, lit cube and the light that lights it.

Shows a window and GL context, the WASD controls, a `basic_material` with a point
and a directional light, and a small custom event handler.
"""

import opengl as gl
import sdl
from sdl import CommonEvent, Event, InitFlags, KeyboardEvent, Scancode, WindowFlags
from std.memory import ArcPointer
from stargine.core import Clock, renderer
from stargine.core.events import EventHandler, WindowHandler
from stargine.core.gpu import OpenGLContext
from stargine.core.linalg import Vec3f, Vec4
from stargine.core.texture import Texture
from stargine.core.window import Window
from stargine.scene import Camera, DirectionalLight, PointLight, Transform
from stargine.scene.material import basic_material, unlit_material
from stargine.event_handlers import ControlsHandler
from stargine.primitives import cube

comptime WIDTH = 1024
comptime HEIGHT = 768
comptime TEXTURES = "examples/assets/textures/"


struct SpinHandler(EventHandler):
    """Arrow keys nudge the cube. Handlers only need `handle`."""

    var transform: ArcPointer[Transform]

    def __init__(out self, var transform: ArcPointer[Transform]):
        self.transform = transform^

    def handle(mut self, event: Event) raises -> Bool:
        if Int(event.unsafe_get[CommonEvent]().type) != Int(sdl.EventType.EVENT_KEY_DOWN):
            return True
        var scancode = Int(event.unsafe_get[KeyboardEvent]().scancode)
        if scancode == Int(Scancode.SCANCODE_UP):
            self.transform[].rotate(0.1)
        elif scancode == Int(Scancode.SCANCODE_DOWN):
            self.transform[].rotate(-0.1)
        elif scancode == Int(Scancode.SCANCODE_LEFT):
            self.transform[].rotate(0, 0.1)
        elif scancode == Int(Scancode.SCANCODE_RIGHT):
            self.transform[].rotate(0, -0.1)
        return True


def main() raises:
    sdl.init(InitFlags.INIT_VIDEO | InitFlags.INIT_EVENTS)
    var window = Window(
        "stargine - lit cube", WIDTH, HEIGHT, WindowFlags.WINDOW_RESIZABLE | WindowFlags.WINDOW_OPENGL
    )
    var context = OpenGLContext(window)
    renderer.init_blend()
    renderer.enable_depth_test()
    gl.viewport(0, 0, WIDTH, HEIGHT)

    var camera = Camera(position=Vec3f(-3.5, 2.2, 3.5), aspect_ratio=Float32(WIDTH) / Float32(HEIGHT))
    camera.look_at(Vec3f(0))
    var light = PointLight(position=Vec3f(2, 3, 2), diffuse=Vec3f(0.85), linear=0.045, quadratic=0.0075)
    light.transform[].set_scale(0.3)

    # The gizmo shares the light's transform, so moving one moves both.
    var gizmo = cube(unlit_material())
    gizmo.transform = light.transform
    gizmo.material.set_vec("color", Vec4(light.specular, 1))

    var box = cube(
        basic_material(
            Texture(TEXTURES + "box.png"),
            Texture(TEXTURES + "box_specular.png", srgb=False),
            point_light=light.copy(),
            dir_light=DirectionalLight(direction=Vec3f(0, -1, 0)),
        )
    )

    var window_handler = WindowHandler(window.copy())
    var controls = ControlsHandler(camera, window.copy())
    var spin = SpinHandler(box.transform)

    var clock = Clock()
    var event = Event(UInt32(0))
    var running = True

    while running:
        while sdl.poll_event(Pointer(to=event)):
            running &= window_handler.handle(event)
            running &= controls.handle(event)
            running &= spin.handle(event)
        if not running:
            break

        clock.tick()
        controls.update(clock.delta)

        renderer.clear()
        box.draw(camera)
        gizmo.draw(camera)
        window.swap()

    # Values die at their last use, so keep the window and context alive until
    # after every GL resource above has been released.
    _ = context^
    _ = window^
    sdl.quit()
