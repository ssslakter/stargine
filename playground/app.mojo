from memory import OwnedPointer
import math
from sys import sizeof
import time
from .texture import load_texture2d
from opengl import BufferTargetARB, VertexAttribPointerType, BufferUsageARB, ShaderType, DrawElementsType, PrimitiveType, ClearBufferMask
import opengl as gl
import sdl
from .linalg import *
from .core import *


alias win_width = 1024
alias win_height = 768


@fieldwise_init
struct Vertex(Copyable & Movable, Writable, WithVertexLayout):
    var position: Vec3f
    var color: Vec4f
    var tex_coords: Vec2f

    fn write_to[W: Writer](self, mut writer: W):
        writer.write("Vertex(position=(", self.position[0], ", ", self.position[1], ", ", self.position[2], "))")
        writer.write(", color=(", self.color[0], ", ", self.color[1], ", ", self.color[2], ", ", self.color[3], "))")
        writer.write(", tex_coords=(", self.tex_coords[0], ", ", self.tex_coords[1], "))")

    @staticmethod
    fn get_layout() -> VertexLayout:
        return VertexLayout(elements=[
            VertexAttribute(total_size=sizeof[Vec3f](), type_size=sizeof[Float32](), type=VertexAttribPointerType.FLOAT, normalized=False),
            VertexAttribute(total_size=sizeof[Vec4f](), type_size=sizeof[Float32](), type=VertexAttribPointerType.FLOAT, normalized=False),
            VertexAttribute(total_size=sizeof[Vec2f](), type_size=sizeof[Float32](), type=VertexAttribPointerType.FLOAT, normalized=False),
        ])

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
    var vbo: VertexBuffer[Vertex]
    var vao: VertexArray
    var ebo: IndexBuffer
    var texture_id: Id
    var shader: Shader
    var fullscreen: Bool
    var start_time: Float64 # start time in milliseconds

    fn __init__(out self, owned window: Window, gl_context: sdl.GLContext):
        self.window = window^
        self.gl_context = gl_context
        self.vbos = []
        self.vaos = []
        self.ebos = []
        self.texture_id = 0
        self.shader = Shader()
        self.fullscreen = False
        self.start_time = time.monotonic()/Float64(1e6)

fn init_buffers(mut state: AppState, vertices: List[Vertex]):


fn init_texture() raises -> Id:
    var texture_id: Id = 0
    gl.gen_textures(1, Ptr(to=texture_id))
    gl.bind_texture(gl.TextureTarget.TEXTURE_2D, texture_id)
    gl.tex_parameteri(gl.TextureTarget.TEXTURE_2D, gl.TextureParameterName.TEXTURE_WRAP_S, Int(gl.TextureWrapMode.MIRRORED_REPEAT))
    gl.tex_parameteri(gl.TextureTarget.TEXTURE_2D, gl.TextureParameterName.TEXTURE_WRAP_T, Int(gl.TextureWrapMode.MIRRORED_REPEAT))
    try:
        image = load_texture2d("wall.jpg")
    except:
        print("Failed to load texture")
        return 0
    shape = image.get_shape()
    width, height, channels = shape[0], shape[1], shape[2]
    gl.tex_image_2d(gl.TextureTarget.TEXTURE_2D, 0, gl.InternalFormat.RGB, width, height, 0, gl.PixelFormat.RGB, gl.PixelType.UNSIGNED_BYTE, image.data.bitcast[NoneType]())
    gl.generate_mipmap(gl.TextureTarget.TEXTURE_2D)
    return texture_id


fn app_init(mut state: AppState) raises:
    gl.viewport(0, 0, win_width, win_height)

    state.texture_id = init_texture()

    # Set up triangles
    state.vbos.append(VertexBuffer[Vertex](triangle))
    state.vaos.append(VertexArray(Vertex.get_layout()))

    state.shader = Shader(vertex_path="shaders/vertex.glsl", fragment_path="shaders/fragment.glsl")^

    # gl.polygon_mode(TriangleFace.FRONT_AND_BACK, PolygonMode.LINE)


fn update(state: AppState) raises:
    t_ms = round(time.monotonic()/Float64(1e6) - state.start_time)
    green = Float32(math.sin(t_ms/2000)/2 + 0.5)
    blue = Float32(math.cos(t_ms/2000)/2 + 0.5)
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
