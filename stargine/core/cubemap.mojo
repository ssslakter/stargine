import opengl as gl
from std.memory import ArcPointer
from .texture import load_image
from .utils import Id, Ptr

comptime FACE_COUNT = 6


struct _CubeMapInner(Movable):
    """Owns a GL cube map texture name and deletes it exactly once."""

    var id: Id

    def __init__(out self, faces: List[String]) raises:
        if len(faces) != FACE_COUNT:
            raise Error("a cube map needs ", FACE_COUNT, " faces, got ", len(faces))
        self.id = 0
        gl.gen_textures(1, Ptr(to=self.id))
        gl.bind_texture(gl.TextureTarget.GL_TEXTURE_CUBE_MAP, self.id)

        for face in range(FACE_COUNT):
            var image = load_image(faces[face].copy())
            # The six face targets are consecutive, in +X -X +Y -Y +Z -Z order.
            var target = gl.TextureTarget(
                UInt32(Int(gl.TextureTarget.GL_TEXTURE_CUBE_MAP_POSITIVE_X) + face)
            )
            gl.tex_image_2d(
                target,
                0,
                gl.InternalFormat.GL_RGBA,
                Int32(image.shape[1]),
                Int32(image.shape[0]),
                0,
                gl.PixelFormat.GL_RGBA,
                gl.PixelType.GL_UNSIGNED_BYTE,
                image.data.unsafe_ptr().unsafe_bitcast[NoneType](),
            )

    def __deinit__(deinit self):
        if self.id:
            try:
                gl.delete_textures(1, Ptr(to=self.id))
            except err:
                print("Failed to delete cube map:", err)


struct CubeMap(Copyable, Movable):
    var inner: ArcPointer[_CubeMapInner]

    def __init__(out self, faces: List[String]) raises:
        """Loads the six faces in +X -X +Y -Y +Z -Z order."""
        self.inner = ArcPointer(_CubeMapInner(faces))
        self.set_parameter(gl.TextureParameterName.GL_TEXTURE_MIN_FILTER, Int(gl.TextureMinFilter.GL_LINEAR))
        self.set_parameter(gl.TextureParameterName.GL_TEXTURE_MAG_FILTER, Int(gl.TextureMagFilter.GL_LINEAR))
        for wrap in [
            gl.TextureParameterName.GL_TEXTURE_WRAP_S,
            gl.TextureParameterName.GL_TEXTURE_WRAP_T,
            gl.TextureParameterName.GL_TEXTURE_WRAP_R,
        ]:
            self.set_parameter(wrap, Int(gl.TextureWrapMode.GL_CLAMP_TO_EDGE))

    def set_parameter(self, name: gl.TextureParameterName, value: Int) raises:
        gl.tex_parameteri(gl.TextureTarget.GL_TEXTURE_CUBE_MAP, name, Int32(value))

    def bind(self, texture_unit: gl.TextureUnit = gl.TextureUnit.GL_TEXTURE0) raises:
        gl.active_texture(texture_unit)
        gl.bind_texture(gl.TextureTarget.GL_TEXTURE_CUBE_MAP, self.inner[].id)
