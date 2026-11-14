extends Node
## Herramientas de prueba (autoload «DebugTools»).
##
## TECLAS (mientras no existan los menús definitivos):
##   F1  mostrar u ocultar la información (fps, renderizador, calidad, época)
##   F2  cambiar entre el aspecto del PRESENTE y el del PASADO
##   F3  cambiar la calidad gráfica (BAJO / ALTO)
##   F4  activar o desactivar los efectos PS1, para comparar
##   F11 pantalla completa
##   F12 guardar una captura en user://capturas
##   (las teclas F1-F4 solo funcionan en las versiones de depuración o con -- --desarrollo)
##
## MODOS AUTOMÁTICOS (los usa el desarrollo para verificar cada etapa):
##   juego -- --capturas=C:/carpeta        guarda una imagen por cada «punto_captura»
##   juego -- --benchmark=C:/resultado.json [--segundos=12]   mide el rendimiento
##   juego -- --prueba-movimiento=C:/resultado.json   recorre la caja gris simulando
##       teclado y mando, y comprueba movimiento, colisiones, agacharse y cámara
##   juego -- --nivel=cap2[:punto]        empieza directamente en un nivel (pruebas)
##   juego -- --recorrido=C:/carpeta [--niveles=cap1,f1]   carga cada nivel y guarda una
##       captura desde el jugador y desde cada cámara de cinemática

const AYUDA := "F1 info · F2 época · F3 calidad · F4 efectos PS1 · F11 pantalla completa · F12 captura · Esc pausa"

var _capa: CanvasLayer
var _etiqueta: Label
var _pausa: Label
var _visible := true
var _acumulado := 0.0
var _automatico := false
## Teclas de desarrollo activas (F1-F4).
var _desarrollo := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_crear_interfaz()

	var segundos := 12.0
	var capturas := ""
	var benchmark := ""
	var prueba := ""
	var nivel := ""
	var recorrido := ""
	var niveles := ""
	_desarrollo = OS.is_debug_build() or OS.get_cmdline_user_args().has("--desarrollo")
	_visible = false
	_etiqueta.visible = false
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--prueba-demo="):
			_automatico = true
			var prueba_demo := Node.new()
			prueba_demo.set_script(load("res://herramientas/prueba_demo.gd"))
			add_child(prueba_demo)
			prueba_demo.call_deferred(&"iniciar", argumento.trim_prefix("--prueba-demo="))
		if argumento.begins_with("--capturas-tiempo="):
			_capturas_por_tiempo.call_deferred(argumento.trim_prefix("--capturas-tiempo="))
		if argumento.begins_with("--nivel="):
			nivel = argumento.trim_prefix("--nivel=")
		elif argumento.begins_with("--recorrido="):
			recorrido = argumento.trim_prefix("--recorrido=")
		elif argumento.begins_with("--niveles="):
			niveles = argumento.trim_prefix("--niveles=")
		if argumento.begins_with("--capturas="):
			capturas = argumento.trim_prefix("--capturas=")
		elif argumento.begins_with("--benchmark="):
			benchmark = argumento.trim_prefix("--benchmark=")
		elif argumento.begins_with("--prueba-movimiento="):
			prueba = argumento.trim_prefix("--prueba-movimiento=")
		elif argumento.begins_with("--segundos="):
			segundos = argumento.trim_prefix("--segundos=").to_float()
	if capturas != "":
		_automatico = true
		_modo_capturas(capturas)
	elif benchmark != "":
		_automatico = true
		_modo_benchmark(benchmark, segundos)
	elif prueba != "":
		_automatico = true
		_modo_prueba_movimiento(prueba)
	elif recorrido != "":
		_automatico = true
		_modo_recorrido.call_deferred(recorrido, niveles)
	elif nivel != "":
		var partes := nivel.split(":")
		_ir_a_nivel.call_deferred(StringName(partes[0]), StringName(partes[1]) if partes.size() > 1 else &"inicio")


