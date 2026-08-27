import opengl as gl
from ..utils import Id, Ptr


struct BufferName(Movable):
    """Owns a GL buffer name and deletes it exactly once."""

    var id: Id

    def __init__(out self) raises:
        self.id = 0
        gl.gen_buffers(1, Ptr(to=self.id))

    def __deinit__(deinit self):
        if self.id:
            try:
                gl.delete_buffers(1, Ptr(to=self.id))
            except err:
                print("Failed to delete buffer:", err)


struct VertexArrayName(Movable):
    """Owns a GL vertex array name and deletes it exactly once."""

    var id: Id

    def __init__(out self) raises:
        self.id = 0
        gl.gen_vertex_arrays(1, Ptr(to=self.id))

    def __deinit__(deinit self):
        if self.id:
            try:
                gl.delete_vertex_arrays(1, Ptr(to=self.id))
            except err:
                print("Failed to delete vertex array:", err)
