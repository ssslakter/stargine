from std.memory import ArcPointer
from ..core.linalg import Vec3f
from ..ecs.material import Material
from ..ecs.mesh import PositionMesh
from ..ecs.transform import Transform


struct Square(Copyable, Movable):
    var mesh: PositionMesh
    var transform: ArcPointer[Transform]
    var material: Optional[Material]

    def __init__(out self, material: Optional[Material] = None) raises:
        self.transform = ArcPointer(Transform())
        self.material = material.copy()

        var positions = [
            Vec3f(0, 0, 0),
            Vec3f(1, 0, 0),
            Vec3f(1, 1, 0),
            Vec3f(0, 1, 0),
        ]
        var indices: List[UInt32] = [0, 1, 2, 0, 2, 3]
        self.mesh = PositionMesh(positions^, indices=indices^)

    def draw(mut self) raises:
        if self.material:
            self.material.value().set_matrix("model", self.transform[].local_to_world_matrix())
            self.material.value().bind()
        self.mesh.draw()
