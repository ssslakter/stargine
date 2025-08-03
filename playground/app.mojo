from .core.linalg import *
from .core.window import *
from .core import *
from .primitives import *
from .ecs.camera import *

alias win_width = 1024
alias win_height = 768


struct ControlsState(Copyable & Movable):
    alias move_speed = 5.0

    var forward: Bool
    var backward: Bool
    var left: Bool
    var right: Bool
    var up: Bool
    var down: Bool

    fn __init__(out self):
        self.forward = False
        self.backward = False
        self.left = False
        self.right = False
        self.up = False
        self.down = False



@fieldwise_init
struct AppState(Movable):
    var window: Window
    var cubes: List[Cube]
    var camera: Camera
    var last_frame: Float64  # start time in milliseconds
    var delta_time: Float64
    var controls_state: ControlsState

    fn __init__(out self, window: Window) raises:
        self.controls_state = ControlsState()
        self.camera = Camera(position=Vec3f(-10.0, 0.0, 0.0), aspect_ratio=Float32(win_width) / Float32(win_height))
        self.last_frame = self.delta_time = 0
        self.window = window
        # cube = Cube(material=unlit_material())
        cube = Cube(material=texture_material(Texture("wall.jpg")))
        cube.mesh.to_gpu()
        positions = [Vec3f(i) for i in range(10)]
        self.cubes = []
        for p in positions:
            new = cube.copy()
            new.transform.translate(p)
            self.cubes.append(new)

        renderer.init_blend()
        renderer.enable_depth_test()
        gl.viewport(0, 0, win_width, win_height)
        # renderer.polygon_mode(gl.TriangleFace.FRONT_AND_BACK, gl.PolygonMode.LINE)

    fn update_movement(mut self):
        ref cam = self.camera
        delta_time = self.delta_time
        pos_delta = Float32(delta_time * ControlsState.move_speed)

        controls = self.controls_state
        if controls.forward:
            cam.transform.translate(cam.get_forward() * pos_delta)
        if controls.backward:
            cam.transform.translate(cam.get_forward() * -pos_delta)
        if controls.left:
            cam.transform.translate(cam.get_right() * -pos_delta)
        if controls.right:
            cam.transform.translate(cam.get_right() * pos_delta)
        if controls.up:
            cam.transform.translate(Vec3f(0.0, 1.0, 0.0) * pos_delta)
        if controls.down:
            cam.transform.translate(Vec3f(0.0, -1.0, 0.0) * pos_delta)



fn update(mut state: AppState) raises:
    state.update_movement()
    renderer.clear(Vec4f(0.0, 0.2, 0.2, 0.0))
    var current_time = time.monotonic() / 1e9
    state.delta_time = current_time - state.last_frame
    state.last_frame = current_time
    var idx = 0
    for ref cube in state.cubes:
        if idx%3 == 0:
            cube.transform.rotate(0.0, Float32(state.delta_time) * (2 * math.pi / 5.0))
        cube.material.set_matrix("view", state.camera.get_view_matrix())
        cube.material.set_matrix("projection", state.camera.get_projection_matrix())
        cube.draw()
        idx+=1

    state.window.swap()



fn texture_reload(mut state: AppState, filename: String) raises:
    fname = filename or state.cubes[0].material.textures["texture"].filename
    state.cubes[0].material.textures["texture"] = Texture(fname)
