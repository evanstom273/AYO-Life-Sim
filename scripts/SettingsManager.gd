extends Node

signal setting_changed(section: String, key: String, value: Variant)

const CONFIG_PATH: String = "user://settings.cfg"

const FONT_INTER_PATH: String = "res://assets/fonts/Inter.ttf"
const FONT_DYSLEXIA_PATH: String = "res://assets/fonts/OpenDyslexic-Regular.ttf"

const BUS_MASTER: String = "Master"
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"

const _CB_META_KEY := &"cb_color_state"
const _CB_COLOR_KEYS: Array[StringName] = [
    &"font_color",
    &"font_hover_color",
    &"font_pressed_color",
    &"font_disabled_color",
    &"font_hover_pressed_color",
]

var _config := ConfigFile.new()
var _inter_font: FontFile
var _dyslexia_font: FontFile

func _ready() -> void:
    load_settings()
    apply_all()

func reset_to_defaults() -> void:
    _write_defaults()
    _config.save(CONFIG_PATH)
    apply_all()

func load_settings() -> void:
    _config = ConfigFile.new()
    var err := _config.load(CONFIG_PATH)
    if err != OK:
        _write_defaults()
        _config.save(CONFIG_PATH)
        return
    _ensure_default_keys()

func save_settings() -> void:
    _config.save(CONFIG_PATH)

func get_value(section: String, key: String, default_value: Variant) -> Variant:
    return _config.get_value(section, key, default_value)

func set_value(section: String, key: String, value: Variant) -> void:
    var v: Variant = value
    if section == "display" and key == "ui_scale":
        var bounds := _get_ui_scale_bounds()
        v = clampf(float(v), bounds.x, bounds.y)
    elif section == "display" and key == "fullscreen":
        v = bool(v)
    elif section == "audio" and (key == "master" or key == "music" or key == "sfx"):
        v = clampi(int(v), 0, 100)
    elif section == "audio" and key == "ui_sounds":
        v = bool(v)
    elif section == "gameplay" and key == "energy_drain_speed":
        v = clampf(float(v), 0.1, 1.0)
    elif section == "accessibility" and (key == "dyslexia_font" or key == "reduce_animations" or key == "colourblind_mode"):
        v = bool(v)
    elif section == "help" and key == "tooltip_hints":
        v = bool(v)

    _config.set_value(section, key, v)
    _config.save(CONFIG_PATH)
    _apply_setting(section, key, v)
    setting_changed.emit(section, key, v)

func apply_all() -> void:
    _apply_display()
    _apply_audio()
    _apply_accessibility()

func get_reduce_animations() -> bool:
    return bool(get_value("accessibility", "reduce_animations", false))

func reset_tutorial_hints() -> void:
    var path := "user://tutorial_hints.cfg"
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(path)

func _write_defaults() -> void:
    _config.set_value("display", "fullscreen", false)
    _config.set_value("display", "resolution", "1280x720")
    _config.set_value("display", "ui_scale", 1.0)

    _config.set_value("audio", "master", 100)
    _config.set_value("audio", "music", 80)
    _config.set_value("audio", "sfx", 80)
    _config.set_value("audio", "ui_sounds", true)

    _config.set_value("gameplay", "energy_drain_speed", 0.40)

    _config.set_value("accessibility", "font_size", "medium")
    _config.set_value("accessibility", "dyslexia_font", false)
    _config.set_value("accessibility", "reduce_animations", false)
    _config.set_value("accessibility", "colourblind_mode", false)

    _config.set_value("help", "tooltip_hints", true)

func _ensure_default_keys() -> void:
    var changed := false
    changed = _ensure_key("display", "fullscreen", false) or changed
    changed = _ensure_key("display", "resolution", "1280x720") or changed
    changed = _ensure_key("display", "ui_scale", 1.0) or changed

    changed = _ensure_key("audio", "master", 100) or changed
    changed = _ensure_key("audio", "music", 80) or changed
    changed = _ensure_key("audio", "sfx", 80) or changed
    changed = _ensure_key("audio", "ui_sounds", true) or changed

    changed = _ensure_key("gameplay", "energy_drain_speed", 0.40) or changed

    changed = _ensure_key("accessibility", "font_size", "medium") or changed
    changed = _ensure_key("accessibility", "dyslexia_font", false) or changed
    changed = _ensure_key("accessibility", "reduce_animations", false) or changed
    changed = _ensure_key("accessibility", "colourblind_mode", false) or changed

    changed = _ensure_key("help", "tooltip_hints", true) or changed

    if changed:
        _config.save(CONFIG_PATH)

