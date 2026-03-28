extends Node2D

## ═══════════════════════════════════════════════════════════
## SALA DOS SONS - VERSÃO FINAL SEM DEPENDÊNCIAS
## ═══════════════════════════════════════════════════════════

const NUM_BELLS: int = 4
const CORRECT_SEQUENCE: Array[int] = [1, 3, 0, 2]

enum PuzzleState { UNSOLVED, VAMPIRE_SAW_CLUES, VAMPIRE_RECORDED, SOLVED }
var current_state: PuzzleState = PuzzleState.UNSOLVED
var player_sequence: Array[int] = []
var machine_playing: bool = false

@onready var bells_container: Node2D = Node2D.new()
@onready var sound_machine: Node2D = Node2D.new()
@onready var decor_root: Node2D = Node2D.new()
@onready var exit_door: Area2D = Area2D.new()
var feedback_label: Label = Label.new()

const BELL_COLORS: Array[Color] = [
	Color(0.6, 0.1, 0.1),
	Color(0.2, 0.5, 0.2),
	Color(0.1, 0.2, 0.6),
	Color(0.8, 0.7, 0.2)
]

const BELL_NOTES: Array[float] = [196.0, 293.66, 392.0, 523.25]

func _ready():
	add_to_group("room4")
	
	# Criar estrutura de nós manualmente para evitar erros de cena
	bells_container.name = "Bells"
	sound_machine.name = "SoundMachine"
	decor_root.name = "Decorations"
	exit_door.name = "ExitDoor"
	
	add_child(decor_root)
	add_child(bells_container)
	add_child(sound_machine)
	add_child(exit_door)
	
	_setup_gothic_room()
	_setup_bells()
	_setup_machine()
	_setup_door()
	_setup_ui()

	# Início seguro
	if _check_night():
		_start_night()
	else:
		_start_day()

func _setup_ui():
	var canvas = CanvasLayer.new()
	add_child(canvas)
	feedback_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_KEEP_WIDTH, 50)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 24)
	canvas.add_child(feedback_label)

func _setup_gothic_room():
	var floor = Polygon2D.new()
	floor.z_index = -10
	floor.color = Color(0.03, 0.03, 0.04)
	floor.polygon = PackedVector2Array([Vector2(-2000, -2000), Vector2(2000, -2000), Vector2(2000, 2000), Vector2(-2000, 2000)])
	decor_root.add_child(floor)

	var p1 = _create_pillar(Vector2(-700, 0), "PillarLeft")
	var p2 = _create_pillar(Vector2(700, 0), "PillarRight")
	decor_root.add_child(p1)
	decor_root.add_child(p2)
	decor_root.add_child(_create_broken_glass(Vector2(-600, -200)))

func _create_pillar(pos: Vector2, p_name: String) -> Node2D:
	var p = Node2D.new(); p.position = pos; p.name = p_name
	var b = Polygon2D.new(); b.color = Color(0.15, 0.15, 0.18)
	b.polygon = [Vector2(-40, -400), Vector2(40, -400), Vector2(50, 400), Vector2(-50, 400)]
	p.add_child(b)
	
	var r_node = Node2D.new(); r_node.name = "Runes"
	for i in range(3):
		var r = Label.new(); r.text = "ᛟ"; r.position = Vector2(-15, -200 + i * 150)
		r.modulate = Color(0.7, 0.3, 1.0, 0.0)
		r_node.add_child(r)
	p.add_child(r_node)
	return p

func _create_broken_glass(pos: Vector2) -> Node2D:
	var g = Node2D.new(); g.position = pos; g.name = "BrokenGlass"
	for i in range(4):
		var f = Node2D.new(); f.name = "Fragment_" + str(i+1); f.position = Vector2(i*40, 0)
		var s = Polygon2D.new(); s.name = "HiddenSymbol"; s.color = BELL_COLORS[i]; s.color.a = 0.0
		s.polygon = [Vector2(-15,-15), Vector2(15,-15), Vector2(15,15), Vector2(-15,15)]
		f.add_child(s); g.add_child(f)
	return g

func _setup_bells():
	var pos_list = [Vector2(-300, 200), Vector2(-100, 180), Vector2(100, 180), Vector2(300, 200)]
	for i in range(NUM_BELLS):
		var b = Node2D.new(); b.name = "Bell" + str(i); b.position = pos_list[i]
		var body = Polygon2D.new(); body.name = "Body"; body.color = BELL_COLORS[i].darkened(0.4)
		body.polygon = [Vector2(-15,-40), Vector2(15,-40), Vector2(35,30), Vector2(-35,30)]
		b.add_child(body)
		
		var area = Area2D.new(); area.input_pickable = true
		var shape = CollisionShape2D.new(); shape.shape = RectangleShape2D.new(); shape.shape.size = Vector2(80, 100)
		area.add_child(shape)
		
		var sc = GDScript.new(); sc.source_code = "extends Area2D\nfunc interact(_n): get_parent().get_parent().get_parent().ring_bell(get_parent())"
		sc.reload(); area.set_script(sc); b.add_child(area)
		bells_container.add_child(b)

