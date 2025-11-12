from ..ecs import *


fn unit_cube_vertices[
    dim: Int, dtype: DType = DType.float32
]() -> List[Vec[dtype, dim]]:
    alias num_vertices = 1 << dim
    var vertices = List[Vec[dtype, dim]]()

    for i in range(num_vertices):
        var vertex = Vec[dtype, dim]()
        for j in range(dim):
            vertex[j] = Scalar[dtype]((i >> j) & 1)
        vertices.append(vertex)

    return vertices


alias square_uvs = List[Vec2f](
    Vec2f(0.0, 0.0),
    Vec2f(1.0, 0.0),
    Vec2f(1.0, 1.0),
    Vec2f(0.0, 1.0),
)


@always_inline
fn generate_cube_data() -> Tuple[
    List[Vec3f],  # positions
    List[Vec2f],  # uvs
    List[Vec3f],  # normals
]:
    var positions = List[Vec3f](
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
    )

    var uvs = List[Vec2f](
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
    )

    var normals = List[Vec3f](
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
    )

    return positions^, uvs^, normals^



struct Cube(Copyable, Movable):
    var mesh: Mesh
    var transform: ArcPointer[Transform]
    var material: Material

    fn __init__(
        out self,
        material: Optional[Material] = None,
        mesh_data: Optional[Mesh] = None,
    ) raises:
        self.transform = ArcPointer(Transform())
        self.material = material.or_else(unlit_material())

        res = generate_cube_data()
        positions = res[0].copy()
        uvs = res[1].copy()
        normals = res[2].copy()

        self.mesh = mesh_data.or_else(
            Mesh(
                positions^,
                uvs=Optional(uvs^) if self.material.textures else None,
                normals=normals^,
            )
        )

    fn draw(mut self, camera: Camera):
        self.material.set_vec("cameraPos", camera.transform.position)
        self.material.set_matrix(
            "model", self.transform[].local_to_world_matrix()
        )
        self.material.set_matrix(
            "normalMatrix", self.transform[].normal_matrix()
        )
        self.material.bind()
        self.mesh.draw()
