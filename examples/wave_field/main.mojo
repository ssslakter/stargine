"""A rippling field driven entirely by a custom vertex shader.

Shows the subdivided plane primitive, `custom_material` with a hand-written
`.glsl` file, and a per-frame uniform. The sphere bobbing on the surface has to
repeat the wave function on the CPU, because the engine cannot read displaced
vertices back from the GPU.
"""

import opengl as gl
import sdl
from sdl import Event, InitFlags, WindowFlags
from std.math import sin
from std.os import env
from std.pathlib import Path
from stargine.core import Clock, renderer
from stargine.core.events import WindowHandler
from stargine.core.gpu import OpenGLContext
from stargine.core.linalg import Vec3f, Vec4f
from stargine.core.shader import Shader
from stargine.core.texture import Texture
from stargine.core.window import Window
from stargine.scene import Camera, DirectionalLight, PointLight
from stargine.scene.material import basic_material, custom_material
from stargine.event_handlers import ControlsHandler
from stargine.primitives import plane, sphere

comptime WIDTH = 1280
comptime HEIGHT = 800
comptime TEXTURES = "examples/assets/textures/"
comptime FIELD_SIZE = 40.0
comptime AMPLITUDE = 1.1


def wave(x: Float32, z: Float32, time: Float32) -> Float32:
    """Mirrors the `wave` function in wave.glsl so the sphere can ride the surface."""
    return AMPLITUDE * (
        0.50 * sin(x * 0.7 + time * 1.6)
        + 0.30 * sin(z * 0.5 - time * 1.1)
        + 0.20 * sin((x + z) * 1.1 + time * 2.4)
    )


def main() raises:
    sdl.init(InitFlags.INIT_VIDEO | InitFlags.INIT_EVENTS)
    var window = Window(
        "stargine - wave field",
        WIDTH,
        HEIGHT,
        WindowFlags.WINDOW_RESIZABLE | WindowFlags.WINDOW_OPENGL,
    )
    var context = OpenGLContext(window)
    renderer.init_blend()
    renderer.enable_depth_test()
    gl.viewport(0, 0, WIDTH, HEIGHT)

    var camera = Camera(
        position=Vec3f(0, 6, 14), aspect_ratio=Float32(WIDTH) / Float32(HEIGHT), far=200
    )
    camera.look_at(Vec3f(0, 0, -6))

    var surface = custom_material(Shader(Path(env.getenv("EXAMPLE_DIR")) / "wave.glsl"))
    surface.set_texture("surface", Texture(TEXTURES + "grid.png", repeat=True))
    surface.set_vec("crest", Vec3f(0.62, 0.78, 0.95))
    surface.set_vec("trough", Vec3f(0.15, 0.35, 0.75))
    surface.set_scalar("amplitude", Float32(AMPLITUDE))

    var field = plane(surface^, subdivisions=192, uv_scale=12)
    field.transform[].set_scale(Vec3f(FIELD_SIZE, 1, FIELD_SIZE))

    var buoy = sphere(
        basic_material(
            Texture(TEXTURES + "white.png"),
            Texture(TEXTURES + "white.png"),
            point_light=PointLight(position=Vec3f(0, 6, 0), diffuse=Vec3f(0.9)),
            dir_light=DirectionalLight(direction=Vec3f(-0.4, -1, -0.3), ambient=Vec3f(0.25)),
        ),
        rings=32,
        segments=64,
    )
    buoy.transform[].set_scale(0.9)

    var window_handler = WindowHandler(window.copy())
    var controls = ControlsHandler(camera, window.copy())
    var clock = Clock()
    var event = Event(UInt32(0))
    var running = True

    while running:
        while sdl.poll_event(Pointer(to=event)):
            running &= window_handler.handle(event)
            running &= controls.handle(event)
        if not running:
            break

        clock.tick()
        controls.update(clock.delta)
        var elapsed = Float32(clock.elapsed())

        field.material.set_scalar("time", elapsed)
        var drift = Vec3f(sin(elapsed * 0.4) * 6, 0, sin(elapsed * 0.27) * 6)
        buoy.transform[].position = Vec3f(
            drift.x(), wave(drift.x(), drift.z(), elapsed) + 2.6, drift.z()
        )

        renderer.clear(Vec4f(0.04, 0.07, 0.13, 1))
        field.draw(camera)
        buoy.draw(camera)
        window.swap()

    _ = context^
    _ = window^
    sdl.quit()
