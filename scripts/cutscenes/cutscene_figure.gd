extends Node2D
## Figuras para cutscene — humano simples; vampiro mais detalhado (silhueta “real” com capa, olhos, brilho).

enum Mode { HUMAN, VAMPIRE }

@export var mode: Mode = Mode.HUMAN


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	if mode == Mode.VAMPIRE:
		_draw_vampire_detailed()
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


func _draw_vampire_detailed() -> void:
	## Paleta: noite, pele fria, capa pesada, olhos não-humanos.
	var cape_outer := Color(0.06, 0.04, 0.1, 1.0)
	var cape_mid := Color(0.14, 0.06, 0.12, 1.0)
	var cape_fold := Color(0.22, 0.1, 0.18, 1.0)
	var cape_rim := Color(0.38, 0.16, 0.24, 0.85)
	var suit := Color(0.12, 0.1, 0.14, 1.0)
	var suit_hi := Color(0.2, 0.16, 0.2, 1.0)
	var skin := Color(0.72, 0.64, 0.7, 1.0)
	var skin_shadow := Color(0.48, 0.4, 0.5, 1.0)
	var hair := Color(0.07, 0.05, 0.09, 1.0)
	var hair_hi := Color(0.14, 0.12, 0.18, 1.0)
	var eye_glow := Color(0.95, 0.18, 0.28, 1.0)
	var eye_core := Color(1.0, 0.75, 0.55, 1.0)
	var fang := Color(0.92, 0.9, 0.88, 0.95)

	# Capa em camadas (volume e dobra)
	_soft_ellipse(Vector2(4, 34), 52.0, 30.0, cape_outer)
	_soft_ellipse(Vector2(0, 26), 44.0, 26.0, cape_mid)
	_soft_ellipse(Vector2(-6, 18), 34.0, 20.0, cape_fold)
	draw_arc(Vector2(0, 28), 46.0, PI * 0.18, PI * 0.92, 42, cape_rim, 4.0, true)

	# Gola alta / colarinho
	_soft_ellipse(Vector2(0, -2), 24.0, 16.0, suit)
	draw_line(Vector2(-20, 4), Vector2(20, 4), suit_hi, 3.0, true)

	# Torso e ombros
	_soft_ellipse(Vector2(0, 8), 22.0, 28.0, suit)
	_soft_circle(Vector2(-18, 6), 11.0, suit)
	_soft_circle(Vector2(18, 6), 11.0, suit)

	# Cabeça alongada, maxilar
	_soft_ellipse(Vector2(0, -26), 15.0, 19.0, skin_shadow)
	_soft_ellipse(Vector2(0, -28), 13.0, 17.0, skin)

	# Cabelo penteado para trás
	_soft_ellipse(Vector2(0, -38), 16.0, 12.0, hair)
	_soft_ellipse(Vector2(-4, -40), 10.0, 8.0, hair_hi)
	_soft_ellipse(Vector2(8, -36), 9.0, 7.0, hair_hi)

	# Olhos com brilho (par de “lentes” vivas)
	_soft_circle(Vector2(-7, -30), 4.2, eye_glow)
	_soft_circle(Vector2(7, -30), 4.2, eye_glow)
	_soft_circle(Vector2(-7, -30), 1.6, eye_core)
	_soft_circle(Vector2(7, -30), 1.6, eye_core)

	# Nariz sugerido
	draw_line(Vector2(0, -26), Vector2(0, -20), skin.darkened(0.35), 1.8, true)

	# Boca + presas discretas
	draw_line(Vector2(-8, -14), Vector2(8, -14), skin_shadow, 2.0, true)
	var fang_pts := PackedVector2Array([Vector2(-5, -14), Vector2(-3, -8), Vector2(-1, -14)])
	draw_colored_polygon(fang_pts, fang)
	var fang_pts2 := PackedVector2Array([Vector2(5, -14), Vector2(3, -8), Vector2(1, -14)])
	draw_colored_polygon(fang_pts2, fang)

	# Viço de luz na face (highlight)
	_soft_circle(Vector2(-4, -32), 3.5, Color(1, 1, 1, 0.12))


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
