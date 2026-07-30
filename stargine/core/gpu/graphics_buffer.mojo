from std.memory import unsafe_memcpy, unsafe_memset
from ..utils import *
from ..linalg.vector import *
from .index_buffer import *
from .vertex_buffer import *
from .vertex_array import *


def copy_or_zero[T: Copyable & Movable & Writable](dst: UnsafePointer[UInt8, MutAnyOrigin], src_list: Optional[List[T]], index: Int):
    if src_list:
        unsafe_memcpy(dest=dst, src=UnsafePointer[UInt8, ImmutAnyOrigin](unsafe_from_address=Int(Ptr(to=src_list.value()[index]))), count=size_of[T]())
    else:
        unsafe_memset(dst, 0, size_of[T]())

def create_interleaved_buffer(
    layout: VertexLayout,
    vertex_count: UInt,
    positions: Optional[List[Vec3f]] = None,
    colors: Optional[List[Vec4f]] = None,
    uvs: Optional[List[Vec2f]] = None,
    normals: Optional[List[Vec3f]] = None,
) -> List[UInt8]:
    buffer = List[UInt8](length=layout.stride * Int(vertex_count), fill=0)
    for i in range(vertex_count):
        dst = UnsafePointer[UInt8, MutAnyOrigin](unsafe_from_address=Int(buffer.unsafe_ptr()) + Int(i) * layout.stride)
        for el in layout.elements:
            if el.attr_type == VertexAttributeType.POSITION:
                copy_or_zero(dst, positions, Int(i))
            elif el.attr_type == VertexAttributeType.UV:
                copy_or_zero(dst, uvs, Int(i))
            elif el.attr_type == VertexAttributeType.COLOR:
                copy_or_zero(dst, colors, Int(i))
            elif el.attr_type == VertexAttributeType.NORMAL:
                copy_or_zero(dst, normals, Int(i))
            # add offset
            dst += el.total_size

    return buffer^


struct GraphicsBuffer[index_dtype: DType = DType.uint32](Copyable, Movable):
    var vao: VertexArray
    var vbo: VertexBuffer[UInt8]
    var ebo: Optional[IndexBuffer[Self.index_dtype]]

    # OpenGL does not support dtypes other then f32 (without extensions)
    def __init__(
        out self,
        layout: VertexLayout,
        var positions: List[Vec3f],
        colors: Optional[List[Vec4f]] = None,
        uvs: Optional[List[Vec2f]] = None,
        normals: Optional[List[Vec3f]] = None,
        indices: Optional[List[Scalar[Self.index_dtype]]] = None,
    ) raises:
        self.vbo = VertexBuffer(create_interleaved_buffer(layout, UInt(len(positions)), positions^, colors, uvs, normals), UInt(layout.stride))
        if indices:
            self.ebo = IndexBuffer(indices.value())
        else: self.ebo = None
        self.vao = VertexArray(layout)

    def draw(self) raises:
        self.vao.bind()
        if not self.ebo:
            self.vbo.draw()
        else:
            self.ebo.value().draw()
