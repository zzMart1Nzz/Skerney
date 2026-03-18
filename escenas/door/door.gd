extends Area2D

@export var next_scene: String
@onready var sprite := $Sprite2D
@onready var collision := $CollisionShape2D

var opened := false

func _on_body_entered(body: Node):
	if opened:
		return

	if body.name == "Skerney":
		if body.has_key:
			open_door()
		else:
			print("Necesitas una llave.") # Más adelante lo cambias por tu UI

func open_door():
	opened = true
	sprite.frame = 1  # Frame 1 = puerta abierta
	collision.disabled = true

	FadeLayer.fade_out_and_call(func():
		get_tree().change_scene_to_file(next_scene)
	)
