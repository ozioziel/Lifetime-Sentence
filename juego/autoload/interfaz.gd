extends CanvasLayer
## Interfaz del juego (autoload «Interfaz»).
##
## Se dibuja a la resolución real de la ventana, encima de la imagen PS1 de 480 x 270.
## Reúne todo lo que se ve por encima del juego:
##   - HUD mínimo (S4): punto + botón para interactuar, munición solo al apuntar,
##     mensajes cortos, objetivo y subtítulos.
##   - Rótulos de capítulo (H5), pantalla «CONTINUAR» (K3) y textos a pantalla completa.
##   - Visor de documentos (H3), pausa, opciones, ranuras de guardado y confirmaciones.
##   - Minijuegos: ganzúa (K2/K6) y teclado de código.
## Las funciones que esperan una respuesta se usan con await:
##     var abierta: bool = await Interfaz.ganzua(0.4)
##     var ranura: int = await Interfaz.elegir_ranura(true)

signal _respuesta(valor: Variant)
## Se emite al abrirse o cerrarse cualquier ventana que pausa el juego.
signal menu_cambiado(abierto: bool)

const COLOR_TEXTO := Color(0.80, 0.77, 0.70)
const COLOR_TENUE := Color(0.55, 0.53, 0.49)
const COLOR_ACENTO := Color(0.78, 0.12, 0.09)
const COLOR_PAPEL := Color(0.80, 0.76, 0.64)
const COLOR_TINTA := Color(0.14, 0.12, 0.10)
const MinijuegoGanzua := preload("res://ui/minijuego_ganzua.gd")
const TecladoCodigo := preload("res://ui/teclado_codigo.gd")

var tema: Theme
var fuente_serif: SystemFont
var fuente_mono: SystemFont
## true si lo último que se ha tocado es un mando (cambia los glifos de los avisos).
var usando_mando := false
## Modo de prueba automática (DebugTools --prueba-demo): las ventanas responden solas.
var prueba_automatica := false

var _raiz: Control
var _hud: Control
var _aviso: HBoxContainer
var _aviso_glifo: Label
var _aviso_texto: Label
var _municion: Label
var _mira: ColorRect
var _reloj: Label
var _mensaje: Label
var _objetivo: Label
var _subtitulo: Label
var _rotulo: VBoxContainer
var _negro: ColorRect
var _modal: Control = null
var _cola_subtitulos: Array = []
var _subtitulo_ocupado := false
var _tween_mensaje: Tween
var _tween_objetivo: Tween
var _pausa: Control
var _opciones: Control
var _al_cerrar_opciones: Callable


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_crear_tema()
	_raiz = Control.new()
	_raiz.name = "Raiz"
	_raiz.theme = tema
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_raiz)
	_crear_hud()
	_negro = ColorRect.new()
	_negro.color = Color.BLACK
	_negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_negro.visible = false
	_raiz.add_child(_negro)


func _input(evento: InputEvent) -> void:
	if evento is InputEventJoypadButton or (evento is InputEventJoypadMotion
			and absf((evento as InputEventJoypadMotion).axis_value) > 0.4):
		if not usando_mando:
			usando_mando = true
			_refrescar_aviso()
	elif evento is InputEventKey or evento is InputEventMouseButton:
		if usando_mando:
			usando_mando = false
			_refrescar_aviso()


func _unhandled_input(evento: InputEvent) -> void:
	if not evento.is_action_pressed(&"pausa") or evento.is_echo():
		return
	if _opciones and _opciones.visible:
		_cerrar_opciones()
	elif _pausa and _pausa.visible:
		cerrar_pausa()
	elif _puede_pausar():
		abrir_pausa()
	else:
		return
	get_viewport().set_input_as_handled()


func _puede_pausar() -> bool:
	return Juego.en_partida and not Juego.muriendo and _modal == null and not get_tree().paused


## true mientras hay una ventana abierta que espera al jugador.
func modal_activo() -> bool:
	return _modal != null or (_pausa != null and _pausa.visible) or (_opciones != null and _opciones.visible)


# --------------------------------------------------------------------- Tema ---

