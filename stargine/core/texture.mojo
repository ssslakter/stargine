from std.python import PythonObject
from .imports import *
from .utils import *

def load_image(path: String) raises -> NDArray[DType.uint8, 3]:
    np = Python.import_module("numpy")
    pil = Python.import_module("PIL.Image")
    # Python conversion consumes its Mojo String; Texture keeps its own filename.
    var python_path = path.copy()
    img = pil.open(PythonObject(python_path))
    # TODO Maybe this can be optimized for non-RGBA images
    img = img.convert("RGBA")
    arr = np.array(img)
    arr = np.flipud(arr)
    return NDArray[DType.uint8, 3](arr)


struct _TextureInner(Movable):
    var id: Id

    def __init__(out self):
        self.id = 0

    def __init__(out self, path: String) raises:
        self = Self()
        gl.gen_textures(1, UnsafePointer[UInt32, MutAnyOrigin](unsafe_from_address=Int(Ptr(to=self.id))))
        gl.bind_texture(gl.TextureTarget.GL_TEXTURE_2D, self.id)
        try:
            var image = load_image(path)
            var shape = image.get_shape()
            height, width, channels = shape[0], shape[1], shape[2]
            comptime channels_to_format = {
                3: gl.PixelFormat.GL_RGB,
                4: gl.PixelFormat.GL_RGBA,
                1: gl.PixelFormat.GL_LUMINANCE
            }
            comptime channels_to_internal_format = {
                3: gl.InternalFormat.GL_RGB,
                4: gl.InternalFormat.GL_RGBA,
                1: gl.InternalFormat.GL_R8
            }
            pixel_format = materialize[channels_to_format]()[channels]
            internal_format = materialize[channels_to_internal_format]()[channels]

            gl.pixel_storei(gl.PixelStoreParameter.GL_UNPACK_ALIGNMENT, 1)
            gl.tex_image_2d(
                gl.TextureTarget.GL_TEXTURE_2D,
                0,
                internal_format,
                Int32(width),
                Int32(height),
                0,
                pixel_format,
                gl.PixelType.GL_UNSIGNED_BYTE,
                UnsafePointer[NoneType, ImmutAnyOrigin](unsafe_from_address=Int(image.data)),
            )
            gl.pixel_storei(gl.PixelStoreParameter.GL_UNPACK_ALIGNMENT, 4)
            gl.generate_mipmap(gl.TextureTarget.GL_TEXTURE_2D)
        except e:
            print("Failed to load texture:", e, ". Fallback to a black texture")
            var black_pixel: Array[UInt8, 3] = [0, 0, 0]
            gl.tex_image_2d(
                gl.TextureTarget.GL_TEXTURE_2D,
                0,
                gl.InternalFormat.GL_RGB,
                1,
                1,
                0,
                gl.PixelFormat.GL_RGB,
                gl.PixelType.GL_UNSIGNED_BYTE,
                UnsafePointer[NoneType, ImmutAnyOrigin](unsafe_from_address=Int(black_pixel.unsafe_ptr())),
            )

    def __del__(deinit self):
        if self.id:
            try:
                gl.delete_textures(1, Ptr(to=self.id))
            except err:
                print("Failed to delete texture:", err)


struct Texture(Copyable, Movable):
    var inner: ArcPointer[_TextureInner]
    var filename: String

    def __init__(out self):
        self.inner = ArcPointer[_TextureInner](_TextureInner())
        self.filename = ""

    def __init__(out self, path: String) raises:
        self.inner = ArcPointer[_TextureInner](_TextureInner(path))
        self.filename = path.copy()
        self.set_parameter(gl.TextureParameterName.GL_TEXTURE_WRAP_S, Int(gl.TextureWrapMode.GL_CLAMP_TO_EDGE))
        self.set_parameter(gl.TextureParameterName.GL_TEXTURE_WRAP_T, Int(gl.TextureWrapMode.GL_CLAMP_TO_EDGE))
        self.set_parameter(gl.TextureParameterName.GL_TEXTURE_MIN_FILTER, Int(gl.TextureMinFilter.GL_NEAREST))
        self.set_parameter(gl.TextureParameterName.GL_TEXTURE_MAG_FILTER, Int(gl.TextureMagFilter.GL_NEAREST))
    def bind(self, texture_unit: gl.TextureUnit = gl.TextureUnit.GL_TEXTURE0) raises:
        gl.active_texture(texture_unit)
        gl.bind_texture(gl.TextureTarget.GL_TEXTURE_2D, self.inner[].id)

    def set_parameter(self, name: gl.TextureParameterName, value: Int) raises:
        gl.tex_parameteri(gl.TextureTarget.GL_TEXTURE_2D, name, Int32(value))

    def unbind(self) raises:
        gl.bind_texture(gl.TextureTarget.GL_TEXTURE_2D, 0)