func _process(delta: float) -> void:
	_acumulado += delta
	if _acumulado < 0.25:
		return
	_acumulado = 0.0
	if _visible:
		_etiqueta.text = _texto_info()


func _unhandled_input(evento: InputEvent) -> void:
	if _automatico:
		return
	var tecla := evento as InputEventKey
	if tecla == null or not tecla.pressed or tecla.echo:
		return
	if not _desarrollo and tecla.keycode in [KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_Q]:
		return
	match tecla.keycode:
		KEY_F1:
			_visible = not _visible
			_etiqueta.visible = _visible
		KEY_F2:
			_alternar_epoca()
		KEY_F3:
			var alto := Settings.calidad == Settings.Calidad.ALTO
			Settings.establecer(&"calidad", Settings.Calidad.BAJO if alto else Settings.Calidad.ALTO)
		KEY_F4:
			RenderRig.alternar_efectos_ps1()
		KEY_F11:
			Settings.establecer(&"pantalla_completa", not Settings.pantalla_completa)
		KEY_F12:
			var carpeta := "user://capturas"
			DirAccess.make_dir_recursive_absolute(carpeta)
			var nombre := "captura_%s" % Time.get_datetime_string_from_system().replace(":", "-")
			_guardar_captura(carpeta.path_join(nombre))


func _crear_interfaz() -> void:
	_capa = CanvasLayer.new()
	_capa.layer = 100
	add_child(_capa)

	_etiqueta = _nueva_etiqueta(13)
	_etiqueta.position = Vector2(10.0, 8.0)
	_capa.add_child(_etiqueta)

	_pausa = _nueva_etiqueta(28)
	_pausa.text = "PAUSA\nEsc: continuar   ·   Q: salir"
	_pausa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pausa.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_pausa.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pausa.visible = false
	_capa.add_child(_pausa)


func _nueva_etiqueta(tamano: int) -> Label:
	var etiqueta := Label.new()
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiqueta.add_theme_font_size_override(&"font_size", tamano)
	etiqueta.add_theme_color_override(&"font_color", Color(0.85, 0.9, 0.88))
	etiqueta.add_theme_color_override(&"font_outline_color", Color.BLACK)
	etiqueta.add_theme_constant_override(&"outline_size", 5)
	return etiqueta


func _texto_info() -> String:
	var calidad := "ALTO" if Settings.calidad == Settings.Calidad.ALTO else "BAJO"
	var epoca := RenderRig.epoca_actual.nombre.to_upper() if RenderRig.epoca_actual else "-"
	var efectos := "sí" if RenderRig.efectos_ps1 else "no"
	return "%d fps · %s · calidad %s · época %s · efectos PS1: %s\n%s" % [
		Engine.get_frames_per_second(), RenderingServer.get_current_rendering_method(),
		calidad, epoca, efectos, AYUDA]


func _alternar_pausa() -> void:
	var pausado := not get_tree().paused
	get_tree().paused = pausado
	_pausa.visible = pausado
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if pausado else Input.MOUSE_MODE_CAPTURED


func _alternar_epoca() -> void:
	var a_pasado := RenderRig.epoca_actual != RenderRig.epoca_pasado
	RenderRig.aplicar_epoca(RenderRig.epoca_pasado if a_pasado else RenderRig.epoca_presente, 0.6)
	var jugador := get_tree().get_first_node_in_group(&"jugador") as Jugador
	if jugador:
		jugador.usar_epoca_pasado(a_pasado)


# ---------------------------------------------------------- Niveles de prueba ---

