extends PanelContainer

const MONTH_NAMES: Array[String] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
const MONTH_NAMES_FULL: Array[String] = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
const _DANGER_RED := Color(0.9372549, 0.26666668, 0.26666668, 1)

@export var year: int = 2025
@export_range(0, 11, 1) var month_index: int = 0
@export_range(1, 4, 1) var week_index: int = 1

@export_range(0.1, 1.0, 0.05) var energy_tick_rate: float = 0.2
@export var ignore_time_scale: bool = true

@export var debug_log_energy_ticks: bool = false
@export var debug_log_energy_run_time: bool = false

var _drain_start_msec: int = -1
var _drain_last_tick_msec: int = -1
var _drain_active_elapsed_msec: int = 0
var _drain_paused_at_msec: int = -1
var _drain_start_energy: int = 100
var _drain_tick_count: int = 0
var _debug_last_percent_bucket: int = 10

# Energy System Variables
var max_energy: int = 100
var current_energy: int = 100
var _player_name: String = ""
var _player_age: int = 0
var _energy_timer: Timer
var _energy_value_tween: Tween
var _energy_color_tween: Tween
var _energy_fill_style: StyleBoxFlat
var _energy_fill_normal_color: Color
var _root_color_rect: Control
var _depleted_tween: Tween
var _micro_shake_tween: Tween
var _month_start_stats: Dictionary = {}
var _month_start_year: int = -1
var _month_start_month_index: int = -1

@onready var _prev_month: Button = get_node("MarginContainer/VBoxContainer/Header/MonthControls/PrevMonth")
@onready var _next_month: Button = get_node("MarginContainer/VBoxContainer/Header/MonthControls/NextMonth")
@onready var _month_label: Label = get_node("MarginContainer/VBoxContainer/Header/MonthControls/MonthLabel")
@onready var _helper: Label = get_node("MarginContainer/VBoxContainer/Helper")
@onready var _weeks_container: Control = get_node("MarginContainer/VBoxContainer/WeeksRow")
@onready var _wk_buttons: Array[BaseButton] = [
    get_node("MarginContainer/VBoxContainer/WeeksRow/Wk1"),
    get_node("MarginContainer/VBoxContainer/WeeksRow/Wk2"),
    get_node("MarginContainer/VBoxContainer/WeeksRow/Wk3"),
    get_node("MarginContainer/VBoxContainer/WeeksRow/Wk4"),
]
# Grab the top header time label
@onready var _meta_label: Label = get_node("/root/Control/ColorRect/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer2/PlayerName/Meta")


# We need to grab the buttons from the nested containers below the calendar
@onready var _next_week_btn: Button = get_node("/root/Control/DepletedOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/NextWeekButton")

@onready var _energy_hud: Control = get_node("/root/Control/ColorRect/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/PanelContainer/CenterMargin/CenterVBox/EnergyHudCard")
@onready var _energy_bar: ProgressBar = get_node("/root/Control/ColorRect/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/PanelContainer/CenterMargin/CenterVBox/EnergyHudCard/MarginContainer/Row/Bar")

@onready var _pause_overlay: Control = get_node("/root/Control/PauseOverlay")
@onready var _pause_resume_button: Button = get_node("/root/Control/PauseOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Buttons/ResumeButton")
@onready var _pause_settings_button: Button = get_node("/root/Control/PauseOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Buttons/SettingsButton")
@onready var _pause_main_menu_button: Button = get_node("/root/Control/PauseOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Buttons/MainMenuButton")

@onready var _settings_overlay: Control = get_node_or_null("/root/Control/SettingsOverlay")
@onready var _settings_back_button: Button = get_node_or_null("/root/Control/SettingsOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HeaderRow/BackButton")
@onready var _settings_tabs: TabContainer = get_node_or_null("/root/Control/SettingsOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer")
@onready var _settings_fullscreen_toggle: CheckButton = get_node_or_null("/root/Control/SettingsOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Display/FullscreenToggle")
@onready var _settings_resolution_dropdown: OptionButton = get_node_or_null("/root/Control/SettingsOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Display/ResolutionRow/ResolutionDropdown")
@onready var _settings_ui_scale_slider: HSlider = get_node_or_null("/root/Control/SettingsOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Display/UIScaleRow/UIScaleSlider")

@onready var _settings_master_slider: HSlider = get_node_or_null("/root/Control/SettingsOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Audio/MasterRow/MasterSlider")
@onready var _settings_music_slider: HSlider = get_node_or_null("/root/Control/SettingsOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Audio/MusicRow/MusicSlider")
@onready var _settings_sfx_slider: HSlider = get_node_or_null("/root/Control/SettingsOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Audio/SfxRow/SfxSlider")
@onready var _settings_ui_sounds_toggle: CheckButton = get_node_or_null("/root/Control/SettingsOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Audio/UISoundsToggle")

@onready var _settings_energy_speed_slider: HSlider = get_node_or_null("/root/Control/SettingsOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Gameplay/EnergyRow/EnergySpeedSlider")
@onready var _settings_energy_speed_value_label: Label = get_node_or_null("/root/Control/SettingsOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Gameplay/EnergyRow/EnergySpeedValueLabel")

