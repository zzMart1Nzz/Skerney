extends Area2D

@export var next_scene: String
@onready var sprite := $Sprite2D
@onready var collision := $CollisionShape2D

var opened := false

func interact():
	if opened:
		return

	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_key:
		open_door()
	else:
		print("Necesitas una llave.")

func open_door():
	opened = true
	sprite.frame = 1
	collision.disabled = true

	FadeLayer.fade_out_and_call(func():
		get_tree().change_scene_to_file(next_scene)
	)
