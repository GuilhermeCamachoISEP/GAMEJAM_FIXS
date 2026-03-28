extends Node2D
class_name Room2GameManager

enum Phase { NIGHT, DAY }

signal phase_changed(new_phase: Phase)
signal time_up
signal puzzle_completed

@export var night_duration_sec: float = 30.0
@export var day_duration_sec: float = 30.0
@export var pause_global_level_timer: bool = true

## Relativo ao nó GameManager. Com `Main` → `RoomContainer` → `Room2`, o `Player` está em `../../../Player`.
@export var spawn_marker_path: NodePath = ^"../Spawn"
@export var player_path: NodePath = ^"../../../Player"
@export var code_puzzle_path: NodePath = ^"../CodePuzzleRoom2"

static var _session_digits: Array[int] = []

var _phase: Phase = Phase.NIGHT
var _puzzle_done: bool = false
var _night_timer: Timer
var _day_timer: Timer
var _code_puzzle: Node


static func get_session_digits() -> Array[int]:
	if _session_digits.is_empty():
		_session_digits = [randi_range(0, 9), randi_range(0, 9), randi_range(0, 9)]
	return _session_digits


static func forget_session_code_for_new_run() -> void:
	_session_digits.clear()


func _ready() -> void:
	if pause_global_level_timer:
		LoopSystem.set_level_timer_paused(true)

	if OS.is_debug_build():
		var d := get_session_digits()
		print("[Room2][debug] Session code: %d%d%d" % [d[0], d[1], d[2]])

	# `Main._ready()` chama `LoopSystem.start_level_session()` → `DayNightSystem.reset_run()`, que
	# volta a ligar o timer global. Isto corre depois deste _ready, por isso paramos o DayNightSystem
	# no frame seguinte para a sala não dessincronizar com o puzzle.
	await get_tree().process_frame
	DayNightSystem.stop_phase_timer()

	_code_puzzle = get_node_or_null(code_puzzle_path)

	_night_timer = Timer.new()
	_night_timer.one_shot = true
	_night_timer.timeout.connect(_on_night_ended)
	add_child(_night_timer)
	_day_timer = Timer.new()
	_day_timer.one_shot = true
	_day_timer.timeout.connect(_on_day_ended)
	add_child(_day_timer)

	_begin_night_phase()
	add_to_group("room2_game_manager")
	call_deferred("_deferred_bind_code_puzzle")


func _deferred_bind_code_puzzle() -> void:
	if _code_puzzle and _code_puzzle.has_method("bind_manager"):
		_code_puzzle.bind_manager(self)


func _exit_tree() -> void:
	if pause_global_level_timer:
		LoopSystem.set_level_timer_paused(false)
	DayNightSystem.reset_run()


func is_puzzle_completed() -> bool:
	return _puzzle_done


func is_night_phase() -> bool:
	return _phase == Phase.NIGHT


func get_current_phase() -> Phase:
	return _phase


## Tempo restante da fase atual (noite ou dia), para o HUD.
func get_room_phase_seconds_left() -> float:
	if _puzzle_done:
		return 0.0
	if _phase == Phase.NIGHT:
		if _night_timer == null or _night_timer.is_stopped():
			return 0.0
		return _night_timer.time_left
	if _day_timer == null or _day_timer.is_stopped():
		return 0.0
	return _day_timer.time_left


## Estimativa até ao fim do ciclo atual se o puzzle não for resolvido.
func get_room_cycle_seconds_left() -> float:
	if _puzzle_done:
		return 0.0
	if _phase == Phase.NIGHT:
		var n_left: float = 0.0
		if _night_timer and not _night_timer.is_stopped():
			n_left = _night_timer.time_left
		return n_left + day_duration_sec
	if _day_timer and not _day_timer.is_stopped():
		return _day_timer.time_left
	return 0.0


func notify_code_solved() -> void:
	if _puzzle_done:
		return
	_puzzle_done = true
	if _day_timer:
		_day_timer.stop()
	puzzle_completed.emit()


func request_room_cycle_reset() -> void:
	if _puzzle_done:
		return
	_perform_soft_reset()


func _begin_night_phase() -> void:
	_phase = Phase.NIGHT
	DayNightSystem.apply_external_phase(true)
	phase_changed.emit(Phase.NIGHT)
	_night_timer.wait_time = night_duration_sec
	_night_timer.start()


func _on_night_ended() -> void:
	if _puzzle_done:
		return
	time_up.emit()
	_phase = Phase.DAY
	DayNightSystem.apply_external_phase(false)
	phase_changed.emit(Phase.DAY)
	_day_timer.wait_time = day_duration_sec
	_day_timer.start()


func _on_day_ended() -> void:
	if _puzzle_done:
		return
	time_up.emit()
	_perform_soft_reset()


func _perform_soft_reset() -> void:
	_day_timer.stop()
	_night_timer.stop()
	_move_player_to_spawn()
	if _code_puzzle and _code_puzzle.has_method("prepare_for_soft_reset"):
		_code_puzzle.prepare_for_soft_reset()
	_begin_night_phase()


func _move_player_to_spawn() -> void:
	var p: Node2D = get_node_or_null(player_path) as Node2D
	var m: Node2D = get_node_or_null(spawn_marker_path) as Node2D
	if p and m:
		p.global_position = m.global_position
