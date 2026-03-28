extends CanvasModulate


func _ready() -> void:
	DayNightSystem.phase_changed.connect(_on_phase_changed)
	_on_phase_changed(DayNightSystem.is_night)


func _on_phase_changed(is_night: bool) -> void:
	if is_night:
		# Night should still be readable, but clearly moodier than day.
		color = Color(0.9, 0.88, 0.96, 1.0)
	else:
		# Day should feel unmistakably bright and easy to read.
		color = Color(1.18, 1.14, 1.08, 1.0)
