extends Constructor
## Capítulo II «Patio Central» (§5.1): revelación monumental (grúa), colgados (H4),
## siluetas que desaparecen (E6), El Vigilante barriendo la pasarela de la planta 10 desde
## el anillo de la torre (K7), escalera de servicio a la planta baja, Los Aislados (K5),
## tres fusibles para el ascensor antiguo y, dentro del ascensor, la nota que lleva a F2.
##
## Geometría del patio (assets/scripts/patio_central.py): muros de celdas en x = ±13,
## pasarelas de 1,6 m hacia el centro, una planta cada 3,2 m (planta 10 = y 32), muros
## norte y sur en z = ±38,4, torre en (0, 27) con su anillo en y = 34,3.

const ESC := "res://assets/escenarios/"
const TEX_METAL := ESC + "patio_central_metal_pintado.png"
const TEX_HIERRO := ESC + "patio_central_hierro_oxidado.png"
const TEX_MADERA := ESC + "ejecucion_madera_oscura.png"
const TEX_SANGRE := ESC + "ejecucion_sangre_charco.png"
const TEX_PAPEL := ESC + "comisaria_papeles.png"
const Y10 := 32.0
const XO := -12.2
const ASCENSOR := Vector3(8.6, 0, 33.0)


func construir() -> int:
	nuevo_nivel(&"cap2")
	entorno(Color(0.02, 0.025, 0.035), Color(0.2, 0.23, 0.28), 1.7, Color(0.1, 0.12, 0.15), 0.011,
			0.018, Color(0.6, 0.7, 0.82), 0.5)
	var patio := instancia(ESC + "patio_central.glb", raiz, "Patio")
	navegable(patio)
	var deco := grupo(raiz, "Decorado")
	navegable(deco)
	_ascensor(deco)
	_decorado(deco)
	navegacion("NavPlanta10", AABB(Vector3(-14.5, Y10 - 1.0, -39.0), Vector3(29.0, 3.5, 78.0)))
	navegacion("NavPlantaBaja", AABB(Vector3(-14.5, -1.0, -39.0), Vector3(29.0, 3.0, 78.0)))
	hornear()

	finalizar("res://niveles/cap2/cap2.gd", {
		"id": &"cap2", "epoca": 0, "superficie_pasos": &"metal",
		"ambiente": &"patio_viento", "volumen_ambiente": -8.0, "capa_ambiente": &"zumbido_pabellon",
		"volumen_capa": -18.0,
	})
	_luces()
	_figuras()
	_camaras()
	_interactivos()
	_entradas()
	_enemigos()
	var sonidos := grupo(raiz, "Sonidos")
	sonido(sonidos, "FocoTorre", Vector3(0, 35.0, 27.0), "foco_zumbido", -8.0, 30.0)
	sonido(sonidos, "Cadenas", Vector3(0, Y10 - 1.0, -20.0), "cadenas_viento", -10.0, 25.0)
	sonido(sonidos, "Gemidos", Vector3(0, 1.0, 0.0), "aislados_lejos", -10.0, 40.0)
	jugador(Vector3(XO, Y10, 34.0))
	return guardar("res://niveles/cap2/cap2.tscn")


