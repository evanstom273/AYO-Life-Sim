extends Node

const CONFIG_PATH: String = "res://resources/theme/theme_config.tres"

const STYLEBOX_CARD_DARK_PATH: String = "res://resources/ui/styleboxes/card_dark.tres"
const STYLEBOX_PANEL_DARK_PATH: String = "res://resources/ui/styleboxes/panel_dark.tres"

const CARD_BG_LIGHT_PATH: String = "res://assets/ui/card_bg_light.svg"
const PANEL_BG_LIGHT_PATH: String = "res://assets/ui/panel_bg_light.svg"

const BUTTON_STYLE_NAMES := [
    "normal",
    "hover",
    "pressed",
    "disabled",
	"focus"
]

const BUTTON_COLOR_NAMES := [
    "font_color",
    "font_hover_color",
    "font_pressed_color",
    "font_focus_color",
    "font_hover_pressed_color",
    "font_disabled_color",
    "icon_normal_color",
    "icon_hover_color",
    "icon_pressed_color",
    "icon_hover_pressed_color",
    "icon_focus_color",
	"icon_disabled_color"
]

const CHECKBOX_ICON_NAMES := [
    "checked",
    "unchecked",
    "checked_disabled",
	"unchecked_disabled"
]

var active := false
var dark_enabled := false

var _saved: Dictionary = {}
var _excluded_roots: Array[Node] = []

var _config: ThemeConfig
var _palette: ThemePalette

var _checkbox_checked: Texture2D
var _checkbox_unchecked: Texture2D

var _sb_card_dark: StyleBox
var _sb_panel_dark: StyleBox


func _ready() -> void:
    _config = load(CONFIG_PATH) as ThemeConfig
    if _config != null:
        _palette = _config.light
    if _palette == null:
        _palette = ThemePalette.new()

    _excluded_roots.clear()
    _excluded_roots.append(self)
    _add_excluded_root("/root/SceneTransitions")
    _add_excluded_root("/root/UIAnimator")
    _add_excluded_root("/root/GlobalShortcuts")

    get_tree().node_added.connect(_on_node_added)


func _add_excluded_root(path: String) -> void:
    var node: Node = get_node_or_null(path)

    if node != null:
        _excluded_roots.append(node)


func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey):
        return

    var e := event as InputEventKey

    if not e.pressed or e.echo:
        return

    if e.keycode == KEY_D and e.ctrl_pressed:
        toggle()
        get_viewport().set_input_as_handled()


func toggle() -> void:
    if _config == null:
        _config = load(CONFIG_PATH) as ThemeConfig
        if _config == null:
            return

    active = true
    dark_enabled = not dark_enabled
    _palette = _config.dark if dark_enabled else _config.light
    if _palette == null:
        return

    _checkbox_checked = _make_checkbox_icon(true, _palette)
    _checkbox_unchecked = _make_checkbox_icon(false, _palette)

    _scan(get_tree().root)


func _on_node_added(node: Node) -> void:
    if not active:
        return

    call_deferred("_scan", node)


func _scan(node: Node) -> void:
    if _is_excluded(node):
        return

    _restore_node(node)
    _apply_node(node)

    for child: Node in node.get_children():
        _scan(child)


func _is_excluded(node: Node) -> bool:
    for root: Node in _excluded_roots:
        if root == null:
            continue

        if node == root:
            return true

        if root.is_ancestor_of(node):
            return true

    return false


func _apply_node(node: Node) -> void:
    if node is ColorRect:
        _apply_color_rect(node as ColorRect)

    if node is PanelContainer:
        _apply_panel_container(node as PanelContainer)

    if node is Panel:
        _apply_panel(node as Panel)

    if node is Label:
        _apply_label(node as Label)

    if node is RichTextLabel:
        _apply_rich_text_label(node as RichTextLabel)

    if node is BaseButton:
        _apply_button(node as BaseButton)

    if node is TextureRect:
        _apply_texture_rect(node as TextureRect)

    if not node.has_meta("darkmode_hooked"):
        node.set_meta("darkmode_hooked", true)
        node.tree_exited.connect(func() -> void:
            _saved.erase(node.get_instance_id())
        )


