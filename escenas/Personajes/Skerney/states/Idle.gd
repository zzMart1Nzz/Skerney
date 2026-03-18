extends State

func enter():
	_play_idle()

func update(delta):
	if Input.is_action_just_pressed("action_button") and skerney.interactable == null:
		state_machine.change_state("attack")
		return

	if skerney.input_vector != Vector2.ZERO:
		state_machine.change_state("walk")


func _play_idle():
	match skerney.last_direction:
		"up":
			skerney.anim.play("idle_up")
		"down":
			skerney.anim.play("idle_down")
		"left", "right":
			skerney.anim.play("idle_left")
