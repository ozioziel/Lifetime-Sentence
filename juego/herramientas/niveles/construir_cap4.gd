extends Constructor
## Capítulo IV «La Sentencia» (§5.1, K9): antesala (escopeta, orden de ejecución, pared de
## guardado) y sala de ejecución: jefe-puzle con tres mecanismos ruidosos (palanca, volante y
## torno), coberturas destructibles y la puerta a los sectores inferiores, que se abre por
## tercios. La sala de Blender ocupa x 0..22, z -16..0 (alto 9); su puerta (sur) va de
## x = 9,5 a 12,5.

const ESC := "res://assets/escenarios/"
const TEX_HORMIGON := ESC + "ejecucion_hormigon_ejecucion.png"
const TEX_SUELO := ESC + "ejecucion_losa_pasarela.png"
const TEX_HIERRO := ESC + "ejecucion_hierro_oxidado_i.png"
const TEX_MADERA := ESC + "ejecucion_madera_oscura.png"
const TEX_SANGRE := ESC + "ejecucion_sangre_charco.png"
const TEX_PAPEL := ESC + "comisaria_papeles.png"
const ROJO := Color(0.85, 0.12, 0.07)


func construir() -> int:
	nuevo_nivel(&"cap4")
	entorno(Color(0, 0, 0), Color(0.22, 0.16, 0.14), 1.3, Color(0.1, 0.05, 0.04), 0.02,
			0.03, Color(0.75, 0.4, 0.3), 0.6)
	var sala := instancia(ESC + "ejecucion.glb", raiz, "Sala")
	navegable(sala)
	var deco := grupo(raiz, "Decorado")
	navegable(deco)
	_estructura(deco)
	var cob := grupo(raiz, "Coberturas")
	navegable(cob)
	_coberturas(cob)
	navegacion("Navegacion", AABB(Vector3(-0.5, -0.5, -16.5), Vector3(23.0, 3.5, 25.0)), 0.5)
	hornear()

	finalizar("res://niveles/cap4/cap4.gd", {
		"id": &"cap4", "epoca": 0, "superficie_pasos": &"hormigon",
		"ambiente": &"sala_ejecucion", "volumen_ambiente": -8.0, "capa_ambiente": &"latido_lento",
		"volumen_capa": -18.0,
	})
	_luces()
	_figuras()
	_camaras()
	_interactivos()
	_entradas()
	var g := grupo(raiz, "Enemigos")
	enemigo("res://enemigos/sentencia.gd", g, "Sentencia", Vector3(11.0, 0, -14.6), 180.0, {"estado_inicial": 0})
	var sonidos := grupo(raiz, "Sonidos")
	sonido(sonidos, "Cadenas", Vector3(11.0, 6.0, -9.0), "cadenas_viento", -8.0, 20.0)
	jugador(Vector3(11.0, 0, 6.0))
	return guardar("res://niveles/cap4/cap4.tscn")


