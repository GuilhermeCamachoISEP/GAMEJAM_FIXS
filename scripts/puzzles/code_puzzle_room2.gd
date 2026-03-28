extends Node2D
## Split-code puzzle: night shows A _ C, day shows _ B _; door opens on correct 3-digit code.


@onready var _night_lbl: Label = $CanvasLayer/UIRoot/NightCodeDisplay
@onready var _day_lbl: Label = $CanvasLayer/UIRoot/DayCodeDisplay
@onready var _input: LineEdit = $CanvasLayer/UIRoot/CodeInput
@onready var _submit: Button = $CanvasLayer/UIRoot/SubmitButton
@onready var _feedback: Label = $CanvasLayer/UIRoot/FeedbackText
@onready var _door: StaticBody2D = $Door

var _gm: Room2GameManager
var _digits: Array[int] = []
var _done: bool = false


func _ready() -> void:
	_submit.pressed.connect(_on_submit)
	_input.text_submitted.connect(func(_t: String) -> void: _on_submit())
	_input.text_changed.connect(_on_input_changed)


func bind_manager(gm: Room2GameManager) -> void:
	_gm = gm
	if not gm.phase_changed.is_connected(_on_phase):
		gm.phase_changed.connect(_on_phase)
	_digits = Room2GameManager.get_session_digits().duplicate()
	_refresh_labels()
	_reset_feedback()
	_on_phase(gm.get_current_phase())


func prepare_for_soft_reset() -> void:
	_done = false
	_input.clear()
	_reset_feedback()
	if _door and _door.has_method("set_door_locked"):
		_door.set_door_locked(true)


func _on_phase(p: Room2GameManager.Phase) -> void:
	_refresh_labels()
	var night: bool = p == Room2GameManager.Phase.NIGHT
	_night_lbl.visible = night
	_day_lbl.visible = not night
	_input.visible = not night and not _done
	_submit.visible = not night and not _done
	if night:
		_input.clear()
		_input.editable = false
		_reset_feedback()
	else:
		_input.editable = not _done
		if not _done:
			_input.call_deferred("grab_focus")


func _refresh_labels() -> void:
	if _digits.size() < 3:
		_digits = Room2GameManager.get_session_digits().duplicate()
	var n0 := str(_digits[0])
	var n1 := str(_digits[1])
	var n2 := str(_digits[2])
	_night_lbl.text = "%s _ %s" % [n0, n2]
	_day_lbl.text = "_ %s _" % [n1]


func _reset_feedback() -> void:
	_feedback.text = ""


func _on_input_changed(new_text: String) -> void:
	var d := ""
	for c in new_text:
		if c in "0123456789":
			d += c
	if d.length() > 3:
		d = d.substr(0, 3)
	if d != new_text:
		_input.text = d
		_input.caret_column = _input.text.length()


func _on_submit() -> void:
	if _done or _gm == null:
		return
	if _gm.get_current_phase() == Room2GameManager.Phase.NIGHT:
		return
	var t := _input.text.strip_edges()
	if t.is_empty():
		return
	if t.length() != 3 or not t.is_valid_int():
		_feedback.text = "Invalid code (need 3 digits)."
		return
	if int(t) != _code_value():
		_feedback.text = "Wrong code."
		return
	_done = true
	_feedback.text = "Unlocked."
	if _door and _door.has_method("open_door"):
		_door.open_door()
	_input.editable = false
	_submit.visible = false
	_gm.notify_code_solved()


func _code_value() -> int:
	return _digits[0] * 100 + _digits[1] * 10 + _digits[2]
