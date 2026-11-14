extends Constructor
## Recuerdo F1 «La huida» (storyboard §6, paso 1.5): calles lluviosas, noche, luz de sodio.
## Motivo (G5): esconder la carpeta antes de que lo detengan. Persecución de goma elástica,
## silbato y refuerzos, tácticos cortando las calles laterales, obstáculos que saltar o
## derribar y, al final, la verja: acorralado (N3) → golpe metálico → presente (D6).
## El callejón de Blender llega hasta z = -30; aquí se amplía con el kit de la ciudad.

const ESC := "res://assets/escenarios/"
const TEX_ASFALTO := ESC + "callejon_asfalto.png"
const TEX_LADRILLO := ESC + "callejon_ladrillo.png"
const TEX_HIERRO := ESC + "bloque_a_juego_hierro_oxidado.png"
const SODIO := Color(1.0, 0.6, 0.27)


func construir() -> int:
	nuevo_nivel(&"f1")
	entorno(Color(0.015, 0.018, 0.03), Color(0.22, 0.18, 0.15), 1.15, Color(0.1, 0.085, 0.075), 0.016,
			0.022, Color(0.75, 0.6, 0.45), 0.45)
	var callejon := instancia(ESC + "callejon.glb", raiz, "Callejon")
	navegable(callejon)
	var calle := grupo(raiz, "Ampliacion")
	navegable(calle)
	_ampliacion(calle)
	navegacion("Navegacion", AABB(Vector3(-23, -1, -92), Vector3(46, 4, 106)))
	hornear()

	finalizar("res://niveles/f1/f1.gd", {
		"id": &"f1", "epoca": 1, "vestuario_civil": true, "superficie_pasos": &"charco",
		"ambiente": &"lluvia", "volumen_ambiente": -4.0, "capa_ambiente": &"ciudad_noche", "volumen_capa": -14.0,
	})
	componente("res://componentes/lluvia.gd", raiz, "Lluvia", Vector3.ZERO, 0.0, {}, "GPUParticles3D")
	_luces()
	_camaras()
	_interactivos()
	_entradas()
	_enemigos()
	var sonidos := grupo(raiz, "Sonidos")
	sonido(sonidos, "Sirena", Vector3(12.0, 1.5, -34.0), "sirena", -6.0, 40.0)
	sonido(sonidos, "Radio", Vector3(1.2, 1.2, -21.0), "radio_policia", -8.0, 12.0)
	sonido(sonidos, "Canalon", Vector3(-2.6, 3.0, -12.0), "canalon", -8.0, 10.0)
	jugador(Vector3(-1.6, 0, -0.7))
	return guardar("res://niveles/f1/f1.tscn")


