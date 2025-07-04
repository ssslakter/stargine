from .utils import *


# TODO: create compile time map that maps Dtypes to VertexAttribPointerType
@fieldwise_init
@register_passable("trivial")
struct VertexAttribute(Copyable, Movable):
    var total_size: Int32
    var type_size: Int32
    var type: VertexAttribPointerType
    var normalized: Bool


struct VertexLayout:
    var elements: List[VertexAttribute]

    fn __init__(out self):
        self.elements = []

    fn __init__(out self, elements: List[VertexAttribute]):
        self.elements = elements

    fn append(self, owned element: VertexAttribute):
        self.elements.append(element)

    fn total_size(self) -> Int32:
        var res: Int32 = 0
        for element in self.elements:
            res += element.total_size
        return res


trait WithVertexLayout:
    @staticmethod
    fn get_layout() -> VertexLayout: ...


struct VertexArray(Movable, Copyable):
    var id: Id

    fn __init__(out self, layout: VertexLayout):
        self.id = 0
        gl.gen_vertex_arrays(1, Ptr(to=self.id))
        self.bind()
        offset, idx = Int32(0), UInt32(0)
        for element in layout.elements:
            print(idx, element.total_size//element.type_size,element.normalized, layout.total_size(), offset)
            gl.vertex_attrib_pointer(idx, element.total_size//element.type_size, element.type, element.normalized, layout.total_size(), UnsafePointer[NoneType]().offset(offset).bitcast[NoneType]())
            gl.enable_vertex_attrib_array(idx)
            offset += element.total_size
            idx += 1

    fn __del__(owned self):
        gl.delete_vertex_arrays(1, Ptr(to=self.id))

    fn bind(self):
        gl.bind_vertex_array(self.id)

    fn unbind(self):
        gl.bind_vertex_array(0)

    
