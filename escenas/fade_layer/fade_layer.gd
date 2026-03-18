extends CanvasLayer

@onready var rect := $ColorRect
@onready var anim := $AnimationPlayer

func fade_out():
	anim.play("fade_out")

func fade_in():
	anim.play("fade_in")

func fade_out_and_call(callback: Callable):
	anim.play("fade_out")
	await anim.animation_finished
	callback.call()
	anim.play("fade_in")
