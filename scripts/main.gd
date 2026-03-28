extends Node2D

## Cena a carregar após `LoopSystem.level_completed` (menu, mapa, próximo nível).
## Deixar vazio enquanto não existir — vitória mantém a cena atual (HUD parado; ver LoopSystem).
## Quando A tiver o menu: definir no inspector do nó Main, ex. `res://scenes/menu.tscn`.
@export var post_victory_scene: String = ""


func _ready() -> void:
	add_to_group("gameplay")
	LoopSystem.level_completed.connect(_on_level_completed)
	LoopSystem.level_failed.connect(_on_level_failed)
	LoopSystem.start_level_session()
	var game_node: Node = get_tree().root.get_node_or_null("Game")
	if game_node != null and game_node.has_method("notify_level_loaded"):
		game_node.call("notify_level_loaded")


func _on_level_failed() -> void:
	# `LoopSystem.fail_level()` já agenda `reload_current_scene`; não duplicar lógica aqui.
	pass


func _on_level_completed() -> void:
	var game_node: Node = get_tree().root.get_node_or_null("Game")
	if game_node != null and game_node.has_method("go_to_post_victory"):
		game_node.call("go_to_post_victory", post_victory_scene)
