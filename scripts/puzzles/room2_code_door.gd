extends StaticBody2D
## Porta do puzzle de código: bloqueada até `open_door()`; desliga colisão para passar.


func _ready() -> void:
	_apply_locked_visual(true)


func open_door() -> void:
	collision_layer = 0
	collision_mask = 0
	_apply_locked_visual(false)


func set_door_locked(locked: bool) -> void:
	if locked:
		collision_layer = 1
		collision_mask = 1
	else:
		open_door()
	_apply_locked_visual(locked)


func _apply_locked_visual(locked: bool) -> void:
	var v := get_node_or_null("Visual") as CanvasItem
	if v:
		v.modulate = Color(0.55, 0.35, 0.28, 1) if locked else Color(0.42, 0.62, 0.38, 1)
