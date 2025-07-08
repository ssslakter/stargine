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


alias vertices = List[Vertex](
    Vertex(position=Vec3f(-0.5, -0.5, -0.5), color=Vec4f(1.0, 1.0, 1.0, 1.0), tex_coords=Vec2f(0.0, 0.0)),
    Vertex(position=Vec3f( 0.5, -0.5, -0.5), color=Vec4f(1.0, 1.0, 1.0, 1.0), tex_coords=Vec2f(1.0, 0.0)),
    Vertex(position=Vec3f( 0.5,  0.5, -0.5), color=Vec4f(1.0, 1.0, 1.0, 1.0), tex_coords=Vec2f(1.0, 1.0)),
    Vertex(position=Vec3f(-0.5,  0.5, -0.5), color=Vec4f(1.0, 1.0, 1.0, 1.0), tex_coords=Vec2f(0.0, 1.0)),

    Vertex(position=Vec3f(-0.5, -0.5,  0.5), color=Vec4f(1.0, 1.0, 1.0, 1.0), tex_coords=Vec2f(0.0, 0.0)),
    Vertex(position=Vec3f( 0.5, -0.5,  0.5), color=Vec4f(1.0, 1.0, 1.0, 1.0), tex_coords=Vec2f(1.0, 0.0)),
    Vertex(position=Vec3f( 0.5,  0.5,  0.5), color=Vec4f(1.0, 1.0, 1.0, 1.0), tex_coords=Vec2f(1.0, 1.0)),
    Vertex(position=Vec3f(-0.5,  0.5,  0.5), color=Vec4f(1.0, 1.0, 1.0, 1.0), tex_coords=Vec2f(0.0, 1.0)),
)

alias indices = List[UInt32](
    1, 5, 6,
    6, 2, 1,

    3, 7, 6,
    6, 2, 3,

    4, 5, 6,
    6, 7, 4
)


@fieldwise_init
struct AppState(Movable):
    var window: Window
    var vaos: List[VertexArray[Vertex]]
    var textures: List[Texture]
    var shaders: List[Shader]
    var fullscreen: Bool
    var start_time: Float64  # start time in milliseconds

    fn __init__(out self, owned window: Window):
        self.window = window^
        self.vaos = []
        self.textures = []
        self.shaders = []
        self.fullscreen = False
        self.start_time = time.monotonic() / Float64(1e6)


fn app_init(mut state: AppState) raises:
    renderer.init_blend()
    gl.viewport(0, 0, win_width, win_height)
    state.textures.append(Texture("glasses.png"))
    state.textures.append(Texture("wall.jpg"))
    var shader = Shader(vertex_path="shaders/vertex.glsl", fragment_path="shaders/fragment.glsl")
    shader.set_uniform("texture1", gl.TextureUnit.TEXTURE0)
    shader.set_uniform("texture2", gl.TextureUnit.TEXTURE1)
    state.shaders.append(shader)

    var vbo = VertexBuffer[Vertex](vertices)
    var ebo = IndexBuffer(indices)
    state.vaos.append(VertexArray(Vertex.get_layout(), vbo, ebo))

    # renderer.polygon_mode(gl.TriangleFace.FRONT_AND_BACK, gl.PolygonMode.LINE)
    state.shaders[0].use()
    state.textures[0].bind(gl.TextureUnit.TEXTURE0)
    state.textures[1].bind(gl.TextureUnit.TEXTURE1)

    var model = Mat4f.diag(1.0)
    model = translate(model, Vec3f(0.0, 0.0, -3.0))
    var view = Mat4f.diag(1.0)
    view = translate(view, Vec3f(0.0, 0.0, -3.0))
    var projection = Mat4f.diag(1.0)
    projection = perspective(projection, math.pi/4, Float32(win_width) / Float32(win_height), 0.1, 100.0)
    state.shaders[0].set_uniform("model", model)
    state.shaders[0].set_uniform("view", view)
    state.shaders[0].set_uniform("projection", projection)




fn update(mut state: AppState) raises:
    t_ms = round(time.monotonic() / Float64(1e6) - state.start_time)
    green = Float32(math.sin(t_ms / 2000) / 2 + 0.5)
    blue = Float32(math.cos(t_ms / 2000) / 2 + 0.5)
    renderer.clear(Vec4f(0.0, 0.2, 0.2, 0.0))
    
    state.shaders[0].set_uniform("myColor", Vec4f(0.0, green, blue, 1.0))


    state.vaos[0].draw()

    state.window.swap()


fn texture_reload(mut state: AppState, filename: String) raises:
    fname = filename or state.textures[0].filename
    state.textures[0] = Texture(fname)
