from std.memory import ArcPointer
from ..core.gpu import VertexAttributeType
from .camera import Camera
from .material import Material
from .mesh import NORMAL, POSITION, UV, Mesh
from .transform import Transform


struct Model[*attributes: VertexAttributeType](Copyable, Movable):
    """A mesh, where it is, and how it is shaded."""

    var mesh: Mesh[*Self.attributes]
    var transform: ArcPointer[Transform]
    var material: Material

    def __init__(out self, var mesh: Mesh[*Self.attributes], var material: Material) raises:
        self.mesh = mesh^
        self.mesh.to_gpu()
        self.transform = ArcPointer(Transform())
        self.material = material^

    def draw(mut self, camera: Camera) raises:
        self.material.set_vec("cameraPos", camera.transform.position)
        self.material.set_matrix("view", camera.get_view_matrix())
        self.material.set_matrix("projection", camera.get_projection_matrix())
        self.material.set_matrix("model", self.transform[].local_to_world_matrix())
        self.material.set_matrix("normalMatrix", self.transform[].normal_matrix())
        self.material.bind()
        self.mesh.draw()


comptime StandardModel = Model[POSITION, UV, NORMAL]
