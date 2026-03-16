extends State

var finished := false

func enter():
	finished = false
	var anim_name = "attack_" + player.last_direction
	player.anim.play(anim_name)
	player.velocity = Vector2.ZERO

func update(delta):
	if player.anim.frame == player.anim.frames.get_frame_count(player.anim.animation) - 1:
		if not finished:
			finished = true
			state_machine.change_state("idle")
