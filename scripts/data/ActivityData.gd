@tool
extends Resource
class_name ActivityResource

enum ActivitySubType { 
    NONE, 
    SOCIAL,
    LOVE_DATING,
    HEALTH_WELLNESS,
    FITNESS,
    NIGHTLIFE,
    TRAVEL,
    FINANCE_SHOPPING,
    LIFESTYLE, 
    CRIME 
}

@export_group("Activity Info")
@export var activity_name: String
@export_multiline var activity_description: String
@export var activity_category: ActivitySubType = ActivitySubType.NONE
@export_range(1, 100, 1) var activity_success_chance: float = 100

@export_group("Activity Rules")
@export var is_repeatable: bool = true
@export var cooldown_weeks: int = 0

@export_group("Activity Requirement")
@export var min_age: int = 0
@export var max_age: int = 120
@export var health_requirement: float = 0.0
@export var happiness_requirement: float = 0.0
@export var stress_requirement: float = 0.0
@export var fitness_requirement: float = 0.0
@export var smarts_requirement: float = 0.0
@export var looks_requirement: float = 0.0
@export var reputation_requirement: float = 0.0
@export var money_requirement: float = 0.0
@export var energy_requirement: float = 0.0

@export_group("Activity Cost")
@export var money_cost: float = 0.0
@export var energy_cost: float = 0.0

@export_group("Activity Success Change")
@export var relationship_change: float = 0.0
@export var health_change: float = 0.0
@export var happiness_change: float = 0.0
@export var stress_change: float = 0.0
@export var fitness_change: float = 0.0
@export var smarts_change: float = 0.0
@export var looks_change: float = 0.0
@export var reputation_change: float = 0.0
@export var money_change: float = 0.0
@export var energy_change: float = 0.0

@export_group("Activity Failure Change")
@export var fail_relationship_change: float = 0.0
@export var fail_health_change: float = 0.0
@export var fail_happiness_change: float = 0.0
@export var fail_stress_change: float = 0.0
@export var fail_fitness_change: float = 0.0
@export var fail_smarts_change: float = 0.0
@export var fail_looks_change: float = 0.0
@export var fail_reputation_change: float = 0.0
@export var fail_money_change: float = 0.0
@export var fail_energy_change: float = 0.0

@export_group("Linked Activities (Choices)")
@export_file("*.tres") var success_followup_activities: Array[String]
@export_file("*.tres") var failure_followup_activities: Array[String]