func _ascensor(deco: Node3D) -> void:
	var hierro := material(TEX_HIERRO, Color.WHITE, 1.4)
	var metal := material(TEX_METAL, Color(0.8, 0.82, 0.78), 1.0)
	var a := grupo(deco, "Ascensor")
	a.position = ASCENSOR
	caja(a, "Suelo", Vector3(0, 0.05, 0), Vector3(2.2, 0.1, 2.2), metal)
	caja(a, "Techo", Vector3(0, 2.75, 0), Vector3(2.3, 0.1, 2.3), hierro, false)
	# Barrotes de la jaula en tres lados (la puerta está en el lado -X).
	for k in 11:
		var t := -1.05 + k * 0.21
		caja(a, "BarroteN%d" % k, Vector3(t, 1.4, -1.08), Vector3(0.04, 2.7, 0.04), hierro)
		caja(a, "BarroteS%d" % k, Vector3(t, 1.4, 1.08), Vector3(0.04, 2.7, 0.04), hierro)
		caja(a, "BarroteE%d" % k, Vector3(1.08, 1.4, t), Vector3(0.04, 2.7, 0.04), hierro)
	for y in [0.4, 1.4, 2.4]:
		caja(a, "AnilloN%d" % int(y * 10), Vector3(0, y, -1.08), Vector3(2.2, 0.06, 0.06), hierro, false)
		caja(a, "AnilloS%d" % int(y * 10), Vector3(0, y, 1.08), Vector3(2.2, 0.06, 0.06), hierro, false)
		caja(a, "AnilloE%d" % int(y * 10), Vector3(1.08, y, 0), Vector3(0.06, 0.06, 2.2), hierro, false)
	# Reja corredera de la puerta (se cierra en la cinemática).
	var reja := grupo(a, "Reja")
	for k in 6:
		caja(reja, "Barra%d" % k, Vector3(-1.1, 1.4, -0.9 + k * 0.08), Vector3(0.03, 2.7, 0.03), hierro, false)
	# Torre del motor por encima (la jaula cuelga de cables).
	caja(a, "Cabria", Vector3(0, 6.0, 0), Vector3(0.3, 6.5, 0.3), hierro, false)
	caja(a, "Cable", Vector3(0, 4.0, 0), Vector3(0.03, 2.5, 0.03), hierro, false)
	# Caja de fusibles en un poste junto a la puerta.
	caja(a, "PosteFusibles", Vector3(-1.6, 0.8, -1.2), Vector3(0.12, 1.6, 0.12), hierro)
	caja(a, "CajaFusibles", Vector3(-1.6, 1.35, -1.08), Vector3(0.42, 0.55, 0.14), metal, false)
	rotulo(a, "Rotulo", "ASCENSOR DE SERVICIO\nSÓTANO — ENFERMERÍA", Vector3(-1.13, 2.2, 0), -90.0, 0.08,
			Color(0.75, 0.7, 0.55))


func _decorado(deco: Node3D) -> void:
	var madera := material(TEX_MADERA, Color.WHITE, 0.8)
	var metal := material(TEX_METAL, Color(0.8, 0.82, 0.78), 1.0)
	# Mesa del puesto de guardia en la planta baja.
	caja(deco, "MesaGuardia", Vector3(0, 0.75, -8.0), Vector3(1.8, 0.08, 0.9), madera)
	for p in [Vector3(-0.8, 0.37, -8.35), Vector3(0.8, 0.37, -8.35), Vector3(-0.8, 0.37, -7.65), Vector3(0.8, 0.37, -7.65)]:
		caja(deco, "PataMesa%d" % int(p.x * 10 + p.z), p, Vector3(0.06, 0.74, 0.06), metal)
	caja(deco, "Silla", Vector3(0.4, 0.45, -7.1), Vector3(0.45, 0.06, 0.45), metal)
	# Escrito en la pared de la planta baja (los Aislados).
	rotulo(deco, "Escrito1", "NO HAGAS RUIDO", Vector3(-12.95, 1.9, 10.0), 90.0, 0.32, Color(0.35, 0.04, 0.03))
	rotulo(deco, "Escrito2", "ELLOS NO VEN\nELLOS OYEN", Vector3(-12.95, 1.15, 12.4), 90.0, 0.22, Color(0.35, 0.04, 0.03))
	rotulo(deco, "Escrito3", "NO HAGAS RUIDO", Vector3(-12.95, 2.3, 14.5), 90.0, 0.18, Color(0.3, 0.03, 0.02))
	# Sangre seca en la planta baja y en la pasarela.
	var manchas := [[Vector3(-1.5, 0.01, -9.0), 2.0], [Vector3(-10.0, 0.01, 12.0), 1.6], [Vector3(6.0, 0.01, 20.0), 1.8],
			[Vector3(XO, Y10 + 0.012, 4.0), 1.2], [Vector3(-3.0, 0.01, -25.0), 2.2], [Vector3(9.0, 0.01, 30.5), 1.5]]
	var i := 0
	for m in manchas:
		lamina(deco, "Sangre%d" % i, TEX_SANGRE, m[0], Vector2(m[1], m[1]), Vector3(-90, i * 47.0, 0), 0.5)
		i += 1
	lamina(deco, "PapelCircular", TEX_PAPEL, Vector3(XO + 0.3, Y10 + 0.012, 30.5), Vector2(0.3, 0.4), Vector3(-90, 20, 0), 0.0)
	# Fusibles visibles donde se recogen.
	for f in [Vector3(XO + 0.4, Y10 + 0.06, 3.4), Vector3(0.3, 0.83, -8.1), Vector3(-10.4, 0.06, 12.0)]:
		caja(deco, "FusibleVisible_%d" % int(f.z), f, Vector3(0.08, 0.08, 0.16), material("", Color(0.85, 0.82, 0.72)), false)


