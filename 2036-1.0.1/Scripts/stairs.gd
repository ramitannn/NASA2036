extends Area2D

@onready var top_point: Marker2D = $TopPoint
@onready var bottom_point: Marker2D = $BottomPoint

var player_inside: CharacterBody2D = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if not body is CharacterBody2D:
		return

	player_inside = body as CharacterBody2D


func _on_body_exited(body: Node2D) -> void:
	if body == player_inside:
		player_inside = null


func _process(_delta: float) -> void:
	if player_inside == null:
		return

	if player_inside.is_climbing:
		return

	if Input.is_action_just_pressed("interact"):
		player_inside.start_climbing(
			top_point.global_position,
			bottom_point.global_position
		)
