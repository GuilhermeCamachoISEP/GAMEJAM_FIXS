extends CanvasLayer
## Menu de código na porta: H fecha; dígitos editáveis com apagar (LineEdit).

signal submitted(code: String)
signal menu_closed

@onready var _line: LineEdit = %CodeLine
@onready var _feedback: Label = %Feedback
@onready var _submit: Button = %SubmitBtn


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_submit.pressed.connect(_emit_submit)
	_line.text_submitted.connect(func(_t: String) -> void: _emit_submit())
	_line.text_changed.connect(_on_text_changed)
	_line.gui_input.connect(_on_line_gui_input)
	call_deferred("_grab")


func _grab() -> void:
	if is_instance_valid(_line):
		_line.grab_focus()


func _on_line_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("door_h"):
		_close_menu()
		_line.accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("door_h"):
		_close_menu()
		get_viewport().set_input_as_handled()


func _emit_submit() -> void:
	submitted.emit(_line.text.strip_edges())


func show_feedback(msg: String) -> void:
	_feedback.text = msg


func close_success() -> void:
	_close_menu()


func _close_menu() -> void:
	get_tree().paused = false
	menu_closed.emit()
	queue_free()


func _on_text_changed(new_text: String) -> void:
	var d := ""
	for c in new_text:
		if c in "0123456789":
			d += c
	if d.length() > 3:
		d = d.substr(0, 3)
	if d != new_text:
		_line.text = d
		_line.caret_column = _line.text.length()
