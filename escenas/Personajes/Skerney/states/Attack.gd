extends State

var finished := false
@export var hit_start_frame: int = 2
@export var hit_end_frame: int = 4
@export var damage: int = 1

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
	skerney.begin_attack()


func update(delta):
	var anim_name = skerney.anim.animation
	var last_frame = skerney.anim.sprite_frames.get_frame_count(anim_name) - 1

	skerney.set_attack_hitbox_direction(skerney.last_direction)
	if skerney.anim.frame >= hit_start_frame and skerney.anim.frame <= hit_end_frame:
		skerney.set_attack_hitbox_active(true)
		skerney.try_attack_hit(damage)
	else:
		skerney.set_attack_hitbox_active(false)

	if skerney.anim.frame == last_frame:
		if not finished:
			finished = true
			state_machine.change_state("idle")


func exit():
	skerney.end_attack()
