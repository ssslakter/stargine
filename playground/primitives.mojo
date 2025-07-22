from .ecs import *


fn unit_cube_vertices[dim: Int, dtype: DType = DType.float32]() -> List[Vec[dtype, dim]]:
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

fn generate_cube_data() -> (List[Vec3f], List[Vec2f], List[UInt32]):   
    var positions = [
        Vec3f(0.0, 0.0, 0.0), Vec3f(1.0, 0.0, 0.0), Vec3f(1.0, 1.0, 0.0), Vec3f(0.0, 1.0, 0.0),
        Vec3f(1.0, 0.0, 1.0), Vec3f(0.0, 0.0, 1.0), Vec3f(0.0, 1.0, 1.0), Vec3f(1.0, 1.0, 1.0),
        Vec3f(0.0, 0.0, 1.0), Vec3f(1.0, 0.0, 1.0), Vec3f(1.0, 0.0, 0.0), Vec3f(0.0, 0.0, 0.0),
        Vec3f(0.0, 1.0, 0.0), Vec3f(1.0, 1.0, 0.0), Vec3f(1.0, 1.0, 1.0), Vec3f(0.0, 1.0, 1.0),
        Vec3f(0.0, 0.0, 1.0), Vec3f(0.0, 0.0, 0.0), Vec3f(0.0, 1.0, 0.0), Vec3f(0.0, 1.0, 1.0),
        Vec3f(1.0, 0.0, 0.0), Vec3f(1.0, 0.0, 1.0), Vec3f(1.0, 1.0, 1.0), Vec3f(1.0, 1.0, 0.0),
    ]
    var uvs = List[Vec2f]()
    for _ in range(6):
        uvs.extend(square_uvs)

    var indices = List[UInt32]()
    for i in range(6):
        base_index = i * 4
        indices.append(base_index + 0)
        indices.append(base_index + 1)
        indices.append(base_index + 2)
        indices.append(base_index + 0)
        indices.append(base_index + 2)
        indices.append(base_index + 3)

    return positions, uvs, indices


struct Cube(Copyable, Movable):
    var mesh: Mesh
    var transform: Transform
    var material: Material

    fn __init__(out self, material: Optional[Material] = None) raises:
        self.transform = Transform()
        self.material = material.or_else(unlit_material())

        positions, uvs, indices = generate_cube_data()

        self.mesh = Mesh(positions, indices=indices, uvs=Optional(uvs) if self.material.textures else None)

    fn draw(mut self):
        self.material.set_matrix("model", self.transform.local_to_world_matrix())
        self.material.bind()
        self.mesh.draw()


struct Square(Copyable, Movable):
    var mesh: Mesh
    var transform: Transform
    var material: Optional[Material]

    fn __init__(out self, material: Optional[Material] = None) raises:
        self.transform = Transform()
        self.material = material

        var positions = [
            Vec3f(0, 0, 0),
            Vec3f(1, 0, 0),
            Vec3f(1, 1, 0),
            Vec3f(0, 1, 0),
        ]
        var indices: List[UInt32] = [0, 1, 2, 0, 2, 3]

        self.mesh = Mesh(positions, indices=indices)

    fn draw(mut self):
        if self.material:
            self.material.value().set_matrix("model", self.transform.local_to_world_matrix())
            self.material.value().bind()
        self.mesh.draw()
