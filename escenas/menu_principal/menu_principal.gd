extends Control

func _ready():
	# Mostrar o no el botón Continuar
	$VBoxContainer/CargarPartida.visible = ControladorPartida.has_any_save()

	# Ocultar ventanas al inicio
	$OpcionesVentana.visible = false
	$FondoOscuro.visible = false
	$FondoOscuro/MenuSlots.visible = false
	
	#Carga los ajustes de sonido
	cargar_ajustes()
	
	#El botón de nueva partida al ser el primero, queda seleccionado
	$VBoxContainer/NuevaPartida.grab_focus()




# ---------------------------------------------------------
#   NUEVA PARTIDA
# ---------------------------------------------------------
func _on_nueva_partida_pressed():
	get_tree().change_scene_to_file("res://escenas/juego/juego.tscn")


# ---------------------------------------------------------
#   CONTINUAR
# ---------------------------------------------------------
func _on_continuar_pressed():
	# Ocultar botones del menú
	$VBoxContainer.visible = false

	# Mostrar fondo oscuro y slots
	$FondoOscuro.visible = true
	$MenuSlots.visible = true

	cargar_slot(1, $MenuSlots/Slot1)
	cargar_slot(2, $MenuSlots/Slot2)
	cargar_slot(3, $MenuSlots/Slot3)


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
#   BOTÓN VOLVER
# ---------------------------------------------------------
func _on_volver_pressed():
	$OpcionesVentana.visible = false
	$VBoxContainer.visible = true
	$VBoxContainer/Opciones.grab_focus()



# ---------------------------------------------------------
#   CARGAR SLOT
# ---------------------------------------------------------
func cargar_slot(slot: int, nodo_slot: Control):
	if ControladorPartida.slot_exists(slot):
		var data = ControladorPartida.load_game(slot)
		nodo_slot.get_node("Miniatura").texture = ControladorPartida.load_thumbnail(slot)
		nodo_slot.get_node("Datos/Fecha").text = data["timestamp"]
		nodo_slot.get_node("Datos/Tiempo").text = str(data["play_time"] / 60) + " min"
		nodo_slot.get_node("Datos/Vidas").text = str(data["lives"])
	else:
		nodo_slot.get_node("Miniatura").texture = null
		nodo_slot.get_node("Datos/Fecha").text = "Vacío"
		nodo_slot.get_node("Datos/Tiempo").text = ""
		nodo_slot.get_node("Datos/Vidas").text = ""
		


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
		return  # No hay archivo aún

	var file = FileAccess.open("user://ajustes.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if data == null:
		return

	# Aplicar valores a los sliders
	$OpcionesVentana/Panel/VBoxContainer/HBox_Maestro/HSliderMaestro.value = data["master"]
	$OpcionesVentana/Panel/VBoxContainer/HBox_Musica/HSliderMusica.value = data["musica"]
	$OpcionesVentana/Panel/VBoxContainer/HBox_SFX/HSliderSFX.value = data["sfx"]

	# Aplicar valores a los buses
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(data["master"]))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(data["musica"]))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(data["sfx"]))


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		
		# Si estás en opciones → volver al menú
		if $OpcionesVentana.visible:
			_on_volver_pressed()
			
		# Si estás en los slots → volver al menú
		elif $FondoOscuro.visible and $MenuSlots.visible:
			$FondoOscuro.visible = false
			$MenuSlots.visible = false
			$VBoxContainer.visible = true
			$VBoxContainer/Continuar.grab_focus()
