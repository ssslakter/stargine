import opengl as gl
from std.os import env
from std.pathlib import Path
from ..core.cubemap import CubeMap
from ..core.linalg import Mat3f, Mat4f
from ..core.shader import Shader
from ..scene.camera import Camera
from ..scene.mesh import PositionMesh
from .shapes import cube_mesh


def get_shaders_path() raises -> Path:
    return Path(env.getenv("ROOT_DIR")) / "primitives/shaders"


struct Skybox(Copyable, Movable):
    """A cube map drawn around the camera, always at the far plane."""

    var cubemap: CubeMap
    var mesh: PositionMesh
    var shader: Shader

    def __init__(out self, var cubemap: CubeMap) raises:
        self.cubemap = cubemap^
        self.shader = Shader(get_shaders_path() / "skybox.glsl")
        self.mesh = PositionMesh(cube_mesh().positions)
        self.mesh.to_gpu()

    def draw(self, camera: Camera) raises:
        # Drop the translation so the box never moves relative to the camera.
        var view = Mat4f(Mat3f(camera.get_view_matrix()))
        view[3, 3] = 1.0

        gl.depth_func(gl.DepthFunction.GL_LEQUAL)
        gl.cull_face(gl.TriangleFace.GL_FRONT)
        self.shader.use()
        self.shader.set_uniform("view", view)
        self.shader.set_uniform("projection", camera.get_projection_matrix())
        self.cubemap.bind(gl.TextureUnit.GL_TEXTURE0)
        self.shader.set_uniform("skybox", gl.TextureUnit.GL_TEXTURE0)
        self.mesh.draw()
        gl.cull_face(gl.TriangleFace.GL_BACK)
        gl.depth_func(gl.DepthFunction.GL_LESS)
