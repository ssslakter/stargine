from ..utils import *

struct IndexBuffer[dtype: DType](Copyable, Movable, Sized):
    var id: ArcPointer[Id]
    var numel: UInt

    def __init__(out self, data: List[Scalar[Self.dtype]]) raises:
        self.id = ArcPointer(UInt32(0))
        gl.gen_buffers(1, UnsafePointer[UInt32, MutAnyOrigin](unsafe_from_address=Int(self.id.unsafe_ptr())))
        comptime assert Self.dtype.is_unsigned(), "dtype must be unsigned"
        self.numel = UInt(len(data))
        self.bind()
        gl.buffer_data(
            gl.BufferTargetARB.GL_ELEMENT_ARRAY_BUFFER,
            size_of[Self.dtype]()* len(data),
            UnsafePointer[NoneType, ImmutAnyOrigin](unsafe_from_address=Int(data.unsafe_ptr())),
            gl.BufferUsageARB.GL_STATIC_DRAW,
        )

    def __len__(self) -> Int:
        return Int(self.numel)

    def __del__(deinit self):
        if self.id.count() == 1 and self.id[]:
            try:
                gl.delete_buffers(1, self.id.unsafe_ptr())
            except err:
                print("Failed to delete index buffer:", err)

    def bind(self) raises:
        gl.bind_buffer(gl.BufferTargetARB.GL_ELEMENT_ARRAY_BUFFER, self.id[])

    def unbind(self) raises:
        gl.bind_buffer(gl.BufferTargetARB.GL_ELEMENT_ARRAY_BUFFER, 0)

    def draw(self) raises:
        self.bind()
        var offset: Optional[Ptr[NoneType, ImmutAnyOrigin]] = None
        gl.draw_elements(gl.PrimitiveType.GL_TRIANGLES, Int32(self.numel), gl.DrawElementsType.GL_UNSIGNED_INT, offset)
        self.unbind()
