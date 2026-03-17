extends State

func enter():
	_play_idle()

func update(delta):
	if Input.is_action_just_pressed("attack"):
		state_machine.change_state("attack")
		return

	if player.input_vector != Vector2.ZERO:
		state_machine.change_state("walk")


func _play_idle():
	match player.last_direction:
		"up":
			player.anim.play("idle_up")
		"down":
			player.anim.play("idle_down")
		"left", "right":
			player.anim.play("idle_left")