func _luces() -> void:
	var l := grupo(raiz, "Luces")
	# Luna a través del tragaluz: haces fríos desde arriba (con niebla volumétrica en ALTO).
	var luna := DirectionalLight3D.new()
	luna.light_color = Color(0.55, 0.66, 0.85)
	luna.light_energy = 1.3
	luna.shadow_enabled = true
	luna.directional_shadow_max_distance = 140.0
	luna.light_volumetric_fog_energy = 2.5
	agregar(l, luna, "Luna")
	luna.add_to_group(&"sombra_alta", true)
	luna.rotation_degrees = Vector3(-62, 25, 0)
	# Relleno frío en el vacío (sin sombras): que se lea la escala del pabellón.
	for p in [Vector3(0, 10.0, -18.0), Vector3(0, 26.0, 8.0), Vector3(0, 42.0, -14.0), Vector3(0, 18.0, 26.0)]:
		omni(l, "Vacio_%d_%d" % [int(p.y), int(p.z)], p, Color(0.55, 0.64, 0.78), 1.4, 28.0)
	# Cabina de la torre: el resplandor cálido de sus ventanas.
	omni(l, "CabinaTorre", Vector3(0, 37.0, 27.0), Color(1.0, 0.75, 0.45), 3.5, 24.0)
	for x in [-4.0, 4.0]:
		omni(l, "VentanasTorre%d" % int(x), Vector3(x, 37.2, 27.0), Color(1.0, 0.72, 0.42), 2.2, 9.0)
	# Colgados bajo el puente de la planta 10.
	omni(l, "LuzColgados", Vector3(0.0, 30.5, -17.5), Color(0.6, 0.68, 0.8), 1.6, 9.0)
	# Pasarela de la planta 10: luces de emergencia frías y débiles.
	for z in [33.0, 21.0, 9.0, -3.0, -15.0, -27.0, -35.0]:
		omni(l, "Pasarela%d" % int(z), Vector3(XO - 0.5, Y10 + 2.6, z), Color(0.62, 0.72, 0.78), 1.0, 7.0)
	omni(l, "PasarelaNorte", Vector3(-6.0, Y10 + 2.6, -37.5), Color(0.62, 0.72, 0.78), 1.0, 7.0)
	# Planta baja: casi a oscuras, luces rojas de emergencia.
	for p in [Vector3(-12.0, 2.8, -22.0), Vector3(12.0, 2.8, 0.0), Vector3(-12.0, 2.8, 18.0), Vector3(0.0, 3.0, -32.0),
			Vector3(11.0, 2.8, 26.0)]:
		omni(l, "Emergencia_%d" % int(p.z), p, Color(0.78, 0.12, 0.07), 2.0, 12.0)
	omni(l, "Flexo", Vector3(0.2, 1.4, -8.0), Color(1.0, 0.8, 0.5), 1.4, 4.0)
	omni(l, "LuzAscensor", ASCENSOR + Vector3(0, 2.5, 0), Color(0.9, 0.85, 0.6), 0.35, 6.0)
	omni(l, "LuzServicio", Vector3(-9.6, 2.6, -36.0), Color(0.65, 0.72, 0.75), 1.2, 6.0)
	for x in [-8.0, 0.0, 8.0]:
		luz_alarma(l, "Alarma%d" % int(x), Vector3(x, Y10 + 3.0, 0.0), 14.0)


