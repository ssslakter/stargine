import opengl as gl
import std.time as time
from .core import renderer
from .core.gpu import OpenGLContext
from .core.linalg import Vec3f, Vec4
from .core.texture import Texture
from .core.window import Window
from .ecs.camera import Camera
from .ecs.light import DirectionalLight, PointLight
from .ecs.material import basic_material, unlit_material
from .primitives import Cube

comptime win_width = 1024
comptime win_height = 768


struct AppState(Movable):
    # Fields are destroyed in declaration order, so every GL resource is listed
    # before the context and the window that keep those resources valid.
    var cubes: List[Cube]
    var light: PointLight
    var light_gizmo: Cube
    var camera: Camera
    var last_frame: Float64
    var delta_time: Float64
    var gl_context: OpenGLContext
    var window: Window

    def __init__(out self, var window: Window) raises:
        self.window = window^
        self.gl_context = OpenGLContext(self.window)
        self.camera = Camera(
            position=Vec3f(-5.0, 1.0, 2.0),
            aspect_ratio=Float32(win_width) / Float32(win_height),
        )
        self.last_frame = 0
        self.delta_time = 0

        self.light = PointLight(position=Vec3f(2, 3, 2))
        self.light.transform[].set_scale(0.3)

        var gizmo = Cube(material=unlit_material())
        gizmo.mesh.to_gpu()
        gizmo.transform = self.light.transform
        gizmo.material.set_vec("color", Vec4(self.light.specular, 1))
        self.light_gizmo = gizmo^

        var cube = Cube(
            material=basic_material(
                Texture("textures/box.png"),
                Texture("textures/box_specular.png"),
                point_light=self.light.copy(),
                dir_light=DirectionalLight(direction=Vec3f(0, -1, 0)),
            )
        )
        cube.mesh.to_gpu()
        self.cubes = [cube^]

        renderer.init_blend()
        renderer.enable_depth_test()
        gl.viewport(0, 0, win_width, win_height)


def render(mut state: AppState) raises:
    """Draws one frame into the back buffer, without presenting it."""
    renderer.clear()
    var current_time = Float64(time.monotonic()) / 1e9
    state.delta_time = current_time - state.last_frame
    state.last_frame = current_time

    var view = state.camera.get_view_matrix()
    var projection = state.camera.get_projection_matrix()

    for ref cube in state.cubes:
        cube.material.set_matrix("view", view)
        cube.material.set_matrix("projection", projection)
        cube.draw(state.camera)

    state.light_gizmo.material.set_matrix("view", view)
    state.light_gizmo.material.set_matrix("projection", projection)
    state.light_gizmo.draw(state.camera)


def update(mut state: AppState) raises:
    render(state)
    state.window.swap()
