from opengl import VertexAttribPointerType
from .imports import *


fn dtype_to_enum(dtype: DType) -> VertexAttribPointerType:
    """Maps a DType to OpenGL's VertexAttribPointerType."""
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
    var num_components: Int
    var offset: Int
    var dtype_size: Int
    var dtype: VertexAttribPointerType
    var normalized: Bool

    fn __init__(out self, total_size: Int, dtype: DType, num_components: Int, normalized: Bool = False):
        self.num_components = num_components
        self.dtype_size = dtype.sizeof()
        self.offset = total_size
        self.dtype = dtype_to_enum(dtype)
        self.normalized = normalized

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(
            "VertexAttribute(num_components=",
            self.num_components,
            ", offset=",
            self.offset,
            ", type_size=",
            self.dtype_size,
            ", normalized=",
            self.normalized,
            ")",
        )


struct VertexLayout:
    var elements: List[VertexAttribute]
    var stride: Int

    fn __init__(out self, elements: List[VertexAttribute], stride: Int):
        self.elements = elements
        self.stride = stride

    fn append(self, owned element: VertexAttribute):
        self.elements.append(element)


trait WithVertexLayout:
    @staticmethod
    fn get_layout() -> VertexLayout:
        ...

