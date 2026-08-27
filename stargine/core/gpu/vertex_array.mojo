import opengl as gl
from std.memory import ArcPointer
from .objects import VertexArrayName


struct VertexArray(Copyable, Movable):
    var name: ArcPointer[VertexArrayName]

    def __init__(out self) raises:
        self.name = ArcPointer(VertexArrayName())

    def bind(self) raises:
        gl.bind_vertex_array(self.name[].id)

    def unbind(self) raises:
        gl.bind_vertex_array(0)
