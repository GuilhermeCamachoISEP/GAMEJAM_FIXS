extends Node
## Arranque opcional da cadeia de cenas. **Não** altera sozinho o `run/main_scene` — a equipa combina
## quando A tiver menu (ex. `first_scene = menu.tscn`) ou pré-carregamentos aqui.
##
## Fluxo: `await App.application_ready` → primeira cena de jogo (ou menu).

@export_file("*.tscn") var first_scene: String = "res://scenes/main.tscn"


func _ready() -> void:
	await App.application_ready
	if first_scene.is_empty() or not ResourceLoader.exists(first_scene):
		push_error("Bootstrap: first_scene inválido: %s" % first_scene)
		return
	App.go_to_scene(first_scene)
