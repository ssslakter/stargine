from opengl import VertexAttribPointerType
from ..linalg import *
from ..utils import *

# TODO: create compile time map that maps Dtypes to VertexAttribPointerType
def dtype_to_enum(dtype: DType) -> VertexAttribPointerType:
    """Maps a DType to OpenGL's VertexAttribPointerType."""
    if dtype == DType.float32:
        return VertexAttribPointerType.GL_FLOAT
    elif dtype == DType.float64:
        return VertexAttribPointerType.GL_DOUBLE
    elif dtype == DType.float16:
        return VertexAttribPointerType.GL_HALF_FLOAT
    elif dtype == DType.int8:
        return VertexAttribPointerType.GL_BYTE
    elif dtype == DType.int16:
        return VertexAttribPointerType.GL_SHORT
    elif dtype == DType.int32:
        return VertexAttribPointerType.GL_INT
    elif dtype == DType.uint8:
        return VertexAttribPointerType.GL_UNSIGNED_BYTE
    elif dtype == DType.uint16:
        return VertexAttribPointerType.GL_UNSIGNED_SHORT
    elif dtype == DType.uint32:
        return VertexAttribPointerType.GL_UNSIGNED_INT
    return VertexAttribPointerType.GL_FLOAT


@fieldwise_init
struct VertexAttributeType(ImplicitlyCopyable, Movable, Equatable, Intable):
    var value: UInt

    comptime POSITION = Self(0)
    comptime UV = Self(1)
    comptime NORMAL = Self(2)
    comptime COLOR = Self(3)

    @always_inline
    def __int__(self) -> Int:
        return Int(self.value)

    @always_inline
    def __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    @always_inline
    def __ne__(self, other: Self) -> Bool:
        return self.value != other.value

    def get_size(self) -> Int:
        if self == Self.UV:
            return size_of[Vec2f]()
        if self == Self.COLOR:
            return size_of[Vec4f]()
        return size_of[Vec3f]()
    
    def num_components(self) -> Int:
        if self == Self.UV:
            return 2
        if self == Self.COLOR:
            return 4
        return 3
    


struct VertexAttribute(ImplicitlyCopyable, Movable, Writable):
    var num_components: Int
    var attr_type: VertexAttributeType
    var total_size: Int
    var dtype_size: Int
    var dtype: VertexAttribPointerType
    var normalized: Bool

    def __init__(out self, attr_type: VertexAttributeType,  normalized: Bool = False):
        self.attr_type = attr_type
        self.num_components = attr_type.num_components()
        self.dtype_size = size_of[DType.float32]() # TODO check if other types are supported
        self.total_size = attr_type.get_size()
        self.dtype = dtype_to_enum(DType.float32)
        self.normalized = normalized

    def write_to[W: Writer](self, mut writer: W):
        writer.write(
            "VertexAttribute(num_components=",
            self.num_components,
            ", total_size=",
            self.total_size,
            ", type_size=",
            self.dtype_size,
            ", normalized=",
            self.normalized,
            ")",
        )


struct VertexLayout(Copyable, Movable, Writable):
    var elements: List[VertexAttribute]
    var stride: Int

    def __init__(out self, *elements: VertexAttribute):
        self.elements = []
        self.stride = 0
        for el in elements:
            self.stride += el.total_size
            self.elements.append(el)

    def __init__(out self, var elements: List[VertexAttribute]):
        self.elements = elements^
        self.stride = 0
        for el in self.elements:
            self.stride += el.total_size

    def __init__(out self, *, copy: Self):
        self.elements = copy.elements.copy()
        self.stride = copy.stride
    
    def write_to[W: Writer](self, mut writer: W):
        writer.write("VertexLayout(stride=", self.stride, ", elements=[")
        for el in self.elements:
            el.write_to(writer)
            writer.write(",\n")
        writer.write("])")
    
