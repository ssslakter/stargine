from memory import OwnedPointer
import math
from sys import sizeof
import time
from opengl import BufferTargetARB, VertexAttribPointerType, BufferUsageARB, ShaderType, DrawElementsType, PrimitiveType, ClearBufferMask
import opengl as gl
import sdl
from .linalg import *
from .core import *


alias win_width = 1024
alias win_height = 768


@fieldwise_init
struct Vertex(Copyable & Movable, WithVertexLayout, Writable):
    var position: Vec3f
    var color: Vec4f
    var tex_coords: Vec2f

    fn write_to[W: Writer](self, mut writer: W):
        writer.write("Vertex(position=(", self.position[0], ", ", self.position[1], ", ", self.position[2], "))")
        writer.write(", color=(", self.color[0], ", ", self.color[1], ", ", self.color[2], ", ", self.color[3], "))")
        writer.write(", tex_coords=(", self.tex_coords[0], ", ", self.tex_coords[1], "))")

    @staticmethod
    fn get_layout() -> VertexLayout:
        return VertexLayout(
            elements=[
                VertexAttribute(sizeof[Vec3f](), DType.float32, num_components=3),
                VertexAttribute(sizeof[Vec4f](), DType.float32, num_components=4),
                VertexAttribute(sizeof[Vec2f](), DType.float32, num_components=2),
            ],
            stride=sizeof[Vertex](),
        )


alias triangle = List[Vertex](
    Vertex(position=Vec3f(-0.5, -0.5, 0.0), color=Vec4f(0.0, 0.0, 1.0, 1.0), tex_coords=Vec2f(0.0, 0.0)),  # Bottom - Blue
    Vertex(position=Vec3f(0.0, 0.5, 0.0), color=Vec4f(1.0, 1.0, 0.0, 1.0), tex_coords=Vec2f(0.5, 1.0)),  # Left - Yellow
    Vertex(position=Vec3f(0.5, -0.5, 0.0), color=Vec4f(1.0, 0.0, 0.0, 1.0), tex_coords=Vec2f(1.0, 0.0)),  # Top - Red
)

alias indices = InlineArray[UInt32, 3](0, 1, 2)


@fieldwise_init
struct AppState(Movable):
    var window: Window
    var gl_context: sdl.GLContext
    var vbos: List[VertexBuffer[Vertex]]
    var vaos: List[VertexArray]
    var ebos: List[IndexBuffer]
    var texture_id: Id
    var shader: Shader
    var fullscreen: Bool
    var start_time: Float64  # start time in milliseconds

    fn __init__(out self, owned window: Window, gl_context: sdl.GLContext):
        self.window = window^
        self.gl_context = gl_context
        self.vbos = []
        self.vaos = []
        self.ebos = []
        self.texture_id = 0
        self.shader = Shader()
        self.fullscreen = False
        self.start_time = time.monotonic() / Float64(1e6)


fn app_init(mut state: AppState) raises:
    gl.viewport(0, 0, win_width, win_height)
    state.texture_id = init_texture("wall.jpg")

    # Set up triangles
    state.vbos.append(VertexBuffer[Vertex](triangle))
    state.vaos.append(VertexArray(Vertex.get_layout()))
    print(sizeof[Vertex]())

    state.shader = Shader(vertex_path="shaders/vertex.glsl", fragment_path="shaders/fragment.glsl")
    # gl.polygon_mode(TriangleFace.FRONT_AND_BACK, PolygonMode.LINE)


fn update(state: AppState) raises:
    t_ms = round(time.monotonic() / Float64(1e6) - state.start_time)
    green = Float32(math.sin(t_ms / 2000) / 2 + 0.5)
    blue = Float32(math.cos(t_ms / 2000) / 2 + 0.5)
    state.shader.bind()
    state.shader.set_uniform("myColor", Vec4f(0.0, green, blue, 1.0))
    gl.clear_color(0.0, 0.2, 0.2, 0.0)
    gl.clear(ClearBufferMask.COLOR_BUFFER_BIT)

    # Draw first triangle
    gl.bind_texture(gl.TextureTarget.TEXTURE_2D, state.texture_id)
    state.vaos[0].bind()
    gl.draw_arrays(PrimitiveType.TRIANGLES, 0, 3)

    # Draw second triangle
    # state.vaos[1].bind()
    # gl.draw_arrays(PrimitiveType.TRIANGLES, 0, 3)

    sdl.gl_swap_window(state.window._handle)
