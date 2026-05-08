extends Control

@export var title_text: String = "Placeholder"
@export_file("*.tscn") var back_scene_path: String = "res://scenes/main/MainMenu.tscn"
@export var title_label_path: NodePath = NodePath("Background/Center/Card/Margin/VBox/TitleLabel")

@onready var _title_label: Label = get_node_or_null(title_label_path) as Label

func _ready() -> void:
    if _title_label == null:
        return
    if not title_text.is_empty():
        _title_label.text = title_text

func _on_back_pressed() -> void:
    var transitions := get_node_or_null("/root/SceneTransitions")
    if transitions != null:
        transitions.call("go_to", back_scene_path)
        return
    get_tree().change_scene_to_file(back_scene_path)
