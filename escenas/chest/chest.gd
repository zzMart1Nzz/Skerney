extends Area2D

@export var key_id: String = ""      # ID de la llave que da
@export var chest_id: String = ""    # ID único del cofre

signal key_obtained

@onready var anim := $AnimatedSprite2D
var opened := false

func _ready():
	# 🔥 Restaurar estado si ya estaba abierto
	if ControladorPartida.temp_data.has("opened_chests"):
		if ControladorPartida.temp_data["opened_chests"].get(chest_id, false):
			opened = true
			anim.play("open")
			$StaticBody2D/CollisionShape2D.disabled = true
			return

	anim.play("closed")


func interact():
	if opened:
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
		print("Llave obtenida:", key_id)

		emit_signal("key_obtained")
	else:
		print("ERROR: No se encontró a Skerney")
