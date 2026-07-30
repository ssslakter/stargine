from ...core.shader import *
from ...core.texture import *

# TODO: use list comprehensions with parameters when they are supported
comptime UniformValue = Variant[
    Vec2f,
    Vec2i,
    Vec2u,
    Vec[DType.float32, 1],
    Vec[DType.int32, 1],
    Vec[DType.int64, 1],
    Vec[DType.uint8, 1],
    Vec[DType.uint16, 1],
    Vec[DType.uint32, 1],
]

# TODO: group with UniformValue when https://github.com/modular/modular/issues/4578 is fixed
comptime UniformValueSIMD16 = Variant[
    Vec4f,
    Vec3f,
    Vec4i,
    Vec3i,
    Vec4u,
    Vec3u,
]


struct Material(Movable, Copyable):
    var name: String
    var shader: Shader
    var textures: Dict[String, Texture]
    var uniforms: Dict[String, UniformValue]
    var uniforms_SIMD16: Dict[String, UniformValueSIMD16]
    var uniform_matrices: Dict[String, Mat4f]

    def __init__(out self, var name: String, var shader: Shader):
        self.name = name
        self.shader = shader^
        self.uniforms = {}
        self.uniforms_SIMD16 = {}
        self.uniform_matrices = {}
        self.textures = {}

    def bind(self) raises:
        # TODO: optimize this to not bind every frame
        self.shader.use()
        for el in self.uniforms.items():
            self._set_uniform(el.key, el.value)

        for el in self.uniforms_SIMD16.items():
            self._set_uniform(el.key, el.value)

        for el in self.uniform_matrices.items():
            self.shader.set_uniform(el.key, el.value)

        idx = 0
        for el in self.textures.items():
            unit = gl.TextureUnit(UInt32(Int(gl.TextureUnit.GL_TEXTURE0) + idx))
            if Int(unit) > Int(gl.TextureUnit.GL_TEXTURE31):
                print("Error: too many textures. Texture", el.key, "will be ignored.")
                break
            el.value.bind(unit)
            self.shader.set_uniform(el.key, unit)
            idx += 1

    def set_texture(mut self, var name: String, var texture: Texture):
        self.textures[name] = texture^

    def set_scalar[dtype: DType](mut self, var name: String, value: Scalar[dtype]):
        self.set_vec(name, Vec[dtype, 1](value))

    def set_bool(mut self, var name: String, value: Bool) raises:
        self.shader.set_uniform(name, Int32(Int(value)))

    def set_vec[N: Int, dtype: DType](mut self, var name: String, value: Vec[dtype, N]):
        comptime
        if N in [1, 2]:
            self.uniforms[name] = UniformValue(value)
        elif N in [3, 4]:
            self.uniforms_SIMD16[name] = UniformValueSIMD16(value)
        else:
            print("Error: unsupported vector size. Uniform value will be ignored.")

    def set_matrix[dim: Int](mut self, var name: String, value: Matrix[DType.float32, dim, dim]):
        comptime
        if dim == 4:
            var m = rebind[Mat4f](value)
            self.uniform_matrices[name] = m
        else:
            print("Error: unsupported matrix size. Uniform value will be ignored.")

    def _set_uniform(self, var name: String, value: UniformValue) raises:
        # TODO this looks like a hack
        if value.isa[Vec2f]():
            self.shader.set_uniform(name, value[Vec2f])
        elif value.isa[Vec2i]():
            self.shader.set_uniform(name, value[Vec2i])
        elif value.isa[Vec2u]():
            self.shader.set_uniform(name, value[Vec2u])
        elif value.isa[Vec[DType.float32, 1]]():
            self.shader.set_uniform(name, value[Vec[DType.float32, 1]])
        elif value.isa[Vec[DType.int32, 1]]():
            self.shader.set_uniform(name, value[Vec[DType.int32, 1]])
        elif value.isa[Vec[DType.int64, 1]]():
            self.shader.set_uniform(name, value[Vec[DType.int64, 1]])
        elif value.isa[Vec[DType.uint8, 1]]():
            self.shader.set_uniform(name, value[Vec[DType.uint8, 1]])
        elif value.isa[Vec[DType.uint16, 1]]():
            self.shader.set_uniform(name, value[Vec[DType.uint16, 1]])
        elif value.isa[Vec[DType.uint32, 1]]():
            self.shader.set_uniform(name, value[Vec[DType.uint32, 1]])

    def _set_uniform(self, var name: String, value: UniformValueSIMD16) raises:
        if value.isa[Vec4f]():
            self.shader.set_uniform(name, value[Vec4f])
        elif value.isa[Vec3f]():
            self.shader.set_uniform(name, value[Vec3f])
        elif value.isa[Vec4i]():
            self.shader.set_uniform(name, value[Vec4i])
        elif value.isa[Vec3i]():
            self.shader.set_uniform(name, value[Vec3i])
        elif value.isa[Vec4u]():
            self.shader.set_uniform(name, value[Vec4u])
        elif value.isa[Vec3u]():
            self.shader.set_uniform(name, value[Vec3u])
