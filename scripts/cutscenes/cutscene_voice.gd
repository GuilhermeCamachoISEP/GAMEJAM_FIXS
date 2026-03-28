extends RefCounted
class_name CutsceneVoice
## Narração por **Text-to-Speech** do sistema (Godot `DisplayServer`). Em Windows costuma haver vozes em português.
## Web/Android podem não ter TTS; nesse caso só o tempo mínimo de legenda corre.

static func stop() -> void:
	if DisplayServer.tts_is_available() and DisplayServer.has_method("tts_stop"):
		DisplayServer.tts_stop()


static func _plain_for_tts(bb_or_text: String) -> String:
	var t: String = bb_or_text
	t = t.replace("[center]", "").replace("[/center]", "")
	t = t.replace("[i]", "").replace("[/i]", "")
	t = t.replace("[b]", "").replace("[/b]", "")
	t = t.replace("\n", " ")
	while t.contains("  "):
		t = t.replace("  ", " ")
	return t.strip_edges()


static func _voice_id_portuguese_or_first() -> String:
	if not DisplayServer.tts_is_available():
		return ""
	var voices: Array = DisplayServer.tts_get_voices()
	for v: Variant in voices:
		var lang: String = String(v.get("language", "")).to_lower()
		if lang.begins_with("pt") or lang.contains("por"):
			return String(v.get("id", ""))
	if voices.size() > 0:
		return String(voices[0].get("id", ""))
	return ""


## Lê o texto em voz alta (idioma conforme voz do SO). `plain` pode ser o mesmo da legenda.
static func speak(plain: String) -> void:
	var t: String = _plain_for_tts(plain)
	if t.is_empty():
		return
	if not DisplayServer.tts_is_available() or not DisplayServer.has_method("tts_speak"):
		return
	var vid: String = _voice_id_portuguese_or_first()
	DisplayServer.tts_speak(t, vid)


static func is_speaking() -> bool:
	if not DisplayServer.tts_is_available() or not DisplayServer.has_method("tts_is_speaking"):
		return false
	return DisplayServer.tts_is_speaking()


## Espera até cumprir `min_sec` e, se existir TTS, até a locução terminar (com limite de segurança).
static func wait_line_finish(tree: SceneTree, running: Callable, min_sec: float) -> void:
	var elapsed: float = 0.0
	var cap: float = 150.0
	min_sec = maxf(min_sec, 0.35)
	while elapsed < cap:
		if running.is_valid() and not running.call():
			stop()
			return
		var done_time: bool = elapsed >= min_sec
		var done_voice: bool = not is_speaking()
		if DisplayServer.tts_is_available() and DisplayServer.has_method("tts_speak"):
			if done_time and done_voice:
				break
		else:
			if done_time:
				break
		await tree.create_timer(0.04, false, true).timeout
		elapsed += 0.04
