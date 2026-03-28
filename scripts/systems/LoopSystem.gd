extends Node
## Handles time loops: what resets each cycle vs what persists (memory, codes, flags).
## Later: save/load persistent state and reload the level scene on loop.

signal loop_started(loop_index: int)

func _ready() -> void:
	pass
