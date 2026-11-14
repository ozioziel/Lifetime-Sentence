extends Node3D
## Créditos finales (C-20): tras «FIN DE LA DEMO», solo los dos nombres, alternándose
## repetidamente sobre secuencias del juego; después la tarjeta de IA (C-10) y vuelta al menú.
## Se pueden saltar con Esc / START.

var _capa: CanvasLayer
var _texto: Label
var _saltar := false


func _ready() -> void:
	Juego.en_partida = false
	RenderRig.establecer_barras(1.0, 0.0)
	RenderRig.fundir(1.0, 0.0)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	Audio.ambiente(&"creditos_drone", -6.0, 2.0)
	_capa = CanvasLayer.new()
	_capa.layer = 10
	add_child(_capa)
	_texto = Interfaz.etiqueta("", 44, Color(0.88, 0.85, 0.78))
	_texto.set_anchors_preset(Control.PRESET_FULL_RECT)
	_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.add_theme_constant_override(&"outline_size", 8)
	_texto.add_theme_font_override(&"font", Interfaz.fuente_serif)
	_texto.modulate.a = 0.0
	_capa.add_child(_texto)
	RenderRig.fundir(0.0, 2.5)
	_secuencia()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"pausa"):
		_saltar = true


func _secuencia() -> void:
	await _esperar(1.5)
	await _mostrar("LIFETIME SENTENCE", 3.0, 52)
	for vuelta in 3:
		for nombre in Creditos.NOMBRES:
			await _mostrar(nombre, 3.2, 44)
	await _mostrar("Desarrollado con asistencia de inteligencia artificial:\nClaude (Anthropic): programación, niveles, modelos, texturas, animación, sonido y textos.\nChatGPT (OpenAI): arte conceptual de referencia.\n\nHecho con Godot Engine y Blender.", 7.0, 22)
	await _mostrar("Gracias por jugar.", 3.0, 36)
	RenderRig.fundir(1.0, 1.5)
	Audio.parar_todo(1.5)
	await get_tree().create_timer(1.6).timeout
	RenderRig.establecer_barras(0.0, 0.0)
	get_tree().change_scene_to_file(Juego.MENU)


func _mostrar(texto: String, segundos: float, tamano: int) -> void:
	if _saltar:
		return
	_texto.text = texto
	_texto.add_theme_font_size_override(&"font_size", tamano)
	var tw := create_tween()
	tw.tween_property(_texto, "modulate:a", 1.0, 1.2)
	await tw.finished
	await _esperar(segundos)
	tw = create_tween()
	tw.tween_property(_texto, "modulate:a", 0.0, 1.0)
	await tw.finished


func _esperar(segundos: float) -> void:
	var t := 0.0
	while t < segundos and not _saltar:
		await get_tree().process_frame
		t += get_process_delta_time()