func _restore_node(node: Node) -> void:
    var id: int = node.get_instance_id()

    if not _saved.has(id):
        return

    var s: Dictionary = _saved[id]

    if node is CanvasItem:
        if s.has("modulate"):
            (node as CanvasItem).modulate = s["modulate"]
        if s.has("self_modulate"):
            (node as CanvasItem).self_modulate = s["self_modulate"]

    if node is ColorRect and s.has("colorrect_color"):
        (node as ColorRect).color = s["colorrect_color"]

    if node is Label:
        if s.has("label_settings"):
            (node as Label).label_settings = s["label_settings"]
        _restore_control_colors(node as Control, s, ["font_color", "font_shadow_color", "font_outline_color"])

    if node is RichTextLabel:
        _restore_control_colors(node as Control, s, ["default_color", "font_color"])

    if node is BaseButton:
        _restore_control_styleboxes(node as Control, s, BUTTON_STYLE_NAMES)
        _restore_control_colors(node as Control, s, BUTTON_COLOR_NAMES)

        if node is CheckBox:
            _restore_control_icons(node as Control, s, CHECKBOX_ICON_NAMES)

    if node is PanelContainer:
        _restore_control_styleboxes(node as Control, s, ["panel"])

    if node is Panel:
        _restore_control_styleboxes(node as Control, s, ["panel"])


func _ensure_saved(id: int) -> Dictionary:
    if _saved.has(id):
        return _saved[id]

    var s: Dictionary = {}
    _saved[id] = s
    return s


func _save_canvas_item(ci: CanvasItem, s: Dictionary) -> void:
    if not s.has("modulate"):
        s["modulate"] = ci.modulate

    if not s.has("self_modulate"):
        s["self_modulate"] = ci.self_modulate


# ------------------------------------------------------------
# Backgrounds
# ------------------------------------------------------------

func _apply_color_rect(cr: ColorRect) -> void:
    var id: int = cr.get_instance_id()
    var s: Dictionary = _ensure_saved(id)

    if not s.has("colorrect_color"):
        s["colorrect_color"] = cr.color

    if cr.is_in_group("theme_background") or _is_fullscreen_rect(cr):
        cr.color = Color(_palette.main_bg.r, _palette.main_bg.g, _palette.main_bg.b, cr.color.a)


func _is_fullscreen_rect(c: Control) -> bool:
    return (
        is_equal_approx(c.anchor_left, 0.0)
        and is_equal_approx(c.anchor_top, 0.0)
        and is_equal_approx(c.anchor_right, 1.0)
        and is_equal_approx(c.anchor_bottom, 1.0)
    )


# ------------------------------------------------------------
# Panels
# ------------------------------------------------------------

func _apply_panel_container(panel: PanelContainer) -> void:
    var c := panel as Control
    var id: int = c.get_instance_id()
    var s: Dictionary = _ensure_saved(id)

    _apply_control_styleboxes(c, s, ["panel"], _panel_bg_for_control(panel))


func _apply_panel(panel: Panel) -> void:
    var c := panel as Control
    var id: int = c.get_instance_id()
    var s: Dictionary = _ensure_saved(id)

    _apply_control_styleboxes(c, s, ["panel"], _panel_bg_for_control(panel))


func _panel_bg_for_control(control: Control) -> Color:
    if control.is_in_group("theme_icon_holder"):
        return _palette.card_bg

    if control.is_in_group("theme_card"):
        return _palette.card_bg

    if control.is_in_group("theme_panel"):
        return _palette.panel_bg

    var min_size: Vector2 = control.custom_minimum_size

    if min_size.x >= 240.0 or min_size.y >= 240.0:
        return _palette.panel_bg

    return _palette.card_bg


# ------------------------------------------------------------
# Labels
# ------------------------------------------------------------

func _apply_label(label: Label) -> void:
    var id: int = label.get_instance_id()
    var s: Dictionary = _ensure_saved(id)

    _save_canvas_item(label, s)
    _save_color_override(label, s, "font_color")
    _save_color_override(label, s, "font_shadow_color")
    _save_color_override(label, s, "font_outline_color")

    if not s.has("label_settings"):
        s["label_settings"] = label.label_settings

    var final_color: Color = _label_dark_color(label)

    label.modulate = Color.WHITE
    label.self_modulate = Color.WHITE

    label.add_theme_color_override("font_color", final_color)
    label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
    label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))

    if label.label_settings != null:
        var new_settings := label.label_settings.duplicate(true) as LabelSettings
        new_settings.font_color = final_color
        new_settings.shadow_color = Color(0, 0, 0, 0)
        new_settings.outline_color = Color(0, 0, 0, 0)
        label.label_settings = new_settings


