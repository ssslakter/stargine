import math
from sys import sizeof
import time
from .texture import load_texture2d
from opengl import BufferTargetARB, VertexAttribPointerType, BufferUsageARB, ShaderType, DrawElementsType, PrimitiveType, ClearBufferMask
import opengl as gl
import sdl
from .linalg import *


alias win_width = 1024
alias win_height = 768


@fieldwise_init
struct Vertex(Copyable & Movable, Writable):
    var position: Vec3f
    var color: Vec4f
    var tex_coords: Vec2f

    fn write_to[W: Writer](self, mut writer: W):
        writer.write("Vertex(position=(", self.position[0], ", ", self.position[1], ", ", self.position[2], "))")
        writer.write(", color=(", self.color[0], ", ", self.color[1], ", ", self.color[2], ", ", self.color[3], "))")
        writer.write(", tex_coords=(", self.tex_coords[0], ", ", self.tex_coords[1], "))")

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
    var vbos: List[Id]
    var vaos: List[Id]
    var ebos: List[Id]
    var texture_id: Id
    var shader: Shader
    var fullscreen: Bool
    var start_time: Float64 # start time in milliseconds

    fn __init__(out self, owned window: Window, gl_context: sdl.GLContext):
        self.window = window^
        self.gl_context = gl_context
        self.vbos = List[Id](10, 0)
        self.vaos = List[Id](10, 0)
        self.ebos = List[Id](10, 0)
        self.texture_id = 0
        self.shader = Shader()
        self.fullscreen = False
        self.start_time = time.monotonic()/Float64(1e6)

fn init_buffers(vao_id: Id, vbo_id: Id, vertices: List[Vertex]):
    gl.bind_vertex_array(vao_id)
    gl.bind_buffer(BufferTargetARB.ARRAY_BUFFER, vbo_id)
    # gl.bind_buffer(BufferTargetARB.ELEMENT_ARRAY_BUFFER, state.ebos[0])
    gl.buffer_data(BufferTargetARB.ARRAY_BUFFER, sizeof[Vertex]() * 3, vertices.unsafe_ptr().bitcast[NoneType](), BufferUsageARB.STATIC_DRAW)
    # gl.buffer_data(BufferTargetARB.ELEMENT_ARRAY_BUFFER, sizeof[UInt32]() * 3, indices.unsafe_ptr().bitcast[NoneType](), BufferUsageARB.STATIC_DRAW)
    # TODO get rid of hack with offsets
    gl.vertex_attrib_pointer(0, 3, VertexAttribPointerType.FLOAT, False, sizeof[Vertex](), UnsafePointer[NoneType]())
    gl.enable_vertex_attrib_array(0)
    gl.vertex_attrib_pointer(1, 4, VertexAttribPointerType.FLOAT, False, sizeof[Vertex](), UnsafePointer[Vec3f]().offset(1).bitcast[NoneType]())
    gl.enable_vertex_attrib_array(1)
    gl.vertex_attrib_pointer(2, 2, VertexAttribPointerType.FLOAT, False, sizeof[Vertex](), UnsafePointer[Float32]().offset(8).bitcast[NoneType]())
    gl.enable_vertex_attrib_array(2)

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

    gl.gen_vertex_arrays(2, state.vaos.unsafe_ptr())
    gl.gen_buffers(2, state.vbos.unsafe_ptr())
    gl.gen_buffers(2, state.ebos.unsafe_ptr())
    
    state.texture_id = init_texture()
    # Set up triangles
    init_buffers(state.vaos[0], state.vbos[0], triangle)

    state.shader = Shader(vertex_path="shaders/vertex.glsl", fragment_path="shaders/fragment.glsl")

    # gl.polygon_mode(TriangleFace.FRONT_AND_BACK, PolygonMode.LINE)

fn app_cleanup(owned state: AppState):
    gl.delete_vertex_arrays(2, state.vaos.unsafe_ptr())
    gl.delete_buffers(2, state.vbos.unsafe_ptr())
    gl.delete_buffers(2, state.ebos.unsafe_ptr())
    gl.delete_program(state.shader.id)


fn reload_shaders(mut state: AppState) raises:
    gl.delete_program(state.shader.id)
    state.shader = Shader(vertex_path="shaders/vertex.glsl", fragment_path="shaders/fragment.glsl")


fn update(state: AppState) raises:
    t_ms = round(time.monotonic()/Float64(1e6) - state.start_time)
    green = Float32(math.sin(t_ms/2000)/2 + 0.5)
    blue = Float32(math.cos(t_ms/2000)/2 + 0.5)
    state.shader.use()
    state.shader.set_uniform("myColor", Vec4f(0.0, green, blue, 1.0))
    gl.clear_color(0.0, 0.2, 0.2, 0.0)
    gl.clear(ClearBufferMask.COLOR_BUFFER_BIT)

    # Draw first triangle
    gl.bind_texture(gl.TextureTarget.TEXTURE_2D, state.texture_id)
    gl.bind_vertex_array(state.vaos[0])
    gl.draw_arrays(PrimitiveType.TRIANGLES, 0, 3)

    # Draw second triangle
    gl.bind_vertex_array(state.vaos[1])
    gl.draw_arrays(PrimitiveType.TRIANGLES, 0, 3)

    sdl.gl_swap_window(state.window._handle)