func _ampliacion(g: Node3D) -> void:
	var asfalto := material(TEX_ASFALTO, Color(0.85, 0.85, 0.9), 0.35)
	var ladrillo := material(TEX_LADRILLO, Color.WHITE, 0.45)
	var hierro := material(TEX_HIERRO, Color.WHITE, 1.0)
	var negro := material("", Color(0.0, 0.0, 0.0))
	# Suelo: calle principal hasta la verja y calles laterales del cruce.
	caja(g, "SueloCalle", Vector3(0, -0.15, -66.0), Vector3(7.6, 0.3, 52.0), asfalto)
	caja(g, "SueloLateralE", Vector3(13.0, -0.15, -34.0), Vector3(18.4, 0.3, 8.4), asfalto)
	caja(g, "SueloLateralO", Vector3(-13.0, -0.15, -34.0), Vector3(18.4, 0.3, 8.4), asfalto)
	# Fachadas de la calle principal (z -38 a -86), alternando los dos tipos del kit.
	for k in 8:
		var tipo_e := "Kit_Fachada_B" if k % 2 == 0 else "Kit_Fachada_A"
		var tipo_o := "Kit_Fachada_A" if k % 2 == 0 else "Kit_Fachada_B"
		pieza(g, "FachadaE%d" % k, "kit_ciudad", tipo_e, Vector3(2.8, 0, -86.0 + 6.0 * k), -90.0, 1)
		pieza(g, "FachadaO%d" % k, "kit_ciudad", tipo_o, Vector3(-2.8, 0, -38.0 - 6.0 * k), 90.0, 1)
	# Fachadas de las calles laterales del cruce (z -30 a -38).
	for k in 3:
		pieza(g, "LatEN%d" % k, "kit_ciudad", "Kit_Fachada_B", Vector3(9.2 + 6.0 * k, 0, -30.4), 180.0, 1)
		pieza(g, "LatES%d" % k, "kit_ciudad", "Kit_Fachada_B", Vector3(3.2 + 6.0 * k, 0, -37.6), 0.0, 1)
		pieza(g, "LatON%d" % k, "kit_ciudad", "Kit_Fachada_B", Vector3(-3.2 - 6.0 * k, 0, -30.4), 180.0, 1)
		pieza(g, "LatOS%d" % k, "kit_ciudad", "Kit_Fachada_B", Vector3(-9.2 - 6.0 * k, 0, -37.6), 0.0, 1)
	# Fondo negro de las calles laterales (se pierden en la oscuridad).
	caja(g, "FinLateralE", Vector3(21.4, 4.0, -34.0), Vector3(0.4, 8.0, 8.0), negro, true)
	caja(g, "FinLateralO", Vector3(-21.4, 4.0, -34.0), Vector3(0.4, 8.0, 8.0), negro, true)
	# Fondo de la calle por detrás del inicio (un edificio que la cierra).
	caja(g, "FinCalleInicio", Vector3(0, 7.5, 8.2), Vector3(7.6, 15.0, 0.4), ladrillo)
	# Verja del final (N3) y muros que cierran la calle a los lados.
	pieza(g, "Verja", "kit_ciudad", "Kit_Verja", Vector3(-2.84, 0, -86.2), 0.0, 1)
	caja(g, "MuroVerjaE", Vector3(3.3, 1.6, -86.2), Vector3(1.0, 3.2, 0.5), ladrillo)
	caja(g, "MuroVerjaO", Vector3(-3.3, 1.6, -86.2), Vector3(1.0, 3.2, 0.5), ladrillo)
	# Obstáculos de la calle (K1, S1): cajas para pasar por encima y cubos para derribar.
	for c in [[Vector3(-1.4, 0, -47.0), 10.0], [Vector3(-0.6, 0, -47.3), -8.0], [Vector3(-1.0, 0.6, -47.15), 25.0],
			[Vector3(0.9, 0, -66.0), 0.0], [Vector3(1.6, 0, -66.2), 15.0], [Vector3(1.25, 0.6, -66.1), -12.0]]:
		pieza(g, "Caja_%d_%d" % [int(c[0].x * 10), int(c[0].y * 10)], "kit_ciudad", "Kit_Caja", c[0], c[1], 1)
	pieza(g, "CuboE", "kit_ciudad", "Kit_Cubo", Vector3(2.1, 0, -53.0), 0.0, 1)
	pieza(g, "CuboO", "kit_ciudad", "Kit_Cubo", Vector3(-2.2, 0, -72.0), 0.0, 1)
	pieza(g, "Contenedor2", "kit_ciudad", "Kit_Contenedor", Vector3(1.5, 0, -60.5), -90.0, 1)
	pieza(g, "CochePatrulla2", "kit_ciudad", "Kit_Coche_Patrulla", Vector3(11.5, 0, -34.0), 90.0, 2)
	# Farolas de sodio en la pared oeste.
	for z in [-45.0, -61.0, -77.0]:
		pieza(g, "Farola%d" % int(-z), "kit_ciudad", "Kit_Farola", Vector3(-3.9, 4.2, z), 90.0, 0)
	# Rejilla de la alcantarilla (aquí se esconde la carpeta).
	caja(g, "Alcantarilla", Vector3(2.75, 0.01, -63.2), Vector3(0.5, 0.04, 0.7), hierro, false)


func _luces() -> void:
	var l := grupo(raiz, "Luces")
	for z in [-3.5, -16.0, -45.0, -61.0, -77.0]:
		omni(l, "Sodio%d" % int(-z), Vector3(-2.75, 4.15, z), SODIO, 2.8, 12.0, z > -20.0)
	omni(l, "SodioCruce", Vector3(0.0, 5.0, -34.0), SODIO, 2.0, 14.0)
	omni(l, "Escaparate", Vector3(2.2, 2.0, -10.5), Color(0.55, 0.62, 0.75), 0.8, 5.0)
	omni(l, "VentanaAlta", Vector3(-2.0, 7.5, -27.0), Color(1.0, 0.82, 0.5), 1.2, 8.0)
	omni(l, "SodioVerja", Vector3(2.6, 3.9, -83.5), SODIO, 2.6, 11.0, true)
	omni(l, "SodioInicio", Vector3(2.4, 4.0, 4.5), SODIO, 2.2, 10.0)
	# Luces giratorias de los coches patrulla (las hace parpadear el script del nivel).
	omni(l, "Giratorio1", Vector3(1.2, 1.8, -21.0), Color(0.15, 0.3, 1.0), 3.0, 9.0)
	omni(l, "Giratorio2", Vector3(11.5, 1.8, -34.0), Color(1.0, 0.1, 0.08), 3.0, 9.0)
	# La prisión en la colina, al fondo (M4): luz fría y lejana sobre su silueta.
	foco(l, "LuzPrision", Vector3(0, 40, -70), Vector3(0, 60, -150), Color(0.6, 0.7, 0.9), 6.0, 160.0, 30.0, false)


