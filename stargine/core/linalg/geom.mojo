from std.math import cos, sin, tan
from .vector import Vec, Vec3, Vec4
from .matrix import Mat4


@always_inline
def translate[dtype: DType](vec: Vec[dtype, 3]) -> Mat4[dtype]:
    var out = Mat4[dtype].id()
    out[0, 3] = vec[0]
    out[1, 3] = vec[1]
    out[2, 3] = vec[2]
    return out

@always_inline
def scale[dtype: DType](vec: Vec[dtype, 3]) -> Mat4[dtype]:
    return Mat4[dtype].diag(Vec4[dtype](vec, 1.0))


@always_inline
def rotate[dtype: DType](angle: Scalar[dtype], axis: Vec[dtype, 3]) -> Mat4[dtype] where dtype.is_floating_point():
    var out = Mat4[dtype]()
    var ax = axis.normalize()
    var cos_theta = cos(angle)
    var sin_theta = sin(angle)
    var t = 1.0 - cos_theta
    var x = ax[0]
    var y = ax[1]
    var z = ax[2]
    out[0, 0] = t * x * x + cos_theta
    out[1, 1] = t * y * y + cos_theta
    out[2, 2] = t * z * z + cos_theta
    out[0, 1] = t * x * y - sin_theta * z
    out[0, 2] = t * x * z + sin_theta * y
    out[1, 0] = t * x * y + sin_theta * z
    out[1, 2] = t * y * z - sin_theta * x
    out[2, 0] = t * x * z - sin_theta * y
    out[2, 1] = t * y * z + sin_theta * x
    return out

@always_inline
def ortho[dtype: DType](left: Scalar[dtype], right: Scalar[dtype], bottom: Scalar[dtype], top: Scalar[dtype], near: Scalar[dtype], far: Scalar[dtype]) -> Mat4[dtype]:
    var mat = Mat4[dtype]()
    mat[0, 0] = 2.0 / (right - left)
    mat[1, 1] = 2.0 / (top - bottom)
    mat[2, 2] = -2.0 / (far - near)
    mat[0, 3] = -(right + left) / (right - left)
    mat[1, 3] = -(top + bottom) / (top - bottom)
    mat[2, 3] = -(far + near) / (far - near)
    return mat

@always_inline
def perspective[dtype: DType](fov: Scalar[dtype], aspect_ratio: Scalar[dtype], near: Scalar[dtype], far: Scalar[dtype]) -> Mat4[dtype] where dtype.is_floating_point():
    var f = 1.0 / tan(fov / 2.0)
    var mat = Mat4[dtype]()
    mat[0, 0] = f / aspect_ratio
    mat[1, 1] = f
    mat[2, 2] = (far + near) / (near - far)
    mat[2, 3] = (2.0 * near * far) / (near - far)
    mat[3, 2] = -1.0
    mat[3, 3] = 0.0
    return mat

@always_inline
def look_at[dtype: DType](eye: Vec[dtype, 3], center: Vec[dtype, 3], up: Vec[dtype, 3]) -> Mat4[dtype] where dtype.is_floating_point():
    var fwd = (eye - center).normalize()
    var right = fwd.cross(up).normalize()
    var up_new = right.cross(fwd).normalize()
    return Mat4[dtype](
        [Vec4[dtype](right, -right.dot(eye)),
         Vec4[dtype](up_new, -up_new.dot(eye)),
         Vec4[dtype](fwd, -fwd.dot(eye)),
         Vec4[dtype](0.0, 0.0, 0.0, 1.0)]
    )

