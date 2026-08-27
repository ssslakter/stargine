import opengl as gl
from std.memory import unsafe_memcpy
from std.python import Python, PythonObject
from .linalg import Vec4f


def clear(color: Vec4f = Vec4f(0)) raises:
    gl.clear_color(color.x(), color.y(), color.z(), color.w())
    gl.clear(gl.ClearBufferMask.GL_COLOR_BUFFER_BIT | gl.ClearBufferMask.GL_DEPTH_BUFFER_BIT)


def init_blend() raises:
    gl.enable(gl.EnableCap.GL_BLEND)
    gl.blend_func(gl.BlendingFactor.GL_SRC_ALPHA, gl.BlendingFactor.GL_ONE_MINUS_SRC_ALPHA)


def enable_depth_test() raises:
    gl.enable(gl.EnableCap.GL_DEPTH_TEST)
    gl.front_face(gl.FrontFaceDirection.GL_CCW)
    gl.enable(gl.EnableCap.GL_CULL_FACE)
    gl.cull_face(gl.TriangleFace.GL_BACK)


def read_pixels(width: Int32, height: Int32) raises -> List[UInt8]:
    """Reads the back buffer as tightly packed RGB rows, bottom row first."""
    var pixels = List[UInt8](length=Int(width) * Int(height) * 3, fill=0)
    gl.pixel_storei(gl.PixelStoreParameter.GL_PACK_ALIGNMENT, 1)
    gl.read_pixels(
        0,
        0,
        width,
        height,
        gl.PixelFormat.GL_RGB,
        gl.PixelType.GL_UNSIGNED_BYTE,
        pixels.unsafe_ptr().unsafe_bitcast[NoneType](),
    )
    return pixels^


def save_screenshot(path: String, width: Int32, height: Int32) raises:
    """Writes the current back buffer to an image file. Call before swapping."""
    var pixels = read_pixels(width, height)
    var np = Python.import_module("numpy")
    var pil = Python.import_module("PIL.Image")

    var buffer = np.empty(len(pixels), dtype="uint8")
    unsafe_memcpy(
        dest=buffer.ctypes.data.unsafe_get_as_pointer[DType.uint8](),
        src=pixels.unsafe_ptr(),
        count=len(pixels),
    )
    # OpenGL hands back the bottom row first.
    var image = np.flipud(buffer.reshape(Int(height), Int(width), 3))
    _ = pil.fromarray(image).save(PythonObject(path.copy()))
