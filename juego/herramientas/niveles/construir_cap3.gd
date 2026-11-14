extends Constructor
## Capítulo III «Enfermería» (§5.1): el ascensor llega al sótano; enfermería con escenario
## gore estático (H4) y documentos; puzle de espejos con El Condenado (K8); archivo de
## expedientes con una caja de seguridad de código; dentro, la foto del guardia → F3.
##
## La enfermería de Blender ocupa x 0..14, z -9..0 (alto 3,4); su puerta, en la pared sur
## (z = 0..0,3), va de x = 1,5 a 2,9. Los cuatro espejos están en la pared norte (z = -9).

const ESC := "res://assets/escenarios/"
const TEX_PARED := ESC + "enfermeria_pared_enfermeria.png"
const TEX_SUELO := ESC + "enfermeria_linoleo.png"
const TEX_TECHO := ESC + "enfermeria_yeso_techo.png"
const TEX_METAL := ESC + "enfermeria_metal_pintado.png"
const TEX_HIERRO := ESC + "enfermeria_hierro_oxidado_i.png"
const TEX_SABANA := ESC + "enfermeria_sabana_sucia.png"
const TEX_SANGRE := ESC + "enfermeria_sangre_charco.png"
const TEX_PAPEL := ESC + "enfermeria_papeles.png"
## Número de interno que lleva cada espejo (de izquierda a derecha).
const NUMEROS := ["2290", "3876", "3115", "4011"]
const X_ESPEJOS := [3.6, 5.0, 6.4, 7.8]


func construir() -> int:
	nuevo_nivel(&"cap3")
	entorno(Color(0, 0, 0), Color(0.17, 0.2, 0.19), 1.0, Color(0.07, 0.08, 0.075), 0.035,
			0.025, Color(0.6, 0.68, 0.62), 0.4)
	var sala := instancia(ESC + "enfermeria.glb", raiz, "Enfermeria")
	navegable(sala)
	var deco := grupo(raiz, "Decorado")
	navegable(deco)
	_estructura(deco)
	navegacion("Navegacion", AABB(Vector3(-0.5, -0.5, -9.5), Vector3(15.0, 3.0, 18.5)))
	hornear()

	finalizar("res://niveles/cap3/cap3.gd", {
		"id": &"cap3", "epoca": 0, "superficie_pasos": &"baldosa",
		"ambiente": &"enfermeria_ambiente", "volumen_ambiente": -10.0, "capa_ambiente": &"goteo_lejano",
		"volumen_capa": -16.0,
	})
	_espejos()
	_luces()
	_camaras()
	_interactivos()
	_entradas()
	_enemigos()
	var sonidos := grupo(raiz, "Sonidos")
	sonido(sonidos, "Gotero", Vector3(13.6, 1.0, -3.4), "goteo", -12.0, 7.0)
	sonido(sonidos, "Respira", Vector3(13.0, 1.0, -6.5), "respiracion_celda", -18.0, 6.0)
	sonido(sonidos, "Zumbido", Vector3(6.5, 2.8, -5.0), "zumbido_quirofano", -12.0, 9.0)
	jugador(Vector3(2.2, 0, 7.4))
	return guardar("res://niveles/cap3/cap3.tscn")


