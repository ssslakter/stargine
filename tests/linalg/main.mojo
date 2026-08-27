"""Unit tests for the vector and matrix types. Needs no display."""

from std.math import isclose, pi, sqrt
from std.testing import TestSuite, assert_almost_equal, assert_equal, assert_true
from stargine.core.linalg import (
    Mat2f,
    Mat3f,
    Mat4f,
    Vec2f,
    Vec3f,
    Vec4f,
    look_at,
    perspective,
    rotate,
    scale,
    translate,
)
from stargine.scene.camera import Camera
from stargine.scene.transform import Transform, radians


def assert_vec_equal[N: Int](got: Vec3f, expected: Vec3f) raises:
    for i in range(3):
        assert_almost_equal(got[i], expected[i], atol=1e-5)


def test_broadcast_leaves_padding_zero() raises:
    # Vec3f is stored in a 4-lane register; a dirty padding lane corrupts dot().
    assert_almost_equal(Vec3f(1.0).dot(Vec3f(1.0)), 3.0)
    assert_almost_equal(Vec3f(1.0).length(), sqrt(Float32(3)))
    assert_almost_equal(Vec3f(0.2).length(), 0.2 * sqrt(Float32(3)), atol=1e-6)
    assert_almost_equal(Vec3f(2.0).data[3], 0.0)


def test_component_constructors() raises:
    var v = Vec3f(1, 2, 3)
    assert_almost_equal(v.x(), 1.0)
    assert_almost_equal(v.y(), 2.0)
    assert_almost_equal(v.z(), 3.0)
    assert_almost_equal(v.data[3], 0.0)

    var w = Vec4f(v, 4.0)
    assert_almost_equal(w.w(), 4.0)
    assert_almost_equal(w.x(), 1.0)

    var partial = Vec3f(1, 2)
    assert_almost_equal(partial.z(), 0.0)


def test_vector_algebra() raises:
    var a = Vec3f(1, 2, 3)
    var b = Vec3f(4, 5, 6)
    assert_almost_equal(a.dot(b), 32.0)
    assert_vec_equal[3](a.cross(b), Vec3f(-3, 6, -3))
    assert_vec_equal[3]((a + b), Vec3f(5, 7, 9))
    assert_vec_equal[3]((b - a), Vec3f(3, 3, 3))
    assert_almost_equal(Vec3f(3, 4, 0).length(), 5.0)
    assert_almost_equal(Vec3f(3, 4, 0).normalize().length(), 1.0)


def test_identity_and_diagonal() raises:
    var identity = Mat4f.id()
    for i in range(4):
        for j in range(4):
            assert_almost_equal(identity[i, j], Float32(1.0) if i == j else Float32(0.0))

    var d = Mat4f.diag(Vec4f(1, 2, 3, 4))
    assert_almost_equal(d[2, 2], 3.0)
    assert_almost_equal(d[2, 1], 0.0)


def test_matmul_matches_hand_computed() raises:
    var a = Mat3f([Vec3f(1, 2, 3), Vec3f(4, 5, 6), Vec3f(7, 8, 9)])
    var b = Mat3f([Vec3f(9, 8, 7), Vec3f(6, 5, 4), Vec3f(3, 2, 1)])
    var c = a.matmul(b)
    assert_almost_equal(c[0, 0], 30.0)
    assert_almost_equal(c[0, 2], 18.0)
    assert_almost_equal(c[1, 1], 69.0)
    assert_almost_equal(c[2, 2], 90.0)

    var identity = Mat3f.id()
    var same = a.matmul(identity)
    for i in range(3):
        for j in range(3):
            assert_almost_equal(same[i, j], a[i, j])


def test_matvec_and_transpose() raises:
    var m = Mat3f([Vec3f(1, 2, 3), Vec3f(4, 5, 6), Vec3f(7, 8, 9)])
    assert_vec_equal[3](m.matmul(Vec3f(1, 0, 0)), Vec3f(1, 4, 7))
    assert_vec_equal[3](m.matmul(Vec3f(1, 1, 1)), Vec3f(6, 15, 24))

    var t = m.transpose()
    for i in range(3):
        for j in range(3):
            assert_almost_equal(t[j, i], m[i, j])


def test_inverse_2x2() raises:
    var m = Mat2f([Vec2f(4, 7), Vec2f(2, 6)])
    var inv = m.inverse()
    assert_almost_equal(inv[0, 0], 0.6)
    assert_almost_equal(inv[0, 1], -0.7)
    assert_almost_equal(inv[1, 0], -0.2)
    assert_almost_equal(inv[1, 1], 0.4)


