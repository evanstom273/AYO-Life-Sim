extends Node

const HOVER_SCALE := 1.01
const PRESS_SCALE := 0.98

const HOVER_MODULATE := Color(1.04, 1.04, 1.04, 1)
const NORMAL_MODULATE := Color(1, 1, 1, 1)

var _tweens: Dictionary = {}

func _ready() -> void:
    get_tree().node_added.connect(_on_node_added)
    _scan(get_tree().root)

func _scan(node: Node) -> void:
    _try_hook_button(node)
    for child in node.get_children():
        _scan(child)

func _on_node_added(node: Node) -> void:
    _try_hook_button(node)

func _try_hook_button(node: Node) -> void:
    if not (node is BaseButton):
        return
    var b := node as BaseButton
    if b.has_meta("ui_anim_hooked"):
        return
    b.set_meta("ui_anim_hooked", true)
    b.set_meta("ui_hover", false)
    b.set_meta("ui_down", false)

    b.scale = Vector2.ONE
    b.self_modulate = NORMAL_MODULATE

    b.tree_exited.connect(func() -> void:
        _cleanup(b.get_instance_id())
    )

    if b is Control:
        _update_pivot(b)
        b.resized.connect(func() -> void: _update_pivot(b))

    b.mouse_entered.connect(func() -> void:
        if b.disabled:
            return
        b.set_meta("ui_hover", true)
        if not bool(b.get_meta("ui_down", false)):
            _anim_to(b, Vector2.ONE * HOVER_SCALE, HOVER_MODULATE, 0.08)
    )

    b.mouse_exited.connect(func() -> void:
        b.set_meta("ui_hover", false)
        if b.disabled:
            _anim_to(b, Vector2.ONE, NORMAL_MODULATE, 0.08)
            return
        if not bool(b.get_meta("ui_down", false)):
            _anim_to(b, Vector2.ONE, NORMAL_MODULATE, 0.10)
    )

    b.button_down.connect(func() -> void:
        if b.disabled:
            return
        b.set_meta("ui_down", true)
        _anim_to(b, Vector2.ONE * PRESS_SCALE, NORMAL_MODULATE, 0.06)
    )

    b.button_up.connect(func() -> void:
        b.set_meta("ui_down", false)
        if b.disabled:
            _anim_to(b, Vector2.ONE, NORMAL_MODULATE, 0.08)
            return
        if bool(b.get_meta("ui_hover", false)) or b.has_focus():
            _anim_to(b, Vector2.ONE * HOVER_SCALE, HOVER_MODULATE, 0.08)
        else:
            _anim_to(b, Vector2.ONE, NORMAL_MODULATE, 0.10)
    )

    b.focus_entered.connect(func() -> void:
        if b.disabled:
            return
        if not bool(b.get_meta("ui_down", false)):
            _anim_to(b, Vector2.ONE * HOVER_SCALE, HOVER_MODULATE, 0.10)
    )

    b.focus_exited.connect(func() -> void:
        if b.disabled:
            _anim_to(b, Vector2.ONE, NORMAL_MODULATE, 0.10)
            return
        if not bool(b.get_meta("ui_hover", false)) and not bool(b.get_meta("ui_down", false)):
            _anim_to(b, Vector2.ONE, NORMAL_MODULATE, 0.10)
    )

func _update_pivot(c: Control) -> void:
    c.pivot_offset = c.size * 0.5

func _anim_to(c: Control, target_scale: Vector2, target_modulate: Color, duration: float) -> void:
    var id := c.get_instance_id()
    var existing = _tweens.get(id)
    if existing != null and existing.has_method("kill"):
        existing.kill()

    var settings := get_node_or_null("/root/SettingsManager")
    if settings != null and settings.has_method("get_reduce_animations") and bool(settings.call("get_reduce_animations")):
        c.scale = target_scale
        c.self_modulate = target_modulate
        return

    var t := create_tween()
    t.set_parallel(true)
    t.set_trans(Tween.TRANS_QUAD)
    t.set_ease(Tween.EASE_OUT)
    t.tween_property(c, "scale", target_scale, duration)
    t.tween_property(c, "self_modulate", target_modulate, duration)
    _tweens[id] = t

func _cleanup(id: int) -> void:
    var existing = _tweens.get(id)
    if existing != null and existing.has_method("kill"):
        existing.kill()
    _tweens.erase(id)
