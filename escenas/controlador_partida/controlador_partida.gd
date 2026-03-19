extends Node

const SAVE_FOLDER := "user://saves/"
const SLOT_PATH := "user://saves/slot%d/"
const DATA_FILE := "data.save"
const THUMB_FILE := "thumbnail.png"

var current_slot: int = 0
var temp_data: Dictionary = {}   # Guardado temporal en RAM


func _ready():
	ensure_save_folder()


# ---------------------------------------------------------
#   CREAR CARPETA DE GUARDADOS
# ---------------------------------------------------------
func ensure_save_folder():
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")


# ---------------------------------------------------------
#   COMPROBAR SI EXISTE ALGÚN GUARDADO
# ---------------------------------------------------------
func has_any_save() -> bool:
	for i in range(1, 4):
		if slot_exists(i):
			return true
	return false


# ---------------------------------------------------------
#   COMPROBAR SI UN SLOT EXISTE
# ---------------------------------------------------------
func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(SLOT_PATH % slot + DATA_FILE)


# ---------------------------------------------------------
#   GUARDAR PARTIDA EN UN SLOT (PERMANENTE)
# ---------------------------------------------------------
func save_game(slot: int, data: Dictionary, thumbnail: Image):
	var path := SLOT_PATH % slot

	var dir := DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")
	if not dir.dir_exists(path):
		dir.make_dir(path)

	# Guardar datos
	var file := FileAccess.open(path + DATA_FILE, FileAccess.WRITE)
	file.store_var(data)
	file.close()

	# Guardar miniatura
	thumbnail.save_png(path + THUMB_FILE)

	# Actualizar RAM
	temp_data = data


# ---------------------------------------------------------
#   CARGAR PARTIDA (ROM si existe, si no RAM)
# ---------------------------------------------------------
func load_game(slot: int) -> Dictionary:
	current_slot = slot

	# Si existe guardado permanente, cargarlo
	if slot_exists(slot):
		var path := SLOT_PATH % slot + DATA_FILE
		var file := FileAccess.open(path, FileAccess.READ)
		var data: Dictionary = file.get_var()
		file.close()
		temp_data = data
		return data

	# Si no existe, usar el guardado temporal
	return temp_data


# ---------------------------------------------------------
#   CARGAR MINIATURA
# ---------------------------------------------------------
func load_thumbnail(slot: int) -> Texture2D:
	var path := SLOT_PATH % slot + THUMB_FILE
	if FileAccess.file_exists(path):
		var img := Image.new()
		var err := img.load(path)
		if err == OK:
			return ImageTexture.create_from_image(img)
	return null


# ---------------------------------------------------------
#   CAPTURAR MINIATURA DEL JUEGO
# ---------------------------------------------------------
func capture_thumbnail() -> Image:
	var img := get_viewport().get_texture().get_image()
	img.resize(256, 144)
	return img


# ---------------------------------------------------------
#   INICIAR NUEVA PARTIDA (GUARDADO TEMPORAL)
# ---------------------------------------------------------
func new_game(slot: int):
	current_slot = slot

	temp_data = {
		"level": "res://escenas/dungeon_1/la_cripta_del_olvido/la_cripta_del_olvido.tscn",
		"player_position": Vector2(0, 0),
		"timestamp": Time.get_datetime_string_from_system(),
		"play_time": 0,
		"lives": 3
	}

	get_tree().change_scene_to_file(temp_data["level"])


# ---------------------------------------------------------
#   BORRAR UNA PARTIDA
# ---------------------------------------------------------
func delete_slot(slot: int):
	var path := SLOT_PATH % slot
	var dir := DirAccess.open(path)

	if dir:
		if dir.file_exists(DATA_FILE):
			dir.remove(DATA_FILE)
		if dir.file_exists(THUMB_FILE):
			dir.remove(THUMB_FILE)
