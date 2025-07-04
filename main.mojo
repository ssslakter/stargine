from sdl import InitFlags, WindowFlags, Event
from sdl.sdl_events import *
import opengl as gl
from playground import *



def main_loop(mut state: AppState):
    var running = True
    var dragging = False
    var drag_offset_x: Float32 = 0.0
    var drag_offset_y: Float32 = 0.0

    while running:
        var event = Event(UInt32(0))
        while sdl.poll_event(Ptr(to=event)):
            if event[CommonEvent].type == Int(EventType.EVENT_QUIT):
                running = False
                break 
            if event[CommonEvent].type == Int(EventType.EVENT_KEY_DOWN):
                key_event = event[KeyboardEvent]
                if Int(key_event.scancode) == Int(sdl.Scancode.SCANCODE_ESCAPE):
                    running = False
                    break
                if Int(key_event.scancode) == Int(sdl.Scancode.SCANCODE_R): pass
                    # state.shader.reload()
            if event[CommonEvent].type == Int(EventType.EVENT_WINDOW_RESIZED):
                window_event = event[WindowEvent]
                new_width = window_event.data1
                new_height = window_event.data2
                gl.viewport(0, 0, new_width, new_height)
            if event[CommonEvent].type == Int(EventType.EVENT_MOUSE_BUTTON_DOWN):
                mouse_event = event[MouseMotionEvent]
                dragging = True
                drag_offset_x = mouse_event.x
                drag_offset_y = mouse_event.y
            elif event[CommonEvent].type == Int(EventType.EVENT_MOUSE_BUTTON_UP):
                dragging = False
            elif event[CommonEvent].type == Int(EventType.EVENT_MOUSE_MOTION) and dragging:
                mouse_event = event[MouseMotionEvent]
                mouse_x = mouse_event.x
                mouse_y = mouse_event.y
                # Get current window position
                win_x, win_y = Int32(0), Int32(0)
                sdl.get_window_position(state.window._handle, Ptr(to=win_x), Ptr(to=win_y))
                # Set new position
                sdl.set_window_position(state.window._handle, Int32(Float32(win_x) + Float32(mouse_x - drag_offset_x)), Int32(Float32(win_y) + Float32(mouse_y - drag_offset_y)))
        if not running:
            break
        update(state)


def main():
    sdl.init(InitFlags.INIT_VIDEO | InitFlags.INIT_EVENTS)

    sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_PROFILE_MASK, Int(sdl.GLProfile.GL_CONTEXT_PROFILE_CORE))
    sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_MAJOR_VERSION, 4)
    sdl.gl_set_attribute(sdl.GLAttr.GL_CONTEXT_MINOR_VERSION, 2)
    sdl.gl_set_attribute(sdl.GLAttr.GL_DOUBLEBUFFER, 1)

    window = Window(
        "SDL Window",
        win_width,
        win_height,
        WindowFlags.WINDOW_RESIZABLE | WindowFlags.WINDOW_OPENGL,
    )
    context = sdl.gl_create_context(window._handle)
    if not context:
        raise Error("Failed to create OpenGL context. Unsupported OpenGL version.")

    sdl.gl_make_current(window._handle, context)
    gl.init_opengl(sdl.gl_get_proc_address)
    state = AppState(window^, context)

    app_init(state)
    main_loop(state)

    sdl.quit()