@onready var _settings_font_size_dropdown: OptionButton = get_node_or_null("/root/Control/SettingsOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Accessibility/FontSizeRow/FontSizeDropdown")
@onready var _settings_dyslexia_toggle: CheckButton = get_node_or_null("/root/Control/SettingsOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Accessibility/DyslexiaFontToggle")
@onready var _settings_reduce_anim_toggle: CheckButton = get_node_or_null("/root/Control/SettingsOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Accessibility/ReduceAnimationsToggle")
@onready var _settings_colourblind_toggle: CheckButton = get_node_or_null("/root/Control/SettingsOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Accessibility/ColourblindToggle")

@onready var _settings_tooltip_hints_toggle: CheckButton = get_node_or_null("/root/Control/SettingsOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Help/TooltipHintsToggle")
@onready var _settings_reset_tutorial_button: Button = get_node_or_null("/root/Control/SettingsOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Help/ResetTutorialHintsButton")
@onready var _settings_reset_defaults_button: Button = get_node_or_null("/root/Control/SettingsOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Help/ResetDefaultsButton")

@onready var _depleted_overlay: Control = get_node("/root/Control/DepletedOverlay")
@onready var _depleted_panel: Control = get_node("/root/Control/DepletedOverlay/CenterContainer/PanelContainer")

@onready var _week_transition_overlay: ColorRect = get_node_or_null("/root/Control/WeekTransitionOverlay")
@onready var _monthly_recap_overlay: Control = get_node_or_null("/root/Control/MonthlyRecapOverlay")
@onready var _monthly_recap_panel: Control = get_node_or_null("/root/Control/MonthlyRecapOverlay/CenterContainer/PanelContainer")
@onready var _monthly_recap_heading: Label = get_node_or_null("/root/Control/MonthlyRecapOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HeadingLabel")
@onready var _monthly_recap_events_empty: Label = get_node_or_null("/root/Control/MonthlyRecapOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/EventsSection/EventsEmptyLabel")
@onready var _monthly_recap_income_value: Label = get_node_or_null("/root/Control/MonthlyRecapOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/FinancesSection/Grid/IncomeValue")
@onready var _monthly_recap_expenses_value: Label = get_node_or_null("/root/Control/MonthlyRecapOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/FinancesSection/Grid/ExpensesValue")
@onready var _monthly_recap_balance_value: Label = get_node_or_null("/root/Control/MonthlyRecapOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/FinancesSection/Grid/BalanceValue")
@onready var _monthly_recap_stats_empty: Label = get_node_or_null("/root/Control/MonthlyRecapOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsSection/StatsEmptyLabel")
@onready var _monthly_recap_stats_list: VBoxContainer = get_node_or_null("/root/Control/MonthlyRecapOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsSection/StatsList")
@onready var _monthly_recap_continue: Button = get_node_or_null("/root/Control/MonthlyRecapOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContinueButton")

var _settings_manager: Node

func _ready() -> void:
    _root_color_rect = get_node_or_null("/root/Control/ColorRect")
    _settings_manager = get_node_or_null("/root/SettingsManager")

    _energy_timer = Timer.new()
    _apply_energy_timer_settings()
    _energy_timer.autostart = true
    add_child(_energy_timer)
    _energy_timer.timeout.connect(_on_energy_tick)

    _prev_month.pressed.connect(_on_prev_month_pressed)
    _next_month.pressed.connect(_on_next_month_pressed)

    _next_week_btn.pressed.connect(_on_next_week_button_pressed)
    _pause_resume_button.pressed.connect(_on_resume_pressed)
    _pause_settings_button.pressed.connect(_on_pause_settings_pressed)
    _pause_main_menu_button.pressed.connect(_on_pause_main_menu_pressed)
    if _monthly_recap_continue != null:
        _monthly_recap_continue.pressed.connect(_on_monthly_recap_continue_pressed)
    if _settings_back_button != null:
        _settings_back_button.pressed.connect(_on_settings_back_pressed)
    if _settings_reset_tutorial_button != null:
        _settings_reset_tutorial_button.pressed.connect(_on_reset_tutorial_hints_pressed)
    if _settings_reset_defaults_button != null:
        _settings_reset_defaults_button.pressed.connect(_on_reset_defaults_pressed)

    for i in range(_wk_buttons.size()):
        var b := _wk_buttons[i]
        var idx := i + 1
        b.toggled.connect(func(pressed: bool) -> void:
            if pressed:
                week_index = idx
                _update_labels()
        )

    week_index = clampi(week_index, 1, 4)
    month_index = clampi(month_index, 0, 11)
    _update_week_pressed()
    _update_labels()
    
    reset_energy()
    print("Game Started. Energy: ", current_energy)
    _ensure_month_snapshot()

    _init_energy_bar_style()
    _init_settings_overlay_ui()
    if debug_log_energy_ticks or debug_log_energy_run_time:
        print("Energy debug enabled. tick_rate=%.2fs ignore_time_scale=%s time_scale=%.2f" % [_energy_timer.wait_time, str(_energy_timer.ignore_time_scale), Engine.time_scale])

func _process(_delta: float) -> void:
    _apply_energy_timer_settings()

func _apply_energy_timer_settings() -> void:
    if _energy_timer == null:
        return
    if absf(_energy_timer.wait_time - energy_tick_rate) > 0.0001:
        _energy_timer.wait_time = energy_tick_rate
    if _energy_timer.ignore_time_scale != ignore_time_scale:
        _energy_timer.ignore_time_scale = ignore_time_scale

