extends Control

@export_file("*.tscn") var back_scene_path: String = "res://scenes/main/MainMenu.tscn"

@onready var _back_button: Button = get_node_or_null("Background/Center/Card/Margin/VBox/BackButton")

@onready var _fullscreen_toggle: CheckButton = get_node_or_null("Background/Center/Card/Margin/VBox/TabContainer/Display/FullscreenToggle")
@onready var _resolution_dropdown: OptionButton = get_node_or_null("Background/Center/Card/Margin/VBox/TabContainer/Display/ResolutionRow/ResolutionDropdown")
@onready var _ui_scale_slider: HSlider = get_node_or_null("Background/Center/Card/Margin/VBox/TabContainer/Display/UIScaleRow/UIScaleSlider")

@onready var _master_slider: HSlider = get_node_or_null("Background/Center/Card/Margin/VBox/TabContainer/Audio/MasterRow/MasterSlider")
@onready var _music_slider: HSlider = get_node_or_null("Background/Center/Card/Margin/VBox/TabContainer/Audio/MusicRow/MusicSlider")
@onready var _sfx_slider: HSlider = get_node_or_null("Background/Center/Card/Margin/VBox/TabContainer/Audio/SfxRow/SfxSlider")
@onready var _ui_sounds_toggle: CheckButton = get_node_or_null("Background/Center/Card/Margin/VBox/TabContainer/Audio/UISoundsToggle")

@onready var _energy_speed_slider: HSlider = get_node_or_null("Background/Center/Card/Margin/VBox/TabContainer/Gameplay/EnergyRow/EnergySpeedSlider")
@onready var _energy_speed_value_label: Label = get_node_or_null("Background/Center/Card/Margin/VBox/TabContainer/Gameplay/EnergyRow/EnergySpeedValueLabel")

@onready var _font_size_dropdown: OptionButton = get_node_or_null("Background/Center/Card/Margin/VBox/TabContainer/Accessibility/FontSizeRow/FontSizeDropdown")
@onready var _dyslexia_toggle: CheckButton = get_node_or_null("Background/Center/Card/Margin/VBox/TabContainer/Accessibility/DyslexiaFontToggle")
@onready var _reduce_anim_toggle: CheckButton = get_node_or_null("Background/Center/Card/Margin/VBox/TabContainer/Accessibility/ReduceAnimationsToggle")
@onready var _colourblind_toggle: CheckButton = get_node_or_null("Background/Center/Card/Margin/VBox/TabContainer/Accessibility/ColourblindToggle")

@onready var _tooltip_hints_toggle: CheckButton = get_node_or_null("Background/Center/Card/Margin/VBox/TabContainer/Help/TooltipHintsToggle")
@onready var _reset_tutorial_button: Button = get_node_or_null("Background/Center/Card/Margin/VBox/TabContainer/Help/ResetTutorialHintsButton")
@onready var _reset_defaults_button: Button = get_node_or_null("Background/Center/Card/Margin/VBox/TabContainer/Help/ResetDefaultsButton")

var _settings: Node
var _resolutions: Array[String] = ["1280x720", "1600x900", "1920x1080", "2560x1440"]

func _ready() -> void:
    _settings = get_node_or_null("/root/SettingsManager")

    if _back_button != null:
        if not _back_button.pressed.is_connected(_on_back_pressed):
            _back_button.pressed.connect(_on_back_pressed)

    _init_ui()

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        _on_back_pressed()

