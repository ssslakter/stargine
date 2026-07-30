from std.random import random_float64
import std.time as time
from .core import renderer
from .core.linalg import *
from .core.window import *
from .core import *
from .primitives import *
from .ecs.camera import *
from .ecs.material import *
from .ecs.light import PointLight

comptime win_width = 1024
comptime win_height = 768


@fieldwise_init
struct AppState(Movable):
    var window: Window
    var cubes: List[Cube]
    var light: PointLight
    var light_gizmo: Cube
    var camera: Camera
    var last_frame: Float64  # start time in milliseconds
    var delta_time: Float64

    def __init__(out self, window: Window) raises:
        self.camera = Camera(
            position=Vec3f(-5.0, 1.0, 2.0),
            aspect_ratio=Float32(win_width) / Float32(win_height),
        )
        self.last_frame = self.delta_time = 0
        self.window = window.copy()

        # light
        light_cube = Cube(material=unlit_material())
        light_cube.mesh.to_gpu()
        self.light = PointLight(position=Vec3f(2, 3, 2))
        self.light.transform[].set_scale(0.3)
        self.light_gizmo = light_cube.copy()
        self.light_gizmo.transform = self.light.transform
        self.light_gizmo.material.set_vec("color", Vec4(self.light.specular, 1))

        dir_light = DirectionalLight(
            direction = Vec3f(0, -1, 0)
        )
        # objects
        cube = Cube(
            material=basic_material(
                Texture('textures/box.png'),
                Texture('textures/box_specular.png'),
                point_light=self.light.copy(),
                dir_light=dir_light.copy()
            )
        )
        # cube = Cube(material=texture_material(Texture("wall.jpg")))
        cube.mesh.to_gpu()
        self.cubes = [cube.copy()]

        # post processing
        renderer.init_blend()
        renderer.enable_depth_test()
        gl.viewport(0, 0, win_width, win_height)


def update(mut state: AppState) raises:
    renderer.clear()
    var current_time = Float64(time.monotonic()) / 1e9
    state.delta_time = current_time - state.last_frame
    state.last_frame = current_time

    for ref cube in state.cubes:
        cube.material.set_matrix("view", state.camera.get_view_matrix())
        cube.material.set_matrix(
            "projection", state.camera.get_projection_matrix()
        )
        cube.draw(state.camera)

    state.light_gizmo.material.set_matrix(
        "view", state.camera.get_view_matrix()
    )
    state.light_gizmo.material.set_matrix(
        "projection", state.camera.get_projection_matrix()
    )
    state.light_gizmo.draw(state.camera)
    state.window.swap()


def texture_reload(mut state: AppState, filename: String) raises:
    fname = filename or state.cubes[0].material.textures["texture"].filename
    state.cubes[0].material.textures["texture"] = Texture(fname)
