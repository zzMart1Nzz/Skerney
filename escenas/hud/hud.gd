extends CanvasLayer

@onready var mensaje_label := $MensajeGuardado
@onready var quote_overlay := $QuoteOverlay
@onready var quote_label := $QuoteOverlay/QuoteLabel
@onready var danger_overlay := $DangerOverlay
@onready var music_player := $MusicPlayer
@onready var cinematic := $Cinematic
@onready var cinematic_image := $Cinematic/Image
@onready var cinematic_text_bg := $Cinematic/TextBg
@onready var cinematic_text := $Cinematic/Text
@onready var cinematic_flash := $Cinematic/FlashWhite
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
		{"path": "res://assets/images/cinematica/cinematica_inicial/Cinematica1.png", "text": "Hace mucho tiempo, dos reinos entraron en guerra. El cielo ardía y la tierra temblaba bajo el choque de ejércitos."},
		{"path": "res://assets/images/cinematica/cinematica_inicial/Cinematica2.png", "text": "El reino malvado tenía a su guerrero más temido: una sombra en armadura negra, portador de un mandoble maldito."},
		{"path": "res://assets/images/cinematica/cinematica_inicial/Cinematica3.png", "text": "El reino defensor alzó a su héroe. Con determinación, juró frenar la masacre y proteger lo que quedaba."},
		{"path": "res://assets/images/cinematica/cinematica_inicial/Cinematica4.png", "text": "La batalla se volvió un caos interminable. Entre fuego y ceniza, ambos rivales se buscaron en medio del campo."},
		{"path": "res://assets/images/cinematica/cinematica_inicial/Cinematica5.png", "text": "Cuando al fin se encontraron, el acero chocó con furia. El guerrero oscuro llevaba la ventaja y el héroe retrocedía."},
		{"path": "res://assets/images/cinematica/cinematica_inicial/Cinematica6.png", "text": "Sin otra salida, el héroe invocó un hechizo prohibido. Su sacrificio derrotó al guerrero… pero el mundo pagó el precio."},
		{"path": "res://assets/images/cinematica/cinematica_inicial/Cinematica7.png", "text": "La luz se apagó. El sol desapareció. Una noche eterna cayó sobre la tierra, y la oscuridad se volvió hogar de monstruos."},
		{"path": "res://assets/images/cinematica/cinematica_inicial/Cinematica8.png", "text": "Criaturas hambrientas surgieron de la sombra. Durante décadas, el mundo se volvió hostil e implacable."},
		{"path": "res://assets/images/cinematica/cinematica_inicial/Cinematica9.png", "text": "Pero en lo profundo de una mazmorra, una pequeña alma azul despertó… guiada por una voz que nadie podía ver."},
		{"path": "res://assets/images/cinematica/cinematica_inicial/Cinematica10.png", "text": "Esa luz encontró un cuerpo olvidado: un esqueleto, una espada… y un destino. La aventura comienza ahora."}
	]

	cinematic.visible = true
	cinematic_text.text = ""
	cinematic_image.texture = null
	cinematic_image.modulate.a = 0.0
	cinematic_text.modulate.a = 0.0
	if cinematic_text_bg != null:
		cinematic_text_bg.modulate.a = 0.0
	await get_tree().process_frame
	_cinematic_reset_transform()
	await _cinematic_fade_content_to(1.0, 0.6)

	for i in range(slides.size()):
		var s = slides[i]
		var dir := _cinematic_dir_for_slide(i)
		await _cinematic_transition_out(0.45, dir)
		var tex := _load_cinematic_texture(s.get("path", ""))
		cinematic_image.texture = tex
		cinematic_text.text = str(s.get("text", ""))
		await _cinematic_transition_in(0.45, dir)
		var hold := _cinematic_hold_seconds(cinematic_text.text)
		var motion := _cinematic_start_motion(hold, dir)
		await _wait_cinematic_advance(hold)
		if motion != null:
			motion.kill()

	await _cinematic_transition_out(0.7, Vector2.DOWN)
	cinematic.visible = false
	_cinematic_running = false


