import std.time as time


struct Clock(Copyable, Movable):
    """Per-frame timing: `delta` since the previous tick, `elapsed` since the first."""

    var start: Float64
    var last: Float64
    var delta: Float64

    def __init__(out self):
        self.start = Self.now()
        self.last = self.start
        self.delta = 0

    @staticmethod
    def now() -> Float64:
        return Float64(time.monotonic()) / 1e9

    def tick(mut self):
        var current = Self.now()
        self.delta = current - self.last
        self.last = current

    def elapsed(self) -> Float64:
        return self.last - self.start
