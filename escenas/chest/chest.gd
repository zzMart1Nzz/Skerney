extends Area2D

@export var key_id: String = ""      # ID de la llave que da
@export var chest_id: String = ""    # ID único del cofre
@export var key_display_name: String = ""
@export var required_temp_key: String = ""
@export var required_temp_min_value: int = 0
@export var required_killed_enemy_id: String = ""
@export var reset_temp_key_on_open: String = ""
@export var reset_temp_value_on_open: int = 0
@export var reload_scene_on_open: bool = false

signal key_obtained

@onready var anim := $AnimatedSprite2D
var opened := false

func _set_enabled(enabled: bool) -> void:
	visible = enabled
	$CollisionShape2D.disabled = not enabled
	$StaticBody2D/CollisionShape2D.disabled = not enabled

func _is_required_enemy_killed() -> bool:
	if required_killed_enemy_id == "":
		return true
	var killed_enemies = ControladorPartida.temp_data.get("killed_enemies")
	if typeof(killed_enemies) != TYPE_DICTIONARY:
		return false
	var v = (killed_enemies as Dictionary).get(required_killed_enemy_id, false)
	if typeof(v) == TYPE_BOOL:
		return v
	return false

func _ready():
	if required_temp_key != "":
		var current_value := int(ControladorPartida.temp_data.get(required_temp_key, 0))
		if current_value < required_temp_min_value:
			_set_enabled(false)
			return
	if not _is_required_enemy_killed():
		_set_enabled(false)
		return

	# 🔥 Restaurar estado si ya estaba abierto
	if ControladorPartida.temp_data.has("opened_chests"):
		if ControladorPartida.temp_data["opened_chests"].get(chest_id, false):
			opened = true
			_set_enabled(true)
			anim.play("open")
			$StaticBody2D/CollisionShape2D.disabled = true
			return

	anim.play("closed")
	_set_enabled(true)


func activate() -> void:
	if not _is_required_enemy_killed():
		return
	if ControladorPartida.temp_data.has("opened_chests"):
		if ControladorPartida.temp_data["opened_chests"].get(chest_id, false):
			opened = true
			_set_enabled(true)
			anim.play("open")
			$StaticBody2D/CollisionShape2D.disabled = true
			return
	opened = false
	anim.play("closed")
	_set_enabled(true)


func interact():
	if opened:
		return
	if required_temp_key != "":
		var current_value := int(ControladorPartida.temp_data.get(required_temp_key, 0))
		if current_value < required_temp_min_value:
			return
	if not _is_required_enemy_killed():
		return

	opened = true
	anim.play("open")
	$StaticBody2D/CollisionShape2D.disabled = true

	# 🔥 Guardar cofre como abierto para siempre
	ControladorPartida.temp_data["opened_chests"][chest_id] = true

	var skerney = get_tree().get_first_node_in_group("Skerney")

	if skerney:
		# Dar llave
		skerney.keys[key_id] = true  
		ControladorPartida.temp_data["keys"] = skerney.keys
		var shown_name := key_display_name if key_display_name != "" else key_id
		HUD.mostrar_mensaje("Has conseguido la llave: " + shown_name)

		emit_signal("key_obtained")
		if reset_temp_key_on_open != "":
			ControladorPartida.temp_data[reset_temp_key_on_open] = reset_temp_value_on_open
		if reload_scene_on_open:
			FadeLayer.fade_out_and_call(func():
				get_tree().reload_current_scene()
			)
	else:
		push_error("No se encontró a Skerney")
