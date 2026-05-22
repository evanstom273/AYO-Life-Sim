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

@export var player_data: PeopleResource

@onready var _content_tabs: TabContainer = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/PanelContainer/CenterMargin/CenterVBox/ContentTabs
@onready var _header_title: Label = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/PanelContainer/CenterMargin/CenterVBox/Header/Title
@onready var _filters_button: Control = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/PanelContainer/CenterMargin/CenterVBox/Header/FiltersButton
@onready var _overview_scroll: Control = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/PanelContainer/CenterMargin/CenterVBox/ScrollContainer
@onready var _overview_show_more: Control = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/PanelContainer/CenterMargin/CenterVBox/ShowMoreContainer
@onready var _overview_bottom_row: Control = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/PanelContainer/CenterMargin/CenterVBox/HBoxContainer
@onready var _right_separator: Control = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/VSeparator2
@onready var _right_bar: Control = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar
@onready var _calendar_card: Node = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/PanelContainer/CenterMargin/CenterVBox/HBoxContainer/CalendarCard

@onready var _top_cash_amount: Label = $ColorRect/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer2/PlayerFinances/CashGroup/CashAmount
@onready var _top_job_title: Label = $ColorRect/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer2/PlayerFinances/JobGroup/JobTitle
@onready var _top_education_title: Label = $ColorRect/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer2/PlayerFinances/EducationGroup/EducationTitle
@onready var _settings_button: Button = $ColorRect/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer2/Options/SettingsButton

@onready var _happiness_bar: ProgressBar = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/StatsCard/MarginContainer/VBoxContainer/Rows/HappinessRow/Bar
@onready var _happiness_value: Label = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/StatsCard/MarginContainer/VBoxContainer/Rows/HappinessRow/Value
@onready var _health_bar: ProgressBar = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/StatsCard/MarginContainer/VBoxContainer/Rows/HealthRow/Bar
@onready var _health_value: Label = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/StatsCard/MarginContainer/VBoxContainer/Rows/HealthRow/Value
@onready var _smarts_bar: ProgressBar = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/StatsCard/MarginContainer/VBoxContainer/Rows/SmartsRow/Bar
@onready var _smarts_value: Label = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/StatsCard/MarginContainer/VBoxContainer/Rows/SmartsRow/Value
@onready var _looks_bar: ProgressBar = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/StatsCard/MarginContainer/VBoxContainer/Rows/LooksRow/Bar
@onready var _looks_value: Label = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/StatsCard/MarginContainer/VBoxContainer/Rows/LooksRow/Value
@onready var _fitness_bar: ProgressBar = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/StatsCard/MarginContainer/VBoxContainer/Rows/FitnessRow/Bar
@onready var _fitness_value: Label = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/StatsCard/MarginContainer/VBoxContainer/Rows/FitnessRow/Value
@onready var _stress_bar: ProgressBar = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/StatsCard/MarginContainer/VBoxContainer/Rows/StressRow/Bar
@onready var _stress_value: Label = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/StatsCard/MarginContainer/VBoxContainer/Rows/StressRow/Value

@onready var _bank_value: Label = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/FinancesCard/MarginContainer/VBoxContainer/Grid/BankValue
@onready var _income_value: Label = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/FinancesCard/MarginContainer/VBoxContainer/Grid/IncomeValue
@onready var _expenses_value: Label = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/FinancesCard/MarginContainer/VBoxContainer/Grid/ExpensesValue

@onready var _career_unemployed_state: Control = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/CareerCard/MarginContainer/VBoxContainer/UnemployedState
@onready var _career_unemployed_label: Label = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/CareerCard/MarginContainer/VBoxContainer/UnemployedState/UnemployedLabel
@onready var _career_find_job_button: Button = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/CareerCard/MarginContainer/VBoxContainer/UnemployedState/FindJobButton
@onready var _career_top_row: Control = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/CareerCard/MarginContainer/VBoxContainer/TopRow
@onready var _career_performance_row: Control = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/CareerCard/MarginContainer/VBoxContainer/PerformanceRow
@onready var _career_education_row: Control = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/CareerCard/MarginContainer/VBoxContainer/EducationRow
@onready var _career_job_title: Label = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/CareerCard/MarginContainer/VBoxContainer/TopRow/JobInfo/JobTitle
@onready var _career_company: Label = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/CareerCard/MarginContainer/VBoxContainer/TopRow/JobInfo/Company
@onready var _career_salary: Label = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/CareerCard/MarginContainer/VBoxContainer/TopRow/Salary
@onready var _career_education_value: Label = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/CareerCard/MarginContainer/VBoxContainer/EducationRow/EducationValue

