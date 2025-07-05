from .utils import *


struct _VertexBufferInner[T: Copyable & Movable](Movable):
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


struct VertexBuffer[T: Copyable & Movable](Copyable, Movable, Sized):
    var inner: ArcPointer[_VertexBufferInner[T]]
    var data: List[T]

    fn __init__(out self, data: List[T]):
        self.inner = ArcPointer[_VertexBufferInner[T]](_VertexBufferInner[T](data))
        self.data = data

    fn __len__(self) -> Int:
        return len(self.data)

    fn bind(self):
        self.inner[].bind()

    fn unbind(self):
        self.inner[].unbind()

    fn draw(self):
        self.bind()
        gl.draw_arrays(gl.PrimitiveType.TRIANGLES, 0, len(self.data))
        self.unbind()


struct _IndexBufferInner(Movable):
    var id: Id

    fn __init__(out self, data: List[UInt32]):
        var total_size = sizeof[UInt32]() * len(data)

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


struct IndexBuffer(Copyable, Movable):
    var inner: ArcPointer[_IndexBufferInner]
    var data: List[UInt32]

    fn __init__(out self, data: List[UInt32]):
        self.inner = ArcPointer[_IndexBufferInner](_IndexBufferInner(data))
        self.data = data

    fn bind(self):
        self.inner[].bind()

    fn unbind(self):
        self.inner[].unbind()

    fn draw(self):
        self.bind()
        gl.draw_elements(
            gl.PrimitiveType.TRIANGLES,
            len(self.data),
            gl.DrawElementsType.UNSIGNED_INT,
            Ptr[NoneType](),
        )
        self.unbind()
