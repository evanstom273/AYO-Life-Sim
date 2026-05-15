@tool
extends Resource
class_name EventsResource

# The core text that appears in the log (e.g., "You were fired from your job.")
@export var event_title: String
@export_multiline var event_description: String

# To help categorise or colour-code the UI
enum EventType {
    MILESTONE,  # Forced life progression: Ageing up, aging-related bodily changes
    CAREER,     # Being fired, company goes bust, surprise bonus, workplace accident
    SOCIAL,     # Friend moves away, family member dies, someone starts a rumour about you
    RANDOM,     # Finding a £20 note, being mugged, car breaks down, house flooded
    HEALTH      # Catching the flu, developing a chronic condition, random injury
}
@export var type: EventType = EventType.RANDOM

# Impact level (could be used for logic, e.g., Major events might auto-pause the game/week progression)
enum ImpactLevel { SMALL, MEDIUM, MAJOR }
@export var impact: ImpactLevel = ImpactLevel.MEDIUM

# Consequences - what stats are affected?
@export var health_change: float = 0.0
@export var happiness_change: float = 0.0
@export var stress_change: float = 0.0
@export var fitness_change: float = 0.0
@export var smarts_change: float = 0.0
@export var looks_change: float = 0.0
@export var reputation_change: float = 0.0
@export var money_change: float = 0.0
@export var energy_minus_amount: float = 0.0

# Metadata
@export var year_occurred: int = 0
