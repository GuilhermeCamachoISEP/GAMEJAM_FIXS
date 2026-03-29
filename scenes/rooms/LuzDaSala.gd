extends CanvasModulate


func _ready() -> void:
	DayNightSystem.phase_changed.connect(_on_phase_changed)
	_on_phase_changed(DayNightSystem.is_night)


func _on_phase_changed(is_night: bool) -> void:
	if is_night:
		color = Color(1.0, 0.98, 1.02, 1.0)
	else:
		color = Color(1.26, 1.22, 1.16, 1.0)
