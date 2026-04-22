extends Area2D

@export var next_scene: String
@export var required_key: String = ""
@export var door_id: String = ""
@export var target_door_id: String = ""
@export var starts_open: bool = false
@export var close_after_player_enters: bool = false

@export var door_edge_offset: float = 8.0
@export var enter_distance: float = 16.0
@export var enter_duration: float = 0.9
@export var exit_distance: float = 24.0
@export var exit_duration: float = 1.0

@export var puzzle_id: String = ""
@export var puzzle_is_correct: bool = false
@export var puzzle_fail_color: Color = Color(1.0, 0.25, 0.25, 1.0)
@export var puzzle_choice_key: String = ""
@export var puzzle_correct_stage: int = -1
@export var puzzle_total_stages: int = 3
@export var puzzle_loop_exit_door_id: String = "puzzle_to_pasillo"
@export var puzzle_loop_exit_entry_direction: String = "from_down"

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var solid_collision: CollisionShape2D = $StaticBody2D/CollisionShape2D
@onready var entry_detector: Area2D = $EntryDetector
@onready var spawn_point: Marker2D = $SpawnPoint

var opened: bool = false
var recently_loaded: bool = false
var is_transitioning: bool = false


func _ready():
	# Asegurar que este nodo está en el grupo Door
	add_to_group("Door")

	if door_id == "":
		door_id = name

	# Evitar activación inmediata al cargar
	recently_loaded = true

	# Restaurar estado abierto si procede
	if ControladorPartida.temp_data.has("opened_doors"):
		if ControladorPartida.temp_data["opened_doors"].get(door_id, false):
			open_door()
	if starts_open and not opened:
		open_door()
	if puzzle_id != "" and not opened:
		open_door()
	if puzzle_id != "":
		sprite.modulate = Color(1, 1, 1, 1)
	if not opened and sprite != null:
		sprite.frame = 0

	# Si venimos por esta puerta, colocar al jugador en el SpawnPoint
	var last_id: String = ControladorPartida.temp_data.get("last_door_id", "")
	var did_exit := false
	if last_id == door_id:
		if is_instance_valid(spawn_point):
			var tries := 0
			var skerney = get_tree().get_first_node_in_group("Skerney")
			while skerney == null and tries < 10:
				tries += 1
				await get_tree().process_frame
				skerney = get_tree().get_first_node_in_group("Skerney")
			if skerney:
				if not (skerney as Node).is_node_ready():
					await (skerney as Node).ready
				did_exit = true
				var last_dir: String = ControladorPartida.temp_data.get("last_door_entry", "from_up")
				var dir_vector := Vector2.ZERO
				if last_dir == "from_up":
					dir_vector = Vector2(0, 1)
					skerney.last_direction = "down"
				elif last_dir == "from_down":
					dir_vector = Vector2(0, -1)
					skerney.last_direction = "up"
				else:
					dir_vector = Vector2(0, 1)
					skerney.last_direction = "down"
				_try_play_walk_anim(skerney, last_dir)

				# Evitar reactivación inmediata del detector
				entry_detector.set_deferred("monitoring", false)
				skerney.can_move = false
				skerney.input_vector = dir_vector
				skerney.velocity = Vector2.ZERO

				var start_pos: Vector2 = spawn_point.global_position - dir_vector * door_edge_offset
				skerney.global_position = start_pos

				var tween := create_tween()
				tween.tween_property(skerney, "global_position", start_pos + dir_vector * exit_distance, exit_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				await tween.finished

				skerney.can_move = true
				skerney.input_vector = Vector2.ZERO
				skerney.velocity = Vector2.ZERO
				if close_after_player_enters:
					await get_tree().create_timer(0.05).timeout
					close_door()

				ControladorPartida.temp_data.erase("last_door_entry")
				ControladorPartida.temp_data.erase("last_door_id")
				ControladorPartida.temp_data.erase("puzzle_looping")

				await get_tree().create_timer(0.10).timeout
				entry_detector.set_deferred("monitoring", true)
	if did_exit:
		await get_tree().create_timer(0.20).timeout
		recently_loaded = false
	else:
		await get_tree().create_timer(0.18).timeout
		recently_loaded = false


func _try_play_walk_anim(skerney: Node, entry_direction: String) -> void:
	if not skerney.has_method("get"):
		return
	var anim_node = skerney.get("anim")
	if not (anim_node is AnimatedSprite2D):
		return
	var anim := anim_node as AnimatedSprite2D
	if anim.sprite_frames == null:
		return
	var anim_name := "walk_down" if entry_direction == "from_up" else "walk_up"
	if anim.sprite_frames.has_animation(anim_name):
		anim.play(anim_name)


func interact():
	if opened:
		return
	var skerney = get_tree().get_first_node_in_group("Skerney")
	if required_key == "" or (skerney and skerney.keys.get(required_key, false)):
		open_door()
	else:
		print("Necesitas la llave:", required_key)


func open_door():
	opened = true
	sprite.frame = 1
	collision.disabled = true
	solid_collision.disabled = true
	if not ControladorPartida.temp_data.has("opened_doors"):
		ControladorPartida.temp_data["opened_doors"] = {}
	ControladorPartida.temp_data["opened_doors"][door_id] = true


func close_door() -> void:
	opened = false
	if sprite != null:
		sprite.frame = 0
	if collision != null:
		collision.disabled = false
	if solid_collision != null:
		solid_collision.disabled = false
	if ControladorPartida.temp_data.has("opened_doors"):
		ControladorPartida.temp_data["opened_doors"].erase(door_id)


# Determina si el jugador entró desde arriba o desde abajo
func get_entry_direction(skerney: Node2D) -> String:
	if is_instance_valid(spawn_point):
		if skerney.global_position.y < spawn_point.global_position.y:
			return "from_up"
		if skerney.global_position.y > spawn_point.global_position.y:
			return "from_down"
	var iv = null
	if skerney.has_method("get"):
		iv = skerney.get("input_vector")
	if typeof(iv) == TYPE_VECTOR2:
		if iv.y < 0.0:
			return "from_down"
		if iv.y > 0.0:
			return "from_up"
	return "from_up"


# Inicio de la secuencia de entrada por la puerta
func start_cutscene(skerney):
	if is_transitioning:
		return
	is_transitioning = true

	if door_id == "salida_to_exterior":
		await _play_ending_cutscene(skerney)
		return

	if puzzle_id != "":
		var stage_key = "puzzle_stage_" + puzzle_id
		var stage = int(ControladorPartida.temp_data.get(stage_key, 0))
		if stage >= puzzle_total_stages:
			is_transitioning = false
			return
		await _play_puzzle_enter(skerney)
		_run_puzzle_choice_after_enter(stage_key, stage)
		return

	# Guardar datos para la escena destino
	var direction: String = get_entry_direction(skerney)
	ControladorPartida.temp_data["last_door_entry"] = direction
	ControladorPartida.temp_data["last_door_id"] = target_door_id if target_door_id != "" else door_id

	# Bloquear control del jugador
	skerney.can_move = false

	# Desactivar detector de forma segura
	entry_detector.set_deferred("monitoring", false)

	# Forzar la dirección de animación (solo animación)
	if direction == "from_up":
		skerney.input_vector = Vector2(0, 1)
		skerney.last_direction = "down"
	else:
		skerney.input_vector = Vector2(0, -1)
		skerney.last_direction = "up"
	_try_play_walk_anim(skerney, direction)

	# Colocar al jugador justo en el borde de la puerta
	var start_pos: Vector2 = spawn_point.global_position - skerney.input_vector * door_edge_offset
	skerney.global_position = start_pos

	# Tween lento hacia dentro (visualmente claro)
	var move_inside: Vector2 = skerney.input_vector * enter_distance
	var tween := create_tween()
	tween.tween_property(skerney, "global_position", start_pos + move_inside, enter_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	# Fade y cambio de escena
	var player_ref = skerney
	FadeLayer.fade_out_and_call(func():
		if next_scene == "":
			get_tree().reload_current_scene()
		else:
			if not ResourceLoader.exists(next_scene):
				is_transitioning = false
				entry_detector.set_deferred("monitoring", true)
				if is_instance_valid(player_ref):
					player_ref.can_move = true
				push_error("Door next_scene no existe: " + next_scene)
				return
			var err := get_tree().change_scene_to_file(next_scene)
			if err != OK:
				is_transitioning = false
				entry_detector.set_deferred("monitoring", true)
				if is_instance_valid(player_ref):
					player_ref.can_move = true
				push_error("Error al cambiar de escena: " + next_scene + " (" + str(err) + ")")
	)

	# limpieza por seguridad
	skerney.input_vector = Vector2.ZERO
	skerney.velocity = Vector2.ZERO


func _play_ending_cutscene(skerney: Node) -> void:
	ControladorPartida.temp_data.erase("last_door_entry")
	ControladorPartida.temp_data.erase("last_door_id")
	ControladorPartida.temp_data.erase("puzzle_looping")

	var dir := get_entry_direction(skerney as Node2D)
	skerney.can_move = false
	entry_detector.set_deferred("monitoring", false)

	if dir == "from_up":
		skerney.input_vector = Vector2(0, 1)
		skerney.last_direction = "down"
	else:
		skerney.input_vector = Vector2(0, -1)
		skerney.last_direction = "up"
	_try_play_walk_anim(skerney, dir)

	var start_pos: Vector2 = spawn_point.global_position - skerney.input_vector * door_edge_offset
	skerney.global_position = start_pos

	var move_inside: Vector2 = skerney.input_vector * enter_distance
	var tween := create_tween()
	tween.tween_property(skerney, "global_position", start_pos + move_inside, enter_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	skerney.input_vector = Vector2.ZERO
	skerney.velocity = Vector2.ZERO

	await FadeLayer.fade_out_blocking()
	await HUD.mostrar_texto_final("Una aventura te espera...", 1.6, 0.5, 0.7)
	await HUD.mostrar_texto_final("Gracias por jugar", 1.4, 0.4, 0.6)
	get_tree().change_scene_to_file("res://escenas/menu_principal/menu_principal.tscn")
	FadeLayer.fade_in()


func _play_puzzle_enter(skerney: Node) -> void:
	var direction: String = get_entry_direction(skerney)
	skerney.can_move = false
	entry_detector.set_deferred("monitoring", false)
	if direction == "from_up":
		skerney.input_vector = Vector2(0, 1)
		skerney.last_direction = "down"
	else:
		skerney.input_vector = Vector2(0, -1)
		skerney.last_direction = "up"
	_try_play_walk_anim(skerney, direction)

	var start_pos: Vector2 = spawn_point.global_position - skerney.input_vector * door_edge_offset
	skerney.global_position = start_pos

	var move_inside: Vector2 = skerney.input_vector * enter_distance
	var tween := create_tween()
	tween.tween_property(skerney, "global_position", start_pos + move_inside, enter_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	skerney.input_vector = Vector2.ZERO
	skerney.velocity = Vector2.ZERO


func _run_puzzle_choice_after_enter(stage_key: String, stage: int) -> void:
	var is_correct := false
	if puzzle_correct_stage >= 0:
		is_correct = puzzle_correct_stage == stage
	else:
		is_correct = puzzle_is_correct

	if is_correct:
		ControladorPartida.temp_data[stage_key] = stage + 1
	else:
		ControladorPartida.temp_data[stage_key] = 0

	FadeLayer.fade_out_and_call(func():
		ControladorPartida.temp_data["puzzle_looping"] = true
		ControladorPartida.temp_data["last_door_id"] = puzzle_loop_exit_door_id
		ControladorPartida.temp_data["last_door_entry"] = puzzle_loop_exit_entry_direction
		get_tree().reload_current_scene()
	)


func _on_EntryDetector_body_entered(body):
	if recently_loaded:
		return
	if is_transitioning:
		return
	if opened and body.is_in_group("Skerney"):
		start_cutscene(body)