@onready var _rel_type_labels: Array[Label] = [
    $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/RelationshipsCard/MarginContainer/VBoxContainer/Grid/R1Type,
    $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/RelationshipsCard/MarginContainer/VBoxContainer/Grid/R2Type,
    $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/RelationshipsCard/MarginContainer/VBoxContainer/Grid/R3Type,
    $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/RelationshipsCard/MarginContainer/VBoxContainer/Grid/R4Type,
    $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/RelationshipsCard/MarginContainer/VBoxContainer/Grid/R5Type,
]

@onready var _rel_name_labels: Array[Label] = [
    $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/RelationshipsCard/MarginContainer/VBoxContainer/Grid/R1Name,
    $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/RelationshipsCard/MarginContainer/VBoxContainer/Grid/R2Name,
    $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/RelationshipsCard/MarginContainer/VBoxContainer/Grid/R3Name,
    $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/RelationshipsCard/MarginContainer/VBoxContainer/Grid/R4Name,
    $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/RelationshipsCard/MarginContainer/VBoxContainer/Grid/R5Name,
]

@onready var _rel_status_labels: Array[Label] = [
    $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/RelationshipsCard/MarginContainer/VBoxContainer/Grid/R1Status,
    $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/RelationshipsCard/MarginContainer/VBoxContainer/Grid/R2Status,
    $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/RelationshipsCard/MarginContainer/VBoxContainer/Grid/R3Status,
    $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/RelationshipsCard/MarginContainer/VBoxContainer/Grid/R4Status,
    $ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar/MarginContainer/VBoxContainer/RelationshipsCard/MarginContainer/VBoxContainer/Grid/R5Status,
]

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

    if _settings_button != null and not _settings_button.pressed.is_connected(_on_settings_pressed):
        _settings_button.pressed.connect(_on_settings_pressed)

    if _career_find_job_button != null and not _career_find_job_button.pressed.is_connected(_on_find_job_pressed):
        _career_find_job_button.pressed.connect(_on_find_job_pressed)

    var initial_section := _get_pressed_section()
    _set_section(initial_section)
    _init_from_player_data()

func _on_settings_pressed() -> void:
    if _calendar_card != null and _calendar_card.has_method("open_pause_menu"):
        _calendar_card.call("open_pause_menu")

func _on_find_job_pressed() -> void:
    _go_to_section(Section.CAREER)

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

func _go_to_section(section: int) -> void:
    for s in _nav_buttons.keys():
        var btn: BaseButton = _nav_buttons[s]
        if btn == null:
            continue
        if btn.has_method("set_pressed_no_signal"):
            btn.call("set_pressed_no_signal", s == section)
        else:
            btn.button_pressed = s == section
    _set_section(section)

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

    if _calendar_card != null and _calendar_card.has_method("set_energy_paused"):
        _calendar_card.call("set_energy_paused", not is_overview)

func _init_from_player_data() -> void:
    if player_data == null:
        return

    if _calendar_card != null:
        if _calendar_card.has_method("set_player_info"):
            _calendar_card.call("set_player_info", player_data.person_name, player_data.person_age)
        if _calendar_card.has_method("set_time"):
            var y := 0
            if _calendar_card.get("year") != null:
                y = int(_calendar_card.get("year"))
            var start_month := clampi(player_data.birth_month - 1, 0, 11)
            _calendar_card.call("set_time", y, start_month, 1)

    var cash_text := _format_money(player_data.bank_balance)
    _top_cash_amount.text = cash_text
    _bank_value.text = cash_text

    var job_title_text := _job_title_text(player_data.current_job)
    _top_job_title.text = job_title_text
    _career_job_title.text = job_title_text
    _career_company.text = _company_text(player_data.current_job, job_title_text)
    _career_salary.text = _salary_text(player_data.current_job, job_title_text)
    _update_career_unemployed_ui(player_data.current_job, job_title_text)

    var education_text := _education_level_to_text(player_data.highest_education_completed)
    _top_education_title.text = education_text
    _career_education_value.text = education_text

    var income: float = 0.0
    if player_data.current_job != null:
        income = player_data.current_job.salary / 12.0
    _income_value.text = _format_money(income)
    _expenses_value.text = _format_money(0.0)

    _set_stat_0_100(_happiness_bar, _happiness_value, player_data.Happiness)
    _set_stat_0_100(_health_bar, _health_value, player_data.Health)
    _set_stat_0_100(_smarts_bar, _smarts_value, player_data.Smarts)
    _set_stat_0_100(_looks_bar, _looks_value, player_data.Looks)
    _set_stat_0_100(_fitness_bar, _fitness_value, player_data.Fitness)
    var stress_0_100 := clampf((player_data.Stress + 100.0) * 0.5, 0.0, 100.0)
    _set_stat_0_100(_stress_bar, _stress_value, stress_0_100)
    _init_relationships_from_player_data()

