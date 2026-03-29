extends Node2D

## Sala dos sinos — puzzle de memória com dia/noite.
## Noite: GRAVAR inicia/para a captura; cada sino tocado entra na fita. Dia: OUVIR reproduz a fita (timbre de noite); repetis a sequência nos sinos.

const NUM_BELLS: int = 4
## Ordem mostrada no vitral (pista do que convém gravar).
const CORRECT_SEQUENCE: Array[int] = [1, 3, 0, 2]
const _MAX_TAPE_NOTES: int = 24

const _CALLBACK_SCRIPT: Script = preload("res://scripts/rooms/interact_callback_area.gd")

enum PuzzleState { UNSOLVED, VAMPIRE_SAW_CLUES, VAMPIRE_RECORDED, SOLVED }

var current_state: PuzzleState = PuzzleState.UNSOLVED
var player_sequence: Array[int] = []
var machine_playing: bool = false

## Fita finalizada (o que a máquina reproduz de dia).
var _tape: Array[int] = []
var _is_recording: bool = false
var _record_buffer: Array[int] = []
var _rec_blink_time: float = 0.0

var bells_container: Node2D
var sound_machine: Node2D
var decor_root: Node2D
var exit_door: Area2D
var feedback_label: Label
var recording_status_label: Label
var controls_hint_label: Label

var _canvas_layer: CanvasLayer

const BELL_COLORS: Array[Color] = [
	Color(0.72, 0.18, 0.2),
	Color(0.22, 0.62, 0.32),
	Color(0.2, 0.35, 0.75),
	Color(0.85, 0.74, 0.22)
]

const BELL_NOTES: Array[float] = [196.0, 293.66, 392.0, 523.25]


func _ready() -> void:
	add_to_group("room4")

	bells_container = Node2D.new()
	bells_container.name = "Bells"
	sound_machine = Node2D.new()
	sound_machine.name = "SoundMachine"
	decor_root = Node2D.new()
	decor_root.name = "Decorations"
	exit_door = Area2D.new()
	exit_door.name = "ExitDoor"

	add_child(decor_root)
	add_child(bells_container)
	add_child(sound_machine)
	add_child(exit_door)

	if has_node("/root/DayNightSystem"):
		if not DayNightSystem.phase_changed.is_connected(_on_phase_changed):
			DayNightSystem.phase_changed.connect(_on_phase_changed)

	_setup_feedback_ui()
	_setup_gothic_room()
	_setup_bells()
	_setup_machine()
	_setup_door()
	_setup_ambient_dust()

	if _check_night():
		_begin_night_intro()
	else:
		_toggle_hints(false)
		_show_msg("O sol entra pela rosácea; os segredos dormem.")
	_refresh_controls_hint()


func _on_phase_changed(is_night: bool) -> void:
	if not is_night and _is_recording:
		_finalize_recording(true)
	_toggle_hints(is_night)
	_refresh_controls_hint()
	if is_night:
		if current_state == PuzzleState.UNSOLVED:
			current_state = PuzzleState.VAMPIRE_SAW_CLUES
		_show_msg("A noite devolve as cores ao vitral partido.")
	else:
		_show_msg("O dia cobre as marcas — a memória da gravação mantém-se.")


func _setup_feedback_ui() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 22
	add_child(_canvas_layer)

	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	feedback_label.add_theme_font_size_override("font_size", 22)
	feedback_label.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.06))
	feedback_label.add_theme_constant_override("outline_size", 6)
	feedback_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	feedback_label.offset_top = 56.0
	feedback_label.offset_bottom = 112.0
	feedback_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_canvas_layer.add_child(feedback_label)

	recording_status_label = Label.new()
	recording_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recording_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	recording_status_label.add_theme_font_size_override("font_size", 40)
	recording_status_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.22))
	recording_status_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04))
	recording_status_label.add_theme_constant_override("outline_size", 8)
	recording_status_label.set_anchors_preset(Control.PRESET_CENTER)
	recording_status_label.offset_left = -320.0
	recording_status_label.offset_right = 320.0
	recording_status_label.offset_top = -200.0
	recording_status_label.offset_bottom = -80.0
	recording_status_label.visible = false
	_canvas_layer.add_child(recording_status_label)

	controls_hint_label = Label.new()
	controls_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	controls_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_hint_label.add_theme_font_size_override("font_size", 15)
	controls_hint_label.add_theme_color_override("font_color", Color(0.92, 0.9, 0.96))
	controls_hint_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.05))
	controls_hint_label.add_theme_constant_override("outline_size", 4)
	controls_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	controls_hint_label.offset_top = -220.0
	controls_hint_label.offset_bottom = -100.0
	controls_hint_label.offset_left = 80.0
	controls_hint_label.offset_right = -80.0
	_canvas_layer.add_child(controls_hint_label)
	_refresh_controls_hint()


