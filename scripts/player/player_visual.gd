extends Node2D

## Desenho “massinha”: círculos/elipses suaves; vampiro gótico, humano vilarejo.
## O pai (`Player`) roda este nó para apontar na direção do movimento.

var _night: bool = true
var _eye_glow_intensity: float = 1.0

# Animation time for subtle effects
var _anim_time: float = 0.0


func _ready() -> void:
	_night = DayNightSystem.is_night
	DayNightSystem.phase_changed.connect(_on_phase)
	queue_redraw()


func _process(delta: float) -> void:
	_anim_time += delta
	# Update eye glow pulse (vampire only)
	if _night:
		_eye_glow_intensity = 0.7 + sin(_anim_time * 3.0) * 0.3
		queue_redraw()


func set_light_pulse_intensity(intensity: float) -> void:
	## Called by player.gd to sync eye glow with point light pulse.
	_eye_glow_intensity = intensity
	if _night:
		queue_redraw()


func _on_phase(is_night: bool) -> void:
	_night = is_night
	queue_redraw()


func _draw() -> void:
	if _night:
		_draw_vampire()
	else:
		_draw_human()


func _soft_circle(center: Vector2, radius: float, fill: Color, edge_mul: float = 1.12) -> void:
	var edge := fill.darkened(0.15)
	edge.a = minf(fill.a + 0.1, 1.0)
	draw_colored_polygon(SoftShapes.circle_poly(center, radius * edge_mul, 28), edge)
	draw_colored_polygon(SoftShapes.circle_poly(center, radius, 28), fill)


func _soft_ellipse(center: Vector2, rx: float, ry: float, fill: Color, edge_mul: float = 1.08) -> void:
	var edge := fill.darkened(0.12)
	edge.a = minf(fill.a + 0.08, 1.0)
	draw_colored_polygon(SoftShapes.ellipse_poly(center, rx * edge_mul, ry * edge_mul, 36), edge)
	draw_colored_polygon(SoftShapes.ellipse_poly(center, rx, ry, 36), fill)


func _draw_triangle(p1: Vector2, p2: Vector2, p3: Vector2, color: Color) -> void:
	var pts: PackedVector2Array = [p1, p2, p3]
	draw_colored_polygon(pts, color)


func _draw_vampire() -> void:
	# ═══════════════════════════════════════════════════════════════════════
	# VAMPIRE - GOTHIC/MENACING DESIGN
	# Darker, sharper palette with bat-wing cape, glowing eyes, fangs
	# ═══════════════════════════════════════════════════════════════════════

	# Colors - deeper, more saturated gothic palette
	var cape_outer := Color(0.12, 0.04, 0.08, 1.0)      # Deep black-red
	var cape_inner := Color(0.18, 0.07, 0.12, 1.0)      # Dark wine
	var cape_highlight := Color(0.28, 0.10, 0.18, 1.0)  # Burgundy highlight
	var body_dark := Color(0.15, 0.06, 0.10, 1.0)       # Near-black body
	var body_mid := Color(0.20, 0.08, 0.14, 1.0)        # Dark red-brown
	var skin_pale := Color(0.78, 0.72, 0.80, 1.0)       # Pale lavender-white
	var eye_glow := Color(0.95, 0.15, 0.12, _eye_glow_intensity)  # Glowing red
	var fang_white := Color(0.95, 0.94, 0.90, 1.0)      # Ivory white

	# ─── CAPE WITH BAT-WING TIPS ───
	# Main cape body (larger, more dramatic)
	_soft_ellipse(Vector2(0, 20), 44.0, 26.0, cape_outer)
	_soft_ellipse(Vector2(0, 16), 32.0, 18.0, cape_inner)
	_soft_ellipse(Vector2(0, 12), 20.0, 10.0, cape_highlight)

	# Bat-wing cape tips (pointed triangles at bottom corners)
	var wing_tip_color := cape_outer.darkened(0.1)
	# Left wing tip
	_draw_triangle(
		Vector2(-38, 28),   # Top inner
		Vector2(-52, 42),   # Bottom outer (point)
		Vector2(-28, 35),   # Bottom inner
		wing_tip_color
	)
	# Right wing tip
	_draw_triangle(
		Vector2(38, 28),    # Top inner
		Vector2(28, 35),    # Bottom inner
		Vector2(52, 42),    # Bottom outer (point)
		wing_tip_color
	)

	# ─── COLLAR (high vampire collar) ───
	_soft_ellipse(Vector2(0, -6), 18.0, 8.0, cape_inner)

	# ─── BODY ───
	_soft_circle(Vector2(0, 4), 14.0, body_dark)
	_soft_circle(Vector2(0, 2), 10.0, body_mid)

	# ─── HEAD ───
	_soft_circle(Vector2(0, -22), 13.0, skin_pale)

	# ─── GLOWING EYES ───
	var eye_y := -24.0
	var eye_spacing := 7.0
	var eye_radius := 3.0 * _eye_glow_intensity

	# Eye glow aura (larger, semi-transparent)
	var glow_color := Color(0.95, 0.20, 0.15, 0.4 * _eye_glow_intensity)
	draw_circle(Vector2(-eye_spacing, eye_y), eye_radius * 2.5, glow_color)
	draw_circle(Vector2(eye_spacing, eye_y), eye_radius * 2.5, glow_color)

	# Eye cores (sharp red points)
	draw_circle(Vector2(-eye_spacing, eye_y), eye_radius, eye_glow)
	draw_circle(Vector2(eye_spacing, eye_y), eye_radius, eye_glow)

	# ─── FANGS ───
	var fang_y := -16.0
	var fang_length := 5.0
	# Left fang
	_draw_triangle(
		Vector2(-4, fang_y),
		Vector2(-6, fang_y + fang_length),
		Vector2(-2, fang_y),
		fang_white
	)
	# Right fang
	_draw_triangle(
		Vector2(4, fang_y),
		Vector2(2, fang_y),
		Vector2(6, fang_y + fang_length),
		fang_white
	)


