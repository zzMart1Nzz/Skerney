extends State

func enter():
	_play_walk()

func update(delta):
	if Input.is_action_just_pressed("action_button") and skerney.interactable == null:
		state_machine.change_state("attack")
		return

	if skerney.can_move:
		if skerney.input_vector == Vector2.ZERO:
			state_machine.change_state("idle")
			return
		


	_play_walk()


func _play_walk():
	match skerney.last_direction:
		"up":
			skerney.anim.play("walk_up")
		"down":
			skerney.anim.play("walk_down")
		"left", "right":
			skerney.anim.play("walk_left")
