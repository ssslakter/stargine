import math
from sys import sizeof
import time
from opengl import BufferTargetARB, VertexAttribPointerType, BufferUsageARB, ShaderType, DrawElementsType, PrimitiveType, ClearBufferMask
import opengl as gl
import sdl


alias win_width = 1024
alias win_height = 768


@fieldwise_init
struct Vertex(Copyable & Movable, Writable):
    var position: Vec3
    var color: Vec4

    fn write_to[W: Writer](self, mut writer: W):
        writer.write("Vertex(position=(", self.position[0], ", ", self.position[1], ", ", self.position[2], "))")
        writer.write(", color=(", self.color[0], ", ", self.color[1], ", ", self.color[2], ", ", self.color[3], "))")


alias triangle1 = List[Vertex](
    Vertex(position=Vec3(-0.5, -0.5, 0.0), color=Vec4(0.0, 0.0, 1.0, 1.0)),  # Bottom - Blue
    Vertex(position=Vec3(-0.5, 0.5, 0.0), color=Vec4(1.0, 1.0, 0.0, 1.0)),  # Left - Yellow
    Vertex(position=Vec3(0.5, 0.5, 0.0), color=Vec4(1.0, 0.0, 0.0, 1.0)),  # Top - Red
)

alias triangle2 = List[Vertex](
    Vertex(position=Vec3(-0.5, -0.5, 0.0), color=Vec4(0.0, 1.0, 0.0, 1.0)),
    Vertex(position=Vec3(0.5, 0.5, 0.0), color=Vec4(0.0, 1.0, 0.0, 1.0)),
    Vertex(position=Vec3(0.5, -0.5, 0.0), color=Vec4(0.0, 1.0, 0.0, 1.0)),
)

alias indices = InlineArray[UInt32, 6](0, 1, 2, 0, 2, 3)
alias indices2 = InlineArray[UInt32, 3](0, 2, 3)



@fieldwise_init
struct AppState(Movable):
    var window: Window
    var gl_context: sdl.GLContext
    var vbos: List[Id]
    var vaos: List[Id]
    var ebos: List[Id]
    var shader: Shader
    var fullscreen: Bool
    var start_time: Float64 # start time in milliseconds

    fn __init__(out self, owned window: Window, gl_context: sdl.GLContext):
        self.window = window^
        self.gl_context = gl_context
        self.vbos = List[Id](10, 0)
        self.vaos = List[Id](10, 0)
        self.ebos = List[Id](10, 0)
        self.shader = Shader()
        self.fullscreen = False
        self.start_time = time.monotonic()/Float64(1e6)

fn init_buffers(vao_id: Id, vbo_id: Id, vertices: List[Vertex]):
    gl.bind_vertex_array(vao_id)
    gl.bind_buffer(BufferTargetARB.ARRAY_BUFFER, vbo_id)
    # gl.bind_buffer(BufferTargetARB.ELEMENT_ARRAY_BUFFER, state.ebos[0])
    gl.buffer_data(BufferTargetARB.ARRAY_BUFFER, sizeof[Vertex]() * 3, vertices.unsafe_ptr().bitcast[NoneType](), BufferUsageARB.STATIC_DRAW)
    # gl.buffer_data(BufferTargetARB.ELEMENT_ARRAY_BUFFER, sizeof[UInt32]() * 3, indices.unsafe_ptr().bitcast[NoneType](), BufferUsageARB.STATIC_DRAW)
    gl.vertex_attrib_pointer(0, 3, VertexAttribPointerType.FLOAT, False, sizeof[Vertex](), UnsafePointer[NoneType]())
    gl.enable_vertex_attrib_array(0)
    gl.vertex_attrib_pointer(1, 4, VertexAttribPointerType.FLOAT, False, sizeof[Vertex](), UnsafePointer[Vec3]().offset(1).bitcast[NoneType]())
    gl.enable_vertex_attrib_array(1)


fn app_init(mut state: AppState) raises:
    gl.viewport(0, 0, win_width, win_height)

    gl.gen_vertex_arrays(2, state.vaos.unsafe_ptr())
    gl.gen_buffers(2, state.vbos.unsafe_ptr())
    gl.gen_buffers(2, state.ebos.unsafe_ptr())

    # Set up triangles
    init_buffers(state.vaos[0], state.vbos[0], triangle1)
    init_buffers(state.vaos[1], state.vbos[1], triangle2)

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
    green = math.sin(t_ms/2000)/2 + 0.5
    blue = math.cos(t_ms/2000)/2 + 0.5
    state.shader.use()
    state.shader.set_uniform("myColor", Tuple(Float32(0.0), Float32(green), Float32(blue), Float32(1.0)))
    gl.clear_color(0.0, 0.0, 0.0, 0.0)
    gl.clear(ClearBufferMask.COLOR_BUFFER_BIT)

    # Draw first triangle
    gl.bind_vertex_array(state.vaos[0])
    gl.draw_arrays(PrimitiveType.TRIANGLES, 0, 3)

    # Draw second triangle
    gl.bind_vertex_array(state.vaos[1])
    gl.draw_arrays(PrimitiveType.TRIANGLES, 0, 3)

    sdl.gl_swap_window(state.window._handle)
