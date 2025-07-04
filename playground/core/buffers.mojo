import opengl as gl
from .imports import *
from .utils import *


struct VertexBuffer[T: Copyable & Movable](Copyable, Movable):
    var id: Id

    fn __init__[T: Copyable & Movable](out self, data: List[T]):
        self.id = 0
        # TODO: create buffer pool (with _Global) to reuse them instead of creating new ones
        gl.gen_buffers(1, Ptr(to=self.id))
        self.bind()
        gl.buffer_data(
            gl.BufferTargetARB.ARRAY_BUFFER,
            sizeof[T]() * len(data),
            data.unsafe_ptr().bitcast[NoneType](),
            gl.BufferUsageARB.STATIC_DRAW,
        )

    fn __del__(owned self):
        gl.delete_buffers(1, Ptr(to=self.id))

    fn bind(self):
        gl.bind_buffer(gl.BufferTargetARB.ARRAY_BUFFER, self.id)

    fn unbind(self):
        gl.bind_buffer(gl.BufferTargetARB.ARRAY_BUFFER, 0)



struct IndexBuffer:
    var id: Id
    var count: Int

    fn __init__(out self, data: List[UInt32]):
        self.count = len(data)
        var total_size = sizeof[UInt32]() * self.count

        self.id = 0
        gl.gen_buffers(1, self.id.address)
        self.bind()
        gl.buffer_data(
            gl.BufferTargetARB.ELEMENT_ARRAY_BUFFER,
            total_size,
            data.unsafe_ptr().bitcast[NoneType](),
            gl.BufferTargetARB.STATIC_DRAW,
        )

    fn __del__(owned self):
        gl.delete_buffers(1, Ptr(to=self.id))

    fn bind(self):
        gl.bind_buffer(gl.BufferTargetARB.ELEMENT_ARRAY_BUFFER, self.id)

    fn unbind(self):
        gl.bind_buffer(gl.BufferTargetARB.ELEMENT_ARRAY_BUFFER, 0)

    fn get_count(self) -> Int:
        return self.count

struct VertexArray:
    var id: Id

