extends PanelContainer

const MONTH_NAMES: Array[String] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

@export var year: int = 2025
@export_range(0, 11, 1) var month_index: int = 0
@export_range(1, 4, 1) var week_index: int = 1

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

func _ready() -> void:
    _prev_month.pressed.connect(_on_prev_month_pressed)
    _next_month.pressed.connect(_on_next_month_pressed)

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
