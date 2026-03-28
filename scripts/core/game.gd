extends Node
## Núcleo de **domínio** deste jogo: fases da corrida (run), caminhos de cena canónicos e ligação a `LoopSystem`.
## Colocado **depois** de `App` nos Autoloads. Não duplica timers nem checklist — só estado de alto nível e navegação coerente.

signal run_phase_changed(phase: RunPhase)
## `get_tree().paused` é a fonte de verdade; o menu de pausa deve usar `set_game_paused` para todo o jogo reagir igual.
signal game_pause_changed(is_paused: bool)

enum RunPhase {
	STARTUP,
	APPLICATION_READY,
	ENTERING_FIRST_SCENE,
	IN_LEVEL,
	LEVEL_FAILED_PENDING_RELOAD,
	LEVEL_WON,
	TRANSITIONING,
}

## Primeira cena após o bootstrap (nível raiz ou menu quando A existir). Editável no script ou no inspector do nó **Game** nos Autoloads (Godot 4.x).
@export_file("*.tscn") var first_play_scene: String = "res://scenes/ui/main_menu.tscn"

## Ligar para ver mudanças de fase na consola (**Output** ao correr com F5).
@export var debug_log_phases: bool = false

var run_phase: RunPhase = RunPhase.STARTUP


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var app_node: Node = get_tree().root.get_node_or_null("App")
	if app_node != null and app_node.has_signal("application_ready"):
		app_node.connect("application_ready", Callable(self, "_on_app_ready"), CONNECT_ONE_SHOT)
	var loop_node: Node = get_tree().root.get_node_or_null("LoopSystem")
	if loop_node != null and loop_node.has_signal("level_failed"):
		loop_node.connect("level_failed", Callable(self, "_on_level_failed"))


func _set_phase(next: RunPhase) -> void:
	if run_phase == next:
		return
	run_phase = next
	if debug_log_phases:
		print("[Game] run_phase → %s" % _phase_to_string(next))
	run_phase_changed.emit(next)


func _phase_to_string(p: RunPhase) -> String:
	match p:
		RunPhase.STARTUP:
			return "STARTUP"
		RunPhase.APPLICATION_READY:
			return "APPLICATION_READY"
		RunPhase.ENTERING_FIRST_SCENE:
			return "ENTERING_FIRST_SCENE"
		RunPhase.IN_LEVEL:
			return "IN_LEVEL"
		RunPhase.LEVEL_FAILED_PENDING_RELOAD:
			return "LEVEL_FAILED_PENDING_RELOAD"
		RunPhase.LEVEL_WON:
			return "LEVEL_WON"
		RunPhase.TRANSITIONING:
			return "TRANSITIONING"
		_:
			return str(p)


func _on_app_ready() -> void:
	_set_phase(RunPhase.APPLICATION_READY)


func _on_level_failed() -> void:
	_set_phase(RunPhase.LEVEL_FAILED_PENDING_RELOAD)


## Chamado desde `bootstrap.gd` antes de `App.go_to_scene(first_play_scene)`.
func notify_bootstrap_handoff() -> void:
	_set_phase(RunPhase.ENTERING_FIRST_SCENE)


## Chamado desde `main.gd` quando o nível arranca ou reinicia após falha.
func notify_level_loaded() -> void:
	_set_phase(RunPhase.IN_LEVEL)


## Chamado desde `main.gd` no fim do nível. Path vazio → `LEVEL_WON` sem mudar de cena (HUD parado).
func go_to_post_victory(scene_path: String) -> void:
	if scene_path.is_empty():
		_set_phase(RunPhase.LEVEL_WON)
		return
	_set_phase(RunPhase.TRANSITIONING)
	var app: Node = get_tree().root.get_node_or_null("App")
	if app != null and app.has_method("go_to_scene_deferred"):
		app.call("go_to_scene_deferred", scene_path)
	else:
		push_error("Game: autoload App em falta.")


func set_game_paused(is_paused: bool) -> void:
	if get_tree().paused == is_paused:
		return
	get_tree().paused = is_paused
	game_pause_changed.emit(is_paused)


func is_game_paused() -> bool:
	return get_tree().paused


## Útil em UI de pausa: alterna e devolve o novo estado.
func toggle_game_paused() -> bool:
	set_game_paused(not get_tree().paused)
	return get_tree().paused
