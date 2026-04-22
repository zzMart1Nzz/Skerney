extends Area2D

@export var mensaje: String = "Partida guardada"

func interact():
	guardar_partida()


func guardar_partida():
	var slot: int = ControladorPartida.current_slot
	if slot == 0:
		push_error("No hay slot activo")
		HUD.mostrar_mensaje("No hay slot activo")
		return

	var thumbnail := ControladorPartida.capture_thumbnail()
	var player := get_tree().current_scene.get_node("Skerney")

	var data: Dictionary = ControladorPartida.temp_data.duplicate(true)
	data["level"] = get_tree().current_scene.scene_file_path
	data["player_position"] = player.global_position
	data["timestamp"] = Time.get_datetime_string_from_system()
	data["play_time"] = ControladorPartida.temp_data.get("play_time", 0)
	data["opened_doors"] = ControladorPartida.temp_data.get("opened_doors", {})
	data["opened_chests"] = ControladorPartida.temp_data.get("opened_chests", {})
	data["keys"] = ControladorPartida.temp_data.get("keys", {})
	data["killed_enemies"] = ControladorPartida.temp_data.get("killed_enemies", {})
	data["lives"] = data.get("lives", 3)

	ControladorPartida.save_game(slot, data, thumbnail)
	mostrar_mensaje_guardado()


func mostrar_mensaje_guardado():
	HUD.mostrar_mensaje(mensaje)
