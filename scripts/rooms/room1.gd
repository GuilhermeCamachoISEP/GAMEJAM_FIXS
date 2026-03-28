extends Node2D

@onready var _vamp_zone_visual: Polygon2D = $ZonaVampiro/Visual

## Cor HDR para Glow no `Polygon2D` da zona (valores > 1 quando o ambiente tem Glow).
const _VAMP_GLOW_BASE := Color(3.0, 0.5, 3.0)

const _INTERACTIVE_NODES: PackedStringArray = ["Quadro", "Cofre", "Porta", "ZonaVampiro"]

func _ready() -> void:
	_setup_light_occluders()
	_setup_vampire_hdr_glow()
	_connect_interactable_signals()


func _setup_light_occluders() -> void:
	for node_name: String in ["Quadro", "Cofre"]:
		var obj := get_node_or_null(node_name) as Node2D
		if obj == null:
			continue
		var visual := obj.get_node_or_null("Visual") as Polygon2D
		if visual == null or visual.polygon.is_empty():
			continue
		var occluder_node := LightOccluder2D.new()
		var occluder_shape := OccluderPolygon2D.new()
		occluder_shape.polygon = visual.polygon
		occluder_node.occluder = occluder_shape
		obj.add_child(occluder_node)


func _setup_vampire_hdr_glow() -> void:
	if _vamp_zone_visual:
		_vamp_zone_visual.self_modulate = _VAMP_GLOW_BASE


func _process(_delta: float) -> void:
	if _vamp_zone_visual == null:
		return
	var t := Time.get_ticks_msec() / 1000.0
	var breathe := 0.85 + 0.15 * sin(t)
	_vamp_zone_visual.self_modulate = _VAMP_GLOW_BASE * breathe


func _connect_interactable_signals() -> void:
	var cb := Callable(self, "_on_object_interacted")
	for node_name: String in _INTERACTIVE_NODES:
		var n := get_node_or_null(node_name)
		if n == null:
			continue
		if n.has_signal("interacted") and not n.is_connected("interacted", cb):
			n.connect("interacted", cb)


func _on_object_interacted(object_name: String) -> void:
	# Liga aqui puzzles, flags em LoopSystem, mudança de cena, etc.
	print("[Room1] Interação: ", object_name)
