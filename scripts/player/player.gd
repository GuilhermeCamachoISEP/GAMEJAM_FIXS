extends CharacterBody2D

const _DashGhostScript: Script = preload("res://scripts/player/dash_ghost.gd")

## If true: walk in all directions (bird's-eye). If false: run/jump platformer (side-view gameplay).
@export var top_down: bool = true
@export var speed: float = 200.0
@export var jump_velocity: float = -480.0
@export var interact_distance: float = 50.0
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 1.0
@export var footstep_interval: float = 0.38
@export var footstep_min_speed_sq: float = 3600.0
@export var sfx_enabled: bool = true

@onready var point_light: PointLight2D = $PointLight2D
@onready var _visual: Node2D = $Visual
@onready var _camera: Camera2D = $Camera2D
@onready var _sfx_step: AudioStreamPlayer2D = $SfxStep
@onready var _sfx_action: AudioStreamPlayer2D = $SfxAction
@onready var _footstep_dust: GPUParticles2D = $FootstepDust
@onready var _dash_smoke: GPUParticles2D = $DashSmoke
@onready var _dash_trail_container: Node2D = $DashTrailContainer

## Última direção de movimento (normalizada); usada quando a velocidade é ~0.
var _last_move_dir: Vector2 = Vector2.DOWN

var _is_dashing: bool = false
## Direção fixa durante o dash: top-down = velocidade completa; side-view = só X é usado.
var _dash_velocity: Vector2 = Vector2.ZERO

var _dash_duration_timer: Timer
var _dash_cooldown_timer: Timer

var _footstep_cooldown: float = 0.0

# Light pulse variables
var _light_pulse_time: float = 0.0
var _light_pulse_speed: float = 2.5  # Rads per second
var _light_pulse_amount: float = 0.15
var _light_base_energy: float = 1.0

# Dash trail variables
var _ghost_spawn_timer: float = 0.0
var _ghost_spawn_interval: float = 0.03
var _is_spawning_trail: bool = false
var _stream_step: AudioStreamWAV
var _stream_interact: AudioStreamWAV
var _stream_dash: AudioStreamWAV
var _stream_phase_night: AudioStreamWAV
var _stream_phase_day: AudioStreamWAV
var _stream_bump: AudioStreamWAV
var _booted: bool = false

# Audio state tracking
var _was_on_floor: bool = true
var _last_collision_normal: Vector2 = Vector2.ZERO


func _ready() -> void:
	_setup_point_light_texture()
	point_light.texture_scale = 3.2
	point_light.position = Vector2.ZERO
	point_light.shadow_filter = Light2D.SHADOW_FILTER_PCF5

	_setup_sfx()

	# Initialize light pulse
	_light_base_energy = point_light.energy

	DayNightSystem.phase_changed.connect(_on_phase_changed)
	_on_phase_changed(DayNightSystem.is_night)
	_booted = true

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


func _setup_sfx() -> void:
	_stream_step = ProceduralSfx.footstep_thump()
	_stream_interact = ProceduralSfx.interact_blip()
	_stream_dash = ProceduralSfx.dash_whoosh()
	_stream_phase_night = ProceduralSfx.phase_night_chime()
	_stream_phase_day = ProceduralSfx.phase_day_chime()
	_stream_bump = ProceduralSfx.bump_thud()
	_sfx_step.stream = _stream_step
	_sfx_step.volume_db = -10.0
	_sfx_action.volume_db = -5.0
	_sfx_step.max_distance = 5000.0
	_sfx_action.max_distance = 5000.0

	# Enhanced spatial audio settings
	_sfx_step.attenuation = 1.5
	_sfx_step.panning_strength = 2.0
	_sfx_action.attenuation = 1.2
	_sfx_action.panning_strength = 2.0
	_sfx_step.bus = &"SFX"
	_sfx_action.bus = &"SFX"


func _play_step() -> void:
	if not sfx_enabled:
		return
	_sfx_step.pitch_scale = randf_range(0.92, 1.08)
	_sfx_step.play()
	_emit_footstep_dust()


func _play_action(stream: AudioStreamWAV, pitch_scale: float = 1.0) -> void:
	if not sfx_enabled:
		return
	_sfx_action.stream = stream
	_sfx_action.pitch_scale = pitch_scale * randf_range(0.98, 1.02)  # Add tiny variation
	_sfx_action.play()


func _feel_camera_shake(strength: float, settle: float) -> void:
	var cam := _camera
	var shake := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(cam, "offset", shake, 0.04)
	tw.tween_property(cam, "offset", Vector2.ZERO, settle)


func _feel_squash(scale_a: Vector2, duration: float) -> void:
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD)
	tw.set_ease(Tween.EASE_OUT)
	_visual.scale = scale_a
	tw.tween_property(_visual, "scale", Vector2.ONE, duration)


