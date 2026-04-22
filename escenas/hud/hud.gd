extends CanvasLayer

@onready var mensaje_label := $MensajeGuardado
@onready var quote_overlay := $QuoteOverlay
@onready var quote_label := $QuoteOverlay/QuoteLabel
@onready var danger_overlay := $DangerOverlay
@onready var cinematic := $Cinematic
@onready var cinematic_image := $Cinematic/Image
@onready var cinematic_text := $Cinematic/Text
@onready var death_menu := $DeathMenu
@onready var btn_retry := $DeathMenu/Panel/VBoxContainer/RetryButton
@onready var btn_menu := $DeathMenu/Panel/VBoxContainer/MenuButton

var _death_menu_open := false
var _quote_tween: Tween = null
var _danger_tween: Tween = null
var _cinematic_running := false

func _ready() -> void:
	var tree := get_tree()
	if tree.has_signal("current_scene_changed"):
		tree.connect("current_scene_changed", Callable(self, "_on_scene_changed"))
	elif tree.has_signal("scene_changed"):
		tree.connect("scene_changed", Callable(self, "_on_scene_changed"))
	else:
		tree.connect("tree_changed", Callable(self, "_on_scene_changed"))
	_on_scene_changed()

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

func mostrar_cita(texto: String, hold_seconds: float = 2.6, fade_in_seconds: float = 1.0, fade_out_seconds: float = 1.0) -> void:
	if _death_menu_open:
		return
	if _quote_tween:
		_quote_tween.kill()
		_quote_tween = null

	var player = get_tree().get_first_node_in_group("Skerney")
	var locked_player := false
	var prev_can_move := true

	if player != null and player.has_method("get"):
		var can_move_value = player.get("can_move")
		if typeof(can_move_value) == TYPE_BOOL:
			prev_can_move = can_move_value
			if prev_can_move:
				player.can_move = false
				player.input_vector = Vector2.ZERO
				player.velocity = Vector2.ZERO
				locked_player = true

	quote_label.text = texto
	quote_overlay.visible = true
	quote_overlay.modulate.a = 0.0

	_quote_tween = create_tween()
	_quote_tween.tween_property(quote_overlay, "modulate:a", 1.0, fade_in_seconds)
	_quote_tween.tween_interval(hold_seconds)
	_quote_tween.tween_property(quote_overlay, "modulate:a", 0.0, fade_out_seconds)
	await _quote_tween.finished

	quote_overlay.visible = false
	_quote_tween = null

	if locked_player and player != null and is_instance_valid(player) and not _death_menu_open:
		var is_dead_value = false
		if player.has_method("get"):
			var v = player.get("is_dead")
			if typeof(v) == TYPE_BOOL:
				is_dead_value = v
		if is_dead_value:
			return
		player.can_move = prev_can_move


func mostrar_peligro(hold_seconds: float = 0.7, peak_alpha: float = 0.35, fade_in_seconds: float = 0.08, fade_out_seconds: float = 0.35) -> void:
	if danger_overlay == null:
		return
	if _danger_tween:
		_danger_tween.kill()
		_danger_tween = null

	danger_overlay.visible = true
	danger_overlay.modulate.a = 0.0

	_danger_tween = create_tween()
	_danger_tween.tween_property(danger_overlay, "modulate:a", peak_alpha, fade_in_seconds)
	_danger_tween.tween_interval(hold_seconds)
	_danger_tween.tween_property(danger_overlay, "modulate:a", 0.0, fade_out_seconds)
	_danger_tween.finished.connect(func():
		danger_overlay.visible = false
		_danger_tween = null
	)


func mostrar_texto_final(texto: String, hold_seconds: float = 1.6, fade_in_seconds: float = 0.5, fade_out_seconds: float = 0.7) -> void:
	if _quote_tween:
		_quote_tween.kill()
		_quote_tween = null
	quote_label.text = texto
	quote_overlay.visible = true
	quote_overlay.modulate.a = 0.0

	_quote_tween = create_tween()
	_quote_tween.tween_property(quote_overlay, "modulate:a", 1.0, fade_in_seconds)
	_quote_tween.tween_interval(hold_seconds)
	_quote_tween.tween_property(quote_overlay, "modulate:a", 0.0, fade_out_seconds)
	await _quote_tween.finished

	quote_overlay.visible = false
	_quote_tween = null


