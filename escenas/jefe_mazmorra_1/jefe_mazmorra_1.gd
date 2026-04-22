extends CharacterBody2D

class Projectile extends Area2D:
	var velocity := Vector2.ZERO
	var lifetime := 2.0
	var damage := 1
	var visual_radius := 6.0
	var visual_color := Color(1.0, 0.5, 0.1, 1.0)
	var z: int = 10
	var frames: Array[Texture2D] = []
	var frames_fps: float = 12.0
	var _dead := false

	func _ready() -> void:
		monitoring = true
		set_physics_process(true)
		z_index = z
		if frames.size() > 0:
			var sprite := AnimatedSprite2D.new()
			var sf := SpriteFrames.new()
			sf.add_animation("default")
			sf.set_animation_speed("default", frames_fps)
			sf.set_animation_loop("default", true)
			for t in frames:
				if t == null:
					continue
				sf.add_frame("default", t)
			sprite.sprite_frames = sf
			sprite.play("default")
			var tex := frames[0]
			if tex != null:
				var s := tex.get_size()
				var denom := maxf(s.x, s.y)
				if denom > 0.0:
					var scale_factor := (visual_radius * 2.0) / denom
					sprite.scale = Vector2.ONE * scale_factor
			add_child(sprite)
		else:
			queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, visual_radius, visual_color)

	func _physics_process(delta: float) -> void:
		if _dead:
			return
		global_position += velocity * delta
		lifetime -= delta
		if lifetime <= 0.0:
			queue_free()

	func _on_body_entered(body: Node) -> void:
		if _dead:
			return
		if body != null and body.is_in_group("Skerney"):
			_dead = true
			if body.has_method("die"):
				body.die()
			queue_free()


enum BossState { CHASE, MELEE, RETURN, FIRE, HIT, RESURRECT, DEAD }
enum FirePattern { AIMED_TRIPLE, CROSS_4, CIRCLE_8 }

@export var max_hp: int = 10
@export var phase2_hp_threshold: int = 10
@export var phase1_mult: float = 0.65
@export var phase2_mult: float = 1.0
@export var phase1_tint: Color = Color(1, 1, 1, 1)
@export var phase2_tint: Color = Color(1, 0.65, 0.65, 1)
@export var phase2_intro_shake_duration: float = 0.75
@export var phase2_intro_shake_strength: float = 1.4
@export var phase2_intro_overlay_hold: float = 0.65
@export var phase2_intro_overlay_alpha: float = 0.35

@export var chase_speed: float = 42.0
@export var chase_acceleration: float = 240.0
@export var chase_friction: float = 280.0
@export var chase_duration: float = 2.2
@export var attack_trigger_range: float = 44.0
@export var attack_range: float = 30.0
@export var stop_when_close_range: float = 34.0
@export var melees_before_fire: int = 3
@export var melee_cooldown: float = 1.0
@export var melee_active_start_frame: int = 9
@export var melee_active_end_frame: int = 12
@export var sword_reach: float = 60.0
@export var sword_forward_dot: float = 0.25
@export var melee_damage: int = 1
@export var melee_hitbox_y: float = 42.5
@export var melee_hitbox_forward_offset: float = 52.0
@export var contact_damage: int = 1
@export var contact_damage_range: float = 12.0
@export var contact_damage_cooldown: float = 0.65
@export var hit_stun_time: float = 0.22
@export var hit_invuln_time: float = 0.18
@export var knockback_speed: float = 70.0
@export var knockback_time: float = 0.08

@export var return_speed: float = 60.0
@export var return_acceleration: float = 320.0
@export var return_stop_distance: float = 6.0

@export var fire_duration: float = 3.6
@export var fire_cancel_hits: int = 3
@export var volley_interval: float = 0.55
@export var fire_release_frame: int = 2
@export var projectile_z_index: int = 10
@export var projectile_speed: float = 96.0
@export var projectile_radius: float = 6.0
@export var projectile_lifetime: float = 2.2
@export var projectile_damage: int = 1
@export var spread_angle: float = 0.28
@export var fireball_spawn_offset: Vector2 = Vector2(-18, 22)
@export var fireball_frames: Array[Texture2D] = []
@export var fireball_frames_fps: float = 12.0

