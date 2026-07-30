from .vector import *


struct Matrix[dtype: DType, nrows: Int, ncols: Int](ImplicitlyCopyable, Movable, Writable):
    comptime rank = 2
    # TODO: maybe use SIMD to speed up
    comptime Data = InlineArray[Scalar[Self.dtype], Self.nrows * Self.ncols]
    var data: Self.Data

    def __init__(out self, value: Scalar[Self.dtype] = 0.0):
        self.data = Self.Data(fill=value)

    def __getitem__(self, row: Int, col: Int) -> Scalar[Self.dtype]:
        return self.data[row * Self.ncols + col]

    def __setitem__(mut self, row: Int, col: Int, value: Scalar[Self.dtype]):
        self.data[row * Self.ncols + col] = value

    def __init__(
        out self: Mat3[Self.dtype],
        rows: Tuple[Vec3[Self.dtype], Vec3[Self.dtype], Vec3[Self.dtype]],
    ):
        comptime dims = 3
        self = Mat3[Self.dtype]()

        comptime
        for i in range(dims):
            for j in range(dims):
                self[i, j] = rows[i][j]

    def __init__[r: Int, c: Int](out self, other: Matrix[Self.dtype, r, c]):
        self = Self()

        comptime
        for i in range(Self.nrows):
            for j in range(Self.ncols):
                if i < r and j < c:
                    self[i, j] = other[i, j]
                else:
                    self[i, j] = 0

    def __init__(
        out self: Mat4[Self.dtype],
        rows: Tuple[Vec4[Self.dtype], Vec4[Self.dtype], Vec4[Self.dtype], Vec4[Self.dtype]],
    ):
        comptime dims = 4
        self = Mat4[Self.dtype]()

        comptime
        for i in range(dims):
            for j in range(dims):
                self[i, j] = rows[i][j]

    def __init__(out self, rows: List[Vec[Self.dtype, Self.ncols]]):
        self = Self()
        for i in range(len(rows)):
            for j in range(Self.ncols):
                self[i, j] = rows[i][j]

    def __copyinit__(out self, other: Self):
        self.data = other.data

    def __moveinit__(out self, deinit other: Self):
        self.data = other.data^

    def write_to[W: Writer](self, mut writer: W):
        writer.write("Matrix(\n")
        for i in range(self.nrows):
            writer.write("    [")
            for j in range(self.ncols):
                writer.write(self[i, j])
                if j < self.ncols - 1:
                    writer.write(", ")
            writer.write("]\n")
        writer.write(")")

    def fill(self, value: Scalar[Self.dtype]):
        for i in range(Self.nrows * Self.ncols):
            self.data[i] = value

    @staticmethod
    def id() -> Matrix[Self.dtype, Self.nrows, Self.nrows]:
        return Self.diag(1.0)

    @staticmethod
    def diag(value: Vec[Self.dtype, Self.nrows]) -> Matrix[Self.dtype, Self.nrows, Self.nrows]:
        var self = Matrix[Self.dtype, Self.nrows, Self.nrows](0.0)
        for i in range(Self.nrows):
            self[i, i] = value[i]

        return self

    @staticmethod
    def diag(value: Scalar[Self.dtype]) -> Matrix[Self.dtype, Self.nrows, Self.nrows]:
        return Self.diag(Vec[Self.dtype, Self.nrows](value))

    def transpose(var self) -> Matrix[Self.dtype, Self.ncols, Self.nrows]:
        var out = Matrix[Self.dtype, Self.ncols, Self.nrows]()
        for i in range(self.nrows):
            for j in range(self.ncols):
                out[j, i] = self[i, j]
        return out

    def __add__(var self, other: Self) -> Self:
        constrained[
            self.nrows == other.Self.nrows and self.ncols == other.Self.ncols,
            "Matrices must have the same dimensions",
        ]()
        for i in range(self.nrows):
            for j in range(self.ncols):
                self[i, j] = self[i, j] + other[i, j]

        return self

    def __neg__(var self) -> Self:
        for i in range(self.nrows):
            for j in range(self.ncols):
                self[i, j] = -self[i, j]
        return self

    def __sub__(var self, var other: Self) -> Self:
        return self + (-other)

    def __mul__(var self, other: Scalar[Self.dtype]) -> Self:
        for i in range(self.nrows):
            for j in range(self.ncols):
                self[i, j] = self[i, j] * other
        return self

    def __mul__(var self, var other: Self) -> Self:
        constrained[
            self.ncols == other.ncols and self.nrows == other.Self.nrows,
            "Matrices must have the same dimensions",
        ]()
        var out = Self()
        for i in range(self.nrows):
            for j in range(self.ncols):
                out[i, j] = self[i, j] * other[i, j]
        return out

    def matmul[
        other_cols: Int
    ](self, other: Matrix[Self.dtype, Self.ncols, other_cols]) -> Matrix[
        Self.dtype, Self.nrows, other_cols
    ]:
        var out = Matrix[Self.dtype, Self.nrows, other_cols](0.0)
        for i in range(self.nrows):
            for j in range(other.ncols):
                for k in range(self.ncols):
                    out[i, j] = (
                        out[i, j] + self[i, k] * other[k, j]
                    )
        return out

    def matmul(self, other: Vec[Self.dtype, Self.ncols]) -> Vec[Self.dtype, Self.nrows]:
        var out = Vec[Self.dtype, Self.nrows]()
        for i in range(self.nrows):
            for j in range(self.ncols):
                out[i] = out[i] + self[i, j] * other[j]
        return out

    def __truediv__(var self, other: Scalar[Self.dtype]) -> Self:
        return self * (1.0 / other)

    def __pow__(var self, other: Int) -> Self:
        var out = Self()
        for i in range(self.nrows):
            for j in range(self.ncols):
                out[i, j] = self[i, j] ** other
        return out

    def __mod__(var self, other: Scalar[Self.dtype]) -> Self:
        for i in range(self.nrows):
            for j in range(self.ncols):
                self[i, j] = self[i, j] % other
        return self

    def inverse2(var self) -> Self where Self == Mat2[Self.dtype]:
        var a = self[0, 0]
        var b = self[0, 1]
        var c = self[1, 0]
        var d = self[1, 1]
        var det = a * d - b * c
        var inv_det = 1.0 / det
        var out = Self(0.0)
        out[0, 0] = d * inv_det
        out[0, 1] = -b * inv_det
        out[1, 0] = -c * inv_det
        out[1, 1] = a * inv_det
        return out

    def inverse(var self) -> Self where Self == Mat3[Self.dtype]:
        var a = self[0, 0]
        var b = self[0, 1]
        var c = self[0, 2]
        var d = self[1, 0]
        var e = self[1, 1]
        var f = self[1, 2]
        var g = self[2, 0]
        var h = self[2, 1]
        var i = self[2, 2]
        var det = (
            a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g)
        )
        var inv_det = 1.0 / det
        var out = Self(0.0)
        out[0, 0] = (e * i - f * h) * inv_det
        out[0, 1] = -(b * i - c * h) * inv_det
        out[0, 2] = (b * f - c * e) * inv_det
        out[1, 0] = -(d * i - f * g) * inv_det
        out[1, 1] = (a * i - c * g) * inv_det
        out[1, 2] = -(a * f - c * d) * inv_det
        out[2, 0] = (d * h - e * g) * inv_det
        out[2, 1] = -(a * h - b * g) * inv_det
        out[2, 2] = (a * e - b * d) * inv_det
        return out

    def inverse4(var self) -> Self where Self == Mat4[Self.dtype]:
        # Extract elements for readability:
        var a = self[0, 0]
        var b = self[0, 1]
        var c = self[0, 2]
        var d = self[0, 3]
        var e = self[1, 0]
        var f = self[1, 1]
        var g = self[1, 2]
        var h = self[1, 3]
        var i = self[2, 0]
        var j = self[2, 1]
        var k = self[2, 2]
        var l = self[2, 3]
        var m = self[3, 0]
        var n = self[3, 1]
        var o = self[3, 2]
        var p = self[3, 3]

        # Compute cofactors for first row (partial)
        var A = f * (k * p - l * o) - g * (j * p - l * n) + h * (j * o - k * n)
        var B = -(
            e * (k * p - l * o) - g * (i * p - l * m) + h * (i * o - k * m)
        )
        var C = e * (j * p - l * n) - f * (i * p - l * m) + h * (i * n - j * m)
        var D = -(
            e * (j * o - k * n) - f * (i * o - k * m) + g * (i * n - j * m)
        )

        var det = a * A + b * B + c * C + d * D
        var inv_det = 1.0 / det

        var out = Self(0.0)
        # Compute inverse matrix (transpose of cofactors multiplied by the reciprocal determinant):
        out[0, 0] = A * inv_det
        out[0, 1] = (
            -(b * (k * p - l * o) - c * (j * p - l * n) + d * (j * o - k * n))
            * inv_det
        )
        out[0, 2] = (
            b * (g * p - h * o) - c * (f * p - h * n) + d * (f * o - g * n)
        ) * inv_det
        out[0, 3] = (
            -(b * (g * l - h * k) - c * (f * l - h * j) + d * (f * k - g * j))
            * inv_det
        )

        out[1, 0] = B * inv_det
        out[1, 1] = (
            a * (k * p - l * o) - c * (i * p - l * m) + d * (i * o - k * m)
        ) * inv_det
        out[1, 2] = (
            -(a * (g * p - h * o) - c * (e * p - h * m) + d * (e * o - g * m))
            * inv_det
        )
        out[1, 3] = (
            a * (g * l - h * k) - c * (e * l - h * i) + d * (e * k - g * i)
        ) * inv_det

        out[2, 0] = C * inv_det
        out[2, 1] = (
            -(a * (j * p - l * n) - b * (i * p - l * m) + d * (i * n - j * m))
            * inv_det
        )
        out[2, 2] = (
            a * (g * p - h * n) - b * (e * p - h * m) + d * (e * n - g * m)
        ) * inv_det
        out[2, 3] = (
            -(a * (g * l - h * j) - b * (e * l - h * i) + d * (e * j - g * i))
            * inv_det
        )

        out[3, 0] = D * inv_det
        out[3, 1] = (
            a * (j * o - k * n) - b * (i * o - k * m) + c * (i * n - j * m)
        ) * inv_det
        out[3, 2] = (
            -(a * (g * o - h * n) - b * (e * o - h * m) + c * (e * n - g * m))
            * inv_det
        )
        out[3, 3] = (
            a * (g * k - h * j) - b * (e * k - h * i) + c * (e * j - g * i)
        ) * inv_det

        return out


comptime Mat2 = Matrix[_, 2, 2]
comptime Mat3 = Matrix[_, 3, 3]
comptime Mat4 = Matrix[_, 4, 4]

comptime Mat2f = Mat2[f32]
comptime Mat3f = Mat3[f32]
comptime Mat4f = Mat4[f32]

comptime Mat2i = Mat2[i32]
comptime Mat3i = Mat3[i32]
comptime Mat4i = Mat4[i32]
