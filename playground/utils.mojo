from memory import UnsafePointer

alias Ptr = UnsafePointer
alias Id = UInt32

# @register_passable('trivial')
# struct Vec[N: Int, T: Copyable & Movable](Copyable, Movable):
#     var data: InlineArray[T, N]

#     fn __init__(out self, *elements: T):
#         for i in range(N):
#             self.data[i] = elements[i]

#     fn __getitem__(self, i: Int) -> T:
#         return self.data[i]

alias Vec2 = Tuple[Float32, Float32]
alias Vec3 = Tuple[Float32, Float32, Float32]
alias Vec4 = Tuple[Float32, Float32, Float32, Float32]


