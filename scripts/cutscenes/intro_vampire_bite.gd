extends Node2D
## Abertura: noite na mansão, vampiro aproxima-se e morde o jogador (torna-se vampiro). Depois → `main.tscn`.

const NEXT_SCENE: String = "res://scenes/main.tscn"

@onready var _camera: Camera2D = $Camera2D
@onready var _human: Node2D = $Stage/Human
@onready var _vampire: Node2D = $Stage/Vampire
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
	_vampire.position.x = -520.0
	_human.scale = Vector2(-1.0, 1.0)
	_vampire.scale = Vector2(-1.0, 1.0)
	call_deferred("_play")


func _unhandled_input(event: InputEvent) -> void:
	if not _running:
		return
	if event.is_echo():
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept") or event is InputEventMouseButton and event.pressed:
		_skip_to_game()


func _play() -> void:
	var tw := create_tween()
	tw.set_parallel(false)
	tw.tween_property(_fade, "modulate:a", 0.0, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished
	if not _running:
		return

	await _beats()
	if not _running:
		return

	await _outro()


func _beats() -> void:
	await _subtitle_for("Estás na sala. A noite acaba de cair…", 2.6)
	if not _running:
		return

	var move := create_tween()
	move.tween_property(_vampire, "position:x", -140.0, 2.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await _subtitle_for("Ouves passos. Uma sombra aproxima-se.", 2.4)
	await move.finished
	if not _running:
		return

	await _subtitle_for("…", 0.45)
	if not _running:
		return

	var bite := create_tween()
	bite.set_parallel(true)
	bite.tween_property(_human, "scale", Vector2(1.08, 0.92), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bite.tween_property(_flash, "modulate:a", 0.55, 0.06)
	await bite.finished
	if not _running:
		return
	var bite2 := create_tween()
	bite2.set_parallel(true)
	bite2.tween_property(_human, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	bite2.tween_property(_flash, "modulate:a", 0.0, 0.45)
	await bite2.finished
	if not _running:
		return

	await _subtitle_for("A mordida. O sangue arde. Já não és só humano — és vampiro.\nO teu primeiro loop começa.", 4.2)


func _outro() -> void:
	_running = false
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished
	App.go_to_scene(NEXT_SCENE)


func _subtitle_for(text: String, seconds: float) -> void:
	_set_subtitle(text)
	if seconds <= 0.0:
		return
	await get_tree().create_timer(seconds, true, false, true).timeout


func _set_subtitle(bb_text: String) -> void:
	if _subtitle:
		_subtitle.text = "[center]%s[/center]" % bb_text


func _skip_to_game() -> void:
	if _skippable_after_sec > 0.0:
		return
	_running = false
	App.go_to_scene(NEXT_SCENE)


func _process(delta: float) -> void:
	if _skippable_after_sec > 0.0:
		_skippable_after_sec -= delta
		if _skippable_after_sec <= 0.0 and _skip_hint:
			_skip_hint.visible = true
