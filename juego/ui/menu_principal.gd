extends Node3D
## Menú principal cinematográfico (C-21). Fondo: ui/fondo_cinematico.tscn (escenarios reales
## del juego con saltos entre pasado y presente). Opciones: Continuar / Nueva partida /
## Cargar partida / Opciones / Créditos y licencias / Salir.

const MarcasConteo := preload("res://ui/marcas_conteo.gd")

var _capa: CanvasLayer
var _menu: VBoxContainer
var _licencias: Control


func _ready() -> void:
	Juego.en_partida = false
	Juego.nivel = null
	Juego.jugador = null
	RenderRig.establecer_barras(0.0, 0.0)
	RenderRig.fundir(1.0, 0.0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Audio.ambiente(&"menu_drone", -6.0, 3.0)
	Audio.capa(&"nivel", &"", 0.0, 1.0)
	_crear_interfaz()
	RenderRig.fundir(0.0, 2.0)


func _crear_interfaz() -> void:
	_capa = CanvasLayer.new()
	_capa.layer = 10
	add_child(_capa)
	var raiz := Control.new()
	raiz.theme = Interfaz.tema
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa.add_child(raiz)
	# Degradado oscuro a la izquierda para que el texto se lea.
	var sombra := TextureRect.new()
	var gradiente := Gradient.new()
	gradiente.set_color(0, Color(0, 0, 0, 0.88))
	gradiente.set_color(1, Color(0, 0, 0, 0.0))
	var textura := GradientTexture2D.new()
	textura.gradient = gradiente
	textura.fill_to = Vector2(1, 0)
	sombra.texture = textura
	sombra.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	sombra.offset_right = 760
	sombra.stretch_mode = TextureRect.STRETCH_SCALE
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(sombra)
	# Logotipo (L2): serif + marcas de conteo + sello.
	var logo := VBoxContainer.new()
	logo.position = Vector2(84, 70)
	logo.add_theme_constant_override(&"separation", 0)
	raiz.add_child(logo)
	for palabra in ["LIFETIME", "SENTENCE"]:
		var e: Label = Interfaz.etiqueta(palabra, 74, Color(0.86, 0.83, 0.76))
		e.add_theme_constant_override(&"outline_size", 0)
		logo.add_child(e)
	var marcas := Control.new()
	marcas.set_script(MarcasConteo)
	marcas.custom_minimum_size = Vector2(420, 44)
	logo.add_child(marcas)
	var sello: Label = Interfaz.etiqueta("PRESO N.º 4827 · PENITENCIARÍA ESTATAL N.º 314", 15, Color(0.7, 0.1, 0.07), true)
	sello.add_theme_constant_override(&"outline_size", 0)
	var marco := StyleBoxFlat.new()
	marco.bg_color = Color(0, 0, 0, 0)
	marco.border_color = Color(0.7, 0.1, 0.07, 0.85)
	marco.set_border_width_all(2)
	marco.set_content_margin_all(6)
	sello.add_theme_stylebox_override(&"normal", marco)
	sello.rotation_degrees = -4.0
	sello.position = Vector2(84, 300)
	raiz.add_child(sello)
	# Opciones.
	_menu = VBoxContainer.new()
	_menu.position = Vector2(90, 370)
	_menu.add_theme_constant_override(&"separation", 6)
	raiz.add_child(_menu)
	_rellenar_menu()
	var pie: Label = Interfaz.etiqueta("GUILD Game Jam 2026 · «Al otro lado de la ley» · v1.0", 15, Color(0.5, 0.48, 0.44))
	pie.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	pie.offset_left = -560
	pie.offset_top = -44
	pie.offset_right = -28
	pie.offset_bottom = -18
	pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	raiz.add_child(pie)


func _rellenar_menu() -> void:
	for hijo in _menu.get_children():
		hijo.queue_free()
	var primero: Button = null
	if Juego.hay_partida():
		primero = Interfaz.boton("Continuar", _continuar, 28)
		_menu.add_child(primero)
	var nueva: Button = Interfaz.boton("Nueva partida", _nueva, 28)
	_menu.add_child(nueva)
	var cargar: Button = Interfaz.boton("Cargar partida", _cargar, 28)
	cargar.disabled = not Guardado.hay_alguna()
	_menu.add_child(cargar)
	_menu.add_child(Interfaz.boton("Opciones", _opciones, 28))
	_menu.add_child(Interfaz.boton("Créditos y licencias", _mostrar_licencias, 28))
	_menu.add_child(Interfaz.boton("Salir", _salir, 28))
	for b in _menu.get_children():
		(b as Button).alignment = HORIZONTAL_ALIGNMENT_LEFT
	await get_tree().process_frame
	if primero:
		primero.grab_focus()
	else:
		nueva.grab_focus()


func _salir() -> void:
	get_tree().quit()


func _salir_del_menu(accion: Callable) -> void:
	_menu.visible = false
	Audio.parar_todo(1.2)
	RenderRig.fundir(1.0, 1.0)
	await get_tree().create_timer(1.1).timeout
	accion.call()


func _continuar() -> void:
	_salir_del_menu(Juego.continuar)


func _nueva() -> void:
	if Juego.hay_partida():
		var si: bool = await Interfaz.confirmar("¿Empezar una partida nueva?\nLas partidas guardadas en las paredes se conservan.")
		if not si:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_rellenar_menu()
			return
	_salir_del_menu(Juego.nueva_partida)


func _cargar() -> void:
	var ranura: int = await Interfaz.elegir_ranura(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if ranura > 0:
		_salir_del_menu(Juego.cargar_ranura.bind(ranura))
	else:
		_rellenar_menu()


func _opciones() -> void:
	_menu.visible = false
	Interfaz.abrir_opciones(_al_cerrar_opciones)


func _al_cerrar_opciones() -> void:
	_menu.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_rellenar_menu()


func _mostrar_licencias() -> void:
	_menu.visible = false
	_licencias = ColorRect.new()
	(_licencias as ColorRect).color = Color(0, 0, 0, 0.93)
	_licencias.set_anchors_preset(Control.PRESET_FULL_RECT)
	_licencias.theme = Interfaz.tema
	_capa.add_child(_licencias)
	var texto := RichTextLabel.new()
	texto.bbcode_enabled = true
	texto.text = Creditos.texto_completo()
	texto.set_anchors_preset(Control.PRESET_FULL_RECT)
	texto.offset_left = 160
	texto.offset_right = -160
	texto.offset_top = 40
	texto.offset_bottom = -90
	texto.add_theme_color_override(&"default_color", Color(0.8, 0.77, 0.7))
	texto.add_theme_font_size_override(&"normal_font_size", 18)
	texto.add_theme_font_size_override(&"bold_font_size", 20)
	texto.focus_mode = Control.FOCUS_ALL
	_licencias.add_child(texto)
	var volver: Button = Interfaz.boton("Volver", _cerrar_licencias, 26)
	volver.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	volver.offset_left = -80
	volver.offset_right = 80
	volver.offset_top = -70
	volver.offset_bottom = -28
	_licencias.add_child(volver)
	volver.grab_focus()


func _cerrar_licencias() -> void:
	if _licencias:
		_licencias.queue_free()
		_licencias = null
	_menu.visible = true
	_rellenar_menu()


func _unhandled_input(evento: InputEvent) -> void:
	if _licencias == null:
		return
	if evento.is_action_pressed(&"pausa") or evento.is_action_pressed(&"ui_cancel"):
		_cerrar_licencias()
		get_viewport().set_input_as_handled()
		return
	var eje := Input.get_axis(&"mover_adelante", &"mover_atras")
	if absf(eje) > 0.3:
		var rtl := _licencias.get_child(0) as RichTextLabel
		rtl.get_v_scroll_bar().value += eje * 40.0
