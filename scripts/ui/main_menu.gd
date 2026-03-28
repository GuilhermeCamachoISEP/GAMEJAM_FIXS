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

# 1. Definir as variáveis para o Easter Egg
@onready var easter_egg_button: TextureButton = %EasterEggButton
var easter_egg_player: AudioStreamPlayer

func _ready() -> void:
	# Conexões originais do menu
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	back_button.pressed.connect(_on_back_pressed)
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)

	# 2. Configurar a IMAGEM por script
	if easter_egg_button:
		# Carrega a imagem da pasta assets
		var textura = load("res://assets/sprites/10005812.jpg")
		if textura:
			easter_egg_button.texture_normal = textura
		
		# Ajustes visuais para a imagem não ficar cortada ou gigante
		easter_egg_button.ignore_texture_size = true
		easter_egg_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		
		# Ligar o clique do botão
		easter_egg_button.pressed.connect(_on_easter_egg_pressed)

	# 3. Configurar o SOM por script
	easter_egg_player = AudioStreamPlayer.new()
	add_child(easter_egg_player)
	# Carrega o ficheiro de áudio que tens na pasta
	var audio_file = "res://assets/audio/12aaaaaaaaaaaaaa-[AudioTrimmer.com].mp3"
	easter_egg_player.stream = load(audio_file)
	easter_egg_player.bus = "SFX" # Usa o canal de efeitos sonoros

	# Inicializar valores das definições
	master_slider.value = Settings.get_master_linear()
	music_slider.value = Settings.get_music_linear()
	sfx_slider.value = Settings.get_sfx_linear()
	fullscreen_check.button_pressed = Settings.get_fullscreen()
	options_panel.hide()

# 4. Função que toca o som ao clicar
func _on_easter_egg_pressed() -> void:
	if easter_egg_player and easter_egg_player.stream:
		easter_egg_player.play()

# Restantes funções do menu (Play, Options, etc.)
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