func _crear_tema() -> void:
	fuente_serif = SystemFont.new()
	fuente_serif.font_names = PackedStringArray(["Georgia", "Times New Roman", "Liberation Serif", "DejaVu Serif", "serif"])
	fuente_serif.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	fuente_serif.hinting = TextServer.HINTING_NONE
	fuente_mono = SystemFont.new()
	fuente_mono.font_names = PackedStringArray(["Courier New", "Courier", "Liberation Mono", "DejaVu Sans Mono", "monospace"])
	fuente_mono.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	tema = Theme.new()
	tema.default_font = fuente_serif
	tema.default_font_size = 22
	var vacio := StyleBoxEmpty.new()
	for estado in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		tema.set_stylebox(estado, "Button", vacio)
		tema.set_stylebox(estado, "CheckButton", vacio)
		tema.set_stylebox(estado, "OptionButton", vacio)
	for clase in ["Button", "CheckButton", "OptionButton"]:
		tema.set_color("font_color", clase, COLOR_TEXTO)
		tema.set_color("font_hover_color", clase, Color(0.95, 0.42, 0.36))
		tema.set_color("font_focus_color", clase, Color(1.0, 0.35, 0.28))
		tema.set_color("font_pressed_color", clase, Color(1.0, 0.5, 0.4))
		tema.set_color("font_hover_pressed_color", clase, Color(1.0, 0.5, 0.4))
		tema.set_color("font_disabled_color", clase, Color(0.35, 0.34, 0.32))
	tema.set_color("font_color", "Label", COLOR_TEXTO)
	tema.set_color("font_outline_color", "Label", Color.BLACK)
	tema.set_constant("outline_size", "Label", 4)
	tema.set_color("default_color", "RichTextLabel", COLOR_TINTA)
	var barra := StyleBoxFlat.new()
	barra.bg_color = Color(0.2, 0.19, 0.18)
	barra.content_margin_top = 3
	barra.content_margin_bottom = 3
	tema.set_stylebox("slider", "HSlider", barra)
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = COLOR_ACENTO
	relleno.content_margin_top = 3
	relleno.content_margin_bottom = 3
	tema.set_stylebox("grabber_area", "HSlider", relleno)
	tema.set_stylebox("grabber_area_highlight", "HSlider", relleno)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.03, 0.03, 0.03, 0.92)
	panel.border_color = Color(0.3, 0.06, 0.05)
	panel.set_border_width_all(1)
	panel.set_content_margin_all(24)
	tema.set_stylebox("panel", "PanelContainer", panel)
	var popup := StyleBoxFlat.new()
	popup.bg_color = Color(0.06, 0.06, 0.06)
	popup.set_content_margin_all(8)
	tema.set_stylebox("panel", "PopupMenu", popup)


## Etiqueta con la fuente y el tamaño indicados.
func etiqueta(texto: String, tamano := 22, color := COLOR_TEXTO, mono := false) -> Label:
	var e := Label.new()
	e.text = texto
	e.add_theme_font_size_override(&"font_size", tamano)
	e.add_theme_color_override(&"font_color", color)
	if mono:
		e.add_theme_font_override(&"font", fuente_mono)
	e.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return e


func boton(texto: String, al_pulsar: Callable, tamano := 26) -> Button:
	var b := Button.new()
	b.text = texto
	b.flat = true
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override(&"font_size", tamano)
	b.pressed.connect(func() -> void:
		Audio.efecto(&"ui_aceptar", -8.0)
		al_pulsar.call())
	b.focus_entered.connect(func() -> void: Audio.efecto(&"ui_mover", -14.0))
	b.mouse_entered.connect(func() -> void: b.grab_focus())
	return b


# ---------------------------------------------------------------------- HUD ---

func _crear_hud() -> void:
	_hud = Control.new()
	_hud.name = "HUD"
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_hud)

	# Aviso de interacción: punto + botón + verbo, abajo en el centro.
	_aviso = HBoxContainer.new()
	_aviso.alignment = BoxContainer.ALIGNMENT_CENTER
	_aviso.add_theme_constant_override(&"separation", 10)
	_aviso.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_aviso.offset_top = -150
	_aviso.offset_bottom = -116
	_aviso.offset_left = -300
	_aviso.offset_right = 300
	_aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var punto := etiqueta("•", 22, COLOR_TEXTO)
	_aviso.add_child(punto)
	_aviso_glifo = etiqueta("E", 18, Color(0.08, 0.08, 0.08))
	var fondo_glifo := StyleBoxFlat.new()
	fondo_glifo.bg_color = Color(0.82, 0.79, 0.72)
	fondo_glifo.set_content_margin_all(4)
	fondo_glifo.content_margin_left = 8
	fondo_glifo.content_margin_right = 8
	fondo_glifo.set_corner_radius_all(2)
	_aviso_glifo.add_theme_stylebox_override(&"normal", fondo_glifo)
	_aviso_glifo.add_theme_constant_override(&"outline_size", 0)
	_aviso_glifo.add_theme_font_override(&"font", fuente_mono)
	_aviso.add_child(_aviso_glifo)
	_aviso_texto = etiqueta("Examinar", 20)
	_aviso.add_child(_aviso_texto)
	_aviso.visible = false
	_aviso.set_meta(&"accion", &"interactuar")
	_hud.add_child(_aviso)

	_municion = etiqueta("", 26, COLOR_TEXTO, true)
	_municion.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_municion.offset_left = -260
	_municion.offset_top = -80
	_municion.offset_right = -40
	_municion.offset_bottom = -40
	_municion.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_municion.visible = false
	_hud.add_child(_municion)

	_mira = ColorRect.new()
	_mira.color = Color(0.9, 0.85, 0.78, 0.85)
	_mira.set_anchors_preset(Control.PRESET_CENTER)
	_mira.offset_left = -2
	_mira.offset_top = -2
	_mira.offset_right = 2
	_mira.offset_bottom = 2
	_mira.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mira.visible = false
	_hud.add_child(_mira)

	_reloj = etiqueta("", 34, Color(0.85, 0.2, 0.12), true)
	_reloj.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_reloj.offset_left = -200
	_reloj.offset_right = 200
	_reloj.offset_top = 26
	_reloj.offset_bottom = 70
	_reloj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reloj.visible = false
	_hud.add_child(_reloj)

	_mensaje = etiqueta("", 20)
	_mensaje.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_mensaje.offset_left = -500
	_mensaje.offset_right = 500
	_mensaje.offset_top = -210
	_mensaje.offset_bottom = -170
	_mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mensaje.modulate.a = 0.0
	_hud.add_child(_mensaje)

	_objetivo = etiqueta("", 17, COLOR_TENUE)
	_objetivo.add_theme_font_override(&"font", fuente_serif)
	_objetivo.position = Vector2(40, 34)
	_objetivo.size = Vector2(700, 30)
	_objetivo.modulate.a = 0.0
	_hud.add_child(_objetivo)

	_subtitulo = etiqueta("", 24)
	_subtitulo.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_subtitulo.offset_left = -560
	_subtitulo.offset_right = 560
	_subtitulo.offset_top = -100
	_subtitulo.offset_bottom = -30
	_subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitulo.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_subtitulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitulo.add_theme_constant_override(&"outline_size", 6)
	_subtitulo.visible = false
	_hud.add_child(_subtitulo)

	_rotulo = VBoxContainer.new()
	_rotulo.alignment = BoxContainer.ALIGNMENT_CENTER
	_rotulo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rotulo.modulate.a = 0.0
	_hud.add_child(_rotulo)