func _label_dark_color(label: Label) -> Color:
    if label.is_in_group("theme_secondary_text"):
        return _palette.text_secondary

    if label.is_in_group("theme_muted_text"):
        return _palette.text_secondary.lerp(_palette.main_bg, 0.45)

    if label.is_in_group("theme_money"):
        return _palette.money_green

    if label.is_in_group("theme_warning"):
        return _palette.warning_orange

    if label.is_in_group("theme_danger"):
        return _palette.danger_red

    if label.is_in_group("theme_accent"):
        return _palette.accent_blue

    var text: String = label.text.strip_edges()

    if text.begins_with("$") or text.contains("$"):
        if text.begins_with("-") or text.contains("Expenses"):
            return _palette.danger_red
        return _palette.money_green

    if text.contains("/ 100") or text.ends_with("%"):
        return _palette.text_primary

    if text in ["Close", "Good", "Excellent"]:
        return _palette.money_green

    if text in ["Dating", "Selected"]:
        return _palette.accent_blue

    if text in ["None", "—"]:
        return _palette.text_secondary.lerp(_palette.main_bg, 0.45)

    return _palette.text_primary


func _apply_rich_text_label(label: RichTextLabel) -> void:
    var id: int = label.get_instance_id()
    var s: Dictionary = _ensure_saved(id)

    _save_canvas_item(label, s)
    _save_color_override(label, s, "default_color")
    _save_color_override(label, s, "font_color")

    label.modulate = Color.WHITE
    label.self_modulate = Color.WHITE

    label.add_theme_color_override("default_color", _palette.text_primary)
    label.add_theme_color_override("font_color", _palette.text_primary)


# ------------------------------------------------------------
# Buttons
# ------------------------------------------------------------

func _apply_button(button: BaseButton) -> void:
    var c := button as Control
    var id: int = c.get_instance_id()
    var s: Dictionary = _ensure_saved(id)

    _save_canvas_item(button, s)

    button.modulate = Color.WHITE
    button.self_modulate = Color.WHITE

    if button is CheckBox:
        _apply_checkbox(button as CheckBox, s)
        return

    if button is CheckButton:
        _apply_control_colors(c, s, BUTTON_COLOR_NAMES)
        return

    _apply_button_styleboxes(button, s)
    _apply_control_colors(c, s, BUTTON_COLOR_NAMES)


func _apply_checkbox(checkbox: CheckBox, s: Dictionary) -> void:
    var c := checkbox as Control

    _apply_control_colors(c, s, BUTTON_COLOR_NAMES)

    if not s.has("theme_icon_overrides"):
        s["theme_icon_overrides"] = {}

    var icons: Dictionary = s["theme_icon_overrides"]

    for icon_name: String in CHECKBOX_ICON_NAMES:
        if not icons.has(icon_name):
            var entry := {"had": c.has_theme_icon_override(icon_name)}
            if c.has_theme_icon_override(icon_name):
                entry["value"] = c.get_theme_icon(icon_name)
            icons[icon_name] = entry

    c.add_theme_icon_override("checked", _checkbox_checked)
    c.add_theme_icon_override("unchecked", _checkbox_unchecked)
    c.add_theme_icon_override("checked_disabled", _checkbox_checked)
    c.add_theme_icon_override("unchecked_disabled", _checkbox_unchecked)


func _apply_button_styleboxes(button: BaseButton, s: Dictionary) -> void:
    var c := button as Control

    if not s.has("theme_stylebox_overrides"):
        s["theme_stylebox_overrides"] = {}

    var so: Dictionary = s["theme_stylebox_overrides"]

    var selected: bool = button.is_in_group("theme_selected")

    for style_name: String in BUTTON_STYLE_NAMES:
        var had: bool = c.has_theme_stylebox_override(style_name)

        if not so.has(style_name):
            var entry := {"had": had}
            entry["value"] = c.get_theme_stylebox(style_name)
            so[style_name] = entry

        var base_style := (so[style_name] as Dictionary)["value"] as StyleBox
        var dark: StyleBox = _recolour_button_stylebox(base_style, style_name, selected)

        c.add_theme_stylebox_override(style_name, dark)


