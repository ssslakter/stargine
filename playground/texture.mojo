from .core.utils import *
from python import Python

def load_texture2d(path: String) -> NDBuffer[DType.uint8, 3, MutableAnyOrigin]:
    np = Python.import_module("numpy")
    pil = Python.import_module("PIL.Image")
    img = pil.open(path)
    img = img.convert("RGB")
    img = img.transpose(pil.FLIP_TOP_BOTTOM)
    return from_numpy[DType.uint8, 3](np.array(img))