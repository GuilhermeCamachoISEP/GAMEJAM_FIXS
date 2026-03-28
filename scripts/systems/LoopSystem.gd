extends Node

signal loop_started(loop_index: int)
signal level_failed
signal level_completed
signal level_time_updated(remaining_sec: float)

## Tempo total do nível (segundos). Esgotou → reset total.
@export var level_duration_sec: float = 180.0

var current_loop: int = 1

var state_flags: Dictionary = {
	"room1_bookshelf_moved": false,
	"room1_safe_opened": false
}

var _level_timer: Timer
var _level_done: bool = false


func _ready() -> void:
	_level_timer = Timer.new()
	_level_timer.one_shot = true
	_level_timer.timeout.connect(_on_level_timeout)
	add_child(_level_timer)


func _process(_delta: float) -> void:
	if _level_done or _level_timer.is_stopped():
		return
	level_time_updated.emit(_level_timer.time_left)


func get_level_time_left() -> float:
	if _level_timer.is_stopped():
		return 0.0
	return _level_timer.time_left


func is_exit_unlocked() -> bool:
	return (get_node("/root/ChecklistSystem") as ChecklistData).is_level_complete()


## Chamado por `main` em cada carga da cena do nível (incluindo após reload por falha).
func start_level_session() -> void:
	_level_done = false
	_start_level_timer()
	DayNightSystem.reset_run()


func _start_level_timer() -> void:
	_level_timer.wait_time = level_duration_sec
	_level_timer.start()


func _on_level_timeout() -> void:
	if _level_done:
		return
	fail_level()


func fail_level() -> void:
	if _level_done:
		return
	_level_done = true
	_level_timer.stop()
	DayNightSystem.stop_phase_timer()
	current_loop += 1
	_reset_state_flags()
	(get_node("/root/InventorySystem") as InventoryData).clear()
	(get_node("/root/ChecklistSystem") as ChecklistData).reset_for_level()
	level_failed.emit()
	loop_started.emit(current_loop)
	get_tree().call_deferred("reload_current_scene")


func complete_level() -> void:
	if _level_done:
		return
	_level_done = true
	_level_timer.stop()
	DayNightSystem.stop_phase_timer()
	level_completed.emit()
	print("Nível completo!")


func _reset_state_flags() -> void:
	state_flags["room1_bookshelf_moved"] = false
	state_flags["room1_safe_opened"] = false
