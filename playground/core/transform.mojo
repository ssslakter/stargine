struct Transform(Copyable, Movable):
    var position: Vec3f
    var rotation: Vec3f
    var scale: Vec3f

    fn __init__(out self):
        self.position = Vec3f(0.0, 0.0, 0.0)
        self.rotation = Vec3f(0.0, 0.0, 0.0)
        self.scale = Vec3f(1.0, 1.0, 1.0)

    fn translate(mut self, position: Vec3f):
        self.position += position

    fn local_to_world_matrix(self) -> Mat4f:
        return translate(self.position).matmul(scale(self.scale))

    fn transform_vector(self, vector: Vec3f) -> Vec3f:
        var model = self.local_to_world_matrix()
        res = model.matmul(Vec4f(vector, 1.0))
        return Vec3f(res[0], res[1], res[2])
