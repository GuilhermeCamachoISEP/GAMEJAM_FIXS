extends CanvasLayer

@onready var _level_time: Label = %LevelTime
@onready var _phase_label: Label = %PhaseLabel
@onready var _phase_time: Label = %PhaseTime
@onready var _loop_label: Label = %LoopLabel
@onready var _checklist: ItemList = %Checklist

@onready var _checklist_data: ChecklistData = get_node("/root/ChecklistSystem") as ChecklistData

var _ended: bool = false


func _ready() -> void:
	LoopSystem.level_failed.connect(_on_level_ended)
	LoopSystem.level_completed.connect(_on_level_ended)
	DayNightSystem.phase_changed.connect(_on_phase_changed)
	_checklist_data.checklist_changed.connect(_refresh_checklist)
	_on_loop_shown()
	_on_phase_changed(DayNightSystem.is_night)
	_refresh_checklist()


func _process(_delta: float) -> void:
	if _ended:
		return
	_level_time.text = "Nível: %ds" % int(ceil(LoopSystem.get_level_time_left()))
	_phase_time.text = "Fase: %ds" % int(ceil(DayNightSystem.get_phase_time_left()))


func _on_loop_shown() -> void:
	_loop_label.text = "Tentativa: %d" % LoopSystem.current_loop


func _on_phase_changed(is_night: bool) -> void:
	if is_night:
		_phase_label.text = "Noite — Vampiro"
	else:
		_phase_label.text = "Dia — Humano"


func _on_level_ended() -> void:
	_ended = true


func _refresh_checklist() -> void:
	_checklist.clear()
	for task_id: String in _checklist_data.level_1_tasks:
		var done: bool = _checklist_data.is_task_done(task_id)
		var text: String = ("[x] " if done else "[ ] ") + ChecklistData.task_label(task_id)
		_checklist.add_item(text)