func _estructura(deco: Node3D) -> void:
	var pared := material(TEX_PARED, Color.WHITE, 0.3)
	var suelo := material(TEX_SUELO, Color.WHITE, 0.5)
	var techo := material(TEX_TECHO, Color.WHITE, 0.5)
	var metal := material(TEX_METAL, Color(0.8, 0.82, 0.78), 0.9)
	var hierro := material(TEX_HIERRO, Color.WHITE, 1.2)
	# Pasillo de llegada (la pared norte es la de la enfermería, con su puerta).
	habitacion(deco, "Pasillo", Vector3(0.6, 0, 0.3), Vector3(3.8, 3.0, 8.3), pared, suelo, techo, 0.3, [
		["n", 2.2, 3.8, 3.2], ["e", 3.6, 1.2, 2.2]])
	# Archivo de expedientes (su pared oeste es la del pasillo).
	habitacion(deco, "Archivo", Vector3(4.1, 0, 0.6), Vector3(10.1, 3.0, 6.6), pared, suelo, techo, 0.3, [
		["o", 3.6, 6.4, 3.2]])
	# Jaula del ascensor al fondo del pasillo.
	var a := grupo(deco, "Ascensor")
	for k in 11:
		var x := 1.25 + k * 0.19
		caja(a, "BarroteS%d" % k, Vector3(x, 1.4, 8.25), Vector3(0.04, 2.8, 0.04), hierro, false)
	for k in 9:
		var z := 6.6 + k * 0.2
		caja(a, "BarroteO%d" % k, Vector3(1.2, 1.4, z), Vector3(0.04, 2.8, 0.04), hierro)
		caja(a, "BarroteE%d" % k, Vector3(3.2, 1.4, z), Vector3(0.04, 2.8, 0.04), hierro)
	caja(a, "TechoJaula", Vector3(2.2, 2.82, 7.45), Vector3(2.1, 0.06, 1.8), hierro, false)
	var reja := grupo(a, "Reja")
	for k in 9:
		caja(reja, "Barra%d" % k, Vector3(1.3 + k * 0.22, 1.4, 6.6), Vector3(0.03, 2.75, 0.03), hierro)
	# Puerta del archivo (bisagra en z = 3,0). Se abre al resolver los espejos.
	var puerta := grupo(deco, "PuertaArchivo")
	puerta.position = Vector3(3.95, 0, 3.0)
	var hoja := grupo(puerta, "Hoja")
	caja(hoja, "Plancha", Vector3(0, 1.08, 0.6), Vector3(0.07, 2.15, 1.18), metal)
	rotulo(deco, "RotuloArchivo", "ARCHIVO — PRIVADO", Vector3(3.78, 2.45, 3.6), -90.0, 0.08, Color(0.25, 0.25, 0.22))
	# Archivo: estanterías, mesa con expedientes y la caja de seguridad.
	for fila in 2:
		for k in 6:
			pieza(deco, "Arch_%d_%d" % [fila, k], "kit_interiores", "Kit_Archivador",
					Vector3(5.2 + k * 0.62, 0, 5.9 - fila * 2.0), 0.0, 1)
	pieza(deco, "MesaArchivo", "kit_interiores", "Kit_Mesa_Metal", Vector3(6.6, 0, 1.4), 0.0, 1)
	pieza(deco, "SillaArchivo", "kit_interiores", "Kit_Silla", Vector3(6.6, 0, 2.2), 180.0, 1)
	lamina(deco, "Expedientes", TEX_PAPEL, Vector3(6.6, 0.8, 1.4), Vector2(0.6, 0.45), Vector3(-90, 8, 0), 0.0)
	caja(deco, "CajaFuerte", Vector3(9.7, 0.5, 3.6), Vector3(0.7, 1.0, 0.8), hierro)
	caja(deco, "PuertaCajaFuerte", Vector3(9.33, 0.5, 3.6), Vector3(0.05, 0.86, 0.66), metal, false)
	caja(deco, "Teclado", Vector3(9.3, 0.82, 3.85), Vector3(0.03, 0.18, 0.13), material("", Color(0.15, 0.15, 0.14)), false)
	# Gore estático (H4): más sangre y sábanas manchadas.
	var manchas := [[Vector3(4.0, 0.012, -7.6), 1.6], [Vector3(10.6, 0.012, -6.6), 1.4], [Vector3(2.4, 0.012, -2.0), 1.2],
			[Vector3(2.2, 0.012, 1.6), 1.0], [Vector3(8.5, 0.012, -1.4), 1.3]]
	var i := 0
	for m in manchas:
		lamina(deco, "Sangre%d" % i, TEX_SANGRE, m[0], Vector2(m[1], m[1]), Vector3(-90, i * 63.0, 0), 0.5)
		i += 1
	lamina(deco, "Registro", TEX_PAPEL, Vector3(7.5, 0.91, -3.9), Vector2(0.28, 0.36), Vector3(-90, 30, 0), 0.0)


