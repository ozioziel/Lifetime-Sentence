extends Node
## Prueba de dificultad de F1 «La huida» (herramienta de desarrollo).
##   juego -- --nivel=f1 --prueba-huida=C:/carpeta[|modo]
## Un bot juega la persecución como lo haría una persona razonable: corre por la calle
## siguiendo la malla de navegación, se aparta de los policías que tiene delante, esconde
## la carpeta en la alcantarilla y llega a la verja. Modos:
##   normal      : solo corre, esquiva y esconde la carpeta.
##   obstaculos  : además derriba lo que tiene a mano cuando le pisan los talones.
## Escribe huida.txt con el resultado (ESCAPA / ATRAPADO en z…) y la distancia al
## perseguidor más cercano cada medio segundo.

var _carpeta := ""
var _modo := "normal"
var _log: FileAccess
var _fin := false
var _t := 0.0
var _t_registro := 0.0
var _min_distancia := 99.0
var _dudo := false
var _captura_cruce := false
var _captura_vista := false


func iniciar(argumento: String) -> void:
	var partes := argumento.split("|")
	_carpeta = partes[0]
	if partes.size() > 1:
		_modo = partes[1]
	DirAccess.make_dir_recursive_absolute(_carpeta)
	_log = FileAccess.open(_carpeta.path_join("huida_%s.txt" % _modo), FileAccess.WRITE)
	await _esperar_control()
	_escribir("inicio (modo %s)" % _modo)
	await get_tree().create_timer(0.2).timeout
	await _captura("inicio")
	var j := Juego.jugador as Jugador
	var alcantarilla := Juego.nivel.get_node(^"Interactivos/Alcantarilla") as Node3D
	var verja := Juego.nivel.get_node(^"Zonas/Verja") as Node3D
	# 1) Correr hasta la alcantarilla.
	if not await _correr_hasta(alcantarilla.global_position, 1.0):
		return _terminar()
	_escribir("en la alcantarilla t=%.1f s, perseguidor más cercano a %.1f m" % [_t, _distancia_perseguidor()])
	_soltar()
	Input.action_press(&"interactuar")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(&"interactuar")
	var espera := 0.0
	while not Juego.bandera(&"carpeta_escondida") and espera < 5.0 and not j.muerto:
		await get_tree().physics_frame
		espera += get_physics_process_delta_time()
		_t += get_physics_process_delta_time()
	if j.muerto:
		_escribir("ATRAPADO escondiendo la carpeta")
		return _terminar()
	if not Juego.bandera(&"carpeta_escondida"):
		_escribir("ERROR: no pudo esconder la carpeta")
		return _terminar()
	while j.ocupado and not j.muerto:
		await get_tree().physics_frame
		_t += get_physics_process_delta_time()
	_escribir("carpeta escondida t=%.1f s, perseguidor a %.1f m" % [_t, _distancia_perseguidor()])
	await _captura("carpeta")
	# 2) Correr hasta la verja.
	if not await _correr_hasta(verja.global_position + Vector3(0, -1.5, 1.5), 0.8):
		return _terminar()
	_escribir("ESCAPA t=%.1f s (distancia mínima a un perseguidor %.1f m)" % [_t, _min_distancia])
	await get_tree().create_timer(1.5).timeout
	_terminar()


func _terminar() -> void:
	_soltar()
	_log.close()
	get_tree().quit()


func _escribir(texto: String) -> void:
	print("HUIDA: ", texto)
	_log.store_line(texto)
	_log.flush()


func _captura(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_carpeta.path_join("%s_%s.png" % [_modo, nombre]))


func _esperar_control() -> void:
	while true:
		var j := Juego.jugador as Jugador
		if j and is_instance_valid(j) and j.control_activo and not j.ocupado and Juego.nivel:
			return
		await get_tree().process_frame


func _soltar() -> void:
	for a: StringName in [&"mover_adelante", &"correr", &"interactuar"]:
		Input.action_release(a)


func _perseguidores() -> Array[Enemigo]:
	var lista: Array[Enemigo] = []
	for n in get_tree().get_nodes_in_group(&"enemigo"):
		var e := n as Enemigo
		if e and e.estado == Enemigo.Estado.PERSEGUIR and e.velocidad_persecucion() > 0.0:
			lista.append(e)
	return lista