## --capturas-tiempo=C:/carpeta|5,20,40 : guarda capturas a esos segundos y cierra el juego.
func _capturas_por_tiempo(valor: String) -> void:
	var partes := valor.split("|")
	var carpeta := partes[0]
	DirAccess.make_dir_recursive_absolute(carpeta)
	var transcurrido := 0.0
	for s in partes[1].split(","):
		var t := s.to_float()
		await get_tree().create_timer(maxf(t - transcurrido, 0.0), true, false, true).timeout
		transcurrido = t
		await _guardar_captura(carpeta.path_join("t%03d" % int(t)))
		print("CAPTURA t=%d s · %d fps · %s · calidad %s" % [int(t), Engine.get_frames_per_second(),
				get_tree().current_scene.name if get_tree().current_scene else "-",
				"ALTO" if Settings.calidad == Settings.Calidad.ALTO else "BAJO"])
	get_tree().quit()

func _ir_a_nivel(id: StringName, punto: StringName) -> void:
	await get_tree().process_frame
	Juego.estado = Juego.estado_inicial()
	Juego.ir_a(id, punto, 0.0)


## Carga cada nivel y guarda capturas desde el jugador y desde cada cámara del grupo
## «Camaras» del nivel. Sirve para revisar el aspecto sin jugar.
func _modo_recorrido(carpeta: String, lista: String) -> void:
	DirAccess.make_dir_recursive_absolute(carpeta)
	var ids: Array = Array(lista.split(",", false)) if lista != "" else Juego.ORDEN
	for id in ids:
		Juego.estado = Juego.estado_inicial()
		Juego.ir_a(StringName(id), &"inicio", 0.0)
		await get_tree().create_timer(4.5).timeout
		var nivel := Juego.nivel
		if nivel == null:
			print("RECORRIDO: no se cargó ", id)
			continue
		if nivel.has_method(&"empezar_cinematica"):
			nivel.set(&"_saltar", true)
		await get_tree().create_timer(2.5).timeout
		get_tree().call_group(&"luz_fluorescente", &"fijar_estable", true)
		RenderRig.establecer_barras(0.0, 0.0)
		RenderRig.fundir(0.0, 0.0)
		Interfaz.limpiar()
		var jugador := get_tree().get_first_node_in_group(&"jugador") as Jugador
		if jugador and jugador.camara:
			RenderRig.activar_camara(jugador.camara.camara)
		await get_tree().create_timer(0.8).timeout
		await _guardar_captura(carpeta.path_join("%s_jugador" % id))
		var camaras := nivel.get_node_or_null(^"Camaras")
		if camaras:
			for cam in camaras.find_children("*", "Camera3D", true, false):
				RenderRig.activar_camara(cam as Camera3D)
				await get_tree().create_timer(0.6).timeout
				await _guardar_captura(carpeta.path_join("%s_%s" % [id, cam.name]))
				RenderRig.desactivar_camara(cam as Camera3D)
		print("RECORRIDO: ", id, " listo")
	get_tree().quit()


# ------------------------------------------------------- Capturas de pantalla ---

## Guarda dos imágenes: la ventana completa y la imagen interna de 480 x 270.
func _guardar_captura(ruta_sin_extension: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ruta_sin_extension + ".png")
	RenderRig.vista.get_texture().get_image().save_png(ruta_sin_extension + "_interna.png")


## Recorre los nodos del grupo «punto_captura» colocando al jugador en cada uno.
## La rotación del punto indica hacia dónde mira la cámara. Si el punto tiene el
## metadato «agachado» = true, el jugador se agacha.
func _modo_capturas(carpeta: String) -> void:
	await get_tree().create_timer(1.5).timeout
	DirAccess.make_dir_recursive_absolute(carpeta)
	_etiqueta.visible = false
	get_tree().call_group(&"luz_fluorescente", &"fijar_estable", true)
	var jugador := get_tree().get_first_node_in_group(&"jugador") as Jugador
	var puntos := get_tree().get_nodes_in_group(&"punto_captura")
	if jugador == null or puntos.is_empty():
		push_error("DebugTools: faltan el jugador o los puntos de captura.")
		get_tree().quit(1)
		return
	jugador.control_activo = false
	for nodo in puntos:
		var punto := nodo as Node3D
		jugador.teletransportar(punto.global_position, punto.global_rotation.y)
		jugador.forzar_agachado(punto.get_meta(&"agachado", false))
		jugador.camara.fijar_orientacion(punto.global_rotation.y, punto.global_rotation.x)
		jugador.camara.saltar_al_objetivo()
		await get_tree().create_timer(1.8).timeout
		await _guardar_captura(carpeta.path_join(String(punto.name)))
	get_tree().quit()


