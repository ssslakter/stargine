from utils import Variant
from opengl import ShaderType
from .utils import *
from .linalg import *


def parse_combined_shader[PathLike: os.PathLike & ListElement](path: PathLike) raises -> Tuple[String, String]:
    lines = read_file(path).splitlines()
    vertex_lines = List[String]()
    fragment_lines =  List[String]()
    current: String = ""

    for line in lines:
        line_stripped = String(line.strip())
        if line_stripped in [String("#shader vertex"), String("#shader fragment")]:
            current = String(line_stripped.split(" ")[1])
            continue

        if current == "vertex":
            vertex_lines.append(String(line))
        elif current == "fragment":
            fragment_lines.append(String(line))

    vertex_code = String("\n".join(vertex_lines).strip())
    fragment_code = String("\n".join(fragment_lines).strip())
    return vertex_code, fragment_code


def compile_shader(var src: List[String], shader_type: ShaderType) raises -> Id:
    shader = gl.create_shader(shader_type)
    print("Created shader:", shader)
    # TODO find better solution to merge opengl shaders
    var res = [String()]
    for s in src:
        res[0] += s
        res[0] += '\n'
    if not res[0].startswith("#version"):
        res[0] = "#version 330 core\n" + res[0]
    print("Compiling shader source:\n", res[0])
    # Mojo String storage is not guaranteed to have a trailing C null byte.
    var source_length = Int32(res[0].byte_length())
    gl.shader_source(shader, 1, res^, UnsafePointer[Int32, ImmutAnyOrigin](unsafe_from_address=Int(Ptr(to=source_length))))
    print("glShaderSource error:", Int(gl.get_error()))
    gl.compile_shader(shader)
    print("glCompileShader error:", Int(gl.get_error()))
    check_shader_errors(shader)
    return shader


def check_shader_errors(shader: Id) raises:
    var success = Int32(0)
    gl.get_shaderiv(shader, gl.ShaderParameterName.GL_COMPILE_STATUS, UnsafePointer[Int32, MutAnyOrigin](unsafe_from_address=Int(Ptr(to=success))))
    if success:
        return
    var log_length = Int32(0)
    gl.get_shaderiv(shader, gl.ShaderParameterName.GL_INFO_LOG_LENGTH, UnsafePointer[Int32, MutAnyOrigin](unsafe_from_address=Int(Ptr(to=log_length))))
    var log = String(unsafe_uninit_length=Int(log_length))
    gl.get_shader_info_log(shader, log_length, UnsafePointer[Int32, MutAnyOrigin](unsafe_from_address=Int(Ptr(to=log_length))), log)
    raise Error("shader compilation failed: " + log)


def check_program_errors(program: Id) raises:
    var success = Int32(0)
    gl.get_programiv(program, gl.ProgramPropertyARB.GL_LINK_STATUS, UnsafePointer[Int32, MutAnyOrigin](unsafe_from_address=Int(Ptr(to=success))))
    if success:
        return
    var log_length = Int32(0)
    gl.get_programiv(program, gl.ProgramPropertyARB.GL_INFO_LOG_LENGTH, UnsafePointer[Int32, MutAnyOrigin](unsafe_from_address=Int(Ptr(to=log_length))))
    var log = String(unsafe_uninit_length=Int(log_length))
    gl.get_program_info_log(program, log_length, UnsafePointer[Int32, MutAnyOrigin](unsafe_from_address=Int(Ptr(to=log_length))), log)
    raise Error("shader program link failed: " + log)


struct _ShaderInner(Movable):
    var id: Id

    def __init__(out self):
        self.id = 0

    def __init__(out self, var vertex_src: List[String], var fragment_src: List[String]) raises:
        self.id = gl.create_program()
        vertex_shader = compile_shader(vertex_src^, ShaderType.GL_VERTEX_SHADER)
        fragment_shader = compile_shader(fragment_src^, ShaderType.GL_FRAGMENT_SHADER)
        gl.attach_shader(self.id, vertex_shader)
        gl.attach_shader(self.id, fragment_shader)
        gl.link_program(self.id)
        gl.delete_shader(vertex_shader)
        gl.delete_shader(fragment_shader)
        check_program_errors(self.id)

    def __del__(deinit self):
        if self.id:
            try:
                gl.delete_program(self.id)
            except err:
                print("Failed to delete shader program:", err)


