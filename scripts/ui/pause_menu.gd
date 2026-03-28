extends CanvasLayer

@onready var panel: PanelContainer = %Panel
@onready var resume_button: Button = %ResumeButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton
@onready var options_panel: PanelContainer = %OptionsPanel
@onready var back_button: Button = %BackButton
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var fullscreen_check: CheckBox = %FullscreenCheck

var _is_paused: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.hide()
	options_panel.hide()

	resume_button.pressed.connect(_on_resume_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	back_button.pressed.connect(_on_back_pressed)

	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)

	# Connect to Game pause signal
	if is_instance_valid(Game):
		Game.game_pause_changed.connect(_on_pause_changed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	if is_instance_valid(Game):
		Game.toggle_game_paused()
	else:
		# Fallback if Game autoload is not available
		_is_paused = not _is_paused
		get_tree().paused = _is_paused
		_update_visibility()

func _on_pause_changed(is_paused: bool) -> void:
	_is_paused = is_paused
	_update_visibility()

func _update_visibility() -> void:
	panel.visible = _is_paused
	if not _is_paused:
		options_panel.hide()

	# Update slider values when showing
	if _is_paused:
		master_slider.value = Settings.get_master_linear()
		music_slider.value = Settings.get_music_linear()
		sfx_slider.value = Settings.get_sfx_linear()
		fullscreen_check.button_pressed = Settings.get_fullscreen()

func _on_resume_pressed() -> void:
	if is_instance_valid(Game):
		Game.set_game_paused(false)
	else:
		_is_paused = false
		get_tree().paused = false
		_update_visibility()

func _on_options_pressed() -> void:
	options_panel.show()

func _on_back_pressed() -> void:
	options_panel.hide()

func _on_quit_pressed() -> void:
	# Go back to main menu instead of quitting
	if is_instance_valid(Game):
		Game.set_game_paused(false)
	App.go_to_scene("res://scenes/ui/main_menu.tscn")

func _on_master_changed(value: float) -> void:
	Settings.set_master_volume_linear(value)

func _on_music_changed(value: float) -> void:
	Settings.set_music_volume_linear(value)

func _on_sfx_changed(value: float) -> void:
	Settings.set_sfx_volume_linear(value)

func _on_fullscreen_toggled(enabled: bool) -> void:
	print("[PauseMenu] Fullscreen toggled: ", enabled)
	Settings.set_fullscreen(enabled)
	# Force apply in case Settings didn't apply it
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
