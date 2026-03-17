extends State

var finished := false

func enter():
	finished = false
	player.velocity = Vector2.ZERO

	# Reproducir sonido de ataque
	player.audio_attack.play()

	var anim_name := ""

	match player.last_direction:
		"up":
			anim_name = "attack_up"
		"down":
			anim_name = "attack_down"
		"left", "right":
			anim_name = "attack_left"

	player.anim.play(anim_name)


func update(delta):
	var anim_name = player.anim.animation
	var last_frame = player.anim.sprite_frames.get_frame_count(anim_name) - 1

	if player.anim.frame == last_frame:
		if not finished:
			finished = true
			state_machine.change_state("idle")
