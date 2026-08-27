"""Frame-time benchmark: renders N cubes off-screen and reports the distribution.

Averages hide hitches, so this reports p50, p99 and max. Needs a display; run it
under Xvfb or a real session.
"""

import opengl as gl
import sdl
from std.math import sqrt
from sdl import InitFlags, WindowFlags
from stargine.core import Clock, renderer
from stargine.core.gpu import OpenGLContext
from stargine.core.linalg import Vec3f, Vec4f
from stargine.core.texture import Texture
from stargine.core.window import Window
from stargine.scene import Camera, PointLight
from stargine.scene.material import basic_material
from stargine.primitives import cube

comptime WIDTH = 1280
comptime HEIGHT = 720
comptime WARMUP = 20
comptime FRAMES = 200
comptime COUNTS = [10, 100, 500, 1000]
comptime TEXTURES = "examples/assets/textures/"


def percentile(sorted_times: List[Float64], fraction: Float64) -> Float64:
    var index = Int(fraction * Float64(len(sorted_times) - 1))
    return sorted_times[index]


def report(count: Int, var times: List[Float64]):
    sort(times)
    var p50 = percentile(times, 0.5)
    print(
        count,
        "cubes | p50",
        p50 * 1e3,
        "ms | p99",
        percentile(times, 0.99) * 1e3,
        "ms | max",
        times[len(times) - 1] * 1e3,
        "ms |",
        p50 * 1e6 / Float64(count),
        "us/cube",
    )


def main() raises:
    sdl.init(InitFlags.INIT_VIDEO | InitFlags.INIT_EVENTS)
    var window = Window("stargine bench", WIDTH, HEIGHT, WindowFlags.WINDOW_OPENGL)
    var context = OpenGLContext(window, debug=False)
    renderer.init_blend()
    renderer.enable_depth_test()
    gl.viewport(0, 0, WIDTH, HEIGHT)
    sdl.gl_set_swap_interval(0)

    var camera = Camera(position=Vec3f(0, 0, 60), aspect_ratio=Float32(WIDTH) / Float32(HEIGHT))
    camera.look_at(Vec3f(0))
    var material = basic_material(
        Texture(TEXTURES + "box.png"),
        Texture(TEXTURES + "box_specular.png", srgb=False),
        point_light=PointLight(position=Vec3f(20, 20, 20)),
    )

    print("stargine bench:", WIDTH, "x", HEIGHT, "-", FRAMES, "frames per row")

    for count in materialize[COUNTS]():
        var cubes = List[type_of(cube(material.copy()))]()
        var side = Int(sqrt(Float64(count))) + 1
        for index in range(count):
            var model = cube(material.copy())
            var x = Float32(index % side) - Float32(side) / 2
            var y = Float32(index // side) - Float32(side) / 2
            model.transform[].position = Vec3f(x * 2, y * 2, 0)
            cubes.append(model^)

        var clock = Clock()
        var times = List[Float64]()
        for frame in range(WARMUP + FRAMES):
            clock.tick()
            renderer.clear(Vec4f(0.01, 0.01, 0.03, 1))
            for ref model in cubes:
                model.draw(camera)
            gl.finish()
            if frame >= WARMUP:
                times.append(clock.delta)
            window.swap()
        report(count, times^)

    _ = context^
    _ = window^
    sdl.quit()
