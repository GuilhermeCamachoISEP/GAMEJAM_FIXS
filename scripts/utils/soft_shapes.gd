extends RefCounted
class_name SoftShapes

## Polígonos com muitos vértices para aspeto arredondado (estilo “massinha”).


static func circle_poly(center: Vector2, radius: float, segments: int = 32) -> PackedVector2Array:
	var pts: PackedVector2Array = []
	for i in segments:
		var t: float = TAU * float(i) / float(segments)
		pts.append(center + Vector2(cos(t), sin(t)) * radius)
	return pts


static func ellipse_poly(center: Vector2, rx: float, ry: float, segments: int = 36) -> PackedVector2Array:
	var pts: PackedVector2Array = []
	for i in segments:
		var t: float = TAU * float(i) / float(segments)
		pts.append(center + Vector2(cos(t) * rx, sin(t) * ry))
	return pts
