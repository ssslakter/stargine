# from utils.static_tuple import StaticTuple

# @fieldwise_init
# struct Mat[nrows: Int, ncols: Int, DType: DType]:
#     var data: StaticTuple[Vec[ncols, DType], nrows]

#     fn __init__() -> Self:
#         var data: StaticTuple[Vec[ncols, DType], nrows]
#         @parameter
#         for i in range(nrows):
#             data[i] = Vec[ncols, DType]()
#         return Self(data=data)

#     @always_inline
#     fn row(self, i: Int) -> Vec[ncols, DType]:
#         return self.data[i]

#     @always_inline
#     fn col(self, j: Int) -> Vec[nrows, DType]:
#         var res: Vec[nrows, DType]
#         @parameter
#         for i in range(nrows):
#             res[i] = self.data[i][j]
#         return res

#     @always_inline
#     fn __mul__[C2: Int](self, other: Mat[nrows, C2, DType]) -> Mat[nrows, C2, DType]:
#         var res: Mat[nrows, C2, DType]
#         @parameter
#         for i in range(nrows):
#             @parameter
#             for j in range(C2):
#                 res.data[i][j] = self.row(i).dot(other.col(j))
#         return res
    
#     @always_inline
#     fn __mul__(self, other: Vec[ncols, DType]) -> Vec[nrows, DType]:
#         var res: Vec[nrows, DType]
#         @parameter
#         for i in range(nrows):
#             res[i] = self.row(i).dot(other)
#         return res