extends Node2D
## Dígito escondido na sala: só visível **dentro do círculo de visão** do jogador e na forma certa (vampiro = extremos, humano = centro).

@onready var _label: Label = $Label

var _value: int = 0
## Índices 0 e 2 → vampiro (noite); índice 1 → humano (dia).
var _vampire_clue: bool = true
var _configured: bool = false


func setup_digit(value: int, slot_index: int) -> void:
	_value = clampi(value, 0, 9)
	_vampire_clue = slot_index != 1
	_label.text = str(_value)
	_label.visible = false
	_configured = true


func _process(_delta: float) -> void:
	if not _configured:
		return
	var p: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var night: bool = DayNightSystem.is_night
	var role_ok: bool = (night and _vampire_clue) or (not night and not _vampire_clue)
	var near: bool = p != null and is_instance_valid(p) and global_position.distance_to(p.global_position) <= VisionRingConstants.WORLD_RADIUS
	_label.visible = role_ok and near