func _init_settings_overlay_ui() -> void:
    if _settings_manager == null:
        return

    if _settings_manager.has_signal("setting_changed"):
        if not _settings_manager.is_connected("setting_changed", Callable(self, "_on_setting_changed")):
            _settings_manager.connect("setting_changed", Callable(self, "_on_setting_changed"))

    var drain_speed := float(_settings_manager.call("get_value", "gameplay", "energy_drain_speed", 0.40))
    energy_tick_rate = clampf(drain_speed, 0.1, 1.0)
    _apply_energy_timer_settings()

    if _settings_fullscreen_toggle != null:
        var fullscreen := bool(_settings_manager.call("get_value", "display", "fullscreen", false))
        _settings_fullscreen_toggle.button_pressed = fullscreen
        if _settings_resolution_dropdown != null:
            _settings_resolution_dropdown.disabled = fullscreen
        if not _settings_fullscreen_toggle.toggled.is_connected(_on_settings_fullscreen_toggled):
            _settings_fullscreen_toggle.toggled.connect(_on_settings_fullscreen_toggled)

    if _settings_resolution_dropdown != null:
        _settings_resolution_dropdown.clear()
        var resolutions: Array[String] = ["1280x720", "1600x900", "1920x1080", "2560x1440"]
        for r in resolutions:
            _settings_resolution_dropdown.add_item(r)
        var res_value := str(_settings_manager.call("get_value", "display", "resolution", "1280x720"))
        var idx := resolutions.find(res_value)
        if idx < 0:
            idx = 0
        _settings_resolution_dropdown.select(idx)
        if not _settings_resolution_dropdown.item_selected.is_connected(_on_settings_resolution_selected):
            _settings_resolution_dropdown.item_selected.connect(_on_settings_resolution_selected)

    if _settings_ui_scale_slider != null:
        var ui_scale_bounds: Vector2 = _settings_manager.call("_get_ui_scale_bounds") as Vector2
        _settings_ui_scale_slider.min_value = ui_scale_bounds.x
        _settings_ui_scale_slider.max_value = ui_scale_bounds.y
        _settings_ui_scale_slider.value = clampf(float(_settings_manager.call("get_value", "display", "ui_scale", 1.0)), ui_scale_bounds.x, ui_scale_bounds.y)
        if not _settings_ui_scale_slider.value_changed.is_connected(_on_settings_ui_scale_changed):
            _settings_ui_scale_slider.value_changed.connect(_on_settings_ui_scale_changed)

    if _settings_master_slider != null:
        _settings_master_slider.value = float(_settings_manager.call("get_value", "audio", "master", 100))
        if not _settings_master_slider.value_changed.is_connected(_on_settings_master_changed):
            _settings_master_slider.value_changed.connect(_on_settings_master_changed)
    if _settings_music_slider != null:
        _settings_music_slider.value = float(_settings_manager.call("get_value", "audio", "music", 80))
        if not _settings_music_slider.value_changed.is_connected(_on_settings_music_changed):
            _settings_music_slider.value_changed.connect(_on_settings_music_changed)
    if _settings_sfx_slider != null:
        _settings_sfx_slider.value = float(_settings_manager.call("get_value", "audio", "sfx", 80))
        if not _settings_sfx_slider.value_changed.is_connected(_on_settings_sfx_changed):
            _settings_sfx_slider.value_changed.connect(_on_settings_sfx_changed)
    if _settings_ui_sounds_toggle != null:
        _settings_ui_sounds_toggle.button_pressed = bool(_settings_manager.call("get_value", "audio", "ui_sounds", true))
        if not _settings_ui_sounds_toggle.toggled.is_connected(_on_settings_ui_sounds_toggled):
            _settings_ui_sounds_toggle.toggled.connect(_on_settings_ui_sounds_toggled)

    if _settings_energy_speed_slider != null:
        _settings_energy_speed_slider.value = energy_tick_rate
        if not _settings_energy_speed_slider.value_changed.is_connected(_on_settings_energy_speed_changed):
            _settings_energy_speed_slider.value_changed.connect(_on_settings_energy_speed_changed)
    _update_energy_speed_value_label()

    if _settings_font_size_dropdown != null:
        _settings_font_size_dropdown.clear()
        _settings_font_size_dropdown.add_item("Small")
        _settings_font_size_dropdown.add_item("Medium")
        _settings_font_size_dropdown.add_item("Large")
        var font_size_key := str(_settings_manager.call("get_value", "accessibility", "font_size", "medium"))
        var font_idx := 1
        if font_size_key == "small":
            font_idx = 0
        elif font_size_key == "large":
            font_idx = 2
        _settings_font_size_dropdown.select(font_idx)
        if not _settings_font_size_dropdown.item_selected.is_connected(_on_settings_font_size_selected):
            _settings_font_size_dropdown.item_selected.connect(_on_settings_font_size_selected)

    if _settings_dyslexia_toggle != null:
        _settings_dyslexia_toggle.button_pressed = bool(_settings_manager.call("get_value", "accessibility", "dyslexia_font", false))
        if not _settings_dyslexia_toggle.toggled.is_connected(_on_settings_dyslexia_toggled):
            _settings_dyslexia_toggle.toggled.connect(_on_settings_dyslexia_toggled)

    if _settings_reduce_anim_toggle != null:
        _settings_reduce_anim_toggle.button_pressed = bool(_settings_manager.call("get_value", "accessibility", "reduce_animations", false))
        if not _settings_reduce_anim_toggle.toggled.is_connected(_on_settings_reduce_animations_toggled):
            _settings_reduce_anim_toggle.toggled.connect(_on_settings_reduce_animations_toggled)

    if _settings_colourblind_toggle != null:
        _settings_colourblind_toggle.button_pressed = bool(_settings_manager.call("get_value", "accessibility", "colourblind_mode", false))
        if not _settings_colourblind_toggle.toggled.is_connected(_on_settings_colourblind_toggled):
            _settings_colourblind_toggle.toggled.connect(_on_settings_colourblind_toggled)

    if _settings_tooltip_hints_toggle != null:
        _settings_tooltip_hints_toggle.button_pressed = bool(_settings_manager.call("get_value", "help", "tooltip_hints", true))
        if not _settings_tooltip_hints_toggle.toggled.is_connected(_on_settings_tooltip_hints_toggled):
            _settings_tooltip_hints_toggle.toggled.connect(_on_settings_tooltip_hints_toggled)

