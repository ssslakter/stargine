from std.memory import unsafe_memcpy
from std.os import PathLike
from std.python import Python, PythonObject

comptime Ptr = Pointer
comptime Id = UInt32

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


def read_file[T: PathLike](path: T) raises -> String:
    with open(path, "r") as file:
        return file.read()


def from_numpy[dtype: DType, rank: Int](array: PythonObject) raises -> List[Scalar[dtype]]:
    """Copies a numpy array into owned Mojo memory, so it outlives the Python object."""
    var np = Python.import_module("numpy")
    var arr = np.ascontiguousarray(array)
    if arr.ndim != rank:
        raise Error("Incorrect numpy rank: ", String(arr.ndim), ", expected: ", rank)
    if materialize[numpy_dtype_map]()[dtype] != String(arr.dtype):
        raise Error("Incorrect numpy dtype: ", String(arr.dtype), ", expected: ", materialize[numpy_dtype_map]()[dtype])

    var size = Int(Python.py_long_as_ssize_t(arr.size.__int__()))
    var data = List[Scalar[dtype]](length=size, fill=0)
    unsafe_memcpy(dest=data.unsafe_ptr(), src=arr.ctypes.data.unsafe_get_as_pointer[dtype](), count=size)
    return data^


struct NDArray[dtype: DType, rank: Int](Movable):
    """A contiguous, owned copy of a numpy array."""

    var data: List[Scalar[Self.dtype]]
    var shape: Array[Int, Self.rank]

    def __init__(out self, array: PythonObject) raises:
        self.data = from_numpy[Self.dtype, Self.rank](array)
        self.shape = Array[Int, Self.rank](fill=0)
        for i in range(Self.rank):
            self.shape[i] = Int(Python.py_long_as_ssize_t(array.shape[i].__int__()))
