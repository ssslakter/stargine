from ...core import *


struct PointLight(Copyable, Movable):
    var transform: ArcPointer[Transform]
    var ambient: Vec3f
    var diffuse: Vec3f
    var specular: Vec3f
    var constant: Float32
    var linear: Float32
    var quadratic: Float32
    var gizmo: Cube

    fn __init__(out self, mut gizmo: Cube, position: Vec3f = Vec3f(0),
        ambient: Vec3f = Vec3f(0.2),
        diffuse: Vec3f = Vec3f(0.5),
        specular: Vec3f = Vec3f(1),
        constant: Float32 = 1.0,
        linear: Float32 = 0.09,
        quadratic: Float32 = 0.032,
        ):
        self.transform = ArcPointer(Transform(position=position))
        self.ambient = ambient
        self.diffuse = diffuse
        self.specular = specular
        self.constant = constant
        self.linear = linear
        self.quadratic = quadratic
        self.gizmo = gizmo
        self.gizmo.transform = self.transform
        self.gizmo.material.set_vec("color", Vec4(self.specular, 1))