func _on_setting_changed(section: String, key: String, value: Variant) -> void:
    if section == "gameplay" and key == "energy_drain_speed":
        energy_tick_rate = clampf(float(value), 0.1, 1.0)
        if _settings_energy_speed_slider != null:
            _settings_energy_speed_slider.value = energy_tick_rate
        _update_energy_speed_value_label()
        _apply_energy_timer_settings()

func _on_settings_fullscreen_toggled(pressed: bool) -> void:
    if _settings_manager != null:
        _settings_manager.call("set_value", "display", "fullscreen", pressed)
    if _settings_resolution_dropdown != null:
        _settings_resolution_dropdown.disabled = pressed
    _refresh_ui_scale_slider_bounds()

func _on_settings_resolution_selected(index: int) -> void:
    if _settings_manager == null or _settings_resolution_dropdown == null:
        return
    var txt := _settings_resolution_dropdown.get_item_text(index)
    _settings_manager.call("set_value", "display", "resolution", txt)
    _refresh_ui_scale_slider_bounds()

func _on_settings_ui_scale_changed(v: float) -> void:
    if _settings_manager == null:
        return
    var bounds: Vector2 = _settings_manager.call("_get_ui_scale_bounds") as Vector2
    var clamped := clampf(v, bounds.x, bounds.y)
    if _settings_ui_scale_slider != null and absf(_settings_ui_scale_slider.value - clamped) > 0.0001:
        _settings_ui_scale_slider.value = clamped
    _settings_manager.call("set_value", "display", "ui_scale", clamped)

func _refresh_ui_scale_slider_bounds() -> void:
    if _settings_manager == null or _settings_ui_scale_slider == null:
        return
    var bounds: Vector2 = _settings_manager.call("_get_ui_scale_bounds") as Vector2
    _settings_ui_scale_slider.min_value = bounds.x
    _settings_ui_scale_slider.max_value = bounds.y
    _settings_ui_scale_slider.value = clampf(_settings_ui_scale_slider.value, bounds.x, bounds.y)

func _on_settings_master_changed(v: float) -> void:
    if _settings_manager != null:
        _settings_manager.call("set_value", "audio", "master", int(round(v)))

func _on_settings_music_changed(v: float) -> void:
    if _settings_manager != null:
        _settings_manager.call("set_value", "audio", "music", int(round(v)))

func _on_settings_sfx_changed(v: float) -> void:
    if _settings_manager != null:
        _settings_manager.call("set_value", "audio", "sfx", int(round(v)))

func _on_settings_ui_sounds_toggled(pressed: bool) -> void:
    if _settings_manager != null:
        _settings_manager.call("set_value", "audio", "ui_sounds", pressed)

func _on_settings_energy_speed_changed(v: float) -> void:
    energy_tick_rate = clampf(v, 0.1, 1.0)
    _apply_energy_timer_settings()
    _update_energy_speed_value_label()
    if _settings_manager != null:
        _settings_manager.call("set_value", "gameplay", "energy_drain_speed", v)

func _update_energy_speed_value_label() -> void:
    if _settings_energy_speed_value_label == null:
        return
    var seconds_per_week := float(max_energy) * float(energy_tick_rate)
    _settings_energy_speed_value_label.text = "%.1fs per week" % seconds_per_week

func _on_settings_font_size_selected(index: int) -> void:
    if _settings_manager == null:
        return
    var key := "medium"
    if index == 0:
        key = "small"
    elif index == 2:
        key = "large"
    _settings_manager.call("set_value", "accessibility", "font_size", key)

func _on_settings_dyslexia_toggled(pressed: bool) -> void:
    if _settings_manager != null:
        _settings_manager.call("set_value", "accessibility", "dyslexia_font", pressed)

func _on_settings_reduce_animations_toggled(pressed: bool) -> void:
    if _settings_manager != null:
        _settings_manager.call("set_value", "accessibility", "reduce_animations", pressed)

func _on_settings_colourblind_toggled(pressed: bool) -> void:
    if _settings_manager != null:
        _settings_manager.call("set_value", "accessibility", "colourblind_mode", pressed)

func _on_settings_tooltip_hints_toggled(pressed: bool) -> void:
    if _settings_manager != null:
        _settings_manager.call("set_value", "help", "tooltip_hints", pressed)

func set_player_info(name: String, age: int) -> void:
    _player_name = name.strip_edges()
    _player_age = age
    _update_labels()
    _ensure_month_snapshot()

func set_time(new_year: int, new_month_index: int, new_week_index: int) -> void:
    year = new_year
    month_index = clampi(new_month_index, 0, 11)
    week_index = clampi(new_week_index, 1, 4)
    _update_week_pressed()
    _update_labels()
    _ensure_month_snapshot()