func _recolour_button_stylebox(current: StyleBox, style_name: String, selected: bool) -> StyleBox:
    if not (current is StyleBoxFlat):
        return current

    var style := (current as StyleBoxFlat).duplicate(true) as StyleBoxFlat

    match style_name:
        "normal":
            if selected:
                style.bg_color = _palette.selected_bg
                style.border_color = _palette.accent_blue
            else:
                style.bg_color = _palette.card_bg
                style.border_color = _palette.border

        "hover":
            if selected:
                style.bg_color = _palette.selected_bg.lightened(0.08)
                style.border_color = _palette.accent_blue
            else:
                style.bg_color = _palette.card_bg.lightened(0.06)
                style.border_color = _palette.accent_blue

        "pressed":
            style.bg_color = _palette.selected_bg
            style.border_color = _palette.accent_blue

        "disabled":
            style.bg_color = _palette.panel_bg.darkened(0.15)
            style.border_color = _palette.border.darkened(0.15)

        "focus":
            style.bg_color = Color(0, 0, 0, 0)
            style.border_color = _palette.accent_blue

    return style


# ------------------------------------------------------------
# Icons / TextureRects
# ------------------------------------------------------------

func _apply_texture_rect(texture_rect: TextureRect) -> void:
    var id: int = texture_rect.get_instance_id()
    var s: Dictionary = _ensure_saved(id)

    _save_canvas_item(texture_rect, s)

    if texture_rect.is_in_group("theme_no_icon_tint"):
        return

    texture_rect.self_modulate = Color.WHITE

    if texture_rect.is_in_group("theme_icon_accent") or texture_rect.is_in_group("theme_accent"):
        texture_rect.modulate = _palette.accent_blue
    elif texture_rect.is_in_group("theme_icon_muted"):
        texture_rect.modulate = _palette.text_secondary
    else:
        texture_rect.modulate = _palette.text_primary


# ------------------------------------------------------------
# Stylebox helpers
# ------------------------------------------------------------

func _apply_control_styleboxes(
    c: Control,
    s: Dictionary,
    names: Array,
    forced_bg: Color = Color(-1, -1, -1, -1)
) -> void:
    if not s.has("theme_stylebox_overrides"):
        s["theme_stylebox_overrides"] = {}

    var so: Dictionary = s["theme_stylebox_overrides"]

    for n in names:
        if not (n is String):
            continue

        var key := n as String
        var had: bool = c.has_theme_stylebox_override(key)

        if not so.has(key):
            var entry := {"had": had}
            entry["value"] = c.get_theme_stylebox(key)
            so[key] = entry

        var base_style := (so[key] as Dictionary)["value"] as StyleBox
        var dark: StyleBox = _make_dark_stylebox(base_style, forced_bg)
        c.add_theme_stylebox_override(key, dark)


func _make_dark_stylebox(current: StyleBox, forced_bg: Color) -> StyleBox:
    if current is StyleBoxTexture:
        var st := current as StyleBoxTexture
        var tex: Texture2D = st.texture
        if tex == null:
            return current

        var tex_path: String = tex.resource_path
        if tex_path == "":
            return current

        if tex_path == CARD_BG_LIGHT_PATH:
            if _sb_card_dark == null:
                _sb_card_dark = load(STYLEBOX_CARD_DARK_PATH) as StyleBox
            return _sb_card_dark if _sb_card_dark != null else current

        if tex_path == PANEL_BG_LIGHT_PATH:
            if _sb_panel_dark == null:
                _sb_panel_dark = load(STYLEBOX_PANEL_DARK_PATH) as StyleBox
            return _sb_panel_dark if _sb_panel_dark != null else current

        return current

    if not (current is StyleBoxFlat):
        return current

    var style := (current as StyleBoxFlat).duplicate(true) as StyleBoxFlat

    if forced_bg.r >= 0.0:
        style.bg_color = forced_bg
    else:
        style.bg_color = _palette.card_bg

    if style.bg_color.a <= 0.001:
        style.bg_color = Color(0, 0, 0, 0)

    style.border_color = _palette.border

    return style


# ------------------------------------------------------------
# Theme colour helpers
# ------------------------------------------------------------

func _apply_control_colors(c: Control, s: Dictionary, names: Array) -> void:
    for n in names:
        if not (n is String):
            continue

        var key := n as String

        _save_color_override(c, s, key)

        if key.contains("disabled"):
            c.add_theme_color_override(key, _palette.text_secondary.lerp(_palette.main_bg, 0.45))
            continue

        if key.begins_with("icon"):
            if c.is_in_group("theme_icon_accent") or c.is_in_group("theme_accent"):
                c.add_theme_color_override(key, _palette.accent_blue)
            elif c.is_in_group("theme_icon_muted"):
                c.add_theme_color_override(key, _palette.text_secondary)
            else:
                c.add_theme_color_override(key, _palette.text_primary)
            continue

        c.add_theme_color_override(key, _palette.text_primary)