func _set_stat_0_100(bar: ProgressBar, value_label: Label, value: float) -> void:
    var v := _clamp_0_100(value)
    if bar != null:
        bar.min_value = 0.0
        bar.max_value = 100.0
        bar.value = v
    if value_label != null:
        value_label.text = "%d / 100" % int(round(v))

func _clamp_0_100(value: float) -> float:
    return clampf(value, 0.0, 100.0)

func _job_title_text(job: JobResource) -> String:
    if job == null:
        return "Unemployed"
    var n := job.job_name.strip_edges()
    if n.is_empty():
        return "Unemployed"
    return n

func _company_text(job: JobResource, job_title_text: String) -> String:
    if job_title_text == "Unemployed":
        return "Unemployed"
    if job == null:
        return "Unemployed"
    var c := job.company_name.strip_edges()
    if c.is_empty():
        return "Unemployed"
    return c

func _salary_text(job: JobResource, job_title_text: String) -> String:
    if job_title_text == "Unemployed":
        return ""
    if job == null:
        return ""
    if job.salary <= 0.0:
        return ""
    return "%s / yr" % _format_money(job.salary)

func _update_career_unemployed_ui(job: JobResource, job_title_text: String) -> void:
    var is_unemployed := job_title_text == "Unemployed" or job == null
    if _career_unemployed_state != null:
        _career_unemployed_state.visible = is_unemployed
    if _career_unemployed_label != null and is_unemployed:
        _career_unemployed_label.text = "Unemployed"
    if _career_top_row != null:
        _career_top_row.visible = not is_unemployed
    if _career_performance_row != null:
        _career_performance_row.visible = not is_unemployed
    if _career_education_row != null:
        _career_education_row.visible = not is_unemployed

func _education_level_to_text(level: PeopleResource.EducationLevel) -> String:
    match level:
        PeopleResource.EducationLevel.NONE:
            return "No Education"
        PeopleResource.EducationLevel.PRESCHOOL:
            return "Preschool"
        PeopleResource.EducationLevel.PRIMARY:
            return "Primary School"
        PeopleResource.EducationLevel.SECONDARY:
            return "Secondary School"
        PeopleResource.EducationLevel.COLLEGE:
            return "College"
        PeopleResource.EducationLevel.UNIVERSITY:
            return "Bachelor's Degree"
        _:
            return "Education"

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

func _init_relationships_from_player_data() -> void:
    if player_data == null:
        return

    var rels: Array[RelationshipResource] = []
    if player_data.mother_relationship != null:
        rels.append(player_data.mother_relationship)
    if player_data.father_relationship != null:
        rels.append(player_data.father_relationship)
    if player_data.partner_relationship != null:
        rels.append(player_data.partner_relationship)

    var best_friend := _pick_best_friend(player_data.friends_relationships)
    if best_friend != null:
        rels.append(best_friend)

    if player_data.child_relationships.size() > 0:
        rels.append(player_data.child_relationships[0])

    for i in range(_rel_type_labels.size()):
        var rel: RelationshipResource = null
        if i < rels.size():
            rel = rels[i]
        _apply_relationship_row(i, rel)

func _pick_best_friend(friends: Array[RelationshipResource]) -> RelationshipResource:
    for r in friends:
        if r != null and r.relationship_type == RelationshipResource.RelationshipType.BEST_FRIEND:
            return r
    for r in friends:
        if r != null and r.relationship_type == RelationshipResource.RelationshipType.FRIEND:
            return r
    if friends.size() > 0:
        return friends[0]
    return null