func open_pause_menu() -> void:
    set_energy_paused(true)
    if _pause_overlay != null:
        _pause_overlay.visible = true

func close_pause_menu() -> void:
    if _settings_overlay != null:
        _settings_overlay.visible = false
    set_energy_paused(false)
    if _pause_overlay != null:
        _pause_overlay.visible = false

func toggle_pause_menu() -> void:
    var paused_now := _energy_timer != null and _energy_timer.paused
    if paused_now:
        close_pause_menu()
    else:
        open_pause_menu()

func toggle_pause() -> void:
    toggle_pause_menu()

func open_settings_overlay() -> void:
    if _settings_overlay == null:
        return
    _settings_overlay.visible = true
    set_energy_paused(true)

func close_settings_overlay() -> void:
    if _settings_overlay == null:
        return
    _settings_overlay.visible = false

# --- INPUT HANDLING ---
func _input(event: InputEvent) -> void:
    if _depleted_overlay.visible:
        if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE and _next_week_btn.visible:
            _on_next_week_button_pressed()
        return

    if _monthly_recap_overlay != null and _monthly_recap_overlay.visible:
        if event.is_action_pressed("ui_cancel"):
            _dismiss_monthly_recap()
        return

    if event.is_action_pressed("ui_cancel"):
        if _settings_overlay != null and _settings_overlay.visible:
            close_settings_overlay()
            return
        toggle_pause_menu()
        return

    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_SPACE and _next_week_btn.visible:
            _on_next_week_button_pressed()
        elif event.keycode == KEY_ENTER:
            attempt_action()

func _on_resume_pressed() -> void:
    close_pause_menu()

func _on_pause_settings_pressed() -> void:
    open_settings_overlay()

func _on_pause_main_menu_pressed() -> void:
    set_energy_paused(true)
    SaveGame.autosave(_get_player_data(), self)
    if _pause_overlay != null:
        _pause_overlay.visible = false
    if _settings_overlay != null:
        _settings_overlay.visible = false
    if SceneTransitions != null:
        SceneTransitions.go_to("res://scenes/main/MainMenu.tscn")

func _on_settings_back_pressed() -> void:
    close_settings_overlay()

func _on_reset_tutorial_hints_pressed() -> void:
    if _settings_manager != null and _settings_manager.has_method("reset_tutorial_hints"):
        _settings_manager.call("reset_tutorial_hints")

func _on_reset_defaults_pressed() -> void:
    if _settings_manager != null and _settings_manager.has_method("reset_to_defaults"):
        _settings_manager.call("reset_to_defaults")
        _init_settings_overlay_ui()

func _on_next_week_button_pressed() -> void:
    await _advance_week_with_transition()

func _on_monthly_recap_continue_pressed() -> void:
    _dismiss_monthly_recap()

func _advance_week_with_transition() -> void:
    var old_year := year
    var old_month_index := month_index

    if _week_transition_overlay == null:
        advance_time(1)
        if year != old_year or month_index != old_month_index:
            _show_monthly_recap(old_year, old_month_index)
        return

    _week_transition_overlay.visible = true
    _week_transition_overlay.modulate.a = 0.0
    var out_tween := create_tween()
    out_tween.set_trans(Tween.TRANS_SINE)
    out_tween.set_ease(Tween.EASE_IN_OUT)
    out_tween.tween_property(_week_transition_overlay, "modulate:a", 1.0, 0.18)
    await out_tween.finished

    advance_time(1)

    if year != old_year or month_index != old_month_index:
        _show_monthly_recap(old_year, old_month_index)
        return

    var in_tween := create_tween()
    in_tween.set_trans(Tween.TRANS_SINE)
    in_tween.set_ease(Tween.EASE_IN_OUT)
    in_tween.tween_property(_week_transition_overlay, "modulate:a", 0.0, 0.18)
    await in_tween.finished
    _week_transition_overlay.visible = false

func _show_monthly_recap(prev_year: int, prev_month_index: int) -> void:
    if _monthly_recap_overlay == null:
        return
    if _pause_overlay != null:
        _pause_overlay.visible = false
    if _settings_overlay != null:
        _settings_overlay.visible = false
    if _depleted_overlay != null:
        _depleted_overlay.visible = false

    _monthly_recap_overlay.visible = true
    _monthly_recap_overlay.modulate.a = 0.0
    if _monthly_recap_panel != null:
        _monthly_recap_panel.pivot_offset = _monthly_recap_panel.size * 0.5
        _monthly_recap_panel.scale = Vector2.ONE * 0.96
        _monthly_recap_panel.modulate.a = 0.0
    set_energy_paused(true)

    var show_tween := create_tween()
    show_tween.set_trans(Tween.TRANS_SINE)
    show_tween.set_ease(Tween.EASE_IN_OUT)
    show_tween.set_parallel(true)
    show_tween.tween_property(_monthly_recap_overlay, "modulate:a", 1.0, 0.16)
    if _monthly_recap_panel != null:
        show_tween.tween_property(_monthly_recap_panel, "modulate:a", 1.0, 0.16)
        show_tween.tween_property(_monthly_recap_panel, "scale", Vector2.ONE, 0.2)
    if _week_transition_overlay != null and _week_transition_overlay.visible:
        show_tween.tween_property(_week_transition_overlay, "modulate:a", 0.0, 0.16)
        show_tween.finished.connect(func() -> void:
            if _week_transition_overlay != null:
                _week_transition_overlay.visible = false
        )

    var heading_month := MONTH_NAMES_FULL[clampi(prev_month_index, 0, 11)]
    if _monthly_recap_heading != null:
        _monthly_recap_heading.text = "%s %d" % [heading_month, prev_year]

    if _monthly_recap_events_empty != null:
        _monthly_recap_events_empty.visible = true

    var player_data := _get_player_data()
    var income: float = 0.0
    var balance: float = 0.0
    if player_data != null:
        balance = player_data.bank_balance
        if player_data.current_job != null:
            income = player_data.current_job.salary / 12.0

    if _monthly_recap_income_value != null:
        _monthly_recap_income_value.text = _format_money(income)
    if _monthly_recap_expenses_value != null:
        _monthly_recap_expenses_value.text = _format_money(0.0)
    if _monthly_recap_balance_value != null:
        _monthly_recap_balance_value.text = _format_money(balance)

    _populate_monthly_stat_changes(player_data)

