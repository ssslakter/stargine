from memory import ArcPointer
from .utils import *


fn dtype_to_enum(dtype: DType) -> VertexAttribPointerType:
    '''Maps a DType to OpenGL's VertexAttribPointerType.'''
    if dtype == DType.float32:
        return VertexAttribPointerType.FLOAT
    elif dtype == DType.float64:
        return VertexAttribPointerType.DOUBLE
    elif dtype == DType.float16:
        return VertexAttribPointerType.HALF_FLOAT
    elif dtype == DType.int8:
        return VertexAttribPointerType.BYTE
    elif dtype == DType.int16:
        return VertexAttribPointerType.SHORT
    elif dtype == DType.int32:
        return VertexAttribPointerType.INT
    elif dtype == DType.uint8:
        return VertexAttribPointerType.UNSIGNED_BYTE
    elif dtype == DType.uint16:
        return VertexAttribPointerType.UNSIGNED_SHORT
    elif dtype == DType.uint32:
        return VertexAttribPointerType.UNSIGNED_INT
    return VertexAttribPointerType.FLOAT


# TODO: create compile time map that maps Dtypes to VertexAttribPointerType
@register_passable("trivial")
struct VertexAttribute(Copyable, Movable, Writable):
    var total_size: Int32
    var dtype_size: Int32
    var dtype: VertexAttribPointerType
    var normalized: Bool

    fn __init__(out self, dtype: DType, total_size: Int32, normalized: Bool = False):
        self.total_size = total_size
        self.dtype_size = dtype.sizeof()
        self.dtype = dtype_to_enum(dtype)
        self.normalized = normalized

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(
            "VertexAttribute(total_size=",
            self.total_size,
            ", type_size=",
            self.dtype_size,
            ", normalized=",
            self.normalized,
            ")",
        )


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
    fn get_layout() -> VertexLayout:
        ...


struct _VertexArrayInner(Movable):
    var id: Id

    fn __init__(out self, layout: VertexLayout):
        self.id = 0
        gl.gen_vertex_arrays(1, Ptr(to=self.id))
        self.bind()
        offset, idx = Int32(0), UInt32(0)
        for element in layout.elements:
            gl.vertex_attrib_pointer(
                idx,
                element.total_size // element.dtype_size,
                element.dtype,
                element.normalized,
                layout.total_size(),
                UnsafePointer[NoneType]().offset(offset).bitcast[NoneType](),
            )
            gl.enable_vertex_attrib_array(idx)
            offset += element.total_size
            idx += 1

    fn __del__(owned self):
        gl.delete_vertex_arrays(1, Ptr(to=self.id))

    fn bind(self):
        gl.bind_vertex_array(self.id)

    fn unbind(self):
        gl.bind_vertex_array(0)


struct VertexArray(Copyable, Movable):
    var inner: ArcPointer[_VertexArrayInner]

    fn __init__(out self, layout: VertexLayout):
        self.inner = ArcPointer[_VertexArrayInner](_VertexArrayInner(layout))

    fn bind(self):
        self.inner[].bind()

    fn unbind(self):
        self.inner[].unbind()
