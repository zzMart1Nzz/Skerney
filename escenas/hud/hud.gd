extends CanvasLayer

@onready var mensaje_label := $MensajeGuardado
@onready var death_menu := $DeathMenu
@onready var btn_retry := $DeathMenu/Panel/VBoxContainer/RetryButton
@onready var btn_menu := $DeathMenu/Panel/VBoxContainer/MenuButton

var _death_menu_open := false

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


func mostrar_menu_muerte() -> void:
	if _death_menu_open:
		return
	_death_menu_open = true
	death_menu.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	btn_retry.grab_focus()


func ocultar_menu_muerte() -> void:
	if not _death_menu_open:
		return
	_death_menu_open = false
	death_menu.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _on_retry_button_pressed() -> void:
	ocultar_menu_muerte()
	FadeLayer.fade_out_and_call(func():
		if ControladorPartida.current_slot != 0 and ControladorPartida.slot_exists(ControladorPartida.current_slot):
			ControladorPartida.load_game(ControladorPartida.current_slot)
		else:
			get_tree().reload_current_scene()
	)


func _on_menu_button_pressed() -> void:
	ocultar_menu_muerte()
	FadeLayer.fade_out_and_call(func():
		get_tree().change_scene_to_file("res://escenas/menu_principal/menu_principal.tscn")
	)
