extends Node2D
## Alterna visibilidade e `collision_layer` de nós nos grupos indicados.


@export var shadow_only_group: StringName = &"room2_shadow_only"
@export var light_only_group: StringName = &"room2_light_only"
@export var shadow_collision_layer_bit: int = 1


func _ready() -> void:
	DayNightSystem.phase_changed.connect(_apply)
	_apply(DayNightSystem.is_night)


func _apply(is_night: bool) -> void:
	_set_group_collision_and_visibility(shadow_only_group, is_night)
	_set_group_collision_and_visibility(light_only_group, not is_night)


func _set_group_collision_and_visibility(group_name: StringName, active: bool) -> void:
	for n: Node in get_tree().get_nodes_in_group(group_name):
		if n is CanvasItem:
			(n as CanvasItem).visible = active
		if n is CollisionObject2D:
			var c := n as CollisionObject2D
			if active:
				c.collision_layer = shadow_collision_layer_bit
			else:
				c.collision_layer = 0
