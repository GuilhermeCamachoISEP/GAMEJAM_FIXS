extends CanvasModulate

func _ready() -> void:
	# Ligamos este nó ao sistema de Dia/Noite
	DayNightSystem.phase_changed.connect(_on_phase_changed)
	
	# Garante que a cor certa é aplicada mal o jogo começa
	_on_phase_changed(DayNightSystem.is_night)

func _on_phase_changed(is_night: bool) -> void:
	if is_night:
		# Cria uma atmosfera azul-escura/roxa para a Noite
		color = Color(0.15, 0.15, 0.25, 1.0) 
	else:
		# Luz do Dia (um tom ligeiramente quente/alaranjado)
		color = Color(1.0, 0.95, 0.9, 1.0)
