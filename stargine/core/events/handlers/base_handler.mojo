from ...imports import *
from sdl import Event, poll_event


trait EventHandler(Movable, ImplicitlyDeletable):
    def handle(mut self, event: Event) raises -> Bool: ...
    # def disable(mut self): ...
    # def enable(mut self): ...


def handle_event[T: EventHandler](ptr: ArcPointer[NoneType], event: Event) raises -> Bool:
    var data = rebind[ArcPointer[T]](ptr)
    return data[].handle(event)

# def enable_handler[T: EventHandler](ptr: ArcPointer[NoneType]):
#     var data = rebind[ArcPointer[T]](ptr)
#     data[].enable()

# def disable_handler[T: EventHandler](ptr: ArcPointer[NoneType]):
#     var data = rebind[ArcPointer[T]](ptr)
#     data[].disable()

struct DynEventHandler(EventHandler, Copyable):
    var data: ArcPointer[NoneType]
    var handle_func: def(ArcPointer[NoneType], Event) raises -> Bool
    # var enable_func: def(ArcPointer[NoneType])
    # var disable_func: def(ArcPointer[NoneType])

    def __init__[T: EventHandler](out self, var ptr: ArcPointer[T]):
        self.data = rebind[ArcPointer[NoneType]](ptr^)
        self.handle_func = handle_event[T]
        # self.enable_func = enable_handler[T]
        # self.disable_func = disable_handler[T]

    def handle(mut self, event: Event) raises -> Bool:
        return self.handle_func(self.data, event)

    # def enable(mut self):
    #     self.enable_func(self.data)
    
    # def disable(mut self):
    #     self.disable_func(self.data)
