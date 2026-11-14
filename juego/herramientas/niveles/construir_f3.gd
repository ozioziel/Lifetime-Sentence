extends Constructor
## Recuerdo F3 «El ingreso» (§5.1): la prisión en el pasado, viva y cálida (el mismo Patio
## Central, en la planta baja). Elías llega en una fila de presos nuevos; un guardia (placa
## 31) le deja caer la llave de los grilletes; hay que escapar del traslado hasta la puerta
## de servicio del fondo sin que los guardias lo vean. El verdugo mira desde una pasarela.

const ESC := "res://assets/escenarios/"
const TEX_MADERA := ESC + "ejecucion_madera_oscura.png"
const TEX_METAL := ESC + "patio_central_metal_pintado.png"
const PRESOS := ["preso_generico_a", "preso_generico_b", "preso_generico_c"]


func construir() -> int:
	nuevo_nivel(&"f3")
	entorno(Color(0.05, 0.035, 0.02), Color(0.34, 0.28, 0.2), 1.3, Color(0.26, 0.2, 0.13), 0.014,
			0.02, Color(0.95, 0.75, 0.5), 0.6)
	var patio := instancia(ESC + "patio_central.glb", raiz, "Patio")
	navegable(patio)
	var deco := grupo(raiz, "Decorado")
	navegable(deco)
	_mobiliario(deco)
	navegacion("Navegacion", AABB(Vector3(-14.5, -1.0, -39.0), Vector3(29.0, 3.0, 78.0)))
	hornear()

	finalizar("res://niveles/f3/f3.gd", {
		"id": &"f3", "epoca": 1, "superficie_pasos": &"hormigon",
		"ambiente": &"patio_pasado", "volumen_ambiente": -6.0, "capa_ambiente": &"murmullo_presos",
		"volumen_capa": -10.0,
	})
	_luces()
	_figuras()
	_camaras()
	_interactivos()
	_entradas()
	_enemigos()
	var polvo := CPUParticles3D.new()
	polvo.amount = 160
	polvo.lifetime = 9.0
	polvo.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	polvo.emission_box_extents = Vector3(7.0, 20.0, 34.0)
	polvo.gravity = Vector3(0, -0.02, 0)
	polvo.initial_velocity_min = 0.02
	polvo.initial_velocity_max = 0.08
	polvo.direction = Vector3(1, 0, 0)
	polvo.spread = 180.0
	var mota := BoxMesh.new()
	mota.size = Vector3(0.03, 0.03, 0.03)
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.albedo_color = Color(1.0, 0.85, 0.55, 0.5)
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mota.material = mm
	polvo.mesh = mota
	agregar(raiz, polvo, "Polvo")
	polvo.position = Vector3(0, 22, 0)
	var sonidos := grupo(raiz, "Sonidos")
	sonido(sonidos, "Radio", Vector3(6.0, 1.2, -10.0), "radio_antigua", -10.0, 14.0)
	sonido(sonidos, "Pelota", Vector3(-4.0, 0.5, 2.0), "pelota", -12.0, 16.0)
	jugador(Vector3(-4.0, 0, 34.0))
	return guardar("res://niveles/f3/f3.tscn")


func _mobiliario(deco: Node3D) -> void:
	var madera := material(TEX_MADERA, Color(1.0, 0.9, 0.8), 0.8)
	var metal := material(TEX_METAL, Color(0.85, 0.8, 0.72), 1.0)
	# Bancos y mesas del patio (se puede pasar por encima, K1).
	for b in [[Vector3(-6.0, 0, 8.0), 0.0], [Vector3(5.0, 0, 6.0), 90.0], [Vector3(-2.0, 0, -6.0), 0.0],
			[Vector3(6.5, 0, -16.0), 0.0], [Vector3(-7.0, 0, -22.0), 90.0]]:
		var g := grupo(deco, "Banco_%d_%d" % [int(b[0].x), int(b[0].z)])
		g.position = b[0]
		g.rotation_degrees.y = b[1]
		caja(g, "Tablero", Vector3(0, 0.45, 0), Vector3(2.2, 0.08, 0.45), madera)
		caja(g, "Pata1", Vector3(-0.95, 0.22, 0), Vector3(0.08, 0.44, 0.4), metal)
		caja(g, "Pata2", Vector3(0.95, 0.22, 0), Vector3(0.08, 0.44, 0.4), metal)
	# Carro de la lavandería y pilas de cajas: cobertura para colarse.
	for c in [Vector3(-9.5, 0, -2.0), Vector3(9.0, 0, -28.0), Vector3(-10.0, 0, -30.0), Vector3(2.5, 0, 18.0)]:
		caja(deco, "Cajas_%d_%d" % [int(c.x), int(c.z)], c + Vector3(0, 0.6, 0), Vector3(1.4, 1.2, 1.2), madera)
	caja(deco, "PuertaServicio", Vector3(-9.6, 1.1, -38.35), Vector3(1.2, 2.2, 0.12), metal)
	rotulo(deco, "RotuloServicio", "SERVICIO", Vector3(-9.6, 2.45, -38.25), 0.0, 0.1, Color(0.9, 0.82, 0.6))


