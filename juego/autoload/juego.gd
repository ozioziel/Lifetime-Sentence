extends Node
## Director del juego (autoload «Juego»).
##
## Lleva el flujo de la partida: niveles, épocas y transiciones, puntos de control,
## muerte → «CONTINUAR», guardado, objetos clave, documentos, armas, ruido y alarma.
##
## Cada nivel tiene un nodo raíz con el script Nivel (niveles/nivel.gd) que se registra
## aquí al cargarse. Desde cualquier script:
##     Juego.ir_a(&"cap2", &"inicio")                  # cambiar de nivel (con fundido)
##     Juego.pasar_al_pasado(&"f1", &"inicio")         # transición D5 (lluvia antes que imagen)
##     Juego.volver_al_presente(&"cap1", &"desde_f1")  # transición D6 (golpe y silencio)
##     Juego.emitir_ruido(posicion, 12.0)              # los enemigos lo oyen
##     Juego.dar_objeto(&"alambre")  /  Juego.tiene(&"alambre")
##     Juego.bandera(&"fusible_1")   /  Juego.poner_bandera(&"fusible_1")
##
## GUARDADO Y MUERTE (decisiones K4 y W2, §7.2 de la planeación):
##   - Guardar = rayar una marca en una pared de conteo (3 ranuras).
##   - Autoguardado en disco solo al empezar cada capítulo y en los puntos de control
##     de los flashbacks.
##   - Al morir se vuelve al punto más reciente entre: la última pared usada, el inicio
##     del tramo actual y el punto de control del flashback.

signal ruido(posicion: Vector3, radio: float, origen: Node)
signal alarma(posicion: Vector3)
signal nivel_listo(nivel: Node)
signal inventario_cambiado
signal armas_cambiadas

enum Epoca { PRESENTE, PASADO }

## Niveles de la demo en orden. «lugar» se muestra en las ranuras de guardado.
## «capitulo» = true: al entrar se autoguarda en disco (§7.2).
const NIVELES := {
	&"cap1": {"ruta": "res://niveles/cap1/cap1.tscn", "lugar": "I · Resiliencia — Bloque A", "capitulo": true},
	&"f1": {"ruta": "res://niveles/f1/f1.tscn", "lugar": "Recuerdo · La huida", "capitulo": false, "flashback": true},
	&"cap2": {"ruta": "res://niveles/cap2/cap2.tscn", "lugar": "II · Patio Central", "capitulo": true},
	&"f2": {"ruta": "res://niveles/f2/f2.tscn", "lugar": "Recuerdo · El interrogatorio", "capitulo": false, "flashback": true},
	&"cap3": {"ruta": "res://niveles/cap3/cap3.tscn", "lugar": "III · Enfermería", "capitulo": true},
	&"f3": {"ruta": "res://niveles/f3/f3.tscn", "lugar": "Recuerdo · El ingreso", "capitulo": false, "flashback": true},
	&"cap4": {"ruta": "res://niveles/cap4/cap4.tscn", "lugar": "IV · La Sentencia", "capitulo": true},
	&"final": {"ruta": "res://niveles/final/final.tscn", "lugar": "Final", "capitulo": true},
}
const ORDEN := [&"cap1", &"f1", &"cap2", &"f2", &"cap3", &"f3", &"cap4", &"final"]
const MENU := "res://ui/menu_principal.tscn"
const CREDITOS := "res://ui/creditos.tscn"
const AUTOGUARDADO := "user://autoguardado.json"

## Objetos clave (inventario sin gestión, decisión H3): [nombre, descripción].
const OBJETOS := {
	&"alambre": ["Alambre del somier", "Sirve de ganzúa. Las cerraduras viejas ceden con paciencia."],
	&"carpeta": ["La carpeta", "Papeles robados de la caja fuerte del consejero. Nombres, firmas, cifras."],
	&"fusible": ["Fusibles de cerámica", "Viejos, pero enteros."],
	&"foto_interrogatorio": ["Fotografía", "Tú, esposado a una mesa de metal. Al dorso: «Comisaría Central, sala 3»."],
	&"llave_archivo": ["Llave del archivo", "Llave pequeña con una etiqueta: «ARCHIVO — ENFERMERÍA»."],
	&"copias": ["Copias", "Fotocopias de las actas que alguien escondió. Las mismas firmas que en la carpeta."],
	&"llave_traslado": ["Llave de grilletes", "Te la dejó caer un guardia. Nadie más la vio."],
}