func _on_phase_changed(is_night: bool) -> void:
	if is_night:
		point_light.color = Color(0.95, 0.35, 0.38)
		point_light.energy = 1.35
		_light_base_energy = 1.35
		_light_pulse_speed = 4.0  # Faster pulse for vampire
		_light_pulse_amount = 0.18  # Stronger pulse
	else:
		point_light.color = Color(1.0, 0.92, 0.72)
		point_light.energy = 0.95
		_light_base_energy = 0.95
		_light_pulse_speed = 1.5  # Slower pulse for human
		_light_pulse_amount = 0.08  # Subtler pulse
	_visual.queue_redraw()

	if sfx_enabled and _booted:
		_play_action(_stream_phase_night if is_night else _stream_phase_day)
		_feel_squash(Vector2(1.04, 0.96), 0.2)


func _get_move_axis() -> Vector2:
	## Returns movement vector supporting both arrows and WASD
	var dir := Vector2.ZERO

	# Horizontal: A/D and arrows
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		dir.x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		dir.x += 1.0

	# Vertical: W/S and arrows
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		dir.y -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		dir.y += 1.0

	return dir


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
	_update_footsteps(delta)


func _begin_dash() -> void:
	var move_input := _get_move_axis()
	if top_down:
		if move_input.length_squared() < 0.01:
			_dash_velocity = Vector2.RIGHT * dash_speed
		else:
			_dash_velocity = move_input.normalized() * dash_speed
			_last_move_dir = _dash_velocity.normalized()
	else:
		var dx := move_input.x
		if absf(dx) < 0.01:
			dx = 1.0
		_dash_velocity = Vector2(signf(dx) * dash_speed, 0.0)

	# Pitch shift dash sound: lower for night (vampire), higher for day (human)
	var dash_pitch: float = 0.85 if DayNightSystem.is_night else 1.15
	_play_action(_stream_dash, dash_pitch)
	_feel_camera_shake(5.5, 0.14)
	_feel_squash(Vector2(1.1, 0.88), 0.16)
	_emit_dash_smoke()

	_is_spawning_trail = true
	_ghost_spawn_timer = 0.0
	_spawn_dash_ghost()  # Spawn first ghost immediately
	_dash_duration_timer.wait_time = dash_duration
	_dash_duration_timer.start()


func _on_dash_duration_finished() -> void:
	_is_dashing = false
	_is_spawning_trail = false
	_dash_cooldown_timer.wait_time = dash_cooldown
	_dash_cooldown_timer.start()


func _top_down_move() -> void:
	var direction := _get_move_axis()
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		_last_move_dir = direction
	velocity = direction * speed
	var prev_velocity := velocity
	move_and_slide()

	# Collision feedback
	if is_on_wall() and velocity.length_squared() < prev_velocity.length_squared() * 0.5:
		if sfx_enabled and _stream_bump:
			_sfx_action.stream = _stream_bump
			_sfx_action.pitch_scale = randf_range(0.9, 1.1)
			_sfx_action.play()


func _side_view_move(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
	var move_input := _get_move_axis()
	velocity.x = move_input.x * speed
	move_and_slide()
	if absf(velocity.x) > 6.0:
		_last_move_dir = Vector2(signf(velocity.x), 0)


func _update_footsteps(delta: float) -> void:
	if not top_down or _is_dashing or not sfx_enabled:
		return
	if velocity.length_squared() < footstep_min_speed_sq:
		return
	_footstep_cooldown -= delta
	if _footstep_cooldown <= 0.0:
		_footstep_cooldown = footstep_interval
		_play_step()


func _process(delta: float) -> void:
	# Update light pulse
	_light_pulse_time += delta * _light_pulse_speed
	var pulse := sin(_light_pulse_time) * _light_pulse_amount
	point_light.energy = _light_base_energy + pulse

	# Update dash trail ghost spawning
	if _is_spawning_trail:
		_ghost_spawn_timer -= delta
		if _ghost_spawn_timer <= 0.0:
			_ghost_spawn_timer = _ghost_spawn_interval
			_spawn_dash_ghost()

	if Input.is_action_just_pressed("interact"):
		interact()


func interact() -> void:
	var space_state := get_world_2d().direct_space_state
	var face := _get_move_axis()
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
			_play_action(_stream_interact)
			_feel_squash(Vector2(1.05, 0.94), 0.12)
			return


func _emit_footstep_dust() -> void:
	if _footstep_dust:
		_footstep_dust.restart()
		_footstep_dust.emitting = true


func _emit_dash_smoke() -> void:
	if _dash_smoke:
		_dash_smoke.restart()
		_dash_smoke.emitting = true


func _spawn_dash_ghost() -> void:
	if not _dash_trail_container:
		return

	var ghost := Node2D.new()
	ghost.name = "DashGhost"
	ghost.rotation = _visual.rotation
	ghost.position = _visual.position
	_dash_trail_container.add_child(ghost)

	# Draw the ghost
	ghost.set_script(_DashGhostScript)
	ghost.set_ghost_color(DayNightSystem.is_night)

	# Fade out and remove
	var tw := ghost.create_tween()
	tw.set_trans(Tween.TRANS_QUAD)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(ghost, "modulate:a", 0.0, 0.35)
	tw.tween_callback(ghost.queue_free)
