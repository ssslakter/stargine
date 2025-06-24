import time
from sys import sizeof
from sdl import InitFlags, WindowFlags, Event, CommonEvent, EventType, WindowEvent, MouseMotionEvent
from playground.utils import *
from playground.window import *
import opengl as gl
from opengl import BufferTargetARB, VertexAttribPointerType, BufferUsageARB, ShaderType, DrawElementsType, PrimitiveType, ClearBufferMask

alias win_width = 1024
alias win_height = 768


@fieldwise_init
struct Vertex(Copyable & Movable, Writable):
    var position: Vec3
    var color: Vec4

    fn write_to[W: Writer](self, mut writer: W):
        writer.write("Vertex(position=(", self.position[0], ", ", self.position[1], ", ", self.position[2], "))")
        writer.write(", color=(", self.color[0], ", ", self.color[1], ", ", self.color[2], ", ", self.color[3], "))")


def read_file(path: String) -> String:
    with open(path, "r") as file:
        return file.read()


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

alias Id = UInt32


@fieldwise_init
struct AppState(Movable):
    var window: Window
    var gl_context: sdl.GLContext
    var vbos: List[Id]
    var vaos: List[Id]
    var ebos: List[Id]
    var shader: Id
    var fullscreen: Bool

    fn __init__(out self, owned window: Window, gl_context: sdl.GLContext):
        self.window = window^
        self.gl_context = gl_context
        self.vbos = List[Id](10, 0)
        self.vaos = List[Id](10, 0)
        self.ebos = List[Id](10, 0)
        self.shader = 0
        self.fullscreen = False


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

    vertex_src = read_file("shaders/vertex.glsl")
    vertex_shader = gl.create_shader(ShaderType.VERTEX_SHADER)
    var cstr_ptr = vertex_src.unsafe_cstr_ptr().origin_cast[origin=MutableAnyOrigin]()
    gl.shader_source(vertex_shader, 1, Ptr(to=cstr_ptr).origin_cast[mut=False](), UnsafePointer[Int32]())
    gl.compile_shader(vertex_shader)

    fragment_src = read_file("shaders/fragment.glsl")
    fragment_shader = gl.create_shader(ShaderType.FRAGMENT_SHADER)
    cstr_ptr = fragment_src.unsafe_cstr_ptr().origin_cast[origin=MutableAnyOrigin]()
    gl.shader_source(fragment_shader, 1, Ptr(to=cstr_ptr).origin_cast[mut=False](), UnsafePointer[Int32]())
    gl.compile_shader(fragment_shader)

    state.shader = gl.create_program()
    gl.attach_shader(state.shader, vertex_shader)
    gl.attach_shader(state.shader, fragment_shader)
    gl.link_program(state.shader)
    gl.delete_shader(vertex_shader)
    gl.delete_shader(fragment_shader)
    # gl.polygon_mode(TriangleFace.FRONT_AND_BACK, PolygonMode.LINE)


fn app_iterate(state: AppState) raises:
    gl.clear_color(0.0, 0.0, 0.0, 0.0)
    gl.clear(ClearBufferMask.COLOR_BUFFER_BIT)
    gl.use_program(state.shader)

    # Draw first triangle
    gl.bind_vertex_array(state.vaos[0])
    gl.draw_arrays(PrimitiveType.TRIANGLES, 0, 3)

    # Draw second triangle
    gl.bind_vertex_array(state.vaos[1])
    gl.draw_arrays(PrimitiveType.TRIANGLES, 0, 3)

    sdl.gl_swap_window(state.window._handle)
    gl.bind_vertex_array(0)


def main_loop(state: AppState):
    var running = True
    var dragging = False
    var drag_offset_x: Float32 = 0.0
    var drag_offset_y: Float32 = 0.0

    while running:
        var event = Event(UInt32(0))
        while sdl.poll_event(Ptr(to=event)):
            if event[CommonEvent].type == Int(EventType.EVENT_QUIT):
                running = False
                break  # Exit event polling loop
            # Handle window resize
            if event[CommonEvent].type == Int(EventType.EVENT_WINDOW_RESIZED):
                window_event = event[WindowEvent]
                new_width = window_event.data1
                new_height = window_event.data2
                gl.viewport(0, 0, new_width, new_height)
            if event[CommonEvent].type == Int(EventType.EVENT_MOUSE_BUTTON_DOWN):
                mouse_event = event[MouseMotionEvent]
                dragging = True
                drag_offset_x = mouse_event.x
                drag_offset_y = mouse_event.y
            elif event[CommonEvent].type == Int(EventType.EVENT_MOUSE_BUTTON_UP):
                dragging = False
            elif event[CommonEvent].type == Int(EventType.EVENT_MOUSE_MOTION) and dragging:
                mouse_event = event[MouseMotionEvent]
                mouse_x = mouse_event.x
                mouse_y = mouse_event.y
                # Get current window position
                win_x, win_y = Int32(0), Int32(0)
                sdl.get_window_position(state.window._handle, Ptr(to=win_x), Ptr(to=win_y))
                # Set new position
                sdl.set_window_position(state.window._handle, Int32(Float32(win_x) + Float32(mouse_x - drag_offset_x)), Int32(Float32(win_y) + Float32(mouse_y - drag_offset_y)))
        if not running:
            break
        app_iterate(state)


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
    context = sdl.gl_create_context(window._handle)
    if not context:
        raise Error("Failed to create OpenGL context. Unsupported OpenGL version.")

    sdl.gl_make_current(window._handle, context)
    gl.init_opengl(sdl.gl_get_proc_address)
    state = AppState(window^, context)

    app_init(state)
    main_loop(state)

    gl.delete_vertex_arrays(2, state.vaos.unsafe_ptr())
    gl.delete_buffers(2, state.vbos.unsafe_ptr())
    gl.delete_buffers(2, state.ebos.unsafe_ptr())
    gl.delete_program(state.shader)

    sdl.quit()