func _camaras() -> void:
	var c := grupo(raiz, "Camaras")
	camara(c, "Cartel", Vector3(-1.85, 1.72, -0.71), Vector3(-2.78, 1.71, -0.71), 38.0)
	camara(c, "Policias", Vector3(-1.2, 1.3, -2.6), Vector3(0.5, 1.4, 9.0), 50.0)
	camara(c, "Persecucion", Vector3(2.5, 3.6, -14.0), Vector3(-0.5, 1.0, -2.0), 55.0)
	camara(c, "Verja", Vector3(0.6, 1.7, -88.6), Vector3(-0.1, 1.35, -84.5), 48.0)
	camara(c, "VerjaContra", Vector3(-1.6, 1.2, -80.0), Vector3(0.0, 1.6, -86.2), 55.0)
	camara(c, "Prision", Vector3(0.0, 1.6, -82.0), Vector3(0.0, 28.0, -150.0), 50.0)


func _interactivos() -> void:
	var it := grupo(raiz, "Interactivos")
	componente("res://componentes/interactuable.gd", it, "Alcantarilla", Vector3(2.75, 0.3, -63.2), 0.0, {
		"texto": "Esconder la carpeta en la alcantarilla", "animacion": &"esconder_objeto",
		"metodo_nivel": &"carpeta_escondida", "una_vez": true, "persistente": false, "radio": 1.5})
	# Obstáculos del pasado (solo se pueden usar en el pasado).
	componente("res://componentes/obstaculo.gd", it, "SaltoCuboVolcado", Vector3(-0.37, 0.4, -6.67), 0.0, {"tipo": 0})
	componente("res://componentes/obstaculo.gd", it, "SaltoCajas1", Vector3(-1.0, 0.5, -47.15), 0.0, {"tipo": 0})
	componente("res://componentes/obstaculo.gd", it, "SaltoCajas2", Vector3(1.25, 0.5, -66.1), 0.0, {"tipo": 0})
	for d in [["DerribarCubo0", Vector3(2.3, 0.5, -8.0), "../../Callejon/Cubo_0"],
			["DerribarCubo1", Vector3(2.0, 0.5, -3.0), "../../Callejon/Cubo_1"],
			["DerribarCubo2", Vector3(-2.3, 0.5, -10.5), "../../Callejon/Cubo_2"],
			["DerribarCuboE", Vector3(2.1, 0.5, -53.0), "../../Ampliacion/CuboE"],
			["DerribarCuboO", Vector3(-2.2, 0.5, -72.0), "../../Ampliacion/CuboO"]]:
		componente("res://componentes/obstaculo.gd", it, d[0], d[1], 0.0, {"tipo": 1, "pieza": NodePath(d[2])})
	var z := grupo(raiz, "Zonas")
	zona_camara(z, "ZonaCalle", Vector3(0, 3.0, -38.0), Vector3(8.0, 6.0, 100.0), 2.4, 1.6, 0.35, 64.0, 1)
	zona_camara(z, "ZonaCruce", Vector3(0, 3.0, -34.0), Vector3(44.0, 6.0, 8.0), 2.8, 1.7, 0.3, 66.0, 2)
	disparador(z, "Mitad", Vector3(0, 1.5, -41.0), Vector3(8.0, 3.0, 1.0), &"punto_mitad")
	disparador(z, "Verja", Vector3(0, 1.5, -83.0), Vector3(8.0, 3.0, 2.0), &"verja")


func _entradas() -> void:
	var e := grupo(raiz, "Entradas")
	punto_entrada(e, &"inicio", Vector3(-1.6, 0, -0.7), 90.0)
	punto_entrada(e, &"mitad", Vector3(0.0, 0, -42.0), 0.0)


func _enemigos() -> void:
	var g := grupo(raiz, "Enemigos")
	var props := {"tipo": 0, "estado_inicial": 0}
	enemigo("res://enemigos/policia.gd", g, "Patrullero1", Vector3(0.4, 0, 5.2), 0.0, props)
	enemigo("res://enemigos/policia.gd", g, "Patrullero2", Vector3(-1.4, 0, 6.8), 0.0, props)
	# Refuerzos: esperan escondidos hasta que suena el silbato.
	enemigo("res://enemigos/policia.gd", g, "Refuerzo1", Vector3(2.4, 0, -25.5), -90.0, props)
	enemigo("res://enemigos/policia.gd", g, "Refuerzo2", Vector3(-6.0, 0, -33.0), -90.0, props)
	enemigo("res://enemigos/policia.gd", g, "Refuerzo3", Vector3(-2.2, 0, -58.0), 90.0, props)
	# Tácticos: cortan las calles laterales del cruce.
	for t in [["TacticoE1", Vector3(8.0, 0, -32.6)], ["TacticoE2", Vector3(8.4, 0, -35.4)],
			["TacticoO1", Vector3(-8.0, 0, -32.8)], ["TacticoO2", Vector3(-8.3, 0, -35.2)]]:
		var rot := 90.0 if t[1].x > 0 else -90.0
		enemigo("res://enemigos/policia.gd", g, t[0], t[1], rot, {"tipo": 1, "estado_inicial": 1, "silba": true})