## Quita todo lo que haya en pantalla (al cambiar de nivel).
func limpiar() -> void:
	ocultar_aviso()
	_municion.visible = false
	_mira.visible = false
	_reloj.visible = false
	_mensaje.modulate.a = 0.0
	_objetivo.modulate.a = 0.0
	_cola_subtitulos.clear()
	_subtitulo.visible = false
	_negro.visible = false
	for hijo in _rotulo.get_children():
		hijo.queue_free()
	_rotulo.modulate.a = 0.0
	if _pausa:
		_pausa.visible = false
	if _opciones:
		_opciones.visible = false


func mostrar_aviso(texto: String, accion := &"interactuar") -> void:
	_aviso_texto.text = texto
	_aviso.set_meta(&"accion", accion)
	_refrescar_aviso()
	_aviso.visible = true


func ocultar_aviso() -> void:
	_aviso.visible = false


func _refrescar_aviso() -> void:
	if _aviso:
		_aviso_glifo.text = glifo(_aviso.get_meta(&"accion", &"interactuar"))


## Texto corto del botón de una acción según el dispositivo en uso.
func glifo(accion: StringName) -> String:
	if usando_mando:
		match accion:
			&"interactuar": return "A"
			&"agacharse": return "B"
			&"lanzar": return "Y"
			&"correr": return "RB"
			&"apuntar": return "LT"
			&"disparar": return "RT"
			&"pausa": return "START"
		return "A"
	if not InputMap.has_action(accion):
		return "?"
	for evento in InputMap.action_get_events(accion):
		if evento is InputEventKey:
			var e := evento as InputEventKey
			var codigo := e.physical_keycode if e.physical_keycode != KEY_NONE else e.keycode
			var real := DisplayServer.keyboard_get_keycode_from_physical(codigo)
			return OS.get_keycode_string(real if real != KEY_NONE else codigo).to_upper()
		if evento is InputEventMouseButton:
			match (evento as InputEventMouseButton).button_index:
				MOUSE_BUTTON_LEFT: return "CLIC IZQ."
				MOUSE_BUTTON_RIGHT: return "CLIC DER."
	return "?"


## Munición: solo se ve mientras se apunta (§7.1).
func mostrar_municion(visible_: bool, texto := "") -> void:
	_municion.visible = visible_
	_municion.text = texto


## Cuenta atrás en pantalla (huidas a contrarreloj, K6). Negativo = ocultarla.
func cuenta_atras(segundos: float) -> void:
	if segundos < 0.0:
		_reloj.visible = false
		return
	_reloj.visible = true
	_reloj.text = "%d:%02d" % [int(segundos) / 60, int(segundos) % 60]


## Punto central mientras se apunta (sin mira automática, §7.1).
func mostrar_mira(visible_: bool) -> void:
	_mira.visible = visible_


func mensaje(texto: String, segundos := 3.0) -> void:
	_mensaje.text = texto
	if _tween_mensaje:
		_tween_mensaje.kill()
	_tween_mensaje = create_tween()
	_tween_mensaje.tween_property(_mensaje, "modulate:a", 1.0, 0.25)
	_tween_mensaje.tween_interval(segundos)
	_tween_mensaje.tween_property(_mensaje, "modulate:a", 0.0, 0.8)


