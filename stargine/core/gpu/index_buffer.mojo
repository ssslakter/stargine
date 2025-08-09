from ..utils import *

struct IndexBuffer[dtype: DType](Copyable, Movable, Sized):
    var id: ArcPointer[Id]
    var numel: UInt

    fn __init__(out self, data: List[Scalar[dtype]]):
        self.id = ArcPointer(UInt32(0))
        gl.gen_buffers(1, self.id.unsafe_ptr())
        constrained[dtype.is_unsigned(), "dtype must be unsigned"]()
        self.numel = len(data)
        self.bind()
        gl.buffer_data(
            gl.BufferTargetARB.ELEMENT_ARRAY_BUFFER,
            dtype.sizeof() * len(data),
            data.unsafe_ptr().bitcast[NoneType](),
            gl.BufferUsageARB.STATIC_DRAW,
        )

    fn __len__(self) -> Int:
        return self.numel

    fn __del__(owned self):
        if self.id.count() == 1:
            gl.delete_buffers(1, self.id.unsafe_ptr())

    fn bind(self):
        gl.bind_buffer(gl.BufferTargetARB.ELEMENT_ARRAY_BUFFER, self.id[])

    fn unbind(self):
        gl.bind_buffer(gl.BufferTargetARB.ELEMENT_ARRAY_BUFFER, 0)

    fn draw(self):
        self.bind()
        gl.draw_elements(
            gl.PrimitiveType.TRIANGLES,
            len(self),
            gl.DrawElementsType.UNSIGNED_INT,
            Ptr[NoneType](),
        )
        self.unbind()
