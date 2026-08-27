"""Renders a few frames of the demo scene and checks that the scene reaches the framebuffer.

Needs a working display; run it under Xvfb or a real session, not a bare TTY.
"""

import opengl as gl
import sdl
from sdl import InitFlags, WindowFlags
from std.testing import assert_true
from stargine.app import AppState, render, win_height, win_width
from stargine.core.gpu import GraphicsBuffer, VertexAttributeType
from stargine.core.linalg import Vec3f
from stargine.core.texture import Texture
from stargine.core.window import Window

comptime FRAMES = 3
comptime RESOURCE_CYCLES = 64


def count_lit_pixels() raises -> Int:
    """Returns how many pixels of the back buffer differ from the black clear colour."""
    var pixels = List[UInt8](length=win_width * win_height * 3, fill=0)
    gl.read_pixels(
        0,
        0,
        win_width,
        win_height,
        gl.PixelFormat.GL_RGB,
        gl.PixelType.GL_UNSIGNED_BYTE,
        pixels.unsafe_ptr().unsafe_bitcast[NoneType](),
    )
    var lit = 0
    for value in pixels:
        if value:
            lit += 1
    return lit


def assert_gl_names_are_reused() raises:
    """A leaked buffer or texture keeps its name allocated, so the driver hands out a new one."""
    var positions: List[Vec3f] = [Vec3f(0, 0, 0), Vec3f(1, 0, 0), Vec3f(1, 1, 0)]

    var first_vao = 0
    for cycle in range(RESOURCE_CYCLES):
        var buffer = GraphicsBuffer[DType.uint32, VertexAttributeType.POSITION](positions)
        var texture = Texture("textures/box.png")
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
    var state = AppState(
        Window("stargine smoke test", win_width, win_height, WindowFlags.WINDOW_OPENGL)
    )

    assert_gl_names_are_reused()

    var lit = 0
    for _ in range(FRAMES):
        render(state)
        lit = max(lit, count_lit_pixels())
        state.window.swap()

    assert_true(lit > 0, "the scene rendered no visible pixels")
    print("smoke test passed:", FRAMES, "frames rendered,", lit, "lit subpixels")
    sdl.quit()
