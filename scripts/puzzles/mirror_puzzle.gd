extends Node2D
## Puzzle de espelhos: noite — rodar espelhos; dia — raio refletido até ao receptor.
## Sinal: `light_puzzle_completed`

signal light_puzzle_completed

const _MAX_BOUNCES := 12
const _RAY_LEN := 8000.0
const _EPS := 2.0

@export_flags_2d_physics var mirror_collision_mask: int = 128
@export_flags_2d_physics var receiver_collision_mask: int = 256

@onready var _beam: Line2D = $Beam
@onready var _sun: Marker2D = $Sun
@export var sun_direction: Vector2 = Vector2(1, 0.15)

var _done: bool = false


func _ready() -> void:
	var d := sun_direction
	if d.length_squared() < 0.001:
		d = Vector2.RIGHT
	sun_direction = d.normalized()


func _physics_process(_delta: float) -> void:
	if _done:
		return
	if DayNightSystem.is_night:
		_beam.clear_points()
		return
	if _trace_light():
		_done = true
		light_puzzle_completed.emit()


func _trace_light() -> bool:
	var space := get_world_2d().direct_space_state as PhysicsDirectSpaceState2D
	var p: Vector2 = _sun.global_position
	var dir: Vector2 = sun_direction.rotated(global_rotation).normalized()
	var points_debug: PackedVector2Array = [to_local(p)]

	for i in _MAX_BOUNCES:
		var q := PhysicsRayQueryParameters2D.create(p, p + dir * _RAY_LEN)
		q.collide_with_areas = false
		q.collide_with_bodies = true
		q.collision_mask = mirror_collision_mask

		var hit: Dictionary = space.intersect_ray(q)
		if hit:
			dir = dir.bounce(hit.normal).normalized()
			p = hit.position + dir * _EPS
			points_debug.append(to_local(p))
			continue

		var q2 := PhysicsRayQueryParameters2D.create(p, p + dir * _RAY_LEN)
		q2.collide_with_areas = true
		q2.collide_with_bodies = false
		q2.collision_mask = receiver_collision_mask

		var hit2: Dictionary = space.intersect_ray(q2)
		if hit2 and hit2.collider.is_in_group("light_receiver"):
			points_debug.append(to_local(hit2.position))
			_beam.points = points_debug
			return true

		_beam.points = points_debug
		return false

	return false
