extends CanvasLayer
## Mostra notificação "Está de Dia!" ou "Está de Noite!" no topo do ecrã

@onready var _label: Label = $PhaseLabel

var _is_night: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Conectar ao sistema de dia/noite
	if DayNightSystem:
		DayNightSystem.phase_changed.connect(_on_phase_changed)
		_is_night = DayNightSystem.is_night
		_update_text()

	# Animação inicial
	_animate_appear()


func _on_phase_changed(is_night: bool) -> void:
	_is_night = is_night
	_update_text()
	_animate_appear()


func _update_text() -> void:
	if _is_night:
		_label.text = "Está de Noite!"
		_label.modulate = Color(0.85, 0.65, 0.75, 1)  # Tom roxo para noite
	else:
		_label.text = "Está de Dia!"
		_label.modulate = Color(0.95, 0.85, 0.55, 1)  # Tom dourado para dia


func _animate_appear() -> void:
	# Animação de fade in/out
	_label.modulate.a = 0.0
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(_label, "modulate:a", 1.0, 0.4)

	# Mantém visível por alguns segundos e depois fade out
	tw.tween_interval(3.0)
	tw.tween_property(_label, "modulate:a", 0.0, 0.5)
