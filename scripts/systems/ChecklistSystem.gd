extends Node
class_name ChecklistData

@export var level_1_tasks: PackedStringArray = PackedStringArray(["view_symbols", "open_safe"])

## Tarefas do nível atual. Completar todas desbloqueia a saída (consultar LoopSystem).
## O singleton em Autoload chama-se `ChecklistSystem` (instância desta classe).

signal checklist_changed

## IDs das tarefas do nível 1 (MVP). Expandir por nível depois.

var _completed: Dictionary = {} # task_id -> true


func _ready() -> void:
	reset_for_level()


func reset_for_level() -> void:
	_completed.clear()
	for t: String in level_1_tasks:
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
	for t: String in level_1_tasks:
		if not _completed.get(t, false):
			return false
	return not level_1_tasks.is_empty()


static func task_label(task_id: String) -> String:
	match task_id:
		"view_symbols":
			return "Ver os símbolos no quadro"
		"open_safe":
			return "Abrir o cofre"
		_:
			return task_id
