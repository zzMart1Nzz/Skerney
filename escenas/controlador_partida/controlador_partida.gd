extends Node

const SAVE_FOLDER := "user://saves/"
const SLOT_PATH := "user://saves/slot%d/"
const DATA_FILE := "data.save"
const THUMB_FILE := "thumbnail.png"

var current_slot: int = 0
var temp_data: Dictionary = {}   # Guardado temporal en RAM


func _ready():
	ensure_save_folder()
	set_process(true)

	# 🔥 Asegurar estructuras persistentes
	if not temp_data.has("opened_doors"):
		temp_data["opened_doors"] = {}

	if not temp_data.has("keys"):
		temp_data["keys"] = {}

	if not temp_data.has("opened_chests"):
		temp_data["opened_chests"] = {}   # 🔥 IMPORTANTE

	if not temp_data.has("play_time"):
		temp_data["play_time"] = 0




func _process(delta):
	if temp_data.has("play_time"):
		temp_data["play_time"] += delta


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
# CARGA LA PARTIDA COMPLETA (COROUTINE)
# ---------------------------------------------------------
func load_game(slot: int):
	current_slot = slot

	var data := load_game_data(slot)
	temp_data = data

	# 🔥 Asegurar estructuras
	if not temp_data.has("opened_doors"):
		temp_data["opened_doors"] = {}
	if not temp_data.has("keys"):
		temp_data["keys"] = {}
	if not temp_data.has("play_time"):
		temp_data["play_time"] = 0
	if not temp_data.has("opened_chests"):
		temp_data["opened_chests"] = {}

	if data.has("level"):
		get_tree().change_scene_to_file(data["level"])
		await get_tree().process_frame

		var player := get_tree().current_scene.get_node_or_null("Skerney")
		if player and data.has("player_position"):
			player.global_position = data["player_position"]

	return data


# ---------------------------------------------------------
# SOLO LEE EL ARCHIVO, NO CAMBIA DE ESCENA
# ---------------------------------------------------------
func load_game_data(slot: int) -> Dictionary:
	if slot_exists(slot):
		var path := SLOT_PATH % slot + DATA_FILE
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
	img.convert(Image.FORMAT_RGBA8)
	return img


# ---------------------------------------------------------
#   INICIAR NUEVA PARTIDA
# ---------------------------------------------------------
func new_game(slot: int):
	current_slot = slot

	temp_data = {
	"level": "res://escenas/dungeon_1/la_cripta_del_olvido/la_cripta_del_olvido.tscn",
	"player_position": Vector2(0, 0),
	"timestamp": Time.get_datetime_string_from_system(),
	"play_time": 0,
	"lives": 3,
	"opened_doors": {},
	"keys": {},
	"opened_chests": {}   
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
