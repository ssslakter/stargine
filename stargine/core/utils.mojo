from std.python import Python, PythonObject
from std.memory import alloc, memcpy
from .imports import *

comptime ListElement = Copyable
comptime Ptr = UnsafePointer
comptime Id = UInt32


def print_list[T: Writable & Movable & Copyable](list: List[T]):
    print("[", end="")
    for item in list:
        print(item, end=",\n")
    print("]")


def read_file[PathLike: os.PathLike](path: PathLike) raises -> String:
    with open(path, "r") as file:
        return file.read()


comptime numpy_dtype_map = {
    DType.bool: 'bool',
    DType.int8: 'int8',
    DType.int16: 'int16',
    DType.int32: 'int32',
    DType.int64: 'int64',
    DType.uint8: 'uint8',
    DType.uint16: 'uint16',
    DType.uint32: 'uint32',
    DType.uint64: 'uint64',
    DType.float16: 'float16',
    DType.float32: 'float32',
    DType.float64: 'float64'
}


def from_numpy[dtype: DType, rank: Int](array: PythonObject) raises -> UnsafePointer[Scalar[dtype], MutUntrackedOrigin]:
    np = Python.import_module("numpy")
    arr = np.ascontiguousarray(array)
    if arr.ndim != rank:
        raise Error("Incorrect numpy rank: ", String(arr.ndim), ", expected: ", rank)
    if materialize[numpy_dtype_map]()[dtype] != String(arr.dtype):
        raise Error("Incorrect numpy dtype: ", String(arr.dtype), ", expected: ", materialize[numpy_dtype_map]()[dtype])
    src = arr.ctypes.data.unsafe_get_as_pointer[dtype]()
    var size = Int(Python.py_long_as_ssize_t(arr.size.__int__()))
    dst = alloc[Scalar[dtype]](size)
    memcpy(dest=dst, src=src, count=size)
    return dst


struct NDArray[dtype: DType, rank: Int]:
    var data: UnsafePointer[Scalar[Self.dtype], MutUntrackedOrigin]
    var shape: Array[Int, Self.rank]

    @always_inline
    def __init__(out self, array: PythonObject) raises:
        self.data = from_numpy[Self.dtype, Self.rank](array)
        self.shape = Array[Int, Self.rank](fill=0)
        for i in range(Self.rank):
            self.shape[i] = Int(Python.py_long_as_ssize_t(array.shape[i].__int__()))

    @always_inline
    def get_shape(self) -> Array[Int, Self.rank]:
        return self.shape
