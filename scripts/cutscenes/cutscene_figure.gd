extends Node2D
## Figuras simples para cutscene — paleta alinhada a `player_visual.gd` (humano vs vampiro).

enum Mode { HUMAN, VAMPIRE }

@export var mode: Mode = Mode.HUMAN


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	if mode == Mode.VAMPIRE:
		_draw_vampire()
	else:
		_draw_human()


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


func _draw_vampire() -> void:
	var cape := Color(0.2, 0.09, 0.16, 1.0)
	var cape_hi := Color(0.28, 0.12, 0.22, 1.0)
	var trim := Color(0.48, 0.22, 0.32, 1.0)
	var body := Color(0.24, 0.1, 0.18, 1.0)
	var head := Color(0.76, 0.68, 0.78, 1.0)
	_soft_ellipse(Vector2(0, 18), 40.0, 22.0, cape)
	_soft_ellipse(Vector2(0, 14), 28.0, 14.0, cape_hi)
	draw_arc(Vector2(0, 22), 30.0, PI * 0.12, PI * 0.88, 36, trim, 3.5, true)
	_soft_circle(Vector2(0, 2), 15.5, body)
	_soft_circle(Vector2(0, -22), 12.0, head)


func _draw_human() -> void:
	var shirt := Color(0.5, 0.42, 0.36, 1.0)
	var shirt_dark := Color(0.4, 0.34, 0.3, 1.0)
	var sleeve := Color(0.44, 0.38, 0.34, 1.0)
	var head := Color(0.92, 0.82, 0.72, 1.0)
	_soft_ellipse(Vector2(0, 5), 18.0, 22.0, shirt)
	_soft_ellipse(Vector2(0, 6), 14.0, 18.0, shirt_dark)
	_soft_circle(Vector2(-21, 3), 8.5, sleeve)
	_soft_circle(Vector2(21, 3), 8.5, sleeve)
	_soft_circle(Vector2(0, -22), 12.0, head)
