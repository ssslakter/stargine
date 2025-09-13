from memory import memset
from ..utils import *
from ..linalg.vector import *
from .index_buffer import *
from .vertex_buffer import *
from .vertex_array import *


fn copy_or_zero[T: Copyable & Movable & Writable](dst: Ptr[UInt8], src_list: Optional[List[T]], index: Int):
    if src_list:
        memcpy(dst, Ptr(to=src_list.value()[index]).bitcast[UInt8](), size_of[T]())
    else:
        memset(dst, 0,  size_of[T]())

fn create_interleaved_buffer(
    layout: VertexLayout,
    vertex_count: UInt,
    positions: Optional[List[Vec3f]] = None,
    colors: Optional[List[Vec4f]] = None,
    uvs: Optional[List[Vec2f]] = None,
    normals: Optional[List[Vec3f]] = None,
) -> List[UInt8]:
    buffer = List[UInt8](length=layout.stride * vertex_count, fill=0)
    for i in range(vertex_count):
        dst = buffer.unsafe_ptr() + i * layout.stride
        for el in layout.elements:
            if el.attr_type == VertexAttributeType.POSITION:
                copy_or_zero(dst, positions, i)
            elif el.attr_type == VertexAttributeType.UV:
                copy_or_zero(dst, uvs, i)
            elif el.attr_type == VertexAttributeType.COLOR:
                copy_or_zero(dst, colors, i)
            elif el.attr_type == VertexAttributeType.NORMAL:
                copy_or_zero(dst, normals, i)
            # add offset
            dst += el.total_size

    return buffer


struct GraphicsBuffer[index_dtype: DType = DType.uint32](Copyable, Movable):
    var vao: VertexArray
    var vbo: VertexBuffer
    var ebo: Optional[IndexBuffer[index_dtype]]

    # OpenGL does not support dtypes other then f32 (without extensions)
    fn __init__(
        out self,
        layout: VertexLayout,
        positions: List[Vec3f],
        colors: Optional[List[Vec4f]] = None,
        uvs: Optional[List[Vec2f]] = None,
        normals: Optional[List[Vec3f]] = None,
        indices: Optional[List[Scalar[index_dtype]]] = None,
    ):
        self.vbo = VertexBuffer(create_interleaved_buffer(layout, len(positions), positions, colors, uvs, normals), UInt(layout.stride))
        if indices:
            self.ebo = IndexBuffer(indices.value())
        else: self.ebo = None
        self.vao = VertexArray(layout)

    fn draw(self):
        self.vao.bind()
        if not self.ebo:
            self.vbo.draw()
        else:
            ebo = self.ebo.value()
            ebo.draw()
