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


@fieldwise_init
struct AppState(Movable):
    var window: Window
    var gl_context: sdl.GLContext
    var vaos: List[VertexArray[Vertex]]
    var texture_id: Id
    var shader: Shader
    var fullscreen: Bool
    var start_time: Float64  # start time in milliseconds

    fn __init__(out self, owned window: Window, gl_context: sdl.GLContext):
        self.window = window^
        self.gl_context = gl_context
        self.vaos = []
        self.texture_id = 0
        self.shader = Shader()
        self.fullscreen = False
        self.start_time = time.monotonic() / Float64(1e6)


fn app_init(mut state: AppState) raises:
    gl.viewport(0, 0, win_width, win_height)
    state.texture_id = init_texture("wall.jpg")

    # Set up triangles
    state.vaos.append(VertexArray(Vertex.get_layout(), VertexBuffer[Vertex](triangle)))
    print(sizeof[Vertex]())

    state.shader = Shader(vertex_path="shaders/vertex.glsl", fragment_path="shaders/fragment.glsl")
    # renderer.polygon_mode(gl.TriangleFace.FRONT_AND_BACK, gl.PolygonMode.LINE)


fn update(state: AppState) raises:
    t_ms = round(time.monotonic() / Float64(1e6) - state.start_time)
    green = Float32(math.sin(t_ms / 2000) / 2 + 0.5)
    blue = Float32(math.cos(t_ms / 2000) / 2 + 0.5)
    state.shader.bind()
    state.shader.set_uniform("myColor", Vec4f(0.0, green, blue, 1.0))
    renderer.clear(Vec4f(0.0, 0.2, 0.2, 0.0))

    # Draw first triangle
    gl.bind_texture(gl.TextureTarget.TEXTURE_2D, state.texture_id)
    state.vaos[0].draw()

    state.window.swap()
