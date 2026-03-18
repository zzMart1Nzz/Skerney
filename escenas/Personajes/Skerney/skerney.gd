extends CharacterBody2D

@export var speed: float = 120.0
@export var anim: AnimatedSprite2D
@export var audio_attack: AudioStreamPlayer2D

var input_vector := Vector2.ZERO
var last_direction := "down"
var has_key := false
var interactable: Node = null

func _physics_process(delta):
	_read_input()
	move_and_slide()

	# Acción inteligente: interactuar o atacar
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

	velocity = input_vector * speed

# Tu ataque original sigue funcionando igual
func attack():
	if audio_attack:
		audio_attack.play()
	# Aquí no toco nada: tu animación de ataque ya la controlas tú desde anim

func _on_chest_key_obtained():
	has_key = true
	print("Has obtenido una llave.")

func _on_InteractionDetector_body_entered(body):
	if body.has_method("interact"):
		interactable = body

func _on_InteractionDetector_body_exited(body):
	if interactable == body:
		interactable = null
