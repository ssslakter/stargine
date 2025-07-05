from opengl import ShaderType
from .utils import *
from ..linalg import *


def compile_shader(paths: List[String], shader_type: ShaderType) -> Id:
    src = [read_file(path) for path in paths]
    shader = gl.create_shader(shader_type)
    gl.shader_source(shader, len(src), src, UnsafePointer[Int32]())
    gl.compile_shader(shader)
    return shader


struct Shader(Movable):
    var fragment_paths: List[String]
    var vertex_paths: List[String]
    var id: Id

    fn __init__(out self):
        self.id = 0
        self.fragment_paths = []
        self.vertex_paths = []

    fn __init__(out self, fragment_path: String, vertex_path: String) raises:
        self = Self([fragment_path], [vertex_path])

    fn __init__(out self, fragment_paths: List[String], vertex_paths: List[String]) raises:
        self.id = gl.create_program()
        self.fragment_paths = fragment_paths
        self.vertex_paths = vertex_paths
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

    fn reload(mut self) raises:
        print("reloading shader", self.id)
        self = Self(self.fragment_paths, self.vertex_paths)

    fn bind(self):
        gl.use_program(self.id)

    fn unbind(self):
        gl.use_program(0)

    fn set_uniform(self, owned name: String, value: Texture):
        self.set_uniform(name, value.id)

    fn set_uniform[dtype: DType](self, owned name: String, value: Scalar[dtype]):
        self.set_uniform(name, Vec[1, dtype](value))

    fn set_uniform[N: Int, dtype: DType, //](self, owned name: String, value: Vec[N, dtype]):
        var location = gl.get_uniform_location(self.id, name)

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
