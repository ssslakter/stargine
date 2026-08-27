import opengl as gl
from std.memory import ArcPointer
from std.sys import size_of
from ..utils import Ptr
from .objects import BufferName


struct IndexBuffer[dtype: DType](Copyable, Movable, Sized):
    var name: ArcPointer[BufferName]
    var numel: UInt

    def __init__(out self, data: List[Scalar[Self.dtype]]) raises:
        comptime assert Self.dtype.is_unsigned(), "dtype must be unsigned"
        self.name = ArcPointer(BufferName())
        self.numel = UInt(len(data))
        self.bind()
        gl.buffer_data(
            gl.BufferTargetARB.GL_ELEMENT_ARRAY_BUFFER,
            size_of[Self.dtype]() * len(data),
            data.unsafe_ptr().unsafe_bitcast[NoneType](),
            gl.BufferUsageARB.GL_STATIC_DRAW,
        )

    def __len__(self) -> Int:
        return Int(self.numel)

    def bind(self) raises:
        gl.bind_buffer(gl.BufferTargetARB.GL_ELEMENT_ARRAY_BUFFER, self.name[].id)

    def unbind(self) raises:
        gl.bind_buffer(gl.BufferTargetARB.GL_ELEMENT_ARRAY_BUFFER, 0)

    def draw(self) raises:
        self.bind()
        var offset: Optional[Ptr[NoneType, ImmutAnyOrigin]] = None
        gl.draw_elements(gl.PrimitiveType.GL_TRIANGLES, Int32(self.numel), gl.DrawElementsType.GL_UNSIGNED_INT, offset)
        self.unbind()
