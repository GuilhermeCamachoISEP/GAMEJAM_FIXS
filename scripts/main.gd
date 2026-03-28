extends Node2D

## Cena após completar a última sala da sequência (vazio = ficar na cena com run ganho).
@export var post_victory_scene: String = ""

## Ordem do run: Room1, Room2, … — adiciona mais paths no inspector se criares Room3+.
@export var room_scene_paths: PackedStringArray = PackedStringArray(
	["res://scenes/rooms/Room1.tscn", "res://scenes/rooms/Room2.tscn"]
)

var _room_index: int = 0
var _room_instance: Node2D
var _room_paths: Array[String] = []

@onready var _room_parent: Node2D = $RoomContainer as Node2D
@onready var _player: Node2D = $Player as Node2D


func _ready() -> void:
	add_to_group("gameplay")
	_build_valid_room_list()
	if _room_paths.is_empty():
		push_error("Main: `room_scene_paths` está vazio — define salas no inspector.")
		return

	LoopSystem.level_completed.connect(_on_level_completed)
	LoopSystem.level_failed.connect(_on_level_failed)
	LoopSystem.start_level_session()

	await _load_room_at_index(_room_index)

	var game_node: Node = get_tree().root.get_node_or_null("Game")
	if game_node != null and game_node.has_method("notify_level_loaded"):
		game_node.call("notify_level_loaded")


func _build_valid_room_list() -> void:
	_room_paths.clear()
	for p: String in room_scene_paths:
		var t: String = p.strip_edges()
		if t.is_empty():
			continue
		if not ResourceLoader.exists(t):
			push_warning("Main: cena inexistente (ignorada): %s" % t)
			continue
		_room_paths.append(t)


func _checklist_tasks_for_room(room_i: int) -> PackedStringArray:
	match room_i:
		0:
			return PackedStringArray(["view_symbols", "open_safe"])
		1:
			return PackedStringArray(["r2_code_entered"])
		_:
			push_warning("Main: sem checklist definida para sala índice %d — usa lista vazia." % room_i)
			return PackedStringArray()


func _load_room_at_index(i: int) -> void:
	if i < 0 or i >= _room_paths.size():
		return
	Room2GameManager.forget_session_code_for_new_run()
	if is_instance_valid(_room_instance):
		_room_instance.queue_free()
		_room_instance = null
		await get_tree().process_frame

	var ps: PackedScene = load(_room_paths[i]) as PackedScene
	if ps == null:
		push_error("Main: falha a carregar %s" % _room_paths[i])
		return
	_room_instance = ps.instantiate() as Node2D
	if _room_instance == null:
		push_error("Main: raiz da sala não é Node2D: %s" % _room_paths[i])
		return
	_room_parent.add_child(_room_instance)

	var cl := get_node_or_null("/root/ChecklistSystem") as ChecklistData
	if cl != null:
		cl.begin_room_requirements(_checklist_tasks_for_room(i))

	_place_player_at_room_spawn(_room_instance)


func _place_player_at_room_spawn(room: Node2D) -> void:
	if not is_instance_valid(_player):
		return
	var spawn: Node2D = room.get_node_or_null("PlayerSpawn") as Node2D
	if spawn == null:
		spawn = room.get_node_or_null("Spawn") as Node2D
	if spawn:
		_player.global_position = spawn.global_position


func _on_level_failed() -> void:
	# `LoopSystem` agenda `reload_current_scene`; `Main` volta a `_ready` com `_room_index` = 0.
	pass


func _on_level_completed() -> void:
	_room_index += 1
	if _room_index >= _room_paths.size():
		var game_node: Node = get_tree().root.get_node_or_null("Game")
		if game_node != null and game_node.has_method("go_to_post_victory"):
			game_node.call("go_to_post_victory", post_victory_scene)
		return

	LoopSystem.prepare_next_room_segment()
	await _load_room_at_index(_room_index)

	var hud: Node = get_node_or_null("GameHUD")
	if hud != null and hud.has_method("reset_after_room_advance"):
		hud.call("reset_after_room_advance")
