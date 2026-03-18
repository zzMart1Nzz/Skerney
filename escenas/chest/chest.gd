extends Area2D

signal key_obtained

@onready var anim := $AnimatedSprite2D
var opened := false

func _ready():
	anim.play("closed")

func interact():
	if opened:
		return

	opened = true
	anim.play("open")

	# Desactivar colisión sólida
	$StaticBody2D/CollisionShape2D.disabled = true

	# Dar la llave a Skerney
	var skerney = get_tree().get_first_node_in_group("Skerney")
	print("Buscando a Skerney:", skerney)

	if skerney:
		skerney.has_key = true
		print("Llave obtenida:", skerney.has_key)
		emit_signal("key_obtained")
	else:
		print("ERROR: No se encontró a Skerney en el grupo 'Skerney'")