## Objetivo actual (texto pequeño arriba a la izquierda que se desvanece).
func objetivo(texto: String, segundos := 6.0) -> void:
	_objetivo.text = texto
	if _tween_objetivo:
		_tween_objetivo.kill()
	_tween_objetivo = create_tween()
	_tween_objetivo.tween_property(_objetivo, "modulate:a", 1.0, 0.6)
	_tween_objetivo.tween_interval(segundos)
	_tween_objetivo.tween_property(_objetivo, "modulate:a", 0.0, 1.5)


## Subtítulo (diálogo o voz). Se encolan. Si los subtítulos están desactivados no se
## muestran, pero la espera se respeta para que las cinemáticas mantengan su ritmo.
func subtitulo(texto: String, segundos := 3.5, quien := "") -> void:
	_cola_subtitulos.append([texto, segundos, quien])
	if not _subtitulo_ocupado:
		_mostrar_subtitulos()


## Igual que subtitulo(), pero se puede esperar a que termine: await Interfaz.decir(...)
func decir(quien: String, texto: String, segundos := 3.5) -> void:
	subtitulo(texto, segundos, quien)
	while _subtitulo_ocupado:
		await get_tree().process_frame


func _mostrar_subtitulos() -> void:
	_subtitulo_ocupado = true
	while not _cola_subtitulos.is_empty():
		var s: Array = _cola_subtitulos.pop_front()
		var texto: String = s[0]
		if s[2] != "":
			texto = "%s: %s" % [s[2], texto]
		_subtitulo.text = texto
		_subtitulo.visible = Settings.subtitulos
		await get_tree().create_timer(s[1], true, false, true).timeout
	_subtitulo.visible = false
	_subtitulo_ocupado = false


## Rótulo de capítulo (H5): «I» y «RESILIENCIA», con fundido. Se puede esperar.
func rotulo_capitulo(numero: String, titulo: String, segundos := 4.0) -> void:
	for hijo in _rotulo.get_children():
		hijo.queue_free()
	var n := etiqueta(numero, 30, COLOR_TENUE)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var t := etiqueta(titulo, 56, COLOR_TEXTO)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_constant_override(&"outline_size", 0)
	var linea := ColorRect.new()
	linea.color = COLOR_ACENTO
	linea.custom_minimum_size = Vector2(220, 2)
	linea.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_rotulo.add_child(n)
	_rotulo.add_child(t)
	_rotulo.add_child(linea)
	Audio.efecto(&"rotulo", -4.0)
	var tw := create_tween()
	tw.tween_property(_rotulo, "modulate:a", 1.0, 1.2)
	tw.tween_interval(segundos)
	tw.tween_property(_rotulo, "modulate:a", 0.0, 1.5)
	await tw.finished


## Texto grande sobre negro («FIN DE LA DEMO»). Se puede esperar.
func texto_central(texto: String, segundos := 4.0, tamano := 54, con_negro := true) -> void:
	_negro.visible = con_negro
	_negro.modulate.a = 1.0
	var e := etiqueta(texto, tamano)
	e.set_anchors_preset(Control.PRESET_FULL_RECT)
	e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	e.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	e.add_theme_constant_override(&"outline_size", 0)
	e.modulate.a = 0.0
	_raiz.add_child(e)
	var tw := create_tween()
	tw.tween_property(e, "modulate:a", 1.0, 1.5)
	tw.tween_interval(segundos)
	tw.tween_property(e, "modulate:a", 0.0, 1.5)
	await tw.finished
	e.queue_free()


func pantalla_negra(visible_: bool) -> void:
	_negro.visible = visible_
	_negro.modulate.a = 1.0


# --------------------------------------------------------------- Continuar ---

## Pantalla «CONTINUAR» tras una muerte (K3). Espera a que el jugador pulse algo.
func pantalla_continuar() -> void:
	if prueba_automatica:
		await get_tree().process_frame
		return
	var capa := _crear_modal(Color.BLACK)
	var caja := VBoxContainer.new()
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_theme_constant_override(&"separation", 18)
	capa.add_child(caja)
	var titulo := etiqueta("CONTINUAR", 64, Color(0.72, 0.1, 0.08))
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_constant_override(&"outline_size", 0)
	caja.add_child(titulo)
	var pie := etiqueta("", 18, COLOR_TENUE)
	pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(pie)
	capa.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(capa, "modulate:a", 1.0, 1.2)
	await tw.finished
	pie.text = "Pulsa %s" % glifo(&"interactuar")
	Audio.efecto(&"continuar", -6.0)
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed(&"interactuar") or Input.is_action_just_pressed(&"ui_accept") \
				or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			break
	Audio.efecto(&"ui_aceptar", -6.0)
	_cerrar_modal()


# --------------------------------------------------------------- Documentos ---