## Armas (§7.1): capacidad del arma y munición de reserva inicial al encontrarla.
const ARMAS := {
	&"pistola": {"nombre": "Pistola", "capacidad": 6, "reserva": 6, "recarga": 1.4, "ruido": 28.0},
	&"escopeta": {"nombre": "Escopeta", "capacidad": 2, "reserva": 4, "recarga": 2.2, "ruido": 34.0},
}
const USOS_PUNZON := 3

var estado := {}
var jugador: Node = null
var nivel: Node = null
var en_partida := false
var muriendo := false
## Último punto al que se vuelve al morir: {"nivel", "punto", "estado"}.
var _punto_control := {}
var _cambiando := false
var _tiempo := 0.0
var _recargando := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	estado = estado_inicial()


func _process(delta: float) -> void:
	if en_partida and not get_tree().paused:
		_tiempo += delta


func estado_inicial() -> Dictionary:
	return {
		"nivel": "", "punto": "", "objetos": [], "documentos": [], "banderas": {},
		"punzon": 0, "armas": {}, "arma_activa": "", "tiempo": 0.0,
	}


# ------------------------------------------------------------------ Partida ---

func nueva_partida() -> void:
	estado = estado_inicial()
	_tiempo = 0.0
	_punto_control = {}
	ir_a(&"cap1", &"inicio")


## Continúa la partida más reciente (pared de conteo o autoguardado de capítulo).
func continuar() -> void:
	var ranura := Guardado.mas_reciente()
	var auto := _leer_autoguardado()
	var t_ranura: float = Guardado.cargar(ranura).get("guardado_unix", -1.0) if ranura > 0 else -1.0
	var t_auto: float = auto.get("guardado_unix", -1.0)
	if not auto.is_empty() and t_auto > t_ranura:
		_cargar_datos(auto)
	elif ranura > 0:
		cargar_ranura(ranura)
	else:
		nueva_partida()


func hay_partida() -> bool:
	return Guardado.hay_alguna() or FileAccess.file_exists(AUTOGUARDADO)


func cargar_ranura(ranura: int) -> void:
	var datos := Guardado.cargar(ranura)
	if not datos.is_empty():
		_cargar_datos(datos)


func _cargar_datos(datos: Dictionary) -> void:
	estado = estado_inicial()
	estado.merge((datos.get("estado", {}) as Dictionary).duplicate(true), true)
	_tiempo = estado.get("tiempo", 0.0)
	_punto_control = {}
	var id := StringName(estado.get("nivel", "cap1"))
	if not NIVELES.has(id):
		id = &"cap1"
	ir_a(id, StringName(estado.get("punto", "")))


## Guarda en una ranura (lo llama la pared de marcas de conteo).
func guardar_ranura(ranura: int, punto: StringName) -> void:
	_fijar_punto(punto)
	Guardado.guardar(ranura, {"estado": estado, "lugar": lugar_actual()})
	_punto_control = {"nivel": nivel.id, "punto": punto, "estado": estado.duplicate(true)}


func lugar_actual() -> String:
	if nivel and NIVELES.has(nivel.id):
		return NIVELES[nivel.id]["lugar"]
	return ""


func _fijar_punto(punto: StringName) -> void:
	estado["nivel"] = String(nivel.id) if nivel else String(estado.get("nivel", ""))
	estado["punto"] = String(punto)
	estado["tiempo"] = _tiempo


