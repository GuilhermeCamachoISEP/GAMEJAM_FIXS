extends Node2D
## Simplified ghost trail that fades out after dash
## Matches the enhanced player visual styles

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
	var edge := fill.darkened(0.15)
	edge.a = minf(fill.a + 0.08, 1.0)
	draw_colored_polygon(SoftShapes.circle_poly(center, radius * 1.12, 20), edge)
	draw_colored_polygon(SoftShapes.circle_poly(center, radius, 20), fill)


func _draw_triangle(p1: Vector2, p2: Vector2, p3: Vector2, color: Color) -> void:
	var pts: PackedVector2Array = [p1, p2, p3]
	draw_colored_polygon(pts, color)


func _draw_vampire_ghost() -> void:
	# Gothic vampire ghost - darker, more menacing
	var cape := Color(0.12, 0.04, 0.08, _alpha * 0.5)
	var cape_inner := Color(0.18, 0.07, 0.12, _alpha * 0.55)
	var body := Color(0.15, 0.06, 0.10, _alpha * 0.65)
	var head := Color(0.78, 0.72, 0.80, _alpha * 0.75)
	var eye_glow := Color(0.95, 0.15, 0.12, _alpha * 0.9)

	# Cape with bat-wing tips
	_soft_circle(Vector2(0, 20), 44.0, cape)
	_soft_circle(Vector2(0, 16), 32.0, cape_inner)

	# Simplified wing tip hints
	var wing_color := cape.darkened(0.1)
	_draw_triangle(Vector2(-38, 28), Vector2(-48, 38), Vector2(-28, 34), wing_color)
	_draw_triangle(Vector2(38, 28), Vector2(28, 34), Vector2(48, 38), wing_color)

	# Body
	_soft_circle(Vector2(0, 4), 14.0, body)

	# Head
	_soft_circle(Vector2(0, -22), 13.0, head)

	# Glowing eyes (simplified)
	draw_circle(Vector2(-7, -24), 3.0 * _alpha, eye_glow)
	draw_circle(Vector2(7, -24), 3.0 * _alpha, eye_glow)


func _draw_human_ghost() -> void:
	# Villager ghost - warm earthy tones
	var shirt := Color(0.58, 0.48, 0.38, _alpha * 0.6)
	var shirt_shadow := Color(0.48, 0.38, 0.30, _alpha * 0.55)
	var head := Color(0.92, 0.82, 0.72, _alpha * 0.75)

	# Torso
	_soft_circle(Vector2(0, 6), 20.0, shirt)
	_soft_circle(Vector2(0, 8), 14.0, shirt_shadow)

	# Arms
	var sleeve := Color(0.52, 0.42, 0.34, _alpha * 0.5)
	_soft_circle(Vector2(-22, 4), 9.0, sleeve)
	_soft_circle(Vector2(22, 4), 9.0, sleeve)

	# Head
	_soft_circle(Vector2(0, -22), 13.0, head)
