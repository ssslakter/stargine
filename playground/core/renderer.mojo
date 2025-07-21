from opengl import TriangleFace, PolygonMode
from .imports import *
from .linalg import *

fn clear(color: Vec4f):
    gl.clear_color(color.x(), color.y(), color.z(), color.w())
    gl.clear(gl.ClearBufferMask.COLOR_BUFFER_BIT | gl.ClearBufferMask.DEPTH_BUFFER_BIT)

fn polygon_mode(face: TriangleFace, mode: PolygonMode):
    gl.polygon_mode(face, mode)

fn init_blend():
    gl.enable(gl.EnableCap.BLEND)
    gl.blend_func(gl.BlendingFactor.SRC_ALPHA, gl.BlendingFactor.ONE_MINUS_SRC_ALPHA)

fn enable_depth_test():
    gl.enable(gl.EnableCap.DEPTH_TEST)