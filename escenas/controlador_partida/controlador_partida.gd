extends Node

const SAVE_FOLDER := "user://saves/"
const SLOT_PATH := "user://saves/slot%d/"
const DATA_FILE := "data.save"
const THUMB_FILE := "thumbnail.png"

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
#   GUARDAR PARTIDA EN UN SLOT
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


# ---------------------------------------------------------
#   CARGAR PARTIDA DE UN SLOT
# ---------------------------------------------------------
func load_game(slot: int) -> Dictionary:
	var path := SLOT_PATH % slot + DATA_FILE
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		var data: Dictionary = file.get_var()
		file.close()
		return data
	return {}


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