func _luces() -> void:
	var l := grupo(raiz, "Luces")
	var sol := DirectionalLight3D.new()
	sol.light_color = Color(1.0, 0.78, 0.52)
	sol.light_energy = 1.8
	sol.shadow_enabled = true
	sol.directional_shadow_max_distance = 140.0
	sol.light_volumetric_fog_energy = 2.5
	agregar(l, sol, "Sol")
	sol.add_to_group(&"sombra_alta", true)
	sol.rotation_degrees = Vector3(-58, -30, 0)
	for p in [Vector3(0, 8.0, -18.0), Vector3(0, 24.0, 6.0), Vector3(0, 40.0, -10.0), Vector3(0, 14.0, 24.0)]:
		omni(l, "Calido_%d_%d" % [int(p.y), int(p.z)], p, Color(1.0, 0.8, 0.55), 1.3, 26.0)
	for z in [-30.0, -10.0, 10.0, 30.0]:
		omni(l, "PlantaBaja%d" % int(z), Vector3(0, 3.0, z), Color(1.0, 0.82, 0.6), 1.4, 12.0)
	omni(l, "Servicio", Vector3(-9.6, 2.7, -36.6), Color(1.0, 0.8, 0.55), 1.4, 5.0)


func _figuras() -> void:
	var f := grupo(raiz, "Figuras")
	# Fila del traslado (presos nuevos) delante y detrás de Elías.
	var fila := [Vector3(-4.0, 0, 30.0), Vector3(-4.0, 0, 31.4), Vector3(-4.0, 0, 32.8), Vector3(-4.0, 0, 35.3),
			Vector3(-4.0, 0, 36.7)]
	for k in fila.size():
		figura(f, "Fila%d" % k, PRESOS[k % 3], fila[k], 0.0, &"quieto").add_to_group(&"fila", true)
	# El guardia que ayuda (placa 31), junto a la fila.
	figura(f, "Guardia31", "guardia_penitenciario", Vector3(-2.9, 0, 33.6), 0.0, &"quieto")
	# Presos en el patio: grupos que charlan y algunos que pasean.
	var grupos := [Vector3(-7.0, 0, 12.0), Vector3(-6.2, 0, 12.8), Vector3(6.0, 0, 2.0), Vector3(6.8, 0, 2.6),
			Vector3(5.6, 0, 3.2), Vector3(-3.0, 0, -12.0), Vector3(-2.2, 0, -12.6), Vector3(8.0, 0, -20.0),
			Vector3(-8.0, 0, -15.0), Vector3(1.0, 0, -26.0), Vector3(1.8, 0, -25.4)]
	var i := 0
	for p in grupos:
		figura(f, "Preso%d" % i, PRESOS[i % 3], p, randf_range(-180, 180), &"quieto")
		i += 1
	for k in 4:
		var paseante := figura(f, "Paseante%d" % k, PRESOS[k % 3], Vector3(-9.0 + k * 6.0, 0, -4.0 + k * 3.0), 0.0, &"andar")
		paseante.add_to_group(&"paseante", true)
	# Presos en las pasarelas altas (la prisión viva).
	for p in [Vector3(-12.2, 6.4, 4.0), Vector3(-12.2, 9.6, -12.0), Vector3(12.2, 6.4, -6.0), Vector3(12.2, 3.2, 14.0),
			Vector3(12.2, 12.8, 2.0)]:
		figura(f, "Arriba_%d_%d" % [int(p.y), int(p.z)], PRESOS[int(p.z) % 3 if int(p.z) >= 0 else 1], p,
				90.0 if p.x > 0 else -90.0, &"quieto")
	# El verdugo, visto de lejos en la pasarela de la planta 4.
	figura(f, "Verdugo", "verdugo", Vector3(-12.2, 12.8, -14.0), -90.0, &"quieto")


