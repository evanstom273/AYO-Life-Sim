extends PanelContainer

const MONTH_NAMES: Array[String] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
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
var _energy_timer: Timer
var _energy_value_tween: Tween
var _energy_color_tween: Tween
var _energy_fill_style: StyleBoxFlat
var _energy_fill_normal_color: Color
var _root_color_rect: Control
var _depleted_tween: Tween
var _micro_shake_tween: Tween

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
@onready var _resume_button: Button = get_node("/root/Control/PauseOverlay/CenterContainer/VBoxContainer/ResumeButton")
@onready var _depleted_overlay: Control = get_node("/root/Control/DepletedOverlay")
@onready var _depleted_panel: Control = get_node("/root/Control/DepletedOverlay/CenterContainer/PanelContainer")

func _ready() -> void:
    _root_color_rect = get_node_or_null("/root/Control/ColorRect")

    _energy_timer = Timer.new()
    _apply_energy_timer_settings()
    _energy_timer.autostart = true
    add_child(_energy_timer)
    _energy_timer.timeout.connect(_on_energy_tick)

    _prev_month.pressed.connect(_on_prev_month_pressed)
    _next_month.pressed.connect(_on_next_month_pressed)

    _next_week_btn.pressed.connect(_on_next_week_button_pressed)
    _resume_button.pressed.connect(_on_resume_pressed)

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

    _init_energy_bar_style()
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

# --- INPUT HANDLING ---
func _input(event: InputEvent) -> void:
    if _depleted_overlay.visible:
        if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE and _next_week_btn.visible:
            _on_next_week_button_pressed()
        return

    if event.is_action_pressed("ui_cancel"):
        var new_paused := not (_energy_timer != null and _energy_timer.paused)
        set_energy_paused(new_paused)
        _pause_overlay.visible = new_paused
        return

    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_SPACE and _next_week_btn.visible:
            _on_next_week_button_pressed()
        elif event.keycode == KEY_ENTER:
            attempt_action()

func _on_resume_pressed() -> void:
    set_energy_paused(false)
    _pause_overlay.visible = false

func _on_next_week_button_pressed() -> void:
    advance_time(1)

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
    
    # --- ADD THIS ---
    # We format the string exactly like your screenshot, upper-casing the month
    if _meta_label:
        # Keep "ADAM JOHNSON  •  🗓  Age: 24  •  " at the start, but update the time dynamically!
        _meta_label.text = "ADAM JOHNSON  •  🗓  Age: 24  •  Year: %d / Month: %s / Week: %d" % [year, month, wi]