# -------------------------------------------------------- Prueba de movimiento ---

var _camara_tras_pared := 0
var _fotogramas_prueba := 0


## Recorre la caja gris con controles simulados y anota si cada comprobación pasa.
## Sustituye a una persona jugando solo para lo objetivo (¿se mueve?, ¿choca?,
## ¿se agacha?, ¿la cámara atraviesa paredes?). La sensación la juzga el creador.
func _modo_prueba_movimiento(ruta_json: String) -> void:
	await get_tree().create_timer(1.0).timeout
	_etiqueta.visible = false
	var jugador := get_tree().get_first_node_in_group(&"jugador") as Jugador
	if jugador == null:
		push_error("DebugTools: no hay jugador en la escena.")
		get_tree().quit(1)
		return
	var pasos: Array[Dictionary] = []

	# 1. Teclado: la tecla W debe hacerlo avanzar.
	var inicio := jugador.global_position
	_enviar_tecla(KEY_W, true)
	await get_tree().create_timer(0.6).timeout
	_enviar_tecla(KEY_W, false)
	await get_tree().create_timer(0.3).timeout
	var avance := inicio.distance_to(jugador.global_position)
	pasos.append(_paso("teclado_W_avanza", avance > 0.3, "%.2f m" % avance))

	# 2. Mando: la palanca izquierda hacia delante debe hacerlo avanzar...
	inicio = jugador.global_position
	_enviar_palanca(JOY_AXIS_LEFT_Y, -1.0)
	await get_tree().create_timer(2.5).timeout
	avance = inicio.distance_to(jugador.global_position)
	pasos.append(_paso("mando_palanca_avanza", avance > 0.2, "%.2f m" % avance))
	# ...y la reja de la celda debe detenerlo (la reja está en z = 0).
	pasos.append(_paso("la_reja_lo_detiene", jugador.global_position.z < -0.2,
			"z = %.2f" % jugador.global_position.z))
	_enviar_palanca(JOY_AXIS_LEFT_Y, 0.0)
	await get_tree().create_timer(0.2).timeout

	# 3. Salir de la celda por la puerta y recorrer el pasillo A corriendo.
	pasos.append(await _ir_a(jugador, "hasta_la_puerta", Vector2(4.5, -0.7)))
	pasos.append(await _ir_a(jugador, "sale_de_la_celda", Vector2(4.5, 0.8)))
	Input.action_press(&"correr")
	var antes := Time.get_ticks_msec()
	var desde := jugador.global_position
	pasos.append(await _ir_a(jugador, "corre_por_el_pasillo_A", Vector2(13.2, 0.8)))
	Input.action_release(&"correr")
	var segundos := (Time.get_ticks_msec() - antes) / 1000.0
	var velocidad := desde.distance_to(jugador.global_position) / maxf(segundos, 0.01)
	pasos.append(_paso("velocidad_de_carrera", velocidad > 2.8, "%.2f m/s" % velocidad))

	# 4. Recodo y pasillo B andando.
	pasos.append(await _ir_a(jugador, "dobla_el_recodo", Vector2(14.8, 0.9)))
	pasos.append(await _ir_a(jugador, "anda_por_el_pasillo_B", Vector2(14.8, 5.4)))

	# 5. Agacharse y pasar bajo el conducto (hueco de 1,25 m).
	await _pulsar(&"agacharse")
	pasos.append(_paso("se_agacha", jugador.agachado, ""))
	pasos.append(await _ir_a(jugador, "pasa_bajo_el_conducto", Vector2(14.8, 7.0)))
	await _pulsar(&"agacharse")  # Intenta levantarse justo debajo: no debe poder.
	await get_tree().create_timer(0.5).timeout
	pasos.append(_paso("no_se_levanta_bajo_techo", jugador.agachado, ""))
	pasos.append(await _ir_a(jugador, "sale_del_conducto", Vector2(14.8, 8.9)))
	await get_tree().create_timer(0.5).timeout
	pasos.append(_paso("se_levanta_al_salir", not jugador.agachado, ""))

	# 6. De pie no debe poder volver a entrar bajo el conducto.
	pasos.append(await _ir_a(jugador, "de_pie_no_cabe_bajo_el_conducto", Vector2(14.8, 6.5),
			4.0, true))

	# 7. El muro del fondo debe detenerlo (el muro está en z = 11,6).
	await _ir_a(jugador, "", Vector2(14.8, 13.0), 6.0)
	pasos.append(_paso("el_muro_del_fondo_lo_detiene", jugador.global_position.z < 11.4,
			"z = %.2f" % jugador.global_position.z))

	var fallos := 0
	for paso in pasos:
		if not paso["ok"]:
			fallos += 1
	var datos := {
		"pasos": pasos,
		"fallos": fallos,
		"fotogramas_comprobados": _fotogramas_prueba,
		"fotogramas_con_camara_tras_una_pared": _camara_tras_pared,
	}
	var archivo := FileAccess.open(ruta_json, FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(datos, "  "))
		archivo.close()
	print("PRUEBA ", JSON.stringify(datos))
	get_tree().quit(0 if fallos == 0 and _camara_tras_pared == 0 else 1)


