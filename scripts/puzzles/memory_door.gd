extends Area2D
## Door that unlocks after memory path puzzle completion.

@export var message_day: String = "A porta está trancada."
@export var message_night: String = "A porta está trancada."
@export var vampire_only: bool = false
@export var human_only: bool = false
@export var completes_checklist_task: String = ""
@export var is_level_exit: bool = true

## Reference to the memory path puzzle
@export var puzzle_node_path: NodePath = "../MemoryPathPuzzle"

signal interacted(object_name: String)

var _is_unlocked: bool = false
var _locked_indicator: Polygon2D


func _ready() -> void:
	# Find the puzzle node
	var puzzle = get_node_or_null(puzzle_node_path) as Node
	if puzzle and puzzle.has_signal("puzzle_completed"):
		puzzle.puzzle_completed.connect(_on_puzzle_completed)

	# Find locked indicator
	_locked_indicator = get_node_or_null("LockedIndicator") as Polygon2D
	_update_visual_state()


func _on_puzzle_completed() -> void:
	_is_unlocked = true
	_update_visual_state()
	print("Porta desbloqueada!")


func _update_visual_state() -> void:
	if _locked_indicator:
		_locked_indicator.visible = not _is_unlocked


func interact(is_night: bool) -> void:
	if is_level_exit:
		if _is_unlocked:
			print("A sair para Room2...")
			_load_room2()
		else:
			print("A porta está trancada. Precisas de completar o puzzle do caminho.")
		interacted.emit(name)
		return

	if vampire_only and not is_night:
		print("És demasiado fraco para mover isto de dia.")
		return

	if human_only and is_night:
		print("As tuas garras não te permitem mexer nisto com precisão.")
		return

	if is_night:
		print("[Noite] ", message_night)
	else:
		print("[Dia] ", message_day)

	if not completes_checklist_task.is_empty():
		(get_node("/root/ChecklistSystem") as ChecklistData).complete_task(completes_checklist_task)

	interacted.emit(name)


func _load_room2() -> void:
	var next_scene = load("res://scenes/rooms/Room2.tscn")
	if next_scene:
		get_tree().change_scene_to_packed(next_scene)