func _espejos() -> void:
	var g := grupo(raiz, "Espejos")
	for k in 4:
		var e := componente("res://componentes/espejo.gd", g, "Espejo%d" % k, Vector3(X_ESPEJOS[k], 1.5, -8.945), 0.0,
				{"tamano": Vector2(0.86, 1.16), "resolucion": 104, "suciedad": 0.45})
		rotulo(g, "Numero%d" % k, "N.º %s" % NUMEROS[k], Vector3(X_ESPEJOS[k], 2.27, -8.94), 0.0, 0.06,
				Color(0.18, 0.16, 0.14))
		var sabana := lamina(g, "Sabana%d" % k, TEX_SABANA, Vector3(X_ESPEJOS[k], 1.45, -8.93), Vector2(1.02, 1.4),
				Vector3.ZERO, 0.2)
		sabana.visible = false


func _luces() -> void:
	var l := grupo(raiz, "Luces")
	var estados := [0, 1, 2, 0]
	var pos := [Vector3(3.5, 3.3, -2.5), Vector3(3.5, 3.3, -6.5), Vector3(9.5, 3.3, -2.5), Vector3(9.5, 3.3, -6.5)]
	for k in 4:
		fluorescente(l, "Fluor%d" % k, pos[k], estados[k], 3.0, 8.0, false, k == 0)
	# Lámpara de quirófano sobre la mesa de operaciones (el centro del horror).
	foco(l, "Quirofano", Vector3(6.5, 2.05, -5.0), Vector3(6.5, 0.0, -5.0), Color(1.0, 0.95, 0.85), 5.0, 4.0, 48.0, true)
	omni(l, "EspejosRelleno", Vector3(5.7, 2.6, -7.2), Color(0.7, 0.8, 0.78), 1.0, 5.0)
	fluorescente(l, "FluorPasillo", Vector3(2.2, 2.95, 3.0), 1, 2.6, 6.5, true)
	omni(l, "LuzAscensor", Vector3(2.2, 2.6, 7.4), Color(0.9, 0.85, 0.6), 1.4, 5.0)
	fluorescente(l, "FluorArchivo", Vector3(7.0, 2.95, 3.6), 2, 2.4, 6.5, true)
	omni(l, "LuzCaja", Vector3(9.0, 1.8, 3.6), Color(0.8, 0.85, 0.7), 0.7, 3.0)


func _camaras() -> void:
	var c := grupo(raiz, "Camaras")
	camara(c, "Llegada", Vector3(2.2, 2.2, 4.4), Vector3(2.2, 1.0, 7.6), 55.0)
	camara(c, "Gore", Vector3(4.6, 2.3, -2.8), Vector3(6.5, 0.8, -5.0), 52.0)
	camara(c, "Espejos", Vector3(5.7, 1.65, -5.6), Vector3(5.7, 1.45, -9.0), 58.0)
	camara(c, "Archivo", Vector3(4.6, 2.2, 1.0), Vector3(9.4, 0.7, 3.6), 55.0)
	camara(c, "Foto", Vector3(9.0, 1.15, 3.6), Vector3(9.4, 0.9, 3.6), 40.0)


