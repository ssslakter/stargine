from ..core.gpu import GraphicsBuffer, VertexAttributeType
from ..core.linalg import Vec2f, Vec3f, Vec4f

comptime POSITION = VertexAttributeType.POSITION
comptime UV = VertexAttributeType.UV
comptime NORMAL = VertexAttributeType.NORMAL
comptime COLOR = VertexAttributeType.COLOR


struct Mesh[*attributes: VertexAttributeType](Copyable, Movable):
    """Vertex data on the CPU plus, once uploaded, its interleaved GPU buffer.

    The attribute list is a compile-time parameter, so the stride and the
    interleaving loop are constants.
    """

    comptime Buffer = GraphicsBuffer[DType.uint32, *Self.attributes]

    var positions: List[Vec3f]
    var uvs: Optional[List[Vec2f]]
    var normals: Optional[List[Vec3f]]
    var colors: Optional[List[Vec4f]]
    var indices: Optional[List[UInt32]]
    var buf: Optional[Self.Buffer]

    def __init__(
        out self,
        positions: List[Vec3f],
        uvs: Optional[List[Vec2f]] = None,
        normals: Optional[List[Vec3f]] = None,
        colors: Optional[List[Vec4f]] = None,
        indices: Optional[List[UInt32]] = None,
    ):
        self.positions = positions.copy()
        self.uvs = uvs.copy()
        self.normals = normals.copy()
        self.colors = colors.copy()
        self.indices = indices.copy()
        self.buf = None

    def to_gpu(mut self) raises:
        self.buf = Self.Buffer(self.positions, self.uvs, self.normals, self.colors, self.indices)

    def draw(self) raises:
        if not self.buf:
            raise Error("mesh has no GPU buffer, call to_gpu() first")
        self.buf.value().draw()


comptime PositionMesh = Mesh[POSITION]
comptime TexturedMesh = Mesh[POSITION, UV]
comptime StandardMesh = Mesh[POSITION, UV, NORMAL]