func _figuras() -> void:
	var f := grupo(raiz, "Figuras")
	# Colgados bajo los puentes (H4). Cuerda + cuerpo; el script los balancea.
	var colgados := [[Vector3(-6.0, 0, -20.0), Y10, "preso_generico_a"], [Vector3(-0.5, 0, -20.0), Y10, "preso_generico_b"],
			[Vector3(5.0, 0, -20.0), Y10, "preso_generico_c"], [Vector3(-3.5, 0, -24.0), 25.6, "preso_generico_b"],
			[Vector3(3.0, 0, -24.0), 25.6, "preso_generico_a"], [Vector3(1.0, 0, -30.0), 38.4, "preso_generico_c"],
			[Vector3(-4.0, 0, 6.0), 19.2, "preso_generico_a"]]
	var cuerda := material("", Color(0.32, 0.28, 0.22))
	var i := 0
	for c in colgados:
		var puente_y: float = c[1]
		var g := grupo(f, "Colgado%d" % i)
		g.position = Vector3(c[0].x, puente_y - 0.55, c[0].z)
		caja(g, "Cuerda", Vector3(0, -0.4, 0), Vector3(0.025, 0.8, 0.025), cuerda, false)
		var cuerpo := figura(g, "Cuerpo", c[2], Vector3(0, -2.65, 0), randf_range(-180, 180), &"quieto", 0.0)
		cuerpo.rotation_degrees.x = 4.0
		g.add_to_group(&"colgado", true)
		i += 1
	# Siluetas inmóviles en las pasarelas altas del otro lado (E6).
	var siluetas := [[Vector3(12.2, 38.4, -8.0), "preso_generico_c", 90.0], [Vector3(12.2, 44.8, 6.0), "preso_generico_a", 90.0],
			[Vector3(12.2, 38.4, 16.0), "preso_generico_b", 90.0], [Vector3(-2.0, 44.8, -37.6), "preso_generico_a", 180.0]]
	i = 0
	for s in siluetas:
		var fig := figura(f, "Silueta%d" % i, s[1], s[0], s[2], &"quieto", 0.3)
		fig.add_to_group(&"silueta", true)
		i += 1
	# Guardia muerto en la pasarela (lleva la pistola y un fusible).
	var guardia := figura(f, "GuardiaPasarela", "guardia_penitenciario", Vector3(XO + 0.1, Y10 + 0.14, 4.0), 0.0, &"quieto", 0.0)
	guardia.rotation_degrees = Vector3(-88, 10, 0)
	# Cadáveres en la planta baja.
	figura(f, "CadaverPB1", "aislado_b", Vector3(-1.2, 0, -9.6), 40.0, &"morir", 1.0)
	figura(f, "CadaverPB2", "aislado_a", Vector3(6.4, 0, 20.4), -100.0, &"morir", 1.0)
	figura(f, "CadaverPB3", "aislado_b", Vector3(-9.5, 0, 12.8), 160.0, &"morir", 1.0)


func _camaras() -> void:
	var c := grupo(raiz, "Camaras")
	var g0 := camara(c, "Grua", Vector3(XO + 0.4, Y10 + 1.7, 36.6), Vector3(XO, Y10 + 1.1, 32.0), 60.0)
	g0.far = 200.0
	marcador(c, "Grua0", Vector3(XO + 0.4, Y10 + 1.7, 36.6), Vector3(XO, Y10 + 1.1, 32.0))
	marcador(c, "Grua1", Vector3(-3.0, Y10 + 6.0, 30.0), Vector3(XO, Y10 + 0.8, 26.0))
	marcador(c, "Grua2", Vector3(6.0, Y10 + 12.0, 8.0), Vector3(-4.0, 14.0, -28.0))
	camara(c, "Vacio", Vector3(9.5, 47.0, 34.0), Vector3(-4.0, 6.0, -30.0), 64.0)
	camara(c, "Vigilante", Vector3(XO + 0.5, Y10 + 1.5, 13.0), Vector3(-3.0, 35.6, 27.0), 42.0)
	camara(c, "Colgados", Vector3(XO + 0.6, Y10 + 1.2, -12.0), Vector3(0.0, 29.0, -20.0), 50.0)
	camara(c, "PlantaBaja", Vector3(-11.0, 1.6, -33.0), Vector3(2.0, 1.0, -5.0), 58.0)
	camara(c, "AscensorDentro", ASCENSOR + Vector3(0.8, 1.9, 0.75), ASCENSOR + Vector3(-1.2, 1.1, -0.6), 62.0)
	camara(c, "AscensorFuera", ASCENSOR + Vector3(-5.5, 1.4, -2.5), ASCENSOR + Vector3(0, 1.3, 0), 50.0)


