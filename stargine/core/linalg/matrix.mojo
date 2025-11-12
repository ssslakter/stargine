from .vector import *
from buffer import *


struct Matrix[dtype: DType, nrows: Int, ncols: Int](ImplicitlyCopyable, Movable, Writable):
    alias rank = 2
    # TODO: maybe use SIMD to speed up
    alias Data = InlineArray[Scalar[dtype], nrows * ncols]
    alias Buffer = NDBuffer[dtype, Self.rank, MutableAnyOrigin]
    var buf: Self.Buffer
    var data: Self.Data

    fn __init__(out self, value: Scalar[dtype] = 0.0):
        self.data = Self.Data(fill=value)
        self.buf = Self.Buffer(self.data.unsafe_ptr(), (nrows, ncols))

    fn __init__(
        out self: Mat3[dtype],
        rows: Tuple[Vec3[dtype], Vec3[dtype], Vec3[dtype]],
    ):
        alias dims = 3
        self = Mat3[dtype]()

        @parameter
        for i in range(dims):
            for j in range(dims):
                self.buf[i, j] = rows[i][j]

    fn __init__[r: Int, c: Int](out self, other: Matrix[dtype, r, c]):
        self = Self()

        @parameter
        for i in range(nrows):
            for j in range(ncols):
                if i < r and j < c:
                    self.buf[i, j] = other.buf[i, j]
                else:
                    self.buf[i, j] = 0

    fn __init__(
        out self: Mat4[dtype],
        rows: Tuple[Vec4[dtype], Vec4[dtype], Vec4[dtype], Vec4[dtype]],
    ):
        alias dims = 4
        self = Mat4[dtype]()

        @parameter
        for i in range(dims):
            for j in range(dims):
                self.buf[i, j] = rows[i][j]

    fn __init__(out self, rows: List[Vec[dtype, ncols]]):
        self = Self()
        for i in range(len(rows)):
            for j in range(Self.ncols):
                self.buf[i, j] = rows[i][j]

    fn __copyinit__(out self, other: Self):
        self.data = other.data
        self.buf = Self.Buffer(self.data.unsafe_ptr(), (nrows, ncols))

    fn __moveinit__(out self, deinit other: Self):
        self.data = other.data^
        self.buf = Self.Buffer(self.data.unsafe_ptr(), (nrows, ncols))

    fn write_to[W: Writer](self, mut writer: W):
        writer.write("Matrix(\n")
        for i in range(self.nrows):
            writer.write("    [")
            for j in range(self.ncols):
                writer.write(self.buf[i, j])
                if j < self.ncols - 1:
                    writer.write(", ")
            writer.write("]\n")
        writer.write(")")

    fn is_contiguous(self) -> Bool:
        return self.buf.is_contiguous()

    fn stride(self) -> IndexList[Self.rank]:
        return self.buf.get_strides()

    fn shape(self) -> IndexList[Self.rank]:
        return self.buf.get_shape()

    fn fill(self, value: Scalar[dtype]):
        self.buf.fill(value)

    @staticmethod
    fn id() -> Matrix[dtype, nrows, nrows]:
        return Self.diag(1.0)

    @staticmethod
    fn diag(value: Vec[dtype, nrows]) -> Matrix[dtype, nrows, nrows]:
        var self = Matrix[dtype, nrows, nrows](0.0)
        for i in range(nrows):
            self.buf[i, i] = value[i]

        return self

    @staticmethod
    fn diag(value: Scalar[dtype]) -> Matrix[dtype, nrows, nrows]:
        return Self.diag(Vec[dtype, nrows](value))

    fn transpose(var self) -> Matrix[dtype, ncols, nrows]:
        var out = Matrix[dtype, ncols, nrows]()
        for i in range(self.nrows):
            for j in range(self.ncols):
                out.buf[j, i] = self.buf[i, j]
        return out

    fn __add__(var self, other: Self) -> Self:
        constrained[
            self.nrows == other.nrows and self.ncols == other.ncols,
            "Matrices must have the same dimensions",
        ]()
        for i in range(self.nrows):
            for j in range(self.ncols):
                self.buf[i, j] = self.buf[i, j] + other.buf[i, j]

        return self

    fn __neg__(var self) -> Self:
        for i in range(self.nrows):
            for j in range(self.ncols):
                self.buf[i, j] = -self.buf[i, j]
        return self

    fn __sub__(var self, var other: Self) -> Self:
        return self + (-other)

    fn __mul__(var self, other: Scalar[dtype]) -> Self:
        for i in range(self.nrows):
            for j in range(self.ncols):
                self.buf[i, j] = self.buf[i, j] * other
        return self

    fn __mul__(var self, var other: Self) -> Self:
        constrained[
            self.ncols == other.ncols and self.nrows == other.nrows,
            "Matrices must have the same dimensions",
        ]()
        var out = Self()
        for i in range(self.nrows):
            for j in range(self.ncols):
                out.buf[i, j] = self.buf[i, j] * other.buf[i, j]
        return out

    fn matmul[
        other_cols: Int
    ](self, other: Matrix[dtype, ncols, other_cols]) -> Matrix[
        dtype, nrows, other_cols
    ]:
        var out = Matrix[dtype, nrows, other_cols](0.0)
        for i in range(self.nrows):
            for j in range(other.ncols):
                for k in range(self.ncols):
                    out.buf[i, j] = (
                        out.buf[i, j] + self.buf[i, k] * other.buf[k, j]
                    )
        return out

    fn matmul(self, other: Vec[dtype, ncols]) -> Vec[dtype, nrows]:
        var out = Vec[dtype, nrows]()
        for i in range(self.nrows):
            for j in range(self.ncols):
                out[i] = out[i] + self.buf[i, j] * other[j]
        return out

    fn __truediv__(var self, other: Scalar[dtype]) -> Self:
        return self * (1.0 / other)

    fn __pow__(var self, other: Int) -> Self:
        var out = Self()
        for i in range(self.nrows):
            for j in range(self.ncols):
                out.buf[i, j] = self.buf[i, j] ** other
        return out

    fn __mod__(var self, other: Scalar[dtype]) -> Self:
        for i in range(self.nrows):
            for j in range(self.ncols):
                self.buf[i, j] = self.buf[i, j] % other
        return self

    fn inverse(var self: Mat2[dtype]) -> Mat2[dtype]:
        var a = self.buf[0, 0]
        var b = self.buf[0, 1]
        var c = self.buf[1, 0]
        var d = self.buf[1, 1]
        var det = a * d - b * c
        var inv_det = 1.0 / det
        var out = Mat2[dtype](0.0)
        out.buf[0, 0] = d * inv_det
        out.buf[0, 1] = -b * inv_det
        out.buf[1, 0] = -c * inv_det
        out.buf[1, 1] = a * inv_det
        return out

    fn inverse(var self: Mat3[dtype]) -> Mat3[dtype]:
        var a = self.buf[0, 0]
        var b = self.buf[0, 1]
        var c = self.buf[0, 2]
        var d = self.buf[1, 0]
        var e = self.buf[1, 1]
        var f = self.buf[1, 2]
        var g = self.buf[2, 0]
        var h = self.buf[2, 1]
        var i = self.buf[2, 2]
        var det = (
            a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g)
        )
        var inv_det = 1.0 / det
        var out = Mat3[dtype](0.0)
        out.buf[0, 0] = (e * i - f * h) * inv_det
        out.buf[0, 1] = -(b * i - c * h) * inv_det
        out.buf[0, 2] = (b * f - c * e) * inv_det
        out.buf[1, 0] = -(d * i - f * g) * inv_det
        out.buf[1, 1] = (a * i - c * g) * inv_det
        out.buf[1, 2] = -(a * f - c * d) * inv_det
        out.buf[2, 0] = (d * h - e * g) * inv_det
        out.buf[2, 1] = -(a * h - b * g) * inv_det
        out.buf[2, 2] = (a * e - b * d) * inv_det
        return out

    fn inverse(var self: Mat4[dtype]) -> Mat4[dtype]:
        # Extract elements for readability:
        var a = self.buf[0, 0]
        var b = self.buf[0, 1]
        var c = self.buf[0, 2]
        var d = self.buf[0, 3]
        var e = self.buf[1, 0]
        var f = self.buf[1, 1]
        var g = self.buf[1, 2]
        var h = self.buf[1, 3]
        var i = self.buf[2, 0]
        var j = self.buf[2, 1]
        var k = self.buf[2, 2]
        var l = self.buf[2, 3]
        var m = self.buf[3, 0]
        var n = self.buf[3, 1]
        var o = self.buf[3, 2]
        var p = self.buf[3, 3]

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

        var out = Mat4[dtype](0.0)
        # Compute inverse matrix (transpose of cofactors multiplied by the reciprocal determinant):
        out.buf[0, 0] = A * inv_det
        out.buf[0, 1] = (
            -(b * (k * p - l * o) - c * (j * p - l * n) + d * (j * o - k * n))
            * inv_det
        )
        out.buf[0, 2] = (
            b * (g * p - h * o) - c * (f * p - h * n) + d * (f * o - g * n)
        ) * inv_det
        out.buf[0, 3] = (
            -(b * (g * l - h * k) - c * (f * l - h * j) + d * (f * k - g * j))
            * inv_det
        )

        out.buf[1, 0] = B * inv_det
        out.buf[1, 1] = (
            a * (k * p - l * o) - c * (i * p - l * m) + d * (i * o - k * m)
        ) * inv_det
        out.buf[1, 2] = (
            -(a * (g * p - h * o) - c * (e * p - h * m) + d * (e * o - g * m))
            * inv_det
        )
        out.buf[1, 3] = (
            a * (g * l - h * k) - c * (e * l - h * i) + d * (e * k - g * i)
        ) * inv_det

        out.buf[2, 0] = C * inv_det
        out.buf[2, 1] = (
            -(a * (j * p - l * n) - b * (i * p - l * m) + d * (i * n - j * m))
            * inv_det
        )
        out.buf[2, 2] = (
            a * (g * p - h * n) - b * (e * p - h * m) + d * (e * n - g * m)
        ) * inv_det
        out.buf[2, 3] = (
            -(a * (g * l - h * j) - b * (e * l - h * i) + d * (e * j - g * i))
            * inv_det
        )

        out.buf[3, 0] = D * inv_det
        out.buf[3, 1] = (
            a * (j * o - k * n) - b * (i * o - k * m) + c * (i * n - j * m)
        ) * inv_det
        out.buf[3, 2] = (
            -(a * (g * o - h * n) - b * (e * o - h * m) + c * (e * n - g * m))
            * inv_det
        )
        out.buf[3, 3] = (
            a * (g * k - h * j) - b * (e * k - h * i) + c * (e * j - g * i)
        ) * inv_det

        return out


alias Mat2 = Matrix[_, 2, 2]
alias Mat3 = Matrix[_, 3, 3]
alias Mat4 = Matrix[_, 4, 4]

alias Mat2f = Mat2[f32]
alias Mat3f = Mat3[f32]
alias Mat4f = Mat4[f32]

alias Mat2i = Mat2[i32]
alias Mat3i = Mat3[i32]
alias Mat4i = Mat4[i32]
