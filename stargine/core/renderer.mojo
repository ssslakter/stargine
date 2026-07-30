from opengl import TriangleFace, PolygonMode
from .imports import *
from .linalg import *

def clear(color: Vec4f = Vec4f(0)) raises:
    gl.clear_color(color.x(), color.y(), color.z(), color.w())
    gl.clear(gl.ClearBufferMask.GL_COLOR_BUFFER_BIT | gl.ClearBufferMask.GL_DEPTH_BUFFER_BIT)

def polygon_mode(face: TriangleFace, mode: PolygonMode) raises:
    gl.polygon_mode(face, mode)

def init_blend() raises:
    gl.enable(gl.EnableCap.GL_BLEND)
    gl.blend_func(gl.BlendingFactor.GL_SRC_ALPHA, gl.BlendingFactor.GL_ONE_MINUS_SRC_ALPHA)

def enable_depth_test() raises:
    gl.enable(gl.EnableCap.GL_DEPTH_TEST)
    gl.front_face(gl.FrontFaceDirection.GL_CCW)
    gl.enable(gl.EnableCap.GL_CULL_FACE)
    gl.cull_face(gl.TriangleFace.GL_BACK)