@export var arena_center: Vector2 = Vector2.ZERO
@export var arena_radius: float = 120.0
@export var enemy_id: String = "jefe_mazmorra_1"

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var melee_hitbox: Area2D = $MeleeHitbox
@onready var body_collision: CollisionShape2D = $CollisionShape2D

var hp: int = 20
var _state := BossState.CHASE
var _prev_state := BossState.CHASE
var _target: Node2D = null
var _facing_right := false

var _state_time := 0.0
var _melee_cd := 0.0
var _hit_invuln := 0.0
var _fire_hits := 0
var _volley_timer := 0.0
var _pattern_index := 0
var _melee_phase := 0
var _melee_timer := 0.0
var _phase2_started := false
var _knockback_left := 0.0
var _knockback_vel := Vector2.ZERO
var _res_phase := 0
var _fire_pending := false
var _sword_hit_ids := {}
var _melees_since_fire := 0
var _contact_cd := 0.0
var _phase2_intro_played := false
var _shake_tween: Tween = null
var _shake_cam: Camera2D = null
var _shake_base: Vector2 = Vector2.ZERO
var _shake_strength: float = 0.0

func _enemy_key() -> String:
	if enemy_id != "":
		return enemy_id
	return str(get_tree().current_scene.scene_file_path) + ":" + str(get_path())


func _ready() -> void:
	if ControladorPartida.temp_data.get("killed_enemies", {}).get(_enemy_key(), false):
		queue_free()
		return
	randomize()
	hp = max_hp
	if arena_center == Vector2.ZERO:
		arena_center = global_position
	melee_hitbox.monitoring = false
	melee_hitbox.body_entered.connect(_on_melee_hitbox_body_entered)
	if anim != null and anim.sprite_frames != null and anim.sprite_frames.has_animation("hit"):
		anim.sprite_frames.set_animation_loop("hit", false)
	if anim != null:
		anim.frame_changed.connect(_on_anim_frame_changed)
	_set_state(BossState.CHASE)


func _physics_process(delta: float) -> void:
	if _state == BossState.DEAD:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_update_target()

	if _knockback_left > 0.0:
		_knockback_left = maxf(0.0, _knockback_left - delta)
		velocity = _knockback_vel
		_apply_arena_constraint(delta)
		_update_anim()
		move_and_slide()
		return

	if _melee_cd > 0.0:
		_melee_cd = maxf(0.0, _melee_cd - delta)
	if _hit_invuln > 0.0:
		_hit_invuln = maxf(0.0, _hit_invuln - delta)

	match _state:
		BossState.CHASE:
			_tick_chase(delta)
		BossState.MELEE:
			_tick_melee(delta)
		BossState.RETURN:
			_tick_return(delta)
		BossState.FIRE:
			_tick_fire(delta)
		BossState.HIT:
			_tick_hit(delta)
		BossState.RESURRECT:
			_tick_resurrect(delta)

	_apply_arena_constraint(delta)
	_update_anim()
	move_and_slide()
	_tick_contact_damage(delta)


func _is_phase2() -> bool:
	return _phase2_started


func _difficulty_mult() -> float:
	return phase2_mult if _is_phase2() else phase1_mult


func _update_target() -> void:
	if _target == null or not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("Skerney") as Node2D


