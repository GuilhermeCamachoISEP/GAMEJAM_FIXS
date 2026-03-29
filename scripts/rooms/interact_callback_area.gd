extends Area2D
class_name InteractCallbackArea

## Usado em salas procedurais: o `Player` chama `interact()` no `Area2D` do raycast.
var callback: Callable = Callable()


func interact(_is_night: bool) -> void:
	if callback.is_valid():
		callback.call()
