extends Node2D

@onready var _vamp_zone_visual: Polygon2D = $ZonaVampiro/Visual
@onready var _puzzle: Node2D = $MemoryPathPuzzle
@onready var _player: Node2D = get_node_or_null("/root/Player")

## Cor HDR para Glow no `Polygon2D` da zona (valores > 1 quando o ambiente tem Glow).
const _VAMP_GLOW_BASE := Color(2.4, 0.45, 2.6)

const _INTERACTIVE_NODES: PackedStringArray = ["Quadro", "Cofre", "Porta", "ZonaVampiro"]

func _ready() -> void:
	_setup_light_occluders()
	_setup_vampire_hdr_glow()
	_connect_interactable_signals()
	_setup_puzzle()


func _setup_light_occluders() -> void:
	for node_name: String in ["Quadro", "Cofre"]:
		var obj := get_node_or_null(node_name) as Node2D
		if obj == null:
			continue
		var visual := obj.get_node_or_null("Visual") as Polygon2D
		if visual == null or visual.polygon.is_empty():
			continue
		var occluder_node := LightOccluder2D.new()
		var occluder_shape := OccluderPolygon2D.new()
		occluder_shape.polygon = visual.polygon
		occluder_node.occluder = occluder_shape
		obj.add_child(occluder_node)


func _setup_vampire_hdr_glow() -> void:
	if _vamp_zone_visual:
		_vamp_zone_visual.self_modulate = _VAMP_GLOW_BASE


func _connect_interactable_signals() -> void:
	var cb := Callable(self, "_on_object_interacted")
	for node_name: String in _INTERACTIVE_NODES:
		var n := get_node_or_null(node_name)
		if n == null:
			continue
		if n.has_signal("interacted") and not n.is_connected("interacted", cb):
			n.connect("interacted", cb)


func _on_object_interacted(object_name: String) -> void:
	# Liga aqui puzzles, flags em LoopSystem, mudança de cena, etc.
	print("[Room1] Interação: ", object_name)


func _setup_puzzle() -> void:
	# Register player with puzzle for position tracking
	if _puzzle and _player:
		_puzzle.register_player(_player)
		_puzzle.puzzle_completed.connect(_on_puzzle_completed)


func _on_puzzle_completed() -> void:
	print("[Room1] Puzzle do caminho completado!")
	# Optionally add checklist task or trigger other events


func _process(_delta: float) -> void:
	if _vamp_zone_visual:
		var t := Time.get_ticks_msec() / 1000.0
		var breathe := 0.85 + 0.15 * sin(t)
		_vamp_zone_visual.self_modulate = _VAMP_GLOW_BASE * breathe

	# Check player position on puzzle (only during day when path is hidden)
	if _puzzle and DayNightSystem and not DayNightSystem.is_night:
		_puzzle.check_player_position()

	# Debug: toggle day/night with F1 key
	if Input.is_action_just_pressed("ui_cancel"):
		DayNightSystem.is_night = not DayNightSystem.is_night
		DayNightSystem.phase_changed.emit(DayNightSystem.is_night)
		print("Debug: Phase changed to ", "Night" if DayNightSystem.is_night else "Day")