func _set_state(next_state: BossState) -> void:
	_state = next_state
	_state_time = 0.0
	match _state:
		BossState.CHASE:
			melee_hitbox.monitoring = false
			_update_melee_hitbox_position(false)
			_state_time = chase_duration / _difficulty_mult()
		BossState.MELEE:
			melee_hitbox.monitoring = false
			_update_melee_hitbox_position(false)
			_melee_phase = 0
			_melee_timer = 0.0
			_sword_hit_ids.clear()
			_state_time = _anim_seconds("attack")
			_play_anim_no_loop("attack")
			if _state_time <= 0.0:
				_state_time = 0.45
		BossState.RETURN:
			melee_hitbox.monitoring = false
			_update_melee_hitbox_position(false)
		BossState.FIRE:
			melee_hitbox.monitoring = false
			_update_melee_hitbox_position(false)
			_fire_hits = 0
			_volley_timer = 0.0
			_pattern_index = 0
			_melees_since_fire = 0
			_state_time = fire_duration / _difficulty_mult()
			_fire_pending = true
			_play_anim("attack")
		BossState.HIT:
			melee_hitbox.monitoring = false
			_update_melee_hitbox_position(false)
			_state_time = hit_stun_time / _difficulty_mult()
			_play_anim("hit")
		BossState.RESURRECT:
			melee_hitbox.monitoring = false
			_update_melee_hitbox_position(false)
			_res_phase = 0
			_hit_invuln = 999.0
			_state_time = _anim_seconds("die")
			_play_anim_no_loop("die")
			if _phase2_started and not _phase2_intro_played:
				_phase2_intro_played = true
				_play_phase2_intro()
			if _state_time <= 0.0:
				_state_time = 0.6
		BossState.DEAD:
			melee_hitbox.monitoring = false
			_update_melee_hitbox_position(false)


func _tick_chase(delta: float) -> void:
	var mult := _difficulty_mult()
	_state_time -= delta

	var desired := Vector2.ZERO
	if _target != null and is_instance_valid(_target):
		var to_player := _target.global_position - global_position
		var dist := to_player.length()
		if to_player.length() > 0.001:
			_facing_right = to_player.x >= 0.0
			if dist <= stop_when_close_range:
				desired = Vector2.ZERO
			else:
				desired = to_player.normalized() * (chase_speed * mult)

		if _melee_cd <= 0.0 and dist <= attack_trigger_range:
			_set_state(BossState.MELEE)
			return

	velocity = velocity.move_toward(desired, chase_acceleration * mult * delta)
	if desired == Vector2.ZERO:
		velocity = velocity.move_toward(Vector2.ZERO, chase_friction * delta)

	if _state_time <= 0.0:
		_set_state(BossState.RETURN)


func _tick_melee(delta: float) -> void:
	var mult := _difficulty_mult()
	velocity = velocity.move_toward(Vector2.ZERO, chase_friction * delta)
	_state_time -= delta
	_update_melee_hitbox_position(melee_hitbox.monitoring)
	if melee_hitbox.monitoring:
		for body in melee_hitbox.get_overlapping_bodies():
			_try_sword_damage(body)
	if _state_time <= 0.0:
		melee_hitbox.monitoring = false
		_update_melee_hitbox_position(false)
		_melee_cd = melee_cooldown / mult
		_melees_since_fire += 1
		if melees_before_fire > 0 and _melees_since_fire >= melees_before_fire:
			_set_state(BossState.RETURN)
		else:
			_set_state(BossState.CHASE)


func _tick_return(delta: float) -> void:
	var mult := _difficulty_mult()
	var to_center := arena_center - global_position
	var dist := to_center.length()
	if dist <= return_stop_distance:
		velocity = velocity.move_toward(Vector2.ZERO, return_acceleration * delta)
		_set_state(BossState.FIRE)
		return

	var desired := to_center.normalized() * (return_speed * mult)
	_facing_right = desired.x > 0.5
	velocity = velocity.move_toward(desired, return_acceleration * mult * delta)


func _tick_fire(delta: float) -> void:
	var mult := _difficulty_mult()
	_state_time -= delta
	velocity = velocity.move_toward(Vector2.ZERO, chase_friction * delta)

	_volley_timer -= delta
	if _volley_timer <= 0.0:
		_volley_timer = volley_interval / mult
		_fire_pending = true
		_play_anim("attack")

	if _fire_hits >= fire_cancel_hits:
		_set_state(BossState.CHASE)
		return

	if _state_time <= 0.0:
		_set_state(BossState.CHASE)


