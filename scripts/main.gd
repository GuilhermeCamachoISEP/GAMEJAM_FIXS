extends Node2D

## Cena a carregar após `LoopSystem.level_completed` (menu, mapa, próximo nível).
## Deixar vazio enquanto não existir — vitória mantém a cena atual (HUD parado; ver LoopSystem).
## Quando A tiver o menu: definir no inspector do nó Main, ex. `res://scenes/menu.tscn`.
@export var post_victory_scene: String = ""


func _ready() -> void:
	LoopSystem.level_completed.connect(_on_level_completed)
	LoopSystem.level_failed.connect(_on_level_failed)
	LoopSystem.start_level_session()


func _on_level_failed() -> void:
	# `LoopSystem.fail_level()` já agenda `reload_current_scene`; não duplicar lógica aqui.
	pass


func _on_level_completed() -> void:
	if post_victory_scene.is_empty():
		return
	if not ResourceLoader.exists(post_victory_scene):
		push_warning("Main: post_victory_scene não encontrado: %s" % post_victory_scene)
		return
	get_tree().call_deferred("change_scene_to_file", post_victory_scene)
