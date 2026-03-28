extends Node
## Primeira cena do `run/main_scene`: espera `application_ready` do autoload **App**, notifica **Game**, carrega `first_play_scene`.

func _ready() -> void:
	var tree := get_tree()
	var app_node: Node = tree.root.get_node_or_null("App")
	if app_node == null:
		push_error("Bootstrap: autoload App em falta.")
		return
	if not app_node.has_signal("application_ready"):
		push_error("Bootstrap: App sem sinal application_ready.")
		return
	app_node.connect("application_ready", Callable(self, "_on_application_ready"), CONNECT_ONE_SHOT)


func _on_application_ready() -> void:
	var tree := get_tree()
	var game_node: Node = tree.root.get_node_or_null("Game")
	if game_node != null and game_node.has_method("notify_bootstrap_handoff"):
		game_node.call("notify_bootstrap_handoff")

	var path: String = ""
	if game_node != null:
		path = String(game_node.get("first_play_scene"))

	if path.is_empty() or not ResourceLoader.exists(path):
		push_error("Bootstrap: Game.first_play_scene inválido: %s" % path)
		return

	var app_node: Node = tree.root.get_node_or_null("App")
	if app_node != null and app_node.has_method("go_to_scene"):
		app_node.call("go_to_scene", path)
	else:
		tree.change_scene_to_file(path)
