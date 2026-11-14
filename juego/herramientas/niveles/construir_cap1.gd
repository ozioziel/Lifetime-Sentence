extends Constructor
## Capítulo I «Resiliencia» (storyboard §6, pasos 1.1 a 1.8): Bloque A, alas A y B.
## Ala A en el origen; ala B, el mismo pasillo 40 m al sur (+Z). Se pasa de una a otra por
## la puerta pesada del fondo (transición con fundido).

const ESC := "res://assets/escenarios/"
const TEX_PARED := ESC + "bloque_a_juego_pared_bicolor.png"
const TEX_METAL := ESC + "bloque_a_juego_metal_pintado.png"
const TEX_HIERRO := ESC + "bloque_a_juego_hierro_oxidado.png"
const TEX_COLCHON := ESC + "bloque_a_juego_colchon.png"
const TEX_MARCAS := ESC + "bloque_a_juego_marcas_conteo.png"
const TEX_SANGRE := ESC + "ejecucion_sangre_charco.png"
const TEX_PAPEL := ESC + "comisaria_papeles.png"
const TEX_CARTEL := ESC + "callejon_cartel_se_busca.png"
const Z_B := 40.0


func construir() -> int:
	nuevo_nivel(&"cap1")
	entorno(Color(0, 0, 0), Color(0.16, 0.19, 0.18), 0.95, Color(0.05, 0.07, 0.065), 0.04,
			0.03, Color(0.5, 0.62, 0.58))
	var ala_a := instancia(ESC + "bloque_a_juego.glb", raiz, "AlaA")
	var ala_b := instancia(ESC + "bloque_a_juego.glb", raiz, "AlaB", Vector3(0, 0, Z_B))
	navegable(ala_a)
	navegable(ala_b)
	var deco := grupo(raiz, "Decorado")
	navegable(deco)
	_decorado(deco)
	var nav := navegacion("Navegacion", AABB(Vector3(-0.5, -0.5, Z_B - 1.25), Vector3(37.0, 3.4, 2.5)))
	hornear()

	finalizar("res://niveles/cap1/cap1.gd", {
		"id": &"cap1", "epoca": 0, "superficie_pasos": &"hormigon",
		"ambiente": &"zumbido_pabellon", "volumen_ambiente": -12.0,
		"capa_ambiente": &"goteo_lejano", "volumen_capa": -16.0,
	})
	_luces()
	_figuras()
	_camaras()
	_zonas()
	_interactivos()
	_entradas()
	_enemigos()
	var sonidos := grupo(raiz, "Sonidos")
	sonido(sonidos, "GoteoCartel", Vector3(33.15, 1.0, 1.0), "goteo", -6.0, 9.0)
	sonido(sonidos, "GoteoCelda", Vector3(0.3, 2.6, 3.8), "goteo", -12.0, 6.0)
	sonido(sonidos, "Respiracion", Vector3(20.0, 1.0, Z_B + 2.6), "respiracion_celda", -14.0, 7.0)
	jugador(Vector3(0.72, 0, 2.42))
	return guardar("res://niveles/cap1/cap1.tscn")