func _tick_hit(delta: float) -> void:
	var mult := _difficulty_mult()
	_state_time -= delta
	velocity = velocity.move_toward(Vector2.ZERO, chase_friction * mult * delta)
	if _state_time <= 0.0:
		if _prev_state == BossState.MELEE:
			_set_state(BossState.CHASE)
			return
		if _prev_state == BossState.FIRE and _fire_hits >= fire_cancel_hits:
			_set_state(BossState.CHASE)
			return
		_set_state(_prev_state)


func _tick_resurrect(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, chase_friction * delta)
	_state_time -= delta
	if _state_time > 0.0:
		return
	if _res_phase == 0:
		_res_phase = 1
		if anim != null and anim.sprite_frames != null and anim.sprite_frames.has_animation("resurrect"):
			_state_time = _anim_seconds("resurrect")
			_play_anim_no_loop("resurrect")
			if _state_time <= 0.0:
				_state_time = 0.6
			return
		_hit_invuln = hit_invuln_time
		_set_state(BossState.CHASE)
		return
	_hit_invuln = hit_invuln_time
	_set_state(BossState.CHASE)


func _apply_arena_constraint(delta: float) -> void:
	if arena_radius <= 0.0:
		return
	var dist := global_position.distance_to(arena_center)
	if dist <= arena_radius:
		return
	var dir := (arena_center - global_position).normalized()
	velocity = velocity.move_toward(dir * return_speed, return_acceleration * delta)


func _update_anim() -> void:
	if anim == null or anim.sprite_frames == null:
		return
	anim.flip_h = _facing_right
	anim.modulate = phase2_tint if _phase2_started else phase1_tint
	if _state == BossState.DEAD:
		return
	if _state == BossState.MELEE or _state == BossState.FIRE:
		if anim.animation != "attack":
			_play_anim("attack")
		return
	if _state == BossState.HIT or _state == BossState.RESURRECT:
		return
	if velocity.length() > 3.0:
		if anim.sprite_frames.has_animation("walk_left"):
			if anim.animation != "walk_left":
				_play_anim("walk_left")
	else:
		if anim.sprite_frames.has_animation("idle"):
			if anim.animation != "idle":
				_play_anim("idle")

func _anim_play_walk() -> void:
	if anim == null or anim.sprite_frames == null:
		return
	if anim.sprite_frames.has_animation("walk_left"):
		anim.play("walk_left")

func _play_anim_no_loop(name: String) -> void:
	if anim == null or anim.sprite_frames == null:
		return
	if anim.sprite_frames.has_animation(name):
		anim.sprite_frames.set_animation_loop(name, false)
		anim.play(name)

func _anim_seconds(anim_name: String) -> float:
	if anim == null or anim.sprite_frames == null:
		return 0.0
	if not anim.sprite_frames.has_animation(anim_name):
		return 0.0
	var frames := anim.sprite_frames.get_frame_count(anim_name)
	var fps := anim.sprite_frames.get_animation_speed(anim_name)
	if fps <= 0.0:
		fps = 10.0
	if frames <= 0:
		return 0.0
	return float(frames - 1) / fps


func _play_anim(name: String) -> void:
	if anim == null or anim.sprite_frames == null:
		return
	if anim.sprite_frames.has_animation(name):
		anim.play(name)


func _fire_volley() -> void:
	var pattern := FirePattern.AIMED_TRIPLE
	match _pattern_index % 3:
		0:
			pattern = FirePattern.AIMED_TRIPLE
		1:
			pattern = FirePattern.CROSS_4
		2:
			pattern = FirePattern.CIRCLE_8
	_pattern_index += 1

	match pattern:
		FirePattern.AIMED_TRIPLE:
			_fire_aimed_triple()
		FirePattern.CROSS_4:
			_fire_cross()
		FirePattern.CIRCLE_8:
			_fire_circle8()


func _fire_aimed_triple() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var base := (_target.global_position - global_position).normalized()
	if base == Vector2.ZERO:
		base = Vector2.LEFT if not _facing_right else Vector2.RIGHT
	_spawn_fireball(base)
	_spawn_fireball(base.rotated(spread_angle))
	_spawn_fireball(base.rotated(-spread_angle))


