from sdl import Event


trait EventHandler(Movable):
    def handle(mut self, event: Event) raises -> Bool:
        """Handles one event and returns False to stop the application."""
        ...
