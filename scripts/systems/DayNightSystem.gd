extends Node
## Tracks day vs night (human vs vampire) and notifies the game when the phase changes.
## Later: hook up to lights, NPC schedules, and which puzzles are available.

signal phase_changed(is_night: bool)

func _ready() -> void:
	pass
