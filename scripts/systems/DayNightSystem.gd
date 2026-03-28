extends Node

signal phase_changed(is_night: bool)
signal phase_time_updated(remaining_sec: float)

## Turnos fixos (segundos por fase). Iguais no MVP.
@export var phase_duration_sec: float = 45.0

## O GDD: o loop começa de noite (vampiro).
var is_night: bool = true

var _phase_timer: Timer


func _ready() -> void:
	_phase_timer = Timer.new()
	_phase_timer.one_shot = true
	_phase_timer.timeout.connect(_on_phase_timeout)
	add_child(_phase_timer)


func _process(_delta: float) -> void:
	if _phase_timer.is_stopped():
		return
	phase_time_updated.emit(_phase_timer.time_left)


func get_phase_time_left() -> float:
	if _phase_timer.is_stopped():
		return 0.0
	return _phase_timer.time_left


func _start_phase_timer() -> void:
	_phase_timer.wait_time = phase_duration_sec
	_phase_timer.start()


func _on_phase_timeout() -> void:
	is_night = !is_night
	if not is_night:
		(get_node("/root/InventorySystem") as InventoryData).clear()
	phase_changed.emit(is_night)
	_start_phase_timer()


## Volta à noite e reinicia o turno (entrada no nível ou após reset).
func reset_run() -> void:
	is_night = true
	_phase_timer.stop()
	_start_phase_timer()
	phase_changed.emit(is_night)


func stop_phase_timer() -> void:
	_phase_timer.stop()
