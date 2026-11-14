extends CharacterBody2D

# ==================================================
# CONFIGURATION
# ==================================================

@export_group("Movement")
@export var move_speed: float = 90.0
@export var grid_size: float = 16.0

@export_group("Grid")
@export var grid_origin: Vector2 = Vector2.ZERO

@export_group("Collision")
@export var player_collision_size: Vector2 = Vector2(12.0, 12.0)

@export_group("Input")
@export var enable_diagonal: bool = true

@export_group("Climbing")
@export var climb_speed: float = 45.0

# ==================================================
# VARIABLES
# ==================================================

var is_moving: bool = false
var movement_locked: bool = false
var movement_blocked: bool = false
var waiting_for_input_release: bool = false

var start_position: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var move_direction: Vector2 = Vector2.ZERO
var blocked_direction: Vector2 = Vector2.ZERO

var door_animation: bool = false
var door_target_position: Vector2 = Vector2.ZERO
var door_animation_speed: float = 55.0

var is_climbing: bool = false
var ladder_top: Vector2 = Vector2.ZERO
var ladder_bottom: Vector2 = Vector2.ZERO
var climb_target: Vector2 = Vector2.ZERO

# ==================================================
# INITIALIZATION
# ==================================================

func _ready() -> void:
	PlayerManager.register_player(self)

	if get_parent() != get_tree().root:
		reparent.call_deferred(get_tree().root)

	grid_size = maxf(grid_size, 1.0)
	safe_margin = 0.001

	var shape_node: CollisionShape2D = get_node_or_null("CollisionShape2D")

	if shape_node == null:
		push_error("Player CollisionShape2D is missing.")
		return

	if shape_node.shape is RectangleShape2D:
		var rectangle: RectangleShape2D = shape_node.shape.duplicate() as RectangleShape2D
		rectangle.size = player_collision_size
		shape_node.shape = rectangle
	else:
		push_warning("Player collision shape must be a RectangleShape2D.")

	shape_node.position = Vector2(grid_size / 2.0, grid_size / 2.0)

	global_position = snap_to_grid(global_position)

	start_position = global_position
	target_position = global_position
	velocity = Vector2.ZERO

	# Center collision shape in the grid cell.
	shape_node.position = Vector2(
		grid_size / 2.0,
		grid_size / 2.0
	)

	# ==============================================
	# SPAWN POSITION (GAME MANAGER)
	# ==============================================

	var spawn_position: Vector2 = GameManager.get_spawn_position()

	global_position = snap_to_grid(spawn_position)

	# Initialize movement positions.
	start_position = global_position
	target_position = global_position

	velocity = Vector2.ZERO


# ==================================================
# PHYSICS PROCESS
# ==================================================

func _physics_process(delta: float) -> void:
	if movement_locked and not is_climbing:
		velocity = Vector2.ZERO
		return

	if is_climbing:
		process_climbing(delta)
		return

	if not is_moving:
		handle_movement_input()

	if is_moving:
		process_movement(delta)

# ==================================================
# GRID SYSTEM
# ==================================================

func snap_to_grid(world_position: Vector2) -> Vector2:
	var relative_position: Vector2 = world_position - grid_origin

	return grid_origin + Vector2(
		roundf(relative_position.x / grid_size) * grid_size,
		roundf(relative_position.y / grid_size) * grid_size
	)


# ==================================================
# INPUT
# ==================================================

func handle_movement_input() -> void:
	var horizontal: float = Input.get_axis("move_left", "move_right")
	var vertical: float = Input.get_axis("move_up", "move_down")

	if not enable_diagonal:
		if absf(horizontal) > 0.0:
			vertical = 0.0
		else:
			horizontal = 0.0

	var input_direction: Vector2 = Vector2(
		signf(horizontal),
		signf(vertical)
	)

	# Reset blocked state when all movement keys are released.
	if input_direction == Vector2.ZERO:
		waiting_for_input_release = false
		blocked_direction = Vector2.ZERO
		return

	# Prevent repeated blocked movement.
	if waiting_for_input_release:
		if input_direction == blocked_direction:
			return

		waiting_for_input_release = false
		blocked_direction = Vector2.ZERO

	start_movement(input_direction)


# ==================================================
# START MOVEMENT
# ==================================================

func start_movement(direction: Vector2) -> void:
	start_position = global_position

	move_direction = Vector2(
		signf(direction.x),
		signf(direction.y)
	)

	target_position = start_position + move_direction * grid_size

	movement_blocked = false
	is_moving = true


# ==================================================
# MOVEMENT
# ==================================================

func process_movement(delta: float) -> void:
	var distance: float = global_position.distance_to(target_position)

	if distance <= 0.01:
		global_position = target_position
		stop_movement(false)
		return

	var direction: Vector2 = global_position.direction_to(target_position)

	var movement_distance: float = minf(
		move_speed * delta,
		distance
	)

	var motion: Vector2 = direction * movement_distance

	var collision: KinematicCollision2D = move_and_collide(motion)

	if collision != null:
		stop_movement(true)
		return

	if global_position.distance_to(target_position) <= 0.01:
		global_position = target_position
		stop_movement(false)


# ==================================================
# STOP MOVEMENT
# ==================================================

func stop_movement(blocked: bool) -> void:
	is_moving = false
	velocity = Vector2.ZERO

	if blocked:
		global_position = start_position

		blocked_direction = move_direction
		waiting_for_input_release = true
	else:
		global_position = target_position
		blocked_direction = Vector2.ZERO
		waiting_for_input_release = false

	move_direction = Vector2.ZERO
	movement_blocked = blocked

func set_movement_locked(locked: bool) -> void:
	movement_locked = locked

	if locked:
		if is_moving:
			global_position = start_position

		is_moving = false
		velocity = Vector2.ZERO
		move_direction = Vector2.ZERO

func walk_towards_door(target: Vector2, speed: float = 55.0) -> void:
	movement_locked = true
	is_moving = false
	velocity = Vector2.ZERO

	var distance: float = global_position.distance_to(target)

	if distance <= 1.0:
		global_position = target
		return

	var duration: float = distance / speed

	var tween: Tween = create_tween()

	tween.tween_property(
		self,
		"global_position",
		target,
		duration
	).set_trans(Tween.TRANS_LINEAR)

	await tween.finished

func start_climbing(top: Vector2, bottom: Vector2) -> void:
	if is_climbing:
		return

	is_climbing = true
	is_moving = false
	movement_locked = false

	ladder_top = top
	ladder_bottom = bottom

	# Determine which end is closer.
	var distance_to_top: float = global_position.distance_to(top)
	var distance_to_bottom: float = global_position.distance_to(bottom)

	if distance_to_top < distance_to_bottom:
		climb_target = bottom
	else:
		climb_target = top


func stop_climbing() -> void:
	is_climbing = false
	is_moving = false
	velocity = Vector2.ZERO
	global_position = climb_target

func process_climbing(delta: float) -> void:
	var direction: Vector2 = global_position.direction_to(climb_target)
	var distance: float = global_position.distance_to(climb_target)

	if distance <= 0.5:
		stop_climbing()
		return

	var motion: Vector2 = direction * climb_speed * delta

	if motion.length() > distance:
		motion = direction * distance

	move_and_collide(motion)
