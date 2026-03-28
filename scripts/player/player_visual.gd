extends Node2D

## Simple cardinal-facing character art for top-down play.

const FACE_UP := 0
const FACE_RIGHT := 1
const FACE_DOWN := 2
const FACE_LEFT := 3

var _night: bool = true
var _facing: int = FACE_DOWN


func _ready() -> void:
	_night = DayNightSystem.is_night
	DayNightSystem.phase_changed.connect(_on_phase)
	queue_redraw()


func _on_phase(is_night: bool) -> void:
	_night = is_night
	queue_redraw()


func set_facing(face: int) -> void:
	if _facing == face:
		return
	_facing = face
	queue_redraw()


func _draw() -> void:
	if _night:
		if _facing == FACE_DOWN:
			_draw_vampire_front()
		else:
			_draw_vampire_back()
	else:
		if _facing == FACE_DOWN:
			_draw_human_front()
		else:
			_draw_human_back()


func _soft_circle(center: Vector2, radius: float, fill: Color, edge_mul: float = 1.12) -> void:
	var edge := fill.darkened(0.12)
	edge.a = minf(fill.a + 0.08, 1.0)
	draw_colored_polygon(SoftShapes.circle_poly(center, radius * edge_mul, 28), edge)
	draw_colored_polygon(SoftShapes.circle_poly(center, radius, 28), fill)


func _soft_ellipse(center: Vector2, rx: float, ry: float, fill: Color, edge_mul: float = 1.08) -> void:
	var edge := fill.darkened(0.1)
	edge.a = minf(fill.a + 0.06, 1.0)
	draw_colored_polygon(SoftShapes.ellipse_poly(center, rx * edge_mul, ry * edge_mul, 36), edge)
	draw_colored_polygon(SoftShapes.ellipse_poly(center, rx, ry, 36), fill)


func _soft_polygon(points: PackedVector2Array, fill: Color, edge_mul: float = 1.06) -> void:
	var edge := fill.darkened(0.12)
	edge.a = minf(fill.a + 0.08, 1.0)
	var outline := PackedVector2Array()
	for point in points:
		outline.append(point * edge_mul)
	draw_colored_polygon(outline, edge)
	draw_colored_polygon(points, fill)


func _draw_mouth_arc(center: Vector2, radius: float, color: Color, smile: bool = true) -> void:
	if smile:
		draw_arc(center, radius, 0.25, PI - 0.25, 16, color, 1.8, true)
	else:
		draw_arc(center + Vector2(0, radius * 0.35), radius, PI + 0.25, TAU - 0.25, 16, color, 1.8, true)


func _draw_vampire_back() -> void:
	var cape := Color(0.22, 0.04, 0.08, 1.0)
	var collar := Color(0.76, 0.12, 0.18, 1.0)
	var skin := Color(0.94, 0.92, 1.0, 1.0)
	var hair := Color(0.04, 0.04, 0.07, 1.0)
	var suit := Color(0.12, 0.12, 0.16, 1.0)

	var hair_shape := PackedVector2Array([
		Vector2(-16, -10),
		Vector2(-14, -22),
		Vector2(-6, -27),
		Vector2(0, -17),
		Vector2(6, -27),
		Vector2(14, -22),
		Vector2(16, -10),
		Vector2(13, 2),
		Vector2(6, 9),
		Vector2(0, 6),
		Vector2(-6, 9),
		Vector2(-13, 2)
	])

	_soft_ellipse(Vector2(0, 11), 25.0, 20.0, cape)
	_soft_polygon(PackedVector2Array([
		Vector2(-19, 4),
		Vector2(-10, -8),
		Vector2(0, -2),
		Vector2(10, -8),
		Vector2(19, 4),
		Vector2(10, 13),
		Vector2(-10, 13)
	]), collar)
	_soft_ellipse(Vector2(0, 17), 11.0, 8.0, suit)
	_soft_circle(Vector2(0, -5), 18.5, skin)
	_soft_polygon(hair_shape, hair)
	_soft_circle(Vector2(-10, -18), 2.3, hair, 1.18)
	_soft_circle(Vector2(10, -18), 2.3, hair, 1.18)


