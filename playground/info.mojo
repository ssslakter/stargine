import opengl as gl
from .utils import *


fn get_gl_int_param(name: gl.GetPName) -> Int32:
    var val: Int32 = 0
    gl.get_integerv(name, Ptr(to=val))
    return val
