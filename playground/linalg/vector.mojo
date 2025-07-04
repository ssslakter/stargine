from bit import next_power_of_two
from math import sqrt
from utils.static_tuple import StaticTuple

@fieldwise_init
@register_passable("trivial")
struct Vec[N: Int, dtype: DType](Copyable, Movable, Writable):
    var data: SIMD[dtype, next_power_of_two(N)]

    @always_inline("nodebug")
    fn __init__(out self):
        data = SIMD[dtype, next_power_of_two(N)]()
        self = Self(data=data)

    @always_inline("nodebug")
    fn __init__(out self, scalar: Scalar[dtype], /):
        self = Self(data=SIMD[dtype, next_power_of_two(N)](scalar))

    @always_inline("nodebug")
    @implicit
    fn __init__(out self, *items: Scalar[dtype]):
        self.data = SIMD[dtype, next_power_of_two(N)]()

        @parameter
        for i in range(N):
            self.data[i] = items[i]

    @always_inline("nodebug")
    fn __init__[other_dtype: DType, //](out self, value: Vec[N, other_dtype]):
        self = Self(data=value.data.cast[dtype]())

    @always_inline
    fn __getitem__(self, i: Int) -> Scalar[dtype]:
        return self.data[i]

    @always_inline
    fn __setitem__(mut self, i: Int, val: Scalar[dtype]):
        self.data[i] = val

    @always_inline
    fn __add__(self, other: Self) -> Self:
        return Self(self.data + other.data)

    @always_inline
    fn __mul__(self, other: Scalar[dtype]) -> Self:
        return Self(self.data * other)

    @always_inline
    fn __sub__(self, other: Self) -> Self:
        return Self(self.data - other.data)

    @always_inline
    fn __neg__(self) -> Self:
        return Self(-self.data)

    @always_inline
    fn __mul__(self, other: Self) -> Self:
        return Self(self.data * other.data)

    @always_inline
    fn __truediv__(self, other: Scalar[dtype]) -> Self:
        return Self(self.data / other)

    @always_inline
    fn __abs__(self) -> Self:
        return Self(abs(self.data))

    @always_inline
    fn write_to[W: Writer](self, mut writer: W):
        writer.write("Vec", N, '(', self.data, ')')

    @always_inline
    fn dot(self, other: Self) -> Scalar[dtype]:
        return (self * other).data.reduce_add()

    @always_inline
    fn length_squared(self) -> Scalar[dtype]:
        return self.dot(self)

    @always_inline
    fn length(self) -> Scalar[dtype]:
        return sqrt(self.length_squared())

    @always_inline
    fn normalize(self) -> Self:
        """Normalize the vector to have a length of 1."""
        return self / self.length()

    @always_inline
    fn cross(self, other: Self) -> Self:
        """Cross product of two vectors."""
        constrained[N == 3, "Cross product is only defined for 3D vectors."]()
        return Self(
            self.data[1] * other.data[2] - self.data[2] * other.data[1],
            self.data[2] * other.data[0] - self.data[0] * other.data[2],
            self.data[0] * other.data[1] - self.data[1] * other.data[0],
        )

    @always_inline
    fn x(self) -> Scalar[dtype]:
        return self.data[0]
    
    @always_inline
    fn y(self) -> Scalar[dtype]:
        return self.data[1]

    @always_inline
    fn z(self) -> Scalar[dtype]:
        constrained[N > 2, "Z is only defined for 3D and 4D vectors."]()
        return self.data[2]

    @always_inline
    fn w(self) -> Scalar[dtype]:
        constrained[N > 3, "W is only defined for 4D vectors."]()
        return self.data[3]


alias Vec2[dtype: DType] = Vec[2, dtype]
alias Vec3[dtype: DType] = Vec[3, dtype]
alias Vec4[dtype: DType] = Vec[4, dtype]

alias f32 = DType.float32
alias i32 = DType.int32

alias Vec2f = Vec2[f32]
alias Vec3f = Vec3[f32]
alias Vec4f = Vec4[f32]

alias Vec2i = Vec2[i32]
alias Vec3i = Vec3[i32]
alias Vec4i = Vec4[i32]
