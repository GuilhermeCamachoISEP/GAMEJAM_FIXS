extends Node2D
## Ghost trail for dash - uses colored placeholder shapes
## When actual sprites are added, this can be updated to use sprite references

var _is_night: bool = true
var _alpha: float = 0.6
var _color: Color = Color.WHITE


func set_ghost_color(night: bool) -> void:
	_is_night = night
	_alpha = 0.6
	# Set color based on form
	if night:
		_color = Color(0.18, 0.06, 0.12, _alpha)  # Dark burgundy for vampire
	else:
		_color = Color(0.58, 0.48, 0.38, _alpha)  # Warm brown for human
	queue_redraw()


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	# Draw a simplified ghost shape - colored ellipse
	var size := Vector2(48.0, 64.0)
	var center := Vector2.ZERO

	# Draw ghost body
	var pts := SoftShapes.ellipse_poly(center, size.x * 0.5, size.y * 0.5, 24)
	draw_colored_polygon(pts, _color)

	# Draw highlight edge
	var edge_color := _color.lightened(0.15)
	var edge_pts := SoftShapes.ellipse_poly(center, size.x * 0.55, size.y * 0.55, 24)
	draw_colored_polygon(edge_pts, edge_color)
	draw_colored_polygon(pts, _color)