def test_inverse_round_trips() raises:
    var m = Mat3f([Vec3f(2, 0, 1), Vec3f(1, 3, 2), Vec3f(1, 1, 4)])
    var product = m.matmul(m.inverse())
    for i in range(3):
        for j in range(3):
            assert_almost_equal(product[i, j], Float32(1.0) if i == j else Float32(0.0), atol=1e-5)

    var diagonal = Mat3f.diag(Vec3f(2, 4, 5)).inverse()
    assert_almost_equal(diagonal[0, 0], 0.5)
    assert_almost_equal(diagonal[1, 1], 0.25)
    assert_almost_equal(diagonal[2, 2], 0.2)

    var m4 = Mat4f([Vec4f(2, 0, 1, 3), Vec4f(1, 3, 2, 0), Vec4f(1, 1, 1, 2), Vec4f(0, 1, 4, 1)])
    var product4 = m4.matmul(m4.inverse())
    for i in range(4):
        for j in range(4):
            assert_almost_equal(product4[i, j], Float32(1.0) if i == j else Float32(0.0), atol=1e-4)


def test_transform_helpers() raises:
    var moved = translate(Vec3f(1, 2, 3)).matmul(Vec4f(0, 0, 0, 1))
    assert_almost_equal(moved[0], 1.0)
    assert_almost_equal(moved[1], 2.0)
    assert_almost_equal(moved[2], 3.0)

    var scaled = scale(Vec3f(2, 3, 4)).matmul(Vec4f(1, 1, 1, 1))
    assert_almost_equal(scaled[0], 2.0)
    assert_almost_equal(scaled[2], 4.0)

    # A quarter turn about Z maps +X onto +Y.
    var turned = rotate(Float32(pi / 2), Vec3f(0, 0, 1)).matmul(Vec4f(1, 0, 0, 1))
    assert_almost_equal(turned[0], 0.0, atol=1e-6)
    assert_almost_equal(turned[1], 1.0, atol=1e-6)


def test_local_to_world() raises:
    var t = Transform(position=Vec3f(1, 0, 0), scale=Vec3f(2))
    assert_vec_equal[3](t.transform_vector(Vec3f(1, 1, 1)), Vec3f(3, 2, 2))

    t.rotate(yaw_delta=radians(90))
    assert_vec_equal[3](t.transform_vector(Vec3f(1, 0, 0)), Vec3f(1, 0, -2))


def test_camera_right_matches_view() raises:
    var camera = Camera(position=Vec3f(0, 0, 0))
    # Default yaw and pitch look down +X, so the camera's right is +Z.
    assert_vec_equal[3](camera.get_forward(), Vec3f(1, 0, 0))
    assert_vec_equal[3](camera.get_right(), Vec3f(0, 0, 1))


def test_camera_look_at() raises:
    var camera = Camera(position=Vec3f(0, 0, 5))
    camera.look_at(Vec3f(0, 0, 0))
    assert_vec_equal[3](camera.get_forward(), Vec3f(0, 0, -1))

    camera.look_at(Vec3f(0, 5, 5))
    assert_vec_equal[3](camera.get_forward(), Vec3f(0, 1, 0))


def test_look_at_and_perspective() raises:
    var view = look_at(Vec3f(0, 0, 5), Vec3f(0, 0, 0), Vec3f(0, 1, 0))
    var origin_in_view = view.matmul(Vec4f(0, 0, 0, 1))
    assert_almost_equal(origin_in_view[0], 0.0, atol=1e-6)
    assert_almost_equal(origin_in_view[1], 0.0, atol=1e-6)
    assert_almost_equal(origin_in_view[2], -5.0, atol=1e-6)

    # A mirrored basis would flip triangle winding and cull every visible face.
    var right_of_camera = view.matmul(Vec4f(1, 0, 0, 1))
    assert_almost_equal(right_of_camera[0], 1.0, atol=1e-6)
    var above_camera = view.matmul(Vec4f(0, 1, 0, 1))
    assert_almost_equal(above_camera[1], 1.0, atol=1e-6)

    var proj = perspective(Float32(radians(90)), Float32(1.0), Float32(1.0), Float32(100.0))
    var near_point = proj.matmul(Vec4f(0, 0, -1, 1))
    assert_almost_equal(near_point[2] / near_point[3], -1.0, atol=1e-4)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
