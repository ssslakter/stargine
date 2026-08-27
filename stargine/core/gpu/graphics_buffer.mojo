from std.memory import unsafe_memcpy
from std.sys import size_of
from ..linalg import Vec2f, Vec3f, Vec4f
from ..utils import Ptr
from .index_buffer import IndexBuffer
from .vertex_array import VertexArray
from .vertex_buffer import VertexBuffer
from .vertex_layout import VertexAttributeType, VertexLayout


def copy_attribute[T: Copyable](mut buffer: List[UInt8], offset: Int, stride: Int, size: Int, values: List[T]):
    """Scatters one attribute across the interleaved buffer with a constant stride."""
    for i in range(len(values)):
        unsafe_memcpy(
            dest=buffer.unsafe_ptr().unsafe_offset(offset + i * stride),
            src=Ptr(to=values[i]).unsafe_bitcast[UInt8](),
            count=size,
        )


def copy_attribute[T: Copyable](
    mut buffer: List[UInt8], offset: Int, stride: Int, size: Int, name: StaticString, src: Optional[List[T]]
) raises:
    if not src:
        raise Error("the vertex layout declares a '", name, "' attribute but the mesh has none")
    copy_attribute(buffer, offset, stride, size, src.value())


struct GraphicsBuffer[index_dtype: DType, *attributes: VertexAttributeType](Copyable, Movable):
    comptime Layout = VertexLayout[*Self.attributes]

    var vao: VertexArray
    var vbo: VertexBuffer[UInt8]
    var ebo: Optional[IndexBuffer[Self.index_dtype]]

    def __init__(
        out self,
        positions: List[Vec3f],
        uvs: Optional[List[Vec2f]] = None,
        normals: Optional[List[Vec3f]] = None,
        colors: Optional[List[Vec4f]] = None,
        indices: Optional[List[Scalar[Self.index_dtype]]] = None,
    ) raises:
        self.vbo = VertexBuffer(
            Self.interleave(positions, uvs, normals, colors), UInt(Self.Layout.stride)
        )
        self.ebo = IndexBuffer(indices.value()) if indices else None
        # The vertex array records the buffer bound above when the attributes are set.
        self.vao = VertexArray()
        self.vao.bind()
        Self.Layout.configure()

    @staticmethod
    def interleave(
        positions: List[Vec3f],
        uvs: Optional[List[Vec2f]],
        normals: Optional[List[Vec3f]],
        colors: Optional[List[Vec4f]],
    ) raises -> List[UInt8]:
        var buffer = List[UInt8](length=Self.Layout.stride * len(positions), fill=0)
        comptime for i in range(Self.Layout.count):
            comptime attribute = Self.attributes[i]
            comptime offset = Self.Layout.offset[i]()
            comptime if attribute == VertexAttributeType.POSITION:
                copy_attribute(buffer, offset, Self.Layout.stride, attribute.size(), positions)
            elif attribute == VertexAttributeType.UV:
                copy_attribute(buffer, offset, Self.Layout.stride, attribute.size(), "uv", uvs)
            elif attribute == VertexAttributeType.NORMAL:
                copy_attribute(buffer, offset, Self.Layout.stride, attribute.size(), "normal", normals)
            else:
                copy_attribute(buffer, offset, Self.Layout.stride, attribute.size(), "color", colors)
        return buffer^

    def draw(self) raises:
        self.vao.bind()
        if self.ebo:
            self.ebo.value().draw()
        else:
            self.vbo.draw()
