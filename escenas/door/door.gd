extends Area2D

@export var next_scene: String
@export var required_key: String = ""
@export var door_id: String = ""   
@export var entry_offset: Vector2 = Vector2(0, -10)


@onready var sprite := $Sprite2D
@onready var collision := $CollisionShape2D
@onready var solid_collision := $StaticBody2D/CollisionShape2D

var opened := false


func _ready():
	#  Restaurar estado si ya estaba abierta
	if ControladorPartida.temp_data.has("opened_doors"):
		if ControladorPartida.temp_data["opened_doors"].get(door_id, false):
			opened = true
			sprite.frame = 1
			collision.disabled = true
			solid_collision.disabled = true


func interact():
	if opened:
		return

	var skerney = get_tree().get_first_node_in_group("Skerney")
	if skerney and skerney.keys.get(required_key, false):
		open_door()
	else:
		print("Necesitas la llave:", required_key)


func open_door():
	opened = true
	sprite.frame = 1
	collision.disabled = true
	solid_collision.disabled = true

	#  Guardar estado de puerta abierta
	if ControladorPartida.temp_data.has("opened_doors"):
		ControladorPartida.temp_data["opened_doors"][door_id] = true

	print("Puerta abierta. Ahora debes avanzar para entrar.")


func start_cutscene(skerney):
	skerney.can_move = false

	var sm = skerney.get_node_or_null("StateMachine")
	if sm:
		sm.change_state("walk")

	var tween := create_tween()
	tween.tween_property(skerney, "position", skerney.position + entry_offset, 1.0)


	FadeLayer.fade_out_and_call(func():
		if next_scene == "":
			get_tree().reload_current_scene()
		else:
			get_tree().change_scene_to_file(next_scene)
	)


func _on_EntryDetector_body_entered(body):
	if opened and body.is_in_group("Skerney"):
		start_cutscene(body)
