from std.memory import ArcPointer
from .vertex_layout import VertexLayout 
from ..utils import *


struct VertexArray(Copyable, Movable):
    var id: ArcPointer[Id]

    def __init__(out self, layout: VertexLayout) raises:
        self.id = ArcPointer(UInt32(0))
        gl.gen_vertex_arrays(1, UnsafePointer[UInt32, MutAnyOrigin](unsafe_from_address=Int(self.id.unsafe_ptr())))
        self.bind()
        offset, idx = Int(0), UInt32(0)
        for element in layout.elements:
            gl.vertex_attrib_pointer(
                idx,
                Int32(element.num_components),
                element.dtype,
                element.normalized,
                Int32(layout.stride),
                UnsafePointer[UInt8, ImmutAnyOrigin](unsafe_from_address=offset).bitcast[NoneType](),
            )
            gl.enable_vertex_attrib_array(idx)
            offset += element.total_size
            idx += 1

    def __del__(deinit self):
        if self.id.count() == 1 and self.id[]:
            try:
                gl.delete_vertex_arrays(1, self.id.unsafe_ptr())
            except err:
                print("Failed to delete vertex array:", err)

    def bind(self) raises:
        gl.bind_vertex_array(self.id[])

    def unbind(self) raises:
        gl.bind_vertex_array(0)
