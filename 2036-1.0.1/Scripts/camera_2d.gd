extends Camera2D

@export_group("Camera")
@export var follow_speed: float = 5.0
@export var use_smoothing: bool = true

@onready var player: CharacterBody2D = get_parent() as CharacterBody2D


func _ready() -> void:
	global_position = player.global_position


func _process(delta: float) -> void:
	if player == null:
		return

	if use_smoothing:
		var weight: float = 1.0 - exp(-follow_speed * delta)

		global_position = global_position.lerp(
			player.global_position,
			weight
		)
	else:
		global_position = player.global_position
