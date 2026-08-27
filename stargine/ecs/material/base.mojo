import opengl as gl
from std.utils import Variant
from ...core.linalg import Mat4f, Matrix, Vec
from ...core.shader import Shader
from ...core.texture import Texture

# The dtypes and component counts OpenGL accepts for a uniform.
comptime UNIFORM_DTYPES = [DType.float32, DType.int32, DType.uint32]
comptime MAX_COMPONENTS = 4

comptime UniformValue = Variant[
    Vec[DType.float32, 1],
    Vec[DType.float32, 2],
    Vec[DType.float32, 3],
    Vec[DType.float32, 4],
    Vec[DType.int32, 1],
    Vec[DType.int32, 2],
    Vec[DType.int32, 3],
    Vec[DType.int32, 4],
    Vec[DType.uint32, 1],
    Vec[DType.uint32, 2],
    Vec[DType.uint32, 3],
    Vec[DType.uint32, 4],
]


struct Material(Copyable, Movable):
    var name: String
    var shader: Shader
    var textures: Dict[String, Texture]
    var uniforms: Dict[String, UniformValue]
    var uniform_matrices: Dict[String, Mat4f]

    def __init__(out self, var name: String, var shader: Shader):
        self.name = name^
        self.shader = shader^
        self.uniforms = {}
        self.uniform_matrices = {}
        self.textures = {}

    def bind(self) raises:
        # TODO: only re-upload the uniforms that changed since the last bind
        self.shader.use()
        for el in self.uniforms.items():
            self._set_uniform(el.key, el.value)

        for el in self.uniform_matrices.items():
            self.shader.set_uniform(el.key, el.value)

        var index = 0
        for el in self.textures.items():
            var unit = gl.TextureUnit(UInt32(Int(gl.TextureUnit.GL_TEXTURE0) + index))
            if Int(unit) > Int(gl.TextureUnit.GL_TEXTURE31):
                print("Error: too many textures. Texture", el.key, "will be ignored.")
                break
            el.value.bind(unit)
            self.shader.set_uniform(el.key, unit)
            index += 1

    def set_texture(mut self, var name: String, var texture: Texture):
        self.textures[name^] = texture^

    def set_vec[N: Int, dtype: DType](mut self, var name: String, value: Vec[dtype, N]):
        self.uniforms[name^] = UniformValue(value)

    def set_scalar[dtype: DType](mut self, var name: String, value: Scalar[dtype]):
        self.set_vec(name^, Vec[dtype, 1](value))

    def set_bool(mut self, var name: String, value: Bool):
        self.set_scalar(name^, Int32(Int(value)))

    def set_matrix[dim: Int](mut self, var name: String, value: Matrix[DType.float32, dim, dim]):
        comptime assert dim == 4, "only 4x4 uniform matrices are supported"
        self.uniform_matrices[name^] = rebind[Mat4f](value)

    def _set_uniform(self, var name: String, value: UniformValue) raises:
        comptime for d in range(len(UNIFORM_DTYPES)):
            comptime for n in range(1, MAX_COMPONENTS + 1):
                comptime V = Vec[UNIFORM_DTYPES[d], n]
                if value.isa[V]():
                    self.shader.set_uniform(name^, value[V])
                    return
