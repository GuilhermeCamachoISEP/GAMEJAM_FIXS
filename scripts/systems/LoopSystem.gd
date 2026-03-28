extends Node

signal loop_started(loop_index: int)

var current_loop: int = 1

# Dicionário para guardar o que foi alterado permanentemente no loop atual
var state_flags: Dictionary = {
	"room1_bookshelf_moved": false,
	"room1_safe_opened": false
}

func reset_loop() -> void:
	current_loop += 1
	# Aqui decides o que faz reset e o que se mantém entre loops
	state_flags["room1_bookshelf_moved"] = false
	state_flags["room1_safe_opened"] = false
	loop_started.emit(current_loop)
	print("Loop ", current_loop, " iniciado!")
