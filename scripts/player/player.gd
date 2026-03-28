extends CharacterBody2D

## If true: walk in all directions (bird's-eye). If false: run/jump platformer (side-view gameplay).
@export var top_down: bool = true
@export var speed: float = 200.0
@export var jump_velocity: float = -480.0
@export var interact_distance: float = 50.0
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 1.0

@onready var point_light: PointLight2D = $PointLight2D
@onready var _visual: Node2D = $Visual

## Última direção de movimento (normalizada); usada quando a velocidade é ~0.
var _last_move_dir: Vector2 = Vector2.DOWN

var _is_dashing: bool = false
## Direção fixa durante o dash: top-down = velocidade completa; side-view = só X é usado.
var _dash_velocity: Vector2 = Vector2.ZERO

var _dash_duration_timer: Timer
var _dash_cooldown_timer: Timer


func _ready() -> void:
	_setup_point_light_texture()
	point_light.texture_scale = 3.2
	point_light.position = Vector2.ZERO
	point_light.shadow_filter = Light2D.SHADOW_FILTER_PCF5

	DayNightSystem.phase_changed.connect(_on_phase_changed)
	_on_phase_changed(DayNightSystem.is_night)

	_dash_duration_timer = Timer.new()
	_dash_duration_timer.one_shot = true
	_dash_duration_timer.timeout.connect(_on_dash_duration_finished)
	add_child(_dash_duration_timer)

	_dash_cooldown_timer = Timer.new()
	_dash_cooldown_timer.one_shot = true
	add_child(_dash_cooldown_timer)


func _setup_point_light_texture() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))

	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.width = 256
	tex.height = 256
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)

	point_light.texture = tex


func _on_phase_changed(is_night: bool) -> void:
	if is_night:
		point_light.color = Color(0.95, 0.35, 0.38)
		point_light.energy = 1.35
	else:
		point_light.color = Color(1.0, 0.92, 0.72)
		point_light.energy = 0.95
	_visual.queue_redraw()


func get_facing_direction() -> Vector2:
	var d := velocity
	if _is_dashing and top_down:
		d = _dash_velocity
	if top_down:
		if d.length_squared() < 100.0:
			return _last_move_dir
		return d.normalized()
	if absf(velocity.x) > 6.0:
		return Vector2(signf(velocity.x), 0)
	if absf(_last_move_dir.x) > 0.01:
		return Vector2(signf(_last_move_dir.x), 0)
	return Vector2.RIGHT


func _update_facing_rotation() -> void:
	if top_down:
		var d := get_facing_direction()
		_visual.rotation = d.angle() + PI * 0.5
	else:
		var dir_x := get_facing_direction().x
		_visual.rotation = PI if dir_x < 0.0 else 0.0


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("dash") and DayNightSystem.is_night and not _is_dashing and _dash_cooldown_timer.is_stopped():
		_begin_dash()

	if _is_dashing:
		if top_down:
			velocity = _dash_velocity
		else:
			velocity.x = _dash_velocity.x
			velocity += get_gravity() * delta
		move_and_slide()
		_update_facing_rotation()
		return

	if top_down:
		_top_down_move()
	else:
		_side_view_move(delta)

	_update_facing_rotation()


func _begin_dash() -> void:
	if top_down:
		var d := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
		if d.length_squared() < 0.01:
			_dash_velocity = Vector2.RIGHT * dash_speed
		else:
			_dash_velocity = d.normalized() * dash_speed
			_last_move_dir = _dash_velocity.normalized()
	else:
		var dx := Input.get_axis("ui_left", "ui_right")
		if absf(dx) < 0.01:
			dx = 1.0
		_dash_velocity = Vector2(signf(dx) * dash_speed, 0.0)

	_is_dashing = true
	_dash_duration_timer.wait_time = dash_duration
	_dash_duration_timer.start()


func _on_dash_duration_finished() -> void:
	_is_dashing = false
	_dash_cooldown_timer.wait_time = dash_cooldown
	_dash_cooldown_timer.start()


func _top_down_move() -> void:
	var direction := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		_last_move_dir = direction
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
	if absf(velocity.x) > 6.0:
		_last_move_dir = Vector2(signf(velocity.x), 0)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		interact()


func interact() -> void:
	var space_state := get_world_2d().direct_space_state
	var face := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	var dirs: Array[Vector2] = []
	if face.length_squared() > 0.01:
		dirs.append(face.normalized())
	for d in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		if d not in dirs:
			dirs.append(d)
	for dir: Vector2 in dirs:
		var query := PhysicsRayQueryParameters2D.create(
			global_position,
			global_position + dir * interact_distance
		)
		query.collide_with_areas = true
		query.collide_with_bodies = true
		var result := space_state.intersect_ray(query)
		if result and result.collider.has_method("interact"):
			result.collider.interact(DayNightSystem.is_night)
			return
