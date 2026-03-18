extends State

var finished := false

func enter():
	finished = false
	skerney.velocity = Vector2.ZERO

	# Reproducir sonido de ataque
	skerney.audio_attack.play()

	var anim_name := ""

	match skerney.last_direction:
		"up":
			anim_name = "attack_up"
		"down":
			anim_name = "attack_down"
		"left", "right":
			anim_name = "attack_left"

	skerney.anim.play(anim_name)


func update(delta):
	var anim_name = skerney.anim.animation
	var last_frame = skerney.anim.sprite_frames.get_frame_count(anim_name) - 1

	if skerney.anim.frame == last_frame:
		if not finished:
			finished = true
			state_machine.change_state("idle")
