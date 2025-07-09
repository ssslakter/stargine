from memory import ArcPointer
from utils.index import IndexList
from python import Python, PythonObject
from buffer import NDBuffer
from memory import memcpy
from .imports import *

alias ListElement = Copyable & Movable
alias Ptr = UnsafePointer
alias Id = UInt32


fn print_list[T: Writable & Movable & Copyable](list: List[T]):
    print("[", end="")
    for item in list:
        print(item, end=",\n")
    print("]")


def read_file[PathLike: os.PathLike](path: PathLike) -> String:
    with open(path, "r") as file:
        return file.read()


alias numpy_dtype_map = {
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


fn from_numpy[dtype: DType, rank: Int](array: PythonObject) raises -> UnsafePointer[Scalar[dtype]]:
    np = Python.import_module("numpy")
    arr = np.ascontiguousarray(array)
    if arr.ndim != rank:
        raise Error("Incorrect numpy rank: ", String(arr.ndim), ", expected: ", rank)
    if numpy_dtype_map[dtype] != String(arr.dtype):
        raise Error("Incorrect numpy dtype: ", String(arr.dtype), ", expected: ", numpy_dtype_map[dtype])
    src = arr.ctypes.data.unsafe_get_as_pointer[dtype]()
    dst = UnsafePointer[Scalar[dtype]].alloc(Int(arr.size))
    memcpy(dst, src, Int(arr.size))
    return dst


struct NDArray[dtype: DType, rank: Int]:
    var data: UnsafePointer[Scalar[dtype]]
    var buf: NDBuffer[dtype, rank, MutableAnyOrigin]

    @always_inline
    fn __init__(out self, array: PythonObject) raises:
        self.data = from_numpy[dtype, rank](array)
        index_list = IndexList[rank]()
        for i in range(rank):
            index_list[i] = Int(array.shape[i])
        self.buf = NDBuffer[dtype, rank, MutableAnyOrigin](self.data, dynamic_shape=index_list)

    @always_inline
    fn get_shape(self) -> IndexList[rank]:
        return self.buf.get_shape()