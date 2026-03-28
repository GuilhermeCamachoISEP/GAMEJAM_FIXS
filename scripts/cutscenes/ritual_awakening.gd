extends Node2D
## Cutscene II — depois da mordida: reflexão breve antes de `main.tscn`. TTS em português via `DisplayServer` (depende do SO).

const NEXT_SCENE: String = "res://scenes/main.tscn"

@onready var _camera: Camera2D = $Camera2D
@onready var _subtitle: RichTextLabel = %Subtitle
@onready var _skip_hint: Label = %SkipHint
@onready var _fade: ColorRect = %Fade
@onready var _pulse: ColorRect = %Pulse

var _running: bool = true
var _skippable_after_sec: float = 0.35


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _camera:
		_camera.enabled = true
		_camera.make_current()
	_fade.modulate.a = 1.0
	if _pulse:
		_pulse.modulate.a = 0.12
	_set_subtitle("")
	call_deferred("_play")


func _unhandled_input(event: InputEvent) -> void:
	if not _running or event.is_echo():
		return
	var is_mouse_click: bool = event is InputEventMouseButton \
		and (event as InputEventMouseButton).pressed
	if event.is_action_pressed("ui_cancel") \
			or event.is_action_pressed("ui_accept") \
			or is_mouse_click:
		_skip_to_game()


func _running_yes() -> bool:
	return _running


func _play() -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 0.0, 1.0)
	await tw.finished
	if not _running:
		return

	var pulse_tween := create_tween()
	pulse_tween.set_loops(12)
	pulse_tween.tween_property(_pulse, "modulate:a", 0.38, 1.4).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(_pulse, "modulate:a", 0.06, 1.4).set_trans(Tween.TRANS_SINE)

	await _line_voice("[i]Capítulo II — O pacto da noite[/i]", 2.5)
	if not _running: return

	await _line_voice(
		"Ouves o relógio da mansão. O tempo já não te pertence como antes.",
		4.0
	)
	if not _running: return

	await _line_voice(
		"Cada noite serás caçador. Cada dia… outra pessoa em ti acorda.",
		4.2
	)
	if not _running: return

	await _line_voice("Respira fundo. A mansão espera.", 3.0)
	if not _running: return

	pulse_tween.kill()
	await _outro()


func _line_voice(bb: String, min_sec: float) -> void:
	_set_subtitle(bb)
	CutsceneVoice.speak(bb)
	await CutsceneVoice.wait_line_finish(_running_yes, min_sec)


func _outro() -> void:
	_running = false
	CutsceneVoice.stop()
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, 0.9)
	await tw.finished
	CutsceneNav.change_scene(get_tree(), NEXT_SCENE)


func _set_subtitle(bb_text: String) -> void:
	if _subtitle:
		_subtitle.text = "[center]%s[/center]" % bb_text


func _skip_to_game() -> void:
	if _skippable_after_sec > 0.0:
		return
	_running = false
	CutsceneVoice.stop()
	CutsceneNav.change_scene(get_tree(), NEXT_SCENE)


func _process(delta: float) -> void:
	if _skippable_after_sec > 0.0:
		_skippable_after_sec -= delta
		if _skippable_after_sec <= 0.0 and _skip_hint:
			_skip_hint.visible = true
