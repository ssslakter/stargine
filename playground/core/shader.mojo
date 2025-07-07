from utils import Variant
from opengl import ShaderType
from .utils import *
from ..linalg import *


def compile_shader[PathLike: os.PathLike & ListElement](paths: List[PathLike], shader_type: ShaderType) -> Id:
    src = [read_file(path) for path in paths]
    shader = gl.create_shader(shader_type)
    gl.shader_source(shader, len(src), src, UnsafePointer[Int32]())
    gl.compile_shader(shader)
    return shader


struct _ShaderInner(Movable):
    var id: Id

    fn __init__(out self):
        self.id = 0

    fn __init__[PathLike: os.PathLike & ListElement](out self, fragment_path: PathLike, vertex_path: PathLike) raises:
        self = Self([fragment_path], [vertex_path])

    fn __init__[PathLike: os.PathLike & ListElement](out self, fragment_paths: List[PathLike], vertex_paths: List[PathLike]) raises:
        self.id = gl.create_program()
        vertex_shader = compile_shader(vertex_paths, ShaderType.VERTEX_SHADER)
        fragment_shader = compile_shader(fragment_paths, ShaderType.FRAGMENT_SHADER)
        gl.attach_shader(self.id, vertex_shader)
        gl.attach_shader(self.id, fragment_shader)
        gl.link_program(self.id)
        gl.delete_shader(vertex_shader)
        gl.delete_shader(fragment_shader)

    fn __del__(owned self):
        print("deleting shader", self.id)
        gl.delete_program(self.id)

    fn reload[PathLike: os.PathLike & ListElement](mut self, fragment_paths: List[PathLike], vertex_paths: List[PathLike]) raises:
        gl.delete_program(self.id)
        self = Self(fragment_paths, vertex_paths)


# TODO: use list comprehensions with parameters when they are supported
alias UniformValue = Variant[
    Vec2f,
    Vec2i,
    Vec2u,
    Vec[1, DType.float32],
    Vec[1, DType.int32],
    Vec[1, DType.int64],
    Vec[1, DType.uint8],
    Vec[1, DType.uint16],
    Vec[1, DType.uint32],
]

# TODO: group with UniformValue when https://github.com/modular/modular/issues/4578 is fixed
alias UniformValueSIMD16 = Variant[
    Vec4f,
    Vec3f,
    Vec4i,
    Vec3i,
    Vec4u,
    Vec3u,
]


