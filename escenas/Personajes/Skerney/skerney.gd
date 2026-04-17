extends CharacterBody2D

@export var speed: float = 60.0
@export var anim: AnimatedSprite2D
@export var audio_attack: AudioStreamPlayer2D

var input_vector := Vector2.ZERO
var last_direction := "down"

# 🔥 NUEVO SISTEMA DE INVENTARIO DE LLAVES
var keys := {}   # Ej: keys["llave_cripta"] = true

var interactable: Node = null
var can_move := true


func _physics_process(delta):
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_read_input()
	move_and_slide()

	if Input.is_action_just_pressed("action_button"):
		if interactable:
			interactable.interact()
		else:
			attack()


func _read_input():
	input_vector = Vector2.ZERO

	var x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	input_vector = Vector2(x, y)

	if input_vector.length() > 0.1:
		input_vector = input_vector.normalized()

		if abs(input_vector.x) > abs(input_vector.y):
			if input_vector.x > 0:
				last_direction = "right"
				anim.flip_h = true
			else:
				last_direction = "left"
				anim.flip_h = false
		else:
			if input_vector.y < 0:
				last_direction = "up"
			else:
				last_direction = "down"

		_update_interaction_detector()

	velocity = input_vector * speed


func attack():
	if audio_attack:
		audio_attack.play()


func _update_interaction_detector():
	var offset := Vector2.ZERO

	match last_direction:
		"up":
			offset = Vector2(0, -12)
		"down":
			offset = Vector2(0, 12)
		"left":
			offset = Vector2(-12, 0)
		"right":
			offset = Vector2(12, 0)

	$InteractionDetector.position = offset


# 🔥 YA NO USAMOS has_key
# ESTE MÉTODO YA NO ES NECESARIO, PERO LO DEJO POR SI LO USAS EN ALGÚN SITIO
func _on_chest_key_obtained():
	print("Has obtenido una llave (usa keys[] ahora).")


func _on_InteractionDetector_area_entered(area):
	if area.has_method("interact"):
		interactable = area
		print("Detectado interactuable:", area.name)


func _on_InteractionDetector_area_exited(area):
	if interactable == area:
		interactable = null
		print("Interactuable salido:", area.name)
