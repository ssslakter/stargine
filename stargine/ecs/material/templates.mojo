from pathlib import Path
from ..light import *
from .base import *
from os import env

fn get_shaders_path() raises -> Path:
    return Path(env.getenv("ROOT_DIR"))/'ecs/material/shaders'

fn unlit_material(color: Vec4f = Vec4f(0.5, 0.5, 0.5, 1.0)) raises -> Material:
    var material = Material("unlit", Shader(get_shaders_path() / "unlit.glsl"))
    material.set_vec("color", color)
    return material^

fn texture_material(texture: Texture) raises -> Material:
    var material = Material("texture", Shader(get_shaders_path() / "texture.glsl"))
    material.set_texture("texture1", texture)
    return material^

fn lighted_material(ref light: PointLight, 
color: Vec4f=Vec4f(1),
ambient: Float32 = 0.1,
specular_strength: Float32 = 0.5) raises -> Material:
    var material = Material("lighted", Shader(get_shaders_path() / "lighted.glsl"))
    material.set_vec("lightColor", light.color)
    material.set_vec("objectColor", color)
    material.set_vec("lightPos", light.transform[].position)
    material.set_scalar("ambient", ambient)
    material.set_scalar("specularStrength", specular_strength)
    return material^

fn custom_material(shader: Shader) -> Material:
    return Material("custom", shader)