func _interactivos() -> void:
	var it := grupo(raiz, "Interactivos")
	componente("res://componentes/documento.gd", it, "Circular", Vector3(XO + 0.3, Y10 + 0.1, 30.5), 0.0, {
		"id_documento": &"circular_recuento", "texto": "Leer el papel"})
	componente("res://componentes/recogible.gd", it, "Pistola", Vector3(XO + 0.3, Y10 + 0.3, 4.3), 0.0, {
		"tipo": 2, "texto": "Registrar al guardia",
		"comentario": "(La funda aún está abrochada. Seis balas.)"})
	componente("res://componentes/interactuable.gd", it, "Fusible1", Vector3(XO + 0.4, Y10 + 0.2, 3.4), 0.0, {
		"texto": "Coger el fusible", "animacion": &"recoger", "metodo_nivel": &"coger_fusible", "una_vez": true})
	componente("res://componentes/pared_marcas.gd", it, "ParedP10", Vector3(-12.85, Y10 + 1.2, -28.0), 0.0, {"punto": &"pared_p10"})
	componente("res://componentes/puerta_transicion.gd", it, "EscaleraBajar", Vector3(-9.6, Y10 + 1.0, -37.2), 0.0, {
		"destino": NodePath("../../Entradas/Entrada_planta_baja"), "texto": "Bajar por la escalera de servicio",
		"sonido_puerta": &"escalera_servicio", "espera_en_negro": 1.6})
	componente("res://componentes/puerta_transicion.gd", it, "EscaleraSubir", Vector3(-9.6, 1.0, -37.2), 0.0, {
		"destino": NodePath("../../Entradas/Entrada_volver_p10"), "texto": "Subir por la escalera de servicio",
		"sonido_puerta": &"escalera_servicio", "espera_en_negro": 1.6})
	componente("res://componentes/pared_marcas.gd", it, "ParedPB", Vector3(-12.85, 1.2, -30.0), 0.0, {"punto": &"pared_planta_baja"})
	componente("res://componentes/documento.gd", it, "EscritoPared", Vector3(-12.6, 1.2, 12.0), 0.0, {
		"id_documento": &"pared_aislados", "texto": "Leer lo escrito en la pared"})
	componente("res://componentes/interactuable.gd", it, "Fusible2", Vector3(0.3, 0.85, -8.1), 0.0, {
		"texto": "Coger el fusible", "animacion": &"recoger", "metodo_nivel": &"coger_fusible", "una_vez": true})
	componente("res://componentes/interactuable.gd", it, "Fusible3", Vector3(-10.4, 0.2, 12.0), 0.0, {
		"texto": "Coger el fusible", "animacion": &"recoger", "metodo_nivel": &"coger_fusible", "una_vez": true})
	componente("res://componentes/recogible.gd", it, "Municion", Vector3(-0.5, 0.85, -8.0), 0.0, {
		"tipo": 4, "cantidad": 6, "texto": "Coger la caja de balas"})
	for b in [Vector3(-4.0, 0.1, -2.0), Vector3(6.0, 0.1, 6.0), Vector3(-6.5, 0.1, 22.0), Vector3(4.0, 0.1, -20.0),
			Vector3(-9.0, 0.1, -30.0)]:
		componente("res://componentes/recogible.gd", it, "Botella_%d" % int(b.z), b, 0.0, {
			"tipo": 6, "texto": "Coger la botella", "animacion": &"recoger"})
	componente("res://componentes/interactuable.gd", it, "CajaFusibles", ASCENSOR + Vector3(-1.6, 1.3, -0.85), 0.0, {
		"texto": "Caja de fusibles", "metodo_nivel": &"caja_fusibles", "radio": 1.3})
	componente("res://componentes/interactuable.gd", it, "Ascensor", ASCENSOR + Vector3(-0.6, 1.0, 0), 0.0, {
		"texto": "Entrar en el ascensor", "metodo_nivel": &"entrar_ascensor", "activo": false, "radio": 1.6})
	var z := grupo(raiz, "Zonas")
	zona_camara(z, "ZonaPasarelaO", Vector3(XO, Y10 + 1.5, 0), Vector3(3.2, 3.2, 78.0), 2.3, 1.6, 0.45, 64.0, 1)
	zona_camara(z, "ZonaPasarelaN", Vector3(0, Y10 + 1.5, -37.6), Vector3(29.0, 3.2, 3.2), 2.2, 1.6, 0.4, 64.0, 1)
	zona_camara(z, "ZonaPlantaBaja", Vector3(0, 1.5, 0), Vector3(26.0, 3.0, 76.0), 2.8, 1.7, 0.35, 66.0, 1)
	disparador(z, "VerColgados", Vector3(XO, Y10 + 1.2, -10.0), Vector3(3.0, 2.4, 1.5), &"ver_colgados", true)
	disparador(z, "LlegarAbajo", Vector3(-9.6, 1.2, -33.0), Vector3(3.0, 2.4, 2.0), &"llegar_abajo", true)