## Muestra un documento en papel. Pausa el juego hasta cerrarlo.
func mostrar_documento(titulo: String, texto: String) -> void:
	if prueba_automatica:
		await get_tree().process_frame
		return
	var capa := _crear_modal(Color(0, 0, 0, 0.82))
	var papel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = COLOR_PAPEL
	estilo.set_content_margin_all(42)
	estilo.shadow_color = Color(0, 0, 0, 0.6)
	estilo.shadow_size = 18
	papel.add_theme_stylebox_override(&"panel", estilo)
	papel.set_anchors_preset(Control.PRESET_CENTER)
	papel.custom_minimum_size = Vector2(760, 560)
	papel.offset_left = -380
	papel.offset_top = -300
	papel.offset_right = 380
	papel.offset_bottom = 300
	capa.add_child(papel)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override(&"separation", 16)
	papel.add_child(caja)
	var t := etiqueta(titulo, 22, COLOR_TINTA, true)
	t.add_theme_constant_override(&"outline_size", 0)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(t)
	var cuerpo := RichTextLabel.new()
	cuerpo.bbcode_enabled = true
	cuerpo.text = texto
	cuerpo.fit_content = false
	cuerpo.scroll_active = true
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_font_override(&"normal_font", fuente_mono)
	cuerpo.add_theme_font_size_override(&"normal_font_size", 18)
	cuerpo.add_theme_color_override(&"default_color", COLOR_TINTA)
	cuerpo.focus_mode = Control.FOCUS_ALL
	caja.add_child(cuerpo)
	var pie := etiqueta("%s  cerrar" % glifo(&"interactuar"), 15, Color(0.3, 0.27, 0.22))
	pie.add_theme_constant_override(&"outline_size", 0)
	pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	caja.add_child(pie)
	Audio.efecto(&"papel", -4.0)
	cuerpo.grab_focus()
	await get_tree().create_timer(0.25, true, false, true).timeout
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed(&"interactuar") or Input.is_action_just_pressed(&"pausa") \
				or Input.is_action_just_pressed(&"ui_cancel"):
			break
		var desplazar := Input.get_axis(&"mover_adelante", &"mover_atras")
		if absf(desplazar) > 0.3:
			cuerpo.get_v_scroll_bar().value += desplazar * 600.0 * get_process_delta_time()
	Audio.efecto(&"papel", -8.0, 0.8)
	_cerrar_modal()


# ------------------------------------------------------------------ Modales ---

func _crear_modal(fondo: Color) -> Control:
	if _modal:
		_modal.queue_free()
	var capa := ColorRect.new()
	capa.color = fondo
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.mouse_filter = Control.MOUSE_FILTER_STOP
	_raiz.add_child(capa)
	_modal = capa
	ocultar_aviso()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu_cambiado.emit(true)
	return capa


func _cerrar_modal() -> void:
	if _modal:
		_modal.queue_free()
		_modal = null
	get_tree().paused = false
	_recapturar_raton()
	menu_cambiado.emit(false)


func _recapturar_raton() -> void:
	if Juego.en_partida and not modal_activo():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Pregunta de sí o no. Devuelve true si se acepta.
func confirmar(texto: String, si := "Sí", no := "No") -> bool:
	if prueba_automatica:
		await get_tree().process_frame
		return true
	var capa := _crear_modal(Color(0, 0, 0, 0.85))
	var caja := VBoxContainer.new()
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_theme_constant_override(&"separation", 22)
	capa.add_child(caja)
	var e := etiqueta(texto, 24)
	e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	e.custom_minimum_size = Vector2(700, 0)
	e.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	caja.add_child(e)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override(&"separation", 80)
	caja.add_child(fila)
	var b_no := boton(no, func() -> void: _respuesta.emit(false))
	var b_si := boton(si, func() -> void: _respuesta.emit(true))
	fila.add_child(b_si)
	fila.add_child(b_no)
	b_no.grab_focus()
	var cancelar := _escuchar_cancelar(false)
	var valor: Variant = await _respuesta
	cancelar.call()
	_cerrar_modal()
	return valor


## Hace que Esc / B respondan [param valor]. Devuelve una función para dejar de escuchar.
func _escuchar_cancelar(valor: Variant) -> Callable:
	var activo := [true]
	var bucle := func() -> void:
		while activo[0]:
			await get_tree().process_frame
			if activo[0] and (Input.is_action_just_pressed(&"pausa") or Input.is_action_just_pressed(&"ui_cancel")):
				_respuesta.emit(valor)
				return
	bucle.call()
	return func() -> void: activo[0] = false


