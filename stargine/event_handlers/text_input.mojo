import sdl
from sdl import CommonEvent, Event, KeyboardEvent, Rect, Scancode, TextInputEvent, c_string
from ..core.events import EventHandler
from ..core.utils import Ptr
from ..core.window import Window


struct TextInputHandler(EventHandler):
    var cursor: Int32
    var text: String
    var active: Bool
    var window: Window

    def __init__(out self, var window: Window):
        self.cursor = 0
        self.text = ""
        self.active = False
        self.window = window^

    def start(mut self) raises:
        self.text = ""
        self.cursor = 0
        var area = Rect(10, 10, 200, 30)
        sdl.set_text_input_area(self.window.handle(), Ptr(to=area), self.cursor)
        sdl.start_text_input(self.window.handle())
        self.active = True
        print("Text input started. Press ENTER or ESC to stop.")

    def stop(mut self) raises:
        sdl.stop_text_input(self.window.handle())
        self.active = False
        print("Entered text:", self.text)

    def handle(mut self, event: Event) raises -> Bool:
        var event_type = Int(event.unsafe_get[CommonEvent]().type)
        if event_type == Int(sdl.EventType.EVENT_TEXT_INPUT):
            self.append(event.unsafe_get[TextInputEvent]())
            return True
        if event_type != Int(sdl.EventType.EVENT_KEY_DOWN):
            return True

        var scancode = Int(event.unsafe_get[KeyboardEvent]().scancode)
        if not self.active:
            if scancode in [Int(Scancode.SCANCODE_T), Int(Scancode.SCANCODE_RETURN)]:
                self.start()
        elif scancode in [Int(Scancode.SCANCODE_RETURN), Int(Scancode.SCANCODE_ESCAPE)]:
            self.stop()
        elif scancode == Int(Scancode.SCANCODE_BACKSPACE):
            self.backspace()
        return True

    def append(mut self, event: TextInputEvent) raises:
        if not self.active:
            return
        self.text += c_string(event.text)
        self.cursor = Int32(self.text.byte_length())

    def backspace(mut self):
        var codepoints = [String(cp) for cp in self.text.codepoint_slices()]
        if not codepoints:
            return
        self.text = String("").join(codepoints[: len(codepoints) - 1])
        self.cursor = Int32(self.text.byte_length())
