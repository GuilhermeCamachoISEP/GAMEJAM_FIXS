extends Node2D

const NEXT_SCENE: String = "res://scenes/ui/main_menu.tscn"

@onready var _camera: Camera2D = $Camera2D
@onready var _vampire: Node2D = $Stage/Vampire
@onready var _left_hand: Node2D = $Stage/LeftHand
@onready var _right_hand: Node2D = $Stage/RightHand
@onready var _subtitle: RichTextLabel = %Subtitle
@onready var _skip_hint: Label = %SkipHint
@onready var _fade: ColorRect = %Fade
@onready var _flash: ColorRect = %Flash

var _running: bool = true
var _skippable_after_sec: float = 0.35


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _camera:
		_camera.enabled = true
		_camera.make_current()
	_fade.modulate.a = 1.0
	_flash.modulate.a = 0.0
	_set_subtitle("")
	call_deferred("_play")


func _unhandled_input(event: InputEvent) -> void:
	if not _running or event.is_echo():
		return
	var is_mouse_click: bool = event is InputEventMouseButton and (event as InputEventMouseButton).pressed
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept") or is_mouse_click:
		_skip_to_menu()


func _play() -> void:
	var open := create_tween()
	open.tween_property(_fade, "modulate:a", 0.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await open.finished
	if not _running:
		return

	await _hold_line("[i]Fim do ritual[/i]", 1.6)
	if not _running:
		return

	var approach := create_tween()
	approach.set_parallel(true)
	approach.tween_property(_left_hand, "position", Vector2(-26, -62), 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	approach.tween_property(_right_hand, "position", Vector2(26, -62), 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	approach.tween_property(_camera, "zoom", Vector2(1.45, 1.45), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _hold_line("O vampiro ergue as mãos e toca os próprios olhos.", 2.8)
	if not _running:
		return

	var pulse := create_tween()
	pulse.set_parallel(true)
	pulse.tween_property(_flash, "modulate:a", 0.68, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	pulse.tween_property(_camera, "offset", Vector2(10, -6), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await pulse.finished
	if not _running:
		return

	var settle := create_tween()
	settle.set_parallel(true)
	settle.tween_property(_flash, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	settle.tween_property(_camera, "offset", Vector2.ZERO, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await settle.finished
	if not _running:
		return

	await _hold_line("Tudo escurece. A noite termina onde começou.", 2.6)
	if not _running:
		return

	await _outro()


func _hold_line(text: String, sec: float) -> void:
	_set_subtitle(text)
	CutsceneVoice.speak(text)
	await CutsceneVoice.wait_line_finish(Callable(self, "_is_running"), sec)


func _is_running() -> bool:
	return _running


func _outro() -> void:
	_running = false
	CutsceneVoice.stop()
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished
	CutsceneNav.change_scene(get_tree(), NEXT_SCENE)


func _skip_to_menu() -> void:
	if _skippable_after_sec > 0.0:
		return
	_running = false
	CutsceneVoice.stop()
	CutsceneNav.change_scene(get_tree(), NEXT_SCENE)


func _set_subtitle(bb_text: String) -> void:
	if _subtitle:
		_subtitle.text = "[center]%s[/center]" % bb_text


func _process(delta: float) -> void:
	if _skippable_after_sec > 0.0:
		_skippable_after_sec -= delta
		if _skippable_after_sec <= 0.0 and _skip_hint:
			_skip_hint.visible = true
