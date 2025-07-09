from .linalg import *


struct Camera(Copyable, Movable):
    alias world_up = Vec3f(0.0, 1.0, 0.0)
    var position: Vec3f
    var yaw: Float32
    var pitch: Float32
    var fov: Float32
    var aspect_ratio: Float32
    var near: Float32
    var far: Float32

    fn __init__(
        out self,
        position: Vec3f = Vec3f(0.0, 0.0, 0.0),
        yaw: Float32 = 0.0,
        pitch: Float32 = 0.0,
        fov: Float32 = 45.0,
        aspect_ratio: Float32 = 1.0,
        near: Float32 = 0.1,
        far: Float32 = 100.0,
    ):
        self.position = position
        self.yaw = yaw
        self.pitch = pitch
        self.fov = fov
        self.aspect_ratio = aspect_ratio
        self.near = near
        self.far = far

    fn get_forward(self) -> Vec3f:
        return Vec3f(
            cos(self.yaw) * cos(self.pitch),
            sin(self.pitch),
            sin(self.yaw) * cos(self.pitch),
        )

    fn look_at(mut self, target: Vec3f):
        var forward = target - self.position
        self.yaw = atan2(forward.z(), forward.x())
        self.pitch = atan2(forward.y(), Vec2f(forward.x(), forward.z()).length())

    fn get_view_matrix(self) -> Mat4f:
        return look_at(self.position, self.position + self.get_forward(), Self.world_up)

    fn get_projection_matrix(self) -> Mat4f:
        return perspective(self.fov, self.aspect_ratio, self.near, self.far)

    fn move(mut self, offset: Vec3f):
        self.position += offset

    fn rotate(mut self, yaw_delta: Float32, pitch_delta: Float32):
        self.yaw += radians(yaw_delta)
        self.pitch += radians(pitch_delta)
        # To prevent screen flipping, the pitch is constrained to be within [-89, 89] degrees.
        alias pitch_limit = radians(89.0)
        if self.pitch > pitch_limit:
            self.pitch = pitch_limit
        if self.pitch < -pitch_limit:
            self.pitch = -pitch_limit


fn radians(degrees: Float32) -> Float32:
    return degrees * math.pi / 180.0