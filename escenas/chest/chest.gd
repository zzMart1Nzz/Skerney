extends Area2D

@export var key_id: String = ""   

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

	$StaticBody2D/CollisionShape2D.disabled = true

	var skerney = get_tree().get_first_node_in_group("Skerney")

	if skerney:
		skerney.keys[key_id] = true  
		print("Llave obtenida:", key_id)
		emit_signal("key_obtained")
	else:
		print("ERROR: No se encontró a Skerney")
