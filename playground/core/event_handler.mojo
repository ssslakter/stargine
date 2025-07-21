from .imports import *
from sdl import Event, poll_event, get_window_position, set_window_position, Scancode, Rect, set_text_input_area
from sdl.sdl_events import *


@fieldwise_init
struct TextInputState:
    var cursor: Int32
    var text: String
    var text_input_active: Bool

    fn start_text_input(mut self) raises:
        self.text = ""
        self.cursor = 0
        var area = Rect(10, 10, 200, 30)
        # set_text_input_area(app_state.window._handle, Ptr(to=area), self.cursor)
        # sdl.start_text_input(app_state.window._handle)
        self.text_input_active = True
        print("Text input started. Press ENTER or ESC to stop.")

    fn stop_text_input(mut self) raises:
        # sdl.stop_text_input(app_state.window._handle)
        self.text_input_active = False
        print("Entered text: ", self.text)

    fn handle_text_input(mut self, event: TextInputEvent):
        if not self.text_input_active:
            return
        self.text += String(unsafe_from_utf8_ptr=event.text)
        self.cursor += len(self.text)


struct EventHandler:
    var dragging: Bool
    var drag_offset_x: Float32
    var drag_offset_y: Float32
    var text_input_state: TextInputState

    fn __init__(out self):
        self.dragging = False
        self.drag_offset_x = 0.0
        self.drag_offset_y = 0.0
        self.text_input_state = TextInputState(cursor=0, text="", text_input_active=False)
    
    fn handle_key_down(mut self, event: KeyboardEvent) raises -> Bool:
        if self.text_input_state.text_input_active:
            # if Int(event.scancode) == Int(Scancode.SCANCODE_RETURN) or Int(event.scancode) == Int(Scancode.SCANCODE_ESCAPE):
                # self.text_input_state.stop_text_input(app_state)
            if Int(event.scancode) == Int(Scancode.SCANCODE_BACKSPACE):
                if len(self.text_input_state.text) > 0:
                    self.text_input_state.text = self.text_input_state.text[:-1]
            return True

        alias move_dist = 1.0
        alias rot_angle = 5.0

        # if Int(event.scancode) == Int(Scancode.SCANCODE_W):
        #     app_state.camera.move(app_state.camera.get_forward() * move_dist)
        # elif Int(event.scancode) == Int(Scancode.SCANCODE_S):
        #     app_state.camera.move(app_state.camera.get_forward() * -move_dist)
        # elif Int(event.scancode) == Int(Scancode.SCANCODE_A):
        #     app_state.camera.move(app_state.camera.get_right() * move_dist)
        # elif Int(event.scancode) == Int(Scancode.SCANCODE_D):
        #     app_state.camera.move(app_state.camera.get_right() * -move_dist)
        # elif Int(event.scancode) == Int(Scancode.SCANCODE_SPACE):
        #     app_state.camera.move(Vec3f(0.0, 1.0, 0.0) * move_dist)
        # elif Int(event.scancode) == Int(Scancode.SCANCODE_LSHIFT):
        #     app_state.camera.move(Vec3f(0.0, -1.0, 0.0) * move_dist)
        # elif Int(event.scancode) == Int(Scancode.SCANCODE_UP):
        #     app_state.camera.rotate(0.0, rot_angle)
        # elif Int(event.scancode) == Int(Scancode.SCANCODE_DOWN):
        #     app_state.camera.rotate(0.0, -rot_angle)
        # elif Int(event.scancode) == Int(Scancode.SCANCODE_LEFT):
        #     app_state.camera.rotate(rot_angle, 0.0)
        # elif Int(event.scancode) == Int(Scancode.SCANCODE_RIGHT):
        #     app_state.camera.rotate(-rot_angle, 0.0)
        if Int(event.scancode) == Int(Scancode.SCANCODE_ESCAPE):
            return False
        # elif Int(event.scancode) == Int(Scancode.SCANCODE_R):
        #     app_state.cubes[0].material.value().shader.reload()
        # elif Int(event.scancode) == Int(Scancode.SCANCODE_F11):
        #     app_state.window.toggle_fullscreen()
        # elif Int(event.scancode) in [Int(Scancode.SCANCODE_T), Int(Scancode.SCANCODE_RETURN)]:
        #     self.text_input_state.start_text_input(app_state)
            
        return True

    fn handle_window_resized(mut self, event: WindowEvent):
        # app_state.window.width = event.data1
        # app_state.window.height = event.data2
        gl.viewport(0, 0, event.data1, event.data2)

    fn handle_mouse_button_down(mut self, event: MouseMotionEvent):
        self.dragging = True
        self.drag_offset_x = event.x
        self.drag_offset_y = event.y

    fn handle_mouse_button_up(mut self):
        self.dragging = False

    fn handle_mouse_motion(self, event: MouseMotionEvent) raises:
        if not self.dragging:
            return

        # var mouse_x = event.x
        # var mouse_y = event.y
        # var win_x, win_y = Int32(0), Int32(0)
        # get_window_position(app_state.window._handle, Ptr(to=win_x), Ptr(to=win_y))
        # set_window_position(
        #     app_state.window._handle,
        #     Int32(Float32(win_x) + (mouse_x - self.drag_offset_x)),
        #     Int32(Float32(win_y) + (mouse_y - self.drag_offset_y)),
        # )

    fn poll_events(mut self) raises -> Bool:
        var event = Event(UInt32(0))
        while poll_event(Ptr(to=event)):
            var event_type = event[CommonEvent].type

            if event_type == Int(EventType.EVENT_QUIT):
                return False

            if event_type == Int(EventType.EVENT_KEY_DOWN):
                if not self.handle_key_down(event[KeyboardEvent]):
                    return False

            if event_type == Int(EventType.EVENT_WINDOW_RESIZED):
                self.handle_window_resized(event[WindowEvent])

            if event_type == Int(EventType.EVENT_MOUSE_BUTTON_DOWN):
                self.handle_mouse_button_down(event[MouseMotionEvent])
            elif event_type == Int(EventType.EVENT_MOUSE_BUTTON_UP):
                self.handle_mouse_button_up()
            elif event_type == Int(EventType.EVENT_MOUSE_MOTION):
                self.handle_mouse_motion(event[MouseMotionEvent])

            if event_type == Int(EventType.EVENT_TEXT_INPUT):
                self.text_input_state.handle_text_input(event[TextInputEvent])

        return True
