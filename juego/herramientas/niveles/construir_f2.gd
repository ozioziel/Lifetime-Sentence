extends Constructor
## Recuerdo F2 «El interrogatorio» (§5.1): sala 3 de la Comisaría Central (escenario de
## Blender) + pasillo, oficina de detectives y archivo con la salida trasera (aquí).
## Motivo: escapar para avisar a su hermana. Ganzúa a contrarreloj (K6) antes de que vuelva
## el interrogador; patrulleros por las oficinas; si lo atrapan → consecuencia (G6).
##
## La sala de Blender ocupa x 0..4,5, z -4,2..0 (alto 3); su puerta, en la pared oeste
## (x = -0,3..0), está centrada en z = -3,4 y mide 1 m de ancho.

const ESC := "res://assets/escenarios/"
const TEX_PARED := ESC + "comisaria_pared_comisaria.png"
const TEX_SUELO := ESC + "comisaria_linoleo_marron.png"
const TEX_TECHO := ESC + "comisaria_yeso_techo.png"
const TEX_PAPEL := ESC + "comisaria_papeles.png"
const TEX_METAL := ESC + "comisaria_metal_hospital.png"
const TEX_MADERA := ESC + "ejecucion_madera_oscura.png"


func construir() -> int:
	nuevo_nivel(&"f2")
	entorno(Color(0, 0, 0), Color(0.24, 0.2, 0.16), 0.95, Color(0.09, 0.075, 0.06), 0.03,
			0.02, Color(0.8, 0.65, 0.45), 0.4)
	var sala := instancia(ESC + "comisaria.glb", raiz, "Sala")
	navegable(sala)
	var deco := grupo(raiz, "Decorado")
	navegable(deco)
	_estructura(deco)
	navegacion("Navegacion", AABB(Vector3(-9.0, -0.5, -13.0), Vector3(14.0, 3.0, 16.5)))
	hornear()

	finalizar("res://niveles/f2/f2.gd", {
		"id": &"f2", "epoca": 1, "vestuario_civil": true, "superficie_pasos": &"baldosa",
		"ambiente": &"comisaria_ambiente", "volumen_ambiente": -10.0, "capa_ambiente": &"interrogatorio_zumbido",
		"volumen_capa": -16.0,
	})
	_luces()
	_figuras()
	_camaras()
	_interactivos()
	_entradas()
	_enemigos()
	var sonidos := grupo(raiz, "Sonidos")
	sonido(sonidos, "Telefono", Vector3(-5.5, 1.0, -3.0), "telefono_lejano", -10.0, 14.0)
	sonido(sonidos, "Maquina", Vector3(-1.3, 1.0, 3.0), "maquina_escribir", -12.0, 10.0)
	jugador(Vector3(1.45, 0, -2.1))
	return guardar("res://niveles/f2/f2.tscn")


