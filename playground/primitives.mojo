from .core import Transform
from .material import *
from .mesh import *

fn unit_cube_vertices[dim: Int, dtype: DType = DType.float32]() -> List[Vec[dtype, dim]]:
    alias num_vertices = 1 << dim
    var vertices = List[Vec[dtype, dim]]()

    for i in range(num_vertices):
        var vertex = Vec[dtype, dim]()
        for j in range(dim):
            vertex[j] = Scalar[dtype]((i >> j) & 1)
        vertices.append(vertex)

    return vertices

struct Cube(Movable, Copyable):
    var mesh: Mesh
    var transform: Transform
    var material: Optional[Material]

    fn __init__(out self, material: Optional[Material] = None) raises:
        self.transform = Transform()
        self.material = material
        vertices = [Vertex(v) for v in unit_cube_vertices[3]()]
        indices: List[UInt32] = [
            0, 1, 2,    1, 3, 2,
            4, 6, 5,    5, 6, 7,
            0, 4, 1,    1, 4, 5,
            2, 3, 6,    3, 7, 6,
            0, 2, 4,    2, 6, 4,
            1, 5, 3,    3, 5, 7
            ]
        self.mesh = Mesh(vertices, indices)

    fn draw(mut self):
        if self.material:
            self.material.value().set_matrix("model", self.transform.local_to_world_matrix())
            self.material.value().bind()
        self.mesh.draw()
