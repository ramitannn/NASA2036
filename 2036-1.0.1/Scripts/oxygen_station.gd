extends Area2D

@export var refill_amount: float = 50.0

var player_inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_inside = true


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_inside = false


func _process(_delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("interact"):
		OxygenSystem.refill_oxygen(refill_amount)