func _draw_vampire_front() -> void:
	var cape := Color(0.22, 0.04, 0.08, 1.0)
	var collar := Color(0.84, 0.12, 0.18, 1.0)
	var skin := Color(0.96, 0.94, 1.0, 1.0)
	var hair := Color(0.04, 0.04, 0.07, 1.0)
	var suit := Color(0.12, 0.12, 0.16, 1.0)
	var eye_white := Color(1.0, 0.95, 0.95, 1.0)
	var pupil := Color(0.82, 0.05, 0.08, 1.0)
	var mouth := Color(0.35, 0.04, 0.08, 1.0)
	var fang := Color(1.0, 1.0, 1.0, 1.0)

	_soft_ellipse(Vector2(0, 11), 25.0, 20.0, cape)
	_soft_polygon(PackedVector2Array([
		Vector2(-19, 4),
		Vector2(-10, 14),
		Vector2(10, 14),
		Vector2(19, 4),
		Vector2(0, -2)
	]), collar)
	_soft_ellipse(Vector2(0, 17), 11.0, 8.0, suit)
	_soft_circle(Vector2(0, -5), 18.5, skin)
	_soft_polygon(PackedVector2Array([
		Vector2(-17, -11),
		Vector2(-14, -23),
		Vector2(-5, -27),
		Vector2(0, -18),
		Vector2(5, -27),
		Vector2(14, -23),
		Vector2(17, -11),
		Vector2(14, -2),
		Vector2(7, -5),
		Vector2(0, -1),
		Vector2(-7, -5),
		Vector2(-14, -2)
	]), hair)
	_soft_ellipse(Vector2(-6, -6), 3.3, 2.6, eye_white, 1.12)
	_soft_ellipse(Vector2(6, -6), 3.3, 2.6, eye_white, 1.12)
	_soft_circle(Vector2(-6, -6), 1.6, pupil, 1.18)
	_soft_circle(Vector2(6, -6), 1.6, pupil, 1.18)
	_soft_ellipse(Vector2(0, -1), 1.2, 1.8, skin.darkened(0.16), 1.1)
	_draw_mouth_arc(Vector2(0, 5), 4.8, mouth, false)
	_soft_polygon(PackedVector2Array([
		Vector2(-4.8, 5.0),
		Vector2(-2.2, 5.0),
		Vector2(-3.6, 11.4)
	]), fang, 1.08)
	_soft_polygon(PackedVector2Array([
		Vector2(2.2, 5.0),
		Vector2(4.8, 5.0),
		Vector2(3.6, 11.4)
	]), fang, 1.08)


func _draw_human_back() -> void:
	var shirt := Color(0.12, 0.88, 1.0, 1.0)
	var collar := Color(1.0, 1.0, 1.0, 1.0)
	var skin := Color(0.98, 0.84, 0.7, 1.0)
	var hair := Color(0.26, 0.18, 0.1, 1.0)

	var hair_shape := PackedVector2Array([
		Vector2(-15, -9),
		Vector2(-13, -20),
		Vector2(-6, -24),
		Vector2(0, -21),
		Vector2(6, -24),
		Vector2(13, -20),
		Vector2(15, -9),
		Vector2(12, 1),
		Vector2(0, 4),
		Vector2(-12, 1)
	])

	_soft_ellipse(Vector2(0, 14), 18.5, 13.5, shirt)
	_soft_ellipse(Vector2(0, 8), 8.5, 5.4, collar)
	_soft_circle(Vector2(0, -4), 17.5, skin)
	_soft_polygon(hair_shape, hair)


func _draw_human_front() -> void:
	var shirt := Color(0.12, 0.88, 1.0, 1.0)
	var collar := Color(1.0, 1.0, 1.0, 1.0)
	var skin := Color(0.98, 0.84, 0.7, 1.0)
	var hair := Color(0.26, 0.18, 0.1, 1.0)
	var eye_white := Color(1.0, 1.0, 1.0, 1.0)
	var pupil := Color(0.16, 0.13, 0.12, 1.0)
	var mouth := Color(0.66, 0.34, 0.28, 1.0)

	_soft_ellipse(Vector2(0, 14), 18.5, 13.5, shirt)
	_soft_ellipse(Vector2(0, 8), 8.5, 5.4, collar)
	_soft_circle(Vector2(0, -4), 17.5, skin)
	_soft_polygon(PackedVector2Array([
		Vector2(-15, -10),
		Vector2(-12, -20),
		Vector2(-5, -24),
		Vector2(0, -22),
		Vector2(5, -24),
		Vector2(12, -20),
		Vector2(15, -10),
		Vector2(12, -2),
		Vector2(0, -6),
		Vector2(-12, -2)
	]), hair)
	_soft_ellipse(Vector2(-5, -4), 2.7, 2.2, eye_white, 1.1)
	_soft_ellipse(Vector2(5, -4), 2.7, 2.2, eye_white, 1.1)
	_soft_circle(Vector2(-5, -4), 1.2, pupil, 1.18)
	_soft_circle(Vector2(5, -4), 1.2, pupil, 1.18)
	_soft_ellipse(Vector2(0, -0.5), 1.0, 1.5, skin.darkened(0.14), 1.1)
	_draw_mouth_arc(Vector2(0, 4), 4.3, mouth, true)
