from std.bit import next_power_of_two
from std.math import sqrt


struct Vec[dtype: DType, N: Int](ImplicitlyCopyable, Movable, Writable):
    """A fixed size vector backed by SIMD storage padded to a power of two.

    The padding lanes are always zero: `dot`, `length` and `normalize` reduce
    over the whole register, so anything that writes `data` must keep them zero.
    """

    comptime Width = next_power_of_two(Self.N)
    comptime Data = SIMD[Self.dtype, Self.Width]

    var data: Self.Data

    @always_inline("nodebug")
    def __init__(out self, *, data: Self.Data):
        self.data = data

    @always_inline("nodebug")
    def __init__(out self):
        self = Self(data=Self.Data())

    @always_inline("nodebug")
    @implicit
    def __init__(out self, scalar: Scalar[Self.dtype], /):
        var data = Self.Data(scalar)
        comptime for i in range(Self.N, Self.Width):
            data[i] = 0
        self = Self(data=data)

    @always_inline("nodebug")
    def __init__(out self, *items: Scalar[Self.dtype]):
        """Builds a vector from its components.

        A single component broadcasts to every lane; otherwise missing
        components are zero.
        """
        if len(items) == 1:
            self = Self(items[0])
            return
        var data = Self.Data()
        for i in range(min(len(items), Self.N)):
            data[i] = items[i]
        self = Self(data=data)

    @always_inline("nodebug")
    def __init__(out self, other: Vec[Self.dtype, Self.N - 1], w: Scalar[Self.dtype] = 0, /):
        var data = Self.Data()
        comptime for i in range(Self.N - 1):
            data[i] = other.data[i]
        data[Self.N - 1] = w
        self = Self(data=data)

    @always_inline("nodebug")
    def __init__(
        out self,
        other: Vec[Self.dtype, Self.N - 2],
        z: Scalar[Self.dtype] = 0,
        w: Scalar[Self.dtype] = 0,
        /,
    ):
        var data = Self.Data()
        comptime for i in range(Self.N - 2):
            data[i] = other.data[i]
        data[Self.N - 2] = z
        data[Self.N - 1] = w
        self = Self(data=data)

    @always_inline("nodebug")
    def __init__(out self, value: Vec[_, Self.N]):
        self = Self(data=value.data.cast[Self.dtype]())

    @always_inline
    def __getitem__(self, i: Int) -> Scalar[Self.dtype]:
        return self.data[i]

    @always_inline
    def __setitem__(mut self, i: Int, val: Scalar[Self.dtype]):
        self.data[i] = val

    @always_inline
    def __add__(self, other: Self) -> Self:
        return Self(data=self.data + other.data)

    @always_inline
    def __iadd__(mut self, other: Self):
        self = self + other

    @always_inline
    def __sub__(self, other: Self) -> Self:
        return Self(data=self.data - other.data)

    @always_inline
    def __isub__(mut self, other: Self):
        self = self - other

    @always_inline
    def __mul__(self, other: Scalar[Self.dtype]) -> Self:
        return Self(data=self.data * other)

    @always_inline
    def __mul__(self, other: Self) -> Self:
        return Self(data=self.data * other.data)

    @always_inline
    def __imul__(mut self, other: Scalar[Self.dtype]):
        self = self * other

    @always_inline
    def __imul__(mut self, other: Self):
        self = self * other

    @always_inline
    def __truediv__(self, other: Scalar[Self.dtype]) -> Self:
        return Self(data=self.data / other)

    @always_inline
    def __neg__(self) -> Self:
        return Self(data=-self.data)

    @always_inline
    def __abs__(self) -> Self:
        return Self(data=abs(self.data))

    @always_inline
    def write_to(self, mut writer: Some[Writer]):
        writer.write("Vec", Self.N, "(", self.data, ")")

    @always_inline
    def dot(self, other: Self) -> Scalar[Self.dtype]:
        return (self * other).data.reduce_add()

    @always_inline
    def length_squared(self) -> Scalar[Self.dtype]:
        return self.dot(self)

    @always_inline
    def length(self) -> Scalar[Self.dtype]:
        return sqrt(self.length_squared())

    @always_inline
    def normalize(self) -> Self:
        """Normalize the vector to have a length of 1."""
        return self / self.length()

    @always_inline
    def cross(self, other: Self) -> Self:
        """Cross product of two vectors."""
        comptime assert Self.N == 3, "Cross product is only defined for 3D vectors."
        return Self(
            self.data[1] * other.data[2] - self.data[2] * other.data[1],
            self.data[2] * other.data[0] - self.data[0] * other.data[2],
            self.data[0] * other.data[1] - self.data[1] * other.data[0],
        )

    @always_inline
    def x(self) -> Scalar[Self.dtype]:
        return self.data[0]

    @always_inline
    def y(self) -> Scalar[Self.dtype]:
        comptime assert Self.N > 1, "Y is only defined for vectors with at least 2 elements."
        return self.data[1]

    @always_inline
    def z(self) -> Scalar[Self.dtype]:
        comptime assert Self.N > 2, "Z is only defined for 3D and 4D vectors."
        return self.data[2]

    @always_inline
    def w(self) -> Scalar[Self.dtype]:
        comptime assert Self.N > 3, "W is only defined for 4D vectors."
        return self.data[3]


comptime Vec2 = Vec[_, 2]
comptime Vec3 = Vec[_, 3]
comptime Vec4 = Vec[_, 4]

comptime f32 = DType.float32
comptime i32 = DType.int32
comptime u32 = DType.uint32

comptime Vec2f = Vec2[f32]
comptime Vec3f = Vec3[f32]
comptime Vec4f = Vec4[f32]

comptime Vec2i = Vec2[i32]
comptime Vec3i = Vec3[i32]
comptime Vec4i = Vec4[i32]

comptime Vec2u = Vec2[u32]
comptime Vec3u = Vec3[u32]
comptime Vec4u = Vec4[u32]
