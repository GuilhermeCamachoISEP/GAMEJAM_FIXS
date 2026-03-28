extends Node
## Narração por Text-to-Speech do sistema (Godot DisplayServer).
## Registado como Autoload com o nome "CutsceneVoice" em Project Settings → Autoload.
## Em Windows costuma haver vozes em português.
## Web/Android podem não ter TTS; nesse caso só o tempo mínimo de legenda corre.

const _TICK: float = 0.04
const _CAP: float = 150.0
const _MIN_HOLD: float = 0.35

var _voice_id: String = ""
var _has_tts: bool = false


func _ready() -> void:
	_has_tts = ClassDB.class_has_method("DisplayServer", "tts_is_available") \
		and DisplayServer.call("tts_is_available")
	if _has_tts:
		_voice_id = _resolve_voice_id()


func speak(plain: String) -> void:
	if not _has_tts:
		return
	var t: String = _plain_for_tts(plain)
	if t.is_empty():
		return
	DisplayServer.call("tts_speak", t, _voice_id)


func stop() -> void:
	if not _has_tts:
		return
	DisplayServer.call("tts_stop")


func is_speaking() -> bool:
	if not _has_tts:
		return false
	return DisplayServer.call("tts_is_speaking")


## Espera até cumprir `min_sec` e, se TTS disponível, até a locução terminar.
## `running` é um Callable que retorna bool — se retornar false, para imediatamente.
func wait_line_finish(running: Callable, min_sec: float) -> void:
	min_sec = maxf(min_sec, _MIN_HOLD)
	var elapsed: float = 0.0

	while elapsed < _CAP:
		if running.is_valid() and not running.call():
			stop()
			return
		if elapsed >= min_sec and (not is_speaking() or not _has_tts):
			break
		await get_tree().create_timer(_TICK, false, true).timeout
		elapsed += _TICK


func _plain_for_tts(bb_or_text: String) -> String:
	var regex := RegEx.new()
	regex.compile("\\[/?(?:center|i|b|s|u|img|url|code|color=[^\\]]*|url=[^\\]]*|font=[^\\]]*)\\]")
	var t: String = regex.sub(bb_or_text, "", true)
	t = t.replace("\n", " ")
	while t.contains("  "):
		t = t.replace("  ", " ")
	return t.strip_edges()


func _resolve_voice_id() -> String:
	var voices: Array = DisplayServer.call("tts_get_voices")
	for v: Variant in voices:
		var lang: String = String(v.get("language", "")).to_lower()
		if lang.begins_with("pt") or lang.contains("por"):
			return String(v.get("id", ""))
	if not voices.is_empty():
		return String(voices[0].get("id", ""))
	return ""
