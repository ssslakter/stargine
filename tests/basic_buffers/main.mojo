from sdl import InitFlags, WindowFlags
from os import env
from pathlib import Path
from sdl.sdl_events import *
import opengl as gl
from playground.core.linalg import *
from playground.core import *
from playground.core.window import *
from playground.core.gpu import *


alias win_width = 1024
alias win_height = 768


def main():
    sdl.init(InitFlags.INIT_VIDEO | InitFlags.INIT_EVENTS)

    sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_PROFILE_MASK, Int(sdl.GLProfile.GL_CONTEXT_PROFILE_CORE))
    sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_MAJOR_VERSION, 4)
    sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_MINOR_VERSION, 2)
    sdl.gl_set_attribute(sdl.GLAttr.GL_DOUBLEBUFFER, 1)

    window = Window(
        "SDL Window",
        win_width,
        win_height,
        WindowFlags.WINDOW_RESIZABLE | WindowFlags.WINDOW_OPENGL,
    )
    context = sdl.gl_create_context(window._handle[])
    if not context:
        raise Error("Failed to create OpenGL context. Unsupported OpenGL version.")

    sdl.gl_make_current(window._handle[], context)
    gl.init_opengl(sdl.gl_get_proc_address)


    var running = True
    var dispatcher = EventDispatcher()
    dispatcher.append(WindowHandler(window))

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

    layout = VertexLayout(VertexAttribute(VertexAttributeType.POSITION))
    vbo = GraphicsBuffer(layout, positions = positions, indices = indices)
    shader = Shader(Path(env.getenv("ROOT_DIR"))/'shader.glsl')
    shader.set_uniform('color', Vec4f(0.3,0.5,0.7,1))

    while running:
        running = dispatcher.poll_events()
        if not running:
            break
        
        renderer.clear(Vec4f(0.0, 0.2, 0.2, 0.0))
        shader.use()
        vbo.draw()
        window.swap()

    sdl.quit()
