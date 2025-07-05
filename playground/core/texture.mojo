from python import PythonConvertible
from .imports import *

alias PyPathLike = os.PathLike & PythonConvertible & Copyable


def load_texture2d[PathLike: PyPathLike](path: PathLike) -> NDBuffer[DType.uint8, 3, MutableAnyOrigin]:
    np = Python.import_module("numpy")
    pil = Python.import_module("PIL.Image")
    img = pil.open(path.to_python_object())
    img = img.convert("RGB")
    img = img.transpose(pil.FLIP_TOP_BOTTOM)
    return from_numpy[DType.uint8, 3](np.array(img))


fn init_texture[PathLike: PyPathLike](path: PathLike) raises -> Id:
    var texture_id: Id = 0
    gl.gen_textures(1, Ptr(to=texture_id))
    gl.bind_texture(gl.TextureTarget.TEXTURE_2D, texture_id)
    gl.tex_parameteri(gl.TextureTarget.TEXTURE_2D, gl.TextureParameterName.TEXTURE_WRAP_S, Int(gl.TextureWrapMode.MIRRORED_REPEAT))
    gl.tex_parameteri(gl.TextureTarget.TEXTURE_2D, gl.TextureParameterName.TEXTURE_WRAP_T, Int(gl.TextureWrapMode.MIRRORED_REPEAT))
    try:
        image = load_texture2d(path)
    except e:
        print("Failed to load texture:", e)
        return 0
    shape = image.get_shape()
    width, height, channels = shape[0], shape[1], shape[2]
    gl.tex_image_2d(gl.TextureTarget.TEXTURE_2D, 0, gl.InternalFormat.RGB, width, height, 0, gl.PixelFormat.RGB, gl.PixelType.UNSIGNED_BYTE, image.data.bitcast[NoneType]())
    gl.generate_mipmap(gl.TextureTarget.TEXTURE_2D)
    return texture_id
