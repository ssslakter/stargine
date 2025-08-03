from ...core import *


struct PointLight(Copyable, Movable):
    var transform: ArcPointer[Transform]
    var color: Vec3f
    var gizmo: Cube

    fn __init__(out self, mut gizmo: Cube, position: Vec3f = Vec3f(0), color: Vec3f = Vec3f(1)):
        self.transform = Transform(position=position)
        self.color = color
        self.gizmo = gizmo
        self.gizmo.transform = self.transform
        self.gizmo.material.set_vec("color", Vec4(self.color, 1))