func _apply_relationship_row(index: int, rel: RelationshipResource) -> void:
    var name_first_label := _rel_type_labels[index]
    var type_second_label := _rel_name_labels[index]
    var status_label := _rel_status_labels[index]

    if rel == null:
        name_first_label.text = "—"
        type_second_label.text = ""
        status_label.text = "None"
        var empty_color := Color(0.56941175, 0.58000004, 0.5905882, 1)
        name_first_label.add_theme_color_override("font_color", empty_color)
        type_second_label.add_theme_color_override("font_color", empty_color)
        status_label.add_theme_color_override("font_color", empty_color)
        return

    if rel.related_person != null and not rel.related_person.person_name.strip_edges().is_empty():
        name_first_label.text = rel.related_person.person_name
        name_first_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
    else:
        name_first_label.text = "—"
        name_first_label.add_theme_color_override("font_color", Color(0.56941175, 0.58000004, 0.5905882, 1))

    var type_text := _relationship_type_to_text(rel)
    type_second_label.text = type_text
    type_second_label.add_theme_color_override("font_color", rel.get_type_color())

    var status_text := _relationship_status_text(rel)
    status_label.text = status_text
    status_label.add_theme_color_override("font_color", _relationship_status_color(rel, status_text))

func _relationship_type_to_text(rel: RelationshipResource) -> String:
    match rel.relationship_type:
        RelationshipResource.RelationshipType.PARENT:
            if rel.related_person != null:
                match rel.related_person.person_gender:
                    PeopleResource.Gender.FEMALE:
                        return "Mother"
                    PeopleResource.Gender.MALE:
                        return "Father"
                    _:
                        return "Parent"
            return "Parent"
        RelationshipResource.RelationshipType.SIBLING:
            return "Sibling"
        RelationshipResource.RelationshipType.CHILD:
            return "Child"
        RelationshipResource.RelationshipType.PARTNER:
            return "Partner"
        RelationshipResource.RelationshipType.EX_PARTNER:
            return "Ex"
        RelationshipResource.RelationshipType.FRIEND:
            return "Friend"
        RelationshipResource.RelationshipType.BEST_FRIEND:
            return "Best Friend"
        RelationshipResource.RelationshipType.ENEMY:
            return "Enemy"
        RelationshipResource.RelationshipType.ACQUAINTANCE:
            return "Acquaintance"
        RelationshipResource.RelationshipType.BOSS:
            return "Boss"
        RelationshipResource.RelationshipType.COWORKER:
            return "Coworker"
        RelationshipResource.RelationshipType.OTHER:
            return "Other"
        _:
            return "—"

func _relationship_status_text(rel: RelationshipResource) -> String:
    if rel.is_romantic_relationship() and rel.romance_type != RelationshipResource.RomanceType.NONE:
        match rel.romance_type:
            RelationshipResource.RomanceType.DATING:
                return "Dating"
            RelationshipResource.RomanceType.ENGAGED:
                return "Engaged"
            RelationshipResource.RomanceType.MARRIED:
                return "Married"
            RelationshipResource.RomanceType.SEPARATED:
                return "Separated"
            RelationshipResource.RomanceType.EX:
                return "Ex"
            _:
                return "Romance"

    match rel.relationship_status:
        RelationshipResource.RelationshipStatus.UNKNOWN:
            return "Unknown"
        RelationshipResource.RelationshipStatus.ACTIVE:
            return "Active"
        RelationshipResource.RelationshipStatus.DISTANT:
            return "Distant"
        RelationshipResource.RelationshipStatus.ESTRANGED:
            return "Estranged"
        RelationshipResource.RelationshipStatus.BROKEN_UP:
            return "Broken Up"
        RelationshipResource.RelationshipStatus.DIVORCED:
            return "Divorced"
        _:
            return "Active"

func _relationship_status_color(rel: RelationshipResource, status_text: String) -> Color:
    if status_text in ["Dating", "Engaged", "Married"]:
        return Color(0.23137255, 0.50980395, 0.9647059, 1)
    if status_text in ["Separated", "Broken Up", "Divorced", "Estranged"]:
        return Color(0.9372549, 0.26666668, 0.26666668, 1)
    if status_text == "Distant":
        return Color(0.9647059, 0.54509807, 0.14117648, 1)
    if status_text == "Unknown" or status_text == "None":
        return Color(0.56941175, 0.58000004, 0.5905882, 1)
    return Color(0.1882353, 0.6392157, 0.38431373, 1)
