import opengl as gl
from opengl import ShaderType
from .utils import *

def read_file(path: String) -> String:
    with open(path, "r") as file:
        return file.read()


def load_shader(path: String, type: ShaderType) -> Id:
    vertex_src = read_file(path)
    shader = gl.create_shader(type)
    var cstr_ptr = vertex_src.unsafe_cstr_ptr().origin_cast[origin=MutableAnyOrigin]()
    gl.shader_source(shader, 1, Ptr(to=cstr_ptr).origin_cast[mut=False](), UnsafePointer[Int32]())
    gl.compile_shader(shader)
    return shader

fn link_shader_program(program: Id, owned vertex_shader: Id, owned fragment_shader: Id):
    gl.attach_shader(program, vertex_shader)
    gl.attach_shader(program, fragment_shader)
    gl.link_program(program)
    gl.delete_shader(vertex_shader)
    gl.delete_shader(fragment_shader)