func _decorado(deco: Node3D) -> void:
	var metal := material(TEX_METAL, Color(0.75, 0.8, 0.78), 0.9)
	var hierro := material(TEX_HIERRO, Color.WHITE, 1.2)
	var negro := material("", Color(0.0, 0.0, 0.0), 1.0)
	# Rótulo del pabellón (texto diegético).
	rotulo(deco, "RotuloBloque", "BLOQUE A — CELDAS A1-A16", Vector3(4.6, 2.48, -1.09), 0.0, 0.11,
			Color(0.72, 0.7, 0.62))
	rotulo(deco, "RotuloAlaB", "BLOQUE A — ALA B", Vector3(4.6, 2.48, Z_B - 1.09), 0.0, 0.11,
			Color(0.72, 0.7, 0.62))
	# Cartel «SE BUSCA» imposible, mojado, junto al fondo del ala A.
	lamina(deco, "Cartel", TEX_CARTEL, Vector3(33.15, 1.62, 1.088), Vector2(0.62, 0.82), Vector3(0, 180, 0), 0.3)
	goteo(deco, "GoteoCartel", Vector3(33.15, 2.05, 1.05), 5)
	# Marcas de conteo junto a las paredes de guardado.
	lamina(deco, "MarcasAlaA", TEX_MARCAS, Vector3(27.15, 1.35, -1.094), Vector2(0.55, 0.42), Vector3.ZERO, 0.35)
	lamina(deco, "MarcasAlaB", TEX_MARCAS, Vector3(30.15, 1.35, Z_B - 1.094), Vector2(0.55, 0.42), Vector3.ZERO, 0.35)
	# Sangre seca en el suelo.
	var manchas := [[Vector3(5.6, 0.012, -0.2), 1.3, 20.0], [Vector3(12.6, 0.012, 0.4), 1.6, 75.0],
			[Vector3(24.3, 0.012, 0.3), 1.2, 130.0], [Vector3(3.6, 0.012, Z_B + 0.4), 1.4, 10.0],
			[Vector3(11.9, 0.012, Z_B - 0.3), 1.8, 200.0], [Vector3(17.6, 0.012, Z_B + 0.5), 1.3, 300.0],
			[Vector3(23.2, 0.012, Z_B - 0.2), 1.5, 45.0], [Vector3(29.1, 0.012, Z_B + 0.3), 1.2, 160.0],
			[Vector3(34.0, 0.012, Z_B + 0.3), 1.6, 80.0]]
	var i := 0
	for m in manchas:
		lamina(deco, "Sangre%d" % i, TEX_SANGRE, m[0], Vector2(m[1], m[1]), Vector3(-90, m[2], 0), 0.5)
		i += 1
	# Papeles: carta bajo el colchón y expediente en el suelo.
	lamina(deco, "PapelCarta", TEX_PAPEL, Vector3(1.9, 0.715, 3.55), Vector2(0.22, 0.28), Vector3(-90, 15, 0), 0.0)
	lamina(deco, "PapelExpediente", TEX_PAPEL, Vector3(18.0, 0.012, -0.45), Vector2(0.3, 0.4), Vector3(-90, -30, 0), 0.0)
	# Puerta del extremo del ala B (por donde se llega) y su marco.
	caja(deco, "PuertaEntradaAlaB", Vector3(0.02, 1.1, Z_B), Vector3(0.1, 2.2, 1.2), metal)
	# Taquillas del ala B (escondites).
	for t in [[Vector3(9.6, 0, Z_B + 0.85), 0.0], [Vector3(15.4, 0, Z_B - 0.85), 180.0],
			[Vector3(21.6, 0, Z_B + 0.85), 0.0], [Vector3(27.4, 0, Z_B - 0.85), 180.0]]:
		_taquilla(deco, "Taquilla_%d" % int(t[0].x), t[0], t[1], metal)
	# Puerta monumental del fondo del ala B (paso 1.8): marco, hoja que sube y volante.
	var pm := grupo(deco, "PuertaMonumental")
	caja(pm, "PilarN", Vector3(34.8, 1.4, Z_B - 1.05), Vector3(0.55, 2.8, 0.3), hierro)
	caja(pm, "PilarS", Vector3(34.8, 1.4, Z_B + 1.05), Vector3(0.55, 2.8, 0.3), hierro)
	var hoja := grupo(pm, "Hoja")
	caja(hoja, "Plancha", Vector3(34.8, 1.4, Z_B), Vector3(0.25, 2.8, 1.85), metal)
	for y in [0.35, 1.0, 1.75, 2.45]:
		caja(hoja, "Refuerzo%d" % int(y * 100), Vector3(34.66, y, Z_B), Vector3(0.06, 0.12, 1.8), hierro, false)
	for z in [-0.75, 0.75]:
		caja(hoja, "Montante%d" % int(z * 100 + 100), Vector3(34.66, 1.4, Z_B + z), Vector3(0.06, 2.7, 0.1), hierro, false)
	rotulo(hoja, "Rotulo", "SEGURIDAD\nPATIO CENTRAL", Vector3(34.62, 2.05, Z_B), -90.0, 0.1, Color(0.65, 0.12, 0.08))
	var rueda := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 0.22
	toro.outer_radius = 0.3
	toro.rings = 12
	toro.ring_segments = 6
	toro.material = hierro
	rueda.mesh = toro
	agregar(hoja, rueda, "Rueda")
	rueda.position = Vector3(34.6, 1.25, Z_B)
	rueda.rotation_degrees = Vector3(0, 0, 90)
	for k in 3:
		var radio := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.52, 0.04, 0.04)
		b.material = hierro
		radio.mesh = b
		agregar(rueda, radio, "Radio%d" % k)
		radio.rotation_degrees = Vector3(0, k * 60.0, 0)
	caja(deco, "Vacio", Vector3(35.75, 1.4, Z_B), Vector3(0.3, 2.8, 2.2), negro, false)