## Elige una de las 3 ranuras. Devuelve 1-3, o 0 si se cancela.
func elegir_ranura(para_guardar: bool) -> int:
	if prueba_automatica:
		await get_tree().process_frame
		return 3
	var capa := _crear_modal(Color(0, 0, 0, 0.88))
	var caja := VBoxContainer.new()
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_theme_constant_override(&"separation", 14)
	capa.add_child(caja)
	var titulo := etiqueta("GUARDAR PARTIDA" if para_guardar else "CARGAR PARTIDA", 34)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(titulo)
	var sub := etiqueta("Rayas una marca más en la pared." if para_guardar else "Elige una partida.", 18, COLOR_TENUE)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(sub)
	caja.add_child(Control.new())
	var primero: Button = null
	for i in range(1, Guardado.RANURAS + 1):
		var r := i
		var b := boton("Ranura %d   —   %s" % [i, Guardado.descripcion(i)], func() -> void: _respuesta.emit(r), 22)
		b.disabled = not para_guardar and not Guardado.existe(i)
		caja.add_child(b)
		if primero == null and not b.disabled:
			primero = b
	caja.add_child(Control.new())
	var volver := boton("Cancelar", func() -> void: _respuesta.emit(0), 22)
	caja.add_child(volver)
	(primero if primero else volver).grab_focus()
	var cancelar := _escuchar_cancelar(0)
	var valor: Variant = await _respuesta
	cancelar.call()
	if para_guardar and int(valor) > 0 and Guardado.existe(int(valor)):
		_cerrar_modal()
		if not await confirmar("¿Sobrescribir la ranura %d?" % int(valor)):
			return 0
		return int(valor)
	_cerrar_modal()
	return int(valor)


# ---------------------------------------------------------------- Minijuegos ---

## Ganzúa (K2). dificultad de 0 (fácil) a 1 (difícil). limite = segundos (0 = sin límite, K6).
## Devuelve true si la cerradura se abre.
func ganzua(dificultad := 0.4, limite := 0.0) -> bool:
	if prueba_automatica:
		await get_tree().create_timer(0.3).timeout
		return true
	var capa := _crear_modal(Color(0, 0, 0, 0.55))
	var juego := MinijuegoGanzua.new()
	juego.dificultad = dificultad
	juego.limite = limite
	juego.interfaz = self
	juego.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(juego)
	juego.terminado.connect(func(ok: bool) -> void: _respuesta.emit(ok))
	var valor: Variant = await _respuesta
	await get_tree().create_timer(0.35, true, false, true).timeout
	_cerrar_modal()
	return valor


## Teclado numérico. Devuelve true si se introduce [param codigo].
func teclado_codigo(codigo: String, titulo := "") -> bool:
	if prueba_automatica:
		await get_tree().process_frame
		return true
	var capa := _crear_modal(Color(0, 0, 0, 0.7))
	var teclado := TecladoCodigo.new()
	teclado.codigo = codigo
	teclado.titulo = titulo
	teclado.interfaz = self
	teclado.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(teclado)
	teclado.terminado.connect(func(ok: bool) -> void: _respuesta.emit(ok))
	var valor: Variant = await _respuesta
	await get_tree().create_timer(0.4, true, false, true).timeout
	_cerrar_modal()
	return valor


func vibrar(debil: float, fuerte: float, segundos: float) -> void:
	if Settings.vibracion_mando and usando_mando:
		for mando in Input.get_connected_joypads():
			Input.start_joy_vibration(mando, debil, fuerte, segundos)


# -------------------------------------------------------------------- Pausa ---

func abrir_pausa() -> void:
	if _pausa == null:
		_crear_pausa()
	_pausa.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ocultar_aviso()
	Audio.efecto(&"ui_pausa", -6.0)
	menu_cambiado.emit(true)
	_mostrar_menu_pausa()


func cerrar_pausa() -> void:
	if _pausa:
		_pausa.visible = false
	get_tree().paused = false
	_recapturar_raton()
	menu_cambiado.emit(false)


func _crear_pausa() -> void:
	_pausa = ColorRect.new()
	(_pausa as ColorRect).color = Color(0, 0, 0, 0.8)
	_pausa.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pausa.mouse_filter = Control.MOUSE_FILTER_STOP
	_pausa.visible = false
	_raiz.add_child(_pausa)


func _limpiar_pausa() -> VBoxContainer:
	for hijo in _pausa.get_children():
		hijo.queue_free()
	var caja := VBoxContainer.new()
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_theme_constant_override(&"separation", 12)
	_pausa.add_child(caja)
	return caja


func _mostrar_menu_pausa() -> void:
	var caja := _limpiar_pausa()
	var titulo := etiqueta("PAUSA", 40)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(titulo)
	var lugar := etiqueta(Juego.lugar_actual(), 17, COLOR_TENUE)
	lugar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(lugar)
	caja.add_child(Control.new())
	var continuar := boton("Continuar", cerrar_pausa)
	caja.add_child(continuar)
	caja.add_child(boton("Documentos", _mostrar_documentos_pausa))
	caja.add_child(boton("Objetos", _mostrar_objetos_pausa))
	caja.add_child(boton("Opciones", func() -> void: abrir_opciones(_mostrar_menu_pausa)))
	caja.add_child(boton("Volver al menú principal", _volver_al_menu))
	continuar.grab_focus()


