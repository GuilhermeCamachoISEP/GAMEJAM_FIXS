extends Node

signal phase_changed(is_night: bool)
signal phase_time_updated(remaining_sec: float)

const DEFAULT_NIGHT_DURATION_SEC: float = 45.0
const DEFAULT_DAY_DURATION_SEC: float = 45.0

## Turnos fixos (segundos por fase). Iguais no MVP.
@export var night_duration_sec: float = DEFAULT_NIGHT_DURATION_SEC
@export var day_duration_sec: float = DEFAULT_DAY_DURATION_SEC

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
	_phase_timer.wait_time = night_duration_sec if is_night else day_duration_sec
	_phase_timer.start()


func set_phase_durations(night_sec: float, day_sec: float, restart_phase: bool = false) -> void:
	night_duration_sec = night_sec
	day_duration_sec = day_sec
	if restart_phase:
		_start_phase_timer()


func reset_phase_durations() -> void:
	night_duration_sec = DEFAULT_NIGHT_DURATION_SEC
	day_duration_sec = DEFAULT_DAY_DURATION_SEC


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


## Salas com ciclo próprio (ex.: Room2): atualiza fase sem depender do timer global.
func apply_external_phase(night: bool) -> void:
	var was_night: bool = is_night
	is_night = night
	if was_night and not night:
		(get_node("/root/InventorySystem") as InventoryData).clear()
	phase_changed.emit(is_night)