func _interactivos() -> void:
	var it := grupo(raiz, "Interactivos")
	componente("res://componentes/documento.gd", it, "Registro", Vector3(7.5, 0.95, -3.9), 0.0, {
		"id_documento": &"registro_defunciones", "texto": "Leer el registro"})
	componente("res://componentes/pared_marcas.gd", it, "ParedPasillo", Vector3(0.75, 1.2, 4.5), 0.0, {"punto": &"pared_pasillo"})
	componente("res://componentes/pared_marcas.gd", it, "ParedArchivo", Vector3(4.3, 1.2, 5.6), 0.0, {"punto": &"pared_archivo"})
	for k in 4:
		componente("res://componentes/interactuable.gd", it, "CubrirEspejo%d" % k, Vector3(X_ESPEJOS[k], 1.2, -8.5), 0.0, {
			"texto": "Cubrir el espejo (n.º %s)" % NUMEROS[k], "metodo_nivel": &"cubrir_espejo", "radio": 0.9,
			"una_vez": false, "persistente": false})
	componente("res://componentes/puerta.gd", it, "PuertaArchivo", Vector3(3.4, 1.0, 3.6), 0.0, {
		"hoja": NodePath("../../Decorado/PuertaArchivo/Hoja"), "cerradura": 4, "texto": "Abrir el archivo",
		"texto_cerrado": "Cerrada. Del otro lado no llega ningún ruido.", "angulo_apertura": 100.0,
		"sonido_apertura": &"puerta_metal", "bandera_cerradura": &"cap3_archivo_abierto", "radio": 1.4})
	componente("res://componentes/documento.gd", it, "NotaGuardia", Vector3(6.6, 0.85, 1.4), 0.0, {
		"id_documento": &"nota_guardia", "texto": "Revisar los expedientes"})
	componente("res://componentes/interactuable.gd", it, "CajaFuerte", Vector3(9.1, 0.9, 3.6), 0.0, {
		"texto": "Caja de seguridad", "cerradura": 3, "codigo": "2915",
		"texto_cerrado": "CAJA DE SEGURIDAD — CUATRO CIFRAS", "metodo_nivel": &"caja_abierta",
		"una_vez": true, "persistente": false, "radio": 1.3})
	var z := grupo(raiz, "Zonas")
	zona_camara(z, "ZonaPasillo", Vector3(2.2, 1.5, 4.3), Vector3(3.2, 3.0, 8.0), 1.6, 1.5, 0.3, 64.0, 1)
	zona_camara(z, "ZonaEnfermeria", Vector3(7.0, 1.7, -4.5), Vector3(14.0, 3.4, 9.0), 2.0, 1.6, 0.35, 64.0, 1)
	zona_camara(z, "ZonaArchivo", Vector3(7.1, 1.5, 3.6), Vector3(6.0, 3.0, 6.0), 1.6, 1.5, 0.3, 64.0, 2)
	disparador(z, "VerGore", Vector3(4.8, 1.2, -3.0), Vector3(1.4, 2.4, 2.4), &"ver_gore", true)
	disparador(z, "CercaEspejos", Vector3(5.7, 1.2, -6.8), Vector3(6.0, 2.4, 4.0), &"cerca_espejos", false)


func _entradas() -> void:
	var e := grupo(raiz, "Entradas")
	punto_entrada(e, &"inicio", Vector3(2.2, 0, 7.4), 0.0)
	punto_entrada(e, &"pared_pasillo", Vector3(1.4, 0, 4.5), 0.0)
	punto_entrada(e, &"pared_archivo", Vector3(4.9, 0, 5.4), -90.0)


func _enemigos() -> void:
	var g := grupo(raiz, "Enemigos")
	enemigo("res://enemigos/condenado.gd", g, "Condenado", Vector3(6.0, 0, -6.0), 0.0, {})
	ruta(g, "RutaAislado", [Vector3(11.0, 0, -1.6), Vector3(11.0, 0, -8.0), Vector3(9.0, 0, -7.6), Vector3(9.4, 0, -2.0)])
	enemigo("res://enemigos/aislado.gd", g, "Aislado", Vector3(11.0, 0, -1.6), 180.0, {
		"ruta": NodePath("../RutaAislado"), "personaje": "aislado_b"})