func _init_ui() -> void:
    if _settings == null:
        return

    if _fullscreen_toggle != null:
        var fullscreen := bool(_settings.call("get_value", "display", "fullscreen", false))
        _fullscreen_toggle.button_pressed = fullscreen
        if not _fullscreen_toggle.toggled.is_connected(_on_fullscreen_toggled):
            _fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)

    if _resolution_dropdown != null:
        _resolution_dropdown.clear()
        for r in _resolutions:
            _resolution_dropdown.add_item(r)
        var res_value := str(_settings.call("get_value", "display", "resolution", "1280x720"))
        var idx := _resolutions.find(res_value)
        if idx < 0:
            idx = 0
        _resolution_dropdown.select(idx)
        _resolution_dropdown.disabled = _fullscreen_toggle != null and _fullscreen_toggle.button_pressed
        if not _resolution_dropdown.item_selected.is_connected(_on_resolution_selected):
            _resolution_dropdown.item_selected.connect(_on_resolution_selected)

    if _ui_scale_slider != null:
        var ui_scale_bounds: Vector2 = _settings.call("_get_ui_scale_bounds") as Vector2
        _ui_scale_slider.min_value = ui_scale_bounds.x
        _ui_scale_slider.max_value = ui_scale_bounds.y
        _ui_scale_slider.value = clampf(float(_settings.call("get_value", "display", "ui_scale", 1.0)), ui_scale_bounds.x, ui_scale_bounds.y)
        if not _ui_scale_slider.value_changed.is_connected(_on_ui_scale_changed):
            _ui_scale_slider.value_changed.connect(_on_ui_scale_changed)

    if _master_slider != null:
        _master_slider.value = float(_settings.call("get_value", "audio", "master", 100))
        if not _master_slider.value_changed.is_connected(_on_master_changed):
            _master_slider.value_changed.connect(_on_master_changed)

    if _music_slider != null:
        _music_slider.value = float(_settings.call("get_value", "audio", "music", 80))
        if not _music_slider.value_changed.is_connected(_on_music_changed):
            _music_slider.value_changed.connect(_on_music_changed)

    if _sfx_slider != null:
        _sfx_slider.value = float(_settings.call("get_value", "audio", "sfx", 80))
        if not _sfx_slider.value_changed.is_connected(_on_sfx_changed):
            _sfx_slider.value_changed.connect(_on_sfx_changed)

    if _ui_sounds_toggle != null:
        _ui_sounds_toggle.button_pressed = bool(_settings.call("get_value", "audio", "ui_sounds", true))
        if not _ui_sounds_toggle.toggled.is_connected(_on_ui_sounds_toggled):
            _ui_sounds_toggle.toggled.connect(_on_ui_sounds_toggled)

    if _energy_speed_slider != null:
        _energy_speed_slider.value = float(_settings.call("get_value", "gameplay", "energy_drain_speed", 0.40))
        if not _energy_speed_slider.value_changed.is_connected(_on_energy_speed_changed):
            _energy_speed_slider.value_changed.connect(_on_energy_speed_changed)
    _update_energy_speed_label()

    if _font_size_dropdown != null:
        _font_size_dropdown.clear()
        _font_size_dropdown.add_item("Small")
        _font_size_dropdown.add_item("Medium")
        _font_size_dropdown.add_item("Large")
        var font_size_key := str(_settings.call("get_value", "accessibility", "font_size", "medium"))
        var font_idx := 1
        if font_size_key == "small":
            font_idx = 0
        elif font_size_key == "large":
            font_idx = 2
        _font_size_dropdown.select(font_idx)
        if not _font_size_dropdown.item_selected.is_connected(_on_font_size_selected):
            _font_size_dropdown.item_selected.connect(_on_font_size_selected)

    if _dyslexia_toggle != null:
        _dyslexia_toggle.button_pressed = bool(_settings.call("get_value", "accessibility", "dyslexia_font", false))
        if not _dyslexia_toggle.toggled.is_connected(_on_dyslexia_toggled):
            _dyslexia_toggle.toggled.connect(_on_dyslexia_toggled)

    if _reduce_anim_toggle != null:
        _reduce_anim_toggle.button_pressed = bool(_settings.call("get_value", "accessibility", "reduce_animations", false))
        if not _reduce_anim_toggle.toggled.is_connected(_on_reduce_animations_toggled):
            _reduce_anim_toggle.toggled.connect(_on_reduce_animations_toggled)

    if _colourblind_toggle != null:
        _colourblind_toggle.button_pressed = bool(_settings.call("get_value", "accessibility", "colourblind_mode", false))
        if not _colourblind_toggle.toggled.is_connected(_on_colourblind_toggled):
            _colourblind_toggle.toggled.connect(_on_colourblind_toggled)

    if _tooltip_hints_toggle != null:
        _tooltip_hints_toggle.button_pressed = bool(_settings.call("get_value", "help", "tooltip_hints", true))
        if not _tooltip_hints_toggle.toggled.is_connected(_on_tooltip_hints_toggled):
            _tooltip_hints_toggle.toggled.connect(_on_tooltip_hints_toggled)

    if _reset_tutorial_button != null and not _reset_tutorial_button.pressed.is_connected(_on_reset_tutorial_hints_pressed):
        _reset_tutorial_button.pressed.connect(_on_reset_tutorial_hints_pressed)
    if _reset_defaults_button != null and not _reset_defaults_button.pressed.is_connected(_on_reset_defaults_pressed):
        _reset_defaults_button.pressed.connect(_on_reset_defaults_pressed)

