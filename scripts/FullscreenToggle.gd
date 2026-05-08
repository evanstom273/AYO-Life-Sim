extends Control

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
        var mode := DisplayServer.window_get_mode()
        if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        else:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
        get_viewport().set_input_as_handled()
