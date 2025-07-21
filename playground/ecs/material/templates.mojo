from pathlib import Path
from .base import *
from os import env

fn get_shaders_path() raises -> Path:
    return Path(env.getenv("ROOT_DIR")/'ecs/material/shaders')

fn unlit_material(color: Vec4f = Vec4f(0.5, 0.5, 0.5, 1.0)) raises -> Material:
    var material = Material("unlit", Shader(get_shaders_path() / "unlit.glsl"))
    material.set_vec("color", color)
    return material^

fn texture_material(texture: Texture) raises -> Material:
    var material = Material("texture", Shader(get_shaders_path() / "texture.glsl"))
    material.set_texture("texture", texture)
    return material^