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


struct Shader(Copyable, Movable):
    var inner: ArcPointer[_ShaderInner]
    var fragment_paths: List[String]
    var vertex_paths: List[String]

    fn __init__(out self):
        self.inner = ArcPointer[_ShaderInner](_ShaderInner())
        self.fragment_paths = []
        self.vertex_paths = []

    fn __init__[PathLike: os.PathLike & ListElement & Stringable](out self, fragment_path: PathLike, vertex_path: PathLike) raises:
        self = Self([fragment_path], [vertex_path])

    fn __init__[
        PathLike: os.PathLike & ListElement & Stringable
    ](out self, fragment_paths: List[PathLike], vertex_paths: List[PathLike]) raises:
        self.inner = ArcPointer[_ShaderInner](_ShaderInner(fragment_paths, vertex_paths))
        self.fragment_paths = [String(path) for path in fragment_paths]
        self.vertex_paths = [String(path) for path in vertex_paths]

    fn reload(mut self) raises:
        print("reloading shader", self.inner[].id)
        self = Self(self.fragment_paths, self.vertex_paths)

    fn use(self):
        gl.use_program(self.inner[].id)


    fn set_uniform(self, owned name: String, texture: Texture):
        self.set_uniform(name, texture.inner[].id)

    fn set_uniform[dtype: DType](self, owned name: String, value: Scalar[dtype]):
        self.set_uniform(name, Vec[1, dtype](value))

    fn set_uniform[N: Int, dtype: DType, //](self, owned name: String, value: Vec[N, dtype]):
        self.use()
        var location = gl.get_uniform_location(self.inner[].id, name)

        @parameter
        if dtype is DType.float32:
            var v = rebind[Vec[N, DType.float32]](value)
            if N == 1:
                gl.uniform1f(location, v.x())
            elif N == 2:
                gl.uniform2f(location, v.x(), v.y())
            elif N == 3:
                gl.uniform3f(location, v.x(), v.y(), v.z())
            elif N == 4:
                gl.uniform4f(location, v.x(), v.y(), v.z(), v.w())
        elif dtype is DType.int32:
            var v = rebind[Vec[N, DType.int32]](value)
            if N == 1:
                gl.uniform1i(location, v.x())
            elif N == 2:
                gl.uniform2i(location, v.x(), v.y())
            elif N == 3:
                gl.uniform3i(location, v.x(), v.y(), v.z())
            elif N == 4:
                gl.uniform4i(location, v.x(), v.y(), v.z(), v.w())