func _estructura(deco: Node3D) -> void:
	var hormigon := material(TEX_HORMIGON, Color.WHITE, 0.4)
	var suelo := material(TEX_SUELO, Color.WHITE, 0.5)
	var hierro := material(TEX_HIERRO, Color.WHITE, 0.9)
	var negro := material("", Color(0, 0, 0))
	# Antesala (la pared norte es la de la sala, con su puerta grande).
	habitacion(deco, "Antesala", Vector3(7.0, 0, 0.3), Vector3(15.0, 4.2, 9.0), hormigon, suelo, hormigon, 0.3, [
		["n", 11.0, 8.6, 4.6]])
	# Rastrillo de la entrada (cae cuando aparece La Sentencia).
	var rastrillo := grupo(deco, "Rastrillo")
	rastrillo.position = Vector3(0, 4.1, 0)
	for k in 14:
		caja(rastrillo, "Barra%d" % k, Vector3(9.6 + k * 0.215, 2.0, 0.15), Vector3(0.06, 4.0, 0.06), hierro)
	for y in [0.4, 2.0, 3.6]:
		caja(rastrillo, "Travesano%d" % int(y * 10), Vector3(11.0, y, 0.15), Vector3(3.0, 0.08, 0.08), hierro, false)
	# Puerta de los sectores inferiores (pared norte, se abre por tercios).
	var salida := grupo(deco, "PuertaSalida")
	caja(salida, "MarcoI", Vector3(18.25, 1.8, -15.85), Vector3(0.35, 3.6, 0.3), hierro)
	caja(salida, "MarcoD", Vector3(20.75, 1.8, -15.85), Vector3(0.35, 3.6, 0.3), hierro)
	caja(salida, "Dintel", Vector3(19.5, 3.75, -15.85), Vector3(2.85, 0.3, 0.3), hierro)
	var hoja := grupo(salida, "Hoja")
	caja(hoja, "Plancha", Vector3(19.5, 1.8, -15.82), Vector3(2.2, 3.6, 0.15), hierro)
	for y in [0.6, 1.8, 3.0]:
		caja(hoja, "Refuerzo%d" % int(y * 10), Vector3(19.5, y, -15.73), Vector3(2.2, 0.12, 0.04), hierro, false)
	caja(salida, "Vacio", Vector3(19.5, 1.8, -15.98), Vector3(2.15, 3.5, 0.02), negro, false)
	rotulo(salida, "Rotulo", "SECTORES INFERIORES", Vector3(19.5, 4.2, -15.7), 0.0, 0.09, Color(0.7, 0.62, 0.5))
	# Sangre y papeles.
	var manchas := [[Vector3(11.5, 0.012, 4.0), 1.4], [Vector3(6.0, 0.012, -9.5), 1.8], [Vector3(15.0, 0.012, -12.0), 1.5],
			[Vector3(18.6, 0.012, -6.0), 1.3]]
	var i := 0
	for m in manchas:
		lamina(deco, "Sangre%d" % i, TEX_SANGRE, m[0], Vector2(m[1], m[1]), Vector3(-90, i * 71.0, 0), 0.5)
		i += 1
	lamina(deco, "Orden", TEX_PAPEL, Vector3(8.6, 0.012, 5.4), Vector2(0.3, 0.4), Vector3(-90, -15, 0), 0.0)


func _coberturas(g: Node3D) -> void:
	var madera := material(TEX_MADERA, Color(0.95, 0.85, 0.75), 0.8)
	var hierro := material(TEX_HIERRO, Color.WHITE, 0.9)
	var pos := [Vector3(5.6, 0, -3.2), Vector3(3.0, 0, -7.8), Vector3(13.0, 0, -2.4), Vector3(19.6, 0, -11.0),
			Vector3(7.4, 0, -15.0), Vector3(18.8, 0, -1.8), Vector3(11.2, 0, -15.0)]
	var i := 0
	for p in pos:
		var c := componente("res://componentes/cobertura.gd", g, "Cobertura%d" % i, p, i * 23.0,
				{"tamano": Vector3(1.4, 1.3, 1.0)}, "StaticBody3D")
		caja(c, "Cajas", Vector3(0, 0.45, 0), Vector3(1.4, 0.9, 1.0), madera, false)
		caja(c, "CajaArriba", Vector3(0.2, 1.1, 0.05), Vector3(0.8, 0.45, 0.7), madera, false)
		caja(c, "Fleje", Vector3(0, 0.62, 0.51), Vector3(1.42, 0.06, 0.02), hierro, false)
		i += 1


func _luces() -> void:
	var l := grupo(raiz, "Luces")
	# Lámparas rojas de la sala (modeladas en las paredes).
	for p in [Vector3(0.4, 3.2, -6.0), Vector3(21.6, 3.2, -8.0), Vector3(16.0, 3.2, -15.6)]:
		omni(l, "Roja_%d" % int(p.x), p, ROJO, 2.6, 12.0, true)
	# Foco cenital sobre el patíbulo (la hoja de La Sentencia brilla al pasar).
	foco(l, "Patibulo", Vector3(11.0, 8.6, -9.4), Vector3(11.0, 0.0, -9.4), Color(0.85, 0.82, 0.75), 4.0, 12.0, 42.0, true)
	omni(l, "Relleno1", Vector3(5.0, 5.0, -5.0), Color(0.6, 0.45, 0.4), 1.9, 15.0)
	omni(l, "Relleno2", Vector3(17.0, 5.0, -10.0), Color(0.6, 0.45, 0.4), 1.9, 15.0)
	omni(l, "Relleno3", Vector3(11.0, 4.0, -3.0), Color(0.6, 0.48, 0.42), 1.4, 10.0)
	omni(l, "Salida", Vector3(19.5, 3.4, -14.8), Color(0.7, 0.75, 0.8), 1.2, 6.0)
	fluorescente(l, "FluorAntesala1", Vector3(11.0, 4.15, 6.5), 1, 3.0, 7.0, true)
	fluorescente(l, "FluorAntesala2", Vector3(11.0, 4.15, 2.5), 2, 2.6, 7.0, true)
	for x in [3.0, 11.0, 19.0]:
		luz_alarma(l, "Alarma%d" % int(x), Vector3(x, 6.0, -8.0), 16.0)


