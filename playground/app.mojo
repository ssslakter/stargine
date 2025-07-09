from .linalg import *
from .core import *
from .primitives import *
from .camera import *

alias win_width = 1024
alias win_height = 768

@fieldwise_init
struct AppState(Movable):
    var window: Window
    var cubes: List[Cube]
    var camera: Camera
    var start_time: Float64  # start time in milliseconds

    fn __init__(out self, owned window: Window) raises:
        self.camera = Camera(position=Vec3f(-10.0, 0.0, 0.0), aspect_ratio=Float32(win_width) / Float32(win_height))
        self.camera.look_at(Vec3f(0.0, 0.0, 0.0))
        self.start_time = time.monotonic() / Float64(1e6)
        self.window = window^
        self.cubes = [Cube(material=unlit_material())]
        for ref cube in self.cubes:
            cube.mesh.bind()

        renderer.init_blend()
        gl.viewport(0, 0, win_width, win_height)
        # renderer.polygon_mode(gl.TriangleFace.FRONT_AND_BACK, gl.PolygonMode.LINE)

fn update(mut state: AppState) raises:
    renderer.clear(Vec4f(0.0, 0.2, 0.2, 0.0))

    for ref cube in state.cubes:
        cube.material.value().set_matrix("view", state.camera.get_view_matrix())
        cube.material.value().set_matrix("projection", state.camera.get_projection_matrix())
        cube.draw()

    state.window.swap()


fn texture_reload(mut state: AppState, filename: String) raises:
    fname = filename or state.cubes[0].material.value().textures["texture1"].filename
    state.cubes[0].material.value().textures["texture1"] = Texture(fname)
