extends Node
## Prueba automática de la demo completa (herramienta de desarrollo).
##   juego -- --prueba-demo=C:/carpeta
## Recorre los 8 tramos usando cada objeto importante, resolviendo los minijuegos en modo
## de prueba (Interfaz.prueba_automatica), cruzando todas las transiciones D5/D6, probando
## una muerte con «CONTINUAR» y terminando en los créditos y el menú. Guarda un registro
## (prueba.txt) y capturas en la carpeta indicada. No sustituye a jugar: comprueba que
## nada se rompe y que la demo se puede terminar.

var _carpeta := ""
var _log: FileAccess
var _errores := 0


func iniciar(carpeta: String) -> void:
	_carpeta = carpeta
	DirAccess.make_dir_recursive_absolute(carpeta)
	_log = FileAccess.open(carpeta.path_join("prueba.txt"), FileAccess.WRITE)
	Interfaz.prueba_automatica = true
	await get_tree().create_timer(1.0).timeout
	var inicio := Time.get_ticks_msec()
	await _recorrido()
	_escribir("FIN en %.0f s. Errores: %d" % [(Time.get_ticks_msec() - inicio) / 1000.0, _errores])
	_log.close()
	get_tree().quit(1 if _errores > 0 else 0)


func _escribir(texto: String) -> void:
	print("PRUEBA: ", texto)
	_log.store_line(texto)
	_log.flush()


func _error(texto: String) -> void:
	_errores += 1
	_escribir("ERROR: " + texto)


# ----------------------------------------------------------------- Ayudas ---

func _esperar_nivel(id: StringName, limite := 30.0) -> bool:
	var t := 0.0
	while t < limite:
		await get_tree().process_frame
		t += get_process_delta_time()
		if Juego.nivel and is_instance_valid(Juego.nivel) and Juego.nivel.id == id and Juego.jugador \
				and is_instance_valid(Juego.jugador) and not get_tree().paused:
			await get_tree().create_timer(1.2).timeout
			_escribir("nivel %s cargado (%s)" % [id, Juego.estado.get("punto", "")])
			return true
	_error("no se cargó el nivel %s" % id)
	return false


func _esperar_control(limite := 20.0) -> void:
	var t := 0.0
	while t < limite:
		var j := Juego.jugador as Jugador
		if j and is_instance_valid(j) and j.control_activo and not j.ocupado:
			return
		await get_tree().process_frame
		t += get_process_delta_time()
	_error("el jugador no recuperó el control")


func _nodo(ruta: String) -> Node:
	var n := Juego.nivel.get_node_or_null(ruta) if Juego.nivel else null
	if n == null:
		_error("no existe %s" % ruta)
	return n


func _colocar_en(p: Vector3) -> void:
	var j := Juego.jugador as Jugador
	var desde := p + Vector3.UP * 0.6
	var rayo := PhysicsRayQueryParameters3D.create(desde, desde + Vector3.DOWN * 5.0, 1)
	rayo.exclude = [j.get_rid()]
	var golpe := j.get_world_3d().direct_space_state.intersect_ray(rayo)
	var y: float = golpe["position"].y if not golpe.is_empty() else p.y
	j.teletransportar(Vector3(p.x, y + 0.02, p.z), j.modelo().rotation.y)
	await get_tree().physics_frame
	await get_tree().physics_frame


func _usar(ruta: String, mantener := false) -> bool:
	var it := _nodo(ruta) as Interactuable
	if it == null:
		return false
	await _esperar_control()
	var p := it.punto_global()
	var hacia: Vector3 = Juego.jugador.global_position - p
	hacia.y = 0.0
	var offset: Vector3 = hacia.normalized() * 0.45 if hacia.length() > 0.1 else Vector3.ZERO
	await _colocar_en(p + offset)
	if not it.disponible(Juego.jugador):
		_error("%s no está disponible" % ruta)
		return false
	if mantener:
		Input.action_press(&"interactuar")
	await it.usar(Juego.jugador)
	if mantener:
		Input.action_release(&"interactuar")
	_escribir("  usado %s" % ruta)
	await get_tree().create_timer(0.4).timeout
	return true