func _fire_cross() -> void:
	_spawn_fireball(Vector2.UP)
	_spawn_fireball(Vector2.DOWN)
	_spawn_fireball(Vector2.LEFT)
	_spawn_fireball(Vector2.RIGHT)


func _fire_circle8() -> void:
	for i in range(8):
		var a := float(i) * (TAU / 8.0)
		_spawn_fireball(Vector2.RIGHT.rotated(a))


func _spawn_fireball(dir: Vector2) -> void:
	var p := Projectile.new()
	p.damage = projectile_damage
	p.lifetime = projectile_lifetime
	p.velocity = dir.normalized() * (projectile_speed * _difficulty_mult())
	p.visual_radius = projectile_radius
	p.z = projectile_z_index
	p.frames = fireball_frames
	p.frames_fps = fireball_frames_fps
	p.collision_layer = 2
	p.collision_mask = 4
	p.body_entered.connect(p._on_body_entered)

	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = projectile_radius
	cs.shape = shape
	p.add_child(cs)

	var offset := fireball_spawn_offset
	if _facing_right:
		offset.x = -offset.x
	p.global_position = global_position + offset
	get_tree().current_scene.add_child(p)


func hit_by(attacker_pos: Vector2, damage: int = 1) -> void:
	if _state == BossState.DEAD:
		return
	if _state == BossState.RESURRECT:
		return
	if _hit_invuln > 0.0:
		return
	var dir := (global_position - attacker_pos)
	if dir.length() < 0.001:
		dir = Vector2.RIGHT
	_knockback_vel = dir.normalized() * knockback_speed
	_knockback_left = knockback_time
	_facing_right = _knockback_vel.x > 0.5
	take_damage(damage)


func _on_melee_hitbox_body_entered(body: Node) -> void:
	if _state != BossState.MELEE:
		return
	_try_sword_damage(body)


func _on_anim_frame_changed() -> void:
	if anim == null:
		return
	if _state == BossState.MELEE and anim.animation == "attack":
		var active := anim.frame >= melee_active_start_frame and anim.frame <= melee_active_end_frame
		melee_hitbox.monitoring = active
		_update_melee_hitbox_position(active)
		return
	if _state == BossState.FIRE and anim.animation == "attack":
		if _fire_pending and anim.frame >= fire_release_frame:
			_fire_pending = false
			_fire_volley()


func _update_melee_hitbox_position(active: bool) -> void:
	if melee_hitbox == null:
		return
	var x := 0.0
	if active:
		x = melee_hitbox_forward_offset if _facing_right else -melee_hitbox_forward_offset
	melee_hitbox.position = Vector2(x, melee_hitbox_y)
	melee_hitbox.visible = active


func _tick_contact_damage(delta: float) -> void:
	if contact_damage <= 0:
		return
	if _contact_cd > 0.0:
		_contact_cd = maxf(0.0, _contact_cd - delta)
		return
	if _state == BossState.DEAD or _state == BossState.RESURRECT:
		return
	if body_collision == null or body_collision.shape == null:
		return
	var space := get_world_2d().direct_space_state
	if space == null:
		return
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = body_collision.shape
	q.transform = body_collision.global_transform
	q.collision_mask = 4
	q.collide_with_areas = false
	q.collide_with_bodies = true
	q.exclude = [get_rid()]
	var hits = space.intersect_shape(q, 4)
	if hits.is_empty():
		return
	for h in hits:
		var collider = h.get("collider")
		if collider == null or not (collider is Node):
			continue
		var n := collider as Node
		if not n.is_in_group("Skerney"):
			continue
		_contact_cd = contact_damage_cooldown / _difficulty_mult()
		if n.has_method("hit_by"):
			n.hit_by(global_position, contact_damage)
		elif n.has_method("take_damage"):
			n.take_damage(contact_damage)
		elif n.has_method("die"):
			n.die()
		return


