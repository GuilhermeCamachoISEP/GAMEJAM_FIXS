extends Node2D
## Puzzle sala 2: dígitos escondidos no mundo; código inserido no menu da porta (H).


@export var scatter_extent: float = 620.0
@export var min_distance_from_door: float = 240.0

@onready var _door: StaticBody2D = $Door
@onready var _digit_root: Node2D = $DigitClues

var _gm: Room2GameManager
var _digits: Array[int] = []
var _done: bool = false


func _ready() -> void:
	_scatter_digit_positions()


func bind_manager(gm: Room2GameManager) -> void:
	_gm = gm
	if not gm.phase_changed.is_connected(_on_phase_changed):
		gm.phase_changed.connect(_on_phase_changed)
	_digits = Room2GameManager.get_session_digits().duplicate()
	_sync_clues()
	_scatter_digit_positions()
	_on_phase_changed(gm.get_current_phase())


func prepare_for_soft_reset() -> void:
	_done = false
	_digits = Room2GameManager.get_session_digits().duplicate()
	_sync_clues()
	_scatter_digit_positions()
	if _door and _door.has_method("set_door_locked"):
		_door.set_door_locked(true)


func _on_phase_changed(_p: Room2GameManager.Phase) -> void:
	pass


func is_door_unlocked() -> bool:
	return _done


func try_unlock_with_code(text: String) -> String:
	if _done:
		return "done"
	var t := text.strip_edges()
	if t.length() != 3 or not t.is_valid_int():
		return "format"
	if int(t) != _code_value():
		return "wrong"
	_done = true
	if _door and _door.has_method("open_door"):
		_door.open_door()
	if _gm:
		_gm.notify_code_solved()
	return "ok"


func _code_value() -> int:
	if _digits.size() < 3:
		_digits = Room2GameManager.get_session_digits().duplicate()
	return _digits[0] * 100 + _digits[1] * 10 + _digits[2]


func _sync_clues() -> void:
	if _digits.size() < 3:
		_digits = Room2GameManager.get_session_digits().duplicate()
	for i: int in 3:
		var n: Node = _digit_root.get_node_or_null("Digit%d" % i)
		if n and n.has_method("setup_digit"):
			n.call("setup_digit", _digits[i], i)


func _scatter_digit_positions() -> void:
	if _digit_root == null or _door == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var door_local: Vector2 = _door.position
	for i: int in 3:
		var node: Node2D = _digit_root.get_node_or_null("Digit%d" % i) as Node2D
		if node == null:
			continue
		var placed := false
		for _attempt in 28:
			var p := Vector2(
				rng.randf_range(-scatter_extent, scatter_extent),
				rng.randf_range(-scatter_extent, scatter_extent)
			)
			if p.distance_to(door_local) >= min_distance_from_door:
				node.position = p
				placed = true
				break
		if not placed:
			node.position = Vector2(-scatter_extent * 0.6 + float(i) * 180.0, scatter_extent * 0.35)
