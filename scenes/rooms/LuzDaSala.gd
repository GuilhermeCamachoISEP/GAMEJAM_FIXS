extends CanvasModulate


func _ready() -> void:
	DayNightSystem.phase_changed.connect(_on_phase_changed)
	_on_phase_changed(DayNightSystem.is_night)


func _on_phase_changed(is_night: bool) -> void:
	if is_night:
		color = Color(0.42, 0.38, 0.52, 1.0)
	else:
		color = Color(0.9, 0.84, 0.76, 1.0)