func _save_color_override(c: Control, s: Dictionary, key: String) -> void:
    if not s.has("theme_color_overrides"):
        s["theme_color_overrides"] = {}

    var co: Dictionary = s["theme_color_overrides"]

    if co.has(key):
        return

    var entry := {"had": c.has_theme_color_override(key)}

    if c.has_theme_color_override(key):
        entry["value"] = c.get_theme_color(key)

    co[key] = entry


func _restore_control_styleboxes(c: Control, s: Dictionary, names: Array) -> void:
    if not s.has("theme_stylebox_overrides"):
        return

    var so: Dictionary = s["theme_stylebox_overrides"]

    for n in names:
        if not (n is String):
            continue

        var key := n as String

        if not so.has(key):
            continue

        var entry: Dictionary = so[key]

        if bool(entry.get("had", false)):
            c.add_theme_stylebox_override(key, entry.get("value"))
        else:
            c.remove_theme_stylebox_override(key)


func _restore_control_colors(c: Control, s: Dictionary, names: Array) -> void:
    if not s.has("theme_color_overrides"):
        return

    var co: Dictionary = s["theme_color_overrides"]

    for n in names:
        if not (n is String):
            continue

        var key := n as String

        if not co.has(key):
            continue

        var entry: Dictionary = co[key]

        if bool(entry.get("had", false)):
            c.add_theme_color_override(key, entry.get("value"))
        else:
            c.remove_theme_color_override(key)


func _restore_control_icons(c: Control, s: Dictionary, names: Array) -> void:
    if not s.has("theme_icon_overrides"):
        return

    var icons: Dictionary = s["theme_icon_overrides"]

    for n in names:
        if not (n is String):
            continue

        var key := n as String

        if not icons.has(key):
            continue

        var entry: Dictionary = icons[key]

        if bool(entry.get("had", false)):
            c.add_theme_icon_override(key, entry.get("value"))
        else:
            c.remove_theme_icon_override(key)


# ------------------------------------------------------------
# Generated CheckBox icons
# ------------------------------------------------------------

func _make_checkbox_icon(checked: bool, palette: ThemePalette) -> Texture2D:
    var size: int = 18
    var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)

    var transparent: Color = Color(0, 0, 0, 0)
    var border: Color = palette.text_secondary
    var fill: Color = palette.card_bg
    var tick: Color = palette.text_primary

    for y: int in range(size):
        for x: int in range(size):
            image.set_pixel(x, y, transparent)

    for y: int in range(3, size - 3):
        for x: int in range(3, size - 3):
            image.set_pixel(x, y, fill)

    for x: int in range(3, size - 3):
        image.set_pixel(x, 3, border)
        image.set_pixel(x, size - 4, border)

    for y: int in range(3, size - 3):
        image.set_pixel(3, y, border)
        image.set_pixel(size - 4, y, border)

    if checked:
        _draw_pixel_line(image, Vector2i(5, 9), Vector2i(8, 12), tick)
        _draw_pixel_line(image, Vector2i(8, 12), Vector2i(13, 6), tick)

    return ImageTexture.create_from_image(image)


func _draw_pixel_line(image: Image, from: Vector2i, to: Vector2i, color: Color) -> void:
    var x0: int = from.x
    var y0: int = from.y
    var x1: int = to.x
    var y1: int = to.y

    var dx: int = abs(x1 - x0)
    var sx: int = 1 if x0 < x1 else -1
    var dy: int = -abs(y1 - y0)
    var sy: int = 1 if y0 < y1 else -1
    var err: int = dx + dy

    while true:
        for oy: int in range(-1, 2):
            for ox: int in range(-1, 2):
                var px: int = x0 + ox
                var py: int = y0 + oy

                if px >= 0 and px < image.get_width() and py >= 0 and py < image.get_height():
                    image.set_pixel(px, py, color)

        if x0 == x1 and y0 == y1:
            break

        var e2: int = 2 * err

        if e2 >= dy:
            err += dy
            x0 += sx

        if e2 <= dx:
            err += dx
            y0 += sy


# ------------------------------------------------------------
# Utility
# ------------------------------------------------------------

func _color_close(a: Color, b: Color, tolerance: float = 0.08) -> bool:
    return (
        abs(a.r - b.r) <= tolerance
        and abs(a.g - b.g) <= tolerance
        and abs(a.b - b.b) <= tolerance
        and abs(a.a - b.a) <= tolerance
    )
