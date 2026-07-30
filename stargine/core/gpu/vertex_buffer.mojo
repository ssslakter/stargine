from ..utils import *
from .vertex_layout import *


struct VertexBuffer[T: Copyable & Movable = UInt8](Copyable, Movable, Sized):
    var id: ArcPointer[Id]
    var numel: UInt

    def __init__(out self, data: List[Self.T], vertex_full_size: Optional[UInt] = None) raises:
        # TODO: create buffer pool (with _Global) to reuse them instead of creating new ones
        self.id = ArcPointer(UInt32(0))
        gl.gen_buffers(1, UnsafePointer[UInt32, MutAnyOrigin](unsafe_from_address=Int(self.id.unsafe_ptr())))
        vertex_size = vertex_full_size.or_else(UInt(size_of[Self.T]()))
        self.numel = UInt(len(data) * size_of[Self.T]()) // vertex_size
        self.bind()
        gl.buffer_data(
            gl.BufferTargetARB.GL_ARRAY_BUFFER,
            Int(vertex_size * self.numel),
            UnsafePointer[NoneType, ImmutAnyOrigin](unsafe_from_address=Int(data.unsafe_ptr())),
            gl.BufferUsageARB.GL_STATIC_DRAW,
        )

    def __del__(deinit self):
        if self.id.count() == 1 and self.id[]:
            try:
                # TODO(upstream-opengl): delete_buffers should accept a pointer with any origin/mutability.
                gl.delete_buffers(1, UnsafePointer[UInt32, ImmutAnyOrigin](unsafe_from_address=Int(self.id.unsafe_ptr())))
            except err:
                # TODO(upstream-opengl): destruction should not expose a fallible API.
                print("Failed to delete vertex buffer:", err)

    def __len__(self) -> Int:
        return Int(self.numel)

    def bind(self) raises:
        gl.bind_buffer(gl.BufferTargetARB.GL_ARRAY_BUFFER, self.id[])

    def unbind(self) raises:
        gl.bind_buffer(gl.BufferTargetARB.GL_ARRAY_BUFFER, 0)

    def draw(self) raises:
        self.bind()
        gl.draw_arrays(gl.PrimitiveType.GL_TRIANGLES, 0, Int32(len(self)))
        self.unbind()
