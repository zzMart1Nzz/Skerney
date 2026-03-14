extends Control

func _ready():
	$AnimacionMenuPrincipal.play("menu_scene")

func _process(delta):
	$AnimacionMenuPrincipal.position.y += sin(Time.get_ticks_msec()/600.0) * 0.05
