import opengl as gl
from opengl import ShaderType
from .utils import *
from .linalg import *

@register_passable("trivial")
struct Shader(Copyable, Movable):
    var id: Id

    fn __init__(out self):
        self.id = 0

    fn __init__(out self, vertex_path: String, fragment_path: String) raises:
        vertex_shader = load_shader(vertex_path, ShaderType.VERTEX_SHADER)
        fragment_shader = load_shader(fragment_path, ShaderType.FRAGMENT_SHADER)
        self.id = gl.create_program()
        link_shader_program(self.id, vertex_shader, fragment_shader)
        gl.delete_shader(vertex_shader)
        gl.delete_shader(fragment_shader)

    fn use(self): gl.use_program(self.id)

    fn set_uniform[dtype: DType](self, owned name: String, value: Scalar[dtype]) raises:
        var location = gl.get_uniform_location(self.id, name)
        @parameter
        if dtype is DType.float32:
            gl.uniform1f(location, rebind[Float32](value))
        elif dtype is DType.int32:
            gl.uniform1i(location, rebind[Int32](value))

    fn set_uniform[dtype: DType](self, owned name: String, value: Vec2[dtype]) raises:        
        var location = gl.get_uniform_location(self.id, name)
        @parameter
        if dtype is DType.float32:
            var v = rebind[Vec2f](value)
            gl.uniform2f(location, v.x(), v.y())

    fn set_uniform[dtype: DType](self, owned name: String, value: Vec3[dtype]) raises:
        var location = gl.get_uniform_location(self.id, name)
        @parameter
        if dtype is DType.float32:
            var v = rebind[Vec3f](value)
            gl.uniform3f(location, v.x(), v.y(), v.z())
        elif dtype is DType.int32:
            var v = rebind[Vec3i](value)
            gl.uniform3i(location, v.x(), v.y(), v.z())

    fn set_uniform[dtype: DType](self, owned name: String, value: Vec4[dtype]) raises:
        var location = gl.get_uniform_location(self.id, name)
        @parameter
        if dtype is DType.float32:
            var v = rebind[Vec4f](value)
            gl.uniform4f(location, v.x(), v.y(), v.z(), v.w())


        

def read_file(path: String) -> String:
    with open(path, "r") as file:
        return file.read()


def load_shader(path: String, type: ShaderType) -> Id:
    vertex_src = [read_file(path)]
    shader = gl.create_shader(type)
    gl.shader_source(shader, 1, vertex_src, UnsafePointer[Int32]())
    gl.compile_shader(shader)
    return shader

fn link_shader_program(program: Id, owned vertex_shader: Id, owned fragment_shader: Id):
    gl.attach_shader(program, vertex_shader)
    gl.attach_shader(program, fragment_shader)
    gl.link_program(program)
    gl.delete_shader(vertex_shader)
    gl.delete_shader(fragment_shader)