extends Node2D
## Room 2 — puzzle cooperativo de código. Checklist: `r2_code_entered`.


func _ready() -> void:
	var gm := get_node_or_null("GameManager") as Room2GameManager
	if gm:
		gm.puzzle_completed.connect(_on_room2_puzzle_completed)


func _on_room2_puzzle_completed() -> void:
	ChecklistSystem.complete_task("r2_code_entered")
	LoopSystem.complete_level()
