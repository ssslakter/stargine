import opengl as gl
from opengl import ShaderType
from std.memory import ArcPointer
from std.os import PathLike
from .linalg import Matrix, Vec
from .utils import Id, Ptr, read_file

comptime SHADER_VERSION_HEADER = "#version 330 core\n"


def parse_combined_shader[T: PathLike](path: T) raises -> Tuple[String, String]:
    """Splits a single `.glsl` file into its `#shader vertex` and `#shader fragment` halves."""
    var vertex_lines = List[String]()
    var fragment_lines = List[String]()
    var current = String("")

    for line in read_file(path).splitlines():
        var stripped = String(line.strip())
        if stripped in [String("#shader vertex"), String("#shader fragment")]:
            current = String(stripped.split(" ")[1])
        elif current == "vertex":
            vertex_lines.append(String(line))
        elif current == "fragment":
            fragment_lines.append(String(line))

    return String("\n".join(vertex_lines).strip()), String("\n".join(fragment_lines).strip())


def shader_info_log(shader: Id) raises -> String:
    var capacity = Int32(0)
    gl.get_shaderiv(shader, gl.ShaderParameterName.GL_INFO_LOG_LENGTH, Ptr(to=capacity))
    var buffer = List[UInt8](length=Int(max(capacity, 0)), fill=0)
    var written = Int32(0)
    if capacity > 0:
        gl.get_shader_info_log(shader, capacity, Ptr(to=written), buffer.unsafe_ptr().unsafe_bitcast[Int8]())
    return String(unsafe_from_utf8=Span(buffer)[: Int(written)])


def program_info_log(program: Id) raises -> String:
    var capacity = Int32(0)
    gl.get_programiv(program, gl.ProgramPropertyARB.GL_INFO_LOG_LENGTH, Ptr(to=capacity))
    var buffer = List[UInt8](length=Int(max(capacity, 0)), fill=0)
    var written = Int32(0)
    if capacity > 0:
        gl.get_program_info_log(program, capacity, Ptr(to=written), buffer.unsafe_ptr().unsafe_bitcast[Int8]())
    return String(unsafe_from_utf8=Span(buffer)[: Int(written)])


def compile_shader(var src: List[String], shader_type: ShaderType) raises -> Id:
    var source = String("\n".join(src))
    if not source.startswith("#version"):
        source = SHADER_VERSION_HEADER + source
    var length = Int32(source.byte_length())
    var shader = gl.create_shader(shader_type)
    gl.shader_source(shader, 1, [source^], Ptr(to=length))
    gl.compile_shader(shader)

    var compiled = Int32(0)
    gl.get_shaderiv(shader, gl.ShaderParameterName.GL_COMPILE_STATUS, Ptr(to=compiled))
    if not compiled:
        var log = shader_info_log(shader)
        gl.delete_shader(shader)
        raise Error("shader compilation failed: ", log)
    return shader


def link_program(var vertex_src: List[String], var fragment_src: List[String]) raises -> Id:
    var shaders = List[Id]()
    var program = gl.create_program()
    try:
        shaders.append(compile_shader(vertex_src^, ShaderType.GL_VERTEX_SHADER))
        shaders.append(compile_shader(fragment_src^, ShaderType.GL_FRAGMENT_SHADER))
        for shader in shaders:
            gl.attach_shader(program, shader)
        gl.link_program(program)

        var linked = Int32(0)
        gl.get_programiv(program, gl.ProgramPropertyARB.GL_LINK_STATUS, Ptr(to=linked))
        if not linked:
            raise Error(
                "shader program link failed: ",
                program_info_log(program),
            )
    except err:
        for shader in shaders:
            gl.delete_shader(shader)
        gl.delete_program(program)
        raise err

    for shader in shaders:
        gl.delete_shader(shader)
    return program


struct _ShaderInner(Movable):
    """Owns a GL program name and deletes it exactly once."""

    var id: Id

    def __init__(out self):
        self.id = 0

    def __init__(out self, var vertex_src: List[String], var fragment_src: List[String]) raises:
        self.id = link_program(vertex_src^, fragment_src^)

    def __deinit__(deinit self):
        if self.id:
            try:
                gl.delete_program(self.id)
            except err:
                print("Failed to delete shader program:", err)