func _try_sword_damage(body: Node) -> void:
	if body == null:
		return
	if not body.is_in_group("Skerney"):
		return
	var id := body.get_instance_id()
	if _sword_hit_ids.has(id):
		return
	if not _is_valid_sword_contact(body):
		return
	_sword_hit_ids[id] = true
	if body.has_method("hit_by"):
		body.hit_by(global_position, melee_damage)
	elif body.has_method("take_damage"):
		body.take_damage(melee_damage)
	elif body.has_method("die"):
		body.die()


func _is_valid_sword_contact(body: Node) -> bool:
	if not (body is Node2D):
		return false
	var to_target := (body as Node2D).global_position - global_position
	if to_target.length() > sword_reach:
		return false
	var facing := Vector2.RIGHT if _facing_right else Vector2.LEFT
	var dir := to_target.normalized()
	return facing.dot(dir) >= sword_forward_dot


func take_damage(amount: int = 1) -> void:
	if _state == BossState.DEAD:
		return
	if _hit_invuln > 0.0:
		return
	hp -= amount
	_hit_invuln = hit_invuln_time

	if _state == BossState.FIRE:
		_fire_hits += 1
		if _fire_hits >= fire_cancel_hits:
			_set_state(BossState.CHASE)

	if hp <= 0:
		if not _phase2_started:
			_phase2_started = true
			hp = maxi(1, phase2_hp_threshold)
			_set_state(BossState.RESURRECT)
			return
		die()
		return

	_prev_state = _state
	if _prev_state == BossState.MELEE:
		_prev_state = BossState.CHASE
	_set_state(BossState.HIT)




func die() -> void:
	if _state == BossState.DEAD:
		return
	_state = BossState.DEAD
	if not ControladorPartida.temp_data.has("killed_enemies"):
		ControladorPartida.temp_data["killed_enemies"] = {}
	ControladorPartida.temp_data["killed_enemies"][_enemy_key()] = true
	melee_hitbox.monitoring = false
	collision_layer = 0
	collision_mask = 0
	if anim != null and anim.sprite_frames != null and anim.sprite_frames.has_animation("die"):
		anim.sprite_frames.set_animation_loop("die", false)
		anim.play("die")
		var frames := anim.sprite_frames.get_frame_count("die")
		var fps := anim.sprite_frames.get_animation_speed("die")
		if fps <= 0.0:
			fps = 10.0
		if frames > 0:
			var seconds := float(frames - 1) / fps
			await get_tree().create_timer(seconds).timeout
	var scene := get_tree().current_scene
	if scene != null:
		var chest := scene.get_node_or_null("ChestSalida")
		if chest != null and chest.has_method("activate"):
			chest.activate()
	queue_free()


func _play_phase2_intro() -> void:
	if Engine.has_singleton("HUD"):
		HUD.mostrar_peligro(phase2_intro_overlay_hold, phase2_intro_overlay_alpha)
	_start_camera_shake(phase2_intro_shake_duration, phase2_intro_shake_strength)


func _get_player_camera() -> Camera2D:
	var player := get_tree().get_first_node_in_group("Skerney")
	if player == null or not is_instance_valid(player):
		return null
	var cam := (player as Node).get_node_or_null("Camera2D")
	if cam is Camera2D:
		return cam as Camera2D
	for child in (player as Node).get_children():
		if child is Camera2D:
			return child as Camera2D
	return null


func _start_camera_shake(duration: float, strength: float) -> void:
	var cam := _get_player_camera()
	if cam == null:
		return
	if _shake_tween:
		_shake_tween.kill()
		_shake_tween = null
	_shake_cam = cam
	_shake_base = cam.position
	_shake_strength = strength

	_shake_tween = create_tween()
	_shake_tween.tween_method(Callable(self, "_shake_step"), 0.0, 1.0, duration)
	_shake_tween.finished.connect(func():
		if is_instance_valid(_shake_cam):
			_shake_cam.position = _shake_base
		_shake_cam = null
		_shake_tween = null
	)


func _shake_step(t: float) -> void:
	if _shake_cam == null or not is_instance_valid(_shake_cam):
		return
	var a := (1.0 - clampf(t, 0.0, 1.0)) * _shake_strength
	_shake_cam.position = _shake_base + Vector2(randf_range(-a, a), randf_range(-a, a))
