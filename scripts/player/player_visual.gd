extends Node2D

## Player visual using sprites (placeholder textures, replace with actual PNGs)
## The scene should have two Sprite2D nodes: VampireSprite and HumanSprite

@onready var _vampire_sprite: Sprite2D = $VampireSprite
@onready var _human_sprite: Sprite2D = $HumanSprite

var _night: bool = true


func _ready() -> void:
	_night = DayNightSystem.is_night
	DayNightSystem.phase_changed.connect(_on_phase)
	_update_sprite_visibility()

	# Create placeholder textures if sprites exist but have no texture
	_setup_placeholder_textures()


func _setup_placeholder_textures() -> void:
	## Creates simple colored placeholder textures - replace with actual sprites
	if _vampire_sprite and _vampire_sprite.texture == null:
		_vampire_sprite.texture = _create_placeholder_texture(
			Color(0.18, 0.06, 0.12),  # Dark burgundy
			Vector2i(64, 80)
		)
	if _human_sprite and _human_sprite.texture == null:
		_human_sprite.texture = _create_placeholder_texture(
			Color(0.58, 0.48, 0.38),  # Warm brown
			Vector2i(48, 64)
		)


func _create_placeholder_texture(color: Color, size: Vector2i) -> ImageTexture:
	## Creates a simple colored rectangle as placeholder
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(color)
	# Add a lighter edge for visibility
	var edge_color := color.lightened(0.2)
	for x in range(size.x):
		img.set_pixel(x, 0, edge_color)
		img.set_pixel(x, size.y - 1, edge_color)
	for y in range(size.y):
		img.set_pixel(0, y, edge_color)
		img.set_pixel(size.x - 1, y, edge_color)

	var tex := ImageTexture.create_from_image(img)
	return tex


func _on_phase(is_night: bool) -> void:
	_night = is_night
	_update_sprite_visibility()


func _update_sprite_visibility() -> void:
	if _vampire_sprite:
		_vampire_sprite.visible = _night
	if _human_sprite:
		_human_sprite.visible = not _night


## Called by player.gd for effects - placeholder for future sprite animations
func set_light_pulse_intensity(intensity: float) -> void:
	## Reserved for future sprite-based effects (e.g., vampire eye glow)
	## You can implement modulate or shader effects here when using actual sprites
	if _night and _vampire_sprite:
		# Subtle glow effect on vampire during night
		var glow := 0.85 + intensity * 0.15
		_vampire_sprite.modulate = Color(glow, glow * 0.9, glow * 0.95, 1.0)
	elif _human_sprite:
		_human_sprite.modulate = Color.WHITE