extends Node

var _is_transitioning := false
var _layer: CanvasLayer
var _overlay: ColorRect

func _ready() -> void:
    _layer = CanvasLayer.new()
    _layer.layer = 1000
    add_child(_layer)

    _overlay = ColorRect.new()
    _overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _overlay.color = Color(0, 0, 0, 0)
    _overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    _layer.add_child(_overlay)

func go_to(scene_path: String) -> void:
    if _is_transitioning:
        return
    if scene_path.is_empty():
        return
    call_deferred("_transition", scene_path)

func _transition(scene_path: String) -> void:
    _is_transitioning = true

    _overlay.color = Color(0, 0, 0, 0)
    var fade_out := create_tween()
    fade_out.set_trans(Tween.TRANS_QUAD)
    fade_out.set_ease(Tween.EASE_OUT)
    fade_out.tween_property(_overlay, "color", Color(0, 0, 0, 1), 0.25)
    await fade_out.finished

    get_tree().change_scene_to_file(scene_path)
    await get_tree().process_frame

    var scene := get_tree().current_scene
    if scene is Control:
        var c := scene as Control
        await get_tree().process_frame
        c.pivot_offset = c.size * 0.5
        c.scale = Vector2(0.98, 0.98)
        var zoom_tween := create_tween()
        zoom_tween.set_trans(Tween.TRANS_QUAD)
        zoom_tween.set_ease(Tween.EASE_OUT)
        zoom_tween.tween_property(c, "scale", Vector2.ONE, 0.25)

    var fade_in := create_tween()
    fade_in.set_trans(Tween.TRANS_QUAD)
    fade_in.set_ease(Tween.EASE_OUT)
    fade_in.tween_property(_overlay, "color", Color(0, 0, 0, 0), 0.25)

    await fade_in.finished
    _is_transitioning = false