struct Shader(Copyable, Movable):
    var inner: ArcPointer[_ShaderInner]
    var fragment_paths: List[String]
    var vertex_paths: List[String]
    var uniforms: Dict[String, UniformValue]
    var uniforms_SIMD16: Dict[String, UniformValueSIMD16]

    fn __init__(out self):
        self.inner = ArcPointer[_ShaderInner](_ShaderInner())
        self.fragment_paths = []
        self.vertex_paths = []
        self.uniforms = {}
        self.uniforms_SIMD16 = {}
    fn __init__[PathLike: os.PathLike & ListElement & Stringable](out self, fragment_path: PathLike, vertex_path: PathLike) raises:
        self = Self([fragment_path], [vertex_path])

    fn __init__[
        PathLike: os.PathLike & ListElement & Stringable
    ](out self, fragment_paths: List[PathLike], vertex_paths: List[PathLike]) raises:
        self.inner = ArcPointer[_ShaderInner](_ShaderInner(fragment_paths, vertex_paths))
        self.fragment_paths = [String(path) for path in fragment_paths]
        self.vertex_paths = [String(path) for path in vertex_paths]
        self.uniforms = {}
        self.uniforms_SIMD16 = {}
    
    fn reload(owned self) raises:
        print("reloading shader", self.inner[].id)

        var uniforms = self.uniforms.copy()
        var uniforms_SIMD16 = self.uniforms_SIMD16.copy()
        self.inner[].reload(self.fragment_paths, self.vertex_paths)

        for el in uniforms.items():
            self.set_uniform(el.key, el.value)

        for el in uniforms_SIMD16.items():
            self.set_uniform(el.key, el.value)
        

    fn use(self):
        gl.use_program(self.inner[].id)

    fn set_uniform(mut self, owned name: String, texture: Texture):
        self.set_uniform(name, texture.inner[].id)

    fn set_uniform[dtype: DType](mut self, owned name: String, value: Scalar[dtype]):
        self.set_uniform(name, Vec[1, dtype](value))

    fn set_uniform[N: Int, dtype: DType, //](mut self, owned name: String, value: Vec[N, dtype]):
        @parameter
        if N in [1,2]:
            self.uniforms[name] = UniformValue(value)
        elif N in [3,4]:
            self.uniforms_SIMD16[name] = UniformValueSIMD16(value)
        else:
            print("Error: unsupported vector size. Uniform value will be ignored.")
        
        self.use()
        var location = gl.get_uniform_location(self.inner[].id, name)

        @parameter
        if dtype == DType.float32:
            var v = rebind[Vec[N, DType.float32]](value)

            @parameter
            if N == 1:
                gl.uniform1f(location, v.x())
            elif N == 2:
                gl.uniform2f(location, v.x(), v.y())
            elif N == 3:
                gl.uniform3f(location, v.x(), v.y(), v.z())
            elif N == 4:
                gl.uniform4f(location, v.x(), v.y(), v.z(), v.w())
        elif dtype == DType.int32:
            var v = rebind[Vec[N, DType.int32]](value)

            @parameter
            if N == 1:
                gl.uniform1i(location, v.x())
            elif N == 2:
                gl.uniform2i(location, v.x(), v.y())
            elif N == 3:
                gl.uniform3i(location, v.x(), v.y(), v.z())
            elif N == 4:
                gl.uniform4i(location, v.x(), v.y(), v.z(), v.w())
        elif dtype == DType.uint32:
            var v = rebind[Vec[N, DType.uint32]](value)

            @parameter
            if N == 1:
                gl.uniform1ui(location, v.x())
            elif N == 2:
                gl.uniform2ui(location, v.x(), v.y())
            elif N == 3:
                gl.uniform3ui(location, v.x(), v.y(), v.z())
            elif N == 4:
                gl.uniform4ui(location, v.x(), v.y(), v.z(), v.w())

    fn set_uniform(mut self, owned name: String, value: UniformValue):
        # TODO this looks like a hack
        if value.isa[Vec2f]():
            self.set_uniform(name, value[Vec2f])
        elif value.isa[Vec2i]():
            self.set_uniform(name, value[Vec2i])
        elif value.isa[Vec2u]():
            self.set_uniform(name, value[Vec2u])
        elif value.isa[Vec[1, DType.float32]]():
            self.set_uniform(name, value[Vec[1, DType.float32]])
        elif value.isa[Vec[1, DType.int32]]():
            self.set_uniform(name, value[Vec[1, DType.int32]])
        elif value.isa[Vec[1, DType.int64]]():
            self.set_uniform(name, value[Vec[1, DType.int64]])
        elif value.isa[Vec[1, DType.uint8]]():
            self.set_uniform(name, value[Vec[1, DType.uint8]])
        elif value.isa[Vec[1, DType.uint16]]():
            self.set_uniform(name, value[Vec[1, DType.uint16]])
        elif value.isa[Vec[1, DType.uint32]]():
            self.set_uniform(name, value[Vec[1, DType.uint32]])

    fn set_uniform(mut self, owned name: String, value: UniformValueSIMD16):
        if value.isa[Vec4f]():
            self.set_uniform(name, value[Vec4f])
        elif value.isa[Vec3f]():
            self.set_uniform(name, value[Vec3f])
        elif value.isa[Vec4i]():
            self.set_uniform(name, value[Vec4i])
        elif value.isa[Vec3i]():
            self.set_uniform(name, value[Vec3i])
        elif value.isa[Vec4u]():
            self.set_uniform(name, value[Vec4u])
        elif value.isa[Vec3u]():
            self.set_uniform(name, value[Vec3u])