func _paso(nombre: String, correcto: bool, detalle: String) -> Dictionary:
	return {"nombre": nombre, "ok": correcto, "detalle": detalle}


func _enviar_tecla(codigo: Key, pulsada: bool) -> void:
	var evento := InputEventKey.new()
	evento.physical_keycode = codigo
	evento.pressed = pulsada
	Input.parse_input_event(evento)


func _enviar_palanca(eje: JoyAxis, valor: float) -> void:
	var evento := InputEventJoypadMotion.new()
	evento.axis = eje
	evento.axis_value = valor
	Input.parse_input_event(evento)


## Pulsa y suelta una acción durante un par de pasos de física.
func _pulsar(accion: StringName) -> void:
	await get_tree().physics_frame
	Input.action_press(accion)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(accion)
	await get_tree().physics_frame
	await get_tree().physics_frame


## Hace andar al jugador hacia un punto (x, z) apuntando la cámara y manteniendo
## «adelante». Con [param debe_fallar] el paso es correcto si NO consigue llegar.
func _ir_a(jugador: Jugador, nombre: String, destino: Vector2, limite := 14.0,
		debe_fallar := false) -> Dictionary:
	var tiempo := 0.0
	var llego := false
	Input.action_press(&"mover_adelante")
	while tiempo < limite:
		await get_tree().physics_frame
		tiempo += get_physics_process_delta_time()
		# Se comprueba el fotograma ya dibujado, antes de girar la cámara otra vez.
		_comprobar_camara(jugador)
		var posicion := jugador.global_position
		var falta := Vector2(destino.x - posicion.x, destino.y - posicion.z)
		if falta.length() < 0.2:
			llego = true
			break
		jugador.camara.fijar_orientacion(atan2(-falta.x, -falta.y), -0.1)
	Input.action_release(&"mover_adelante")
	var llegada := jugador.global_position
	return _paso(nombre, llego != debe_fallar,
			"%.1f s, termina en (%.2f, %.2f)" % [tiempo, llegada.x, llegada.z])