## Chamado primeiro pelo `Player.interact()`: máquina tem prioridade por distância (sem lutar com raycast dos sinos).
func try_consume_machine_interact() -> bool:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p == null:
		return false
	var nr := sound_machine.get_node_or_null("BtnRecord") as Node2D
	var npl := sound_machine.get_node_or_null("BtnPlay") as Node2D
	if nr == null or npl == null:
		return false
	var d_rec := p.global_position.distance_to(nr.global_position)
	var d_play := p.global_position.distance_to(npl.global_position)
	var thr := 150.0
	if d_rec > thr and d_play > thr:
		return false
	var use_record := d_rec < d_play
	if is_equal_approx(d_rec, d_play):
		use_record = _check_night()
	if use_record:
		_on_record_pressed()
	else:
		_on_play_pressed()
	return true


func _refresh_controls_hint() -> void:
	if controls_hint_label == null:
		return
	var key_str := _interact_key_display()
	var a := "Não há clique no rato: usa a tecla %s (Interagir), encostado ao objeto." % key_str
	var b := "Se ouviste um som de sino, estavas a interagir com um sino — vai à máquina de eco (centro, em baixo)."
	var c: String
	if _check_night():
		c = "Noite: encosta-te à máquina (baixo ao centro). %s em GRAVAR (vermelho) = começa · aparece REC · %s nos sinos · %s de novo em GRAVAR = para e guarda." % [key_str, key_str, key_str]
	else:
		c = "Dia: encosta-te à máquina. %s em OUVIR (verde) = ouve a fita da noite; depois repete nos sinos com %s." % [key_str, key_str]
	controls_hint_label.text = a + "\n" + b + "\n" + c


func _interact_key_display() -> String:
	if InputMap.has_action("interact"):
		for ev: InputEvent in InputMap.action_get_events("interact"):
			if ev is InputEventKey:
				var k: InputEventKey = ev as InputEventKey
				var code: Key = k.keycode if k.keycode != KEY_NONE else k.physical_keycode
				if code != KEY_NONE:
					return OS.get_keycode_string(code)
	return "E"


func _process(delta: float) -> void:
	if not _is_recording or recording_status_label == null:
		return
	_rec_blink_time += delta
	var pulse: float = 0.55 + 0.45 * abs(sin(_rec_blink_time * 7.0))
	recording_status_label.modulate = Color(1.0, pulse, pulse, 1.0)


func _begin_night_intro() -> void:
	current_state = PuzzleState.VAMPIRE_SAW_CLUES
	_toggle_hints(true)
	_show_msg("Visão vampírica: segue o vitral. GRAVAR liga a fita, toca os sinos, GRAVAR outra vez para guardar.")