func _ensure_key(section: String, key: String, default_value: Variant) -> bool:
    if _config.has_section_key(section, key):
        return false
    _config.set_value(section, key, default_value)
    return true

func _apply_setting(section: String, key: String, value: Variant) -> void:
    if section == "display":
        _apply_display()
        return
    if section == "audio":
        _apply_audio()
        return
    if section == "accessibility":
        _apply_accessibility()
        return

func _apply_display() -> void:
    var fullscreen := bool(get_value("display", "fullscreen", false))
    if fullscreen:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        var res := _parse_resolution(str(get_value("display", "resolution", "1280x720")))
        if res.x > 0 and res.y > 0:
            DisplayServer.window_set_size(res)

    var ui_scale := float(get_value("display", "ui_scale", 1.0))
    var bounds := _get_ui_scale_bounds()
    ui_scale = clampf(ui_scale, bounds.x, bounds.y)

    var viewport_w := float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920))
    var viewport_h := float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
    var window_size := _get_window_size()
    var base_scale := 1.0
    if viewport_w > 0.0 and viewport_h > 0.0 and window_size[0] > 0.0 and window_size[1] > 0.0:
        base_scale = max(window_size[0] / viewport_w, window_size[1] / viewport_h)
    if base_scale <= 0.0:
        base_scale = 1.0

    var target_content_scale := clampf(ui_scale / base_scale, 0.1, 10.0)
    var win := get_tree().root.get_window()
    if win != null:
        win.content_scale_factor = target_content_scale
    if absf(ui_scale - float(get_value("display", "ui_scale", 1.0))) > 0.0001:
        _config.set_value("display", "ui_scale", ui_scale)
        _config.save(CONFIG_PATH)

func _apply_audio() -> void:
    _set_bus_volume_percent(BUS_MASTER, int(get_value("audio", "master", 100)))
    _set_bus_volume_percent(BUS_MUSIC, int(get_value("audio", "music", 80)))
    _set_bus_volume_percent(BUS_SFX, int(get_value("audio", "sfx", 80)))

func _apply_accessibility() -> void:
    var size_key := str(get_value("accessibility", "font_size", "medium"))
    var font_size := 16
    var scale := 1.0
    match size_key:
        "small":
            font_size = 14
            scale = 0.9
        "large":
            font_size = 18
            scale = 1.15
        _:
            font_size = 16
            scale = 1.0
    ProjectSettings.set_setting("gui/theme/default_font_size", font_size)
    ThemeDB.fallback_font_size = font_size

    var dyslexia := bool(get_value("accessibility", "dyslexia_font", false))
    var font: FontFile
    if dyslexia:
        ProjectSettings.set_setting("gui/theme/default_font", FONT_DYSLEXIA_PATH)
        font = _get_dyslexia_font()
    else:
        ProjectSettings.set_setting("gui/theme/default_font", FONT_INTER_PATH)
        font = _get_inter_font()
    ThemeDB.fallback_font = font
    _apply_font_to_ui(font)

    _apply_font_scale_to_ui(scale)

    var colorblind := bool(get_value("accessibility", "colourblind_mode", false))
    _apply_colorblind_mode(colorblind)
    _refresh_theme()

func _refresh_theme() -> void:
    var root := get_tree().root
    if root == null:
        return
    root.propagate_notification(Control.NOTIFICATION_THEME_CHANGED)

func _apply_font_to_ui(font: FontFile) -> void:
    var scene_root := _get_ui_root()
    if scene_root == null:
        return
    _apply_font_to_node(scene_root, font)

func _apply_font_to_node(node: Node, font: FontFile) -> void:
    if node is Control:
        var c := node as Control
        c.add_theme_font_override(&"font", font)
    for child in node.get_children():
        _apply_font_to_node(child, font)

func _apply_font_scale_to_ui(scale: float) -> void:
    var scene_root := _get_ui_root()
    if scene_root == null:
        return
    _apply_font_scale_to_node(scene_root, scale)

func _apply_font_scale_to_node(node: Node, scale: float) -> void:
    if node is Control:
        var c := node as Control
        var base_key := &"base_font_size"
        var base := 0
        if c.has_meta(base_key):
            base = int(c.get_meta(base_key))
        else:
            base = int(c.get_theme_font_size(&"font_size"))
            c.set_meta(base_key, base)
        c.add_theme_font_size_override(&"font_size", int(round(float(base) * scale)))

    for child in node.get_children():
        _apply_font_scale_to_node(child, scale)

func _apply_colorblind_mode(enabled: bool) -> void:
    var scene_root := _get_ui_root()
    if scene_root == null:
        return
    _apply_colorblind_to_node(scene_root, enabled)

