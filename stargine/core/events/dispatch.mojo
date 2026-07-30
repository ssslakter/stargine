from .handlers import *


struct EventDispatcher:
    var handlers: List[DynEventHandler]

    def __init__(out self):
        self.handlers = []

    # def __init__[T: EventHandler](out self, var *handlers: T):
    #     self = Self()
    #     for h in handlers:
    #         self.append(h^)

    def append[T: EventHandler](mut self, var handler: T):
        self.handlers.append(DynEventHandler(ArcPointer(handler^)))

    def append[T: EventHandler](mut self, handler: ArcPointer[T]):
        self.handlers.append(DynEventHandler(handler))

    def poll_events(mut self) raises -> Bool:
        var event = Event(UInt32(0))
        should_continue = True
        while poll_event(Ptr(to=event)):
            for ref h in self.handlers:
                should_continue &= h.handle(event)
        return should_continue