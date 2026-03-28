extends Node
## Definições em `user://settings.cfg`. **Menu / opções** da equipa devem chamar estes setters; persistência e aplicação a buses/janela ficam centralizadas.

const CFG_PATH: String = "user://settings.cfg"
const SECTION: String = "game"

signal settings_loaded
signal settings_saved

signal master_volume_changed(linear: float)
signal music_volume_changed(linear: float)
signal sfx_volume_changed(linear: float)
signal fullscreen_changed(enabled: bool)
signal vsync_changed(enabled: bool)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_and_apply()


func load_and_apply() -> void:
	var cf := ConfigFile.new()
	var err: Error = cf.load(CFG_PATH)
	if err != OK:
		_write_defaults(cf)
		cf.save(CFG_PATH)
	_apply_config(cf)
	settings_loaded.emit()


func save_all() -> void:
	var cf := ConfigFile.new()
	cf.load(CFG_PATH)
	_store_current_into_config(cf)
	cf.save(CFG_PATH)
	settings_saved.emit()


func get_master_linear() -> float:
	return _read_linear("master_linear", 1.0)


func get_music_linear() -> float:
	return _read_linear("music_linear", 0.85)


func get_sfx_linear() -> float:
	return _read_linear("sfx_linear", 1.0)


func get_fullscreen() -> bool:
	var cf := ConfigFile.new()
	cf.load(CFG_PATH)
	return bool(cf.get_value(SECTION, "fullscreen", false))


func get_vsync() -> bool:
	var cf := ConfigFile.new()
	cf.load(CFG_PATH)
	return bool(cf.get_value(SECTION, "vsync", true))


func set_master_volume_linear(v: float, persist: bool = true) -> void:
	v = clampf(v, 0.0, 1.0)
	AudioBuses.set_linear_master(v)
	master_volume_changed.emit(v)
	if persist:
		_persist_key("master_linear", v)


func set_music_volume_linear(v: float, persist: bool = true) -> void:
	v = clampf(v, 0.0, 1.0)
	AudioBuses.set_linear_music(v)
	music_volume_changed.emit(v)
	if persist:
		_persist_key("music_linear", v)


func set_sfx_volume_linear(v: float, persist: bool = true) -> void:
	v = clampf(v, 0.0, 1.0)
	AudioBuses.set_linear_sfx(v)
	sfx_volume_changed.emit(v)
	if persist:
		_persist_key("sfx_linear", v)


func set_fullscreen(enabled: bool, persist: bool = true) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	fullscreen_changed.emit(enabled)
	if persist:
		_persist_key("fullscreen", enabled)


func set_vsync(enabled: bool, persist: bool = true) -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED
	)
	vsync_changed.emit(enabled)
	if persist:
		_persist_key("vsync", enabled)


func _write_defaults(cf: ConfigFile) -> void:
	cf.set_value(SECTION, "master_linear", 1.0)
	cf.set_value(SECTION, "music_linear", 0.85)
	cf.set_value(SECTION, "sfx_linear", 1.0)
	cf.set_value(SECTION, "fullscreen", false)
	cf.set_value(SECTION, "vsync", true)


func _apply_config(cf: ConfigFile) -> void:
	var m: float = float(cf.get_value(SECTION, "master_linear", 1.0))
	var mu: float = float(cf.get_value(SECTION, "music_linear", 0.85))
	var sx: float = float(cf.get_value(SECTION, "sfx_linear", 1.0))
	AudioBuses.set_linear_master(m)
	AudioBuses.set_linear_music(mu)
	AudioBuses.set_linear_sfx(sx)
	var fs: bool = bool(cf.get_value(SECTION, "fullscreen", false))
	var vs: bool = bool(cf.get_value(SECTION, "vsync", true))
	if fs:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vs else DisplayServer.VSYNC_DISABLED
	)


func _store_current_into_config(cf: ConfigFile) -> void:
	cf.set_value(SECTION, "master_linear", AudioBuses.get_bus_linear_by_name(AudioBuses.MASTER))
	cf.set_value(SECTION, "music_linear", AudioBuses.get_bus_linear_by_name(AudioBuses.MUSIC))
	cf.set_value(SECTION, "sfx_linear", AudioBuses.get_bus_linear_by_name(AudioBuses.SFX))
	var fs: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	cf.set_value(SECTION, "fullscreen", fs)
	var vs: bool = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
	cf.set_value(SECTION, "vsync", vs)


func _read_linear(key: String, default_v: float) -> float:
	var cf := ConfigFile.new()
	if cf.load(CFG_PATH) != OK:
		return default_v
	return float(cf.get_value(SECTION, key, default_v))


func _persist_key(key: String, value: Variant) -> void:
	var cf := ConfigFile.new()
	cf.load(CFG_PATH)
	cf.set_value(SECTION, key, value)
	cf.save(CFG_PATH)
	settings_saved.emit()