func _taquilla(padre: Node3D, nombre: String, centro: Vector3, rot_y: float, mat: Material) -> void:
	var t := grupo(padre, nombre)
	t.position = centro
	t.rotation_degrees.y = rot_y
	# Cuerpo: fondo, laterales, techo y suelo (abierta por delante, -Z local).
	caja(t, "Fondo", Vector3(0, 0.98, 0.23), Vector3(0.62, 1.96, 0.04), mat)
	caja(t, "LadoI", Vector3(-0.29, 0.98, 0), Vector3(0.04, 1.96, 0.5), mat)
	caja(t, "LadoD", Vector3(0.29, 0.98, 0), Vector3(0.04, 1.96, 0.5), mat)
	caja(t, "Techo", Vector3(0, 1.94, 0), Vector3(0.62, 0.04, 0.5), mat)
	caja(t, "Base", Vector3(0, 0.02, 0), Vector3(0.62, 0.04, 0.5), mat)
	# Puerta de lamas: se ve el pasillo por las rendijas desde dentro.
	for k in 7:
		caja(t, "Lama%d" % k, Vector3(0, 0.12 + k * 0.29, -0.24), Vector3(0.56, 0.2, 0.03), mat)


func _luces() -> void:
	var luces := grupo(raiz, "Luces")
	# Ala A: fluorescentes del pasillo (los tubos ya están modelados).
	var estados_a := [0, 1, 2, 0, 3, 1]
	var estados_b := [2, 3, 1, 3, 2, 0]
	for k in 6:
		var x := 1.5 + k * 6.0
		fluorescente(luces, "FluorA%d" % k, Vector3(x, 2.72, 0), estados_a[k], 3.2, 7.5, false, k == 0)
		fluorescente(luces, "FluorB%d" % k, Vector3(x, 2.72, Z_B), estados_b[k], 3.0, 7.5, false, k == 5)
	# Celdas con luz dentro (bombilla débil).
	for p in [Vector3(7.5, 2.3, -2.6), Vector3(10.5, 2.3, 2.6), Vector3(19.5, 2.3, -2.6), Vector3(28.5, 2.3, 2.6),
			Vector3(16.5, 2.3, Z_B + 2.6), Vector3(31.5, 2.3, Z_B - 2.6)]:
		omni(luces, "Celda_%d_%d" % [int(p.x), int(p.z)], p, Color(0.95, 0.78, 0.55), 0.7, 3.6)
	# Luna por el ventanuco de la celda.
	foco(luces, "Luna", Vector3(1.1, 2.4, 4.7), Vector3(0.9, 0.0, 2.6), Color(0.55, 0.68, 0.88), 1.6, 6.0, 32.0, true)
	# Luces rojas de emergencia del ala B (se encienden al detectar, A4).
	for x in [6.0, 18.0, 30.0]:
		luz_alarma(luces, "Alarma%d" % int(x), Vector3(x, 2.55, Z_B), 8.0)
	omni(luces, "Contraluz", Vector3(35.4, 2.2, Z_B), Color(0.8, 0.85, 0.9), 0.8, 4.0)
	# Rellenos: que Elías y lo importante se lean en la penumbra.
	omni(luces, "RellenoCelda", Vector3(1.0, 2.3, 2.6), Color(0.62, 0.76, 0.8), 1.0, 4.2)
	omni(luces, "RellenoCartel", Vector3(32.6, 2.2, 0.2), Color(0.7, 0.8, 0.8), 0.9, 3.6)
	foco(luces, "FocoMonumental", Vector3(33.6, 2.7, Z_B), Vector3(34.75, 1.3, Z_B), Color(0.75, 0.85, 0.85), 3.5, 6.0, 45.0, true)


