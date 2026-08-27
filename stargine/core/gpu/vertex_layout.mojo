import opengl as gl
from opengl import VertexAttribPointerType
from std.sys import size_of
from ..utils import Ptr


@fieldwise_init
struct VertexAttributeType(ImplicitlyCopyable, Equatable, Intable, Writable):
    """One interleaved vertex attribute. Every attribute is `f32`, which is all
    OpenGL supports for vertex data without extensions."""

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

    @always_inline
    def num_components(self) -> Int:
        if self == Self.UV:
            return 2
        if self == Self.COLOR:
            return 4
        return 3

    @always_inline
    def size(self) -> Int:
        return self.num_components() * size_of[DType.float32]()

    def write_to(self, mut writer: Some[Writer]):
        if self == Self.POSITION:
            writer.write("position")
        elif self == Self.UV:
            writer.write("uv")
        elif self == Self.NORMAL:
            writer.write("normal")
        else:
            writer.write("color")


struct VertexLayout[*attributes: VertexAttributeType]:
    """An interleaved vertex layout resolved entirely at compile time.

    Stride and per-attribute offsets are compile-time constants, so
    `configure` and the interleaving loop unroll with no runtime branching.
    """

    comptime count = len(Self.attributes)
    comptime stride = Self._stride()

    @staticmethod
    def _stride() -> Int:
        var total = 0
        comptime for i in range(len(Self.attributes)):
            total += Self.attributes[i].size()
        return total

    @staticmethod
    def offset[index: Int]() -> Int:
        var total = 0
        comptime for i in range(index):
            total += Self.attributes[i].size()
        return total

    @staticmethod
    def has[attribute: VertexAttributeType]() -> Bool:
        var found = False
        comptime for i in range(Self.count):
            found |= Self.attributes[i] == attribute
        return found

    @staticmethod
    def configure() raises:
        """Points the bound vertex array at each attribute of the bound buffer."""
        comptime for i in range(Self.count):
            gl.vertex_attrib_pointer(
                UInt32(i),
                Int32(Self.attributes[i].num_components()),
                VertexAttribPointerType.GL_FLOAT,
                False,
                Int32(Self.stride),
                # OpenGL reads this argument as a byte offset into the bound buffer.
                Ptr[UInt8, ImmutAnyOrigin](unsafe_from_address=Self.offset[i]()).unsafe_bitcast[NoneType](),
            )
            gl.enable_vertex_attrib_array(UInt32(i))

    @staticmethod
    def describe() -> String:
        var out = String("VertexLayout(stride=", Self.stride, ", ")
        comptime for i in range(Self.count):
            out += String(Self.attributes[i], "@", Self.offset[i]())
            if i < Self.count - 1:
                out += ", "
        return out + ")"