## Punto de control. en_disco = true lo escribe además en el autoguardado (inicio de
## capítulo y puntos internos de los flashbacks).
func punto_de_control(punto: StringName, en_disco := false) -> void:
	if nivel == null:
		return
	_fijar_punto(punto)
	_punto_control = {"nivel": nivel.id, "punto": punto, "estado": estado.duplicate(true)}
	if en_disco:
		var archivo := FileAccess.open(AUTOGUARDADO, FileAccess.WRITE)
		if archivo:
			archivo.store_string(JSON.stringify({"estado": estado, "lugar": lugar_actual(),
					"guardado_unix": Time.get_unix_time_from_system()}, "\t"))


func _leer_autoguardado() -> Dictionary:
	if not FileAccess.file_exists(AUTOGUARDADO):
		return {}
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(AUTOGUARDADO))
	return datos if datos is Dictionary else {}


# ------------------------------------------------------------------ Niveles ---

## Cambia de nivel con un fundido a negro.
func ir_a(id: StringName, punto: StringName = &"", fundido := 0.8) -> void:
	if _cambiando:
		return
	if not NIVELES.has(id):
		push_error("Juego: nivel desconocido «%s»" % id)
		return
	_cambiando = true
	estado["nivel"] = String(id)
	estado["punto"] = String(punto)
	if fundido > 0.0:
		RenderRig.fundir(1.0, fundido)
		await get_tree().create_timer(fundido + 0.05, true, false, true).timeout
	else:
		RenderRig.fundir(1.0, 0.0)
	Interfaz.limpiar()
	get_tree().paused = false
	jugador = null
	nivel = null
	get_tree().change_scene_to_file(NIVELES[id]["ruta"])
	_cambiando = false


## Transición PRESENTE → PASADO (decisión D5): la lluvia (o el sonido del recuerdo) entra
## antes que la imagen y el encuadre se re-dithera de frío a ámbar.
func pasar_al_pasado(id: StringName, punto: StringName = &"", sonido := &"lluvia") -> void:
	if jugador and jugador.has_method(&"bloquear"):
		jugador.bloquear(true)
	Audio.capa(&"transicion", sonido, -6.0, 1.2)
	RenderRig.aplicar_epoca(RenderRig.epoca_pasado, 1.8)
	await get_tree().create_timer(1.6, true, false, true).timeout
	await ir_a(id, punto, 0.6)
	Audio.capa(&"transicion", &"", 0.0, 2.5)


## Transición PASADO → PRESENTE (decisión D6): golpe metálico, corte seco a silencio absoluto.
func volver_al_presente(id: StringName, punto: StringName = &"") -> void:
	if jugador and jugador.has_method(&"bloquear"):
		jugador.bloquear(true)
	Audio.efecto(&"golpe_metalico", 2.0)
	RenderRig.fundir(1.0, 0.0)
	await get_tree().create_timer(0.06, true, false, true).timeout
	Audio.silencio_absoluto(1.8)
	RenderRig.aplicar_epoca(RenderRig.epoca_presente, 0.0)
	await ir_a(id, punto, 0.0)


func volver_al_menu() -> void:
	en_partida = false
	Audio.parar_todo(0.6)
	RenderRig.fundir(1.0, 0.6)
	await get_tree().create_timer(0.65, true, false, true).timeout
	Interfaz.limpiar()
	get_tree().paused = false
	RenderRig.aplicar_epoca(RenderRig.epoca_presente, 0.0)
	RenderRig.establecer_barras(0.0, 0.0)
	jugador = null
	nivel = null
	get_tree().change_scene_to_file(MENU)


func ir_a_creditos() -> void:
	en_partida = false
	Interfaz.limpiar()
	get_tree().paused = false
	jugador = null
	nivel = null
	get_tree().change_scene_to_file(CREDITOS)


