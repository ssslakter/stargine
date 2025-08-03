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
fn generate_cube_data() -> (
    List[Vec3f],
    List[Vec2f],
    List[UInt32],
    List[Vec3f],
):
    var positions = [
        Vec3f(0.0, 0.0, 0.0),
        Vec3f(1.0, 0.0, 0.0),
        Vec3f(1.0, 1.0, 0.0),
        Vec3f(0.0, 1.0, 0.0),
        Vec3f(1.0, 0.0, 1.0),
        Vec3f(0.0, 0.0, 1.0),
        Vec3f(0.0, 1.0, 1.0),
        Vec3f(1.0, 1.0, 1.0),
        Vec3f(0.0, 0.0, 1.0),
        Vec3f(1.0, 0.0, 1.0),
        Vec3f(1.0, 0.0, 0.0),
        Vec3f(0.0, 0.0, 0.0),
        Vec3f(0.0, 1.0, 0.0),
        Vec3f(1.0, 1.0, 0.0),
        Vec3f(1.0, 1.0, 1.0),
        Vec3f(0.0, 1.0, 1.0),
        Vec3f(0.0, 0.0, 1.0),
        Vec3f(0.0, 0.0, 0.0),
        Vec3f(0.0, 1.0, 0.0),
        Vec3f(0.0, 1.0, 1.0),
        Vec3f(1.0, 0.0, 0.0),
        Vec3f(1.0, 0.0, 1.0),
        Vec3f(1.0, 1.0, 1.0),
        Vec3f(1.0, 1.0, 0.0),
    ]

    for ref p in positions:
        p -= Vec3f(0.5)

    var uvs = List[Vec2f]()
    for _ in range(6):
        uvs.extend(square_uvs)

    var normals = List[Vec3f]()

    var face_normals = [
        Vec3f(0.0, 0.0, -1.0),
        Vec3f(0.0, 0.0, 1.0),
        Vec3f(0.0, -1.0, 0.0),
        Vec3f(0.0, 1.0, 0.0),
        Vec3f(-1.0, 0.0, 0.0),
        Vec3f(1.0, 0.0, 0.0),
    ]

    for i in range(6):
        for _ in range(4):
            normals.append(face_normals[i])

    var indices = List[UInt32]()
    for i in range(6):
        base_index = i * 4
        indices.append(base_index + 0)
        indices.append(base_index + 1)
        indices.append(base_index + 2)
        indices.append(base_index + 0)
        indices.append(base_index + 2)
        indices.append(base_index + 3)

    return positions, uvs, indices, normals


struct Cube(Copyable, ExplicitlyCopyable, Movable):
    var mesh: Mesh
    var transform: ArcPointer[Transform]
    var material: Material

    fn __init__(
        out self,
        material: Optional[Material] = None,
        mesh_data: Optional[Mesh] = None,
    ) raises:
        self.transform = Transform()
        self.material = material.or_else(unlit_material())

        positions, uvs, indices, normals = generate_cube_data()

        self.mesh = mesh_data.or_else(
            Mesh(
                positions,
                indices=indices,
                uvs=Optional(uvs) if self.material.textures else None,
                normals=normals,
            )
        )

    fn copy(self) -> Self:
        return self

    fn draw(mut self):
        self.material.set_matrix(
            "model", self.transform[].local_to_world_matrix()
        )
        self.material.bind()
        self.mesh.draw()
