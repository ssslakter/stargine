from utils import Variant
from opengl import ShaderType
from .utils import *
from .linalg import *


def parse_combined_shader[PathLike: os.PathLike & ListElement](path: PathLike) -> Tuple[String, String]:
    lines = read_file(path).splitlines()
    vertex_lines, fragment_lines = List[String](), List[String]()
    current: String = ""

    for line in lines:
        line_stripped = String(line.strip())
        if line_stripped in [String("#shader vertex"), String("#shader fragment")]:
            current = line_stripped.split(" ")[1]
            continue

        if current == "vertex":
            vertex_lines.append(line)
        elif current == "fragment":
            fragment_lines.append(line)

    vertex_code = String("\n".join(vertex_lines).strip())
    fragment_code = String("\n".join(fragment_lines).strip())
    return vertex_code, fragment_code


def compile_shader(owned src: List[String], shader_type: ShaderType) -> Id:
    shader = gl.create_shader(shader_type)
    gl.shader_source(shader, len(src), src, UnsafePointer[Int32]())
    gl.compile_shader(shader)
    check_errors(
        gl.get_shaderiv,
        gl.get_shader_info_log,
        shader,
        gl.ShaderParameterName.COMPILE_STATUS,
        gl.ShaderParameterName.INFO_LOG_LENGTH,
    )
    return shader


alias GL_GET_IV_FN[pnameT: Intable] = fn (obj_id: UInt32, pname: pnameT, params: Ptr[Int32, mut=True])
alias GL_LOG_FN = fn (obj_id: UInt32, buf_size: gl.GLsizei, length: Ptr[gl.GLsizei, mut=True], var info_log: String)


fn check_errors[
    pnameT: Intable
](get_iv: GL_GET_IV_FN[pnameT], log_fn: GL_LOG_FN, obj_id: UInt32, pname: pnameT, log_pname: pnameT):
    var success = Int32(0)
    get_iv(obj_id, pname, Ptr(to=success))
    if success:
        return
    var log_length = Int32(0)
    get_iv(obj_id, log_pname, Ptr(to=log_length))
    if not log_length:
        return
    log = String(unsafe_uninit_length=UInt(log_length))
    log_fn(obj_id, log.capacity(), Ptr(to=log_length), log)
    print("error: ", log)


struct _ShaderInner(Movable):
    var id: Id

    fn __init__(out self):
        self.id = 0

    fn __init__(out self, owned vertex_src: List[String], owned fragment_src: List[String]) raises:
        self.id = gl.create_program()
        vertex_shader = compile_shader(vertex_src, ShaderType.VERTEX_SHADER)
        fragment_shader = compile_shader(fragment_src, ShaderType.FRAGMENT_SHADER)
        gl.attach_shader(self.id, vertex_shader)
        gl.attach_shader(self.id, fragment_shader)
        gl.link_program(self.id)
        gl.delete_shader(vertex_shader)
        gl.delete_shader(fragment_shader)
        check_errors(
            gl.get_programiv,
            gl.get_program_info_log,
            self.id,
            gl.ProgramPropertyARB.LINK_STATUS,
            gl.ProgramPropertyARB.INFO_LOG_LENGTH,
        )

    fn __del__(owned self):
        gl.delete_program(self.id)