func ring_bell(bell_node: Node2D):
	var idx = bell_node.name.replace("Bell", "").to_int()
	var tw = create_tween(); tw.tween_property(bell_node.get_node("Body"), "scale", Vector2(1.2, 0.8), 0.1)
	tw.tween_property(bell_node.get_node("Body"), "scale", Vector2(1.0, 1.0), 0.1)
	
	_play_sound(BELL_NOTES[idx])
	_on_bell_played(idx)

func _play_sound(f: float):
	var p = AudioStreamPlayer.new(); add_child(p)
	var s = AudioStreamWAV.new(); s.format = AudioStreamWAV.FORMAT_16_BITS; s.mix_rate = 44100
	var d = 0.4; var n = int(44100 * d); var b = PackedByteArray(); b.resize(n * 2)
	var freq = f * (0.6 if _check_night() else 1.4)
	for i in range(n):
		var t = float(i) / 44100.0
		var val = int(sin(t * freq * TAU) * exp(-t * 6.0) * 20000)
		b.encode_s16(i * 2, val)
	s.data = b; p.stream = s; p.play(); p.finished.connect(p.queue_free)

func _setup_machine():
	sound_machine.position = Vector2(0, 450)
	var base = Polygon2D.new(); base.color = Color(0.1, 0.1, 0.1); base.polygon = [Vector2(-100,-30), Vector2(100,-30), Vector2(90,30), Vector2(-90,30)]
	sound_machine.add_child(base)
	
	var btn_rec = _create_btn(Vector2(-40, 0), Color(0.7, 0.1, 0.1), "_on_record_pressed")
	var btn_play = _create_btn(Vector2(40, 0), Color(0.1, 0.7, 0.1), "_on_play_pressed")
	sound_machine.add_child(btn_rec); sound_machine.add_child(btn_play)

func _create_btn(pos: Vector2, c: Color, m: String) -> Node2D:
	var b = Node2D.new(); b.position = pos
	var p = Polygon2D.new(); p.color = c; p.polygon = _circle(20)
	b.add_child(p)
	var a = Area2D.new(); a.input_pickable = true; var s = CollisionShape2D.new(); s.shape = CircleShape2D.new(); s.shape.radius = 20; a.add_child(s)
	var sc = GDScript.new(); sc.source_code = "extends Area2D\nfunc interact(_n): get_parent().get_parent().get_parent()." + m + "()"
	sc.reload(); a.set_script(sc); b.add_child(a)
	return b

func _on_record_pressed():
	if not _check_night(): 
		_msg("A máquina precisa de sombras para gravar...")
		return
	current_state = PuzzleState.VAMPIRE_RECORDED
	_msg("🔴 Som guardado...")

func _on_play_pressed():
	if _check_night() or current_state < PuzzleState.VAMPIRE_RECORDED or machine_playing: return
	machine_playing = true
	for i in CORRECT_SEQUENCE:
		_play_sound(BELL_NOTES[i] * 1.5); await get_tree().create_timer(0.7).timeout
	machine_playing = false
	_msg("Ouve o eco da noite...")

func _on_bell_played(idx: int):
	if _check_night() or current_state != PuzzleState.VAMPIRE_RECORDED: return
	player_sequence.append(idx)
	if player_sequence[player_sequence.size()-1] != CORRECT_SEQUENCE[player_sequence.size()-1]:
		player_sequence.clear(); _msg("❌ Errado...")
	elif player_sequence.size() == CORRECT_SEQUENCE.size():
		current_state = PuzzleState.SOLVED; _msg("✨ Porta aberta!"); exit_door.get_node("Visual").color = Color(0,1,0)

func _setup_door():
	exit_door.position = Vector2(800, 0)
	var v = Polygon2D.new(); v.name = "Visual"; v.color = Color(0.2, 0.1, 0.1); v.polygon = [Vector2(-30,-60), Vector2(30,-60), Vector2(30,60), Vector2(-30,60)]
	exit_door.add_child(v)

func _check_night() -> bool:
	if has_node("/root/DayNightSystem"): return get_node("/root/DayNightSystem").is_night
	return false

func _start_night():
	current_state = PuzzleState.VAMPIRE_SAW_CLUES
	_msg("🦇 A visão vampírica revela símbolos...")
	_toggle_hints(true)

func _start_day():
	_toggle_hints(false)
	_msg("☀️ O dia esconde os segredos.")

func _toggle_hints(show: bool):
	var a = 0.8 if show else 0.0
	if has_node("Decorations/PillarLeft"):
		for r in get_node("Decorations/PillarLeft/Runes").get_children(): r.modulate.a = a
	if has_node("Decorations/BrokenGlass"):
		for i in range(1, 5): get_node("Decorations/BrokenGlass/Fragment_" + str(i) + "/HiddenSymbol").color.a = a

func _msg(t: String):
	feedback_label.text = t; feedback_label.modulate.a = 1.0
	var tw = create_tween(); tw.tween_property(feedback_label, "modulate:a", 0.0, 3.0).set_delay(1.5)

func _circle(r: float) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in range(16): pts.append(Vector2(cos(i*TAU/16)*r, sin(i*TAU/16)*r))
	return pts
