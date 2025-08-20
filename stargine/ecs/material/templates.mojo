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
ambient: Vec3f = Vec3f(0.1),
diffuse: Vec3f = Vec3f(0.5),
specular: Vec3f = Vec3f(0.5),
shininess: Float32 = 32) raises -> Material:
    var material = Material("lighted", Shader(get_shaders_path() / "lighted.glsl"))
    material.set_vec("light.ambient", light.ambient)
    material.set_vec("light.diffuse", light.diffuse)
    material.set_vec("light.specular", light.specular)
    material.set_vec("light.position", light.transform[].position)
    material.set_vec("material.diffuse", diffuse)
    material.set_vec("material.ambient", ambient)
    material.set_vec("material.specular", specular)
    material.set_scalar("material.shininess", shininess)
    return material^

fn custom_material(shader: Shader) -> Material:
    return Material("custom", shader)
