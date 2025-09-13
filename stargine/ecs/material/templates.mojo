from pathlib import Path
from ..light import *
from .base import *
from os import env


fn get_shaders_path() raises -> Path:
    return Path(env.getenv("ROOT_DIR")) / "ecs/material/shaders"


fn get_light_shaders_path() raises -> Path:
    return Path(env.getenv("ROOT_DIR")) / "ecs/light/shaders"


fn unlit_material(color: Vec4f = Vec4f(0.5, 0.5, 0.5, 1.0)) raises -> Material:
    var material = Material("unlit", Shader(get_shaders_path() / "unlit.glsl"))
    material.set_vec("color", color)
    return material^


fn texture_material(texture: Texture) raises -> Material:
    var material = Material("texture", Shader(get_shaders_path() / "texture.glsl"))
    material.set_texture("texture1", texture)
    return material^


fn basic_material(
    diffuse: Texture,
    specular: Texture,
    point_light: Optional[PointLight] = None,
    dir_light: Optional[DirectionalLight] = None,
    shininess: Float32 = 32,
) raises -> Material:
    var path = get_shaders_path() / "basic"
    var light_path = get_light_shaders_path()
    var material = Material(
        "lighted",
        Shader(
            [path / "vertex.glsl"], [ path / "fragment.glsl", light_path / "lights.glsl",]
        ),
    )
    if point_light:
        var light = point_light.value()
        material.set_bool("pointLight.enabled", True)
        material.set_vec("pointLight.ambient", light.ambient)
        material.set_vec("pointLight.diffuse", light.diffuse)
        material.set_vec("pointLight.specular", light.specular)
        material.set_vec("pointLight.position", light.transform[].position)
        material.set_scalar("pointLight.constant", light.constant)
        material.set_scalar("pointLight.linear", light.linear)
        material.set_scalar("pointLight.quadratic", light.quadratic)
    else:
        material.set_bool("pointLight.enabled", False)
    if dir_light:
        var light = dir_light.value()
        material.set_bool("dirLight.enabled", True)
        material.set_vec("dirLight.direction", light.direction)
        material.set_vec("dirLight.ambient", light.ambient)
        material.set_vec("dirLight.diffuse", light.diffuse)
        material.set_vec("dirLight.specular", light.specular)
    else:
        material.set_bool("dirLight.enabled", False)

    material.set_texture("material.diffuse", diffuse)
    material.set_texture("material.specular", specular)
    material.set_scalar("material.shininess", shininess)
    return material^


fn custom_material(shader: Shader) -> Material:
    return Material("custom", shader)
