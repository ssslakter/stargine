from .handlers import *


struct EventDispatcher:
    var handlers: List[DynEventHandler]

    fn __init__(out self):
        self.handlers = []

    fn __init__[T: EventHandler](out self, *handlers: T):
        self = Self()
        for h in handlers:
            self.append(h)

    fn append[T: EventHandler](mut self, handler: T):
        self.handlers.append(DynEventHandler(ArcPointer(handler)))

    fn poll_events(mut self) raises -> Bool:
        var event = Event(UInt32(0))
        should_continue = True
        while poll_event(Ptr(to=event)):
            for ref h in self.handlers:
                should_continue &= h.handle(event)
        return should_continue