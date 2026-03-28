extends Area2D
## Receptor da luz; deve estar na máscara de áreas do `mirror_puzzle.gd`.


func _ready() -> void:
	add_to_group("light_receiver")