func _figuras() -> void:
	var f := grupo(raiz, "Figuras")
	figura(f, "CadaverA1", "aislado_a", Vector3(5.5, 0, -0.4), 70.0, &"morir", 1.0)
	figura(f, "CadaverA2", "aislado_b", Vector3(12.8, 0, 0.5), -120.0, &"morir", 1.0)
	var guardia := figura(f, "GuardiaMuerto", "guardia_penitenciario", Vector3(18.6, 0.14, -0.55), 90.0, &"quieto", 0.0)
	guardia.rotation_degrees.x = -88.0
	figura(f, "CadaverPunzon", "aislado_a", Vector3(24.5, 0, 0.35), 200.0, &"morir", 1.0)
	figura(f, "CadaverB1", "aislado_b", Vector3(3.5, 0, Z_B + 0.6), 30.0, &"morir", 1.0)
	figura(f, "CadaverB2", "aislado_a", Vector3(11.8, 0, Z_B - 0.4), -60.0, &"morir", 1.0)
	figura(f, "CadaverB3", "aislado_b", Vector3(17.5, 0, Z_B + 0.6), 150.0, &"morir", 1.0)
	figura(f, "CadaverB4", "aislado_a", Vector3(23.3, 0, Z_B - 0.45), 90.0, &"morir", 1.0)
	figura(f, "CadaverB5", "aislado_b", Vector3(29.0, 0, Z_B + 0.5), -20.0, &"morir", 1.0)
	var guardia_b := figura(f, "GuardiaUmbral", "guardia_penitenciario", Vector3(34.1, 0.14, Z_B + 0.35), 180.0, &"quieto", 0.0)
	guardia_b.rotation_degrees.x = -88.0


func _camaras() -> void:
	var c := grupo(raiz, "Camaras")
	camara(c, "Cenital", Vector3(0.78, 2.6, 2.45), Vector3(0.74, 0.0, 2.43), 72.0)
	camara(c, "Celda", Vector3(1.9, 2.3, 4.0), Vector3(0.7, 0.4, 2.2), 62.0)
	camara(c, "Cartel", Vector3(33.15, 1.6, 0.35), Vector3(33.15, 1.58, 1.09), 38.0)
	camara(c, "Reja", Vector3(31.55, 1.4, 0.7), Vector3(31.6, 1.35, 1.7), 46.0)
	camara(c, "Monumental", Vector3(30.2, 1.15, Z_B + 0.75), Vector3(34.8, 1.7, Z_B), 52.0)
	camara(c, "Uniforme", Vector3(5.0, 1.0, Z_B - 0.7), Vector3(33.0, 1.6, Z_B), 34.0)


func _zonas() -> void:
	var z := grupo(raiz, "Zonas")
	zona_camara(z, "ZonaCelda", Vector3(1.1, 1.4, 2.6), Vector3(2.4, 2.8, 3.0), 1.05, 1.5, 0.12, 70.0, 2)
	zona_camara(z, "ZonaAlaA", Vector3(18.0, 1.4, 0), Vector3(36.0, 2.8, 2.2), 1.55, 1.45, 0.3, 64.0, 1)
	zona_camara(z, "ZonaAlaB", Vector3(18.0, 1.4, Z_B), Vector3(36.0, 2.8, 2.2), 1.5, 1.45, 0.3, 64.0, 1)
	disparador(z, "EntrarAlaB", Vector3(4.2, 1.2, Z_B), Vector3(1.2, 2.4, 2.2), &"entrar_ala_b")
	disparador(z, "SalirAlPatio", Vector3(35.35, 1.2, Z_B), Vector3(0.5, 2.4, 2.0), &"salir_al_patio")
	disparador(z, "Arrastre", Vector3(22.0, 1.2, 0.0), Vector3(1.0, 2.4, 2.2), &"arrastre_lejano")


