from .core.linalg import *
from .core.window import *
from .core import *
from .primitives import *
from .ecs.camera import *

alias win_width = 1024
alias win_height = 768


@fieldwise_init
struct AppState(Movable):
    var window: Window
    var cubes: List[Cube]
    var camera: Camera
    var start_time: Float64  # start time in milliseconds
    var last_time: Float64

    fn __init__(out self, owned window: Window) raises:
        self.camera = Camera(position=Vec3f(-10.0, 0.0, 0.0), aspect_ratio=Float32(win_width) / Float32(win_height))
        self.camera.look_at(Vec3f(0.0, 0.0, 0.0))
        self.start_time = time.monotonic() / Float64(1e9)
        self.last_time = self.start_time
        self.window = window^
        # self.cubes=[]
        self.cubes = [
            Cube(material=texture_material(Texture("wall.jpg"))), 
            Cube(material=unlit_material())
            ]
        self.cubes[1].transform.translate(Vec3f(0,2,0))
        for ref cube in self.cubes:
            cube.mesh.to_gpu()

        renderer.init_blend()
        renderer.enable_depth_test()
        gl.viewport(0, 0, win_width, win_height)
        # renderer.polygon_mode(gl.TriangleFace.FRONT_AND_BACK, gl.PolygonMode.LINE)


fn update(mut state: AppState) raises:
    renderer.clear(Vec4f(0.0, 0.2, 0.2, 0.0))
    var current_time = time.monotonic() / 1e9
    var delta_time = current_time - state.last_time
    state.last_time = current_time

    for ref cube in state.cubes:
        cube.transform.rotate(0.0, Float32(delta_time) * (2 * math.pi / 5.0))
        cube.material.value().set_matrix("view", state.camera.get_view_matrix())
        cube.material.value().set_matrix("projection", state.camera.get_projection_matrix())
        cube.draw()

    state.window.swap()


fn texture_reload(mut state: AppState, filename: String) raises:
    fname = filename or state.cubes[0].material.value().textures["texture"].filename
    state.cubes[0].material.value().textures["texture"] = Texture(fname)
