extends Area2D

@export var next_scene: String
@onready var sprite := $Sprite2D
@onready var collision := $CollisionShape2D
@onready var solid_collision := $StaticBody2D/CollisionShape2D

var opened := false


func interact():
	if opened:
		return

	var skerney = get_tree().get_first_node_in_group("Skerney")
	if skerney and skerney.has_key:
		open_door()
	else:
		print("Necesitas una llave.")


func open_door():
	opened = true
	sprite.frame = 1
	collision.disabled = true
	solid_collision.disabled = true
	print("Puerta abierta. Ahora debes avanzar para entrar.")


func start_cutscene(skerney):
	# 1. Bloquear control
	skerney.can_move = false

	# 2. Animación de caminar
	var sm = skerney.get_node_or_null("StateMachine")
	if sm:
		sm.change_state("walk")

	# 3. Movimiento automático mientras se oscurece
	var tween := create_tween()
	tween.tween_property(skerney, "position:y", skerney.position.y - 10, 1.0)

	# 4. Fade + cambio de escena (en paralelo al tween)
	FadeLayer.fade_out_and_call(func():
		if next_scene == "":
			get_tree().reload_current_scene()
		else:
			get_tree().change_scene_to_file(next_scene)
	)


func _on_EntryDetector_body_entered(body):
	if opened and body.is_in_group("Skerney"):
		start_cutscene(body)
