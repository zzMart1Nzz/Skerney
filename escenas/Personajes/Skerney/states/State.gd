extends Node
class_name State

var state_machine
var player

func _ready():
	player = get_parent().get_parent()

func enter():
	pass

func exit():
	pass

func update(delta):
	pass