func _draw_human() -> void:
	# ═══════════════════════════════════════════════════════════════════════
	# HUMAN - VILLAGER DESIGN
	# Simple, approachable, warm earthy tones, clearly vulnerable
	# ═══════════════════════════════════════════════════════════════════════

	# Colors - warm, earthy villager palette
	var shirt_base := Color(0.58, 0.48, 0.38, 1.0)      # Warm brown
	var shirt_shadow := Color(0.48, 0.38, 0.30, 1.0)    # Darker brown
	var shirt_highlight := Color(0.65, 0.55, 0.45, 1.0) # Light brown
	var collar_white := Color(0.92, 0.90, 0.86, 1.0)    # Off-white
	var sleeve := Color(0.52, 0.42, 0.34, 1.0)          # Sleeve color
	var pants := Color(0.35, 0.30, 0.26, 1.0)           # Dark pants hint
	var skin := Color(0.92, 0.82, 0.72, 1.0)           # Warm skin tone
	var skin_shadow := Color(0.82, 0.72, 0.62, 1.0)     # Skin shadow

	# ─── BODY/TORSO ───
	# Main torso (rounded, friendly shape)
	_soft_ellipse(Vector2(0, 6), 20.0, 24.0, shirt_base)
	_soft_ellipse(Vector2(0, 8), 14.0, 16.0, shirt_shadow)

	# Collar detail (simple V-neck)
	_draw_triangle(
		Vector2(-6, -4),
		Vector2(0, 8),
		Vector2(6, -4),
		collar_white
	)

	# ─── SLEEVES ───
	# Arms spread slightly wider, more natural pose
	_soft_circle(Vector2(-22, 4), 9.0, sleeve)
	_soft_circle(Vector2(22, 4), 9.0, sleeve)

	# Hands (small circles at end of arms)
	_soft_circle(Vector2(-26, 8), 5.0, skin)
	_soft_circle(Vector2(26, 8), 5.0, skin)

	# ─── PANTS HINT ───
	# Simple indication at bottom
	_soft_ellipse(Vector2(0, 22), 12.0, 8.0, pants)

	# ─── HEAD ───
	# Slightly larger head for friendly villager look
	_soft_circle(Vector2(0, -22), 13.0, skin)
	# Subtle cheek shadows for dimension
	_soft_circle(Vector2(-6, -18), 3.5, skin_shadow)
	_soft_circle(Vector2(6, -18), 3.5, skin_shadow)

	# ─── SIMPLE FACE (eyes and friendly expression) ───
	# Simple dot eyes (not glowing like vampire)
	var eye_color := Color(0.25, 0.18, 0.15, 1.0)  # Dark brown
	draw_circle(Vector2(-5, -24), 2.0, eye_color)
	draw_circle(Vector2(5, -24), 2.0, eye_color)

	# Small friendly smile (subtle arc)
	draw_arc(Vector2(0, -18), 4.0, PI * 0.2, PI * 0.8, 12, Color(0.35, 0.25, 0.20, 0.7), 1.5, true)
