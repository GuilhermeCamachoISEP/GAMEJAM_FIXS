extends Node
## Fachada de arranque da aplicação e ponto único para mudanças de cena com validação.
## Autoload **antes** de `Game`. Ordem: sistemas de jogo → `App` → `Game`.
##
## Não substitui `LoopSystem` nem lógica de nível — apenas ordem de vida da app e navegação estável.

signal application_ready
## Emitido antes de `change_scene_to_file`; útil para fade-out ou guardar estado.
signal scene_change_started(path: String)
## Emitido após `change_scene_to_file` devolver `OK` (a nova cena começa a instanciar de seguida).
signal scene_change_finished

enum Phase { BOOT, RUNNING }

var phase: Phase = Phase.BOOT


func _ready() -> void:
	# Mesmo com áudio/jogo em pausa, o núcleo pode completar o arranque.
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_complete_boot")


func _complete_boot() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	phase = Phase.RUNNING
	application_ready.emit()


## Troca de cena imediata (não usar dentro de callbacks que corram durante troca de árvore sem deferred).
func go_to_scene(scene_path: String) -> Error:
	if scene_path.is_empty():
		push_warning("App.go_to_scene: path vazio.")
		return ERR_INVALID_PARAMETER
	if not ResourceLoader.exists(scene_path):
		push_warning("App.go_to_scene: ficheiro inexistente: %s" % scene_path)
		return ERR_FILE_NOT_FOUND

	## Nova cena arranca sempre despausada (evita ficar preso após pausa no menu/nível).
	get_tree().paused = false

	scene_change_started.emit(scene_path)
	var err: Error = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("App.go_to_scene: falha (%s) código %s" % [scene_path, str(err)])
		return err
	scene_change_finished.emit()
	return OK


## Seguro a partir de sinais (`level_completed`, botões de UI, etc.).
func go_to_scene_deferred(scene_path: String) -> void:
	call_deferred("_deferred_go_to_scene", scene_path)


func _deferred_go_to_scene(scene_path: String) -> void:
	go_to_scene(scene_path)