func _figuras() -> void:
	var f := grupo(raiz, "Figuras")
	var guardia := figura(f, "GuardiaAntesala", "guardia_penitenciario", Vector3(8.4, 0.14, 4.6), 0.0, &"quieto", 0.0)
	guardia.rotation_degrees = Vector3(-88, 30, 0)
	figura(f, "Cadaver1", "aislado_a", Vector3(4.5, 0, -10.6), 120.0, &"morir", 1.0)
	figura(f, "Cadaver2", "aislado_b", Vector3(16.4, 0, -5.8), -40.0, &"morir", 1.0)
	figura(f, "Cadaver3", "aislado_a", Vector3(1.8, 0, -6.6), 200.0, &"morir", 1.0)


func _camaras() -> void:
	var c := grupo(raiz, "Camaras")
	camara(c, "Antesala", Vector3(13.5, 3.2, 8.0), Vector3(10.5, 0.8, 3.0), 58.0)
	camara(c, "Sala", Vector3(11.0, 2.0, 1.8), Vector3(11.0, 3.5, -12.0), 60.0)
	camara(c, "Sentencia", Vector3(9.4, 1.0, -3.5), Vector3(11.0, 2.6, -13.0), 40.0)
	camara(c, "SentenciaCerca", Vector3(11.6, 1.6, -9.0), Vector3(11.0, 2.4, -13.5), 46.0)
	camara(c, "Rastrillo", Vector3(11.0, 1.4, -3.0), Vector3(11.0, 2.0, 0.3), 55.0)
	camara(c, "Salida", Vector3(16.0, 2.2, -9.0), Vector3(19.5, 1.5, -15.8), 56.0)


func _interactivos() -> void:
	var it := grupo(raiz, "Interactivos")
	componente("res://componentes/recogible.gd", it, "Escopeta", Vector3(8.5, 0.35, 4.3), 0.0, {
		"tipo": 3, "texto": "Registrar al guardia", "comentario": "(Una escopeta de dos cañones. Pesa como una condena.)"})
	componente("res://componentes/documento.gd", it, "Orden", Vector3(8.6, 0.1, 5.4), 0.0, {
		"id_documento": &"orden_sentencia", "texto": "Leer la orden"})
	componente("res://componentes/pared_marcas.gd", it, "ParedAntesala", Vector3(14.85, 1.2, 6.0), 0.0, {"punto": &"inicio"})
	componente("res://componentes/recogible.gd", it, "Cartuchos", Vector3(4.6, 0.2, -10.2), 0.0, {
		"tipo": 5, "cantidad": 4, "texto": "Registrar el cuerpo"})
	var mec := [["Palanca", Vector3(1.35, 1.0, -6.0), 3.0, &"palanca", "Bajar la palanca (mantener)"],
			["Volante", Vector3(20.9, 1.0, -8.0), 4.0, &"volante", "Girar el volante (mantener)"],
			["Torno", Vector3(16.0, 1.0, -14.2), 5.0, &"volante", "Girar el torno (mantener)"]]
	for m in mec:
		componente("res://componentes/mecanismo.gd", it, m[0], m[1], 0.0, {
			"texto": m[4], "duracion": m[2], "animacion_bucle": m[3], "ruido_radio": 22.0,
			"metodo_nivel": &"mecanismo_activado", "pierde_progreso": true, "radio": 1.4})
	var z := grupo(raiz, "Zonas")
	zona_camara(z, "ZonaAntesala", Vector3(11.0, 2.0, 4.6), Vector3(8.0, 4.2, 8.6), 1.9, 1.6, 0.35, 64.0, 1)
	zona_camara(z, "ZonaSala", Vector3(11.0, 2.5, -8.0), Vector3(22.0, 5.0, 16.0), 3.0, 1.8, 0.4, 66.0, 1)
	disparador(z, "EntrarSala", Vector3(11.0, 1.5, -1.6), Vector3(3.2, 3.0, 1.0), &"entrar_sala", true)
	disparador(z, "Escapar", Vector3(19.5, 1.5, -15.1), Vector3(2.2, 3.0, 1.0), &"escapar", false)


func _entradas() -> void:
	var e := grupo(raiz, "Entradas")
	punto_entrada(e, &"inicio", Vector3(11.0, 0, 6.0), 0.0)
