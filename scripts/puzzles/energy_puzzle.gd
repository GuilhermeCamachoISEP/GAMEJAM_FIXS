extends Node2D
## Noite: ligar gerador. Dia: ativar painel final só com cadeia alimentada.
## Sinal: `energy_complete`

signal energy_complete

@onready var _cable_a: Line2D = $CableA
@onready var _cable_b: Line2D = $CableB
@onready var _gen_core: Polygon2D = $Generator/Visual
@onready var _node_mid: Polygon2D = $EnergyNode/Visual
@onready var _panel_core: Polygon2D = $FinalPanel/Visual

var generator_on: bool = false
var _done: bool = false


func _ready() -> void:
	_update_visuals()


func on_generator_interact(is_night: bool) -> void:
	if not is_night:
		print("[Energy] O gerador só responde ao vampiro.")
		return
	generator_on = not generator_on
	_update_visuals()


func on_panel_interact(is_night: bool) -> void:
	if _done:
		return
	if is_night:
		print("[Energy] O painel está morto até ao dia.")
		return
	if not generator_on:
		print("[Energy] Ainda não há energia na rede.")
		return
	_done = true
	energy_complete.emit()
	_update_visuals()


func _chain_lit() -> bool:
	return generator_on


func _update_visuals() -> void:
	var lit := _chain_lit()
	var gen_col := Color(0.35, 0.85, 0.45) if generator_on else Color(0.28, 0.32, 0.38)
	var node_col := Color(0.45, 0.9, 0.95) if lit else Color(0.25, 0.3, 0.35)
	var panel_col := Color(0.95, 0.82, 0.35) if _done else (Color(0.85, 0.55, 0.2) if lit else Color(0.3, 0.28, 0.26))

	_gen_core.color = gen_col
	_node_mid.color = node_col
	_panel_core.color = panel_col

	var c_a := Color(0.5, 0.95, 0.55, 0.95) if generator_on else Color(0.25, 0.28, 0.3, 0.45)
	var c_b := Color(0.55, 0.92, 1.0, 0.95) if lit else Color(0.22, 0.26, 0.3, 0.4)
	_cable_a.default_color = c_a
	_cable_b.default_color = c_b
