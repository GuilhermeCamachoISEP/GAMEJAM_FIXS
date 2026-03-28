extends RefCounted
class_name ProceduralSfx

## Gera AudioStreamWAV em PCM 16-bit mono (sem ficheiros externos — útil para jam / placeholder).
## Substituir por imports .ogg no AudioStreamPlayer quando tiveres assets finais.

const DEFAULT_MIX := 22050


static func _append_i16(pcm: PackedByteArray, sample: float) -> void:
	var v := clampi(int(sample * 32000.0), -32768, 32767)
	pcm.append(v & 0xFF)
	pcm.append((v >> 8) & 0xFF)


static func _pcm_to_stream(pcm: PackedByteArray, mix_rate: int = DEFAULT_MIX) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = mix_rate
	s.stereo = false
	s.loop_mode = AudioStreamWAV.LOOP_DISABLED
	s.data = pcm
	return s


static func footstep_thump() -> AudioStreamWAV:
	var mix := DEFAULT_MIX
	var dur := 0.07
	var n := int(dur * float(mix))
	var pcm := PackedByteArray()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in n:
		var t := float(i) / float(n)
		var env := exp(-t * 18.0)
		var nse := (rng.randf() * 2.0 - 1.0) * 0.35
		var thump := sin(PI * t) * 0.45
		_append_i16(pcm, (nse * 0.4 + thump) * env)
	return _pcm_to_stream(pcm, mix)


static func interact_blip() -> AudioStreamWAV:
	var mix := DEFAULT_MIX
	var dur := 0.06
	var n := int(dur * float(mix))
	var pcm := PackedByteArray()
	var freq := 880.0
	for i in n:
		var t := float(i) / float(mix)
		var env := exp(-t * 35.0)
		_append_i16(pcm, sin(TAU * freq * t) * 0.22 * env)
	return _pcm_to_stream(pcm, mix)


static func dash_whoosh() -> AudioStreamWAV:
	var mix := DEFAULT_MIX
	var dur := 0.14
	var n := int(dur * float(mix))
	var pcm := PackedByteArray()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in n:
		var t := float(i) / float(mix)
		var env := smoothstep(0.0, 0.02, t) * (1.0 - smoothstep(0.1, 0.14, t))
		var f := lerpf(420.0, 90.0, t / dur)
		var s := sin(TAU * f * t) * 0.18
		var nse := (rng.randf() * 2.0 - 1.0) * 0.25
		_append_i16(pcm, (s + nse * 0.5) * env)
	return _pcm_to_stream(pcm, mix)


static func phase_night_chime() -> AudioStreamWAV:
	return _two_tone(140.0, 95.0, 0.11)


static func phase_day_chime() -> AudioStreamWAV:
	return _two_tone(330.0, 440.0, 0.1)


static func _two_tone(f0: float, f1: float, dur: float) -> AudioStreamWAV:
	var mix := DEFAULT_MIX
	var n := int(dur * float(mix))
	var pcm := PackedByteArray()
	var half := n / 2
	for i in n:
		var t := float(i) / float(mix)
		var f := f0 if i < half else f1
		var env := sin(PI * float(i) / float(n))
		_append_i16(pcm, sin(TAU * f * t) * 0.2 * env)
	return _pcm_to_stream(pcm, mix)


static func bump_thud() -> AudioStreamWAV:
	var mix := DEFAULT_MIX
	var dur := 0.08
	var n := int(dur * float(mix))
	var pcm := PackedByteArray()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in n:
		var t := float(i) / float(n)
		var env := exp(-t * 25.0)
		var thump := sin(PI * t) * 0.6
		var nse := (rng.randf() * 2.0 - 1.0) * 0.2
		_append_i16(pcm, (thump + nse * 0.3) * env)
	return _pcm_to_stream(pcm, mix)
