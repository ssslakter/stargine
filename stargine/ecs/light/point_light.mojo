from ...core import *


struct PointLight(Copyable, Movable):
    var transform: ArcPointer[Transform]
    var ambient: Vec3f
    var diffuse: Vec3f
    var specular: Vec3f
    var gizmo: Cube

    fn __init__(out self, mut gizmo: Cube, position: Vec3f = Vec3f(0),
        ambient: Vec3f = Vec3f(0.2),
        diffuse: Vec3f = Vec3f(0.5),
        specular: Vec3f = Vec3f(1),
        ):
        self.transform = Transform(position=position)
        self.ambient = ambient
        self.diffuse = diffuse
        self.specular = specular
        self.gizmo = gizmo
        self.gizmo.transform = self.transform
        self.gizmo.material.set_vec("color", Vec4(self.specular, 1))
