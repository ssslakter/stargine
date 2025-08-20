from random import random_float64
from .core.linalg import *
from .core.window import *
from .core import *
from .primitives import *
from .ecs.camera import *
from .ecs.material import *
from .ecs.light import PointLight

alias win_width = 1024
alias win_height = 768


@fieldwise_init
struct AppState(Movable):
    var window: Window
    var cubes: List[Cube]
    var light: PointLight
    var camera: Camera
    var last_frame: Float64  # start time in milliseconds
    var delta_time: Float64

    fn __init__(out self, window: Window) raises:
        self.camera = Camera(
            position=Vec3f(-5.0, 1.0, 2.0),
            aspect_ratio=Float32(win_width) / Float32(win_height),
        )
        self.last_frame = self.delta_time = 0
        self.window = window

        # light
        light_cube = Cube(material=unlit_material())
        light_cube.mesh.to_gpu()
        self.light = PointLight(light_cube, position=Vec3f(2, 3, 2))
        self.light.transform[].set_scale(0.3)

        # objects
        cube = Cube(
            material=lighted_material(
                self.light,
                ambient=Vec3f(1, 0.5, 0.31),
                diffuse=Vec3f(1, 0.5, 0.31),
            )
        )
        # cube = Cube(material=texture_material(Texture("wall.jpg")))
        cube.mesh.to_gpu()

        # little fun with shaders
        # material = custom_material(
        #     Shader("./stargine/custom_shaders/random.glsl")
        # )
        # material.set_vec("light", Vec4f(1))
        # material.set_vec("color", Vec4f(0.4, 0,0,1))
        # custom_cube = Cube(material=material^, mesh_data=cube.mesh)
        # custom_cube.transform[].translate(Vec3f(3, 0, 0))
        self.cubes = [cube]

        # post processing
        renderer.init_blend()
        renderer.enable_depth_test()
        gl.viewport(0, 0, win_width, win_height)
        # renderer.polygon_mode(gl.TriangleFace.FRONT_AND_BACK, gl.PolygonMode.LINE)


fn update(mut state: AppState) raises:
    renderer.clear()
    var current_time = time.monotonic() / 1e9
    state.delta_time = current_time - state.last_frame
    state.last_frame = current_time
    # state.cubes[-1].material.set_scalar('seed', Float32(random_float64()))
    var light_color = Vec3f(math.sin((Vec3f(2, 0.7, 1.3)*Float32(current_time)).data))
    for ref cube in state.cubes:
        cube.material.set_matrix("view", state.camera.get_view_matrix())
        cube.material.set_matrix(
            "projection", state.camera.get_projection_matrix()
        )
        cube.material.set_vec("light.ambient", light_color)
        cube.draw(state.camera)

    state.light.gizmo.material.set_vec(
        "color", Vec4f(light_color, 1.0)
    )        
    state.light.gizmo.material.set_matrix(
        "view", state.camera.get_view_matrix()
    )
    state.light.gizmo.material.set_matrix(
        "projection", state.camera.get_projection_matrix()
    )
    state.light.gizmo.draw(state.camera)
    state.window.swap()


fn texture_reload(mut state: AppState, filename: String) raises:
    fname = filename or state.cubes[0].material.textures["texture"].filename
    state.cubes[0].material.textures["texture"] = Texture(fname)
