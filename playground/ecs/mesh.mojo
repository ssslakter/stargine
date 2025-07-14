from ..core import *


@fieldwise_init
struct Vertex(Copyable & Movable, Writable):
    var position: Vec3f

    fn write_to[W: Writer](self, mut writer: W):
        writer.write("Vertex(position=(", self.position[0], ", ", self.position[1], ", ", self.position[2], "))")

    @staticmethod
    fn get_layout() -> VertexLayout:
        return VertexLayout(
            elements=[
                VertexAttributeDescriptor(VertexAttributeType.POSITION),
            ],
            stride=sizeof[Vertex](),
        )


struct Mesh(Copyable, Movable):
    var positions: List[Vec3f]
    var normals: Optional[List[Vec3f]]
    var uvs: Optional[List[Vec2f]]
    var colors: Optional[List[Vec4f]]
    var indices: Optional[List[UInt32]]

    var buf: Optional[GraphicsBuffer]

    fn __init__(
        out self,
        positions: List[Vec3f],
        normals: Optional[List[Vec3f]] = None,
        uvs: Optional[List[Vec2f]] = None,
        colors: Optional[List[Vec4f]] = None,
        indices: Optional[List[UInt32]] = None,
    ):
        self.positions = positions
        self.normals = normals
        self.uvs = uvs
        self.colors = colors
        self.indices = indices
        self.buf = None

    fn get_layout(self) -> VertexLayout:
        elements = List[VertexAttributeDescriptor]()
        elements.append(VertexAttributeDescriptor(VertexAttributeType.POSITION))
        if self.uvs:
            elements.append(VertexAttributeDescriptor(VertexAttributeType.UV))
        if self.normals:
            elements.append(VertexAttributeDescriptor(VertexAttributeType.NORMAL))
        if self.colors:
            elements.append(VertexAttributeDescriptor(VertexAttributeType.COLOR))
        print('got layout')
        return VertexLayout(elements)

    fn to_gpu(mut self):
        print("creating graphics buffer")
        self.buf = GraphicsBuffer(self.get_layout(), self.positions, self.colors, self.uvs, self.normals, self.indices)

    fn draw(self):
        if not self.buf:
            print("ERROR: VertexArray not bound, skipping draw")
            return
        self.buf.value().draw()
