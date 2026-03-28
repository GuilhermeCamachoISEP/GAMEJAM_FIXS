extends Node2D

const FACE_UP := 0
const FACE_RIGHT := 1
const FACE_DOWN := 2
const FACE_LEFT := 3

var _night: bool = true
var _facing: int = FACE_DOWN
var _is_moving: bool = false 

@onready var vampire_sprite: AnimatedSprite2D = $VampireSprite
@onready var human_sprite: AnimatedSprite2D = $HumanSprite

func _ready() -> void:
	_night = DayNightSystem.is_night
	DayNightSystem.phase_changed.connect(_on_phase)
	_update_visibility()

func _on_phase(is_night: bool) -> void:
	_night = is_night
	_update_visibility()

func _update_visibility() -> void:
	if _night:
		vampire_sprite.visible = true
		human_sprite.visible = false
	else:
		vampire_sprite.visible = false
		human_sprite.visible = true
	_update_animation()

func set_facing(face: int) -> void:
	if _facing == face:
		return
	_facing = face
	_update_animation()

func set_moving(moving: bool) -> void:
	if _is_moving == moving:
		return
	_is_moving = moving
	_update_animation()

func _update_animation() -> void:
	var anim_name = "walk" if _is_moving else "idle"
	var dir_name = "_down"
	
	match _facing:
		FACE_DOWN:
			dir_name = "_down"
		FACE_UP:
			dir_name = "_up"
		FACE_RIGHT:
			dir_name = "_right"
		FACE_LEFT:
			dir_name = "_left"
			
	var final_anim = anim_name + dir_name
	
	# ISTO AJUDA A DESCOBRIR O ERRO! Lê o que aparece na consola quando andas.
	print("A tentar tocar: ", final_anim)
	
	vampire_sprite.play(final_anim)
	human_sprite.play(final_anim)
