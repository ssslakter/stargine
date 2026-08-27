from std.math import asin, atan2, cos, sin
from ..core.linalg import Mat4f, Vec3f, look_at, perspective
from .transform import Transform, radians


struct Camera(Copyable, Movable):
    comptime world_up = Vec3f(0, 1, 0)

    var transform: Transform
    var fov: Float32
    var aspect_ratio: Float32
    var near: Float32
    var far: Float32

    def __init__(
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

    def get_forward(self) -> Vec3f:
        var yaw, pitch = self.transform.yaw, self.transform.pitch
        return Vec3f(cos(yaw) * cos(pitch), sin(pitch), sin(yaw) * cos(pitch))

    def get_right(self) -> Vec3f:
        return self.get_forward().cross(Self.world_up).normalize()

    def look_at(mut self, target: Vec3f):
        """Aims the camera at a point, leaving its position alone."""
        var direction = (target - self.transform.position).normalize()
        self.transform.pitch = asin(max(min(direction.y(), 1), -1))
        self.transform.yaw = atan2(direction.z(), direction.x())

    def rotate_deg(mut self, yaw: Float32, pitch: Float32):
        self.transform.rotate_deg(pitch, yaw)
        self.transform.pitch = max(min(self.transform.pitch, radians(89)), radians(-89))

    def get_view_matrix(self) -> Mat4f:
        return look_at(
            self.transform.position,
            self.transform.position + self.get_forward(),
            Self.world_up,
        )

    def get_projection_matrix(self) -> Mat4f:
        return perspective(self.fov, self.aspect_ratio, self.near, self.far)
