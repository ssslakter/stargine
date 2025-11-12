from memory import ArcPointer
from .vertex_layout import VertexLayout 
from ..utils import *


struct VertexArray(Copyable, Movable):
    var id: ArcPointer[Id]

    fn __init__(out self, layout: VertexLayout):
        self.id = ArcPointer(UInt32(0))
        gl.gen_vertex_arrays(1, self.id.unsafe_ptr())
        self.bind()
        offset, idx = Int(0), UInt(0)
        for element in layout.elements:
            gl.vertex_attrib_pointer(
                idx,
                element.num_components,
                element.dtype,
                element.normalized,
                layout.stride,
                LegacyUnsafePointer[UInt8]().offset(offset).bitcast[NoneType](),
            )
            gl.enable_vertex_attrib_array(idx)
            offset += element.total_size
            idx += 1

    fn __del__(deinit self):
        if self.id.count() == 1:
            gl.delete_vertex_arrays(1, self.id.unsafe_ptr())

    fn bind(self):
        gl.bind_vertex_array(self.id[])

    fn unbind(self):
        gl.bind_vertex_array(0)
