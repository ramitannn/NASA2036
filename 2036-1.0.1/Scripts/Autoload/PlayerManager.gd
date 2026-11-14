extends Node

var player: CharacterBody2D = null

func register_player(new_player: CharacterBody2D) -> void:
	player = new_player

func get_player() -> CharacterBody2D:
	return player
