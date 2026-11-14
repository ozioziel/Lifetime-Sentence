extends Control
## Minijuego de ganzúa (decisiones K2 y K6).
##
## El alambre se mueve por la mitad superior de la cerradura. Al girar (mantener
## Interactuar o clic), el cilindro solo llega hasta el final si el alambre está en el
## punto justo; si no, se atasca y el alambre sufre hasta romperse (se vuelve a empezar).
## Cuanto más cerca del punto, más gira el cilindro: esa es la pista.
##
## Lo crea Interfaz.ganzua(dificultad, limite). Emite «terminado(true)» al abrir.

signal terminado(abierta: bool)

## 0 = fácil (margen amplio), 1 = difícil (margen estrecho).
var dificultad := 0.4
## Segundos para abrirla (0 = sin límite). K6: la ganzúa de F2 es a contrarreloj.
var limite := 0.0
var interfaz: Node

var _angulo := 90.0
var _objetivo := 0.0
var _tolerancia := 9.0
var _giro := 0.0
var _esfuerzo := 0.0
var _tiempo := 0.0
var _acabado := false
var _roto := 0.0
var _ultimo_clic := 0.0
var _sonido_esfuerzo: AudioStreamPlayer
var _ayuda: Label
var _reloj: Label
var _raton := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_objetivo = randf_range(18.0, 162.0)
	_tolerancia = lerpf(13.0, 4.5, clampf(dificultad, 0.0, 1.0))
	_tiempo = limite
	var titulo: Label = interfaz.etiqueta("CERRADURA", 22, Color(0.6, 0.57, 0.5))
	titulo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	titulo.offset_top = 40
	titulo.offset_left = -200
	titulo.offset_right = 200
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(titulo)
	_reloj = interfaz.etiqueta("", 40, Color(0.85, 0.15, 0.1), true)
	_reloj.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_reloj.offset_top = 76
	_reloj.offset_left = -200
	_reloj.offset_right = 200
	_reloj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reloj.visible = limite > 0.0
	add_child(_reloj)
	_ayuda = interfaz.etiqueta("", 17, Color(0.6, 0.58, 0.53))
	_ayuda.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_ayuda.offset_top = -80
	_ayuda.offset_bottom = -40
	_ayuda.offset_left = -600
	_ayuda.offset_right = 600
	_ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_ayuda)
	_actualizar_ayuda()
	_sonido_esfuerzo = AudioStreamPlayer.new()
	_sonido_esfuerzo.bus = &"Efectos"
	_sonido_esfuerzo.stream = Audio.cargar(&"ganzua_esfuerzo")
	_sonido_esfuerzo.volume_db = -60.0
	add_child(_sonido_esfuerzo)
	if _sonido_esfuerzo.stream:
		_sonido_esfuerzo.play()
	Audio.efecto(&"ganzua_meter", -4.0)


func _actualizar_ayuda() -> void:
	if interfaz.usando_mando:
		_ayuda.text = "Palanca izquierda: mover el alambre  ·  Mantén A: girar  ·  B: soltar"
	else:
		_ayuda.text = "Ratón o A / D: mover el alambre  ·  Mantén %s o clic: girar  ·  Esc: soltar" % interfaz.glifo(&"interactuar")


