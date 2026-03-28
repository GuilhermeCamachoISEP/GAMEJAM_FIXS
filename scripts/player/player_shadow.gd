extends Node2D

## Sombra elíptica no chão (não roda com o personagem).


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var pts := SoftShapes.ellipse_poly(Vector2(0, 10), 34.0, 15.0, 40)
	draw_colored_polygon(pts, Color(0, 0, 0, 0.2))
	var inner := SoftShapes.ellipse_poly(Vector2(0, 10), 28.0, 11.0, 36)
	draw_colored_polygon(inner, Color(0, 0, 0, 0.08))
