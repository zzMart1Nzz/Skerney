extends Area2D

@export var mensaje: String = "Partida guardada"

func interact():
	guardar_partida()


func guardar_partida():
	var slot: int = ControladorPartida.current_slot
	if slot == 0:
		print("ERROR: No hay slot activo")
		return

	var thumbnail := ControladorPartida.capture_thumbnail()
	var player := get_tree().current_scene.get_node("Skerney")

	var data := {
		"level": get_tree().current_scene.scene_file_path,
		"player_position": player.global_position,
		"timestamp": Time.get_datetime_string_from_system(),
		"play_time": ControladorPartida.temp_data.get("play_time", 0),
		"opened_doors": ControladorPartida.temp_data.get("opened_doors", {}),
		"lives": 3
	}

	ControladorPartida.save_game(slot, data, thumbnail)
	mostrar_mensaje_guardado()


func mostrar_mensaje_guardado():
	HUD.mostrar_mensaje(mensaje)
