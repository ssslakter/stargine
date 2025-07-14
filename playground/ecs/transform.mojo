struct Transform(Copyable, Movable):
    var position: Vec3f
    var scale: Vec3f
    var pitch: Float32
    var yaw: Float32
    var roll: Float32

    fn __init__(out self):
        self.position = Vec3f(0.0, 0.0, 0.0)
        self.scale = Vec3f(1.0, 1.0, 1.0)
        self.pitch = 0.0
        self.yaw = 0.0
        self.roll = 0.0

    fn rotate(mut self, pitch_delta: Float32 = 0, yaw_delta: Float32 = 0, roll_delta: Float32 = 0):
        self.pitch += pitch_delta % (2.0 * math.pi)
        self.yaw += yaw_delta % (2.0 * math.pi)
        self.roll += roll_delta % (2.0 * math.pi)

    fn translate(mut self, position: Vec3f):
        self.position += position

    fn local_to_world_matrix(self) -> Mat4f:
        return (
            translate(self.position)
            .matmul(rotate_y(self.yaw))
            .matmul(rotate_x(self.pitch))
            .matmul(rotate_z(self.roll))
            .matmul(scale(self.scale))
        )

    fn transform_vector(self, vector: Vec3f) -> Vec3f:
        var model = self.local_to_world_matrix()
        res = model.matmul(Vec4f(vector, 1.0))
        return Vec3f(res[0], res[1], res[2])


fn rotate_y(angle: Float32) -> Mat4f:
    return Mat4f(
        [
            Vec4f(cos(angle), 0.0, sin(angle), 0.0),
            Vec4f(0.0, 1.0, 0.0, 0.0),
            Vec4f(-sin(angle), 0.0, cos(angle), 0.0),
            Vec4f(0.0, 0.0, 0.0, 1.0),
        ]
    )


fn rotate_x(angle: Float32) -> Mat4f:
    return Mat4f(
        [
            Vec4f(1.0, 0.0, 0.0, 0.0),
            Vec4f(0.0, cos(angle), sin(angle), 0.0),
            Vec4f(0.0, -sin(angle), cos(angle), 0.0),
            Vec4f(0.0, 0.0, 0.0, 1.0),
        ]
    )


fn rotate_z(angle: Float32) -> Mat4f:
    return Mat4f(
        [
            Vec4f(cos(angle), sin(angle), 0.0, 0.0),
            Vec4f(-sin(angle), cos(angle), 0.0, 0.0),
            Vec4f(0.0, 0.0, 1.0, 0.0),
            Vec4f(0.0, 0.0, 0.0, 1.0),
        ]
    )
