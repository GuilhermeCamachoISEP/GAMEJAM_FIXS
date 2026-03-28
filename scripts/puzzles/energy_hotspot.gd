extends Area2D
## Área que encaminha interações para `energy_puzzle.gd` no ascendente.


enum Kind { GENERATOR, PANEL }

@export var kind: Kind = Kind.GENERATOR


func interact(is_night: bool) -> void:
	var p := _find_energy_parent()
	if p:
		match kind:
			Kind.GENERATOR:
				p.on_generator_interact(is_night)
			Kind.PANEL:
				p.on_panel_interact(is_night)


func _find_energy_parent() -> Node:
	var n: Node = get_parent()
	while n:
		if n.has_method("on_generator_interact"):
			return n
		n = n.get_parent()
	return null