struct Shader(Copyable, Movable):
    var inner: ArcPointer[_ShaderInner]
    var fragment_paths: List[String]
    var vertex_paths: List[String]
    var combined_path: Optional[String]

    def __init__(out self):
        self.inner = ArcPointer[_ShaderInner](_ShaderInner())
        self.fragment_paths = []
        self.vertex_paths = []
        self.combined_path = None

    def __init__[PathLike: os.PathLike & ListElement & Writable](out self, combined_path: PathLike) raises:
        vertex_src, fragment_src = parse_combined_shader(combined_path)
        self = Self(vertex_src=[vertex_src], fragment_src=[fragment_src])
        self.combined_path = String(combined_path)

    def __init__[
        PathLike: os.PathLike & ListElement & Writable
    ](out self, vertex_path: PathLike, fragment_path: PathLike) raises:
        self = Self([vertex_path.copy()], [fragment_path.copy()])

    def __init__[
        PathLike: os.PathLike & ListElement & Writable
    ](out self, vertex_paths: List[PathLike], fragment_paths: List[PathLike]) raises:
        vertex_src = [read_file(path) for path in vertex_paths]
        fragment_src = [read_file(path) for path in fragment_paths]
        self = Self(vertex_src=vertex_src^, fragment_src=fragment_src^)
        self.vertex_paths = [String(path) for path in vertex_paths]
        self.fragment_paths = [String(path) for path in fragment_paths]

    def __init__(out self, *, var vertex_src: List[String], var fragment_src: List[String]) raises:
        self.inner = ArcPointer[_ShaderInner](_ShaderInner(vertex_src^, fragment_src^))
        self.fragment_paths = []
        self.vertex_paths = []
        self.combined_path = None

    def reload(mut self) raises:
        if not (self.vertex_paths and self.fragment_paths or self.combined_path):
            return
        print("reloading shader", self.inner[].id)
        if self.combined_path:
            self = Self(self.combined_path.value())
        else:
            self = Self(self.vertex_paths^, self.fragment_paths^)

    def use(self) raises:
        gl.use_program(self.inner[].id)

    def set_uniform(self, var name: String, texture_unit: gl.TextureUnit = gl.TextureUnit.GL_TEXTURE0) raises:
        self.set_uniform(name, Int32(Int(texture_unit) - Int(gl.TextureUnit.GL_TEXTURE0)))

    def set_uniform[dtype: DType](self, var name: String, value: Scalar[dtype]) raises:
        self.set_uniform(name, Vec[dtype, 1](value))

    def set_uniform[N: Int, dtype: DType, //](self, var name: String, value: Vec[dtype, N]) raises:
        self.use()
        var location = gl.get_uniform_location(self.inner[].id, name)

        comptime
        if dtype == DType.float32:
            var v = rebind[Vec[DType.float32, N]](value)

            comptime
            if N == 1:
                gl.uniform1f(location, v.x())
            elif N == 2:
                gl.uniform2f(location, v.x(), v.y())
            elif N == 3:
                gl.uniform3f(location, v.x(), v.y(), v.z())
            elif N == 4:
                gl.uniform4f(location, v.x(), v.y(), v.z(), v.w())
        elif dtype == DType.int32:
            var v = rebind[Vec[DType.int32, N]](value)

            comptime
            if N == 1:
                gl.uniform1i(location, v.x())
            elif N == 2:
                gl.uniform2i(location, v.x(), v.y())
            elif N == 3:
                gl.uniform3i(location, v.x(), v.y(), v.z())
            elif N == 4:
                gl.uniform4i(location, v.x(), v.y(), v.z(), v.w())
        elif dtype == DType.uint32:
            var v = rebind[Vec[DType.uint32, N]](value)

            comptime
            if N == 1:
                gl.uniform1ui(location, v.x())
            elif N == 2:
                gl.uniform2ui(location, v.x(), v.y())
            elif N == 3:
                gl.uniform3ui(location, v.x(), v.y(), v.z())
            elif N == 4:
                gl.uniform4ui(location, v.x(), v.y(), v.z(), v.w())

    def set_uniform[cols: Int, rows: Int](self, var name: String, value: Matrix[DType.float32, rows, cols]) raises:
        self.use()
        var location = gl.get_uniform_location(self.inner[].id, name)
        var data = UnsafePointer[Float32, ImmutAnyOrigin](unsafe_from_address=Int(value.data.unsafe_ptr()))

        comptime
        if rows == 4:

            comptime
            if cols == 4:
                gl.uniform_matrix4fv(location, 1, True, data)
            elif cols == 3:
                gl.uniform_matrix4x3fv(location, 1, True, data)
            elif cols == 2:
                gl.uniform_matrix4x2fv(location, 1, True, data)
        elif rows == 3:

            comptime
            if cols == 4:
                gl.uniform_matrix3x4fv(location, 1, True, data)
            elif cols == 3:
                gl.uniform_matrix3fv(location, 1, True, data)
            elif cols == 2:
                gl.uniform_matrix3x2fv(location, 1, True, data)
        elif rows == 2:

            comptime
            if cols == 4:
                gl.uniform_matrix2x4fv(location, 1, True, data)
            elif cols == 3:
                gl.uniform_matrix2x3fv(location, 1, True, data)
            elif cols == 2:
                gl.uniform_matrix2fv(location, 1, True, data)
