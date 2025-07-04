from utils.index import IndexList
from python import Python, PythonObject
from buffer import NDBuffer
from python._cpython import PyObjectPtr

@fieldwise_init
struct PyArrayObject[dtype: DType](Copyable, Movable):
    """
    Container for a numpy array.

    See: https://numpy.org/doc/2.1/reference/c-api/types-and-structures.html#c.PyArrayObject
    """

    var data: UnsafePointer[Scalar[dtype]]
    var nd: Int
    var dimensions: UnsafePointer[Int]
    var strides: UnsafePointer[Int]
    var base: PyObjectPtr
    var descr: PyObjectPtr
    var flags: Int
    var weakreflist: PyObjectPtr

    # version dependent private members are omitted
    # ...


def from_numpy[dtype: DType, rank: Int](py_array_object: PythonObject) -> NDBuffer[dtype, rank=rank, origin=MutableAnyOrigin]:
    py_arr_ptr = UnsafePointer[PyArrayObject[dtype], **_](unchecked_downcast_value=py_array_object)
    py_arr = py_arr_ptr[]
    if py_arr.nd != rank:
        raise Error(String("NumPy array rank mismatch: {} != {}").format(py_arr.nd, rank))
    var shape = IndexList[rank]()
    for i in range(rank):
        shape[i] = Int(py_arr.dimensions[i])
    return NDBuffer[dtype, rank=rank, origin=MutableAnyOrigin](py_arr.data, dynamic_shape=shape)
