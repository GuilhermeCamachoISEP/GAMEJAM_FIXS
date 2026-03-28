extends Node
class_name ChecklistData

## Presets só para referência no editor; em jogo usa-se `begin_room_requirements` (chamado em `main.gd`).
@export var level_1_tasks: PackedStringArray = PackedStringArray(["view_symbols", "open_safe"])

## Tarefas Room4 — usadas por `room4_test.gd` com `begin_room_requirements(room4_tasks)`.
@export var room4_tasks: PackedStringArray = PackedStringArray(["r4_recorded_sequence", "r4_solved_bells"])

## O singleton em Autoload chama-se `ChecklistSystem`.

signal checklist_changed

var _completed: Dictionary = {}
var _active_tasks: PackedStringArray = []


func get_active_tasks() -> PackedStringArray:
	return _active_tasks.duplicate()


## Define as tarefas da sala actual e repõe o progresso.
func begin_room_requirements(task_ids: PackedStringArray) -> void:
	_active_tasks = task_ids.duplicate()
	_completed.clear()
	for t: String in _active_tasks:
		_completed[t] = false
	checklist_changed.emit()


func reset_for_level() -> void:
	for t: String in _active_tasks:
		_completed[t] = false
	checklist_changed.emit()


func complete_task(task_id: String) -> void:
	if task_id not in _completed:
		return
	if _completed.get(task_id, false):
		return
	_completed[task_id] = true
	checklist_changed.emit()


func is_task_done(task_id: String) -> bool:
	return _completed.get(task_id, false)


func is_level_complete() -> bool:
	if _active_tasks.is_empty():
		return false
	for t: String in _active_tasks:
		if not _completed.get(t, false):
			return false
	return true


static func task_label(task_id: String) -> String:
	match task_id:
		"view_symbols":
			return "Ver os símbolos no quadro"
		"open_safe":
			return "Abrir o cofre"
		"r2_code_entered":
			return "Introduzir o código de 3 dígitos (sala 2)"
		"r4_recorded_sequence":
			return "Gravar sequência na máquina (Room4)"
		"r4_solved_bells":
			return "Resolver puzzle dos sinos (Room4)"
		_:
			return task_id
