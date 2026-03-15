extends Control

func _ready():
	$VBoxContainer/Continuar.visible = ControladorPartida.has_any_save()

func _on_Continuar_pressed():
	$FondoOscuro.visible = true
	$FondoOscuro/MenuSlots.visible = true

	cargar_slot(1, $FondoOscuro/MenuSlots/Slot1)
	cargar_slot(2, $FondoOscuro/MenuSlots/Slot2)
	cargar_slot(3, $FondoOscuro/MenuSlots/Slot3)

func cargar_slot(slot: int, nodo_slot: Control):
	if ControladorPartida.slot_exists(slot):
		var data = ControladorPartida.load_game(slot)
		nodo_slot.get_node("Miniatura").texture = ControladorPartida.load_thumbnail(slot)
		nodo_slot.get_node("Datos/Fecha").text = data["timestamp"]
		nodo_slot.get_node("Datos/Tiempo").text = str(data["play_time"] / 60) + " min"
		nodo_slot.get_node("Datos/Vidas").text = str(data["lives"])
	else:
		nodo_slot.get_node("Miniatura").texture = null
		nodo_slot.get_node("Datos/Fecha").text = "Vacio"
		nodo_slot.get_node("Datos/Tiempo").text = ""
		nodo_slot.get_node("Datos/Vidas").text = ""
