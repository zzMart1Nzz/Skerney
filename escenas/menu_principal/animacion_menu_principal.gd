extends AnimatedSprite2D




func _ready():
	play("menu_scene")
	

func _process(delta):
	position.y += sin(Time.get_ticks_msec()/600.0) * 0.05