func _distancia_perseguidor() -> float:
	var j := Juego.jugador as Jugador
	var d := 99.0
	for e in _perseguidores():
		d = minf(d, e.global_position.distance_to(j.global_position))
	return d


## Corre por la malla de navegación hasta [param meta]. Devuelve false si lo atrapan.
func _corre_hacia_direccion(dir: Vector3) -> void:
	var j := Juego.jugador as Jugador
	j.camara.yaw = atan2(-dir.x, -dir.z)
	Input.action_press(&"mover_adelante")
	Input.action_press(&"correr")


func _correr_hasta(meta: Vector3, margen: float) -> bool:
	var j := Juego.jugador as Jugador
	var mapa := j.get_world_3d().navigation_map
	var t_atasco := 0.0
	var ultima := j.global_position
	while true:
		await get_tree().physics_frame
		var dt := get_physics_process_delta_time()
		_t += dt
		if j.muerto:
			_escribir("ATRAPADO en z=%.1f t=%.1f s" % [j.global_position.z, _t])
			await get_tree().create_timer(0.8).timeout
			await _captura("atrapado")
			return false
		var plano := Vector3(meta.x, j.global_position.y, meta.z)
		if j.global_position.distance_to(plano) < margen:
			return true
		if j.ocupado or not j.control_activo:
			continue
		# Modos «duda_N»: se para N segundos en el cruce, como quien no sabe por dónde ir.
		if _modo.begins_with("duda_") and not _dudo and j.global_position.z < -33.0:
			_dudo = true
			_soltar()
			_escribir("duda %s s en el cruce (perseguidor a %.1f m)" % [_modo.trim_prefix("duda_"), _distancia_perseguidor()])
			var parado := 0.0
			while parado < _modo.trim_prefix("duda_").to_float() and not j.muerto:
				await get_tree().physics_frame
				parado += get_physics_process_delta_time()
				_t += get_physics_process_delta_time()
			continue
		var camino := NavigationServer3D.map_get_path(mapa, j.global_position, meta, true)
		var dir := plano - j.global_position
		for p in camino:
			var d := Vector3(p.x - j.global_position.x, 0.0, p.z - j.global_position.z)
			if d.length() > 0.6:
				dir = d
				break
		dir.y = 0.0
		dir = dir.normalized()
		# Esquivar a los policías que vienen de frente o por delante.
		var lado := Vector3(-dir.z, 0.0, dir.x)
		var empuje := Vector3.ZERO
		for e in _perseguidores():
			var hacia := e.global_position - j.global_position
			hacia.y = 0.0
			var dist := hacia.length()
			_min_distancia = minf(_min_distancia, dist)
			if dist < 7.0 and hacia.dot(dir) > 0.0:
				var s := signf(hacia.dot(lado))
				if s == 0.0:
					s = 1.0
				empuje -= lado * s * (7.0 - dist) / 7.0 * 1.6
			# Derribar lo que tenga a mano si le pisan los talones.
			if _modo == "obstaculos" and dist < 5.0 and hacia.dot(dir) < 0.0:
				_derribar_si_puede()
		dir = (dir + empuje).normalized()
		_corre_hacia_direccion(dir)
		if not _captura_cruce and j.global_position.z < -38.0:
			_captura_cruce = true
			await _captura("cruce")
		if not _captura_vista and j.global_position.z < -46.0:
			_captura_vista = true
			await _captura("alcantarilla_a_la_vista")
		_t_registro += dt
		if _t_registro >= 0.5:
			_t_registro = 0.0
			_log.store_line("  t=%.1f z=%.1f x=%.1f perseguidor=%.1f m (%d)" % [_t, j.global_position.z,
					j.global_position.x, _distancia_perseguidor(), _perseguidores().size()])
		if j.global_position.distance_to(ultima) < 0.02:
			t_atasco += dt
			if t_atasco > 3.0:
				_escribir("ERROR: atascado en %s" % j.global_position)
				return false
		else:
			t_atasco = 0.0
		ultima = j.global_position
	return false


func _derribar_si_puede() -> void:
	var j := Juego.jugador as Jugador
	for n in get_tree().get_nodes_in_group(&"obstaculo_derribable"):
		var o := n as Node3D
		if o.is_in_group(&"obstaculo_derribado"):
			continue
		if o.global_position.distance_to(j.global_position) < 1.5:
			_escribir("derriba %s en z=%.1f" % [o.name, j.global_position.z])
			(o as Interactuable).usar(j)
			return
