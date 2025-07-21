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

fn square_uvs() -> List[Vec2f]:
    return [
        Vec2f(0.0, 0.0),
        Vec2f(1.0, 0.0),
        Vec2f(0.0, 1.0),
        Vec2f(1.0, 1.0),
    ]

struct Cube(Movable, Copyable):
    var mesh: Mesh
    var transform: Transform
    var material: Optional[Material]

    fn __init__(out self, material: Optional[Material] = None) raises:
        self.transform = Transform()
        self.material = material
        
        var positions = unit_cube_vertices[3, DType.float32]()
        # var uvs = List[Vec2f](
        #     Vec2f(0.0, 0.0), Vec2f(1.0, 0.0), Vec2f(1.0, 1.0), 
        # )

        self.mesh = Mesh(positions)

    fn draw(mut self):
        if self.material:
            self.material.value().set_matrix("model", self.transform.local_to_world_matrix())
            self.material.value().bind()
        self.mesh.draw()


struct Square(Movable, Copyable):
    var mesh: Mesh
    var transform: Transform
    var material: Optional[Material]

    fn __init__(out self, material: Optional[Material] = None) raises:
        self.transform = Transform()
        self.material = material
        
        var positions = [
            Vec3f(0,0,0),
            Vec3f(1,0,0,),
            Vec3f(1,1,0),
            Vec3f(0,1,0),
        ]
        var indices: List[UInt32] = [
            0,1,2,
            0,2,3
        ]

        self.mesh = Mesh(positions, indices=indices)

    fn draw(mut self):
        if self.material:
            self.material.value().set_matrix("model", self.transform.local_to_world_matrix())
            self.material.value().bind()
        self.mesh.draw()