struct Shader(Copyable, Movable):
    var inner: ArcPointer[_ShaderInner]
    var vertex_paths: List[String]
    var fragment_paths: List[String]
    var combined_path: Optional[String]

    def __init__(out self):
        self.inner = ArcPointer(_ShaderInner())
        self.vertex_paths = []
        self.fragment_paths = []
        self.combined_path = None

    def __init__(out self, *, var vertex_src: List[String], var fragment_src: List[String]) raises:
        self.inner = ArcPointer(_ShaderInner(vertex_src^, fragment_src^))
        self.vertex_paths = []
        self.fragment_paths = []
        self.combined_path = None

    def __init__[T: PathLike & Writable](out self, combined_path: T) raises:
        var vertex_src, fragment_src = parse_combined_shader(combined_path)
        self = Self(vertex_src=[vertex_src^], fragment_src=[fragment_src^])
        self.combined_path = String(combined_path)

    def __init__[T: PathLike & Writable & Copyable](out self, vertex_path: T, fragment_path: T) raises:
        self = Self([vertex_path.copy()], [fragment_path.copy()])

    def __init__[T: PathLike & Writable & Copyable](out self, vertex_paths: List[T], fragment_paths: List[T]) raises:
        self = Self(
            vertex_src=[read_file(path) for path in vertex_paths],
            fragment_src=[read_file(path) for path in fragment_paths],
        )
        self.vertex_paths = [String(path) for path in vertex_paths]
        self.fragment_paths = [String(path) for path in fragment_paths]

    def reload(mut self) raises:
        if self.combined_path:
            self = Self(self.combined_path.value())
        elif self.vertex_paths and self.fragment_paths:
            self = Self(self.vertex_paths^, self.fragment_paths^)

    def use(self) raises:
        gl.use_program(self.inner[].id)

    def set_uniform(self, var name: String, texture_unit: gl.TextureUnit = gl.TextureUnit.GL_TEXTURE0) raises:
        self.set_uniform(name^, Int32(Int(texture_unit) - Int(gl.TextureUnit.GL_TEXTURE0)))

    def set_uniform[dtype: DType](self, var name: String, value: Scalar[dtype]) raises:
        self.set_uniform(name^, Vec[dtype, 1](value))

    def set_uniform[N: Int, dtype: DType, //](self, var name: String, value: Vec[dtype, N]) raises:
        self.use()
        var location = gl.get_uniform_location(self.inner[].id, name^)

        comptime if dtype == DType.float32:
            var v = rebind[Vec[DType.float32, N]](value)
            comptime if N == 1:
                gl.uniform1f(location, v.x())
            elif N == 2:
                gl.uniform2f(location, v.x(), v.y())
            elif N == 3:
                gl.uniform3f(location, v.x(), v.y(), v.z())
            elif N == 4:
                gl.uniform4f(location, v.x(), v.y(), v.z(), v.w())
        elif dtype == DType.int32:
            var v = rebind[Vec[DType.int32, N]](value)
            comptime if N == 1:
                gl.uniform1i(location, v.x())
            elif N == 2:
                gl.uniform2i(location, v.x(), v.y())
            elif N == 3:
                gl.uniform3i(location, v.x(), v.y(), v.z())
            elif N == 4:
                gl.uniform4i(location, v.x(), v.y(), v.z(), v.w())
        elif dtype == DType.uint32:
            var v = rebind[Vec[DType.uint32, N]](value)
            comptime if N == 1:
                gl.uniform1ui(location, v.x())
            elif N == 2:
                gl.uniform2ui(location, v.x(), v.y())
            elif N == 3:
                gl.uniform3ui(location, v.x(), v.y(), v.z())
            elif N == 4:
                gl.uniform4ui(location, v.x(), v.y(), v.z(), v.w())

    def set_uniform[rows: Int, cols: Int](self, var name: String, value: Matrix[DType.float32, rows, cols]) raises:
        self.use()
        var location = gl.get_uniform_location(self.inner[].id, name^)
        var data = value.data.unsafe_ptr()

        comptime if rows == 4:
            comptime if cols == 4:
                gl.uniform_matrix4fv(location, 1, True, data)
            elif cols == 3:
                gl.uniform_matrix4x3fv(location, 1, True, data)
            elif cols == 2:
                gl.uniform_matrix4x2fv(location, 1, True, data)
        elif rows == 3:
            comptime if cols == 4:
                gl.uniform_matrix3x4fv(location, 1, True, data)
            elif cols == 3:
                gl.uniform_matrix3fv(location, 1, True, data)
            elif cols == 2:
                gl.uniform_matrix3x2fv(location, 1, True, data)
        elif rows == 2:
            comptime if cols == 4:
                gl.uniform_matrix2x4fv(location, 1, True, data)
            elif cols == 3:
                gl.uniform_matrix2x3fv(location, 1, True, data)
            elif cols == 2:
                gl.uniform_matrix2fv(location, 1, True, data)
