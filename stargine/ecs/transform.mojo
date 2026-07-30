from std.math import pi, tau

struct Transform(Copyable, Movable):
    var position: Vec3f
    var scale: Vec3f
    var pitch: Float32
    var yaw: Float32
    var roll: Float32

    def __init__(out self, position: Vec3f = Vec3f(0), scale: Vec3f = Vec3f(1)):
        self.position = position
        self.scale = scale
        self.pitch = 0.0
        self.yaw = 0.0
        self.roll = 0.0

    def set_scale(mut self, scale: Vec3f): self.scale = scale
    def set_scale(mut self, scale: Float32): self.set_scale(Vec3f(scale))

    def rotate(
        mut self,
        pitch_delta: Float32 = 0,
        yaw_delta: Float32 = 0,
        roll_delta: Float32 = 0,
    ):
        self.pitch = normalize_angle(self.pitch + pitch_delta)
        self.yaw = normalize_angle(self.yaw + yaw_delta)
        self.roll = normalize_angle(self.roll + roll_delta)

    def rotate_deg(
        mut self,
        pitch_delta: Float32 = 0,
        yaw_delta: Float32 = 0,
        roll_delta: Float32 = 0,
    ):
        self.rotate(
            radians(pitch_delta), radians(yaw_delta), radians(roll_delta)
        )

    def translate(mut self, position: Vec3f):
        self.position += position

    def local_to_world_matrix(self) -> Mat4f:
        return (
            translate(self.position)
            .matmul(rotate_y(self.yaw))
            .matmul(rotate_x(self.pitch))
            .matmul(rotate_z(self.roll))
            .matmul(scale(self.scale))
        )

    def normal_matrix(self) -> Mat4f:
        return Mat4f(Mat3f(self.local_to_world_matrix()).inverse().transpose())

    def transform_vector(self, vector: Vec3f) -> Vec3f:
        var model = self.local_to_world_matrix()
        res = model.matmul(Vec4f(vector, 1.0))
        return Vec3f(res[0], res[1], res[2])


def radians(degrees: Float32) -> Float32:
    return degrees * pi / 180.0


def normalize_angle(angle: Float32) -> Float32:
    return (angle + pi) % tau - pi


def rotate_y(angle: Float32) -> Mat4f:
    return Mat4f(
        [
            Vec4f(cos(angle), 0.0, sin(angle), 0.0),
            Vec4f(0.0, 1.0, 0.0, 0.0),
            Vec4f(-sin(angle), 0.0, cos(angle), 0.0),
            Vec4f(0.0, 0.0, 0.0, 1.0),
        ]
    )


def rotate_x(angle: Float32) -> Mat4f:
    return Mat4f(
        [
            Vec4f(1.0, 0.0, 0.0, 0.0),
            Vec4f(0.0, cos(angle), sin(angle), 0.0),
            Vec4f(0.0, -sin(angle), cos(angle), 0.0),
            Vec4f(0.0, 0.0, 0.0, 1.0),
        ]
    )


def rotate_z(angle: Float32) -> Mat4f:
    return Mat4f(
        [
            Vec4f(cos(angle), sin(angle), 0.0, 0.0),
            Vec4f(-sin(angle), cos(angle), 0.0, 0.0),
            Vec4f(0.0, 0.0, 1.0, 0.0),
            Vec4f(0.0, 0.0, 0.0, 1.0),
        ]
    )