## Cuenta los fotogramas en los que hay una pared entre la cámara y el punto que
## sigue (junto al hombro del personaje). Si eso ocurre, la cámara está viendo a
## través de la geometría.
func _comprobar_camara(jugador: Jugador) -> void:
	_fotogramas_prueba += 1
	var consulta := PhysicsRayQueryParameters3D.create(
			jugador.camara.obtener_punto_de_mira(), RenderRig.camara.global_position, 1)
	consulta.exclude = [jugador.get_rid()]
	var golpe := jugador.get_world_3d().direct_space_state.intersect_ray(consulta)
	if not golpe.is_empty():
		_camara_tras_pared += 1
		print("CAMARA TRAS PARED: jugador %s, camara %s, obstaculo %s" % [
			jugador.global_position, RenderRig.camara.global_position,
			(golpe["collider"] as Node).get_path()])


# ------------------------------------------------------------------ Benchmark ---

## Recorre con una cámara la ruta del grupo «ruta_benchmark» y mide los fps.
func _modo_benchmark(ruta_json: String, segundos: float) -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	await get_tree().create_timer(1.0).timeout
	_etiqueta.visible = false
	var ruta := get_tree().get_first_node_in_group(&"ruta_benchmark") as Path3D
	if ruta == null:
		push_error("DebugTools: no hay ninguna ruta en el grupo «ruta_benchmark».")
		get_tree().quit(1)
		return
	var jugador := get_tree().get_first_node_in_group(&"jugador") as Jugador
	if jugador:
		jugador.control_activo = false

	var seguidor := PathFollow3D.new()
	seguidor.loop = false
	seguidor.rotation_mode = PathFollow3D.ROTATION_ORIENTED
	seguidor.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	ruta.add_child(seguidor)
	var camara := Camera3D.new()
	camara.fov = 62.0
	camara.near = 0.05
	seguidor.add_child(camara)
	RenderRig.activar_camara(camara)

	# Vuelta de calentamiento: compila shaders y carga texturas.
	await _recorrer(seguidor, 3.0, PackedFloat32Array())
	var tiempos := PackedFloat32Array()
	var llamadas := await _recorrer(seguidor, segundos, tiempos)

	var ordenados := Array(tiempos)
	ordenados.sort()
	var total := 0.0
	for t: float in ordenados:
		total += t
	var cuenta := ordenados.size()
	var datos := {
		"renderizador": RenderingServer.get_current_rendering_method(),
		"controlador": RenderingServer.get_current_rendering_driver_name(),
		"adaptador": RenderingServer.get_video_adapter_name(),
		"calidad": "ALTO" if Settings.calidad == Settings.Calidad.ALTO else "BAJO",
		"ventana": "%d x %d" % [get_window().size.x, get_window().size.y],
		"resolucion_interna": "%d x %d" % [RenderRig.vista.size.x, RenderRig.vista.size.y],
		"fotogramas": cuenta,
		"fps_medio": snappedf(cuenta / maxf(total, 0.001), 0.1),
		"fps_minimo_1pct": snappedf(1.0 / maxf(ordenados[int(cuenta * 0.99)], 0.0001), 0.1),
		"fps_peor": snappedf(1.0 / maxf(ordenados[cuenta - 1], 0.0001), 0.1),
		"llamadas_dibujo_medias": snappedf(llamadas, 1.0),
	}
	var archivo := FileAccess.open(ruta_json, FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(datos, "  "))
		archivo.close()
	print("BENCHMARK ", JSON.stringify(datos))
	get_tree().quit()


## Mueve el seguidor de principio a fin y anota la duración de cada fotograma.
## Devuelve la media de llamadas de dibujo.
func _recorrer(seguidor: PathFollow3D, segundos: float, tiempos: PackedFloat32Array) -> float:
	var transcurrido := 0.0
	var llamadas := 0.0
	var fotogramas := 0
	var anterior := Time.get_ticks_usec()
	while transcurrido < segundos:
		await get_tree().process_frame
		var ahora := Time.get_ticks_usec()
		var paso := (ahora - anterior) / 1000000.0
		anterior = ahora
		transcurrido += paso
		seguidor.progress_ratio = clampf(transcurrido / segundos, 0.0, 1.0)
		tiempos.append(paso)
		llamadas += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		fotogramas += 1
	return llamadas / maxf(fotogramas, 1.0)
