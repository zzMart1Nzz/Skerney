extends State

func enter():
	_play_walk()

func update(delta):
	if Input.is_action_just_pressed("attack"):
		state_machine.change_state("attack")
		return

	if player.input_vector == Vector2.ZERO:
		state_machine.change_state("idle")
		return

	_play_walk()


func _play_walk():
	match player.last_direction:
		"up":
			player.anim.play("walk_up")
		"down":
			player.anim.play("walk_down")
		"left", "right":
			player.anim.play("walk_left")
