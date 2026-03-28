extends RefCounted
class_name CutsceneNav
## Troca de cena sem usar os identificadores globais `App`/`Game` (compatível com o compilador GDScript).

static func change_scene(tree: SceneTree, path: String) -> void:
	if path.is_empty():
		push_error("CutsceneNav: path vazio.")
		return
	if not ResourceLoader.exists(path):
		push_error("CutsceneNav: ficheiro inexistente: %s" % path)
		return
	var app: Node = tree.root.get_node_or_null("App")
	if app != null and app.has_method("go_to_scene"):
		app.call("go_to_scene", path)
	else:
		tree.change_scene_to_file(path)