func _dismiss_monthly_recap() -> void:
    if _monthly_recap_overlay == null or not _monthly_recap_overlay.visible:
        return
    _monthly_recap_overlay.modulate.a = 1.0
    _monthly_recap_overlay.visible = false
    _capture_month_snapshot()
    set_energy_paused(false)

    if _week_transition_overlay != null and _week_transition_overlay.visible:
        var in_tween := create_tween()
        in_tween.set_trans(Tween.TRANS_SINE)
        in_tween.set_ease(Tween.EASE_IN_OUT)
        in_tween.tween_property(_week_transition_overlay, "modulate:a", 0.0, 0.18)
        in_tween.finished.connect(func() -> void:
            if _week_transition_overlay != null:
                _week_transition_overlay.visible = false
        )

func _populate_monthly_stat_changes(player_data: PeopleResource) -> void:
    if _monthly_recap_stats_list != null:
        for c in _monthly_recap_stats_list.get_children():
            c.queue_free()

    if player_data == null or _month_start_stats.is_empty():
        if _monthly_recap_stats_empty != null:
            _monthly_recap_stats_empty.visible = true
        if _monthly_recap_stats_list != null:
            _monthly_recap_stats_list.visible = false
        return

    var deltas: Array[String] = []
    deltas.append_array(_stat_delta_lines("Health", player_data.Health))
    deltas.append_array(_stat_delta_lines("Happiness", player_data.Happiness))
    deltas.append_array(_stat_delta_lines("Smarts", player_data.Smarts))
    deltas.append_array(_stat_delta_lines("Looks", player_data.Looks))
    deltas.append_array(_stat_delta_lines("Fitness", player_data.Fitness))
    deltas.append_array(_stat_delta_lines("Stress", player_data.Stress))

    if deltas.is_empty():
        if _monthly_recap_stats_empty != null:
            _monthly_recap_stats_empty.visible = true
        if _monthly_recap_stats_list != null:
            _monthly_recap_stats_list.visible = false
        return

    if _monthly_recap_stats_empty != null:
        _monthly_recap_stats_empty.visible = false
    if _monthly_recap_stats_list != null:
        _monthly_recap_stats_list.visible = true
        for line in deltas:
            var l := Label.new()
            l.text = line
            _monthly_recap_stats_list.add_child(l)

func _stat_delta_lines(stat_name: String, current_value: float) -> Array[String]:
    if not _month_start_stats.has(stat_name):
        return []
    var start_value := float(_month_start_stats[stat_name])
    var delta := int(round(current_value - start_value))
    if delta == 0:
        return []
    return ["%s %s" % [("%+d" % delta), stat_name]]

func _ensure_month_snapshot() -> void:
    if _month_start_year >= 0 and _month_start_month_index >= 0:
        return
    _capture_month_snapshot()

func _capture_month_snapshot() -> void:
    var player_data := _get_player_data()
    if player_data == null:
        return
    _month_start_year = year
    _month_start_month_index = month_index
    _month_start_stats = {
        "Health": player_data.Health,
        "Happiness": player_data.Happiness,
        "Smarts": player_data.Smarts,
        "Looks": player_data.Looks,
        "Fitness": player_data.Fitness,
        "Stress": player_data.Stress,
    }

func _get_player_data() -> PeopleResource:
    var root := get_node_or_null("/root/Control")
    if root == null:
        return null
    var pd: PeopleResource = root.get("player_data") as PeopleResource
    return pd

func _format_money(amount: float) -> String:
    var is_negative := amount < 0.0
    var n := int(round(absf(amount)))
    var s := str(n)
    var formatted: String = ""
    var group_len := 0
    for i in range(s.length() - 1, -1, -1):
        formatted = s.substr(i, 1) + formatted
        group_len += 1
        if group_len == 3 and i != 0:
            formatted = "," + formatted
            group_len = 0
    if is_negative:
        return "-$%s" % formatted
    return "$%s" % formatted

