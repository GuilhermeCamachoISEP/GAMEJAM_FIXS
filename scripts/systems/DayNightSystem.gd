extends Node

signal phase_changed(is_night: bool)

# O GDD diz que o loop começa de noite (Vampiro)
var is_night: bool = true 

func toggle_phase() -> void:
	is_night = !is_night
	phase_changed.emit(is_night)
	
	if is_night:
		print("Anoiteceu... O Vampiro desperta.")
	else:
		print("Amanheceu... O Humano acorda.")
