from python import ConvertibleToPython
from .imports import *
from .utils import *

def load_image[PathLike: os.PathLike & ConvertibleToPython & ListElement](path: PathLike) -> NDArray[DType.uint8, 3]:
    np = Python.import_module("numpy")
    pil = Python.import_module("PIL.Image")
    img = pil.open(path.copy().to_python_object())
    # TODO Maybe this can be optimized for non-RGBA images
    img = img.convert("RGBA")
    arr = np.array(img)
    arr = np.flipud(arr)
    return NDArray[DType.uint8, 3](arr)


struct _TextureInner(Movable):
    var id: Id

    fn __init__(out self):
        self.id = 0

    fn __init__[PathLike: os.PathLike & ConvertibleToPython & ListElement](out self, path: PathLike):
        self = Self()
        gl.gen_textures(1, Ptr(to=self.id))
        gl.bind_texture(gl.TextureTarget.TEXTURE_2D, self.id)
        try:
            var image = load_image(path)
            var shape = image.get_shape()
            height, width, channels = shape[0], shape[1], shape[2]
            alias channels_to_format = {
                3: gl.PixelFormat.RGB,
                4: gl.PixelFormat.RGBA,
                1: gl.PixelFormat.LUMINANCE
            }
            alias channels_to_internal_format = {
                3: gl.InternalFormat.RGB,
                4: gl.InternalFormat.RGBA,
                1: gl.InternalFormat.R8 
            }
            pixel_format = materialize[channels_to_format]()[channels]
            internal_format = materialize[channels_to_internal_format]()[channels]

            gl.pixel_storei(gl.PixelStoreParameter.UNPACK_ALIGNMENT, 1)
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
            gl.pixel_storei(gl.PixelStoreParameter.UNPACK_ALIGNMENT, 4)
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

    fn __del__(deinit self):
        print('deleting texture')
        gl.delete_textures(1, Ptr(to=self.id))


struct Texture(Copyable, Movable):
    var inner: ArcPointer[_TextureInner]
    var filename: String

    fn __init__(out self):
        self.inner = ArcPointer[_TextureInner](_TextureInner())
        self.filename = ""
    fn __init__[PathLike: os.PathLike & ConvertibleToPython & ListElement & Stringable](out self, path: PathLike) raises:
        self.inner = ArcPointer[_TextureInner](_TextureInner(path))
        self.filename = String(path)
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
