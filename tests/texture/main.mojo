from sdl import InitFlags, WindowFlags
from os import env
from pathlib import Path
from sdl.sdl_events import *
import opengl as gl
from stargine.core.linalg import *
from stargine.core import *
from stargine.core.window import *
from stargine.core.gpu import *


alias win_width = 1024
alias win_height = 768


def main():
    sdl.init(InitFlags.INIT_VIDEO | InitFlags.INIT_EVENTS)

    window = Window(
        "SDL Window",
        win_width,
        win_height,
        WindowFlags.WINDOW_RESIZABLE | WindowFlags.WINDOW_OPENGL,
    )
    init_opengl(window)

    var running = True
    var dispatcher = EventDispatcher()
    dispatcher.append(WindowHandler(window.copy()))

    var positions = [
        Vec3f(0,0,0),
        Vec3f(1,0,0,),
        Vec3f(1,1,0),
        Vec3f(0,1,0),
    ]
    var indices: List[UInt32] = [
        0,1,2,
        0,2,3
    ]
    var uvs = [
        Vec2f(0,0),
        Vec2f(1,0),
        Vec2f(1,1),
        Vec2f(0,1),
    ]

    layout = VertexLayout(
        VertexAttribute(VertexAttributeType.POSITION),
        VertexAttribute(VertexAttributeType.UV),
        )
    vbo = GraphicsBuffer(layout, positions = positions^, indices = indices^, uvs=uvs^)
    shader = Shader(Path(env.getenv("ROOT_DIR"))/'shader.glsl')
    texture = Texture('textures/wall.jpg')
    shader.set_uniform('color', Vec4f(0.3,0.5,0.7,1))
    shader.set_uniform('texture', gl.TextureUnit.TEXTURE0)

    while running:
        running = dispatcher.poll_events()
        if not running:
            break
        
        renderer.clear(Vec4f(0.0, 0.2, 0.2, 0.0))
        shader.use()
        texture.bind(gl.TextureUnit.TEXTURE0)
        vbo.draw()
        window.swap()

    sdl.quit()
