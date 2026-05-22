@tool
extends Resource
class_name PeopleResource

enum PeopleAge { BABY, TODDLER, CHILD, TEEN, YOUNG_ADULT, ADULT, ELDER }
enum Region { NORTH_AMERICA, SOUTH_AMERICA, EUROPE, ASIA, AFRICA, OCEANIA }
enum EducationLevel { NONE, PRESCHOOL, PRIMARY, SECONDARY, COLLEGE, UNIVERSITY }
enum Gender { NONE, MALE, FEMALE, NON_BINARY }

const MIN_JOB_AGE := 16

@export_group("Person Info")
@export var person_name: String = ""

@export_range(0, 150, 1) var person_age: int = 0:
    set(value):
        person_age = value
        update_age_group()
        notify_property_list_changed()

@export var person_age_group: PeopleAge = PeopleAge.BABY
@export var person_gender: Gender = Gender.NONE
@export_range(1, 12, 1) var birth_month: int = 1
@export var person_region: Region = Region.NORTH_AMERICA
@export var current_education: EducationLevel
@export var highest_education_completed: EducationLevel

@export_group("Stats")
@export_range(0, 100, 1) var Health: float = 0
@export_range(0, 100, 1) var Happiness: float = 0
@export_range(0, 100, 1) var Looks: float = 0
@export_range(0, 100, 1) var Fitness: float = 0
@export_range(0, 100, 1) var Smarts: float = 0
@export_range(-100, 100, 1) var Reputation: float = 0
@export_range(-100, 100, 1) var Karma: float = 0
@export_range(-100, 100, 1) var Stress: float = 0

@export_group("Relationships")
@export var mother_relationship: RelationshipResource
@export var father_relationship: RelationshipResource
@export var partner_relationship: RelationshipResource
@export var siblings_relationships: Array[RelationshipResource]
@export var friends_relationships: Array[RelationshipResource]
@export var enemies_relationships: Array[RelationshipResource]
@export var child_relationships: Array[RelationshipResource]
@export var general_relationships: Array[RelationshipResource]


@export_group("Job & Finances")
@export_range(-150000, 10000000) var bank_balance: float = 0
@export var current_job: JobResource
@export var previous_jobs: Array[JobResource]


func _validate_property(property: Dictionary) -> void:
    if property.name in [&"current_job", &"previous_jobs"]:
        if not can_have_job():
            property.usage = PROPERTY_USAGE_NO_EDITOR


func can_have_job() -> bool:
    return person_age >= MIN_JOB_AGE


func update_age_group() -> void:
    if person_age < 1:
        person_age_group = PeopleAge.BABY
    elif person_age <= 3:
        person_age_group = PeopleAge.TODDLER
    elif person_age <= 12:
        person_age_group = PeopleAge.CHILD
    elif person_age <= 18:
        person_age_group = PeopleAge.TEEN
    elif person_age >= 65:
        person_age_group = PeopleAge.ELDER
    elif person_age >= 30:
        person_age_group = PeopleAge.ADULT
    else:
        person_age_group = PeopleAge.YOUNG_ADULT