func _zona(ruta: String) -> void:
	var z := _nodo(ruta) as Node3D
	if z == null:
		return
	await _esperar_control()
	var tam: Vector3 = z.get(&"tamano")
	await _colocar_en(z.global_position + Vector3(0, -tam.y * 0.5 + 0.3, 0))
	_escribir("  zona %s" % ruta)
	await get_tree().create_timer(0.6).timeout


func _escena_es(nombre: String) -> bool:
	var e := get_tree().current_scene
	return e != null and e.name == nombre


func _calmar_enemigos() -> void:
	for e in get_tree().get_nodes_in_group(&"enemigo"):
		(e as Enemigo).cambiar_estado(Enemigo.Estado.GUION)


func _captura(nombre: String) -> void:
	await get_tree().create_timer(0.3).timeout
	await DebugTools._guardar_captura(_carpeta.path_join(nombre))


# -------------------------------------------------------------- Recorrido ---

func _recorrido() -> void:
	Juego.estado = Juego.estado_inicial()
	Juego.ir_a(&"cap1", &"inicio", 0.0)
	# ---- Capítulo I
	if not await _esperar_nivel(&"cap1"):
		return
	await _esperar_control()
	await _captura("01_cap1_celda")
	await _usar("Interactivos/Somier")
	await _usar("Interactivos/Carta")
	await _usar("Interactivos/PuertaCelda")
	await _usar("Interactivos/ParedCelda")
	await _usar("Interactivos/Expediente")
	await _usar("Interactivos/Punzon")
	if Juego.usos_punzon() != 3:
		_error("el punzón no se ha recogido")
	await _usar("Interactivos/ParedAlaA")
	await _captura("02_cap1_cartel")
	await _usar("Interactivos/Cartel")
	# ---- Recuerdo F1
	if not await _esperar_nivel(&"f1"):
		return
	await _esperar_control()
	await _captura("03_f1_calle")
	_calmar_enemigos()
	await _usar("Interactivos/SaltoCuboVolcado")
	await _usar("Interactivos/DerribarCubo0")
	await _zona("Zonas/Mitad")
	await _usar("Interactivos/Alcantarilla")
	if not Juego.bandera(&"carpeta_escondida"):
		_error("la carpeta no se ha escondido")
	await _zona("Zonas/Verja")
	# ---- Regreso al Bloque A
	if not await _esperar_nivel(&"cap1"):
		return
	await _esperar_control()
	await _captura("04_cap1_regreso")
	await _usar("Interactivos/PuertaFondo")
	await _zona("Zonas/EntrarAlaB")
	await get_tree().create_timer(2.0).timeout
	await _captura("05_cap1_ala_b")
	# Muerte de prueba: El Uniforme atrapa a Elías (ya sin punzón, para ver la muerte).
	Juego.estado["punzon"] = 0
	var uniforme := _nodo("Enemigos/Uniforme") as Enemigo
	if uniforme:
		uniforme.activar(Enemigo.Estado.PERSEGUIR)
		await _colocar_en(uniforme.global_position + uniforme.adelante() * 0.8)
		uniforme.atacar()
		var t := 0.0
		while not Juego.muriendo and t < 6.0:
			await get_tree().process_frame
			t += get_process_delta_time()
		if not Juego.muriendo:
			_error("El Uniforme no ha matado al jugador")
		else:
			_escribir("  muerte por El Uniforme: OK")
		if not await _esperar_nivel(&"cap1"):
			return
		_escribir("  CONTINUAR → reaparece en %s" % Juego.estado.get("punto", ""))
	await _esperar_control()
	if Juego.estado.get("punto", "") != "ala_b":
		await _usar("Interactivos/PuertaFondo")
	_calmar_enemigos()
	await _usar("Interactivos/ParedAlaB")
	await _usar("Interactivos/Volante", true)
	await get_tree().create_timer(1.0).timeout
	await _esperar_control()
	await _zona("Zonas/SalirAlPatio")
	# ---- Capítulo II
	if not await _esperar_nivel(&"cap2", 45.0):
		return
	await _esperar_control()
	await _captura("06_cap2_pasarela")
	_calmar_enemigos()
	await _usar("Interactivos/Circular")
	await _usar("Interactivos/Pistola")
	await _usar("Interactivos/Fusible1")
	await _usar("Interactivos/EscaleraBajar")
	await _captura("07_cap2_planta_baja")
	_calmar_enemigos()
	await _usar("Interactivos/Fusible2")
	await _usar("Interactivos/Municion")
	await _usar("Interactivos/Fusible3")
	await _usar("Interactivos/Botella_-2")
	await _usar("Interactivos/CajaFusibles")
	if not Juego.bandera(&"energia_ascensor"):
		_error("el ascensor no tiene corriente (fusibles: %d)" % Juego.contador(&"fusibles"))
	_calmar_enemigos()
	await _usar("Interactivos/Ascensor")
	# ---- Recuerdo F2
	if not await _esperar_nivel(&"f2"):
		return
	await _esperar_control(30.0)
	await _captura("08_f2_sala")
	_calmar_enemigos()
	await _usar("Interactivos/PuertaSala")
	await _usar("Interactivos/Salida")
	# ---- Capítulo III
	if not await _esperar_nivel(&"cap3"):
		return
	await _esperar_control()
	await _captura("09_cap3_pasillo")
	_calmar_enemigos()
	await _usar("Interactivos/Registro")
	await _usar("Interactivos/CubrirEspejo1")
	await get_tree().create_timer(1.5).timeout
	for k in [2, 0, 3, 1]:
		await _usar("Interactivos/CubrirEspejo%d" % k)
	await get_tree().create_timer(1.5).timeout
	if not Juego.bandera(&"espejos_resueltos"):
		_error("el puzle de los espejos no se ha resuelto")
	await _captura("10_cap3_espejos")
	await _usar("Interactivos/PuertaArchivo")
	await _usar("Interactivos/NotaGuardia")
	await _usar("Interactivos/CajaFuerte")
	# ---- Recuerdo F3
	if not await _esperar_nivel(&"f3"):
		return
	await _esperar_control(30.0)
	await _captura("11_f3_patio")
	_calmar_enemigos()
	await _usar("Interactivos/Llave")
	await _usar("Interactivos/PuertaServicio")
	# ---- Capítulo IV
	if not await _esperar_nivel(&"cap4"):
		return
	await _esperar_control()
	await _usar("Interactivos/Escopeta")
	await _usar("Interactivos/Orden")
	await _usar("Interactivos/ParedAntesala")
	await _captura("12_cap4_antesala")
	await _zona("Zonas/EntrarSala")
	await _esperar_control(30.0)
	await _captura("13_cap4_sala")
	_calmar_enemigos()
	for m in ["Palanca", "Volante", "Torno"]:
		await _usar("Interactivos/" + m, true)
	await get_tree().create_timer(2.5).timeout
	await _zona("Zonas/Escapar")
	# ---- Final
	if not await _esperar_nivel(&"final", 40.0):
		return
	await _esperar_control(30.0)
	await _captura("14_final")
	await _zona("Zonas/Voz1")
	await _zona("Zonas/Escena")
	var t2 := 0.0
	while t2 < 60.0 and not _escena_es("Creditos"):
		await get_tree().process_frame
		t2 += get_process_delta_time()
	if not _escena_es("Creditos"):
		_error("no se llegó a los créditos")
		return
	_escribir("créditos")
	await get_tree().create_timer(6.0).timeout
	await _captura("15_creditos")
	get_tree().current_scene.set(&"_saltar", true)
	var t3 := 0.0
	while t3 < 20.0 and not _escena_es("MenuPrincipal"):
		await get_tree().process_frame
		t3 += get_process_delta_time()
	if not _escena_es("MenuPrincipal"):
		_error("no se volvió al menú")
		return
	await get_tree().create_timer(4.0).timeout
	await _captura("16_menu")
	_escribir("demo completa: menú → capítulos I-IV → final → créditos → menú")
