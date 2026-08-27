"""A small solar system: a star, three worlds, a moon and a star field.

Shows the sphere primitive, an indexed mesh, a cube-map skybox, and a point
light standing in for the star. The moon's orbit is composed by hand, because
the engine has no transform hierarchy yet.
"""

import opengl as gl
import sdl
from sdl import Event, InitFlags, WindowFlags
from std.math import cos, sin, tau
from stargine.core import Clock, CubeMap, renderer
from stargine.core.events import WindowHandler
from stargine.core.gpu import OpenGLContext
from stargine.core.linalg import Vec3f, Vec4f
from stargine.core.texture import Texture
from stargine.core.window import Window
from stargine.scene import Camera, PointLight, StandardModel
from stargine.scene.material import basic_material, texture_material
from stargine.event_handlers import ControlsHandler
from stargine.primitives import Skybox, sphere

comptime WIDTH = 1280
comptime HEIGHT = 800
comptime TEXTURES = "examples/assets/textures/"


@fieldwise_init
struct Orbit(Copyable, Movable):
    var radius: Float32
    var period: Float32
    """Seconds for one trip around the star."""
    var day: Float32
    """Seconds for one rotation about its own axis."""
    var size: Float32

    def position(self, elapsed: Float32) -> Vec3f:
        var angle = Float32(tau) * elapsed / self.period
        return Vec3f(cos(angle) * self.radius, 0, sin(angle) * self.radius)


struct World(Copyable, Movable):
    var model: StandardModel
    var orbit: Orbit

    def __init__(out self, var model: StandardModel, var orbit: Orbit) raises:
        self.model = model^
        self.orbit = orbit^
        self.model.transform[].set_scale(self.orbit.size)

    def update(mut self, elapsed: Float32, origin: Vec3f = Vec3f(0)):
        ref transform = self.model.transform[]
        transform.position = origin + self.orbit.position(elapsed)
        transform.yaw = Float32(tau) * elapsed / self.orbit.day


def world(star: PointLight, texture_name: String, var orbit: Orbit) raises -> World:
    var texture = Texture(TEXTURES + texture_name)
    return World(
        sphere(basic_material(texture.copy(), texture.copy(), point_light=star.copy(), shininess=8)),
        orbit^,
    )


def main() raises:
    sdl.init(InitFlags.INIT_VIDEO | InitFlags.INIT_EVENTS)
    var window = Window(
        "stargine - solar system",
        WIDTH,
        HEIGHT,
        WindowFlags.WINDOW_RESIZABLE | WindowFlags.WINDOW_OPENGL,
    )
    var context = OpenGLContext(window)
    renderer.init_blend()
    renderer.enable_depth_test()
    gl.viewport(0, 0, WIDTH, HEIGHT)

    var camera = Camera(
        position=Vec3f(0, 6, 18), aspect_ratio=Float32(WIDTH) / Float32(HEIGHT), far=200
    )
    camera.look_at(Vec3f(0))

    # The faces are loaded in +X -X +Y -Y +Z -Z order.
    var faces = [String(TEXTURES, "stars_", face, ".png") for face in range(6)]
    var skybox = Skybox(CubeMap(faces))

    var star_light = PointLight(position=Vec3f(0), ambient=Vec3f(0.06), linear=0.014, quadratic=0.0007)
    var star = sphere(texture_material(Texture(TEXTURES + "sun.png")))
    star.transform[].set_scale(2.4)

    var worlds = [
        world(star_light, "planet_ember.png", Orbit(radius=5.5, period=9, day=5, size=0.6)),
        world(star_light, "planet_terra.png", Orbit(radius=9.0, period=17, day=3, size=0.9)),
        world(star_light, "planet_wisp.png", Orbit(radius=14.0, period=31, day=7, size=1.5)),
    ]
    var moon = world(star_light, "moon.png", Orbit(radius=1.8, period=2.5, day=2.5, size=0.25))

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

        star.transform[].yaw = elapsed * 0.05
        for ref planet in worlds:
            planet.update(elapsed)
        # No transform hierarchy, so the moon is offset from its planet by hand.
        moon.update(elapsed, worlds[1].model.transform[].position)

        renderer.clear(Vec4f(0.01, 0.01, 0.03, 1))
        star.draw(camera)
        for ref planet in worlds:
            planet.model.draw(camera)
        moon.model.draw(camera)
        skybox.draw(camera)
        window.swap()

    _ = context^
    _ = window^
    sdl.quit()
