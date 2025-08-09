from ..core.imports import *
from ..core.utils import *
from ..core.window import *
from ..core.events import *
from sdl import Rect, Scancode


struct TextInputHandler(EventHandler):
    var cursor: Int32
    var text: String
    var text_input_active: Bool
    var window: Window

    fn start_text_input(mut self) raises:
        self.text = ""
        self.cursor = 0
        var area = Rect(10, 10, 200, 30)
        sdl.set_text_input_area(self.window._handle[], Ptr(to=area), self.cursor)
        sdl.start_text_input(self.window._handle[])
        self.text_input_active = True
        print("Text input started. Press ENTER or ESC to stop.")

    fn stop_text_input(mut self) raises:
        sdl.stop_text_input(self.window._handle[])
        self.text_input_active = False
        print("Entered text: ", self.text)

    fn handle_text_input(mut self, event: TextInputEvent):
        if not self.text_input_active:
            return
        self.text += String(unsafe_from_utf8_ptr=event.text)
        self.cursor += len(self.text)

    fn handle(mut self, event: Event) raises -> Bool:
        var key_event = event[KeyboardEvent]
        if self.text_input_active:
            if Int(key_event.scancode) == Int(Scancode.SCANCODE_RETURN) or Int(key_event.scancode) == Int(Scancode.SCANCODE_ESCAPE):
                self.stop_text_input()
            if Int(key_event.scancode) == Int(Scancode.SCANCODE_BACKSPACE) and len(self.text) > 0:
                self.text = self.text[:-1]
        elif Int(key_event.scancode) in [Int(Scancode.SCANCODE_T), Int(Scancode.SCANCODE_RETURN)]:
            self.start_text_input()
        if event[CommonEvent].type == Int(EventType.EVENT_TEXT_INPUT):
                self.handle_text_input(event[TextInputEvent])
        return True