func _camaras() -> void:
	var c := grupo(raiz, "Camaras")
	camara(c, "Fila", Vector3(-0.8, 1.7, 26.5), Vector3(-4.0, 1.2, 33.0), 52.0)
	camara(c, "Guardia", Vector3(-3.3, 1.65, 31.6), Vector3(-2.9, 1.55, 33.6), 40.0)
	camara(c, "Llave", Vector3(-3.0, 0.9, 33.0), Vector3(-3.6, 0.0, 34.1), 45.0)
	camara(c, "Patio", Vector3(6.0, 9.0, 34.0), Vector3(-2.0, 2.0, 0.0), 58.0)
	camara(c, "Verdugo", Vector3(-6.0, 1.6, -4.0), Vector3(-12.2, 14.4, -14.0), 34.0)
	camara(c, "Puerta", Vector3(-7.0, 1.6, -33.5), Vector3(-9.6, 1.2, -38.3), 52.0)


func _interactivos() -> void:
	var it := grupo(raiz, "Interactivos")
	componente("res://componentes/recogible.gd", it, "Llave", Vector3(-3.6, 0.1, 34.1), 0.0, {
		"tipo": 0, "objeto": &"llave_traslado", "texto": "Coger la llave", "activo": false})
	componente("res://componentes/interactuable.gd", it, "PuertaServicio", Vector3(-9.6, 1.0, -37.6), 0.0, {
		"texto": "Abrir la puerta de servicio", "cerradura": 2, "objeto_necesario": &"llave_traslado",
		"texto_cerrado": "Cerrada con llave.", "metodo_nivel": &"puerta_servicio", "una_vez": true,
		"persistente": false})
	for b in [["SaltoBanco1", Vector3(-6.0, 0.45, 8.0)], ["SaltoBanco2", Vector3(5.0, 0.45, 6.0)],
			["SaltoBanco3", Vector3(-2.0, 0.45, -6.0)], ["SaltoBanco4", Vector3(6.5, 0.45, -16.0)],
			["SaltoBanco5", Vector3(-7.0, 0.45, -22.0)]]:
		componente("res://componentes/obstaculo.gd", it, b[0], b[1], 0.0, {"tipo": 0, "distancia": 1.6})
	var z := grupo(raiz, "Zonas")
	zona_camara(z, "ZonaPatio", Vector3(0, 1.5, 0), Vector3(26.0, 3.0, 76.0), 2.6, 1.65, 0.35, 64.0, 1)
	disparador(z, "VerVerdugo", Vector3(-4.0, 1.2, -2.0), Vector3(10.0, 2.4, 1.5), &"ver_verdugo", true)
	disparador(z, "MitadPatio", Vector3(0, 1.2, 0.0), Vector3(26.0, 2.4, 1.0), &"mitad_patio", true)


func _entradas() -> void:
	var e := grupo(raiz, "Entradas")
	punto_entrada(e, &"inicio", Vector3(-4.0, 0, 34.0), 0.0)
	punto_entrada(e, &"mitad", Vector3(-11.0, 0, -0.5), 0.0)


func _enemigos() -> void:
	var g := grupo(raiz, "Enemigos")
	var props := {"tipo": 2, "linterna": false, "vision_distancia": 12.0, "vision_angulo": 90.0}
	# Guardias del traslado: delante y detrás de la fila.
	enemigo("res://enemigos/policia.gd", g, "Escolta1", Vector3(-4.0, 0, 28.6), 0.0, props.merged({"estado_inicial": 1}))
	enemigo("res://enemigos/policia.gd", g, "Escolta2", Vector3(-4.6, 0, 38.0), 0.0, props.merged({"estado_inicial": 1}))
	# Guardias que patrullan el patio.
	ruta(g, "RutaG1", [Vector3(4.0, 0, 20.0), Vector3(4.0, 0, -2.0), Vector3(-5.0, 0, -2.0), Vector3(-5.0, 0, 20.0)])
	ruta(g, "RutaG2", [Vector3(8.0, 0, -8.0), Vector3(-2.0, 0, -18.0), Vector3(8.0, 0, -30.0)])
	ruta(g, "RutaG3", [Vector3(-9.6, 0, -33.0), Vector3(-2.0, 0, -34.0), Vector3(-6.0, 0, -26.0)])
	enemigo("res://enemigos/policia.gd", g, "Guardia1", Vector3(4.0, 0, 20.0), 180.0, props.merged({"ruta": NodePath("../RutaG1")}))
	enemigo("res://enemigos/policia.gd", g, "Guardia2", Vector3(8.0, 0, -8.0), 0.0, props.merged({"ruta": NodePath("../RutaG2"), "espera_en_punto": 3.0}))
	enemigo("res://enemigos/policia.gd", g, "Guardia3", Vector3(-9.6, 0, -33.0), 180.0, props.merged({"ruta": NodePath("../RutaG3"), "espera_en_punto": 4.0}))