func _estructura(deco: Node3D) -> void:
	var pared := material(TEX_PARED, Color.WHITE, 0.32)
	var suelo := material(TEX_SUELO, Color.WHITE, 0.5)
	var techo := material(TEX_TECHO, Color.WHITE, 0.5)
	var madera := material(TEX_MADERA, Color(0.9, 0.85, 0.8), 0.8)
	var metal := material(TEX_METAL, Color(0.75, 0.78, 0.72), 0.9)
	# Pasillo (la pared este deja libre el tramo de la sala de interrogatorios).
	habitacion(deco, "Pasillo", Vector3(-2.3, 0, -12.3), Vector3(-0.3, 2.8, 3.0), pared, suelo, techo, 0.3, [
		["e", -2.1, 4.8, 3.0], ["o", -3.0, 6.0, 3.0], ["o", -9.3, 6.0, 3.0]])
	habitacion(deco, "Oficina", Vector3(-8.3, 0, -6.0), Vector3(-2.6, 2.8, 0.0), pared, suelo, techo, 0.3, [
		["e", -3.0, 1.2, 2.2]])
	habitacion(deco, "Archivo", Vector3(-8.3, 0, -12.3), Vector3(-2.6, 2.8, -6.3), pared, suelo, techo, 0.3, [
		["e", -9.3, 1.2, 2.2], ["s", -5.45, 6.2, 3.0]])
	# Puerta de la sala 3 (gira sobre la bisagra en z = -3,9).
	var puerta := grupo(deco, "PuertaSala")
	puerta.position = Vector3(-0.15, 0, -3.9)
	var hoja := grupo(puerta, "Hoja")
	caja(hoja, "Plancha", Vector3(0, 1.08, 0.5), Vector3(0.06, 2.15, 0.98), madera)
	caja(hoja, "Ventanuco", Vector3(-0.035, 1.6, 0.5), Vector3(0.01, 0.3, 0.4), material("", Color(0.05, 0.05, 0.05)), false)
	# Puerta trasera (salida) y puerta de recepción (cerrada).
	caja(deco, "PuertaSalida", Vector3(-1.3, 1.08, -12.27), Vector3(1.0, 2.15, 0.06), metal)
	rotulo(deco, "RotuloSalida", "SALIDA — PATIO DE VEHÍCULOS", Vector3(-1.3, 2.4, -12.24), 0.0, 0.07, Color(0.8, 0.75, 0.6))
	caja(deco, "PuertaRecepcion", Vector3(-1.3, 1.08, 2.97), Vector3(1.0, 2.15, 0.06), madera)
	caja(deco, "CristalRecepcion", Vector3(-1.3, 1.6, 2.93), Vector3(0.6, 0.5, 0.01), material("", Color(0.9, 0.85, 0.6), 1.0, true, Color(1.0, 0.85, 0.55), 1.5), false)
	rotulo(deco, "RotuloSala", "SALA 3", Vector3(-0.32, 2.35, -3.4), -90.0, 0.08, Color(0.8, 0.75, 0.6))
	# Oficina de detectives: mesas, sillas, archivadores, papeles.
	for m in [[Vector3(-6.6, 0, -1.8), 90.0], [Vector3(-6.6, 0, -4.4), 90.0], [Vector3(-4.0, 0, -1.4), 0.0]]:
		pieza(deco, "Mesa_%d_%d" % [int(m[0].x), int(m[0].z)], "kit_interiores", "Kit_Mesa_Metal", m[0], m[1], 1)
	for s in [[Vector3(-5.8, 0, -1.8), -90.0], [Vector3(-5.8, 0, -4.4), -90.0], [Vector3(-4.0, 0, -0.6), 180.0]]:
		pieza(deco, "Silla_%d_%d" % [int(s[0].x), int(s[0].z)], "kit_interiores", "Kit_Silla", s[0], s[1], 1)
	for k in 4:
		pieza(deco, "ArchivadorO%d" % k, "kit_interiores", "Kit_Archivador", Vector3(-8.25, 0, -0.6 - k * 0.6), 90.0, 1)
	lamina(deco, "PapelesMesa1", TEX_PAPEL, Vector3(-6.6, 0.8, -1.8), Vector2(0.5, 0.4), Vector3(-90, 15, 0), 0.0)
	lamina(deco, "PapelesMesa2", TEX_PAPEL, Vector3(-4.0, 0.8, -1.4), Vector2(0.5, 0.4), Vector3(-90, -20, 0), 0.0)
	caja(deco, "Maquina", Vector3(-6.6, 0.88, -4.4), Vector3(0.45, 0.16, 0.35), metal, false)
	# Archivo: estanterías de archivadores en filas.
	for fila in 3:
		for k in 5:
			pieza(deco, "Arch_%d_%d" % [fila, k], "kit_interiores", "Kit_Archivador",
					Vector3(-7.6 + fila * 1.7, 0, -7.2 - k * 0.62), 90.0, 1)
	pieza(deco, "ArchivadorSuelto", "kit_interiores", "Kit_Archivador", Vector3(-3.2, 0, -8.0), 0.0, 1)


func _luces() -> void:
	var l := grupo(raiz, "Luces")
	# Lámpara colgante de la sala de interrogatorios: luz dura sobre la mesa.
	foco(l, "LamparaMesa", Vector3(2.2, 1.78, -2.1), Vector3(2.2, 0.0, -2.1), Color(1.0, 0.86, 0.62), 6.0, 5.0, 55.0, true)
	omni(l, "RellenoSala", Vector3(3.8, 2.6, -0.6), Color(0.7, 0.62, 0.5), 0.7, 5.0)
	fluorescente(l, "FluorPasillo1", Vector3(-1.3, 2.75, 1.0), 1, 2.6, 6.0, true)
	fluorescente(l, "FluorPasillo2", Vector3(-1.3, 2.75, -6.0), 0, 2.6, 6.0, true)
	fluorescente(l, "FluorPasillo3", Vector3(-1.3, 2.75, -11.0), 2, 2.4, 6.0, true)
	fluorescente(l, "FluorOficina1", Vector3(-5.4, 2.75, -1.6), 0, 2.8, 6.5, true, true)
	fluorescente(l, "FluorOficina2", Vector3(-5.4, 2.75, -4.6), 1, 2.6, 6.5, true)
	fluorescente(l, "FluorArchivo", Vector3(-5.4, 2.75, -9.3), 2, 2.4, 6.5, true)
	omni(l, "Recepcion", Vector3(-1.3, 2.0, 3.6), Color(1.0, 0.82, 0.55), 1.2, 4.0)


func _figuras() -> void:
	var f := grupo(raiz, "Figuras")
	figura(f, "Interrogador", "interrogador", Vector3(3.1, 0, -2.4), 90.0, &"quieto")