func _setup_gothic_room() -> void:
	var z_floor := -30
	var z_wall := -20

	var floor_poly := Polygon2D.new()
	floor_poly.z_index = z_floor
	floor_poly.color = Color(0.06, 0.055, 0.05)
	floor_poly.polygon = PackedVector2Array([
		Vector2(-960, -540), Vector2(960, -540), Vector2(960, 540), Vector2(-960, 540)
	])
	decor_root.add_child(floor_poly)

	for i in range(14):
		var plank := Polygon2D.new()
		plank.z_index = z_floor + 1
		plank.color = Color(0.08 + (i % 3) * 0.012, 0.06, 0.045)
		var x0 := -920.0 + i * 140.0
		plank.polygon = PackedVector2Array([
			Vector2(x0, -520), Vector2(x0 + 128, -520), Vector2(x0 + 132, 520), Vector2(x0 - 4, 520)
		])
		decor_root.add_child(plank)

	var rug := Polygon2D.new()
	rug.z_index = z_floor + 2
	rug.color = Color(0.32, 0.06, 0.08, 0.92)
	rug.polygon = _ellipse_polygon(Vector2(0, 120), Vector2(420, 160), 48)
	decor_root.add_child(rug)

	var back := Polygon2D.new()
	back.z_index = z_wall
	back.color = Color(0.07, 0.065, 0.09)
	back.polygon = PackedVector2Array([
		Vector2(-880, -420), Vector2(880, -420), Vector2(820, 320), Vector2(-820, 320)
	])
	decor_root.add_child(back)

	var arch := Line2D.new()
	arch.z_index = z_wall + 1
	arch.width = 6.0
	arch.default_color = Color(0.25, 0.2, 0.28)
	arch.points = _arch_points(Vector2(0, -400), 420.0, 310.0)
	decor_root.add_child(arch)

	var rose := Node2D.new()
	rose.name = "RoseWindow"
	rose.position = Vector2(0, -180)
	rose.z_index = z_wall + 2
	decor_root.add_child(rose)
	_build_rose_window(rose)

	var side_l := Polygon2D.new()
	side_l.z_index = z_wall
	side_l.color = Color(0.045, 0.042, 0.05)
	side_l.polygon = PackedVector2Array([
		Vector2(-960, -520), Vector2(-640, -420), Vector2(-620, 340), Vector2(-960, 520)
	])
	decor_root.add_child(side_l)

	var side_r := Polygon2D.new()
	side_r.z_index = z_wall
	side_r.color = Color(0.045, 0.042, 0.05)
	side_r.polygon = PackedVector2Array([
		Vector2(960, -520), Vector2(640, -420), Vector2(620, 340), Vector2(960, 520)
	])
	decor_root.add_child(side_r)

	var chains := Line2D.new()
	chains.z_index = 5
	chains.width = 2.5
	chains.default_color = Color(0.35, 0.34, 0.38, 0.65)
	chains.points = PackedVector2Array([
		Vector2(-520, -460), Vector2(-500, -120), Vector2(500, -120), Vector2(520, -460)
	])
	decor_root.add_child(chains)

	var p1 := _create_pillar(Vector2(-520, 20), "PillarLeft")
	var p2 := _create_pillar(Vector2(520, 20), "PillarRight")
	decor_root.add_child(p1)
	decor_root.add_child(p2)

	var glass := _create_broken_glass(Vector2(0, -120))
	decor_root.add_child(glass)

	var skull := Polygon2D.new()
	skull.z_index = 4
	skull.color = Color(0.55, 0.52, 0.48)
	skull.position = Vector2(-780, 180)
	skull.polygon = PackedVector2Array([
		Vector2(0, -20), Vector2(18, -28), Vector2(32, -10), Vector2(28, 24),
		Vector2(8, 40), Vector2(-12, 38), Vector2(-26, 10), Vector2(-22, -12)
	])
	decor_root.add_child(skull)


func _build_rose_window(parent: Node2D) -> void:
	var rings := [[130.0, 0.12, 0.14, 0.22, 0.75], [95.0, 0.35, 0.42, 0.65, 0.5], [55.0, 0.55, 0.22, 0.2, 0.45]]
	for spec in rings:
		var p := Polygon2D.new()
		p.color = Color(spec[1], spec[2], spec[3], spec[4])
		p.polygon = _circle_poly(spec[0], 32)
		parent.add_child(p)

	const COLS: Array[Color] = [Color(0.75, 0.2, 0.22, 0.7), Color(0.25, 0.65, 0.35, 0.65), Color(0.28, 0.4, 0.8, 0.65), Color(0.85, 0.7, 0.25, 0.65)]
	for i in range(6):
		var pet := Polygon2D.new()
		var a := float(i) / 6.0 * TAU
		pet.color = COLS[i % COLS.size()]
		var pts := PackedVector2Array()
		pts.append(Vector2.ZERO)
		for j in range(8):
			var aa := a + (float(j) / 7.0) * (TAU / 6.0)
			pts.append(Vector2(cos(aa), sin(aa)) * 48.0)
		pet.polygon = pts
		parent.add_child(pet)