func _update_energy_speed_label() -> void:
    if _energy_speed_value_label == null or _energy_speed_slider == null:
        return
    var seconds_per_week := float(_energy_speed_slider.value) * 100.0
    _energy_speed_value_label.text = "%.1fs per week" % seconds_per_week

func _on_fullscreen_toggled(pressed: bool) -> void:
    if _settings != null:
        _settings.call("set_value", "display", "fullscreen", pressed)
    if _resolution_dropdown != null:
        _resolution_dropdown.disabled = pressed
    _refresh_ui_scale_slider_bounds()

func _on_resolution_selected(index: int) -> void:
    if _settings == null or _resolution_dropdown == null:
        return
    _settings.call("set_value", "display", "resolution", _resolution_dropdown.get_item_text(index))
    _refresh_ui_scale_slider_bounds()

func _on_ui_scale_changed(v: float) -> void:
    if _settings == null:
        return
    var bounds: Vector2 = _settings.call("_get_ui_scale_bounds") as Vector2
    var clamped := clampf(v, bounds.x, bounds.y)
    if _ui_scale_slider != null and absf(_ui_scale_slider.value - clamped) > 0.0001:
        _ui_scale_slider.value = clamped
    _settings.call("set_value", "display", "ui_scale", clamped)

func _refresh_ui_scale_slider_bounds() -> void:
    if _settings == null or _ui_scale_slider == null:
        return
    var bounds: Vector2 = _settings.call("_get_ui_scale_bounds") as Vector2
    _ui_scale_slider.min_value = bounds.x
    _ui_scale_slider.max_value = bounds.y
    _ui_scale_slider.value = clampf(_ui_scale_slider.value, bounds.x, bounds.y)

func _on_master_changed(v: float) -> void:
    if _settings != null:
        _settings.call("set_value", "audio", "master", int(round(v)))

func _on_music_changed(v: float) -> void:
    if _settings != null:
        _settings.call("set_value", "audio", "music", int(round(v)))

func _on_sfx_changed(v: float) -> void:
    if _settings != null:
        _settings.call("set_value", "audio", "sfx", int(round(v)))

func _on_ui_sounds_toggled(pressed: bool) -> void:
    if _settings != null:
        _settings.call("set_value", "audio", "ui_sounds", pressed)

func _on_energy_speed_changed(v: float) -> void:
    _update_energy_speed_label()
    if _settings != null:
        _settings.call("set_value", "gameplay", "energy_drain_speed", v)

func _on_font_size_selected(index: int) -> void:
    if _settings == null:
        return
    var key := "medium"
    if index == 0:
        key = "small"
    elif index == 2:
        key = "large"
    _settings.call("set_value", "accessibility", "font_size", key)

func _on_dyslexia_toggled(pressed: bool) -> void:
    if _settings != null:
        _settings.call("set_value", "accessibility", "dyslexia_font", pressed)

func _on_reduce_animations_toggled(pressed: bool) -> void:
    if _settings != null:
        _settings.call("set_value", "accessibility", "reduce_animations", pressed)

func _on_colourblind_toggled(pressed: bool) -> void:
    if _settings != null:
        _settings.call("set_value", "accessibility", "colourblind_mode", pressed)

func _on_tooltip_hints_toggled(pressed: bool) -> void:
    if _settings != null:
        _settings.call("set_value", "help", "tooltip_hints", pressed)

func _on_reset_tutorial_hints_pressed() -> void:
    if _settings != null and _settings.has_method("reset_tutorial_hints"):
        _settings.call("reset_tutorial_hints")

func _on_reset_defaults_pressed() -> void:
    if _settings != null and _settings.has_method("reset_to_defaults"):
        _settings.call("reset_to_defaults")
        _init_ui()

func _on_back_pressed() -> void:
    var transitions := get_node_or_null("/root/SceneTransitions")
    if transitions != null:
        transitions.call("go_to", back_scene_path)
        return
    get_tree().change_scene_to_file(back_scene_path)