func _mostrar_documentos_pausa() -> void:
	var caja := _limpiar_pausa()
	var titulo := etiqueta("DOCUMENTOS", 34)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(titulo)
	caja.add_child(Control.new())
	var leidos: Array = Juego.estado.get("documentos", [])
	var primero: Button = null
	if leidos.is_empty():
		var vacio := etiqueta("Aún no has leído ningún documento.", 20, COLOR_TENUE)
		vacio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caja.add_child(vacio)
	for id in leidos:
		var doc := Documentos.obtener(StringName(id))
		var b := boton(doc.get("titulo", id), func() -> void: _releer(doc), 20)
		caja.add_child(b)
		if primero == null:
			primero = b
	caja.add_child(Control.new())
	var volver := boton("Volver", _mostrar_menu_pausa, 22)
	caja.add_child(volver)
	(primero if primero else volver).grab_focus()


func _releer(doc: Dictionary) -> void:
	_pausa.visible = false
	await mostrar_documento(doc.get("titulo", ""), doc.get("texto", ""))
	# mostrar_documento despausa al cerrar: se vuelve a la pausa.
	_pausa.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_mostrar_documentos_pausa()


func _mostrar_objetos_pausa() -> void:
	var caja := _limpiar_pausa()
	var titulo := etiqueta("OBJETOS", 34)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(titulo)
	caja.add_child(Control.new())
	var lista: Array = Juego.estado.get("objetos", [])
	var lineas: PackedStringArray = []
	for id in lista:
		if Juego.OBJETOS.has(StringName(id)):
			var o: Array = Juego.OBJETOS[StringName(id)]
			lineas.append("%s — %s" % [o[0], o[1]])
	var armas := Juego.texto_armas()
	if armas != "":
		lineas.append(armas)
	if lineas.is_empty():
		lineas.append("Nada. Solo lo puesto.")
	for l in lineas:
		var e := etiqueta(l, 19, COLOR_TEXTO)
		e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		e.custom_minimum_size = Vector2(900, 0)
		e.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		caja.add_child(e)
	caja.add_child(Control.new())
	var volver := boton("Volver", _mostrar_menu_pausa, 22)
	caja.add_child(volver)
	volver.grab_focus()


func _volver_al_menu() -> void:
	_pausa.visible = false
	var si := await confirmar("¿Volver al menú principal?\nSe perderá lo que no hayas guardado en una pared.")
	if si:
		get_tree().paused = false
		Juego.volver_al_menu()
	else:
		_pausa.visible = true
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_mostrar_menu_pausa()


# ----------------------------------------------------------------- Opciones ---

## Abre las opciones. [param al_cerrar] se llama al volver (lo usan la pausa y el menú).
func abrir_opciones(al_cerrar: Callable) -> void:
	_al_cerrar_opciones = al_cerrar
	if _opciones:
		_opciones.queue_free()
	_opciones = ColorRect.new()
	(_opciones as ColorRect).color = Color(0, 0, 0, 0.92)
	_opciones.set_anchors_preset(Control.PRESET_FULL_RECT)
	_opciones.mouse_filter = Control.MOUSE_FILTER_STOP
	_raiz.add_child(_opciones)
	if _pausa:
		_pausa.visible = false
	var desplazable := ScrollContainer.new()
	desplazable.set_anchors_preset(Control.PRESET_FULL_RECT)
	desplazable.offset_left = 220
	desplazable.offset_right = -220
	desplazable.offset_top = 40
	desplazable.offset_bottom = -40
	desplazable.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_opciones.add_child(desplazable)
	var caja := VBoxContainer.new()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.add_theme_constant_override(&"separation", 8)
	desplazable.add_child(caja)
	var titulo := etiqueta("OPCIONES", 36)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(titulo)

	caja.add_child(_seccion("Sonido"))
	var primero := _deslizador(caja, "Volumen general", &"volumen_general", 0.0, 1.0)
	_deslizador(caja, "Música", &"volumen_musica", 0.0, 1.0)
	_deslizador(caja, "Ambiente", &"volumen_ambiente", 0.0, 1.0)
	_deslizador(caja, "Efectos", &"volumen_efectos", 0.0, 1.0)
	_deslizador(caja, "Voces", &"volumen_voces", 0.0, 1.0)
	_casilla(caja, "Subtítulos", &"subtitulos")

	caja.add_child(_seccion("Imagen"))
	var calidad := _fila(caja, "Calidad gráfica")
	var selector := OptionButton.new()
	selector.add_item("Baja (portátiles)", Settings.Calidad.BAJO)
	selector.add_item("Alta (niebla volumétrica, brillo)", Settings.Calidad.ALTO)
	selector.select(Settings.calidad)
	selector.item_selected.connect(func(i: int) -> void: Settings.establecer(&"calidad", i))
	selector.add_theme_font_size_override(&"font_size", 20)
	calidad.add_child(selector)
	_casilla(caja, "Pantalla completa", &"pantalla_completa")

	caja.add_child(_seccion("Control"))
	_deslizador(caja, "Sensibilidad del ratón", &"sensibilidad_raton", 0.0006, 0.006)
	_deslizador(caja, "Sensibilidad del mando", &"sensibilidad_mando", 0.8, 5.0)
	_casilla(caja, "Invertir eje vertical", &"invertir_y")
	_casilla(caja, "Agacharse: pulsar una vez (no mantener)", &"agacharse_alternar")
	_casilla(caja, "Vibración del mando", &"vibracion_mando")

	caja.add_child(_seccion("Teclas"))
	for accion: StringName in Settings.REASIGNABLES:
		_fila_tecla(caja, accion)
	caja.add_child(boton("Restaurar teclas por defecto", func() -> void:
		Settings.restaurar_controles()
		abrir_opciones(_al_cerrar_opciones), 20))
	var ayuda := etiqueta("Mando: palanca izq. moverse · palanca der. cámara · A interactuar · B agacharse · RB correr · LT apuntar · RT disparar · Y lanzar · START pausa", 15, COLOR_TENUE)
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(ayuda)
	caja.add_child(Control.new())
	var volver := boton("Volver", _cerrar_opciones, 24)
	caja.add_child(volver)
	primero.grab_focus()
	menu_cambiado.emit(true)