func _entradas() -> void:
	var e := grupo(raiz, "Entradas")
	punto_entrada(e, &"inicio", Vector3(XO, Y10, 34.0), 0.0)
	punto_entrada(e, &"pared_p10", Vector3(XO, Y10, -27.0), 0.0)
	punto_entrada(e, &"planta_baja", Vector3(-9.6, 0.0, -35.0), 180.0)
	punto_entrada(e, &"pared_planta_baja", Vector3(-12.0, 0.0, -29.0), 180.0)
	punto_entrada(e, &"volver_p10", Vector3(-9.6, Y10, -36.0), 90.0)


func _enemigos() -> void:
	var g := grupo(raiz, "Enemigos")
	# El Vigilante da vueltas por el anillo de la torre (y = 34,3) barriendo la pasarela oeste.
	var anillo := []
	for k: int in [5, 4, 3, 4, 5, 6]:
		var a := TAU * k / 8.0
		anillo.append(Vector3(cos(a) * 3.75, 34.3, 27.0 + sin(a) * 3.75))
	ruta(g, "RutaVigilante", anillo)
	enemigo("res://enemigos/vigilante.gd", g, "Vigilante", anillo[0], 90.0, {
		"ruta": NodePath("../RutaVigilante"), "espera_en_punto": 2.5, "barrido": 40.0, "inclinacion": 0.0,
		"alcance_foco": 30.0, "punto_mirada": Vector3(XO, Y10 + 0.6, 22.0)})
	# El Uniforme aparece si salta la alarma (E2: recorre la prisión entera).
	enemigo("res://enemigos/uniforme.gd", g, "Uniforme", Vector3(XO, Y10, -34.0), 180.0, {"estado_inicial": 0})
	marcador(g, "UniformeNorte", Vector3(XO, Y10, -34.0))
	marcador(g, "UniformeSur", Vector3(XO, Y10, 36.0))
	# Los Aislados (planta baja).
	ruta(g, "RutaAislado1", [Vector3(-6.0, 0, -18.0), Vector3(4.0, 0, -12.0), Vector3(2.0, 0, 2.0), Vector3(-7.0, 0, -4.0)])
	ruta(g, "RutaAislado2", [Vector3(8.0, 0, 4.0), Vector3(9.0, 0, 18.0), Vector3(2.0, 0, 14.0)])
	ruta(g, "RutaAislado3", [Vector3(-4.0, 0, 26.0), Vector3(5.0, 0, 30.0), Vector3(-6.0, 0, 34.0)])
	enemigo("res://enemigos/aislado.gd", g, "Aislado1", Vector3(-6.0, 0, -18.0), 0.0, {"ruta": NodePath("../RutaAislado1")})
	enemigo("res://enemigos/aislado.gd", g, "Aislado2", Vector3(8.0, 0, 4.0), 0.0, {"ruta": NodePath("../RutaAislado2"), "personaje": "aislado_b"})
	enemigo("res://enemigos/aislado.gd", g, "Aislado3", Vector3(-4.0, 0, 26.0), 0.0, {"ruta": NodePath("../RutaAislado3")})
