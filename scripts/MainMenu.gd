extends Control

@export_file("*.tscn") var continue_scene_path: String = "res://scenes/main/MainUI.tscn"
@export_file("*.tscn") var new_game_scene_path: String = "res://scenes/main/NewGame.tscn"
@export_file("*.tscn") var load_game_scene_path: String = "res://scenes/main/LoadGame.tscn"
@export_file("*.tscn") var settings_scene_path: String = "res://scenes/main/Settings.tscn"

func _on_continue_pressed() -> void:
    _go_to(continue_scene_path)

func _on_new_game_pressed() -> void:
    _go_to(new_game_scene_path)

func _on_load_game_pressed() -> void:
    _go_to(load_game_scene_path)

func _on_settings_pressed() -> void:
    _go_to(settings_scene_path)

func _on_quit_pressed() -> void:
    get_tree().quit()

func _go_to(scene_path: String) -> void:
    if scene_path.is_empty():
        return
    var transitions := get_node_or_null("/root/SceneTransitions")
    if transitions != null:
        transitions.call("go_to", scene_path)
        return
    get_tree().change_scene_to_file(scene_path)
