import opengl as gl
import sdl
from sdl import Event, InitFlags, WindowFlags
from std.os import env
from std.pathlib import Path
from stargine.core import renderer
from stargine.core.events import WindowHandler
from stargine.core.gpu import GraphicsBuffer, OpenGLContext, VertexAttributeType
from stargine.core.linalg import Vec2f, Vec3f, Vec4f
from stargine.core.shader import Shader
from stargine.core.texture import Texture
from stargine.core.window import Window

comptime win_width = 1024
comptime win_height = 768


def main() raises:
    sdl.init(InitFlags.INIT_VIDEO | InitFlags.INIT_EVENTS)

    var window = Window(
        "texture",
        win_width,
        win_height,
        WindowFlags.WINDOW_RESIZABLE | WindowFlags.WINDOW_OPENGL,
    )
    var context = OpenGLContext(window)

    var window_handler = WindowHandler(window.copy())

    var positions: List[Vec3f] = [
        Vec3f(0, 0, 0),
        Vec3f(1, 0, 0),
        Vec3f(1, 1, 0),
        Vec3f(0, 1, 0),
    ]
    var indices: List[UInt32] = [0, 1, 2, 0, 2, 3]
    var uvs: List[Vec2f] = [
        Vec2f(0, 0),
        Vec2f(1, 0),
        Vec2f(1, 1),
        Vec2f(0, 1),
    ]

    var buffer = GraphicsBuffer[
        DType.uint32, VertexAttributeType.POSITION, VertexAttributeType.UV
    ](positions, uvs=uvs^, indices=indices^)
    var shader = Shader(Path(env.getenv("TEST_DIR")) / "shader.glsl")
    var texture = Texture("textures/wall.jpg")
    shader.set_uniform("color", Vec4f(0.3, 0.5, 0.7, 1))
    shader.set_uniform("texture", gl.TextureUnit.GL_TEXTURE0)

    var event = Event(UInt32(0))
    var running = True

    while running:
        while sdl.poll_event(Pointer(to=event)):
            running &= window_handler.handle(event)
        if not running:
            break
        renderer.clear(Vec4f(0.0, 0.2, 0.2, 0.0))
        shader.use()
        texture.bind(gl.TextureUnit.GL_TEXTURE0)
        buffer.draw()
        window.swap()

    _ = context^
    sdl.quit()