func _arch_points(center: Vector2, width: float, height: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := 24
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var a := PI + t * PI
		pts.append(center + Vector2(cos(a) * width, sin(a) * height * 0.55 + height * 0.2))
	return pts


func _ellipse_polygon(center: Vector2, radius: Vector2, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments):
		var a := float(i) / float(segments) * TAU
		pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	return pts


func _create_pillar(pos: Vector2, p_name: String) -> Node2D:
	var p := Node2D.new()
	p.position = pos
	p.name = p_name

	var base := Polygon2D.new()
	base.color = Color(0.12, 0.11, 0.13)
	base.position = Vector2(0, 200)
	base.polygon = PackedVector2Array([
		Vector2(-56, 40), Vector2(56, 40), Vector2(48, 0), Vector2(-48, 0)
	])
	p.add_child(base)

	var shaft := Polygon2D.new()
	shaft.color = Color(0.16, 0.15, 0.18)
	shaft.polygon = PackedVector2Array([
		Vector2(-44, -280), Vector2(44, -280), Vector2(52, 200), Vector2(-52, 200)
	])
	p.add_child(shaft)

	var cap := Polygon2D.new()
	cap.color = Color(0.22, 0.2, 0.24)
	cap.position = Vector2(0, -280)
	cap.polygon = PackedVector2Array([
		Vector2(-60, 0), Vector2(60, 0), Vector2(50, -36), Vector2(-50, -36)
	])
	p.add_child(cap)

	var r_node := Node2D.new()
	r_node.name = "Runes"
	const RUNES := ["ᚠ", "ᚢ", "ᚦ", "ᚨ"]
	for i in range(4):
		var r := Label.new()
		r.text = RUNES[i]
		r.position = Vector2(-16, -220 + i * 110)
		r.modulate = BELL_COLORS[CORRECT_SEQUENCE[i]]
		r.modulate.a = 0.0
		r.add_theme_font_size_override("font_size", 28)
		r_node.add_child(r)
	p.add_child(r_node)

	var candle := Polygon2D.new()
	candle.color = Color(0.95, 0.82, 0.35)
	candle.position = Vector2(0, -300)
	candle.polygon = PackedVector2Array([Vector2(-6, 0), Vector2(6, 0), Vector2(4, -28), Vector2(-4, -28)])
	p.add_child(candle)

	var flame := PointLight2D.new()
	flame.position = Vector2(0, -318)
	flame.color = Color(1.0, 0.75, 0.35)
	flame.energy = 0.55
	flame.texture_scale = 2.2
	p.add_child(flame)

	var flicker := func():
		var tw := p.create_tween().set_loops()
		tw.tween_property(flame, "energy", 0.38, 0.35)
		tw.tween_property(flame, "energy", 0.62, 0.4)
	flicker.call()

	return p


func _create_broken_glass(pos: Vector2) -> Node2D:
	var g := Node2D.new()
	g.position = pos
	g.name = "BrokenGlass"
	var bar := Line2D.new()
	bar.width = 3.0
	bar.default_color = Color(0.5, 0.55, 0.65, 0.35)
	bar.points = PackedVector2Array([Vector2(-200, 24), Vector2(200, 24)])
	g.add_child(bar)

	var slot := 0
	for bell_idx in CORRECT_SEQUENCE:
		var f := Node2D.new()
		f.name = "Order_%d_Bell%d" % [slot, bell_idx]
		f.position = Vector2(-150 + slot * 100, 0)

		var crack := Line2D.new()
		crack.width = 1.2
		crack.default_color = Color(0.7, 0.72, 0.8, 0.5)
		crack.points = PackedVector2Array([Vector2(-20, -18), Vector2(8, 16), Vector2(22, -6)])
		f.add_child(crack)

		var s := Polygon2D.new()
		s.name = "HiddenSymbol"
		s.color = BELL_COLORS[bell_idx]
		s.color.a = 0.0
		s.polygon = PackedVector2Array([
			Vector2(-22, -20), Vector2(22, -20), Vector2(26, 24), Vector2(-26, 24)
		])
		f.add_child(s)

		var ord_l := Label.new()
		ord_l.name = "StepLabel"
		ord_l.text = str(slot + 1)
		ord_l.position = Vector2(-8, -42)
		ord_l.modulate = Color(0.85, 0.8, 0.95)
		ord_l.modulate.a = 0.0
		ord_l.add_theme_font_size_override("font_size", 18)
		f.add_child(ord_l)

		g.add_child(f)
		slot += 1
	return g


func _setup_bells() -> void:
	var pos_list := [
		Vector2(-300, 80), Vector2(-100, 48), Vector2(100, 48), Vector2(300, 80)
	]
	for i in range(NUM_BELLS):
		var b := Node2D.new()
		b.name = "Bell%d" % i
		b.position = pos_list[i]

		var rope := Line2D.new()
		rope.width = 2.0
		rope.default_color = Color(0.35, 0.28, 0.22)
		rope.points = PackedVector2Array([Vector2(0, -180), Vector2(0, -52)])
		b.add_child(rope)

		var body := Polygon2D.new()
		body.name = "Body"
		body.color = BELL_COLORS[i].darkened(0.45)
		body.polygon = PackedVector2Array([
			Vector2(-22, -48), Vector2(22, -48), Vector2(38, 36), Vector2(-38, 36)
		])
		b.add_child(body)

		var rim := Line2D.new()
		rim.width = 3.0
		rim.default_color = BELL_COLORS[i].lightened(0.15)
		var rp := PackedVector2Array()
		for j in range(17):
			var a := PI + float(j) / 16.0 * PI
			rp.append(Vector2(cos(a) * 40.0, sin(a) * 22.0 - 8.0))
		rim.points = rp
		b.add_child(rim)

		var lip := Polygon2D.new()
		lip.color = BELL_COLORS[i].darkened(0.2)
		lip.polygon = PackedVector2Array([
			Vector2(-40, 32), Vector2(40, 32), Vector2(34, 48), Vector2(-34, 48)
		])
		b.add_child(lip)

		var area := Area2D.new()
		area.collision_layer = 1
		area.collision_mask = 0
		area.monitoring = true
		area.set_script(_CALLBACK_SCRIPT)
		(area as InteractCallbackArea).callback = Callable(self, "ring_bell").bind(b)
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(130, 150)
		shape.position = Vector2(0, -10)
		shape.shape = rect
		area.add_child(shape)
		b.add_child(area)

		var stand := Polygon2D.new()
		stand.color = Color(0.14, 0.13, 0.16)
		stand.position = Vector2(0, 52)
		stand.polygon = PackedVector2Array([
			Vector2(-48, 0), Vector2(48, 0), Vector2(42, 22), Vector2(-42, 22)
		])
		b.add_child(stand)

		bells_container.add_child(b)


func ring_bell(bell_node: Node2D) -> void:
	if machine_playing:
		return
	var idx: int = int(bell_node.name.replace("Bell", ""))
	var body := bell_node.get_node("Body") as Polygon2D
	var tw := create_tween()
	tw.tween_property(body, "scale", Vector2(1.15, 0.88), 0.08)
	tw.tween_property(body, "scale", Vector2(1.0, 1.0), 0.12)

	_play_sound(BELL_NOTES[idx])
	if _check_night():
		if _is_recording:
			if _record_buffer.size() < _MAX_TAPE_NOTES:
				_record_buffer.append(idx)
				_update_recording_ui()
			else:
				_show_msg("Fita cheia — carrega em GRAVAR para parar.")
	else:
		_on_bell_day_attempt(idx)


func _play_sound(freq: float) -> void:
	## Noite e dia usam o mesmo som de sino para reconheceres a ordem na fita (OUVIR = mesmo timbre).
	_play_sound_with_timbre(freq, false)


## `night_timbre` só para efeitos especiais; sinos e fita usam sempre `false` (timbre de dia).
func _play_sound_with_timbre(freq: float, night_timbre: bool) -> void:
	var p := AudioStreamPlayer.new()
	add_child(p)
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = 44100
	var d := 0.42
	var n := int(44100 * d)
	var b := PackedByteArray()
	b.resize(n * 2)
	var f := freq * (0.62 if night_timbre else 1.32)
	for i in range(n):
		var t := float(i) / 44100.0
		var env: float = exp(-t * 5.2)
		var harm := sin(t * f * TAU) * 0.72 + sin(t * f * 2.0 * TAU) * 0.22
		var val := int(clamp(harm * env * 22000.0, -32000.0, 32000.0))
		b.encode_s16(i * 2, val)
	s.data = b
	p.stream = s
	p.play()
	p.finished.connect(p.queue_free)


func _update_recording_ui() -> void:
	var rec_face: Polygon2D = sound_machine.get_node_or_null("BtnRecord/Face") as Polygon2D
	if rec_face:
		if _is_recording:
			rec_face.color = Color(1.0, 0.22, 0.18)
		else:
			rec_face.color = Color(0.65, 0.12, 0.14)
	if recording_status_label:
		if _is_recording:
			recording_status_label.visible = true
			recording_status_label.text = "REC\n%d nota(s)\n(E em GRAVAR para parar)" % _record_buffer.size()
		else:
			recording_status_label.visible = false
			recording_status_label.text = ""


func _start_recording() -> void:
	if current_state == PuzzleState.SOLVED:
		_show_msg("A porta já cedeu.")
		return
	_record_buffer.clear()
	_is_recording = true
	_rec_blink_time = 0.0
	_update_recording_ui()
	_show_msg("Gravação ligada. Toca os sinos; carrega E de novo em GRAVAR para parar e guardar.")


func _finalize_recording(from_daybreak: bool = false) -> void:
	_is_recording = false
	_update_recording_ui()
	if _record_buffer.is_empty():
		if from_daybreak:
			_show_msg("O dia nasceu — não ficou nada na fita.")
		else:
			_show_msg("Fita vazia. Gravação cancelada.")
		return
	_tape = _record_buffer.duplicate()
	player_sequence.clear()
	if current_state != PuzzleState.SOLVED:
		current_state = PuzzleState.VAMPIRE_RECORDED
	_complete_checklist_task("r4_recorded_sequence")
	_show_msg("Fita com %d notas guardada. De dia, usa OUVIR para a ouvir." % _tape.size())


func _setup_machine() -> void:
	sound_machine.position = Vector2(0, 320)
	sound_machine.z_index = 2

	var pedestal := Polygon2D.new()
	pedestal.color = Color(0.11, 0.1, 0.12)
	pedestal.polygon = PackedVector2Array([
		Vector2(-120, 40), Vector2(120, 40), Vector2(110, 72), Vector2(-110, 72)
	])
	sound_machine.add_child(pedestal)

	var base := Polygon2D.new()
	base.color = Color(0.09, 0.085, 0.1)
	base.position = Vector2(0, -40)
	base.polygon = PackedVector2Array([
		Vector2(-100, -10), Vector2(100, -10), Vector2(96, 48), Vector2(-96, 48)
	])
	sound_machine.add_child(base)

	var reel_l := Polygon2D.new()
	reel_l.color = Color(0.18, 0.16, 0.2)
	reel_l.position = Vector2(-48, -4)
	reel_l.polygon = _circle_poly(22.0, 20)
	sound_machine.add_child(reel_l)

	var reel_r := Polygon2D.new()
	reel_r.color = Color(0.18, 0.16, 0.2)
	reel_r.position = Vector2(48, -4)
	reel_r.polygon = _circle_poly(22.0, 20)
	sound_machine.add_child(reel_r)

	var label := Label.new()
	label.text = "Máquina de eco"
	label.position = Vector2(-72, -36)
	label.modulate = Color(0.82, 0.78, 0.88)
	label.add_theme_font_size_override("font_size", 16)
	sound_machine.add_child(label)

	_create_machine_button(Vector2(-40, 24), Color(0.65, 0.12, 0.14), "GRAVAR", "BtnRecord")
	_create_machine_button(Vector2(40, 24), Color(0.12, 0.55, 0.22), "OUVIR", "BtnPlay")


func _create_machine_button(offset: Vector2, col: Color, txt: String, root_name: String = "") -> void:
	var root := Node2D.new()
	root.position = offset
	if not root_name.is_empty():
		root.name = root_name

	var face := Polygon2D.new()
	face.name = "Face"
	face.color = col
	face.polygon = _circle_poly(24.0, 20)
	root.add_child(face)

	var ring := Line2D.new()
	ring.width = 2.5
	ring.default_color = Color(0.92, 0.9, 0.95, 0.4)
	var rp := PackedVector2Array()
	for i in range(21):
		var a := float(i) / 20.0 * TAU
		rp.append(Vector2(cos(a) * 26.0, sin(a) * 26.0))
	ring.points = rp
	root.add_child(ring)

	var cap := Label.new()
	cap.text = txt
	cap.position = Vector2(-36, -11)
	cap.modulate = Color(0.95, 0.94, 0.98)
	cap.add_theme_font_size_override("font_size", 11)
	root.add_child(cap)

	sound_machine.add_child(root)


func _on_record_pressed() -> void:
	if not _check_night():
		_show_msg("Só à noite a máquina grava.")
		return
	if machine_playing:
		return
	if _is_recording:
		_finalize_recording(false)
	else:
		_start_recording()


func _on_play_pressed() -> void:
	if _check_night():
		_show_msg("A reprodução só funciona de dia.")
		return
	if _tape.is_empty():
		_show_msg("A fita está vazia — grava de noite primeiro.")
		return
	if machine_playing:
		return
	machine_playing = true
	_show_msg("A reproduzir a fita…")
	for i: int in _tape:
		_play_sound(BELL_NOTES[i])
		await get_tree().create_timer(0.68).timeout
	machine_playing = false
	_show_msg("Isso foi a tua fita — repete nos sinos.")


func _on_bell_day_attempt(idx: int) -> void:
	if current_state != PuzzleState.VAMPIRE_RECORDED or _tape.is_empty():
		return
	player_sequence.append(idx)
	var n: int = player_sequence.size()
	if player_sequence[n - 1] != _tape[n - 1]:
		player_sequence.clear()
		_show_msg("Ordem errada — a sequência começa de novo.")
	elif n == _tape.size():
		current_state = PuzzleState.SOLVED
		_complete_checklist_task("r4_solved_bells")
		_show_msg("Harmonia certa. A porta abre em verde — interage para sair.")
		_animate_exit_door_open()


func _animate_exit_door_open() -> void:
	var vis: Polygon2D = exit_door.get_node("Visual") as Polygon2D
	var frame: Polygon2D = exit_door.get_node_or_null("DoorFrame") as Polygon2D
	var hnd: Polygon2D = exit_door.get_node_or_null("DoorHandle") as Polygon2D
	var door_light: PointLight2D = exit_door.get_node_or_null("ExitGlow") as PointLight2D
	if vis == null:
		return
	var tw := create_tween().set_parallel()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(vis, "color", Color(0.1, 0.78, 0.4), 0.5)
	tw.tween_property(vis, "position:x", 38.0, 0.55)
	if frame:
		tw.tween_property(frame, "color", Color(0.14, 0.48, 0.26), 0.5)
	if hnd:
		tw.tween_property(hnd, "color", Color(0.88, 0.98, 0.45), 0.45)
	if door_light:
		door_light.color = Color(0.35, 1.0, 0.55)
		tw.tween_property(door_light, "energy", 1.2, 0.55)


func _setup_door() -> void:
	exit_door.position = Vector2(820, 40)
	exit_door.z_index = 3
	exit_door.collision_layer = 1
	exit_door.monitoring = true

	var frame := Polygon2D.new()
	frame.name = "DoorFrame"
	frame.color = Color(0.22, 0.18, 0.16)
	frame.z_index = -1
	frame.polygon = PackedVector2Array([
		Vector2(-52, -92), Vector2(52, -92), Vector2(48, 92), Vector2(-48, 92)
	])
	exit_door.add_child(frame)

	var v := Polygon2D.new()
	v.name = "Visual"
	v.position = Vector2.ZERO
	v.color = Color(0.32, 0.12, 0.14)
	v.polygon = PackedVector2Array([
		Vector2(-42, -78), Vector2(42, -78), Vector2(42, 78), Vector2(-42, 78)
	])
	exit_door.add_child(v)

	var handle := Polygon2D.new()
	handle.name = "DoorHandle"
	handle.color = Color(0.55, 0.5, 0.35)
	handle.position = Vector2(28, 8)
	handle.polygon = PackedVector2Array([
		Vector2(0, -8), Vector2(14, -4), Vector2(14, 10), Vector2(0, 6)
	])
	exit_door.add_child(handle)

	var glow := PointLight2D.new()
	glow.name = "ExitGlow"
	glow.color = Color(0.4, 0.85, 0.45)
	glow.energy = 0.0
	glow.texture_scale = 3.5
	exit_door.add_child(glow)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(88, 168)
	shape.shape = rect
	exit_door.add_child(shape)

	exit_door.set_script(_CALLBACK_SCRIPT)
	(exit_door as InteractCallbackArea).callback = Callable(self, "_on_exit_interact")


func _on_exit_interact() -> void:
	if current_state != PuzzleState.SOLVED:
		_show_msg("Madeira fechada; falta o ritual dos sinos.")
		return
	if not LoopSystem.is_exit_unlocked():
		_show_msg("A checklist ainda pede passos.")
		return
	LoopSystem.complete_level()


func _check_night() -> bool:
	if has_node("/root/DayNightSystem"):
		return DayNightSystem.is_night
	return false


func _complete_checklist_task(task_id: String) -> void:
	if not has_node("/root/ChecklistSystem"):
		return
	var cl := get_node("/root/ChecklistSystem") as ChecklistData
	if cl.is_task_done(task_id):
		return
	cl.complete_task(task_id)


func _toggle_hints(show: bool) -> void:
	var a: float = 0.88 if show else 0.0
	for pname: String in ["PillarLeft", "PillarRight"]:
		var pillar: Node = decor_root.get_node_or_null(pname)
		if pillar == null:
			continue
		var runes: Node = pillar.get_node_or_null("Runes")
		if runes == null:
			continue
		for r: Node in runes.get_children():
			if r is Label:
				(r as Label).modulate.a = a
	var glass := decor_root.get_node_or_null("BrokenGlass")
	if glass:
		for child: Node in glass.get_children():
			if not child.name.begins_with("Order_"):
				continue
			var sym := child.get_node_or_null("HiddenSymbol") as Polygon2D
			if sym:
				sym.color.a = a
			var lbl := child.get_node_or_null("StepLabel") as Label
			if lbl:
				lbl.modulate.a = a


func _show_msg(t: String) -> void:
	feedback_label.text = t
	feedback_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(feedback_label, "modulate:a", 0.0, 3.2).set_delay(2.0)


func _setup_ambient_dust() -> void:
	var dust := CPUParticles2D.new()
	dust.z_index = 15
	dust.amount = 42
	dust.lifetime = 5.5
	dust.preprocess = 2.0
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(880, 520)
	dust.direction = Vector2(0.1, -0.6)
	dust.spread = 28.0
	dust.initial_velocity_min = 8.0
	dust.initial_velocity_max = 22.0
	dust.angular_velocity_min = -12.0
	dust.angular_velocity_max = 12.0
	dust.scale_amount_min = 0.35
	dust.scale_amount_max = 1.0
	dust.color = Color(0.88, 0.86, 0.92, 0.12)
	add_child(dust)


func _circle_poly(radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments):
		var ang := float(i) / float(segments) * TAU
		pts.append(Vector2(cos(ang) * radius, sin(ang) * radius))
	return pts
