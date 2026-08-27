from .vector import Vec, Vec3, Vec4, f32, i32


struct Matrix[dtype: DType, nrows: Int, ncols: Int](ImplicitlyCopyable, Movable, Writable):
    """A dense row-major matrix whose rows are SIMD vectors."""

    comptime Row = Vec[Self.dtype, Self.ncols]

    var rows: Array[Self.Row, Self.nrows]

    def __init__(out self, value: Scalar[Self.dtype] = 0.0):
        self.rows = Array[Self.Row, Self.nrows](fill=Self.Row(value))

    def __init__(out self, *, copy: Self):
        self.rows = copy.rows.copy()

    def __init__[r: Int, c: Int](out self, other: Matrix[Self.dtype, r, c]):
        """Embeds `other` in the top-left corner, zeroing anything it does not cover."""
        self = Self()
        comptime for i in range(min(Self.nrows, r)):
            comptime for j in range(min(Self.ncols, c)):
                self[i, j] = other[i, j]

    def __init__(out self, rows: List[Self.Row]):
        self = Self()
        for i in range(min(len(rows), Self.nrows)):
            self.rows[i] = rows[i]

    @always_inline
    def __getitem__(self, row: Int, col: Int) -> Scalar[Self.dtype]:
        return self.rows[row][col]

    @always_inline
    def __setitem__(mut self, row: Int, col: Int, value: Scalar[Self.dtype]):
        self.rows[row][col] = value

    def write_to(self, mut writer: Some[Writer]):
        writer.write("Matrix(\n")
        for i in range(Self.nrows):
            writer.write("    [")
            for j in range(Self.ncols):
                writer.write(self[i, j])
                if j < Self.ncols - 1:
                    writer.write(", ")
            writer.write("]\n")
        writer.write(")")

    def fill(mut self, value: Scalar[Self.dtype]):
        self.rows = Array[Self.Row, Self.nrows](fill=Self.Row(value))

    def flatten(self) -> Array[Scalar[Self.dtype], Self.nrows * Self.ncols]:
        """Packs the rows without their SIMD padding, ready to hand to OpenGL."""
        var out = Array[Scalar[Self.dtype], Self.nrows * Self.ncols](fill=0)
        comptime for i in range(Self.nrows):
            comptime for j in range(Self.ncols):
                out[i * Self.ncols + j] = self[i, j]
        return out^

    @staticmethod
    def id() -> Matrix[Self.dtype, Self.nrows, Self.nrows]:
        return Self.diag(1.0)

    @staticmethod
    def diag(value: Vec[Self.dtype, Self.nrows]) -> Matrix[Self.dtype, Self.nrows, Self.nrows]:
        var out = Matrix[Self.dtype, Self.nrows, Self.nrows]()
        for i in range(Self.nrows):
            out[i, i] = value[i]
        return out^

    @staticmethod
    def diag(value: Scalar[Self.dtype]) -> Matrix[Self.dtype, Self.nrows, Self.nrows]:
        return Self.diag(Vec[Self.dtype, Self.nrows](value))

    def transpose(self) -> Matrix[Self.dtype, Self.ncols, Self.nrows]:
        var out = Matrix[Self.dtype, Self.ncols, Self.nrows]()
        comptime for i in range(Self.nrows):
            comptime for j in range(Self.ncols):
                out[j, i] = self[i, j]
        return out^

    def __add__(self, other: Self) -> Self:
        var out = Self()
        comptime for i in range(Self.nrows):
            out.rows[i] = self.rows[i] + other.rows[i]
        return out^

    def __sub__(self, other: Self) -> Self:
        var out = Self()
        comptime for i in range(Self.nrows):
            out.rows[i] = self.rows[i] - other.rows[i]
        return out^

    def __neg__(self) -> Self:
        var out = Self()
        comptime for i in range(Self.nrows):
            out.rows[i] = -self.rows[i]
        return out^

    def __mul__(self, other: Scalar[Self.dtype]) -> Self:
        var out = Self()
        comptime for i in range(Self.nrows):
            out.rows[i] = self.rows[i] * other
        return out^

    def __mul__(self, other: Self) -> Self:
        """Element-wise product; use `matmul` for the linear-algebra product."""
        var out = Self()
        comptime for i in range(Self.nrows):
            out.rows[i] = self.rows[i] * other.rows[i]
        return out^

    def __truediv__(self, other: Scalar[Self.dtype]) -> Self:
        return self * (1.0 / other)

    def __pow__(self, other: Int) -> Self:
        var out = Self()
        comptime for i in range(Self.nrows):
            comptime for j in range(Self.ncols):
                out[i, j] = self[i, j] ** other
        return out^

    def __mod__(self, other: Scalar[Self.dtype]) -> Self:
        var out = Self()
        comptime for i in range(Self.nrows):
            comptime for j in range(Self.ncols):
                out[i, j] = self[i, j] % other
        return out^

    def matmul[other_cols: Int](
        self, other: Matrix[Self.dtype, Self.ncols, other_cols]
    ) -> Matrix[Self.dtype, Self.nrows, other_cols]:
        var out = Matrix[Self.dtype, Self.nrows, other_cols]()
        comptime for i in range(Self.nrows):
            var row = Vec[Self.dtype, other_cols]()
            comptime for k in range(Self.ncols):
                row += other.rows[k] * self[i, k]
            out.rows[i] = row
        return out^

    def matmul(self, other: Self.Row) -> Vec[Self.dtype, Self.nrows]:
        var out = Vec[Self.dtype, Self.nrows]()
        comptime for i in range(Self.nrows):
            out[i] = self.rows[i].dot(other)
        return out^

    def _minor(self, row: Int, col: Int) -> Scalar[Self.dtype] where Self.nrows == 4 and Self.ncols == 4:
        """Determinant of the 3x3 matrix left after deleting `row` and `col`."""
        var m = Matrix[Self.dtype, 3, 3]()
        var r = 0
        for i in range(4):
            if i == row:
                continue
            var c = 0
            for j in range(4):
                if j == col:
                    continue
                m[r, c] = self[i, j]
                c += 1
            r += 1
        return (
            m[0, 0] * (m[1, 1] * m[2, 2] - m[1, 2] * m[2, 1])
            - m[0, 1] * (m[1, 0] * m[2, 2] - m[1, 2] * m[2, 0])
            + m[0, 2] * (m[1, 0] * m[2, 1] - m[1, 1] * m[2, 0])
        )

    def inverse(self) -> Self where Self.nrows == Self.ncols:
        comptime assert Self.nrows >= 2 and Self.nrows <= 4, "inverse is implemented for 2x2, 3x3 and 4x4 matrices"
        var out = Self()

        comptime if Self.nrows == 2:
            var a = self[0, 0]
            var b = self[0, 1]
            var c = self[1, 0]
            var d = self[1, 1]
            var inv_det = 1.0 / (a * d - b * c)
            out[0, 0] = d * inv_det
            out[0, 1] = -b * inv_det
            out[1, 0] = -c * inv_det
            out[1, 1] = a * inv_det
        elif Self.nrows == 3:
            var a = self[0, 0]
            var b = self[0, 1]
            var c = self[0, 2]
            var d = self[1, 0]
            var e = self[1, 1]
            var f = self[1, 2]
            var g = self[2, 0]
            var h = self[2, 1]
            var i = self[2, 2]
            var inv_det = 1.0 / (a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g))
            out[0, 0] = (e * i - f * h) * inv_det
            out[0, 1] = -(b * i - c * h) * inv_det
            out[0, 2] = (b * f - c * e) * inv_det
            out[1, 0] = -(d * i - f * g) * inv_det
            out[1, 1] = (a * i - c * g) * inv_det
            out[1, 2] = -(a * f - c * d) * inv_det
            out[2, 0] = (d * h - e * g) * inv_det
            out[2, 1] = -(a * h - b * g) * inv_det
            out[2, 2] = (a * e - b * d) * inv_det
        else:
            # inverse = adjugate / determinant, and the adjugate is the transposed cofactors.
            var cofactors = Self()
            comptime for i in range(4):
                comptime for j in range(4):
                    var minor = rebind[Matrix[Self.dtype, 4, 4]](self)._minor(i, j)
                    cofactors[i, j] = minor if (i + j) % 2 == 0 else -minor

            var det = Scalar[Self.dtype](0)
            comptime for j in range(4):
                det += self[0, j] * cofactors[0, j]

            var inv_det = 1.0 / det
            comptime for i in range(4):
                comptime for j in range(4):
                    out[i, j] = cofactors[j, i] * inv_det

        return out^


comptime Mat2 = Matrix[_, 2, 2]
comptime Mat3 = Matrix[_, 3, 3]
comptime Mat4 = Matrix[_, 4, 4]

comptime Mat2f = Mat2[f32]
comptime Mat3f = Mat3[f32]
comptime Mat4f = Mat4[f32]

comptime Mat2i = Mat2[i32]
comptime Mat3i = Mat3[i32]
comptime Mat4i = Mat4[i32]
