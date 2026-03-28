extends CanvasLayer

const EASTER_EGG_TEXTURE_PATH := "res://assets/sprites/10005812_menu_bg.png"
const EASTER_EGG_AUDIO_PATH := "res://assets/audio/12aaaaaaaaaaaaaa-[AudioTrimmer.com].mp3"

@onready var play_button: Button = %PlayButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton
@onready var options_panel: PanelContainer = %OptionsPanel
@onready var back_button: Button = %BackButton
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var fullscreen_check: CheckBox = %FullscreenCheck
@onready var easter_egg_button: TextureButton = %EasterEggButton
@onready var easter_egg_hint: Label = %EasterEggHint

var easter_egg_player: AudioStreamPlayer


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	back_button.pressed.connect(_on_back_pressed)
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)

	_setup_easter_egg()
	_setup_settings_values()


func _setup_easter_egg() -> void:
	if not easter_egg_button:
		push_warning("MainMenu: EasterEggButton node not found.")
		return

	var texture := load(EASTER_EGG_TEXTURE_PATH) as Texture2D
	if texture == null:
		push_warning("MainMenu: easter egg texture missing at %s" % EASTER_EGG_TEXTURE_PATH)
	else:
		easter_egg_button.texture_normal = texture
		easter_egg_button.texture_hover = texture
		easter_egg_button.texture_pressed = texture

	easter_egg_button.ignore_texture_size = true
	easter_egg_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	easter_egg_button.modulate = Color(1, 1, 1, 0.96)
	easter_egg_button.tooltip_text = "?"
	easter_egg_button.focus_mode = Control.FOCUS_NONE
	if not easter_egg_button.button_down.is_connected(_on_easter_egg_pressed):
		easter_egg_button.button_down.connect(_on_easter_egg_pressed)

	easter_egg_player = AudioStreamPlayer.new()
	add_child(easter_egg_player)
	easter_egg_player.process_mode = Node.PROCESS_MODE_ALWAYS
	easter_egg_player.bus = "Master"
	easter_egg_player.volume_db = 6.0

	var stream := load(EASTER_EGG_AUDIO_PATH) as AudioStream
	if stream == null:
		push_warning("MainMenu: easter egg audio missing at %s, using fallback blip." % EASTER_EGG_AUDIO_PATH)
		easter_egg_player.stream = ProceduralSfx.interact_blip()
	else:
		easter_egg_player.stream = stream


func _setup_settings_values() -> void:
	master_slider.value = Settings.get_master_linear()
	music_slider.value = Settings.get_music_linear()
	sfx_slider.value = Settings.get_sfx_linear()
	fullscreen_check.button_pressed = Settings.get_fullscreen()
	options_panel.hide()


func _on_easter_egg_pressed() -> void:
	_play_easter_egg_feedback()
	if easter_egg_player == null or easter_egg_player.stream == null:
		push_warning("MainMenu: easter egg pressed but audio stream is missing.")
		return
	easter_egg_player.stop()
	easter_egg_player.play()


func _play_easter_egg_feedback() -> void:
	if easter_egg_button:
		easter_egg_button.pivot_offset = easter_egg_button.size * 0.5
		easter_egg_button.modulate = Color(1.3, 1.25, 1.1, 1.0)
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_BACK)
		tw.set_ease(Tween.EASE_OUT)
		tw.tween_property(easter_egg_button, "scale", Vector2(1.18, 1.18), 0.08)
		tw.tween_property(easter_egg_button, "scale", Vector2.ONE, 0.16)
		tw.parallel().tween_property(easter_egg_button, "modulate", Color(1, 1, 1, 0.96), 0.22)

	if easter_egg_hint:
		easter_egg_hint.visible = true
		easter_egg_hint.modulate = Color(1, 1, 1, 1)
		easter_egg_hint.position = Vector2(easter_egg_hint.position.x, 0.0)
		var hint_tw := create_tween()
		hint_tw.set_trans(Tween.TRANS_SINE)
		hint_tw.set_ease(Tween.EASE_OUT)
		hint_tw.tween_property(easter_egg_hint, "position:y", -8.0, 0.12)
		hint_tw.parallel().tween_property(easter_egg_hint, "modulate:a", 0.0, 0.9)
		hint_tw.tween_callback(easter_egg_hint.hide)


func _on_play_pressed() -> void:
	App.go_to_scene(GamePaths.INTRO_VAMPIRE_BITE)


func _on_options_pressed() -> void:
	options_panel.show()


func _on_back_pressed() -> void:
	options_panel.hide()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_master_changed(value: float) -> void:
	Settings.set_master_volume_linear(value)


func _on_music_changed(value: float) -> void:
	Settings.set_music_volume_linear(value)


func _on_sfx_changed(value: float) -> void:
	Settings.set_sfx_volume_linear(value)


func _on_fullscreen_toggled(enabled: bool) -> void:
	Settings.set_fullscreen(enabled)
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
