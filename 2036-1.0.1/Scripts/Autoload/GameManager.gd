extends Node

var spawn_position: Vector2 = Vector2.ZERO

var transition_duration: float = 0.4
var transition_active: bool = false

var fade_layer: CanvasLayer
var fade_rect: ColorRect


func _ready() -> void:
	_create_fade_overlay()


func _create_fade_overlay() -> void:
	fade_layer = CanvasLayer.new()
	fade_layer.name = "FadeLayer"
	fade_layer.layer = 100
	add_child(fade_layer)

	fade_rect = ColorRect.new()
	fade_rect.name = "FadeRect"
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	fade_layer.add_child(fade_rect)


func set_spawn_position(position: Vector2) -> void:
	spawn_position = position


func get_spawn_position() -> Vector2:
	return spawn_position


func fade_to_black() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(
		fade_rect,
		"color:a",
		1.0,
		transition_duration
	)

	await tween.finished


func fade_from_black() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(
		fade_rect,
		"color:a",
		0.0,
		transition_duration
	)

	await tween.finished


func change_scene(scene_path: String, destination: Vector2) -> void:
	if transition_active:
		return

	if scene_path.is_empty():
		push_error("Destination scene is empty.")
		return

	transition_active = true

	var player: CharacterBody2D = PlayerManager.get_player()

	if player != null:
		player.set_movement_locked(true)

	# Fade out.
	await fade_to_black()

	# Save destination and change scene.
	set_spawn_position(destination)

	var error: Error = get_tree().change_scene_to_file(scene_path)

	if error != OK:
		push_error("Failed to change scene: " + scene_path)

		if player != null:
			player.set_movement_locked(false)

		await fade_from_black()
		transition_active = false
		return

	# Wait until the new scene is loaded.
	await get_tree().scene_changed

	# Move the persistent player.
	player = PlayerManager.get_player()

	if player != null:
		player.global_position = spawn_position
		player.start_position = spawn_position
		player.target_position = spawn_position
		player.set_movement_locked(true)

	# Fade in.
	await fade_from_black()

	# Allow movement again.
	if player != null:
		player.set_movement_locked(false)

	transition_active = false
