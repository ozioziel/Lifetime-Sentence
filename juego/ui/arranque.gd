extends Control
## Arranque: advertencias de fotosensibilidad y de contenido (C-22) y paso al menú.
## Se pueden pasar pulsando cualquier tecla o botón.

const PANTALLAS := [
	["ADVERTENCIA DE FOTOSENSIBILIDAD",
		"Este juego contiene luces parpadeantes, destellos y cambios bruscos de imagen que pueden provocar ataques a personas con epilepsia fotosensible.\n\nSi notas mareo, visión alterada, tics, desorientación o pérdida de consciencia, deja de jugar de inmediato y consulta a un médico."],
	["ADVERTENCIA DE CONTENIDO",
		"Lifetime Sentence es una ficción de terror psicológico para público adulto.\n\nContiene violencia, sangre, cadáveres, personas ahorcadas, amenazas, tortura psicológica y un escenario explícito (gore).\n\nTodos los personajes, lugares e instituciones son ficticios."],
	["", "Se recomienda jugar con auriculares y a oscuras."],
]

var _saltar := false


func _ready() -> void:
	theme = Interfaz.tema
	var fondo := ColorRect.new()
	fondo.color = Color.BLACK
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--nivel=") or argumento.begins_with("--recorrido=") \
				or argumento.begins_with("--capturas=") or argumento.begins_with("--benchmark="):
			return
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	await get_tree().create_timer(0.6).timeout
	for p in PANTALLAS:
		await _mostrar(p[0], p[1])
	Settings.establecer(&"advertencias_vistas", true)
	get_tree().change_scene_to_file(Juego.MENU)


func _input(evento: InputEvent) -> void:
	if (evento is InputEventKey or evento is InputEventJoypadButton or evento is InputEventMouseButton) \
			and evento.is_pressed():
		_saltar = true


func _mostrar(titulo: String, texto: String) -> void:
	var caja := VBoxContainer.new()
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_theme_constant_override(&"separation", 26)
	add_child(caja)
	if titulo != "":
		var t: Label = Interfaz.etiqueta(titulo, 30, Color(0.75, 0.14, 0.1))
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.add_theme_constant_override(&"outline_size", 0)
		caja.add_child(t)
	var c: Label = Interfaz.etiqueta(texto, 22, Color(0.78, 0.75, 0.68))
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	c.custom_minimum_size = Vector2(860, 0)
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	c.add_theme_constant_override(&"outline_size", 0)
	caja.add_child(c)
	caja.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(caja, "modulate:a", 1.0, 0.9)
	await tw.finished
	_saltar = false
	var t := 0.0
	var minimo := 1.2 if titulo != "" else 0.6
	var maximo := 9.0 if titulo != "" else 2.6
	while t < maximo and not (_saltar and t > minimo):
		await get_tree().process_frame
		t += get_process_delta_time()
	tw = create_tween()
	tw.tween_property(caja, "modulate:a", 0.0, 0.7)
	await tw.finished
	caja.queue_free()
