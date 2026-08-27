import opengl as gl
from std.memory import ArcPointer
from std.sys import size_of
from ..utils import Ptr
from .objects import BufferName


struct VertexBuffer[T: Copyable = UInt8](Copyable, Movable, Sized):
    var name: ArcPointer[BufferName]
    var numel: UInt

    def __init__(out self, data: List[Self.T], vertex_full_size: Optional[UInt] = None) raises:
        self.name = ArcPointer(BufferName())
        var vertex_size = vertex_full_size.or_else(UInt(size_of[Self.T]()))
        self.numel = UInt(len(data) * size_of[Self.T]()) // vertex_size
        self.bind()
        gl.buffer_data(
            gl.BufferTargetARB.GL_ARRAY_BUFFER,
            Int(vertex_size * self.numel),
            data.unsafe_ptr().unsafe_bitcast[NoneType](),
            gl.BufferUsageARB.GL_STATIC_DRAW,
        )

    def __len__(self) -> Int:
        return Int(self.numel)

    def bind(self) raises:
        gl.bind_buffer(gl.BufferTargetARB.GL_ARRAY_BUFFER, self.name[].id)

    def unbind(self) raises:
        gl.bind_buffer(gl.BufferTargetARB.GL_ARRAY_BUFFER, 0)

    def draw(self) raises:
        self.bind()
        gl.draw_arrays(gl.PrimitiveType.GL_TRIANGLES, 0, Int32(len(self)))
        self.unbind()
