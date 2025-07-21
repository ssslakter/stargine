from ..utils import *
from .vertex_layout import *


struct VertexBuffer[T: Copyable & Movable = UInt8](Copyable, Movable, Sized):
    var id: ArcPointer[Id]
    var numel: UInt

    fn __init__(out self, data: List[T], vertex_full_size: Optional[UInt] = None):
        # TODO: create buffer pool (with _Global) to reuse them instead of creating new ones
        self.id = ArcPointer(UInt32(0))
        gl.gen_buffers(1, self.id.unsafe_ptr())
        vertex_size = vertex_full_size.or_else(sizeof[T]())
        self.numel = len(data)*sizeof[T]() // vertex_size
        self.bind()
        gl.buffer_data(
            gl.BufferTargetARB.ARRAY_BUFFER,
            vertex_size * self.numel,
            data.unsafe_ptr().bitcast[NoneType](),
            gl.BufferUsageARB.STATIC_DRAW,
        )

    fn __del__(owned self):
        if self.id.count() == 1:
            gl.delete_buffers(1, self.id.unsafe_ptr())

    fn __len__(self) -> Int:
        return self.numel

    fn bind(self):
        gl.bind_buffer(gl.BufferTargetARB.ARRAY_BUFFER, self.id[])

    fn unbind(self):
        gl.bind_buffer(gl.BufferTargetARB.ARRAY_BUFFER, 0)

    fn draw(self):
        self.bind()
        gl.draw_arrays(gl.PrimitiveType.TRIANGLES, 0, len(self))
        self.unbind()
