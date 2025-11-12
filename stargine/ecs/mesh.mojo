from ..core import *

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
        self.positions = positions.copy()
        self.normals = normals
        self.uvs = uvs
        self.colors = colors
        self.indices = indices
        self.buf = None

    fn get_layout(self) -> VertexLayout:
        elements = List[VertexAttribute]()
        elements.append(VertexAttribute(VertexAttributeType.POSITION))
        if self.uvs:
            elements.append(VertexAttribute(VertexAttributeType.UV))
        if self.normals:
            elements.append(VertexAttribute(VertexAttributeType.NORMAL))
        if self.colors:
            elements.append(VertexAttribute(VertexAttributeType.COLOR))
        return VertexLayout(elements^)

    fn to_gpu(mut self):
        self.buf = GraphicsBuffer(self.get_layout(), self.positions.copy(), self.colors, self.uvs, self.normals, self.indices)

    fn draw(self):
        if not self.buf:
            print("ERROR: VertexArray not bound, skipping draw")
            return
        self.buf.value().draw()
