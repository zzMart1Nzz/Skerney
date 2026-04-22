extends Control

var modo_slots := ""  # "new" o "load"
var _starting_new_game := false

func _ready():

	$VBoxContainer/CargarPartida.visible = ControladorPartida.has_any_save()

	$OpcionesVentana.visible = false
	$FondoOscuro.visible = false
	$FondoOscuro/MenuSlots.visible = false
	
	cargar_ajustes()
	$VBoxContainer/NuevaPartida.grab_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)



# ---------------------------------------------------------
#   NUEVA PARTIDA
# ---------------------------------------------------------
func _on_nueva_partida_pressed():
	modo_slots = "new"
	$VBoxContainer.visible = false
	$FondoOscuro.visible = true
	$FondoOscuro/MenuSlots.visible = true

	_update_slots()
	$FondoOscuro/MenuSlots/Slot1.grab_focus()



# ---------------------------------------------------------
#   CONTINUAR / CARGAR PARTIDA
# ---------------------------------------------------------
func _on_cargar_partida_pressed():
	modo_slots = "load"
	$VBoxContainer.visible = false
	$FondoOscuro.visible = true
	$FondoOscuro/MenuSlots.visible = true

	_update_slots()
	$FondoOscuro/MenuSlots/Slot1.grab_focus()



# ---------------------------------------------------------
#   ACTUALIZAR INFORMACIÓN DE SLOTS
# ---------------------------------------------------------
func _update_slots():
	for i in range(1, 4):
		var slot_node = $FondoOscuro/MenuSlots.get_node("Slot%d" % i)

		if ControladorPartida.slot_exists(i):
			var data = ControladorPartida.load_game_data(i)
			var tex = ControladorPartida.load_thumbnail(i)

			if tex:
				var img := tex.get_image()

				# Obtener tamaño del marco
				var marco = slot_node.get_node("MarcoMiniatura")
				var target_size: Vector2 = marco.size

				# Redimensionar manteniendo calidad
				img.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)

				# Aplicar textura
				slot_node.get_node("MarcoMiniatura/Miniatura").texture = ImageTexture.create_from_image(img)

			slot_node.get_node("Datos/Fecha").text = data.get("timestamp", "Fecha desconocida")
			var total_seconds := int(data.get("play_time", 0))
			var total_minutes := total_seconds / 60
			var hours := total_minutes / 60
			var minutes := total_minutes % 60
			slot_node.get_node("Datos/Tiempo").text = "%02d:%02d" % [hours, minutes]
		else:
			slot_node.get_node("MarcoMiniatura/Miniatura").texture = null
			slot_node.get_node("Datos/Fecha").text = "Vacío"
			slot_node.get_node("Datos/Tiempo").text = ""





# ---------------------------------------------------------
#   ACCIÓN AL PULSAR UN SLOT
# ---------------------------------------------------------
func _on_slot_pressed(slot: int):

	if modo_slots == "new":
		if _starting_new_game:
			return
		_starting_new_game = true

		if ControladorPartida.slot_exists(slot):
			ControladorPartida.delete_slot(slot)

		$FondoOscuro.visible = false
		$FondoOscuro/MenuSlots.visible = false
		$OpcionesVentana.visible = false
		$VBoxContainer.visible = false
		await HUD.reproducir_cinematica_intro()
		FadeLayer.fade_out_and_call(func():
			ControladorPartida.new_game(slot)
		)

	elif modo_slots == "load":
		if ControladorPartida.slot_exists(slot):
			FadeLayer.fade_out_and_call(func():
				ControladorPartida.load_game(slot)
			)



# ---------------------------------------------------------
#   SLOTS PRESSED (CONEXIONES)
# ---------------------------------------------------------
func _on_slot_1_pressed():
	_on_slot_pressed(1)

func _on_slot_2_pressed():
	_on_slot_pressed(2)

func _on_slot_3_pressed():
	_on_slot_pressed(3)



# ---------------------------------------------------------
#   OPCIONES
# ---------------------------------------------------------
func _on_opciones_pressed():
	$VBoxContainer.visible = false
	$OpcionesVentana.visible = true
	$OpcionesVentana/Panel/VBoxContainer/HBox_Maestro/HSliderMaestro.grab_focus()



# ---------------------------------------------------------
#   SALIR
# ---------------------------------------------------------
func _on_salir_pressed():
	get_tree().quit()



# ---------------------------------------------------------
#   SLIDERS DE AUDIO
# ---------------------------------------------------------
func _on_h_slider_maestro_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
	guardar_ajustes()

func _on_h_slider_musica_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))
	guardar_ajustes()

func _on_h_slider_sfx_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))
	guardar_ajustes()
	$SFX_Navigate.play()



# ---------------------------------------------------------
#   BOTÓN VOLVER (OPCIONES)
# ---------------------------------------------------------
func _on_volver_pressed():
	$OpcionesVentana.visible = false
	$VBoxContainer.visible = true
	$VBoxContainer/Opciones.grab_focus()



# ---------------------------------------------------------
#   BOTÓN VOLVER (SLOTS)
# ---------------------------------------------------------
func _on_volver_load_pressed():
	$FondoOscuro.visible = false
	$FondoOscuro/MenuSlots.visible = false
	$VBoxContainer.visible = true
	$VBoxContainer/NuevaPartida.grab_focus()



# ---------------------------------------------------------
#   GUARDAR AJUSTES
# ---------------------------------------------------------
func guardar_ajustes():
	var ajustes = {
		"master": $OpcionesVentana/Panel/VBoxContainer/HBox_Maestro/HSliderMaestro.value,
		"musica": $OpcionesVentana/Panel/VBoxContainer/HBox_Musica/HSliderMusica.value,
		"sfx": $OpcionesVentana/Panel/VBoxContainer/HBox_SFX/HSliderSFX.value
	}

	var file = FileAccess.open("user://ajustes.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(ajustes))
	file.close()



# ---------------------------------------------------------
#   CARGAR AJUSTES
# ---------------------------------------------------------
func cargar_ajustes():
	if not FileAccess.file_exists("user://ajustes.json"):
		return

	var file = FileAccess.open("user://ajustes.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if data == null:
		return

	$OpcionesVentana/Panel/VBoxContainer/HBox_Maestro/HSliderMaestro.value = data["master"]
	$OpcionesVentana/Panel/VBoxContainer/HBox_Musica/HSliderMusica.value = data["musica"]
	$OpcionesVentana/Panel/VBoxContainer/HBox_SFX/HSliderSFX.value = data["sfx"]

	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(data["master"]))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(data["musica"]))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(data["sfx"]))



# ---------------------------------------------------------
#   INPUT (VOLVER ATRÁS)
# ---------------------------------------------------------
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):

		if $OpcionesVentana.visible:
			_on_volver_pressed()

		elif $FondoOscuro.visible and $FondoOscuro/MenuSlots.visible:
			_on_volver_load_pressed()
