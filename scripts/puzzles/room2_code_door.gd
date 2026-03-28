extends StaticBody2D
## Porta: humano de dia perto da zona; H abre/fecha menu de código; após destrancar, colisão desliga.

const MENU_SCENE := preload("res://scenes/puzzles/room2_door_code_menu.tscn")

var _puzzle: Node2D
var _menu: CanvasLayer
var _player_near: bool = false
var _is_unlocked: bool = false

# Cores para diferentes estados
const COLOR_LOCKED: Color = Color(0.55, 0.35, 0.28, 1)
const COLOR_NEAR_DAY: Color = Color(0.75, 0.55, 0.45, 1)
const COLOR_OPEN: Color = Color(0.42, 0.62, 0.38, 1)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_puzzle = get_parent() as Node2D
	_apply_locked_visual(true)
	var prox: Area2D = $ProximityArea as Area2D
	if prox:
		prox.body_entered.connect(_on_body_entered)
		prox.body_exited.connect(_on_body_exited)
	var hint: Label = $HintLabel as Label
	if hint:
		hint.visible = false


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_near = true
		_update_visual_based_on_state()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_near = false
		var hint: Label = $HintLabel as Label
		if hint:
			hint.visible = false
		_update_visual_based_on_state()


func _unhandled_input(event: InputEvent) -> void:
	if _menu != null and is_instance_valid(_menu):
		return
	if not event.is_action_pressed("door_h"):
		return
	if not _player_near:
		return
	if not _is_human_day_phase():
		return
	if _puzzle != null and _puzzle.has_method("is_door_unlocked") and bool(_puzzle.call("is_door_unlocked")):
		return
	_open_code_menu()


func _process(_delta: float) -> void:
	var hint: Label = $HintLabel as Label
	if hint == null or _puzzle == null:
		return
	if _menu != null and is_instance_valid(_menu):
		hint.visible = false
		return
	var unlocked: bool = _puzzle.has_method("is_door_unlocked") and bool(_puzzle.call("is_door_unlocked"))
	hint.visible = _player_near and _is_human_day_phase() and not unlocked


func _is_human_day_phase() -> bool:
	var gm: Room2GameManager = get_node_or_null("../../GameManager") as Room2GameManager
	if gm == null:
		return false
	return gm.get_current_phase() == Room2GameManager.Phase.DAY


func _open_code_menu() -> void:
	if _menu != null and is_instance_valid(_menu):
		return
	_menu = MENU_SCENE.instantiate() as CanvasLayer
	_menu.submitted.connect(_on_menu_submitted)
	_menu.menu_closed.connect(_on_menu_closed)
	var scene_root: Node = get_tree().current_scene
	if scene_root:
		scene_root.add_child(_menu)
	else:
		get_tree().root.add_child(_menu)


func _on_menu_submitted(code: String) -> void:
	if _puzzle == null or not _puzzle.has_method("try_unlock_with_code"):
		return
	var r: String = String(_puzzle.call("try_unlock_with_code", code))
	match r:
		"ok":
			if _menu != null and is_instance_valid(_menu):
				_menu.close_success()
			_menu = null
		"format":
			if _menu != null and is_instance_valid(_menu):
				_menu.show_feedback("Usa exatamente 3 dígitos.")
		"wrong":
			if _menu != null and is_instance_valid(_menu):
				_menu.show_feedback("Código errado.")
		"done":
			if _menu != null and is_instance_valid(_menu):
				_menu.show_feedback("Porta já está destrancada.")


func _on_menu_closed() -> void:
	_menu = null


func open_door() -> void:
	collision_layer = 0
	collision_mask = 0
	_is_unlocked = true
	_apply_locked_visual(false)
	# Animar abertura após breve delay
	var timer := get_tree().create_timer(0.2)
	timer.timeout.connect(_animate_door_open)


func set_door_locked(locked: bool) -> void:
	if locked:
		collision_layer = 1
		collision_mask = 1
	else:
		open_door()
	_apply_locked_visual(locked)


func _apply_locked_visual(locked: bool) -> void:
	_is_unlocked = not locked
	_update_visual_based_on_state()


func _update_visual_based_on_state() -> void:
	var door_visual := get_node_or_null("DoorVisual") as Node2D
	if door_visual == null:
		return

	var frame := door_visual.get_node_or_null("Frame") as CanvasItem
	var door := door_visual.get_node_or_null("Door") as CanvasItem

	if _is_unlocked:
		# Porta aberta - cor verde
		if frame:
			frame.modulate = COLOR_OPEN
		if door:
			door.modulate = COLOR_OPEN
		# Animar abertura
		_animate_door_open()
	elif _player_near and _is_human_day_phase():
		# Jogador perto durante o dia - cor mais clara
		if frame:
			frame.modulate = COLOR_NEAR_DAY
		if door:
			door.modulate = COLOR_NEAR_DAY
	else:
		# Estado normal - porta trancada
		if frame:
			frame.modulate = COLOR_LOCKED
		if door:
			door.modulate = COLOR_LOCKED


func _animate_door_open() -> void:
	var door_visual := get_node_or_null("DoorVisual") as Node2D
	if door_visual == null:
		return

	var door := door_visual.get_node_or_null("Door") as Node2D
	if door == null:
		return

	# Animação de abrir a porta (escala X diminui e roda ligeiramente)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(door, "scale:x", 0.15, 0.4)
	tw.parallel().tween_property(door, "rotation", -0.25, 0.4)
