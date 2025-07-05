from python import PythonConvertible
from .imports import *
from .utils import *


def load_image[PathLike: os.PathLike & PythonConvertible & ListElement](path: PathLike) -> NDBuffer[DType.uint8, 3, MutableAnyOrigin]:
    np = Python.import_module("numpy")
    pil = Python.import_module("PIL.Image")
    img = pil.open(path.to_python_object())
    img = img.transpose(pil.FLIP_TOP_BOTTOM)
    arr = np.array(img)
    if arr.ndim == 2:
        arr = np.expand_dims(arr, axis=-1)
    res = from_numpy[DType.uint8, 3](arr)
    return res


struct _TextureInner(Movable):
    var id: Id

    fn __init__(out self):
        self.id = 0

    fn __init__[PathLike: os.PathLike & PythonConvertible & ListElement](out self, path: PathLike) raises:
        self = Self()
        gl.gen_textures(1, Ptr(to=self.id))
        gl.bind_texture(gl.TextureTarget.TEXTURE_2D, self.id)
        try:
            var image = load_image(path)
            var shape = image.get_shape()
            width, height, channels = shape[0], shape[1], shape[2]
            alias channels_to_format = {
                3: gl.PixelFormat.RGB,
                4: gl.PixelFormat.RGBA,
                1: gl.PixelFormat.LUMINANCE
            }
            alias channels_to_internal_format = {
                3: gl.InternalFormat.RGB,
                4: gl.InternalFormat.RGBA8,
                1: gl.InternalFormat.R8 
            }
            pixel_format = channels_to_format[channels]
            internal_format = channels_to_internal_format[channels]
            gl.tex_image_2d(
                gl.TextureTarget.TEXTURE_2D,
                0,
                internal_format,
                width,
                height,
                0,
                pixel_format,
                gl.PixelType.UNSIGNED_BYTE,
                image.data.bitcast[NoneType](),
            )
            gl.generate_mipmap(gl.TextureTarget.TEXTURE_2D)
        except e:
            print("Failed to load texture:", e, ". Fallback to a black texture")
            var black_pixel = InlineArray[UInt8, 3](0)
            gl.tex_image_2d(
                gl.TextureTarget.TEXTURE_2D,
                0,
                gl.InternalFormat.RGB,
                1,
                1,
                0,
                gl.PixelFormat.RGB,
                gl.PixelType.UNSIGNED_BYTE,
                black_pixel.unsafe_ptr().bitcast[NoneType](),
            )

    fn __del__(owned self):
        gl.delete_textures(1, Ptr(to=self.id))


struct Texture(Copyable, Movable):
    var inner: ArcPointer[_TextureInner]

    fn __init__(out self):
        self.inner = ArcPointer[_TextureInner](_TextureInner())

    fn __init__[PathLike: os.PathLike & PythonConvertible & ListElement](out self, path: PathLike) raises:
        self.inner = ArcPointer[_TextureInner](_TextureInner(path))
        self.set_parameter(gl.TextureParameterName.TEXTURE_WRAP_S, Int(gl.TextureWrapMode.CLAMP_TO_EDGE))
        self.set_parameter(gl.TextureParameterName.TEXTURE_WRAP_T, Int(gl.TextureWrapMode.CLAMP_TO_EDGE))
        self.set_parameter(gl.TextureParameterName.TEXTURE_MIN_FILTER, Int(gl.TextureMinFilter.NEAREST))
        self.set_parameter(gl.TextureParameterName.TEXTURE_MAG_FILTER, Int(gl.TextureMagFilter.NEAREST))

    fn bind(self, texture_unit: gl.TextureUnit = gl.TextureUnit.TEXTURE0):
        gl.active_texture(texture_unit)
        gl.bind_texture(gl.TextureTarget.TEXTURE_2D, self.inner[].id)

    fn set_parameter(self, name: gl.TextureParameterName, value: Int):
        gl.tex_parameteri(gl.TextureTarget.TEXTURE_2D, name, value)

    fn unbind(self):
        gl.bind_texture(gl.TextureTarget.TEXTURE_2D, 0)