## Lo llama cada nivel en su _ready().
func registrar_nivel(n: Node) -> void:
	nivel = n
	muriendo = false
	en_partida = true
	var pasado: bool = n.epoca == Epoca.PASADO
	RenderRig.aplicar_epoca(RenderRig.epoca_pasado if pasado else RenderRig.epoca_presente, 0.0)
	jugador = get_tree().get_first_node_in_group(&"jugador")
	var punto := StringName(estado.get("punto", ""))
	if punto == &"":
		punto = &"inicio"
	if jugador:
		jugador.usar_epoca_pasado(pasado)
		var destino: Node3D = n.punto_entrada(punto)
		if destino:
			jugador.teletransportar(destino.global_position, destino.global_rotation.y)
	# Punto de control al entrar en cada tramo; en disco solo al empezar un capítulo
	# o un recuerdo (§7.2). Al recargar tras morir no se repite.
	var info: Dictionary = NIVELES.get(n.id, {})
	if _punto_control.is_empty() or _punto_control.get("nivel") != n.id \
			or _punto_control.get("punto") != punto:
		var en_disco: bool = (info.get("capitulo", false) and punto == &"inicio") or info.get("flashback", false)
		punto_de_control(punto, en_disco)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	RenderRig.fundir(0.0, 0.0)
	nivel_listo.emit(n)
	n.al_entrar(punto)


# ------------------------------------------------------------------- Muerte ---

## El jugador ha muerto. Se llama cuando su animación de muerte llega al impacto (K3).
func morir() -> void:
	if muriendo:
		return
	muriendo = true
	RenderRig.fundir(1.0, 0.0)
	Audio.efecto(&"impacto_muerte", 0.0)
	Audio.parar_todo(0.15)
	Interfaz.ocultar_aviso()
	Interfaz.mostrar_municion(false)
	await get_tree().create_timer(1.1, true, false, true).timeout
	if nivel and is_instance_valid(nivel) and nivel.has_method(&"al_morir"):
		await nivel.al_morir()
	await Interfaz.pantalla_continuar()
	reintentar()


## Vuelve al último punto de control (o a la última partida guardada).
func reintentar() -> void:
	if _punto_control.is_empty():
		continuar()
		return
	estado = (_punto_control["estado"] as Dictionary).duplicate(true)
	ir_a(_punto_control["nivel"], _punto_control["punto"], 0.0)


# ---------------------------------------------------------- Objetos y datos ---

func dar_objeto(id: StringName, avisar := true) -> void:
	if not tiene(id):
		(estado["objetos"] as Array).append(String(id))
		inventario_cambiado.emit()
	if avisar and OBJETOS.has(id):
		Interfaz.mensaje("Obtienes: %s" % OBJETOS[id][0])
	Audio.efecto(&"recoger", -4.0)


func tiene(id: StringName) -> bool:
	return (estado["objetos"] as Array).has(String(id))


func quitar_objeto(id: StringName) -> void:
	(estado["objetos"] as Array).erase(String(id))
	inventario_cambiado.emit()


func bandera(nombre: StringName) -> bool:
	return (estado["banderas"] as Dictionary).get(String(nombre), false)


func poner_bandera(nombre: StringName, valor := true) -> void:
	(estado["banderas"] as Dictionary)[String(nombre)] = valor


## Contador guardado en las banderas (fusibles encontrados, errores en un puzle...).
func contador(nombre: StringName) -> int:
	return int((estado["banderas"] as Dictionary).get(String(nombre), 0))


func sumar(nombre: StringName, cantidad := 1) -> int:
	var valor := contador(nombre) + cantidad
	(estado["banderas"] as Dictionary)[String(nombre)] = valor
	return valor


## Lee un documento (lo marca como leído y lo muestra).
func leer_documento(id: StringName) -> void:
	if not (estado["documentos"] as Array).has(String(id)):
		(estado["documentos"] as Array).append(String(id))
	var doc := Documentos.obtener(id)
	await Interfaz.mostrar_documento(doc.get("titulo", ""), doc.get("texto", ""))


# -------------------------------------------------------------------- Armas ---

func dar_punzon() -> void:
	estado["punzon"] = USOS_PUNZON
	Interfaz.mensaje("Obtienes: Punzón (%d usos). Si algo te atrapa, lo clavarás." % USOS_PUNZON, 4.0)
	Audio.efecto(&"recoger", -4.0)
	armas_cambiadas.emit()


func usos_punzon() -> int:
	return int(estado.get("punzon", 0))


