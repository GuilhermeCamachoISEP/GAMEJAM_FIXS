extends Node2D

@onready var _puzzle: Node = $MemoryPathPuzzle
@onready var _player: Node2D = get_tree().get_first_node_in_group("player") as Node2D

const _ROOM1_NIGHT_DURATION_SEC: float = 15.0
const _ROOM1_DAY_DURATION_SEC: float = 20.0


func _ready() -> void:
	if DayNightSystem:
		DayNightSystem.set_phase_durations(_ROOM1_NIGHT_DURATION_SEC, _ROOM1_DAY_DURATION_SEC, true)
	_setup_puzzle()


func _setup_puzzle() -> void:
	if not _puzzle:
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node2D
	if _player and _puzzle.has_method("register_player"):
		_puzzle.call("register_player", _player)
	var cb := Callable(self, "_on_puzzle_completed")
	if _puzzle.has_signal("puzzle_completed") and not _puzzle.is_connected("puzzle_completed", cb):
		_puzzle.connect("puzzle_completed", cb)


func _on_puzzle_completed() -> void:
	print("[Room1] Puzzle do caminho completado!")


func _process(_delta: float) -> void:
	if _puzzle and DayNightSystem and not DayNightSystem.is_night:
		if _puzzle.has_method("check_player_position"):
			_puzzle.call("check_player_position")
