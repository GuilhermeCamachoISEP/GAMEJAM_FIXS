extends CanvasLayer
## Escurece tudo fora de um círculo centrado no jogador (coordenadas de ecrã derivadas do raio em mundo).

@export var darken: Color = Color(0.025, 0.02, 0.07, 0.88)

@onready var _rect: ColorRect = $ColorRect

var _mat: ShaderMaterial


func _ready() -> void:
	layer = 35
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh: Shader = load("res://shaders/torch_vision_ring.gdshader") as Shader
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	_rect.material = _mat
	_mat.set_shader_parameter("darken", darken)
	_mat.set_shader_parameter("edge_softness_px", VisionRingConstants.EDGE_SOFTNESS_PX)


func _process(_delta: float) -> void:
	var vp: Viewport = get_viewport()
	if vp == null or _mat == null:
		return
	var size: Vector2 = vp.get_visible_rect().size
	_mat.set_shader_parameter("viewport_px", size)
	var p: Node2D = vp.get_tree().get_first_node_in_group("player") as Node2D
	var xf: Transform2D = vp.get_canvas_transform()
	if p == null or not is_instance_valid(p):
		_mat.set_shader_parameter("center_px", size * 0.5)
		_mat.set_shader_parameter("inner_radius_px", minf(size.x, size.y) * 0.35)
		return
	var c: Vector2 = xf * p.global_position
	_mat.set_shader_parameter("center_px", c)
	var edge: Vector2 = xf * (p.global_position + Vector2(VisionRingConstants.WORLD_RADIUS, 0.0))
	var r_px: float = maxf(8.0, c.distance_to(edge))
	_mat.set_shader_parameter("inner_radius_px", r_px)
