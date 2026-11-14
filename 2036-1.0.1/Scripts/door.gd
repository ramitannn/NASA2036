extends Area2D

@export_file("*.tscn")
var destination_scene: String = "res://Scenes/cabin.tscn"

@export var destination_position: Vector2 = Vector2.ZERO
@export var walk_speed: float = 55.0

@onready var entrance_point: Marker2D = $EntrancePoint

var transitioning: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if transitioning or GameManager.transition_active:
		return

	if not body is CharacterBody2D:
		return

	if destination_scene.is_empty():
		push_error("Destination scene is not assigned.")
		return

	transitioning = true

	var player: CharacterBody2D = body

	# Get the actual world position of the entrance marker.
	var target_position: Vector2 = entrance_point.global_position

	# Walk toward the entrance marker.
	await player.walk_towards_door(target_position, walk_speed)

	# Transition after reaching the entrance.
	GameManager.change_scene(
		destination_scene,
		destination_position
	)
