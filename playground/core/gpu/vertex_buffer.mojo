from ..utils import *
from .vertex_layout import *


struct VertexBuffer(Copyable, Movable, Sized):
    var id: ArcPointer[Id]
    var numel: UInt

    fn __init__(out self, vertex_size: UInt, bytes: List[UInt8]):
        print('creating vertex buffer')
        # TODO: create buffer pool (with _Global) to reuse them instead of creating new ones
        self.id = ArcPointer(UInt32(0))
        gl.gen_buffers(1, self.id.unsafe_ptr())
        self.numel = len(bytes) // vertex_size
        for i in range(0, len(bytes), 4):
            val = Ptr(to=bytes[i]).bitcast[Float32]()[]
            print(val, end = ' ')
        self.bind()
        gl.buffer_data(
            gl.BufferTargetARB.ARRAY_BUFFER,
            vertex_size * self.numel,
            bytes.unsafe_ptr().bitcast[NoneType](),
            gl.BufferUsageARB.STATIC_DRAW,
        )

    fn __del__(owned self):
        print("deleting vb ref")
        if self.id.count() == 1:
            print("DELETING vb")
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
