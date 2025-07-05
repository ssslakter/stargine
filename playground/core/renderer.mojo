from opengl import TriangleFace, PolygonMode
from .imports import *
from ..linalg import *

fn clear(color: Vec4f):
    gl.clear_color(color.x(), color.y(), color.z(), color.w())
    gl.clear(gl.ClearBufferMask.COLOR_BUFFER_BIT)

fn draw(vao: VertexArray, indices: List[UInt32]):
    vao.bind()
    gl.draw_elements(gl.PrimitiveType.TRIANGLES, len(indices), gl.DrawElementsType.UNSIGNED_INT, indices.unsafe_ptr().bitcast[NoneType]())

fn polygon_mode(face: TriangleFace, mode: PolygonMode):
    gl.polygon_mode(face, mode)