# --- ENERGY SYSTEM ---
func _on_energy_tick() -> void:
    var now_msec := Time.get_ticks_msec()
    if _drain_start_msec < 0:
        _drain_start_msec = now_msec
        _drain_last_tick_msec = now_msec
        _drain_active_elapsed_msec = 0
        _drain_paused_at_msec = -1
        _drain_start_energy = current_energy
        _drain_tick_count = 0
        if max_energy > 0:
            _debug_last_percent_bucket = int(ceil((float(current_energy) / float(max_energy)) * 10.0))
        else:
            _debug_last_percent_bucket = 0

    if current_energy <= 0:
        current_energy = 0
        _update_energy_ui()
        _energy_timer.stop()
        _on_energy_depleted()
        return

    var prev_tick_msec := _drain_last_tick_msec
    var delta_msec := 0
    if prev_tick_msec >= 0:
        delta_msec = now_msec - prev_tick_msec
        _drain_active_elapsed_msec += delta_msec
    _drain_last_tick_msec = now_msec

    _drain_tick_count += 1
    current_energy = maxi(0, current_energy - 1)
    _update_energy_ui()
    if debug_log_energy_ticks:
        var wall_seconds := float(now_msec - _drain_start_msec) / 1000.0
        var active_seconds := float(_drain_active_elapsed_msec) / 1000.0
        var dt_seconds := float(delta_msec) / 1000.0
        var bucket := 0
        if max_energy > 0:
            bucket = int(ceil((float(current_energy) / float(max_energy)) * 10.0))
        var pct := bucket * 10
        if bucket < _debug_last_percent_bucket:
            print("Energy drain | %d%% | tick#%d | %d/%d | dt=%.3fs | wall=%.2fs | active=%.2fs | rate=%.2fs | ignore_ts=%s | time_scale=%.2f | paused=%s" % [pct, _drain_tick_count, current_energy, max_energy, dt_seconds, wall_seconds, active_seconds, _energy_timer.wait_time, str(_energy_timer.ignore_time_scale), Engine.time_scale, str(_energy_timer.paused)])
            _debug_last_percent_bucket = bucket

    if current_energy == 0:
        _energy_timer.stop()
        _on_energy_depleted()

func set_energy_paused(is_paused: bool) -> void:
    if _energy_timer == null:
        return
    _energy_timer.paused = is_paused
    var now_msec := Time.get_ticks_msec()
    if is_paused:
        if _drain_paused_at_msec < 0:
            _drain_paused_at_msec = now_msec
    else:
        if _drain_paused_at_msec >= 0:
            _drain_paused_at_msec = -1
            _drain_last_tick_msec = now_msec
    if not is_paused and current_energy > 0 and _energy_timer.is_stopped():
        _energy_timer.start()
    if debug_log_energy_ticks:
        print("Energy timer %s. Energy: %d/%d" % [("paused" if is_paused else "resumed"), current_energy, max_energy])

func _on_energy_depleted() -> void:
    if _energy_hud != null:
        _energy_hud.visible = false
    if _depleted_overlay != null:
        _depleted_overlay.visible = true
    if _next_week_btn != null:
        _next_week_btn.visible = true
    if _depleted_panel != null:
        _depleted_panel.pivot_offset = _depleted_panel.size * 0.5
        _depleted_panel.scale = Vector2.ONE * 0.92
        _depleted_panel.modulate.a = 0.0
        var t := create_tween()
        t.set_trans(Tween.TRANS_QUAD)
        t.set_ease(Tween.EASE_OUT)
        t.set_parallel(true)
        t.tween_property(_depleted_panel, "modulate:a", 1.0, 0.14)
        t.tween_property(_depleted_panel, "scale", Vector2.ONE, 0.18)

    if debug_log_energy_run_time and _drain_start_msec >= 0:
        var end_msec := Time.get_ticks_msec()
        var wall_seconds := float(end_msec - _drain_start_msec) / 1000.0
        var active_seconds := float(_drain_active_elapsed_msec) / 1000.0
        print("Energy depleted: %d -> 0. Wall: %.2fs Active: %.2fs (tick_rate=%.2fs ignore_time_scale=%s time_scale=%.2f)" % [_drain_start_energy, wall_seconds, active_seconds, _energy_timer.wait_time, str(_energy_timer.ignore_time_scale), Engine.time_scale])

    if _root_color_rect == null:
        return

    if _depleted_tween != null:
        _depleted_tween.kill()
    _root_color_rect.position = Vector2.ZERO

    _depleted_tween = create_tween()
    _depleted_tween.set_trans(Tween.TRANS_SINE)
    _depleted_tween.set_ease(Tween.EASE_OUT)

    var shake_px := 6.0
    _depleted_tween.tween_property(_root_color_rect, "position", Vector2(-shake_px, 0), 0.03)
    _depleted_tween.tween_property(_root_color_rect, "position", Vector2(shake_px, 0), 0.03)
    _depleted_tween.tween_property(_root_color_rect, "position", Vector2(-shake_px * 0.8, 0), 0.03)
    _depleted_tween.tween_property(_root_color_rect, "position", Vector2(shake_px * 0.8, 0), 0.03)
    _depleted_tween.tween_property(_root_color_rect, "position", Vector2(-shake_px * 0.6, 0), 0.03)
    _depleted_tween.tween_property(_root_color_rect, "position", Vector2(shake_px * 0.6, 0), 0.03)
    _depleted_tween.tween_property(_root_color_rect, "position", Vector2.ZERO, 0.02)

func attempt_action() -> bool:
    if current_energy > 0:
        return true
    _micro_shake()
    return false

func _micro_shake() -> void:
    if _root_color_rect == null:
        return
    if _micro_shake_tween != null:
        _micro_shake_tween.kill()
    _root_color_rect.position = Vector2.ZERO
    _micro_shake_tween = create_tween()
    _micro_shake_tween.set_trans(Tween.TRANS_SINE)
    _micro_shake_tween.set_ease(Tween.EASE_OUT)
    _micro_shake_tween.tween_property(_root_color_rect, "position", Vector2(-3, 0), 0.03)
    _micro_shake_tween.tween_property(_root_color_rect, "position", Vector2(3, 0), 0.03)
    _micro_shake_tween.tween_property(_root_color_rect, "position", Vector2.ZERO, 0.04)

