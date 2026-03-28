extends CharacterBody2D

## If true: walk in all directions (bird's-eye). If false: run/jump platformer (side-view gameplay).
@export var top_down: bool = true
@export var speed: float = 200.0
@export var jump_velocity: float = -480.0
@export var interact_distance: float = 50.0

func _physics_process(delta: float) -> void:
	if top_down:
		_top_down_move()
	else:
		_side_view_move(delta)

func _top_down_move() -> void:
	var direction := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	if direction != Vector2.ZERO:
		direction = direction.normalized()
	velocity = direction * speed
	move_and_slide()

func _side_view_move(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
	var dir_x := Input.get_axis("ui_left", "ui_right")
	velocity.x = dir_x * speed
	move_and_slide()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		interact()

func interact() -> void:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + Vector2.RIGHT * interact_distance
	)
	var result := space_state.intersect_ray(query)
	if result and result.collider.has_method("interact"):
		result.collider.interact()
