extends CanvasLayer

@onready var mensaje_label := $MensajeGuardado

func mostrar_mensaje(texto: String):
	mensaje_label.text = texto
	mensaje_label.visible = true
	mensaje_label.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(mensaje_label, "modulate:a", 1.0, 0.2)
	tween.tween_interval(1.0)
	tween.tween_property(mensaje_label, "modulate:a", 0.0, 0.4)
	tween.finished.connect(func():
		mensaje_label.visible = false
	)
