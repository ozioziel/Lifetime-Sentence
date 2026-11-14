extends Node
## Prueba de recorrido a pie (herramienta de desarrollo).
##   juego -- --nivel=cap2 "--prueba-camino=C:/carpeta|Interactivos/A|Interactivos/B…"
## Un bot va ANDANDO (sin teletransportarse) por la malla de navegación hasta cada
## interactuable de la lista, en orden, y lo usa pulsando Interactuar como un jugador. Así se
## comprueba que cada sitio es alcanzable y que el aviso aparece. Los enemigos se mantienen
## calmados (esto prueba el camino, no la dificultad). Escribe camino.txt y capturas.

var _carpeta := ""
var _objetivos: PackedStringArray = []
var _log: FileAccess
var _errores := 0


func iniciar(argumento: String) -> void:
	var partes := argumento.split("|")
	_carpeta = partes[0]
	_objetivos = partes.slice(1)
	DirAccess.make_dir_recursive_absolute(_carpeta)
	_log = FileAccess.open(_carpeta.path_join("camino.txt"), FileAccess.WRITE)
	Interfaz.prueba_automatica = true
	_calmar()
	await _esperar_control()
	var i := 0
	for ruta in _objetivos:
		i += 1
		var it := Juego.nivel.get_node_or_null(NodePath(ruta)) as Interactuable
		if it == null:
			_error("no existe %s" % ruta)
			continue
		var nivel_antes: Node = Juego.nivel
		var pos_antes: Vector3 = (Juego.jugador as Jugador).global_position
		var nombre := String(it.name)
		if not await _andar_hasta(it):
			continue
		await _captura("%02d_%s" % [i, nombre])
		Input.action_press(&"interactuar")
		await get_tree().physics_frame
		await get_tree().physics_frame
		Input.action_release(&"interactuar")
		await get_tree().create_timer(4.0).timeout
		await _esperar_control()
		var j := Juego.jugador as Jugador
		_escribir("usado %s → jugador en %s%s" % [ruta, _v(j.global_position),
				" (otro nivel)" if Juego.nivel != nivel_antes else ""])
		if Juego.nivel == nivel_antes and j.global_position.distance_to(pos_antes) < 0.01:
			_error("usar %s no hizo nada visible" % ruta)
		await _captura("%02d_%s_despues" % [i, nombre])
	_escribir("FIN. Errores: %d" % _errores)
	_log.close()
	get_tree().quit(1 if _errores > 0 else 0)


func _v(p: Vector3) -> String:
	return "(%.1f, %.1f, %.1f)" % [p.x, p.y, p.z]


func _escribir(texto: String) -> void:
	print("CAMINO: ", texto)
	_log.store_line(texto)
	_log.flush()


func _error(texto: String) -> void:
	_errores += 1
	_escribir("ERROR: " + texto)


func _captura(nombre: String) -> void:
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_carpeta.path_join(nombre + ".png"))


## Apaga a los enemigos (sin lógica ni colisión): esta prueba mide el camino, no la dificultad.
func _calmar() -> void:
	while is_inside_tree():
		for e in get_tree().get_nodes_in_group(&"enemigo"):
			var en := e as Enemigo
			if en.process_mode != Node.PROCESS_MODE_DISABLED:
				en.process_mode = Node.PROCESS_MODE_DISABLED
				var forma := en.get_node_or_null(^"Colision") as CollisionShape3D
				if forma:
					forma.set_deferred(&"disabled", true)
		await get_tree().physics_frame


func _esperar_control() -> void:
	while true:
		var j := Juego.jugador as Jugador
		if j and is_instance_valid(j) and j.control_activo and not j.ocupado and Juego.nivel:
			return
		await get_tree().process_frame


## Anda (sin correr) hasta que el interactuable sea el candidato del jugador.
func _andar_hasta(it: Interactuable) -> bool:
	var j := Juego.jugador as Jugador
	var mapa := j.get_world_3d().navigation_map
	var meta := it.punto_global()
	var t := 0.0
	var t_atasco := 0.0
	var ultima := j.global_position
	_escribir("hacia %s en %s desde %s" % [it.name, _v(meta), _v(j.global_position)])
	while t < 120.0:
		await get_tree().physics_frame
		var dt := get_physics_process_delta_time()
		t += dt
		if j.get(&"_candidato") == it:
			Input.action_release(&"mover_adelante")
			_escribir("  llega a %s en %.1f s (aviso: «%s»)" % [it.name, t, it.texto_aviso(j)])
			await get_tree().create_timer(0.3).timeout
			return true
		var camino := NavigationServer3D.map_get_path(mapa, j.global_position, meta, true)
		var dir := Vector3(meta.x - j.global_position.x, 0, meta.z - j.global_position.z)
		for p in camino:
			var d := Vector3(p.x - j.global_position.x, 0.0, p.z - j.global_position.z)
			if d.length() > 0.5:
				dir = d
				break
		if dir.length() > 0.01:
			dir = dir.normalized()
			j.camara.yaw = atan2(-dir.x, -dir.z)
		Input.action_press(&"mover_adelante")
		if j.global_position.distance_to(ultima) < 0.01:
			t_atasco += dt
			if t_atasco > 3.0:
				Input.action_release(&"mover_adelante")
				_error("atascado camino de %s en %s (a %.1f m)" % [it.name, _v(j.global_position),
						Vector2(j.global_position.x, j.global_position.z).distance_to(Vector2(meta.x, meta.z))])
				await _captura("atasco_%s" % it.name)
				return false
		else:
			t_atasco = 0.0
		ultima = j.global_position
	Input.action_release(&"mover_adelante")
	_error("no llegó a %s en 120 s" % it.name)
	return false
