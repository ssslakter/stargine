from memory import ArcPointer
from .imports import *


struct _VertexArrayInner(Movable):
    var id: Id

    fn __init__(out self, layout: VertexLayout):
        self.id = 0
        gl.gen_vertex_arrays(1, Ptr(to=self.id))
        self.bind()
        offset, idx = Int(0), UInt(0)
        for element in layout.elements:
            gl.vertex_attrib_pointer(
                idx,
                element.num_components,
                element.dtype,
                element.normalized,
                layout.stride,
                # TODO: Use somehow types itself instead of using total_size (mojo must implement dynamic usage of types)
                UnsafePointer[UInt8]().offset(offset).bitcast[NoneType](),
            )
            gl.enable_vertex_attrib_array(idx)
            offset += element.offset
            idx += 1

    fn __del__(owned self):
        gl.delete_vertex_arrays(1, Ptr(to=self.id))

    fn bind(self):
        gl.bind_vertex_array(self.id)

    fn unbind(self):
        gl.bind_vertex_array(0)


struct VertexArray[T: Copyable & Movable](Copyable, Movable):
    var inner: ArcPointer[_VertexArrayInner]
    var vertices: VertexBuffer[T]
    var indices: Optional[IndexBuffer]

    fn __init__(out self, layout: VertexLayout, vertices: VertexBuffer[T], indices: Optional[IndexBuffer] = None):
        self.inner = ArcPointer[_VertexArrayInner](_VertexArrayInner(layout))
        self.vertices = vertices
        self.indices = indices

    fn draw(self):
        self.vertices.bind()
        self.inner[].bind()
        if not self.indices:
            self.vertices.draw()
        else:
            indices = self.indices.value()
            indices.draw()
        self.vertices.unbind()
        self.inner[].unbind()
