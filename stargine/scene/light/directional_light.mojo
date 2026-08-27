from ...core.linalg import Vec3f


struct DirectionalLight(Copyable, Movable):
    var direction: Vec3f
    var ambient: Vec3f
    var diffuse: Vec3f
    var specular: Vec3f

    def __init__(
        out self,
        direction: Vec3f = Vec3f(0),
        ambient: Vec3f = Vec3f(0.2),
        diffuse: Vec3f = Vec3f(0.5),
        specular: Vec3f = Vec3f(1),
    ):
        self.direction = direction
        self.ambient = ambient
        self.diffuse = diffuse
        self.specular = specular
