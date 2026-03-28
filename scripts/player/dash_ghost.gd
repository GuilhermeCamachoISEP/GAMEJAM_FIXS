extends Node2D
## Simplified ghost trail that fades out after dash

var _is_night: bool = true
var _alpha: float = 0.6


func set_ghost_color(night: bool) -> void:
	_is_night = night
	_alpha = 0.6
	queue_redraw()


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	if _is_night:
		_draw_vampire_ghost()
	else:
		_draw_human_ghost()


func _soft_circle(center: Vector2, radius: float, fill: Color) -> void:
	var edge := fill.darkened(0.12)
	edge.a = minf(fill.a + 0.08, 1.0)
	draw_colored_polygon(SoftShapes.circle_poly(center, radius * 1.12, 20), edge)
	draw_colored_polygon(SoftShapes.circle_poly(center, radius, 20), fill)


func _draw_vampire_ghost() -> void:
	var cape := Color(0.2, 0.09, 0.16, _alpha * 0.5)
	var body := Color(0.24, 0.1, 0.18, _alpha * 0.7)
	var head := Color(0.76, 0.68, 0.78, _alpha * 0.8)

	# Simplified cape
	_soft_circle(Vector2(0, 18), 38.0, cape)
	# Body
	_soft_circle(Vector2(0, 2), 14.0, body)
	# Head
	_soft_circle(Vector2(0, -22), 11.0, head)


func _draw_human_ghost() -> void:
	var shirt := Color(0.5, 0.42, 0.36, _alpha * 0.6)
	var head := Color(0.92, 0.82, 0.72, _alpha * 0.8)

	# Simplified torso
	_soft_circle(Vector2(0, 5), 16.0, shirt)
	# Head
	_soft_circle(Vector2(0, -22), 11.0, head)
