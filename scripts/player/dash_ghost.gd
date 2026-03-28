extends Node2D

## Simplified ghost trail matching the current facing.

const FACE_UP := 0
const FACE_RIGHT := 1
const FACE_DOWN := 2
const FACE_LEFT := 3

var _is_night: bool = true
var _alpha: float = 0.6
var _facing: int = FACE_DOWN


func set_ghost_color(night: bool) -> void:
	_is_night = night
	_alpha = 0.6
	queue_redraw()


func set_facing(face: int) -> void:
	_facing = face
	queue_redraw()


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	if _is_night:
		if _facing == FACE_DOWN:
			_draw_front_ghost(Color(0.88, 0.85, 0.94, _alpha * 0.78), Color(0.19, 0.04, 0.08, _alpha * 0.55), Color(0.05, 0.05, 0.08, _alpha * 0.7))
		else:
			_draw_back_ghost(Color(0.88, 0.85, 0.94, _alpha * 0.78), Color(0.19, 0.04, 0.08, _alpha * 0.55), Color(0.05, 0.05, 0.08, _alpha * 0.7))
	else:
		if _facing == FACE_DOWN:
			_draw_front_ghost(Color(0.95, 0.82, 0.69, _alpha * 0.78), Color(0.18, 0.74, 0.78, _alpha * 0.62), Color(0.29, 0.19, 0.1, _alpha * 0.68))
		else:
			_draw_back_ghost(Color(0.95, 0.82, 0.69, _alpha * 0.78), Color(0.18, 0.74, 0.78, _alpha * 0.62), Color(0.29, 0.19, 0.1, _alpha * 0.68))


func _soft_circle(center: Vector2, radius: float, fill: Color, edge_mul: float = 1.12) -> void:
	var edge := fill.darkened(0.12)
	edge.a = minf(fill.a + 0.08, 1.0)
	draw_colored_polygon(SoftShapes.circle_poly(center, radius * edge_mul, 20), edge)
	draw_colored_polygon(SoftShapes.circle_poly(center, radius, 20), fill)


func _soft_ellipse(center: Vector2, rx: float, ry: float, fill: Color, edge_mul: float = 1.08) -> void:
	var edge := fill.darkened(0.1)
	edge.a = minf(fill.a + 0.06, 1.0)
	draw_colored_polygon(SoftShapes.ellipse_poly(center, rx * edge_mul, ry * edge_mul, 24), edge)
	draw_colored_polygon(SoftShapes.ellipse_poly(center, rx, ry, 24), fill)


func _soft_polygon(points: PackedVector2Array, fill: Color, edge_mul: float = 1.06) -> void:
	var edge := fill.darkened(0.12)
	edge.a = minf(fill.a + 0.08, 1.0)
	var outline := PackedVector2Array()
	for point in points:
		outline.append(point * edge_mul)
	draw_colored_polygon(outline, edge)
	draw_colored_polygon(points, fill)


func _draw_back_ghost(head: Color, body: Color, hair: Color) -> void:
	_soft_ellipse(Vector2(0, 11), 20.0, 15.0, body)
	_soft_circle(Vector2(0, -4), 15.0, head)
	_soft_polygon(PackedVector2Array([
		Vector2(-13, -8),
		Vector2(-11, -17),
		Vector2(-5, -21),
		Vector2(0, -17),
		Vector2(5, -21),
		Vector2(11, -17),
		Vector2(13, -8),
		Vector2(10, 1),
		Vector2(0, 3),
		Vector2(-10, 1)
	]), hair)


func _draw_front_ghost(head: Color, body: Color, hair: Color) -> void:
	_soft_ellipse(Vector2(0, 11), 20.0, 15.0, body)
	_soft_circle(Vector2(0, -4), 15.0, head)
	_soft_polygon(PackedVector2Array([
		Vector2(-13, -9),
		Vector2(-10, -17),
		Vector2(-4, -20),
		Vector2(0, -18),
		Vector2(4, -20),
		Vector2(10, -17),
		Vector2(13, -9),
		Vector2(10, -2),
		Vector2(0, -5),
		Vector2(-10, -2)
	]), hair)
