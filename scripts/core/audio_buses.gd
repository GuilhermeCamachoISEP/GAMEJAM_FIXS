extends RefCounted
class_name AudioBuses
## Nomes de **Audio buses** acordados com a equipa de som. Criar no editor: **Project → Audio → Buses** (`Music`, `SFX`) se ainda não existirem.
## Volumes em linear 0..1; conversão interna para dB.

const MASTER: String = "Master"
const MUSIC: String = "Music"
const SFX: String = "SFX"


static func _bus_index_or_neg(bus_name: String) -> int:
	return AudioServer.get_bus_index(bus_name)


## Aplica volume linear; se o bus não existir, ignora (sem erro em builds sem Music/SFX ainda).
static func set_bus_linear_by_name(bus_name: String, linear: float) -> void:
	var idx: int = _bus_index_or_neg(bus_name)
	if idx < 0:
		return
	linear = clampf(linear, 0.0, 1.0)
	var db: float = linear_to_db(maxf(linear, 0.0001))
	AudioServer.set_bus_volume_db(idx, db)


static func get_bus_linear_by_name(bus_name: String) -> float:
	var idx: int = _bus_index_or_neg(bus_name)
	if idx < 0:
		return 1.0
	return db_to_linear(AudioServer.get_bus_volume_db(idx))


static func set_linear_master(linear: float) -> void:
	set_bus_linear_by_name(MASTER, linear)


static func set_linear_music(linear: float) -> void:
	set_bus_linear_by_name(MUSIC, linear)


static func set_linear_sfx(linear: float) -> void:
	set_bus_linear_by_name(SFX, linear)
