from std.memory import ArcPointer
from ..core.linalg import Vec2f, Vec3f
from ..ecs.camera import Camera
from ..ecs.material import Material, unlit_material
from ..ecs.mesh import Mesh
from ..ecs.transform import Transform


def generate_cube_data() -> Tuple[List[Vec3f], List[Vec2f], List[Vec3f]]:
    """Returns the positions, uvs and normals of a unit cube, two triangles per face."""
    var positions: List[Vec3f] = [
        # Back face (-Z)
        Vec3f(-0.5, -0.5, -0.5), Vec3f(0.5, -0.5, -0.5), Vec3f(0.5, 0.5, -0.5),
        Vec3f(-0.5, -0.5, -0.5), Vec3f(0.5, 0.5, -0.5), Vec3f(-0.5, 0.5, -0.5),

        # Front face (+Z)
        Vec3f(0.5, -0.5, 0.5), Vec3f(-0.5, -0.5, 0.5), Vec3f(-0.5, 0.5, 0.5),
        Vec3f(0.5, -0.5, 0.5), Vec3f(-0.5, 0.5, 0.5), Vec3f(0.5, 0.5, 0.5),

        # Bottom face (-Y)
        Vec3f(-0.5, -0.5, 0.5), Vec3f(0.5, -0.5, 0.5), Vec3f(0.5, -0.5, -0.5),
        Vec3f(-0.5, -0.5, 0.5), Vec3f(0.5, -0.5, -0.5), Vec3f(-0.5, -0.5, -0.5),

        # Top face (+Y)
        Vec3f(-0.5, 0.5, -0.5), Vec3f(0.5, 0.5, -0.5), Vec3f(0.5, 0.5, 0.5),
        Vec3f(-0.5, 0.5, -0.5), Vec3f(0.5, 0.5, 0.5), Vec3f(-0.5, 0.5, 0.5),

        # Left face (-X)
        Vec3f(-0.5, -0.5, 0.5), Vec3f(-0.5, -0.5, -0.5), Vec3f(-0.5, 0.5, -0.5),
        Vec3f(-0.5, -0.5, 0.5), Vec3f(-0.5, 0.5, -0.5), Vec3f(-0.5, 0.5, 0.5),

        # Right face (+X)
        Vec3f(0.5, -0.5, -0.5), Vec3f(0.5, -0.5, 0.5), Vec3f(0.5, 0.5, 0.5),
        Vec3f(0.5, -0.5, -0.5), Vec3f(0.5, 0.5, 0.5), Vec3f(0.5, 0.5, -0.5),
    ]

    var uvs: List[Vec2f] = [
        # Back face
        Vec2f(0.0, 0.0), Vec2f(1.0, 0.0), Vec2f(1.0, 1.0),
        Vec2f(0.0, 0.0), Vec2f(1.0, 1.0), Vec2f(0.0, 1.0),

        # Front face
        Vec2f(1.0, 0.0), Vec2f(0.0, 0.0), Vec2f(0.0, 1.0),
        Vec2f(1.0, 0.0), Vec2f(0.0, 1.0), Vec2f(1.0, 1.0),

        # Bottom face
        Vec2f(0.0, 1.0), Vec2f(1.0, 1.0), Vec2f(1.0, 0.0),
        Vec2f(0.0, 1.0), Vec2f(1.0, 0.0), Vec2f(0.0, 0.0),

        # Top face
        Vec2f(0.0, 0.0), Vec2f(1.0, 0.0), Vec2f(1.0, 1.0),
        Vec2f(0.0, 0.0), Vec2f(1.0, 1.0), Vec2f(0.0, 1.0),

        # Left face
        Vec2f(1.0, 0.0), Vec2f(0.0, 0.0), Vec2f(0.0, 1.0),
        Vec2f(1.0, 0.0), Vec2f(0.0, 1.0), Vec2f(1.0, 1.0),

        # Right face
        Vec2f(0.0, 0.0), Vec2f(1.0, 0.0), Vec2f(1.0, 1.0),
        Vec2f(0.0, 0.0), Vec2f(1.0, 1.0), Vec2f(0.0, 1.0),
    ]

    var normals: List[Vec3f] = [
        # Back face
        Vec3f(0.0, 0.0, -1.0), Vec3f(0.0, 0.0, -1.0), Vec3f(0.0, 0.0, -1.0),
        Vec3f(0.0, 0.0, -1.0), Vec3f(0.0, 0.0, -1.0), Vec3f(0.0, 0.0, -1.0),

        # Front face
        Vec3f(0.0, 0.0, 1.0), Vec3f(0.0, 0.0, 1.0), Vec3f(0.0, 0.0, 1.0),
        Vec3f(0.0, 0.0, 1.0), Vec3f(0.0, 0.0, 1.0), Vec3f(0.0, 0.0, 1.0),

        # Bottom face
        Vec3f(0.0, -1.0, 0.0), Vec3f(0.0, -1.0, 0.0), Vec3f(0.0, -1.0, 0.0),
        Vec3f(0.0, -1.0, 0.0), Vec3f(0.0, -1.0, 0.0), Vec3f(0.0, -1.0, 0.0),

        # Top face
        Vec3f(0.0, 1.0, 0.0), Vec3f(0.0, 1.0, 0.0), Vec3f(0.0, 1.0, 0.0),
        Vec3f(0.0, 1.0, 0.0), Vec3f(0.0, 1.0, 0.0), Vec3f(0.0, 1.0, 0.0),

        # Left face
        Vec3f(-1.0, 0.0, 0.0), Vec3f(-1.0, 0.0, 0.0), Vec3f(-1.0, 0.0, 0.0),
        Vec3f(-1.0, 0.0, 0.0), Vec3f(-1.0, 0.0, 0.0), Vec3f(-1.0, 0.0, 0.0),

        # Right face
        Vec3f(1.0, 0.0, 0.0), Vec3f(1.0, 0.0, 0.0), Vec3f(1.0, 0.0, 0.0),
        Vec3f(1.0, 0.0, 0.0), Vec3f(1.0, 0.0, 0.0), Vec3f(1.0, 0.0, 0.0),
    ]

    return positions^, uvs^, normals^


struct Cube(Copyable, Movable):
    var mesh: Mesh
    var transform: ArcPointer[Transform]
    var material: Material

    def __init__(out self, material: Optional[Material] = None, mesh: Optional[Mesh] = None) raises:
        self.transform = ArcPointer(Transform())
        self.material = material.value().copy() if material else unlit_material()

        if mesh:
            self.mesh = mesh.value().copy()
        else:
            var data = generate_cube_data()
            self.mesh = Mesh(
                data[0].copy(),
                uvs=Optional(data[1].copy()) if self.material.textures else None,
                normals=data[2].copy(),
            )

    def draw(mut self, camera: Camera) raises:
        self.material.set_vec("cameraPos", camera.transform.position)
        self.material.set_matrix("model", self.transform[].local_to_world_matrix())
        self.material.set_matrix("normalMatrix", self.transform[].normal_matrix())
        self.material.bind()
        self.mesh.draw()
