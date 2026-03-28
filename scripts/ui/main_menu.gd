extends CanvasLayer

@onready var play_button: Button = %PlayButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton
@onready var options_panel: PanelContainer = %OptionsPanel
@onready var back_button: Button = %BackButton
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var fullscreen_check: CheckBox = %FullscreenCheck

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	back_button.pressed.connect(_on_back_pressed)

	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)

	# Initialize sliders with current values
	master_slider.value = Settings.get_master_linear()
	music_slider.value = Settings.get_music_linear()
	sfx_slider.value = Settings.get_sfx_linear()
	fullscreen_check.button_pressed = Settings.get_fullscreen()

	options_panel.hide()

func _on_play_pressed() -> void:
	# TODO: Change Game.first_play_scene to this menu path in game.gd
	# For now, go directly to main level
	App.go_to_scene(GamePaths.MAIN_LEVEL)

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