func _input(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion:
		_raton += (evento as InputEventMouseMotion).relative.x
	if evento.is_action_pressed(&"pausa") or evento.is_action_pressed(&"ui_cancel") \
			or (evento is InputEventJoypadButton and (evento as InputEventJoypadButton).button_index == JOY_BUTTON_B
				and evento.is_pressed()):
		if not _acabado:
			_acabado = true
			_sonido_esfuerzo.stop()
			terminado.emit(false)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_actualizar_ayuda()
	if _acabado:
		queue_redraw()
		return
	if limite > 0.0:
		_tiempo -= delta
		_reloj.text = "%d:%02d" % [int(maxf(_tiempo, 0.0)) / 60, int(maxf(_tiempo, 0.0)) % 60]
		if _tiempo <= 0.0:
			_acabado = true
			_sonido_esfuerzo.stop()
			Audio.efecto(&"ganzua_rota", 0.0)
			terminado.emit(false)
			return
	if _roto > 0.0:
		_roto -= delta
		_raton = 0.0
		queue_redraw()
		return
	var girando := Input.is_action_pressed(&"interactuar") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if not girando:
		var antes := _angulo
		var eje := Input.get_axis(&"mover_izquierda", &"mover_derecha")
		_angulo = clampf(_angulo + eje * 70.0 * delta + _raton * 0.25, 2.0, 178.0)
		if absf(_angulo - antes) > 0.4 and absf(_angulo - _objetivo) < _tolerancia * 2.2:
			_ultimo_clic -= delta
			if _ultimo_clic <= 0.0:
				_ultimo_clic = 0.14
				Audio.efecto(&"ganzua_clic", -10.0, randf_range(0.9, 1.15))
	_raton = 0.0

	var diferencia := absf(_angulo - _objetivo)
	var maximo := 90.0
	if diferencia > _tolerancia:
		maximo = 90.0 * clampf(1.0 - (diferencia - _tolerancia) / (_tolerancia * 3.0 + 22.0), 0.0, 0.82)
	if girando:
		_giro = move_toward(_giro, maximo, 110.0 * delta)
		if _giro >= 89.0 and diferencia <= _tolerancia:
			_abrir()
			return
		if _giro >= maximo - 0.6:
			_esfuerzo += delta * (0.75 + dificultad * 0.8)
			_sonido_esfuerzo.volume_db = lerpf(-24.0, -6.0, _esfuerzo)
			interfaz.vibrar(0.2 + _esfuerzo * 0.5, _esfuerzo * 0.6, 0.1)
			if _esfuerzo >= 1.0:
				_romper()
		else:
			_sonido_esfuerzo.volume_db = -60.0
	else:
		_giro = move_toward(_giro, 0.0, 200.0 * delta)
		_esfuerzo = maxf(_esfuerzo - delta * 0.6, 0.0)
		_sonido_esfuerzo.volume_db = -60.0
	queue_redraw()


func _abrir() -> void:
	_acabado = true
	_giro = 90.0
	_sonido_esfuerzo.stop()
	Audio.efecto(&"cerradura_abrir", 0.0)
	interfaz.vibrar(0.6, 0.3, 0.25)
	queue_redraw()
	terminado.emit(true)


func _romper() -> void:
	_esfuerzo = 0.0
	_giro = 0.0
	_roto = 0.9
	_sonido_esfuerzo.volume_db = -60.0
	Audio.efecto(&"ganzua_rota", -2.0)
	interfaz.vibrar(0.8, 0.8, 0.3)


func _draw() -> void:
	var c := size * 0.5 + Vector2(0, 20)
	var temblor := Vector2.ZERO
	if _esfuerzo > 0.05 and not _acabado:
		temblor = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _esfuerzo * 5.0
	# Cuerpo de la cerradura.
	draw_circle(c, 182.0, Color(0.05, 0.05, 0.05))
	draw_circle(c, 176.0, Color(0.16, 0.15, 0.13))
	draw_arc(c, 176.0, 0.0, TAU, 48, Color(0.33, 0.29, 0.22), 4.0)
	for i in 8:
		var a := TAU * i / 8.0
		draw_circle(c + Vector2(cos(a), sin(a)) * 150.0, 6.0, Color(0.1, 0.09, 0.08))
	# Cilindro que gira.
	var giro := deg_to_rad(_giro)
	draw_circle(c, 96.0, Color(0.26, 0.24, 0.2))
	draw_arc(c, 96.0, 0.0, TAU, 40, Color(0.12, 0.11, 0.1), 3.0)
	var ojo := PackedVector2Array()
	for p in [Vector2(-9, -52), Vector2(9, -52), Vector2(9, 20), Vector2(22, 46), Vector2(-22, 46), Vector2(-9, 20)]:
		ojo.append(c + (p as Vector2).rotated(giro))
	draw_colored_polygon(ojo, Color(0.02, 0.02, 0.02))
	# Llave de tensión (abajo).
	var base := c + Vector2(0, 30).rotated(giro)
	draw_line(base, base + Vector2(0, 150).rotated(giro), Color(0.42, 0.4, 0.36), 7.0)
	draw_line(base + Vector2(0, 150).rotated(giro), base + Vector2(60, 150).rotated(giro), Color(0.42, 0.4, 0.36), 7.0)
	# Alambre (ganzúa).
	var a := deg_to_rad(180.0 - _angulo)
	var dir := Vector2(cos(a), -sin(a))
	var color := Color(0.7, 0.66, 0.56).lerp(Color(0.9, 0.2, 0.15), _esfuerzo)
	if _roto > 0.0:
		draw_line(c + dir * 14.0, c + dir * 70.0, color, 3.0)
		draw_line(c + dir * 90.0 + Vector2(0, 30 * (1.0 - _roto)), c + dir * 290.0 + Vector2(0, 60 * (1.0 - _roto)), color, 3.0)
	else:
		draw_line(c + dir * 14.0 + temblor, c + dir * 290.0 + temblor, color, 3.5)
		draw_line(c + dir * 290.0 + temblor, c + dir * 290.0 + dir.orthogonal() * 18.0 + temblor, color, 3.5)
	if _acabado and _giro >= 89.0:
		draw_arc(c, 190.0, 0.0, TAU, 48, Color(0.75, 0.65, 0.4, 0.8), 3.0)
