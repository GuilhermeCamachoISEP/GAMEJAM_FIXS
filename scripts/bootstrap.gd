extends Node
## Primeira cena do `run/main_scene`: espera `App.application_ready`, regista handoff em `Game`, entra em `Game.first_play_scene`.
## Quando existir menu, altera **só** `Game.first_play_scene` (inspector do autoload, ou valor por defeito no script).

func _ready() -> void:
	await App.application_ready
	Game.notify_bootstrap_handoff()
	var path: String = Game.first_play_scene
	if path.is_empty() or not ResourceLoader.exists(path):
		push_error("Bootstrap: Game.first_play_scene inválido: %s" % path)
		return
	App.go_to_scene(path)
