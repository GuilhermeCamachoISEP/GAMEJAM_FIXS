extends CanvasLayer

@onready var _panel: PanelContainer = $Panel
@onready var _menu_hint: Label = $MenuHint
@onready var _level_time: Label = %LevelTime
@onready var _phase_label: Label = %PhaseLabel
@onready var _phase_time: Label = %PhaseTime
@onready var _loop_label: Label = %LoopLabel
@onready var _checklist: ItemList = %Checklist

var _checklist_data: ChecklistData
var _ended: bool = false
var _menu_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_menu_open = false
	_apply_menu_visibility()

	_checklist_data = get_node_or_null("/root/ChecklistSystem") as ChecklistData
	if _checklist_data == null:
		push_error("GameHUD: ChecklistSystem autoload em falta. Verifica Project Settings → Autoload (caminhos res://).")
		if _level_time:
			_level_time.text = "Erro: autoloads"
		return

	if is_instance_valid(LoopSystem):
		LoopSystem.level_failed.connect(_on_level_ended)
		LoopSystem.level_completed.connect(_on_level_ended)
	if is_instance_valid(DayNightSystem):
		DayNightSystem.phase_changed.connect(_on_phase_changed)
	_checklist_data.checklist_changed.connect(_refresh_checklist)
	_on_loop_shown()
	if is_instance_valid(DayNightSystem):
		_on_phase_changed(DayNightSystem.is_night)
	_refresh_checklist()


func _unhandled_input(event: InputEvent) -> void:
	if _ended:
		return
	if event.is_action_pressed("hud_menu"):
		_toggle_menu()
		get_viewport().set_input_as_handled()


func _apply_menu_visibility() -> void:
	_panel.visible = _menu_open
	_menu_hint.visible = not _menu_open


func _toggle_menu() -> void:
	_menu_open = not _menu_open
	_apply_menu_visibility()
	if is_instance_valid(Game):
		Game.set_game_paused(_menu_open)


func _process(_delta: float) -> void:
	if _ended or _checklist_data == null:
		return
	var room_gm: Node = get_tree().get_first_node_in_group("room2_game_manager")
	if room_gm and room_gm.has_method("get_room_phase_seconds_left"):
		var phase_left: float = room_gm.call("get_room_phase_seconds_left") as float
		var cycle_left: float = room_gm.call("get_room_cycle_seconds_left") as float
		_phase_time.text = "Fase: %ds" % int(ceil(maxf(phase_left, 0.0)))
		if bool(room_gm.get("pause_global_level_timer")):
			_level_time.text = "Ciclo sala: %ds" % int(ceil(maxf(cycle_left, 0.0)))
		else:
			_level_time.text = "Nível: %ds" % int(ceil(LoopSystem.get_level_time_left()))
	else:
		_level_time.text = "Nível: %ds" % int(ceil(LoopSystem.get_level_time_left()))
		_phase_time.text = "Fase: %ds" % int(ceil(DayNightSystem.get_phase_time_left()))


func _on_loop_shown() -> void:
	if is_instance_valid(LoopSystem):
		_loop_label.text = "Tentativa: %d" % LoopSystem.current_loop


func _on_phase_changed(is_night: bool) -> void:
	if is_night:
		_phase_label.text = "Noite — Vampiro"
	else:
		_phase_label.text = "Dia — Humano"


func _on_level_ended() -> void:
	_ended = true
	if _menu_open:
		_menu_open = false
		_apply_menu_visibility()
		if is_instance_valid(Game):
			Game.set_game_paused(false)


## Nova sala no mesmo run — o timer global continua mas o painel de check volta a atualizar.
func reset_after_room_advance() -> void:
	_ended = false
	_on_loop_shown()
	_refresh_checklist()


func _refresh_checklist() -> void:
	if _checklist_data == null:
		return
	_checklist.clear()
	for task_id: String in _checklist_data.get_active_tasks():
		var done: bool = _checklist_data.is_task_done(task_id)
		var text: String = ("[x] " if done else "[ ] ") + ChecklistData.task_label(task_id)
		_checklist.add_item(text)
