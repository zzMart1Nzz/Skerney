extends Area2D

@export var mensaje: String = "Partida guardada"

var puede_guardar := false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body):
	if body.name == "Player":
		puede_guardar = true


func _on_body_exited(body):
	if body.name == "Player":
		puede_guardar = false


func _process(delta):
	if puede_guardar and Input.is_action_just_pressed("interactuar"):
		guardar_partida()


func guardar_partida():
	# Fade opcional
	FadeLayer.fade_out_and_call(func():
		var slot: int = ControladorPartida.current_slot
		if slot == 0:
			print("ERROR: No hay slot activo")
			FadeLayer.fade_in()
			return

		# Capturar miniatura
		var thumbnail := ControladorPartida.capture_thumbnail()

		# Buscar al jugador
		var player := get_tree().current_scene.get_node("Player")

		# Datos a guardar
		var data := {
			"level": get_tree().current_scene.scene_file_path,
			"player_position": player.global_position,
			"timestamp": Time.get_datetime_string_from_system(),
			"play_time": 0,
			"lives": 3
		}

		# Guardar
		ControladorPartida.save_game(slot, data, thumbnail)

		# Fade in
		FadeLayer.fade_in()

		# Mostrar mensaje
		mostrar_mensaje_guardado()
	)


func mostrar_mensaje_guardado():
	var label := get_tree().current_scene.get_node("HUD/MensajeGuardado")
	label.text = mensaje
	label.visible = true

	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.2)
	tween.tween_interval(1.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.4)
	tween.finished.connect(func():
		label.visible = false
	)
