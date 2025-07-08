from buffer import *

struct HostNDBuffer[dtype: DType, rank: Int, 
shape: DimList = DimList.create_unknown[rank](),
    strides: DimList = DimList.create_unknown[rank]()]:
    pass