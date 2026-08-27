from std.math import cos, pi, sin, tau
from ..core.linalg import Vec2f, Vec3f
from ..scene.material import Material, unlit_material
from ..scene.mesh import StandardMesh
from ..scene.model import StandardModel


def cube_mesh() -> StandardMesh:
    """A unit cube centred on the origin, two triangles per face, flat normals."""
    var positions = List[Vec3f]()
    var uvs = List[Vec2f]()
    var normals = List[Vec3f]()

    # Each face is described by its normal and the two edge vectors that span it.
    var faces: List[Tuple[Vec3f, Vec3f, Vec3f]] = [
        (Vec3f(0, 0, -1), Vec3f(-1, 0, 0), Vec3f(0, 1, 0)),
        (Vec3f(0, 0, 1), Vec3f(1, 0, 0), Vec3f(0, 1, 0)),
        (Vec3f(0, -1, 0), Vec3f(1, 0, 0), Vec3f(0, 0, 1)),
        (Vec3f(0, 1, 0), Vec3f(1, 0, 0), Vec3f(0, 0, -1)),
        (Vec3f(-1, 0, 0), Vec3f(0, 0, 1), Vec3f(0, 1, 0)),
        (Vec3f(1, 0, 0), Vec3f(0, 0, -1), Vec3f(0, 1, 0)),
    ]
    var corners: List[Tuple[Float32, Float32]] = [
        (Float32(0), Float32(0)),
        (Float32(1), Float32(0)),
        (Float32(1), Float32(1)),
        (Float32(0), Float32(0)),
        (Float32(1), Float32(1)),
        (Float32(0), Float32(1)),
    ]

    for face in faces:
        var normal, right, up = face[0], face[1], face[2]
        for corner in corners:
            var u, v = corner[0], corner[1]
            positions.append((normal + right * (u * 2 - 1) + up * (v * 2 - 1)) * 0.5)
            uvs.append(Vec2f(u, v))
            normals.append(normal)

    return StandardMesh(positions^, uvs=uvs^, normals=normals^)


def plane_mesh(subdivisions: Int = 1, uv_scale: Float32 = 1.0) -> StandardMesh:
    """A unit quad in the XZ plane facing +Y, subdivided into a grid."""
    var steps = max(subdivisions, 1)
    var positions = List[Vec3f]()
    var uvs = List[Vec2f]()
    var normals = List[Vec3f]()
    var indices = List[UInt32]()

    for row in range(steps + 1):
        for col in range(steps + 1):
            var u = Float32(col) / Float32(steps)
            var v = Float32(row) / Float32(steps)
            positions.append(Vec3f(u - 0.5, 0, v - 0.5))
            uvs.append(Vec2f(u * uv_scale, v * uv_scale))
            normals.append(Vec3f(0, 1, 0))

    for row in range(steps):
        for col in range(steps):
            var top_left = UInt32(row * (steps + 1) + col)
            var top_right = top_left + 1
            var bottom_left = top_left + UInt32(steps + 1)
            var bottom_right = bottom_left + 1
            indices += [top_left, bottom_left, bottom_right, top_left, bottom_right, top_right]

    return StandardMesh(positions^, uvs=uvs^, normals=normals^, indices=indices^)


def sphere_mesh(rings: Int = 24, segments: Int = 48) -> StandardMesh:
    """A unit-radius UV sphere; `rings` run pole to pole, `segments` around the equator."""
    var positions = List[Vec3f]()
    var uvs = List[Vec2f]()
    var normals = List[Vec3f]()
    var indices = List[UInt32]()

    for ring in range(rings + 1):
        var v = Float32(ring) / Float32(rings)
        var polar = v * Float32(pi)
        for segment in range(segments + 1):
            var u = Float32(segment) / Float32(segments)
            var azimuth = u * Float32(tau)
            var normal = Vec3f(
                sin(polar) * cos(azimuth),
                cos(polar),
                sin(polar) * sin(azimuth),
            )
            positions.append(normal)
            normals.append(normal)
            uvs.append(Vec2f(u, 1 - v))

    for ring in range(rings):
        for segment in range(segments):
            var current = UInt32(ring * (segments + 1) + segment)
            var next = current + UInt32(segments + 1)
            indices += [current, current + 1, next, current + 1, next + 1, next]

    return StandardMesh(positions^, uvs=uvs^, normals=normals^, indices=indices^)


def cube(var material: Optional[Material] = None) raises -> StandardModel:
    return StandardModel(cube_mesh(), material.value().copy() if material else unlit_material())


def plane(
    var material: Optional[Material] = None, subdivisions: Int = 1, uv_scale: Float32 = 1.0
) raises -> StandardModel:
    return StandardModel(
        plane_mesh(subdivisions, uv_scale), material.value().copy() if material else unlit_material()
    )


def sphere(
    var material: Optional[Material] = None, rings: Int = 24, segments: Int = 48
) raises -> StandardModel:
    return StandardModel(
        sphere_mesh(rings, segments), material.value().copy() if material else unlit_material()
    )
