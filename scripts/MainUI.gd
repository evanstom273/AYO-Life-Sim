extends Control

enum Section {
    OVERVIEW,
    RELATIONSHIPS,
    CAREER,
    EDUCATION,
    HEALTH,
    FINANCES,
    ASSETS,
    ACTIVITIES,
    HISTORY,
}

const SECTION_TITLES := {
    Section.OVERVIEW: "Life Log",
    Section.RELATIONSHIPS: "Relationships",
    Section.CAREER: "Career",
    Section.EDUCATION: "Education",
    Section.HEALTH: "Health",
    Section.FINANCES: "Finances",
    Section.ASSETS: "Assets",
    Section.ACTIVITIES: "Activities",
    Section.HISTORY: "History",
}

@onready var _content_tabs: TabContainer = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/PanelContainer/CenterMargin/CenterVBox/ContentTabs
@onready var _header_title: Label = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/PanelContainer/CenterMargin/CenterVBox/Header/Title
@onready var _filters_button: Control = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/PanelContainer/CenterMargin/CenterVBox/Header/FiltersButton
@onready var _overview_scroll: Control = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/PanelContainer/CenterMargin/CenterVBox/ScrollContainer
@onready var _overview_show_more: Control = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/PanelContainer/CenterMargin/CenterVBox/ShowMoreContainer
@onready var _overview_bottom_row: Control = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/PanelContainer/CenterMargin/CenterVBox/HBoxContainer
@onready var _right_separator: Control = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/VSeparator2
@onready var _right_bar: Control = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar

@onready var _nav_buttons := {
    Section.OVERVIEW: $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Home,
    Section.RELATIONSHIPS: $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Relationships,
    Section.CAREER: $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Career,
    Section.EDUCATION: $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Education,
    Section.HEALTH: $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Health,
    Section.FINANCES: $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Finances,
    Section.ASSETS: $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Assets,
    Section.ACTIVITIES: $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Activities,
    Section.HISTORY: $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/History,
}

func _ready() -> void:
    for section in _nav_buttons.keys():
        var btn: BaseButton = _nav_buttons[section]
        if not btn.toggled.is_connected(_on_nav_toggled.bind(section)):
            btn.toggled.connect(_on_nav_toggled.bind(section))

    var initial_section := _get_pressed_section()
    _set_section(initial_section)

func _on_nav_toggled(pressed: bool, section: int) -> void:
    if not pressed:
        return
    _set_section(section)

func _get_pressed_section() -> int:
    for section in _nav_buttons.keys():
        var btn: BaseButton = _nav_buttons[section]
        if btn.button_pressed:
            return section
    return Section.OVERVIEW

func _set_section(section: int) -> void:
    var is_overview := section == Section.OVERVIEW

    _overview_scroll.visible = is_overview
    _overview_show_more.visible = is_overview
    _overview_bottom_row.visible = is_overview
    _content_tabs.visible = not is_overview

    if not is_overview:
        var tab_index := section
        if tab_index < 0 or tab_index >= _content_tabs.get_tab_count():
            tab_index = 0
        _content_tabs.current_tab = tab_index

    _header_title.text = SECTION_TITLES.get(section, "Life Log")
    _filters_button.visible = is_overview
    _right_separator.visible = is_overview
    _right_bar.visible = is_overview
