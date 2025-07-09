from pathlib import Path
from .base import *
from os import env

fn unlit_material(color: Vec4f = Vec4f(0.5, 0.5, 0.5, 1.0)) raises -> Material:
    shaders_path = Path(env.getenv("DEFAULT_SHADERS_PATH"))
    var material = Material("unlit", Shader(shaders_path / "unlit.glsl"))
    material.set_vec("color", color)
    return material^