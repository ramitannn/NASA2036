extends Node

signal oxygen_changed(current: float, maximum: float)
signal oxygen_depleted

@export_group("Oxygen")
@export var max_oxygen: float = 100.0
@export var oxygen_drain_rate: float = 1.0
@export var oxygen_restore_rate: float = 5.0

var current_oxygen: float = 100.0

var in_pressurized_area: bool = false
var depleted: bool = false

signal player_health_changed(current: float, maximum: float)

@export_group("Health")
@export var max_health: float = 100.0
@export var suffocation_damage: float = 5.0

var current_health: float = 100.0

func _ready() -> void:
	current_oxygen = max_oxygen
	current_health = max_health

func _process(delta: float) -> void:
	if depleted:
		current_health -= suffocation_damage * delta
		current_health = maxf(current_health, 0.0)

		player_health_changed.emit(current_health, max_health)

		if current_health <= 0.0:
			print("MISSION FAILED: PLAYER SUFFOCATED")
		return

	if in_pressurized_area:
		restore_oxygen(delta)
	else:
		drain_oxygen(delta)

func drain_oxygen(delta: float) -> void:
	current_oxygen -= oxygen_drain_rate * delta
	current_oxygen = maxf(current_oxygen, 0.0)

	oxygen_changed.emit(current_oxygen, max_oxygen)

	if current_oxygen <= 0.0:
		depleted = true
		oxygen_depleted.emit()


func restore_oxygen(delta: float) -> void:
	current_oxygen += oxygen_restore_rate * delta
	current_oxygen = minf(current_oxygen, max_oxygen)

	oxygen_changed.emit(current_oxygen, max_oxygen)


func refill_oxygen(amount: float = -1.0) -> void:
	if amount < 0.0:
		current_oxygen = max_oxygen
	else:
		current_oxygen = minf(current_oxygen + amount, max_oxygen)

	if current_oxygen > 0.0:
		depleted = false

	oxygen_changed.emit(current_oxygen, max_oxygen)


func set_pressurized(value: bool) -> void:
	in_pressurized_area = value


func get_oxygen_percentage() -> float:
	return (current_oxygen / max_oxygen) * 100.0