func _init_energy_bar_style() -> void:
    if _energy_bar == null:
        return
    _energy_bar.step = 0.001
    var fill := _energy_bar.get_theme_stylebox("fill", "ProgressBar")
    if fill == null or not (fill is StyleBoxFlat):
        return
    _energy_fill_style = (fill as StyleBoxFlat).duplicate()
    _energy_fill_normal_color = _energy_fill_style.bg_color
    _energy_bar.add_theme_stylebox_override("fill", _energy_fill_style)
    _tween_energy_bar_color(false)

func _tween_energy_bar_color(animated: bool) -> void:
    if _energy_fill_style == null:
        return
    if max_energy <= 0:
        return

    var ratio := clampf(float(current_energy) / float(max_energy), 0.0, 1.0)
    var t := 1.0 - ratio
    var target := _energy_fill_normal_color.lerp(_DANGER_RED, t)

    if _energy_color_tween != null:
        _energy_color_tween.kill()

    if not animated:
        _energy_fill_style.bg_color = target
        return

    _energy_color_tween = create_tween()
    _energy_color_tween.set_trans(Tween.TRANS_SINE)
    _energy_color_tween.set_ease(Tween.EASE_IN_OUT)
    _energy_color_tween.tween_property(_energy_fill_style, "bg_color", target, 0.18)

func reset_energy() -> void:
    current_energy = max_energy
    _update_energy_ui(false)
    if _energy_hud != null:
        _energy_hud.visible = true
    if _next_week_btn != null:
        _next_week_btn.visible = false
    if _depleted_overlay != null:
        _depleted_overlay.visible = false
    var now_msec := Time.get_ticks_msec()
    _drain_start_msec = now_msec
    _drain_last_tick_msec = now_msec
    _drain_active_elapsed_msec = 0
    _drain_paused_at_msec = -1
    _drain_start_energy = current_energy
    _drain_tick_count = 0
    if max_energy > 0:
        _debug_last_percent_bucket = int(ceil((float(current_energy) / float(max_energy)) * 10.0))
    else:
        _debug_last_percent_bucket = 0
    if _energy_timer != null:
        _apply_energy_timer_settings()
        _energy_timer.paused = false
        _energy_timer.start()
    if debug_log_energy_run_time:
        print("Energy run started: %d -> 0 (rate=%.2fs ignore_time_scale=%s time_scale=%.2f)" % [current_energy, _energy_timer.wait_time, str(_energy_timer.ignore_time_scale), Engine.time_scale])

func _update_energy_ui(animate_value: bool = true) -> void:
    if _energy_bar:
        _energy_bar.max_value = max_energy
        if _energy_value_tween != null:
            _energy_value_tween.kill()

        if not animate_value:
            _energy_bar.value = current_energy
        else:
            var duration: float = maxf(0.05, energy_tick_rate)
            _energy_value_tween = create_tween()
            _energy_value_tween.set_trans(Tween.TRANS_LINEAR)
            _energy_value_tween.set_ease(Tween.EASE_OUT)
            if _energy_value_tween.has_method("set_ignore_time_scale"):
                _energy_value_tween.call("set_ignore_time_scale", ignore_time_scale)
            _energy_value_tween.tween_property(_energy_bar, "value", float(current_energy), duration)
    _tween_energy_bar_color(true)

# --- TIME SYSTEM ---
func advance_time(weeks_to_skip: int) -> void:
    for i in range(weeks_to_skip):
        _process_single_week()
    
    _update_week_pressed()
    _update_labels()

func _process_single_week() -> void:
    # Reset energy at the start of a new week
    reset_energy()
    
    week_index += 1
    if week_index > 4:
        week_index = 1
        month_index += 1
        
        if month_index > 11:
            month_index = 0
            year += 1

# For your popup when you add it
func advance_custom_time(amount: int, time_scale_index: int) -> void:
    var weeks: int = 0
    match time_scale_index:
        0: weeks = amount       # Weeks
        1: weeks = amount * 4   # Months
        2: weeks = amount * 48  # Years
    
    advance_time(weeks)

# --- EXISTING UI LOGIC ---
func _on_prev_month_pressed() -> void:
    month_index -= 1
    if month_index < 0:
        month_index = 11
        year -= 1
    _reset_week_to_one()
    _update_labels()

func _on_next_month_pressed() -> void:
    month_index += 1
    if month_index > 11:
        month_index = 0
        year += 1
    _reset_week_to_one()
    _update_labels()

func _reset_week_to_one() -> void:
    week_index = 1
    _update_week_pressed()

func _update_week_pressed() -> void:
    var target: int = clampi(week_index, 1, 4)
    for i in range(_wk_buttons.size()):
        _wk_buttons[i].button_pressed = (i + 1) == target

func _update_labels() -> void:
    var mi: int = clampi(month_index, 0, 11)
    var wi: int = clampi(week_index, 1, 4)
    var month: String = MONTH_NAMES[mi]
    
    _month_label.text = "%s %d" % [month, year]
    _helper.text = "%s  •  Wk%d" % [month, wi]
    if _meta_label != null and not _player_name.is_empty():
        _meta_label.text = "%s  •  🗓  Age: %d  •  Year: %d / Month: %s / Week: %d" % [_player_name, _player_age, year, month, wi]
