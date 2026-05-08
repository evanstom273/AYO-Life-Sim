@tool
extends Node

const BUTTON_STYLE_NAMES: Array[String] = ["normal", "hover", "pressed", "disabled", "focus"]

const BUTTON_COLOR_NAMES: Array[String] = [
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

const CHECKBOX_ICON_NAMES: Array[String] = ["checked", "unchecked", "checked_disabled", "unchecked_disabled"]

const STYLEBOX_CARD_LIGHT_PATH: String = "res://resources/ui/styleboxes/card_light.tres"
const STYLEBOX_CARD_DARK_PATH: String = "res://resources/ui/styleboxes/card_dark.tres"
const STYLEBOX_PANEL_LIGHT_PATH: String = "res://resources/ui/styleboxes/panel_light.tres"
const STYLEBOX_PANEL_DARK_PATH: String = "res://resources/ui/styleboxes/panel_dark.tres"

@export var config: ThemeConfig = load("res://resources/theme/theme_config.tres") as ThemeConfig

@export var preview_dark: bool = false:
    set(value):
        preview_dark = value
        if Engine.is_editor_hint():
            call_deferred("_apply_preview")

var _baseline: Dictionary = {}
var _baseline_captured: bool = false

var _sb_card_light: StyleBox
var _sb_card_dark: StyleBox
var _sb_panel_light: StyleBox
var _sb_panel_dark: StyleBox


func _get_textured_stylebox(control: Control) -> StyleBox:
    var is_panel: bool = _is_panel_like(control)

    if preview_dark:
        if is_panel:
            if _sb_panel_dark == null:
                _sb_panel_dark = load(STYLEBOX_PANEL_DARK_PATH) as StyleBox
            return _sb_panel_dark
        if _sb_card_dark == null:
            _sb_card_dark = load(STYLEBOX_CARD_DARK_PATH) as StyleBox
        return _sb_card_dark

    if is_panel:
        if _sb_panel_light == null:
            _sb_panel_light = load(STYLEBOX_PANEL_LIGHT_PATH) as StyleBox
        return _sb_panel_light
    if _sb_card_light == null:
        _sb_card_light = load(STYLEBOX_CARD_LIGHT_PATH) as StyleBox
    return _sb_card_light


func _is_panel_like(control: Control) -> bool:
    if control.is_in_group("theme_panel"):
        return true
    if control.is_in_group("theme_card"):
        return false
    var min_size: Vector2 = control.custom_minimum_size
    return min_size.x >= 240.0 or min_size.y >= 240.0


func _ready() -> void:
    if Engine.is_editor_hint():
        _hook_config_changes()
        call_deferred("_apply_preview")


func _apply_preview() -> void:
    if not Engine.is_editor_hint():
        return

    var root := get_tree().edited_scene_root
    if root == null:
        root = get_owner()
    if root == null:
        root = get_parent()
    if root == null:
        return

    if config == null:
        config = load("res://resources/theme/theme_config.tres") as ThemeConfig
        if config == null:
            return

    if not _baseline_captured:
        _capture_baseline(root)
        _baseline_captured = true
    else:
        _restore_tree(root)

    var palette: ThemePalette = config.dark if preview_dark else config.light
    if palette == null:
        return

    _apply_tree(root, palette)


func _hook_config_changes() -> void:
    if not Engine.is_editor_hint():
        return

    if config == null:
        return

    if not config.changed.is_connected(_on_config_changed):
        config.changed.connect(_on_config_changed)

    if config.light != null and not config.light.changed.is_connected(_on_config_changed):
        config.light.changed.connect(_on_config_changed)

    if config.dark != null and not config.dark.changed.is_connected(_on_config_changed):
        config.dark.changed.connect(_on_config_changed)


func _on_config_changed() -> void:
    call_deferred("_apply_preview")


func _capture_baseline(node: Node) -> void:
    if _is_excluded(node):
        return

    _capture_node(node)

    for child in node.get_children():
        _capture_baseline(child)


func _capture_node(node: Node) -> void:
    var id: int = node.get_instance_id()

    if _baseline.has(id):
        return

    var s: Dictionary = {}
    _baseline[id] = s

    if node is CanvasItem:
        var ci := node as CanvasItem
        s["modulate"] = ci.modulate
        s["self_modulate"] = ci.self_modulate

    if node is ColorRect:
        s["colorrect_color"] = (node as ColorRect).color

    if node is Control:
        _capture_control_styleboxes(node as Control, s, ["panel"])
        _capture_control_styleboxes(node as Control, s, BUTTON_STYLE_NAMES)
        _capture_control_colors(node as Control, s, ["font_color", "font_shadow_color", "font_outline_color", "default_color"])
        _capture_control_colors(node as Control, s, BUTTON_COLOR_NAMES)

        if node is CheckBox:
            _capture_control_icons(node as Control, s, CHECKBOX_ICON_NAMES)

    if node is Label:
        var label := node as Label
        s["label_settings"] = label.label_settings


func _restore_tree(node: Node) -> void:
    if _is_excluded(node):
        return

    _restore_node(node)

    for child in node.get_children():
        _restore_tree(child)


func _restore_node(node: Node) -> void:
    var id: int = node.get_instance_id()
    if not _baseline.has(id):
        return

    var s: Dictionary = _baseline[id]

    if node is CanvasItem:
        var ci := node as CanvasItem
        ci.modulate = s["modulate"]
        ci.self_modulate = s["self_modulate"]

    if node is ColorRect:
        (node as ColorRect).color = s["colorrect_color"]

    if node is Label:
        (node as Label).label_settings = s["label_settings"]

    if node is Control:
        _restore_control_styleboxes(node as Control, s, ["panel"])
        _restore_control_styleboxes(node as Control, s, BUTTON_STYLE_NAMES)
        _restore_control_colors(node as Control, s, ["font_color", "font_shadow_color", "font_outline_color", "default_color"])
        _restore_control_colors(node as Control, s, BUTTON_COLOR_NAMES)

        if node is CheckBox:
            _restore_control_icons(node as Control, s, CHECKBOX_ICON_NAMES)


func _apply_tree(node: Node, palette: ThemePalette) -> void:
    if _is_excluded(node):
        return

    _apply_node(node, palette)

    for child in node.get_children():
        _apply_tree(child, palette)


func _apply_node(node: Node, palette: ThemePalette) -> void:
    if node is ColorRect:
        _apply_color_rect(node as ColorRect, palette)

    if node is PanelContainer:
        _apply_panel_container(node as PanelContainer, palette)

    if node is Panel:
        _apply_panel(node as Panel, palette)

    if node is Label:
        _apply_label(node as Label, palette)

    if node is RichTextLabel:
        _apply_rich_text_label(node as RichTextLabel, palette)

    if node is BaseButton:
        _apply_button(node as BaseButton, palette)

    if node is TextureRect:
        _apply_texture_rect(node as TextureRect, palette)


func _is_excluded(node: Node) -> bool:
    if node == self:
        return true
    if self.is_ancestor_of(node):
        return true
    return false


func _apply_color_rect(cr: ColorRect, palette: ThemePalette) -> void:
    if cr.is_in_group("theme_background") or _is_fullscreen_rect(cr):
        cr.color = Color(palette.main_bg.r, palette.main_bg.g, palette.main_bg.b, cr.color.a)


func _is_fullscreen_rect(c: Control) -> bool:
    return (
        is_equal_approx(c.anchor_left, 0.0)
        and is_equal_approx(c.anchor_top, 0.0)
        and is_equal_approx(c.anchor_right, 1.0)
        and is_equal_approx(c.anchor_bottom, 1.0)
    )


func _apply_panel_container(panel: PanelContainer, palette: ThemePalette) -> void:
    var c := panel as Control
    var base: StyleBox = c.get_theme_stylebox("panel")

    if base is StyleBoxTexture:
        var textured: StyleBox = _get_textured_stylebox(c)
        if textured != null:
            c.add_theme_stylebox_override("panel", textured)
        return

    if base is StyleBoxFlat:
        var flat := (base as StyleBoxFlat).duplicate(true) as StyleBoxFlat
        flat.bg_color = _panel_bg_for(panel, palette)
        flat.border_color = palette.border
        c.add_theme_stylebox_override("panel", flat)

func _apply_panel(panel: Panel, palette: ThemePalette) -> void:
    var c := panel as Control
    var base: StyleBox = c.get_theme_stylebox("panel")

    if base is StyleBoxTexture:
        var textured: StyleBox = _get_textured_stylebox(c)
        if textured != null:
            c.add_theme_stylebox_override("panel", textured)
        return

    if base is StyleBoxFlat:
        var flat := (base as StyleBoxFlat).duplicate(true) as StyleBoxFlat
        flat.bg_color = _panel_bg_for(panel, palette)
        flat.border_color = palette.border
        c.add_theme_stylebox_override("panel", flat)


func _panel_bg_for(panel: Control, palette: ThemePalette) -> Color:
    if panel.is_in_group("theme_card"):
        return palette.card_bg
    if panel.is_in_group("theme_panel"):
        return palette.panel_bg

    var min_size := panel.custom_minimum_size
    if min_size.x >= 240.0 or min_size.y >= 240.0:
        return palette.panel_bg

    return palette.card_bg


func _apply_label(label: Label, palette: ThemePalette) -> void:
    var final_color := _label_color(label, palette)

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


func _muted_text(palette: ThemePalette) -> Color:
    return palette.text_secondary.lerp(palette.main_bg, 0.45)


func _label_color(label: Label, palette: ThemePalette) -> Color:
    if label.is_in_group("theme_secondary_text"):
        return palette.text_secondary
    if label.is_in_group("theme_muted_text"):
        return _muted_text(palette)
    if label.is_in_group("theme_money"):
        return palette.money_green
    if label.is_in_group("theme_warning"):
        return palette.warning_orange
    if label.is_in_group("theme_danger"):
        return palette.danger_red
    if label.is_in_group("theme_accent"):
        return palette.accent_blue

    var text := label.text.strip_edges()

    if text.begins_with("$") or text.contains("$"):
        if text.begins_with("-") or text.contains("Expenses"):
            return palette.danger_red
        return palette.money_green

    if text in ["Close", "Good", "Excellent"]:
        return palette.money_green

    if text in ["Dating", "Selected"]:
        return palette.accent_blue

    if text in ["None", "—"]:
        return _muted_text(palette)

    return palette.text_primary


func _apply_rich_text_label(label: RichTextLabel, palette: ThemePalette) -> void:
    label.modulate = Color.WHITE
    label.self_modulate = Color.WHITE

    label.add_theme_color_override("default_color", palette.text_primary)
    label.add_theme_color_override("font_color", palette.text_primary)


func _apply_button(button: BaseButton, palette: ThemePalette) -> void:
    var c := button as Control
    var selected := button.is_in_group("theme_selected")

    _apply_button_styleboxes(c, palette, selected)
    _apply_button_colors(c, palette, selected)

    if button is CheckBox:
        _apply_checkbox_icons(c, palette)


func _apply_button_styleboxes(c: Control, palette: ThemePalette, selected: bool) -> void:
    for style_name in BUTTON_STYLE_NAMES:
        var base: StyleBox = c.get_theme_stylebox(style_name)
        if not (base is StyleBoxFlat):
            continue

        var style := (base as StyleBoxFlat).duplicate(true) as StyleBoxFlat

        match style_name:
            "normal":
                if selected:
                    style.bg_color = palette.selected_bg
                    style.border_color = palette.accent_blue
                else:
                    style.bg_color = palette.card_bg
                    style.border_color = palette.border
            "hover":
                if selected:
                    style.bg_color = palette.selected_bg.lightened(0.08)
                    style.border_color = palette.accent_blue
                else:
                    style.bg_color = palette.card_bg.lightened(0.06)
                    style.border_color = palette.accent_blue
            "pressed":
                style.bg_color = palette.selected_bg
                style.border_color = palette.accent_blue
            "disabled":
                style.bg_color = palette.panel_bg.darkened(0.08)
                style.border_color = palette.border.darkened(0.08)
            "focus":
                style.bg_color = Color(0, 0, 0, 0)
                style.border_color = palette.accent_blue

        c.add_theme_stylebox_override(style_name, style)


func _apply_button_colors(c: Control, palette: ThemePalette, selected: bool) -> void:
    var primary: Color = palette.accent_blue if selected else palette.text_primary
    var secondary: Color = palette.text_secondary
    var disabled: Color = secondary
    disabled.a = 0.45

    c.add_theme_color_override("font_color", primary)
    c.add_theme_color_override("font_hover_color", primary)
    c.add_theme_color_override("font_pressed_color", primary)
    c.add_theme_color_override("font_focus_color", primary)
    c.add_theme_color_override("font_hover_pressed_color", primary)
    c.add_theme_color_override("font_disabled_color", disabled)

    c.add_theme_color_override("icon_normal_color", secondary)
    c.add_theme_color_override("icon_hover_color", palette.accent_blue)
    c.add_theme_color_override("icon_pressed_color", palette.accent_blue)
    c.add_theme_color_override("icon_hover_pressed_color", palette.accent_blue)
    c.add_theme_color_override("icon_focus_color", palette.accent_blue)
    c.add_theme_color_override("icon_disabled_color", disabled)


func _apply_checkbox_icons(c: Control, palette: ThemePalette) -> void:
    var checked := _make_checkbox_icon(true, palette)
    var unchecked := _make_checkbox_icon(false, palette)

    c.add_theme_icon_override("checked", checked)
    c.add_theme_icon_override("unchecked", unchecked)
    c.add_theme_icon_override("checked_disabled", checked)
    c.add_theme_icon_override("unchecked_disabled", unchecked)


func _make_checkbox_icon(checked: bool, palette: ThemePalette) -> Texture2D:
    var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))

    var border := palette.border
    var fill := palette.selected_bg

    for x in range(16):
        for y in range(16):
            var is_border := (x == 0 or y == 0 or x == 15 or y == 15)
            if is_border:
                img.set_pixel(x, y, border)
            else:
                img.set_pixel(x, y, fill if checked else Color(0, 0, 0, 0))

    return ImageTexture.create_from_image(img)


