extends CharacterBody2D

@export var speed: float = 60.0
@export var anim: AnimatedSprite2D
@export var audio_attack: AudioStreamPlayer2D

var input_vector := Vector2.ZERO
var last_direction := "down"
var keys := {}
var interactable: Node = null
var can_move := true
var is_dead := false

@onready var attack_hitbox: Area2D = $AttackHitbox

func die() -> void:
	if is_dead:
		return
	is_dead = true

	can_move = false
	velocity = Vector2.ZERO
	input_vector = Vector2.ZERO
	var state_machine := get_node_or_null("StateMachine")
	if state_machine:
		state_machine.set_process(false)
		state_machine.set_physics_process(false)

	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("die"):
		anim.sprite_frames.set_animation_loop("die", false)
		anim.play("die")
		var frames := anim.sprite_frames.get_frame_count("die")
		var fps := anim.sprite_frames.get_animation_speed("die")
		if fps <= 0.0:
			fps = 10.0
		if frames > 0:
			var seconds := float(frames - 1) / fps
			await get_tree().create_timer(seconds).timeout
			anim.frame = frames - 1
			anim.stop()

	HUD.mostrar_menu_muerte()


func _enter_tree():
	add_to_group("Skerney")


func _ready():
	# Cargar llaves persistentes
	if ControladorPartida.temp_data.has("keys"):
		keys = ControladorPartida.temp_data["keys"]

	if is_instance_valid(attack_hitbox):
		attack_hitbox.monitoring = false


func _physics_process(delta):
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_read_input()
	move_and_slide()

	if Input.is_action_just_pressed("action_button"):
		if interactable:
			interactable.interact()
		else:
			attack()


func _read_input():
	input_vector = Vector2.ZERO
	var x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = Vector2(x, y)

	if input_vector.length() > 0.1:
		input_vector = input_vector.normalized()
		if abs(input_vector.x) > abs(input_vector.y):
			if input_vector.x > 0:
				last_direction = "right"
				anim.flip_h = true
			else:
				last_direction = "left"
				anim.flip_h = false
		else:
			if input_vector.y < 0:
				last_direction = "up"
			else:
				last_direction = "down"
		_update_interaction_detector()

	velocity = input_vector * speed


func attack():
	if audio_attack:
		audio_attack.play()


var _attack_hit_ids := {}

func begin_attack() -> void:
	_attack_hit_ids.clear()


func end_attack() -> void:
	if is_instance_valid(attack_hitbox):
		attack_hitbox.monitoring = false
	attack_hitbox.position = Vector2.ZERO
	input_vector = Vector2.ZERO
	velocity = Vector2.ZERO


func set_attack_hitbox_direction(direction: String) -> void:
	var offset := Vector2.ZERO
	match direction:
		"up":
			offset = Vector2(0, -18)
		"down":
			offset = Vector2(0, 18)
		"left":
			offset = Vector2(-18, 0)
		"right":
			offset = Vector2(18, 0)
	attack_hitbox.position = offset


func set_attack_hitbox_active(active: bool) -> void:
	if is_instance_valid(attack_hitbox):
		attack_hitbox.monitoring = active


func try_attack_hit(damage: int = 1) -> void:
	if not is_instance_valid(attack_hitbox):
		return
	for body in attack_hitbox.get_overlapping_bodies():
		var id := body.get_instance_id()
		if _attack_hit_ids.has(id):
			continue
		_attack_hit_ids[id] = true
		if body.has_method("take_damage"):
			body.take_damage(damage)
		elif body.has_method("die"):
			body.die()


func _update_interaction_detector():
	var offset := Vector2.ZERO
	match last_direction:
		"up":
			offset = Vector2(0, -12)
		"down":
			offset = Vector2(0, 12)
		"left":
			offset = Vector2(-12, 0)
		"right":
			offset = Vector2(12, 0)
	$InteractionDetector.position = offset


func _on_InteractionDetector_area_entered(area):
	if area.has_method("interact"):
		interactable = area


func _on_InteractionDetector_area_exited(area):
	if interactable == area:
		interactable = null