func reproducir_cinematica_intro() -> void:
	if _cinematic_running:
		return
	_cinematic_running = true
	if cinematic == null or cinematic_image == null or cinematic_text == null:
		_cinematic_running = false
		return

	var slides := [
		{"path": "res://assets/images/cinematica/Cinematica1.png", "text": "Hace mucho tiempo, dos reinos entraron en guerra. El cielo ardía y la tierra temblaba bajo el choque de ejércitos."},
		{"path": "res://assets/images/cinematica/Cinematica2.png", "text": "El reino malvado tenía a su guerrero más temido: una sombra en armadura negra, portador de un mandoble maldito."},
		{"path": "res://assets/images/cinematica/Cinematica3.png", "text": "El reino defensor alzó a su héroe. Con determinación, juró frenar la masacre y proteger lo que quedaba."},
		{"path": "res://assets/images/cinematica/Cinematica4.png", "text": "La batalla se volvió un caos interminable. Entre fuego y ceniza, ambos rivales se buscaron en medio del campo."},
		{"path": "res://assets/images/cinematica/Cinematica5.png", "text": "Cuando al fin se encontraron, el acero chocó con furia. El guerrero oscuro llevaba la ventaja y el héroe retrocedía."},
		{"path": "res://assets/images/cinematica/Cinematica6.png", "text": "Sin otra salida, el héroe invocó un hechizo prohibido. Su sacrificio derrotó al guerrero… pero el mundo pagó el precio."},
		{"path": "res://assets/images/cinematica/Cinematica7.png", "text": "La luz se apagó. El sol desapareció. Una noche eterna cayó sobre la tierra, y la oscuridad se volvió hogar de monstruos."},
		{"path": "res://assets/images/cinematica/Cinematica8.png", "text": "Criaturas hambrientas surgieron de la sombra. Durante décadas, el mundo se volvió hostil e implacable."},
		{"path": "res://assets/images/cinematica/Cinematica9.png", "text": "Pero en lo profundo de una mazmorra, una pequeña alma azul despertó… guiada por una voz que nadie podía ver."},
		{"path": "res://assets/images/cinematica/Cinematica10.png", "text": "Esa luz encontró un cuerpo olvidado: un esqueleto, una espada… y un destino. La aventura comienza ahora."}
	]

	cinematic.visible = true
	cinematic.modulate.a = 0.0
	cinematic_text.text = ""
	cinematic_image.texture = null
	await _cinematic_fade_to(1.0, 0.6)

	for s in slides:
		await _cinematic_fade_to(0.0, 0.35)
		var tex := _load_cinematic_texture(s.get("path", ""))
		cinematic_image.texture = tex
		cinematic_text.text = str(s.get("text", ""))
		await _cinematic_fade_to(1.0, 0.35)
		await _wait_cinematic_advance(_cinematic_hold_seconds(cinematic_text.text))

	await _cinematic_fade_to(0.0, 0.5)
	cinematic.visible = false
	_cinematic_running = false


func _cinematic_hold_seconds(texto: String) -> float:
	var chars := texto.length()
	var s := 2.4 + float(chars) / 18.0
	return clampf(s, 6.0, 12.0)


func _cinematic_fade_to(alpha: float, seconds: float) -> void:
	if cinematic == null:
		return
	var tween := create_tween()
	tween.tween_property(cinematic, "modulate:a", alpha, seconds)
	await tween.finished


func _wait_cinematic_advance(hold_seconds: float) -> void:
	var start_ms := Time.get_ticks_msec()
	var hold_ms := int(hold_seconds * 1000.0)
	var min_skip_ms := 350
	while true:
		var now := Time.get_ticks_msec()
		if now - start_ms >= hold_ms:
			return
		if now - start_ms >= min_skip_ms and Input.is_action_just_pressed("action_button"):
			return
		await get_tree().process_frame


func _load_cinematic_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if not ResourceLoader.exists(path):
		return null
	var res = ResourceLoader.load(path)
	if res is Texture2D:
		return res as Texture2D
	return null


func _wait_for_player_movable(timeout_seconds: float = 3.0) -> Node:
	var player := get_tree().get_first_node_in_group("Skerney")
	var elapsed := 0.0
	while elapsed < timeout_seconds:
		if player == null or not is_instance_valid(player):
			player = get_tree().get_first_node_in_group("Skerney")
		if player != null and player.has_method("get"):
			var can_move_value = player.get("can_move")
			var is_dead_value = player.get("is_dead")
			if typeof(is_dead_value) == TYPE_BOOL and is_dead_value:
				return player
			if typeof(can_move_value) == TYPE_BOOL and can_move_value:
				return player
		await get_tree().process_frame
		elapsed += 1.0 / float(Engine.get_frames_per_second() if Engine.get_frames_per_second() > 0 else 60)
	return player

func _on_scene_changed(scene_root: Node = null) -> void:
	if scene_root == null:
		scene_root = get_tree().current_scene
	if scene_root == null:
		return
	if (scene_root as Node).scene_file_path.ends_with("res://escenas/sala_puzzle/sala_puzzle.tscn"):
		if ControladorPartida.temp_data.get("last_door_id", "") == "puzzle_to_pasillo" and not ControladorPartida.temp_data.get("puzzle_looping", false):
			ControladorPartida.temp_data["puzzle_stage_santayana_puzzle"] = 0
		_update_puzzle_candles(scene_root)
		if ControladorPartida.temp_data.get("quote_santayana_seen", false):
			return
		ControladorPartida.temp_data["quote_santayana_seen"] = true
		await _wait_for_player_movable()
		await get_tree().create_timer(0.05).timeout
		mostrar_cita("Quien no recuerda el pasado está condenado a repetirlo.\n— George Santayana")


func _update_puzzle_candles(scene_root: Node) -> void:
	var candle_right: Node = get_tree().get_first_node_in_group("PuzzleVelaDerecha")
	var candle_left: Node = get_tree().get_first_node_in_group("PuzzleVelaIzquierda")

	if candle_right == null:
		candle_right = scene_root.get_node_or_null("VelaDerecha")
	if candle_left == null:
		candle_left = scene_root.get_node_or_null("VelaIzquierda")

	if candle_right == null or candle_left == null:
		return

	var stage := int(ControladorPartida.temp_data.get("puzzle_stage_santayana_puzzle", 0))
	candle_right.visible = stage >= 1
	candle_left.visible = stage >= 2

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