struct Shader(Copyable, Movable):
    var inner: ArcPointer[_ShaderInner]
    var fragment_paths: List[String]
    var vertex_paths: List[String]
    var combined_path: Optional[String]

    fn __init__(out self):
        self.inner = ArcPointer[_ShaderInner](_ShaderInner())
        self.fragment_paths = []
        self.vertex_paths = []
        self.combined_path = None

    fn __init__[PathLike: os.PathLike & ListElement & Stringable](out self, combined_path: PathLike) raises:
        vertex_src, fragment_src = parse_combined_shader(combined_path)
        self = Self(vertex_src=[vertex_src], fragment_src=[fragment_src])
        self.combined_path = String(combined_path)

    fn __init__[
        PathLike: os.PathLike & ListElement & Stringable
    ](out self, vertex_path: PathLike, fragment_path: PathLike) raises:
        self = Self([vertex_path], [fragment_path])

    fn __init__[
        PathLike: os.PathLike & ListElement & Stringable
    ](out self, vertex_paths: List[PathLike], fragment_paths: List[PathLike]) raises:
        vertex_src = [read_file(path) for path in vertex_paths]
        fragment_src = [read_file(path) for path in fragment_paths]
        self = Self(vertex_src=vertex_src, fragment_src=fragment_src)
        self.vertex_paths = [String(path) for path in vertex_paths]
        self.fragment_paths = [String(path) for path in fragment_paths]

    fn __init__(out self, *, owned vertex_src: List[String], owned fragment_src: List[String]) raises:
        self.inner = ArcPointer[_ShaderInner](_ShaderInner(vertex_src, fragment_src))
        self.fragment_paths = []
        self.vertex_paths = []
        self.combined_path = None

    fn reload(mut self) raises:
        if not (self.vertex_paths and self.fragment_paths or self.combined_path):
            return
        print("reloading shader", self.inner[].id)
        if self.combined_path:
            self = Self(self.combined_path.value())
        else:
            self = Self(self.vertex_paths, self.fragment_paths)

    fn use(self):
        gl.use_program(self.inner[].id)

    fn set_uniform(self, owned name: String, texture_unit: gl.TextureUnit = gl.TextureUnit.TEXTURE0):
        self.set_uniform(name, Int32(Int(texture_unit) - Int(gl.TextureUnit.TEXTURE0)))

    fn set_uniform[dtype: DType](self, owned name: String, value: Scalar[dtype]):
        self.set_uniform(name, Vec[dtype, 1](value))

    fn set_uniform[N: Int, dtype: DType, //](self, owned name: String, value: Vec[dtype, N]):
        self.use()
        var location = gl.get_uniform_location(self.inner[].id, name)

        @parameter
        if dtype == DType.float32:
            var v = rebind[Vec[DType.float32, N]](value)

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
            var v = rebind[Vec[DType.int32, N]](value)

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
            var v = rebind[Vec[DType.uint32, N]](value)

            @parameter
            if N == 1:
                gl.uniform1ui(location, v.x())
            elif N == 2:
                gl.uniform2ui(location, v.x(), v.y())
            elif N == 3:
                gl.uniform3ui(location, v.x(), v.y(), v.z())
            elif N == 4:
                gl.uniform4ui(location, v.x(), v.y(), v.z(), v.w())

    fn set_uniform[cols: Int, rows: Int](self, owned name: String, value: Matrix[DType.float32, rows, cols]):
        self.use()
        var location = gl.get_uniform_location(self.inner[].id, name)

        @parameter
        if rows == 4:

            @parameter
            if cols == 4:
                gl.uniform_matrix4fv(location, 1, True, value.data.unsafe_ptr())
            elif cols == 3:
                gl.uniform_matrix4x3fv(location, 1, True, value.data.unsafe_ptr())
            elif cols == 2:
                gl.uniform_matrix4x2fv(location, 1, True, value.data.unsafe_ptr())
        elif rows == 3:

            @parameter
            if cols == 4:
                gl.uniform_matrix3x4fv(location, 1, True, value.data.unsafe_ptr())
            elif cols == 3:
                gl.uniform_matrix3fv(location, 1, True, value.data.unsafe_ptr())
            elif cols == 2:
                gl.uniform_matrix3x2fv(location, 1, True, value.data.unsafe_ptr())
        elif rows == 2:

            @parameter
            if cols == 4:
                gl.uniform_matrix2x4fv(location, 1, True, value.data.unsafe_ptr())
            elif cols == 3:
                gl.uniform_matrix2x3fv(location, 1, True, value.data.unsafe_ptr())
            elif cols == 2:
                gl.uniform_matrix2fv(location, 1, True, value.data.unsafe_ptr())