func _apply_texture_rect(texture_rect: TextureRect, palette: ThemePalette) -> void:
    if texture_rect.is_in_group("theme_no_icon_tint"):
        return

    texture_rect.self_modulate = Color.WHITE
    texture_rect.modulate = palette.accent_blue if texture_rect.is_in_group("theme_accent") else palette.text_primary


func _capture_control_styleboxes(c: Control, s: Dictionary, names: Array[String]) -> void:
    if not s.has("styleboxes"):
        s["styleboxes"] = {}

    var sb: Dictionary = s["styleboxes"] as Dictionary

    for name in names:
        if sb.has(name):
            continue

        var entry: Dictionary = {"had": c.has_theme_stylebox_override(name)}
        if entry["had"]:
            entry["value"] = c.get_theme_stylebox(name)
        sb[name] = entry


func _restore_control_styleboxes(c: Control, s: Dictionary, names: Array[String]) -> void:
    if not s.has("styleboxes"):
        return

    var sb: Dictionary = s["styleboxes"] as Dictionary

    for name in names:
        if not sb.has(name):
            continue

        var entry: Dictionary = sb[name]
        if entry["had"]:
            c.add_theme_stylebox_override(name, entry["value"])
        else:
            c.remove_theme_stylebox_override(name)


func _capture_control_colors(c: Control, s: Dictionary, names: Array[String]) -> void:
    if not s.has("colors"):
        s["colors"] = {}

    var co: Dictionary = s["colors"] as Dictionary

    for name in names:
        if co.has(name):
            continue

        var entry: Dictionary = {"had": c.has_theme_color_override(name)}
        if entry["had"]:
            entry["value"] = c.get_theme_color(name)
        co[name] = entry


func _restore_control_colors(c: Control, s: Dictionary, names: Array[String]) -> void:
    if not s.has("colors"):
        return

    var co: Dictionary = s["colors"] as Dictionary

    for name in names:
        if not co.has(name):
            continue

        var entry: Dictionary = co[name]
        if entry["had"]:
            c.add_theme_color_override(name, entry["value"])
        else:
            c.remove_theme_color_override(name)


func _capture_control_icons(c: Control, s: Dictionary, names: Array[String]) -> void:
    if not s.has("icons"):
        s["icons"] = {}

    var ic: Dictionary = s["icons"] as Dictionary

    for name in names:
        if ic.has(name):
            continue

        var entry: Dictionary = {"had": c.has_theme_icon_override(name)}
        if entry["had"]:
            entry["value"] = c.get_theme_icon(name)
        ic[name] = entry


func _restore_control_icons(c: Control, s: Dictionary, names: Array[String]) -> void:
    if not s.has("icons"):
        return

    var ic: Dictionary = s["icons"] as Dictionary

    for name in names:
        if not ic.has(name):
            continue

        var entry: Dictionary = ic[name]
        if entry["had"]:
            c.add_theme_icon_override(name, entry["value"])
        else:
            c.remove_theme_icon_override(name)
