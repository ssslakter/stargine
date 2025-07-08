from math import *
from .vector import *
from .matrix import *



fn translate[dtype: DType](owned mat: Mat4[dtype], vec: Vec[dtype, 3]) -> Mat4[dtype]:
    mat.buf[0, 3] = vec[0]
    mat.buf[1, 3] = vec[1]
    mat.buf[2, 3] = vec[2]
    return mat

fn scale[dtype: DType](owned mat: Mat4[dtype], vec: Vec[dtype, 3]) -> Mat4[dtype]:
    mat.buf[0, 0] = vec[0]
    mat.buf[1, 1] = vec[1]
    mat.buf[2, 2] = vec[2]
    return mat

fn rotate[dtype: DType](owned mat: Mat4[dtype], angle: Scalar[dtype], axis: Vec[dtype, 3]) -> Mat4[dtype]:
    var ax = axis.normalize()
    var cos_theta = cos(angle)
    var sin_theta = sin(angle)
    var t = 1.0 - cos_theta
    var x = ax[0]
    var y = ax[1]
    var z = ax[2]
    mat.buf[0, 0] = t * x * x + cos_theta
    mat.buf[1, 1] = t * y * y + cos_theta
    mat.buf[2, 2] = t * z * z + cos_theta
    mat.buf[0, 1] = t * x * y - sin_theta * z
    mat.buf[0, 2] = t * x * z + sin_theta * y
    mat.buf[1, 0] = t * x * y + sin_theta * z
    mat.buf[1, 2] = t * y * z - sin_theta * x
    mat.buf[2, 0] = t * x * z - sin_theta * y
    mat.buf[2, 1] = t * y * z + sin_theta * x
    return mat

fn ortho[dtype: DType](owned mat: Mat4[dtype], left: Scalar[dtype], right: Scalar[dtype], bottom: Scalar[dtype], top: Scalar[dtype], near: Scalar[dtype], far: Scalar[dtype]) -> Mat4[dtype]:
    mat.buf[0, 0] = 2.0 / (right - left)
    mat.buf[1, 1] = 2.0 / (top - bottom)
    mat.buf[2, 2] = -2.0 / (far - near)
    mat.buf[0, 3] = -(right + left) / (right - left)
    mat.buf[1, 3] = -(top + bottom) / (top - bottom)
    mat.buf[2, 3] = -(far + near) / (far - near)
    return mat

fn perspective[dtype: DType](owned mat: Mat4[dtype], fov: Scalar[dtype], aspect_ratio: Scalar[dtype], near: Scalar[dtype], far: Scalar[dtype]) -> Mat4[dtype]:
    var f = 1.0 / tan(fov / 2.0)
    mat.buf[0, 0] = f / aspect_ratio
    mat.buf[1, 1] = f
    mat.buf[2, 2] = (near + far) / (near - far)
    mat.buf[2, 3] = -1.0
    mat.buf[3, 2] = (2.0 * near * far) / (near - far)
    return mat
