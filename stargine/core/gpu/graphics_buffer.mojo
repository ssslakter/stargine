from std.memory import unsafe_memcpy
from std.sys import size_of
from ..linalg import Vec2f, Vec3f, Vec4f
from ..utils import Ptr
from .index_buffer import IndexBuffer
from .vertex_array import VertexArray
from .vertex_buffer import VertexBuffer
from .vertex_layout import VertexAttributeType, VertexLayout


def copy_attribute[T: Copyable](mut buffer: List[UInt8], offset: Int, src: Optional[List[T]], index: Int):
    """Copies one vertex attribute into the interleaved buffer; absent attributes stay zeroed."""
    if src:
        unsafe_memcpy(
            dest=buffer.unsafe_ptr().unsafe_offset(offset),
            src=Ptr(to=src.value()[index]).unsafe_bitcast[UInt8](),
            count=size_of[T](),
        )


def create_interleaved_buffer(
    layout: VertexLayout,
    vertex_count: Int,
    positions: Optional[List[Vec3f]] = None,
    colors: Optional[List[Vec4f]] = None,
    uvs: Optional[List[Vec2f]] = None,
    normals: Optional[List[Vec3f]] = None,
) -> List[UInt8]:
    var buffer = List[UInt8](length=layout.stride * vertex_count, fill=0)
    for i in range(vertex_count):
        var offset = i * layout.stride
        for el in layout.elements:
            if el.attr_type == VertexAttributeType.POSITION:
                copy_attribute(buffer, offset, positions, i)
            elif el.attr_type == VertexAttributeType.UV:
                copy_attribute(buffer, offset, uvs, i)
            elif el.attr_type == VertexAttributeType.COLOR:
                copy_attribute(buffer, offset, colors, i)
            elif el.attr_type == VertexAttributeType.NORMAL:
                copy_attribute(buffer, offset, normals, i)
            offset += el.total_size
    return buffer^


struct GraphicsBuffer[index_dtype: DType = DType.uint32](Copyable, Movable):
    var vao: VertexArray
    var vbo: VertexBuffer[UInt8]
    var ebo: Optional[IndexBuffer[Self.index_dtype]]

    def __init__(
        out self,
        layout: VertexLayout,
        var positions: List[Vec3f],
        colors: Optional[List[Vec4f]] = None,
        uvs: Optional[List[Vec2f]] = None,
        normals: Optional[List[Vec3f]] = None,
        indices: Optional[List[Scalar[Self.index_dtype]]] = None,
    ) raises:
        var vertex_count = len(positions)
        self.vbo = VertexBuffer(
            create_interleaved_buffer(layout, vertex_count, positions^, colors, uvs, normals),
            UInt(layout.stride),
        )
        self.ebo = IndexBuffer(indices.value()) if indices else None
        self.vao = VertexArray(layout)

    def draw(self) raises:
        self.vao.bind()
        if self.ebo:
            self.ebo.value().draw()
        else:
            self.vbo.draw()
