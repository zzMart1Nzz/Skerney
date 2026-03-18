extends Area2D

signal key_obtained

@onready var anim := $AnimatedSprite2D
var opened := false

func _ready():
	anim.play("closed")

func interact():
	if opened:
		return
	opened = true
	anim.play("open")
	await anim.animation_finished
	emit_signal("key_obtained")