## Gasta un uso del punzón. [param romper] = true lo rompe (El Uniforme, §7.1).
func gastar_punzon(romper := false) -> void:
	estado["punzon"] = 0 if romper else maxi(usos_punzon() - 1, 0)
	armas_cambiadas.emit()


func dar_arma(id: StringName) -> void:
	var datos: Dictionary = ARMAS[id]
	var armas: Dictionary = estado["armas"]
	if armas.has(String(id)):
		armas[String(id)]["reserva"] += int(datos["reserva"])
	else:
		armas[String(id)] = {"cargador": int(datos["capacidad"]), "reserva": int(datos["reserva"])}
	estado["arma_activa"] = String(id)
	Interfaz.mensaje("Obtienes: %s. Mantén %s para apuntar." % [datos["nombre"], Interfaz.glifo(&"apuntar")], 4.5)
	Audio.efecto(&"recoger_arma", -2.0)
	armas_cambiadas.emit()


func dar_municion(id: StringName, cantidad: int) -> void:
	var armas: Dictionary = estado["armas"]
	if not armas.has(String(id)):
		return
	armas[String(id)]["reserva"] += cantidad
	Interfaz.mensaje("Munición: +%d" % cantidad)
	Audio.efecto(&"recoger", -4.0)
	armas_cambiadas.emit()


func arma_activa() -> StringName:
	return StringName(estado.get("arma_activa", ""))


func tiene_arma() -> bool:
	return arma_activa() != &"" and (estado["armas"] as Dictionary).has(String(arma_activa()))


## Datos de munición del arma activa: {"cargador", "reserva"}.
func municion() -> Dictionary:
	if not tiene_arma():
		return {}
	return estado["armas"][String(arma_activa())]


func texto_municion() -> String:
	var m := municion()
	if m.is_empty():
		return ""
	return "%s   %d | %d" % [ARMAS[arma_activa()]["nombre"].to_upper(), m["cargador"], m["reserva"]]


## Gasta una bala. Devuelve false si el cargador está vacío.
func disparar_bala() -> bool:
	var m := municion()
	if m.is_empty() or int(m["cargador"]) <= 0 or _recargando:
		return false
	m["cargador"] = int(m["cargador"]) - 1
	armas_cambiadas.emit()
	return true


## Recarga el arma activa (tarda lo que indique ARMAS). Devuelve false si no hay balas.
func recargar() -> bool:
	var m := municion()
	if m.is_empty() or _recargando or int(m["reserva"]) <= 0:
		return false
	var capacidad: int = ARMAS[arma_activa()]["capacidad"]
	if int(m["cargador"]) >= capacidad:
		return false
	_recargando = true
	Audio.efecto(StringName("recargar_%s" % arma_activa()), -2.0)
	await get_tree().create_timer(ARMAS[arma_activa()]["recarga"], false).timeout
	var meter := mini(capacidad - int(m["cargador"]), int(m["reserva"]))
	m["cargador"] = int(m["cargador"]) + meter
	m["reserva"] = int(m["reserva"]) - meter
	_recargando = false
	armas_cambiadas.emit()
	return true


func recargando() -> bool:
	return _recargando


## Resumen de armas para la pausa.
func texto_armas() -> String:
	var partes: PackedStringArray = []
	if usos_punzon() > 0:
		partes.append("Punzón (%d usos)" % usos_punzon())
	for id: String in (estado["armas"] as Dictionary):
		var m: Dictionary = estado["armas"][id]
		partes.append("%s (%d + %d)" % [ARMAS[StringName(id)]["nombre"], m["cargador"], m["reserva"]])
	return " · ".join(partes)


# ------------------------------------------------------------ Ruido y alarma ---

## Avisa a los enemigos de un ruido. radio = metros a los que se oye.
func emitir_ruido(posicion: Vector3, radio: float, origen: Node = null) -> void:
	ruido.emit(posicion, radio, origen)


## Alarma (foco de El Vigilante, disparo): enciende las luces rojas y atrae a los enemigos.
func dar_alarma(posicion: Vector3) -> void:
	alarma.emit(posicion)
	get_tree().call_group(&"luz_alarma", &"encender")
	Audio.efecto(&"alarma", -2.0)
