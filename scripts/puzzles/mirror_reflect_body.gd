extends StaticBody2D
## Corpo usado só pelo traçado da luz; pertence ao grupo `light_mirrors`.


func _ready() -> void:
	add_to_group("light_mirrors")