func _cerrar_opciones() -> void:
	if _opciones:
		_opciones.queue_free()
		_opciones = null
	if _pausa and _al_cerrar_opciones.is_valid() and get_tree().paused:
		_pausa.visible = true
	if _al_cerrar_opciones.is_valid():
		_al_cerrar_opciones.call()


func _seccion(texto: String) -> Control:
	var e := etiqueta(texto.to_upper(), 18, COLOR_ACENTO)
	e.add_theme_constant_override(&"outline_size", 0)
	var m := MarginContainer.new()
	m.add_theme_constant_override(&"margin_top", 14)
	m.add_child(e)
	return m


func _fila(caja: VBoxContainer, texto: String) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override(&"separation", 20)
	var e := etiqueta(texto, 20)
	e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(e)
	caja.add_child(fila)
	return fila


func _deslizador(caja: VBoxContainer, texto: String, ajuste: StringName, minimo: float, maximo: float) -> HSlider:
	var fila := _fila(caja, texto)
	var s := HSlider.new()
	s.min_value = minimo
	s.max_value = maximo
	s.step = (maximo - minimo) / 50.0
	s.value = Settings.get(ajuste)
	s.custom_minimum_size = Vector2(320, 24)
	s.focus_mode = Control.FOCUS_ALL
	s.value_changed.connect(func(v: float) -> void: Settings.establecer(ajuste, v))
	fila.add_child(s)
	return s


func _casilla(caja: VBoxContainer, texto: String, ajuste: StringName) -> void:
	var c := CheckButton.new()
	c.text = texto
	c.button_pressed = Settings.get(ajuste)
	c.add_theme_font_size_override(&"font_size", 20)
	c.toggled.connect(func(v: bool) -> void: Settings.establecer(ajuste, v))
	caja.add_child(c)


const NOMBRES_ACCIONES := {
	&"mover_adelante": "Avanzar", &"mover_atras": "Retroceder", &"mover_izquierda": "Izquierda",
	&"mover_derecha": "Derecha", &"correr": "Correr", &"agacharse": "Agacharse",
	&"interactuar": "Interactuar", &"lanzar": "Lanzar objeto",
}


func _fila_tecla(caja: VBoxContainer, accion: StringName) -> void:
	var fila := _fila(caja, NOMBRES_ACCIONES.get(accion, String(accion)))
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override(&"font_size", 20)
	b.add_theme_font_override(&"font", fuente_mono)
	b.text = "[ %s ]" % _nombre_tecla(Settings.tecla_de(accion))
	b.pressed.connect(func() -> void:
		b.text = "[ pulsa una tecla ]"
		var tecla: Key = await _esperar_tecla()
		if tecla != KEY_NONE and tecla != KEY_ESCAPE:
			Settings.reasignar(accion, tecla)
		b.text = "[ %s ]" % _nombre_tecla(Settings.tecla_de(accion)))
	fila.add_child(b)


func _esperar_tecla() -> Key:
	while true:
		await get_tree().process_frame
		for codigo in [KEY_ESCAPE, KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_SPACE, KEY_TAB, KEY_ENTER]:
			if Input.is_physical_key_pressed(codigo):
				return codigo
		for codigo in range(KEY_0, KEY_Z + 1):
			if Input.is_physical_key_pressed(codigo):
				return codigo
		for codigo in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_F, KEY_Q]:
			if Input.is_physical_key_pressed(codigo):
				return codigo
	return KEY_NONE


func _nombre_tecla(codigo: Key) -> String:
	if codigo == KEY_NONE:
		return "—"
	var real := DisplayServer.keyboard_get_keycode_from_physical(codigo)
	return OS.get_keycode_string(real if real != KEY_NONE else codigo).to_upper()
