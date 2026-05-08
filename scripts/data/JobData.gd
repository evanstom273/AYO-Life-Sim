@tool
extends Resource
class_name JobResource

@export_group("Job Info")
@export var job_name: String = ""
@export var minimum_education_level = PeopleResource.EducationLevel.NONE
@export_range(0, 100000, 1000) var salary: float = 0


@export_group("Requirements")
@export var requires_smarts: bool = false:
    set(value):
        requires_smarts = value
        notify_property_list_changed()
@export_range(0, 100, 1) var required_smarts: float = 0
@export var requires_fitness: bool = false:
    set(value):
        requires_fitness = value
        notify_property_list_changed()
@export_range(0, 100, 1) var required_fitness: float = 0
@export var requires_looks: bool = false:
    set(value):
        requires_looks = value
        notify_property_list_changed()
@export_range(0, 100, 1) var required_looks: float = 0


func _validate_property(property: Dictionary) -> void:
    if property.name == "required_smarts" and not requires_smarts:
        property.usage = PROPERTY_USAGE_NO_EDITOR
    if property.name == "required_fitness" and not requires_fitness:
        property.usage = PROPERTY_USAGE_NO_EDITOR
    if property.name == "required_looks" and not requires_looks:
        property.usage = PROPERTY_USAGE_NO_EDITOR
