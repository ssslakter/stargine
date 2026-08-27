import opengl as gl
from std.memory import ArcPointer
from std.python import Python, PythonObject
from .utils import Id, NDArray, Ptr

comptime channels_to_format = {
    1: gl.PixelFormat.GL_LUMINANCE,
    3: gl.PixelFormat.GL_RGB,
    4: gl.PixelFormat.GL_RGBA,
}

comptime channels_to_internal_format = {
    1: gl.InternalFormat.GL_R8,
    3: gl.InternalFormat.GL_RGB,
    4: gl.InternalFormat.GL_RGBA,
}


def load_image(var path: String) raises -> NDArray[DType.uint8, 3]:
    var np = Python.import_module("numpy")
    var pil = Python.import_module("PIL.Image")
    var img = pil.open(PythonObject(path^)).convert("RGBA")
    return NDArray[DType.uint8, 3](np.flipud(np.array(img)))


struct _TextureInner(Movable):
    """Owns a GL texture name and deletes it exactly once."""

    var id: Id

    def __init__(out self):
        self.id = 0

    def __init__(out self, path: String, srgb: Bool) raises:
        self = Self()
        gl.gen_textures(1, Ptr(to=self.id))
        gl.bind_texture(gl.TextureTarget.GL_TEXTURE_2D, self.id)
        try:
            var image = load_image(path.copy())
            var height, width, channels = image.shape[0], image.shape[1], image.shape[2]
            var internal_format = (
                gl.InternalFormat.GL_SRGB8_ALPHA8
                if srgb
                else materialize[channels_to_internal_format]()[channels]
            )
            gl.pixel_storei(gl.PixelStoreParameter.GL_UNPACK_ALIGNMENT, 1)
            gl.tex_image_2d(
                gl.TextureTarget.GL_TEXTURE_2D,
                0,
                internal_format,
                Int32(width),
                Int32(height),
                0,
                materialize[channels_to_format]()[channels],
                gl.PixelType.GL_UNSIGNED_BYTE,
                image.data.unsafe_ptr().unsafe_bitcast[NoneType](),
            )
            gl.pixel_storei(gl.PixelStoreParameter.GL_UNPACK_ALIGNMENT, 4)
            gl.generate_mipmap(gl.TextureTarget.GL_TEXTURE_2D)
        except e:
            print("Failed to load texture:", e, ". Falling back to a black texture")
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
                Ptr(to=black_pixel).unsafe_bitcast[NoneType](),
            )

    def __deinit__(deinit self):
        if self.id:
            try:
                gl.delete_textures(1, Ptr(to=self.id))
            except err:
                print("Failed to delete texture:", err)


struct Texture(Copyable, Movable):
    var inner: ArcPointer[_TextureInner]
    var filename: String

    def __init__(out self):
        self.inner = ArcPointer(_TextureInner())
        self.filename = ""

    def __init__(
        out self, var path: String, smooth: Bool = True, repeat: Bool = False, srgb: Bool = True
    ) raises:
        """`smooth` filters trilinearly off the generated mip chain; turn it off for
        pixel art. `repeat` tiles the image instead of clamping at the edges.
        `srgb` decodes the image to linear on read: leave it on for anything that
        is a colour, turn it off for data maps (specular, roughness, normals)."""
        self.inner = ArcPointer(_TextureInner(path, srgb))
        self.filename = path^

        var wrap = gl.TextureWrapMode.GL_REPEAT if repeat else gl.TextureWrapMode.GL_CLAMP_TO_EDGE
        self.set_parameter(gl.TextureParameterName.GL_TEXTURE_WRAP_S, Int(wrap))
        self.set_parameter(gl.TextureParameterName.GL_TEXTURE_WRAP_T, Int(wrap))

        var minify = (
            gl.TextureMinFilter.GL_LINEAR_MIPMAP_LINEAR if smooth else gl.TextureMinFilter.GL_NEAREST
        )
        var magnify = gl.TextureMagFilter.GL_LINEAR if smooth else gl.TextureMagFilter.GL_NEAREST
        self.set_parameter(gl.TextureParameterName.GL_TEXTURE_MIN_FILTER, Int(minify))
        self.set_parameter(gl.TextureParameterName.GL_TEXTURE_MAG_FILTER, Int(magnify))

    def bind(self, texture_unit: gl.TextureUnit = gl.TextureUnit.GL_TEXTURE0) raises:
        gl.active_texture(texture_unit)
        gl.bind_texture(gl.TextureTarget.GL_TEXTURE_2D, self.inner[].id)

    def set_parameter(self, name: gl.TextureParameterName, value: Int) raises:
        gl.tex_parameteri(gl.TextureTarget.GL_TEXTURE_2D, name, Int32(value))

    def unbind(self) raises:
        gl.bind_texture(gl.TextureTarget.GL_TEXTURE_2D, 0)