func reproducir_cinematica_salida() -> void:
	if _cinematic_running:
		return
	_cinematic_running = true
	if cinematic == null or cinematic_image == null:
		_cinematic_running = false
		return

	cinematic.visible = true
	var restore_text_bg_visible := false
	var restore_text_visible := false
	if cinematic_text_bg != null:
		restore_text_bg_visible = cinematic_text_bg.visible
		cinematic_text_bg.visible = false
		cinematic_text_bg.modulate.a = 0.0
	if cinematic_text != null:
		restore_text_visible = cinematic_text.visible
		cinematic_text.visible = false
		cinematic_text.text = ""
		cinematic_text.modulate.a = 0.0
	if cinematic_flash != null:
		cinematic_flash.modulate.a = 0.0

	var p1 := "res://assets/images/cinematica/cinematica_salida_mazmorra_1/Cinematica11.png"
	var p2 := "res://assets/images/cinematica/cinematica_salida_mazmorra_1/Cinematica12.png"
	cinematic_image.texture = _load_cinematic_texture(p1)
	cinematic_image.modulate.a = 0.0
	await _cinematic_fade_image_to(1.0, 0.35)
	await _wait_cinematic_advance(6.5)

	if cinematic_flash != null:
		var ft := create_tween()
		ft.tween_property(cinematic_flash, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		ft.tween_callback(func():
			cinematic_image.texture = _load_cinematic_texture(p2)
		)
		ft.tween_property(cinematic_flash, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await ft.finished
	else:
		cinematic_image.texture = _load_cinematic_texture(p2)

	await _wait_cinematic_advance(6.5)
	await _cinematic_fade_image_to(0.0, 0.5)
	cinematic.visible = false
	_cinematic_running = false
	if cinematic_text_bg != null:
		cinematic_text_bg.visible = restore_text_bg_visible
	if cinematic_text != null:
		cinematic_text.visible = restore_text_visible


func _cinematic_fade_image_to(alpha: float, seconds: float) -> void:
	if cinematic_image == null:
		return
	var tween := create_tween()
	tween.tween_property(cinematic_image, "modulate:a", alpha, seconds)
	await tween.finished


func reproducir_cinematica_trailer() -> void:
	if _cinematic_running:
		return
	_cinematic_running = true
	if cinematic == null or cinematic_image == null or cinematic_text == null:
		_cinematic_running = false
		return

	cinematic.visible = true
	if cinematic_text_bg != null:
		cinematic_text_bg.visible = true
	cinematic_text.visible = true
	cinematic_text.text = ""
	cinematic_image.texture = null
	cinematic_image.modulate.a = 0.0
	cinematic_text.modulate.a = 0.0
	if cinematic_text_bg != null:
		cinematic_text_bg.modulate.a = 0.0
	if cinematic_flash != null:
		cinematic_flash.modulate.a = 0.0

	var slides := [
		{"path": "res://assets/images/cinematica/trailer/trailer1.png", "text": "¡Atrás!"},
		{"path": "res://assets/images/cinematica/trailer/trailer2.png", "text": "¡Cuidado, hija… sepárate de él!"},
		{"path": "res://assets/images/cinematica/trailer/trailer3.png", "text": "No tengas miedo… estás a salvo."},
		{"path": "res://assets/images/cinematica/trailer/trailer4.png", "text": "Estos recuerdos… ¿por qué duelen tanto?"},
		{"path": "res://assets/images/cinematica/trailer/trailer5.png", "text": "Te estaré esperando… viejo amigo…"}
	]

	await get_tree().process_frame
	_cinematic_reset_transform()
	await _cinematic_fade_content_to(1.0, 0.6)
	for i in range(slides.size()):
		var s = slides[i]
		var dir := _cinematic_dir_for_slide(i)
		await _cinematic_transition_out(0.45, dir)
		cinematic_image.texture = _load_cinematic_texture(str(s.get("path", "")))
		cinematic_text.text = str(s.get("text", ""))
		await _cinematic_transition_in(0.45, dir)
		var hold := _cinematic_hold_seconds(cinematic_text.text)
		var motion := _cinematic_start_motion(hold, dir)
		await _wait_cinematic_advance(hold)
		if motion != null:
			motion.kill()
	await _cinematic_transition_out(0.8, Vector2.RIGHT)

	cinematic.visible = false
	_cinematic_running = false


func _cinematic_reset_transform() -> void:
	if cinematic_image == null:
		return
	cinematic_image.pivot_offset = cinematic_image.size * 0.5
	cinematic_image.rotation = 0.0
	cinematic_image.scale = Vector2.ONE
	cinematic_image.position = Vector2.ZERO


func _cinematic_dir_for_slide(i: int) -> Vector2:
	var m := i % 3
	if m == 0:
		return Vector2.RIGHT
	if m == 1:
		return Vector2.DOWN
	return Vector2.LEFT


func _cinematic_rot_deg_for_dir(dir: Vector2) -> float:
	if dir.x > 0.5:
		return 10.0
	if dir.x < -0.5:
		return -10.0
	if dir.y > 0.5:
		return 6.0
	return 0.0


func _cinematic_offset_for_dir(dir: Vector2, amount: float) -> Vector2:
	if dir == Vector2.ZERO:
		return Vector2.ZERO
	return dir.normalized() * amount


func _cinematic_transition_out(seconds: float, dir: Vector2) -> void:
	if cinematic_image == null or cinematic_text == null:
		return
	var rot := deg_to_rad(_cinematic_rot_deg_for_dir(dir))
	var off := _cinematic_offset_for_dir(dir, 30.0)
	var tween := create_tween()
	tween.tween_property(cinematic_image, "modulate:a", 0.0, seconds)
	tween.parallel().tween_property(cinematic_image, "rotation", rot, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(cinematic_image, "position", off, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(cinematic_image, "scale", Vector2.ONE * 1.03, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(cinematic_text, "modulate:a", 0.0, seconds)
	if cinematic_text_bg != null:
		tween.parallel().tween_property(cinematic_text_bg, "modulate:a", 0.0, seconds)
	await tween.finished


func _cinematic_transition_in(seconds: float, dir: Vector2) -> void:
	if cinematic_image == null or cinematic_text == null:
		return
	var rot := deg_to_rad(_cinematic_rot_deg_for_dir(dir))
	var off := _cinematic_offset_for_dir(dir, 30.0)
	cinematic_image.rotation = -rot
	cinematic_image.position = -off
	cinematic_image.scale = Vector2.ONE * 1.03
	var tween := create_tween()
	tween.tween_property(cinematic_image, "modulate:a", 1.0, seconds)
	tween.parallel().tween_property(cinematic_image, "rotation", 0.0, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(cinematic_image, "position", Vector2.ZERO, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(cinematic_image, "scale", Vector2.ONE, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(cinematic_text, "modulate:a", 1.0, seconds)
	if cinematic_text_bg != null:
		tween.parallel().tween_property(cinematic_text_bg, "modulate:a", 1.0, seconds)
	await tween.finished


func _cinematic_start_motion(hold_seconds: float, dir: Vector2) -> Tween:
	if cinematic_image == null:
		return null
	var d := dir
	if d == Vector2.ZERO:
		d = Vector2.RIGHT
	var off := _cinematic_offset_for_dir(d, 18.0)
	var rot := deg_to_rad(_cinematic_rot_deg_for_dir(d) * 0.35)
	var t := create_tween()
	t.tween_property(cinematic_image, "position", off, hold_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.parallel().tween_property(cinematic_image, "scale", Vector2.ONE * 1.06, hold_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.parallel().tween_property(cinematic_image, "rotation", rot, hold_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return t


func _cinematic_hold_seconds(texto: String) -> float:
	var chars := texto.length()
	var s := 2.4 + float(chars) / 18.0
	return clampf(s, 6.0, 12.0)


func _cinematic_fade_content_to(alpha: float, seconds: float) -> void:
	if cinematic_image == null or cinematic_text == null:
		return
	var tween := create_tween()
	tween.tween_property(cinematic_image, "modulate:a", alpha, seconds)
	tween.parallel().tween_property(cinematic_text, "modulate:a", alpha, seconds)
	if cinematic_text_bg != null:
		tween.parallel().tween_property(cinematic_text_bg, "modulate:a", alpha, seconds)
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
	await get_tree().process_frame
	_sync_music_from_scene(scene_root)
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


func _sync_music_from_scene(scene_root: Node) -> void:
	if music_player == null or scene_root == null:
		return

	var scene_music = _find_scene_music_player(scene_root)
	if scene_music == null:
		return

	var stream = scene_music.stream
	if stream == null:
		return

	var pos := 0.0
	if scene_music.playing:
		pos = scene_music.get_playback_position()

	if music_player.stream == stream:
		if not music_player.playing:
			music_player.volume_db = scene_music.volume_db
			music_player.play(pos)
	else:
		music_player.stop()
		music_player.stream = stream
		music_player.volume_db = scene_music.volume_db
		music_player.play(pos)

	scene_music.autoplay = false
	scene_music.stop()


func _find_scene_music_player(root: Node) -> AudioStreamPlayer2D:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is AudioStreamPlayer2D:
			var p := n as AudioStreamPlayer2D
			if p.bus == &"Music":
				return p
		for c in n.get_children():
			if c is Node:
				stack.push_back(c)
	return null


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