func _interactivos() -> void:
	var it := grupo(raiz, "Interactivos")
	componente("res://componentes/recogible.gd", it, "Somier", Vector3(1.85, 0.5, 2.5), 0.0, {
		"tipo": 0, "objeto": &"alambre", "texto": "Arrancar un alambre del somier", "radio": 1.2,
		"comentario": "(Un alambre largo, duro. Servirá.)"})
	componente("res://componentes/documento.gd", it, "Carta", Vector3(1.9, 0.62, 3.5), 0.0, {
		"id_documento": &"carta_hermana", "texto": "Leer la carta", "radio": 1.2})
	componente("res://componentes/puerta.gd", it, "PuertaCelda", Vector3(0.45, 1.0, 1.3), 0.0, {
		"hoja": NodePath("../../AlaA/Puerta_Celda_Elias"), "cerradura": 1, "dificultad": 0.25,
		"texto": "Abrir la reja", "texto_cerrado": "La reja está cerrada.", "angulo_apertura": -105.0,
		"metodo_nivel": &"celda_abierta", "radio": 1.3})
	componente("res://componentes/pared_marcas.gd", it, "ParedCelda", Vector3(2.15, 1.3, 2.7), 0.0, {
		"punto": &"pared_celda", "radio": 1.3})
	componente("res://componentes/documento.gd", it, "Expediente", Vector3(18.0, 0.1, -0.45), 0.0, {
		"id_documento": &"expediente_4827", "texto": "Leer el expediente"})
	componente("res://componentes/recogible.gd", it, "Punzon", Vector3(24.4, 0.3, 0.35), 0.0, {
		"tipo": 1, "texto": "Registrar el cuerpo",
		"comentario": "(Una cuchara afilada contra el suelo. No llegó a usarla.)"})
	componente("res://componentes/pared_marcas.gd", it, "ParedAlaA", Vector3(27.15, 1.25, -0.95), 0.0, {"punto": &"pared_ala_a"})
	componente("res://componentes/interactuable.gd", it, "Cartel", Vector3(33.15, 1.3, 0.75), 0.0, {
		"texto": "Examinar el cartel", "metodo_nivel": &"examinar_cartel", "una_vez": true, "persistente": false})
	componente("res://componentes/puerta_transicion.gd", it, "PuertaFondo", Vector3(35.55, 1.0, 0.0), 0.0, {
		"destino": NodePath("../../Entradas/Entrada_ala_b"), "cerradura": 4, "texto": "Cruzar la puerta",
		"texto_cerrado": "La puerta no cede. Muy lejos, al otro lado, suenan unas llaves.",
		"bandera_cerradura": &"cap1_puerta_fondo"})
	componente("res://componentes/pared_marcas.gd", it, "ParedAlaB", Vector3(30.15, 1.25, Z_B - 0.95), 0.0, {"punto": &"pared_ala_b"})
	componente("res://componentes/mecanismo.gd", it, "Volante", Vector3(34.45, 1.0, Z_B), 0.0, {
		"texto": "Girar el volante (mantener)", "duracion": 4.0, "animacion_bucle": &"volante",
		"pieza": NodePath("../../Decorado/PuertaMonumental/Hoja/Rueda"), "eje_giro": Vector3(0, 1, 0),
		"vueltas": 3.0, "ruido_radio": 18.0, "metodo_nivel": &"puerta_monumental", "radio": 1.4})
	# Escondites: taquillas del ala B.
	for t in [[Vector3(9.6, 0, Z_B + 0.85), 0.0], [Vector3(15.4, 0, Z_B - 0.85), 180.0],
			[Vector3(21.6, 0, Z_B + 0.85), 0.0], [Vector3(27.4, 0, Z_B - 0.85), 180.0]]:
		var e := componente("res://componentes/escondite.gd", it, "Escondite_%d" % int(t[0].x), t[0], t[1], {
			"tipo": 0, "desplazamiento": Vector3(0, 1.0, -0.35), "texto": "Esconderse en la taquilla"})
		marcador(e, "Punto", Vector3(0, 0, 0.02))
		marcador(e, "Salida", Vector3(0, 0, -0.8))
		camara(e, "Camara", Vector3(0, 1.62, -0.1), Vector3(0, 1.45, -3.0), 72.0)


func _entradas() -> void:
	var e := grupo(raiz, "Entradas")
	punto_entrada(e, &"inicio", Vector3(0.72, 0, 2.42), 0.0)
	punto_entrada(e, &"pared_celda", Vector3(1.6, 0, 2.7), -90.0)
	punto_entrada(e, &"pared_ala_a", Vector3(27.2, 0, -0.25), -90.0)
	punto_entrada(e, &"desde_f1", Vector3(31.2, 0, 0.15), -90.0)
	punto_entrada(e, &"ala_b", Vector3(1.6, 0, Z_B), -90.0)
	punto_entrada(e, &"pared_ala_b", Vector3(30.3, 0, Z_B - 0.3), -90.0)


func _enemigos() -> void:
	var g := grupo(raiz, "Enemigos")
	ruta(g, "RutaUniforme", [Vector3(32.5, 0, Z_B), Vector3(24.0, 0, Z_B + 0.2), Vector3(14.0, 0, Z_B - 0.2),
			Vector3(4.5, 0, Z_B), Vector3(14.0, 0, Z_B + 0.2), Vector3(24.0, 0, Z_B - 0.2)])
	enemigo("res://enemigos/uniforme.gd", g, "Uniforme", Vector3(32.5, 0, Z_B), 90.0, {
		"ruta": NodePath("../RutaUniforme"), "estado_inicial": 0})
