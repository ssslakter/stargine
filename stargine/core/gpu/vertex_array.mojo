import opengl as gl
from std.memory import ArcPointer
from ..utils import Ptr
from .objects import VertexArrayName
from .vertex_layout import VertexLayout


struct VertexArray(Copyable, Movable):
    var name: ArcPointer[VertexArrayName]

    def __init__(out self, layout: VertexLayout) raises:
        self.name = ArcPointer(VertexArrayName())
        self.bind()
        var offset = 0
        var index = UInt32(0)
        for element in layout.elements:
            gl.vertex_attrib_pointer(
                index,
                Int32(element.num_components),
                element.dtype,
                element.normalized,
                Int32(layout.stride),
                # OpenGL reads this argument as a byte offset into the bound buffer.
                Ptr[UInt8, ImmutAnyOrigin](unsafe_from_address=offset).unsafe_bitcast[NoneType](),
            )
            gl.enable_vertex_attrib_array(index)
            offset += element.total_size
            index += 1

    def bind(self) raises:
        gl.bind_vertex_array(self.name[].id)

    def unbind(self) raises:
        gl.bind_vertex_array(0)
