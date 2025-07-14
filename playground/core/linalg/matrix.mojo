from .vector import *
from buffer import *


struct Matrix[dtype: DType, rows: Int, cols: Int](Copyable, Movable, Writable):
    alias rank = 2
    # TODO: maybe use SIMD to speed up
    alias Data = InlineArray[Scalar[dtype], rows * cols]
    alias Buffer = NDBuffer[dtype, Self.rank, MutableAnyOrigin]
    var buf: Self.Buffer
    var data: Self.Data

    fn __init__(out self, value: Scalar[dtype] = 0.0):
        self.data = Self.Data(fill=value)
        self.buf = Self.Buffer(self.data.unsafe_ptr(), (rows, cols))

    fn __init__(out self: Mat3[dtype], rows: Tuple[Vec3[dtype], Vec3[dtype], Vec3[dtype]]):
        alias dims = 3
        self = Mat3[dtype]()
        @parameter
        for i in range(dims):
            for j in range(dims):
                self.buf[i, j] = rows[i][j]

    fn __init__(out self: Mat4[dtype], rows: Tuple[Vec4[dtype], Vec4[dtype], Vec4[dtype], Vec4[dtype]]):
        alias dims = 4
        self = Mat4[dtype]()
        @parameter
        for i in range(dims):
            for j in range(dims):
                self.buf[i, j] = rows[i][j]

    fn __init__(out self, rows: List[Vec[dtype, cols]]):
        self = Self()
        for i in range(len(rows)):
            for j in range(Self.cols):
                self.buf[i, j] = rows[i][j]

    fn __copyinit__(out self, other: Self):
        self.data = other.data
        self.buf = Self.Buffer(self.data.unsafe_ptr(), (rows, cols))

    fn __moveinit__(out self, owned other: Self):
        self.data = other.data^
        self.buf = Self.Buffer(self.data.unsafe_ptr(), (rows, cols))

    fn write_to[W: Writer](self, mut writer: W):
        writer.write("Matrix(\n")
        for i in range(self.rows):
            writer.write("    [")
            for j in range(self.cols):
                writer.write(self.buf[i, j])
                if j < self.cols - 1:
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
    fn id() -> Matrix[dtype, rows, rows]:
        return Self.diag(1.0)

    @staticmethod
    fn diag(value: Vec[dtype, rows]) -> Matrix[dtype, rows, rows]:
        var self = Matrix[dtype, rows, rows](0.0)
        for i in range(rows):
            self.buf[i, i] = value[i]

        return self

    @staticmethod
    fn diag(value: Scalar[dtype]) -> Matrix[dtype, rows, rows]:
        return Self.diag(Vec[dtype, rows](value))

    fn transpose(owned self) -> Matrix[dtype, cols, rows]:
        var out = Matrix[dtype, cols, rows]()
        for i in range(self.rows):
            for j in range(self.cols):
                out.buf[j, i] = self.buf[i, j]
        return out

    fn __add__(owned self, other: Self) -> Self:
        constrained[self.rows == other.rows and self.cols == other.cols, "Matrices must have the same dimensions"]()
        for i in range(self.rows):
            for j in range(self.cols):
                self.buf[i, j] = self.buf[i, j] + other.buf[i, j]

        return self

    fn __neg__(owned self) -> Self:
        for i in range(self.rows):
            for j in range(self.cols):
                self.buf[i, j] = -self.buf[i, j]
        return self

    fn __sub__(owned self, owned other: Self) -> Self:
        return self + (-other)

    fn __mul__(owned self, other: Scalar[dtype]) -> Self:
        for i in range(self.rows):
            for j in range(self.cols):
                self.buf[i, j] = self.buf[i, j] * other
        return self

    fn __mul__(owned self, owned other: Self) -> Self:
        constrained[self.cols == other.cols and self.rows == other.rows, "Matrices must have the same dimensions"]()
        var out = Self()
        for i in range(self.rows):
            for j in range(self.cols):
                out.buf[i, j] = self.buf[i, j] * other.buf[i, j]
        return out

    fn matmul[other_cols: Int](self, other: Matrix[dtype, cols, other_cols]) -> Matrix[dtype, rows, other_cols]:
        var out = Matrix[dtype, rows, other_cols](0.0)
        for i in range(self.rows):
            for j in range(other.cols):
                for k in range(self.cols):
                    out.buf[i, j] = out.buf[i, j] + self.buf[i, k] * other.buf[k, j]
        return out

    fn matmul(self, other: Vec[dtype, cols]) -> Vec[dtype, rows]:
        var out = Vec[dtype, rows]()
        for i in range(self.rows):
            for j in range(self.cols):
                out[i] = out[i] + self.buf[i, j] * other[j]
        return out

    fn __truediv__(owned self, other: Scalar[dtype]) -> Self:
        return self * (1.0 / other)

    fn __pow__(owned self, other: Int) -> Self:
        var out = Self()
        for i in range(self.rows):
            for j in range(self.cols):
                out.buf[i, j] = self.buf[i, j] ** other
        return out

    fn __mod__(owned self, other: Scalar[dtype]) -> Self:
        for i in range(self.rows):
            for j in range(self.cols):
                self.buf[i, j] = self.buf[i, j] % other
        return self

alias Mat2 = Matrix[_, 2, 2]
alias Mat3 = Matrix[_, 3, 3]
alias Mat4 = Matrix[_, 4, 4]

alias Mat2f = Mat2[f32]
alias Mat3f = Mat3[f32]
alias Mat4f = Mat4[f32]

alias Mat2i = Mat2[i32]
alias Mat3i = Mat3[i32]
alias Mat4i = Mat4[i32]