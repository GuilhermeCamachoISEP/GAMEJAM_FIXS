extends Node2D
## Código em duas metades: noite mostra extremos, dia o dígito central.
## O jogador de dia introduz o código completo de 3 dígitos.
## Sinal: `code_correct`

signal code_correct

@onready var _night_lbl: Label = $NightCodeDisplay
@onready var _day_lbl: Label = $DayCodeDisplay
@onready var _input: LineEdit = $CodeInput
@onready var _submit: Button = $SubmitButton

var _digits: Array[int] = [0, 0, 0]
var _done: bool = false


func _ready() -> void:
	_roll_code()
	_submit.pressed.connect(_on_submit)
	_input.text_submitted.connect(func(_t: String) -> void: _on_submit())
	DayNightSystem.phase_changed.connect(_on_phase)
	_on_phase(DayNightSystem.is_night)


func _roll_code() -> void:
	for i in 3:
		_digits[i] = randi_range(0, 9)
	# Evita ambiguidade de strings vazias / zeros à esquerda no texto
	if _digits[0] == 0:
		_digits[0] = randi_range(1, 9)


func _refresh_labels() -> void:
	var n0 := str(_digits[0])
	var n1 := str(_digits[1])
	var n2 := str(_digits[2])
	_night_lbl.text = "%s _ %s" % [n0, n2]
	_day_lbl.text = "_ %s _" % [n1]


func _on_phase(is_night: bool) -> void:
	_refresh_labels()
	_night_lbl.visible = is_night
	_day_lbl.visible = not is_night
	_input.visible = not is_night
	_submit.visible = not is_night
	if not is_night:
		_input.editable = true
		_input.placeholder_text = "3 dígitos"
		_input.call_deferred("grab_focus")
	else:
		_input.clear()
		_input.editable = false


func _on_submit() -> void:
	if _done or DayNightSystem.is_night:
		return
	var t := _input.text.strip_edges()
	if t.length() != 3 or not t.is_valid_int():
		print("[CodePuzzle] Introduz exatamente 3 dígitos.")
		return
	if int(t) == _code_value():
		_done = true
		code_correct.emit()


func _code_value() -> int:
	return _digits[0] * 100 + _digits[1] * 10 + _digits[2]
