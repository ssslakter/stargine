from ..core import *


struct Camera(Copyable, Movable):
    alias world_up = Vec3f(0, 1, 0)
    var transform: Transform
    var fov: Float32
    var aspect_ratio: Float32
    var near: Float32
    var far: Float32

    fn __init__(
        out self,
        position: Vec3f = Vec3f(0),
        fov: Float32 = 45.0,
        aspect_ratio: Float32 = 1.0,
        near: Float32 = 0.1,
        far: Float32 = 100.0,
    ):
        self.transform = Transform(position)
        self.fov = fov
        self.aspect_ratio = aspect_ratio
        self.near = near
        self.far = far

    fn get_forward(self) -> Vec3f:
        yaw, pitch = self.transform.yaw, self.transform.pitch
        return Vec3f(
            cos(yaw) * cos(pitch),
            sin(pitch),
            sin(yaw) * cos(pitch),
        )

    fn get_right(self) -> Vec3f:
        return self.world_up.cross(self.get_forward()).normalize()

    fn rotate_deg(mut self, yaw: Float32, pitch: Float32):
        self.transform.rotate_deg(pitch, yaw)
        self.transform.pitch = max(min(self.transform.pitch, radians(89)), radians(-89))

    fn get_view_matrix(self) -> Mat4f:
        return look_at(
            self.transform.position,
            self.transform.position + self.get_forward(),
            Self.world_up,
        )

    fn get_projection_matrix(self) -> Mat4f:
        return perspective(self.fov, self.aspect_ratio, self.near, self.far)
