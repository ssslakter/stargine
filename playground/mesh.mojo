from .core import *

@fieldwise_init
struct Vertex(Copyable & Movable, WithVertexLayout, Writable):
    var position: Vec3f

    fn write_to[W: Writer](self, mut writer: W):
        writer.write("Vertex(position=(", self.position[0], ", ", self.position[1], ", ", self.position[2], "))")

    @staticmethod
    fn get_layout() -> VertexLayout:
        return VertexLayout(
            elements=[
                VertexAttribute(sizeof[Vec3f](), DType.float32, num_components=3),
            ],
            stride=sizeof[Vertex](),
        )


struct Mesh(Movable, Copyable):
    var vertices: List[Vertex]
    var indices: List[UInt32]

    var vao: Optional[VertexArray[Vertex]]

    fn __init__(out self, vertices: List[Vertex], indices: List[UInt32]):
        self.vertices = vertices
        self.indices = indices
        self.vao = None

    fn bind(mut self):
        var vbo = VertexBuffer[Vertex](self.vertices)
        var ebo = IndexBuffer(self.indices)
        self.vao = VertexArray(Vertex.get_layout(), vbo, ebo)

    fn draw(self):
        if not self.vao:
            print("ERROR: VertexArray not bound, skipping draw")
            return
        self.vao.value().draw()