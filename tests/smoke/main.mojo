"""Renders a scene off-screen and checks that it reaches the framebuffer and leaks nothing.

Needs a working display; run it under Xvfb or a real session, not a bare TTY.
"""

import opengl as gl
import sdl
from sdl import InitFlags, WindowFlags
from std.testing import assert_true
from stargine.core import renderer
from stargine.core.gpu import GraphicsBuffer, OpenGLContext, VertexAttributeType
from stargine.core.linalg import Vec3f, Vec4f
from stargine.core.texture import Texture
from stargine.core.window import Window
from stargine.scene import Camera, DirectionalLight, PointLight
from stargine.scene.material import basic_material
from stargine.primitives import plane, sphere

comptime WIDTH = 640
comptime HEIGHT = 480
comptime FRAMES = 3
comptime RESOURCE_CYCLES = 64
comptime TEXTURES = "examples/assets/textures/"


def count_lit_pixels() raises -> Int:
    """Returns how many colour channels differ from the black clear colour."""
    var lit = 0
    for value in renderer.read_pixels(WIDTH, HEIGHT):
        if value:
            lit += 1
    return lit


def assert_gl_names_are_reused() raises:
    """A leaked buffer or texture keeps its name allocated, so the driver hands out a new one."""
    var positions: List[Vec3f] = [Vec3f(0, 0, 0), Vec3f(1, 0, 0), Vec3f(1, 1, 0)]
    var first_vao = 0
    for cycle in range(RESOURCE_CYCLES):
        var buffer = GraphicsBuffer[DType.uint32, VertexAttributeType.POSITION](positions)
        var texture = Texture(TEXTURES + "box.png")
        _ = texture^
        if cycle == 0:
            first_vao = Int(buffer.vao.name[].id)
        else:
            assert_true(
                Int(buffer.vao.name[].id) == first_vao,
                "vertex array names are not being reused, GL objects are leaking",
            )


def main() raises:
    sdl.init(InitFlags.INIT_VIDEO | InitFlags.INIT_EVENTS)
    var window = Window("stargine smoke test", WIDTH, HEIGHT, WindowFlags.WINDOW_OPENGL)
    var context = OpenGLContext(window)
    renderer.init_blend()
    renderer.enable_depth_test()
    gl.viewport(0, 0, WIDTH, HEIGHT)

    assert_gl_names_are_reused()

    var camera = Camera(position=Vec3f(0, 2.5, 5), aspect_ratio=Float32(WIDTH) / Float32(HEIGHT))
    camera.look_at(Vec3f(0))

    var light = PointLight(position=Vec3f(2, 4, 3))
    var material = basic_material(
        Texture(TEXTURES + "box.png"),
        Texture(TEXTURES + "box_specular.png", srgb=False),
        point_light=light.copy(),
        dir_light=DirectionalLight(direction=Vec3f(0, -1, 0)),
    )
    var ball = sphere(material.copy(), rings=16, segments=32)
    var ground = plane(material.copy(), subdivisions=4, uv_scale=4)
    ground.transform[].set_scale(Vec3f(8, 1, 8))
    ground.transform[].position = Vec3f(0, -1.2, 0)

    var lit = 0
    for _ in range(FRAMES):
        renderer.clear(Vec4f(0))
        ball.draw(camera)
        ground.draw(camera)
        lit = max(lit, count_lit_pixels())
        window.swap()

    assert_true(lit > 0, "the scene rendered no visible pixels")
    print("smoke test passed:", FRAMES, "frames rendered,", lit, "lit subpixels")

    _ = context^
    _ = window^
    sdl.quit()
