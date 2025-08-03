from ...imports import *
from sdl import Event, poll_event


trait EventHandler(Movable):
    fn handle(mut self, event: Event) raises -> Bool: ...
    # fn disable(mut self): ...
    # fn enable(mut self): ...


fn handle_event[T: EventHandler](ptr: ArcPointer[NoneType], event: Event) raises -> Bool:
    var data = rebind[ArcPointer[T]](ptr)
    return data[].handle(event)

# fn enable_handler[T: EventHandler](ptr: ArcPointer[NoneType]):
#     var data = rebind[ArcPointer[T]](ptr)
#     data[].enable()

# fn disable_handler[T: EventHandler](ptr: ArcPointer[NoneType]):
#     var data = rebind[ArcPointer[T]](ptr)
#     data[].disable()

struct DynEventHandler(EventHandler, Copyable):
    var data: ArcPointer[NoneType]
    var handle_func: fn(ArcPointer[NoneType], Event) raises -> Bool
    # var enable_func: fn(ArcPointer[NoneType])
    # var disable_func: fn(ArcPointer[NoneType])

    fn __init__[T: EventHandler](out self, var ptr: ArcPointer[T]):
        self.data = rebind[ArcPointer[NoneType]](ptr^)
        self.handle_func = handle_event[T]
        # self.enable_func = enable_handler[T]
        # self.disable_func = disable_handler[T]

    fn handle(mut self, event: Event) raises -> Bool:
        return self.handle_func(self.data, event)

    # fn enable(mut self):
    #     self.enable_func(self.data)
    
    # fn disable(mut self):
    #     self.disable_func(self.data)