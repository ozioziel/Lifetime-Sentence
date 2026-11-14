extends Control
## Teclado numérico de una cerradura de código (puzle del archivo de la Enfermería).
##
## Se escribe con el ratón, con las teclas numéricas o con el mando. Al completar las
## cifras se comprueba. Lo crea Interfaz.teclado_codigo(codigo, titulo).

signal terminado(correcto: bool)

var codigo := "0000"
var titulo := ""
var interfaz: Node

var _escrito := ""
var _pantalla: Label
var _acabado := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -190
	panel.offset_right = 190
	panel.offset_top = -270
	panel.offset_bottom = 270
	add_child(panel)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override(&"separation", 12)
	panel.add_child(caja)
	if titulo != "":
		var t: Label = interfaz.etiqueta(titulo, 18, Color(0.6, 0.57, 0.5))
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caja.add_child(t)
	_pantalla = interfaz.etiqueta("", 44, Color(0.85, 0.3, 0.2), true)
	_pantalla.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.02, 0.03, 0.02)
	fondo.set_content_margin_all(8)
	_pantalla.add_theme_stylebox_override(&"normal", fondo)
	caja.add_child(_pantalla)
	var rejilla := GridContainer.new()
	rejilla.columns = 3
	rejilla.add_theme_constant_override(&"h_separation", 10)
	rejilla.add_theme_constant_override(&"v_separation", 10)
	caja.add_child(rejilla)
	var primero: Button = null
	for t in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "←", "0", "×"]:
		var b := Button.new()
		b.text = t
		b.custom_minimum_size = Vector2(100, 70)
		b.focus_mode = Control.FOCUS_ALL
		b.add_theme_font_size_override(&"font_size", 30)
		b.add_theme_font_override(&"font", interfaz.fuente_mono)
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color(0.14, 0.13, 0.12)
		estilo.border_color = Color(0.3, 0.28, 0.24)
		estilo.set_border_width_all(2)
		b.add_theme_stylebox_override(&"normal", estilo)
		var foco := estilo.duplicate() as StyleBoxFlat
		foco.border_color = Color(0.85, 0.25, 0.2)
		b.add_theme_stylebox_override(&"focus", foco)
		b.add_theme_stylebox_override(&"hover", foco)
		b.add_theme_stylebox_override(&"pressed", foco)
		var valor: String = t
		b.pressed.connect(func() -> void: _pulsar(valor))
		rejilla.add_child(b)
		if primero == null:
			primero = b
	var ayuda: Label = interfaz.etiqueta("Esc / B: salir", 15, Color(0.5, 0.48, 0.44))
	ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(ayuda)
	_refrescar()
	primero.grab_focus()


func _input(evento: InputEvent) -> void:
	if _acabado:
		return
	if evento.is_action_pressed(&"pausa") or evento.is_action_pressed(&"ui_cancel"):
		_acabado = true
		terminado.emit(false)
		get_viewport().set_input_as_handled()
		return
	var tecla := evento as InputEventKey
	if tecla and tecla.pressed and not tecla.echo:
		if tecla.unicode >= 48 and tecla.unicode <= 57:
			_pulsar(char(tecla.unicode))
			get_viewport().set_input_as_handled()
		elif tecla.keycode == KEY_BACKSPACE:
			_pulsar("←")
			get_viewport().set_input_as_handled()


func _pulsar(t: String) -> void:
	if _acabado:
		return
	Audio.efecto(&"teclado_tecla", -6.0, randf_range(0.95, 1.05))
	match t:
		"←":
			_escrito = _escrito.substr(0, maxi(_escrito.length() - 1, 0))
		"×":
			_acabado = true
			terminado.emit(false)
			return
		_:
			if _escrito.length() < codigo.length():
				_escrito += t
	_refrescar()
	if _escrito.length() == codigo.length():
		_comprobar()


func _comprobar() -> void:
	if _escrito == codigo:
		_acabado = true
		_pantalla.add_theme_color_override(&"font_color", Color(0.4, 0.85, 0.4))
		Audio.efecto(&"teclado_ok", -2.0)
		terminado.emit(true)
		return
	Audio.efecto(&"teclado_error", -2.0)
	_pantalla.add_theme_color_override(&"font_color", Color(1.0, 0.1, 0.05))
	await get_tree().create_timer(0.6, true, false, true).timeout
	_pantalla.add_theme_color_override(&"font_color", Color(0.85, 0.3, 0.2))
	_escrito = ""
	_refrescar()


func _refrescar() -> void:
	var texto := ""
	for i in codigo.length():
		texto += (_escrito[i] if i < _escrito.length() else "_") + " "
	_pantalla.text = texto.strip_edges()