func _camaras() -> void:
	var c := grupo(raiz, "Camaras")
	camara(c, "Mesa", Vector3(4.2, 2.45, -0.35), Vector3(2.0, 0.9, -2.1), 58.0)
	camara(c, "Elias", Vector3(2.95, 1.3, -1.75), Vector3(1.45, 1.15, -2.1), 42.0)
	camara(c, "Interrogador", Vector3(0.95, 1.45, -1.55), Vector3(3.1, 1.45, -2.55), 46.0)
	camara(c, "Espejo", Vector3(4.3, 1.6, -3.9), Vector3(1.4, 1.1, -1.8), 50.0)
	camara(c, "Puerta", Vector3(3.6, 1.7, -3.8), Vector3(-0.2, 1.1, -3.4), 55.0)
	camara(c, "Salida", Vector3(-1.9, 1.5, -9.5), Vector3(-1.3, 1.2, -12.2), 55.0)


func _interactivos() -> void:
	var it := grupo(raiz, "Interactivos")
	componente("res://componentes/puerta.gd", it, "PuertaSala", Vector3(0.35, 1.0, -3.4), 0.0, {
		"hoja": NodePath("../../Decorado/PuertaSala/Hoja"), "cerradura": 1, "dificultad": 0.45,
		"texto": "Forzar la cerradura", "texto_cerrado": "Cerrada por fuera.", "angulo_apertura": -100.0,
		"sonido_apertura": &"puerta_madera", "metodo_nivel": &"puerta_sala_abierta", "radio": 1.3})
	componente("res://componentes/interactuable.gd", it, "Salida", Vector3(-1.3, 1.0, -11.8), 0.0, {
		"texto": "Forzar la puerta trasera", "cerradura": 1, "dificultad": 0.5, "limite_tiempo": 40.0,
		"texto_cerrado": "Cerrada con llave.", "metodo_nivel": &"salida", "una_vez": true, "persistente": false,
		"radio": 1.4})
	componente("res://componentes/interactuable.gd", it, "Recepcion", Vector3(-1.3, 1.0, 2.5), 0.0, {
		"texto": "Puerta de recepción", "cerradura": 4,
		"texto_cerrado": "Al otro lado: voces, teléfonos, risas. Por ahí no."})
	# Obstáculos del pasado: derribar un archivador, saltar una mesa.
	componente("res://componentes/obstaculo.gd", it, "DerribarArchivador", Vector3(-3.2, 0.6, -8.0), 0.0, {
		"tipo": 1, "pieza": NodePath("../../Decorado/ArchivadorSuelto")})
	componente("res://componentes/obstaculo.gd", it, "SaltarMesa", Vector3(-4.0, 0.45, -1.4), 0.0, {"tipo": 0, "distancia": 2.0})
	var z := grupo(raiz, "Zonas")
	zona_camara(z, "ZonaSala", Vector3(2.25, 1.5, -2.1), Vector3(4.5, 3.0, 4.2), 1.3, 1.5, 0.25, 66.0, 2)
	zona_camara(z, "ZonaPasillo", Vector3(-1.3, 1.4, -4.6), Vector3(2.0, 2.8, 15.3), 1.5, 1.5, 0.3, 64.0, 1)
	zona_camara(z, "ZonaOficinas", Vector3(-5.45, 1.4, -6.15), Vector3(5.7, 2.8, 12.3), 1.9, 1.6, 0.35, 64.0, 1)


func _entradas() -> void:
	var e := grupo(raiz, "Entradas")
	punto_entrada(e, &"inicio", Vector3(1.45, 0, -2.1), -90.0)
	punto_entrada(e, &"pasillo", Vector3(-1.3, 0, -3.4), 180.0)


func _enemigos() -> void:
	var g := grupo(raiz, "Enemigos")
	ruta(g, "RutaPasillo", [Vector3(-1.3, 0, 2.2), Vector3(-1.3, 0, -11.2)])
	ruta(g, "RutaOficinas", [Vector3(-4.0, 0, -3.0), Vector3(-7.4, 0, -3.0), Vector3(-5.0, 0, -5.4), Vector3(-1.3, 0, -6.2),
			Vector3(-4.0, 0, -9.3), Vector3(-6.0, 0, -11.5)])
	enemigo("res://enemigos/policia.gd", g, "Policia1", Vector3(-1.3, 0, 2.2), 180.0, {
		"tipo": 0, "ruta": NodePath("../RutaPasillo"), "espera_en_punto": 3.0, "linterna": false,
		"vision_distancia": 9.0})
	enemigo("res://enemigos/policia.gd", g, "Policia2", Vector3(-4.0, 0, -3.0), 90.0, {
		"tipo": 0, "ruta": NodePath("../RutaOficinas"), "espera_en_punto": 2.0, "linterna": false,
		"vision_distancia": 8.0})
