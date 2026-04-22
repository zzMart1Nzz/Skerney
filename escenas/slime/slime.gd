extends CharacterBody2D

@export var speed: float = 18.0
@export var acceleration: float = 120.0
@export var chase_range: float = 180.0
@export var stop_distance: float = 10.0
@export var anim: AnimatedSprite2D
@export var hp: int = 3
@export var knockback_speed: float = 48.0
@export var knockback_time: float = 0.08
@export var enemy_id: String = ""

var _can_kill := true
var _dead := false
var _target: Node2D = null
var _knockback_vel := Vector2.ZERO
var _knockback_left := 0.0

@onready var detect_radius: Area2D = $DetectRadius
@onready var hitbox: Area2D = $Hitbox

func _enemy_key() -> String:
	if enemy_id != "":
		return enemy_id
	return str(get_tree().current_scene.scene_file_path) + ":" + str(get_path())

func _ready() -> void:
	if ControladorPartida.temp_data.get("killed_enemies", {}).get(_enemy_key(), false):
		queue_free()
		return
	if is_instance_valid(detect_radius):
		var shape_node := detect_radius.get_node_or_null("CollisionShape2D")
		if shape_node and shape_node.shape is CircleShape2D:
			if shape_node is Node2D:
				(shape_node as Node2D).scale = Vector2.ONE
			(shape_node.shape as CircleShape2D).radius = chase_range
	if is_instance_valid(hitbox):
		hitbox.monitoring = true

	if anim and anim.sprite_frames:
		if anim.sprite_frames.has_animation("idle"):
			anim.play("idle")
		elif anim.sprite_frames.has_animation("walk"):
			anim.play("walk")
			anim.stop()
			anim.frame = 0

func _physics_process(delta: float) -> void:
	if _dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if _knockback_left > 0.0:
		_knockback_left = maxf(0.0, _knockback_left - delta)
		velocity = _knockback_vel
		move_and_slide()
		return

	var player := _target
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Skerney") as Node2D
	if player == null:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		move_and_slide()
		return

	var to_player := player.global_position - global_position
	var dist := to_player.length()

	var desired := Vector2.ZERO
	if dist <= chase_range and dist > stop_distance:
		desired = to_player.normalized() * speed

	velocity = velocity.move_toward(desired, acceleration * delta)
	move_and_slide()

	if _can_kill and is_instance_valid(hitbox):
		for body in hitbox.get_overlapping_bodies():
			if body.is_in_group("Skerney"):
				_on_Hitbox_body_entered(body)
				break

	if _can_kill:
		var count := get_slide_collision_count()
		for i in range(count):
			var col := get_slide_collision(i)
			var collider := col.get_collider()
			if collider != null and collider is Node and (collider as Node).is_in_group("Skerney"):
				_on_Hitbox_body_entered(collider as Node)
				break

	if anim:
		if velocity.length() > 1.0:
			if anim.sprite_frames and anim.sprite_frames.has_animation("walk"):
				if anim.animation != "walk":
					anim.play("walk")
		else:
			if anim.sprite_frames and anim.sprite_frames.has_animation("idle"):
				if anim.animation != "idle":
					anim.play("idle")
			else:
				if anim.animation == "walk":
					anim.stop()
					anim.frame = 0
				else:
					anim.stop()

func _on_Hitbox_body_entered(body: Node) -> void:
	if not _can_kill:
		return
	if _dead:
		return
	if body.is_in_group("Skerney"):
		_can_kill = false

		if body.has_method("die"):
			body.die()
			return

		FadeLayer.fade_out_and_call(func():
			if ControladorPartida.current_slot != 0 and ControladorPartida.slot_exists(ControladorPartida.current_slot):
				ControladorPartida.load_game(ControladorPartida.current_slot)
			else:
				get_tree().reload_current_scene()
		)


func take_damage(amount: int = 1) -> void:
	if _dead:
		return
	hp -= amount
	if hp <= 0:
		die()


func hit_by(attacker_pos: Vector2, damage: int = 1) -> void:
	if _dead:
		return
	var dir := (global_position - attacker_pos)
	if dir.length() < 0.001:
		dir = Vector2.RIGHT
	_knockback_vel = dir.normalized() * knockback_speed
	_knockback_left = knockback_time
	take_damage(damage)


func die() -> void:
	if _dead:
		return
	_dead = true
	_can_kill = false
	if not ControladorPartida.temp_data.has("killed_enemies"):
		ControladorPartida.temp_data["killed_enemies"] = {}
	ControladorPartida.temp_data["killed_enemies"][_enemy_key()] = true
	velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	var hitbox_node := get_node_or_null("Hitbox")
	if hitbox_node:
		hitbox_node.set_deferred("monitoring", false)
		hitbox_node.set_deferred("collision_layer", 0)
		hitbox_node.set_deferred("collision_mask", 0)
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("die"):
		anim.sprite_frames.set_animation_loop("die", false)
		anim.play("die")
		var frames := anim.sprite_frames.get_frame_count("die")
		if frames > 0:
			var fps := anim.sprite_frames.get_animation_speed("die")
			if fps <= 0.0:
				fps = 10.0
			var seconds := float(frames - 1) / fps
			await get_tree().create_timer(seconds).timeout
			anim.frame = frames - 1
			anim.stop()
		await get_tree().process_frame
	queue_free()


func _on_DetectRadius_body_entered(body: Node) -> void:
	if _dead:
		return
	if body.is_in_group("Skerney"):
		_target = body as Node2D


func _on_DetectRadius_body_exited(body: Node) -> void:
	if _target == body:
		_target = null
