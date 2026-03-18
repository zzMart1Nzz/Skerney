extends Area2D

@export var next_scene: String
@onready var sprite := $Sprite2D
@onready var collision := $CollisionShape2D
@onready var solid_collision := $StaticBody2D/CollisionShape2D

var opened := false

func interact():
	if opened:
		return

	var skerney := get_tree().get_first_node_in_group("Skerney")
	if skerney and skerney.has_key:
		open_door()
	else:
		print("Necesitas una llave.")

func open_door():
	opened = true
	sprite.frame = 1
	collision.disabled = true
	solid_collision.disabled = true

	var skerney = get_tree().get_first_node_in_group("Skerney")
	if not skerney:
		print("ERROR: No se encontró a Skerney en el grupo 'Skerney'")
		return

	# 1. Bloquear control del jugador
	skerney.can_move = false

	# 2. Cambiar al estado WALK para animación
	var sm = skerney.get_node_or_null("StateMachine")
	if sm:
		sm.change_state("walk")

	# 3. Movimiento automático (40px hacia arriba)
	var tween := create_tween()
	tween.tween_property(skerney, "position:y", skerney.position.y - 40, 1.0)

	# 4. Cuando termine → Fade → cambiar escena
	tween.tween_callback(func():
		FadeLayer.fade_out_and_call(func():
			if next_scene == "":
				get_tree().reload_current_scene()
			else:
				get_tree().change_scene_to_file(next_scene)
		))
