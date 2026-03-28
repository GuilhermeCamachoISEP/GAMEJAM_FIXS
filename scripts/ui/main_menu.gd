extends Control
## Menu principal do jogo.
## Botões: Jogar → res://scenes/main.tscn | Opções → placeholder | Sair → quit.
##
## TODO (responsável pelo core): para o jogo abrir neste menu,
## alterar `Game.first_play_scene` (scripts/core/game.gd linha 20)
## de "res://scenes/cutscenes/intro_vampire_bite.tscn"
## para "res://scenes/ui/main_menu.tscn".

@onready var _btn_play: Button = %BtnPlay
@onready var _btn_options: Button = %BtnOptions
@onready var _btn_quit: Button = %BtnQuit
@onready var _options_panel: PanelContainer = %OptionsPanel


func _ready() -> void:
	_btn_play.pressed.connect(_on_play_pressed)
	_btn_options.pressed.connect(_on_options_pressed)
	_btn_quit.pressed.connect(_on_quit_pressed)
	_options_panel.visible = false


func _on_play_pressed() -> void:
	var app: Node = get_tree().root.get_node_or_null("App")
	if app != null and app.has_method("go_to_scene"):
		app.call("go_to_scene", "res://scenes/main.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_options_pressed() -> void:
	_options_panel.visible = not _options_panel.visible


func _on_quit_pressed() -> void:
	get_tree().quit()
