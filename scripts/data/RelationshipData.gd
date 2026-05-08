@tool
extends Resource
class_name RelationshipResource


enum RelationshipType {
    NONE,
    PARENT,
    SIBLING,
    CHILD,
    PARTNER,
    EX_PARTNER,
    FRIEND,
    BEST_FRIEND,
    ENEMY,
    ACQUAINTANCE,
    BOSS,
    COWORKER,
    OTHER
}

enum RelationshipStatus {
    UNKNOWN,
    ACTIVE,
    DISTANT,
    ESTRANGED,
    BROKEN_UP,
    DIVORCED,
}

enum RelationshipDirection {
    MUTUAL,
    THIS_PERSON_TO_THEM,
    THEM_TO_THIS_PERSON
}

enum FamilyLinkType {
    NONE,
    BIOLOGICAL,
    ADOPTED,
    STEP,
    HALF,
    IN_LAW
}

enum RomanceType {
    NONE,
    DATING,
    ENGAGED,
    MARRIED,
    SEPARATED,
    EX
}


@export_group("Core Info")
@export var related_person: PeopleResource

@export var relationship_type: RelationshipType = RelationshipType.NONE:
    set(value):
        relationship_type = value
        _update_defaults_from_type()
        notify_property_list_changed()

@export var relationship_status: RelationshipStatus = RelationshipStatus.ACTIVE
@export var relationship_direction: RelationshipDirection = RelationshipDirection.MUTUAL


@export_group("Relationship Scores")
@export_range(-100, 100, 1) var opinion: float = 0
@export_range(0, 100, 1) var closeness: float = 0
@export_range(0, 100, 1) var trust: float = 0
@export_range(0, 100, 1) var respect: float = 0
@export_range(0, 100, 1) var conflict: float = 0


@export_group("Family Details")
@export var family_link_type: FamilyLinkType = FamilyLinkType.NONE


@export_group("Romance Details")
@export var romance_type: RomanceType = RomanceType.NONE
@export_range(0, 100, 1) var attraction: float = 0
@export_range(0, 100, 1) var commitment: float = 0


@export_group("History")
@export_range(0, 150, 1) var years_known: int = 0
@export var lives_together: bool = false
@export var is_active_relationship: bool = true
@export_multiline var relationship_notes: String = ""


func _validate_property(property: Dictionary) -> void:
    if property.name == "family_link_type" and not is_family_relationship():
        property.usage = PROPERTY_USAGE_NO_EDITOR

    if property.name == "romance_type" and not is_romantic_relationship():
        property.usage = PROPERTY_USAGE_NO_EDITOR

    if property.name == "attraction" and not is_romantic_relationship():
        property.usage = PROPERTY_USAGE_NO_EDITOR

    if property.name == "commitment" and not is_romantic_relationship():
        property.usage = PROPERTY_USAGE_NO_EDITOR


func is_family_relationship() -> bool:
    return relationship_type in [
        RelationshipType.PARENT,
        RelationshipType.SIBLING,
        RelationshipType.CHILD
    ]


func is_romantic_relationship() -> bool:
    return relationship_type in [
        RelationshipType.PARTNER,
        RelationshipType.EX_PARTNER
    ]


func is_work_relationship() -> bool:
    return relationship_type in [
        RelationshipType.BOSS,
        RelationshipType.COWORKER
    ]


func is_positive_relationship() -> bool:
    return opinion > 25 and conflict < 50


func is_negative_relationship() -> bool:
    return opinion < -25 or conflict > 70


func _update_defaults_from_type() -> void:
    match relationship_type:
        RelationshipType.PARENT, RelationshipType.CHILD:
            family_link_type = FamilyLinkType.BIOLOGICAL
            romance_type = RomanceType.NONE
            relationship_status = RelationshipStatus.ACTIVE

        RelationshipType.SIBLING:
            family_link_type = FamilyLinkType.BIOLOGICAL
            romance_type = RomanceType.NONE
            relationship_status = RelationshipStatus.ACTIVE

        RelationshipType.PARTNER:
            family_link_type = FamilyLinkType.NONE
            romance_type = RomanceType.DATING
            relationship_status = RelationshipStatus.ACTIVE

        RelationshipType.EX_PARTNER:
            family_link_type = FamilyLinkType.NONE
            romance_type = RomanceType.EX
            relationship_status = RelationshipStatus.BROKEN_UP

        _:
            family_link_type = FamilyLinkType.NONE
            romance_type = RomanceType.NONE
            relationship_status = RelationshipStatus.ACTIVE
