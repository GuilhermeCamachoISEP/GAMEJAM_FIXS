extends Area2D
## Área de interação à volta do espelho; roda o pivô do espelho à noite.

@export var mirror_pivot: Node2D
@export var step_degrees: float = 45.0


func _ready() -> void:
	if mirror_pivot == null:
		mirror_pivot = get_parent() as Node2D


func interact(is_night: bool) -> void:
	if not is_night or mirror_pivot == null:
		return
	mirror_pivot.rotation_degrees = wrapf(mirror_pivot.rotation_degrees + step_degrees, 0.0, 360.0)
