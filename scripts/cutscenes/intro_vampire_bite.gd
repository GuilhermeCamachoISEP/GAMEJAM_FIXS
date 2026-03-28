extends Node2D
## Abertura: noite na mansão, vampiro aproxima-se e morde o jogador (torna-se vampiro). Depois → `main.tscn`.

const NEXT_SCENE: String = "res://scenes/main.tscn"

const HUMAN_FACE_FLIP := Vector2(-1.0, 1.0)

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
	_vampire.position = Vector2(-520.0, _vampire.position.y)
	_human.scale = HUMAN_FACE_FLIP
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
	var open := create_tween()
	open.tween_property(_fade, "modulate:a", 0.0, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await open.finished
	if not _running:
		return

	await _beats()
	if not _running:
		return

	await _outro()


func _beats() -> void:
	await _subtitle_hold("Estás na sala. A noite acaba de cair…", 2.5)
	if not _running:
		return

	_set_subtitle("Ouves passos. Uma sombra aproxima-se.")
	## Um único await no tween — evita ficar preso entre timer e Tween.finished.
	var approach := create_tween()
	approach.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUINT)
	approach.tween_property(_vampire, "position:x", -95.0, 3.2)
	await approach.finished
	if not _running:
		return

	await _subtitle_hold("Ele inclina-se para ti…", 1.1)
	if not _running:
		return

	## Aproximação final + mordida (flash + escala mantendo o flip do humano).
	var lunge := create_tween()
	lunge.set_parallel(true)
	lunge.tween_property(_vampire, "position:x", -35.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	lunge.tween_property(_vampire, "rotation", 0.08, 0.18)
	await lunge.finished
	if not _running:
		return

	_set_subtitle("— A mordida.")

	var bite := create_tween()
	bite.set_parallel(true)
	bite.tween_property(_human, "scale", Vector2(-1.12, 0.88), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bite.tween_property(_flash, "modulate:a", 0.62, 0.05)
	bite.tween_property(_camera, "offset", Vector2(6.0, -3.0), 0.06)
	await bite.finished
	if not _running:
		return

	var recover := create_tween()
	recover.set_parallel(true)
	recover.tween_property(_human, "scale", HUMAN_FACE_FLIP, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	recover.tween_property(_flash, "modulate:a", 0.0, 0.55)
	recover.tween_property(_vampire, "position:x", -120.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	recover.tween_property(_vampire, "rotation", 0.0, 0.45)
	recover.tween_property(_camera, "offset", Vector2.ZERO, 0.5)
	await recover.finished
	if not _running:
		return

	await _subtitle_hold(
		"A mordida queima nas veias. Já não és só humano — és vampiro.\nO teu primeiro loop começa.",
		4.6
	)


func _outro() -> void:
	_running = false
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, 0.95).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished
	_go_to_main_scene()


func _subtitle_hold(text: String, seconds: float) -> void:
	_set_subtitle(text)
	if seconds <= 0.0:
		return
	## Timer simples; ignore_time_scale evita cortar a cutscene se o tempo do jogo mudar.
	await get_tree().create_timer(seconds, false, true).timeout


func _set_subtitle(bb_text: String) -> void:
	if _subtitle:
		_subtitle.text = "[center]%s[/center]" % bb_text


func _skip_to_game() -> void:
	if _skippable_after_sec > 0.0:
		return
	_running = false
	_go_to_main_scene()


func _go_to_main_scene() -> void:
	## Evita depender do identificador global `App` no compilador (autoload nem sempre exposto como nome global).
	var app := get_tree().root.get_node_or_null("App")
	if app != null and app.has_method("go_to_scene"):
		app.call("go_to_scene", NEXT_SCENE)
	elif ResourceLoader.exists(NEXT_SCENE):
		get_tree().change_scene_to_file(NEXT_SCENE)
	else:
		push_error("IntroCutscene: cena inválida: %s" % NEXT_SCENE)


func _process(delta: float) -> void:
	if _skippable_after_sec > 0.0:
		_skippable_after_sec -= delta
		if _skippable_after_sec <= 0.0 and _skip_hint:
			_skip_hint.visible = true
