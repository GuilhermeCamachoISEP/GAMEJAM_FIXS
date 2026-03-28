extends Node2D
## Memory Path Puzzle - displays path at night, player must memorize and follow during day.

signal puzzle_completed

## Grid configuration
@export var tile_size: float = 64.0
@export var grid_offset: Vector2 = Vector2.ZERO
@export var grid_width: int = 5
@export var grid_height: int = 5

## Path definition - array of Vector2i positions (column, row)
@export var correct_path: Array[Vector2i] = [
	Vector2i(0, 2),
	Vector2i(1, 2),
	Vector2i(2, 2),
	Vector2i(2, 1),
	Vector2i(2, 0),
	Vector2i(3, 0),
	Vector2i(4, 0)
]

## Visual references
@export var tile_scene: PackedScene

## Puzzle state
var current_step: int = 0
var is_active: bool = true
var is_path_visible: bool = false
var puzzle_solved: bool = false

# Tile tracking
var _tiles: Dictionary = {}  # position -> tile node
var _path_tiles: Array = []  # tiles that are part of the path

# Player reference
var _player: Node2D
var _last_player_tile: Vector2i = Vector2i(-1, -1)


func _ready() -> void:
	_create_grid()
	_connect_to_day_night()
	_update_path_visibility(false)
	# Add collision area for puzzle detection
	_create_puzzle_area()


func _create_grid() -> void:
	# Create visual grid tiles
	for row in range(grid_height):
		for col in range(grid_width):
			var pos = Vector2i(col, row)
			var world_pos = grid_offset + Vector2(col * tile_size, row * tile_size)

			var tile = _create_tile(pos, world_pos)
			_tiles[pos] = tile
			add_child(tile)


func _create_tile(pos: Vector2i, world_pos: Vector2) -> Node2D:
	var tile = Node2D.new()
	tile.name = "Tile_%d_%d" % [pos.x, pos.y]
	tile.position = world_pos

	# Create visual polygon for the tile
	var poly = Polygon2D.new()
	poly.name = "Visual"
	poly.polygon = PackedVector2Array([
		Vector2(-tile_size/2 + 2, -tile_size/2 + 2),
		Vector2(tile_size/2 - 2, -tile_size/2 + 2),
		Vector2(tile_size/2 - 2, tile_size/2 - 2),
		Vector2(-tile_size/2 + 2, tile_size/2 - 2)
	])
	poly.color = Color(0.3, 0.3, 0.3, 0.5)
	tile.add_child(poly)

	# Create border
	var border = Line2D.new()
	border.name = "Border"
	border.points = PackedVector2Array([
		Vector2(-tile_size/2 + 2, -tile_size/2 + 2),
		Vector2(tile_size/2 - 2, -tile_size/2 + 2),
		Vector2(tile_size/2 - 2, tile_size/2 - 2),
		Vector2(-tile_size/2 + 2, tile_size/2 - 2),
		Vector2(-tile_size/2 + 2, -tile_size/2 + 2)
	])
	border.width = 2.0
	border.default_color = Color(0.5, 0.5, 0.5, 0.8)
	tile.add_child(border)

	# Create glow indicator (for path tiles, hidden by default)
	var glow = Polygon2D.new()
	glow.name = "Glow"
	glow.polygon = PackedVector2Array([
		Vector2(-tile_size/2 + 4, -tile_size/2 + 4),
		Vector2(tile_size/2 - 4, -tile_size/2 + 4),
		Vector2(tile_size/2 - 4, tile_size/2 - 4),
		Vector2(-tile_size/2 + 4, tile_size/2 - 4)
	])
	glow.color = Color(1.0, 0.8, 0.2, 0.0)  # Start invisible
	tile.add_child(glow)

	return tile


func _connect_to_day_night() -> void:
	if DayNightSystem:
		DayNightSystem.phase_changed.connect(_on_phase_changed)
		# Initialize based on current phase
		_on_phase_changed(DayNightSystem.is_night)


func _on_phase_changed(is_night: bool) -> void:
	is_path_visible = is_night
	_update_path_visibility(is_night)


func _update_path_visibility(visible: bool) -> void:
	for pos in correct_path:
		var tile = _tiles.get(pos)
		if tile:
			var glow = tile.get_node_or_null("Glow") as Polygon2D
			if glow:
				if visible:
					# Start blinking animation
					_animate_glow(glow, true)
				else:
					# Hide glow
					glow.color = Color(1.0, 0.8, 0.2, 0.0)


func _animate_glow(glow: Polygon2D, enable: bool) -> void:
	if enable:
		var tween = create_tween().set_loops()
		tween.tween_property(glow, "color:a", 0.9, 0.6)
		tween.tween_property(glow, "color:a", 0.3, 0.6)
	else:
		# Stop any existing tween
		pass


func get_tile_for_position(world_pos: Vector2) -> Vector2i:
	"""Convert world position to grid position."""
	var local = world_pos - grid_offset
	var col = int(floor(local.x / tile_size))
	var row = int(floor(local.y / tile_size))
	return Vector2i(col, row)


func _create_puzzle_area() -> void:
	# Create an Area2D that covers the entire puzzle grid for detection
	var area = Area2D.new()
	area.name = "PuzzleArea"
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(grid_width * tile_size, grid_height * tile_size)
	collision.shape = shape
	collision.position = Vector2(grid_width * tile_size / 2, grid_height * tile_size / 2) - Vector2(tile_size/2, tile_size/2)
	area.add_child(collision)
	add_child(area)


func _process(_delta: float) -> void:
	# Track player position continuously during day phase
	if _player and DayNightSystem and not DayNightSystem.is_night and is_active and not puzzle_solved:
		var current_tile = get_tile_for_position(_player.global_position)
		if current_tile != _last_player_tile:
			_last_player_tile = current_tile
			_on_player_entered_tile(current_tile)


func _on_player_entered_tile(tile: Vector2i) -> void:
	"""Called when player enters a new tile during day phase."""
	if current_step < correct_path.size():
		var expected_tile = correct_path[current_step]

		if tile == expected_tile:
			# Correct tile!
			current_step += 1
			print("Passo correto: ", current_step, "/", correct_path.size())
			if current_step >= correct_path.size():
				_complete_puzzle()
		else:
			# Check if player stepped on ANY path tile out of order - that's wrong
			if tile in correct_path:
				_reset_player()


func register_player(player: Node2D) -> void:
	_player = player


func check_player_position() -> void:
	"""Check if player is on the correct path tile. Handled by _process."""
	pass


func _reset_player() -> void:
	"""Reset player to spawn position."""
	if not _player:
		return

	var spawn = get_parent().get_node_or_null("Spawn") as Marker2D
	if spawn:
		_player.global_position = spawn.global_position
		current_step = 0
		print("Caminho errado! Reset para o inicio.")


func _complete_puzzle() -> void:
	puzzle_solved = true
	is_active = false
	puzzle_completed.emit()
	print("Puzzle completido! Porta desbloqueada.")


func reset_puzzle() -> void:
	current_step = 0
	puzzle_solved = false
	is_active = true


func is_puzzle_complete() -> bool:
	return puzzle_solved