func _get_ui_root() -> Node:
    var scene := get_tree().current_scene
    if scene != null:
        return scene
    return get_node_or_null("/root/Control")

func _get_ui_scale_bounds() -> Vector2:
    var min_scale: float = 0.5
    var max_scale: float = 2.0

    var viewport_w := float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920))
    var viewport_h := float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080))

    var win := get_tree().root.get_window()
    var size := Vector2.ZERO
    if win != null:
        size = Vector2(win.size)

    var bounds := Vector2(min_scale, max_scale)
    return bounds

func _get_window_size() -> Array[float]:
    var s: Vector2i = DisplayServer.window_get_size()
    return [float(s.x), float(s.y)]

func _get_viewport_size() -> Array[float]:
    var viewport_w := float(ProjectSettings.get_setting("display/window/size/viewport_width", 0))
    var viewport_h := float(ProjectSettings.get_setting("display/window/size/viewport_height", 0))
    return [viewport_w, viewport_h]

func _apply_colorblind_to_node(node: Node, enabled: bool) -> void:
    if node is Control:
        var c := node as Control
        if enabled:
            _apply_colorblind_to_control(c)
        else:
            _restore_colorblind_control(c)

    for child in node.get_children():
        _apply_colorblind_to_node(child, enabled)

func _apply_colorblind_to_control(c: Control) -> void:
    var state: Dictionary = {}
    if c.has_meta(_CB_META_KEY):
        state = c.get_meta(_CB_META_KEY) as Dictionary

    for key in _CB_COLOR_KEYS:
        if state.has(key):
            continue
        var entry: Dictionary = {}
        entry["had"] = c.has_theme_color_override(key)
        entry["color"] = c.get_theme_color(key)
        state[key] = entry

        var mapped := _map_color(entry["color"])
        if mapped != entry["color"]:
            c.add_theme_color_override(key, mapped)

    if state.size() > 0:
        c.set_meta(_CB_META_KEY, state)

func _restore_colorblind_control(c: Control) -> void:
    if not c.has_meta(_CB_META_KEY):
        return
    var state: Dictionary = c.get_meta(_CB_META_KEY) as Dictionary
    for key in state.keys():
        var entry: Dictionary = state[key]
        var had := bool(entry.get("had", false))
        if had:
            c.add_theme_color_override(key, entry.get("color"))
        else:
            c.remove_theme_color_override(key)
    c.remove_meta(_CB_META_KEY)

func _map_color(c: Color) -> Color:
    var blue := Color(0.23137255, 0.50980395, 0.9647059, 1)
    var green := Color(0.20784314, 0.76862746, 0.41568628, 1)
    var red := Color(0.9372549, 0.26666668, 0.26666668, 1)
    var purple := Color(0.7411765, 0.41960785, 0.9607843, 1)
    var orange := Color(0.9647059, 0.54509807, 0.14117648, 1)

    var cb_blue := Color(0.0, 0.447, 0.698, c.a)
    var cb_green := Color(0.0, 0.62, 0.451, c.a)
    var cb_red := Color(0.835, 0.369, 0.0, c.a)
    var cb_purple := Color(0.8, 0.475, 0.655, c.a)
    var cb_orange := Color(0.902, 0.624, 0.0, c.a)

    if _color_close(c, blue):
        return cb_blue
    if _color_close(c, green):
        return cb_green
    if _color_close(c, red):
        return cb_red
    if _color_close(c, purple):
        return cb_purple
    if _color_close(c, orange):
        return cb_orange
    return c

func _color_close(a: Color, b: Color, eps: float = 0.06) -> bool:
    return absf(a.r - b.r) <= eps and absf(a.g - b.g) <= eps and absf(a.b - b.b) <= eps

func _get_inter_font() -> FontFile:
    if _inter_font == null:
        _inter_font = load(FONT_INTER_PATH) as FontFile
    return _inter_font

func _get_dyslexia_font() -> FontFile:
    if _dyslexia_font == null:
        _dyslexia_font = load(FONT_DYSLEXIA_PATH) as FontFile
    return _dyslexia_font

func _parse_resolution(s: String) -> Vector2i:
    var parts := s.split("x", false)
    if parts.size() != 2:
        return Vector2i.ZERO
    return Vector2i(int(parts[0]), int(parts[1]))

func _set_bus_volume_percent(bus_name: String, percent: int) -> void:
    var idx := AudioServer.get_bus_index(bus_name)
    if idx < 0:
        return
    var p := clampi(percent, 0, 100)
    var db := -80.0
    if p > 0:
        db = linear_to_db(float(p) / 100.0)
    AudioServer.set_bus_volume_db(idx, db)
