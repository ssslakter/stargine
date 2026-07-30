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
                gl.delete_buffers(1, UnsafePointer[UInt32, ImmutAnyOrigin](unsafe_from_address=Int(self.id.unsafe_ptr())))
            except err:
                # TODO(upstream-opengl): destruction should not expose a fallible API.
                print("Failed to delete index buffer:", err)

    def bind(self) raises:
        gl.bind_buffer(gl.BufferTargetARB.GL_ELEMENT_ARRAY_BUFFER, self.id[])

    def unbind(self) raises:
        gl.bind_buffer(gl.BufferTargetARB.GL_ELEMENT_ARRAY_BUFFER, 0)

    def draw(self) raises:
        # TODO(upstream-opengl): expose glDrawElements' nullable index-offset
        # pointer. Passing a fabricated non-null pointer would be unsafe.
        raise Error("indexed drawing is unavailable until opengl-mojo supports a null EBO offset")
