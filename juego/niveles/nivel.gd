class_name Nivel
extends Node3D
## Base de todos los niveles. El nodo raíz de cada nivel lleva un script que hereda de
## este (niveles/<id>/<id>.gd) con la lógica propia: cinemáticas, puzles, sustos...
##
## Al cargarse se registra en Juego, que coloca al jugador en el PuntoEntrada pedido y
## llama a al_entrar(punto). Las funciones de cinemática se usan con await:
##     empezar_cinematica()
##     plano($Camaras/Plano1)            # corte a una cámara del nivel
##     await espera(2.0)                 # se acorta si el jugador mantiene «Interactuar»
##     await decir("Policía", "¡Alto!", 2.0)
##     terminar_cinematica()

const EPOCA_PRESENTE := 0
const EPOCA_PASADO := 1

@export var id: StringName = &""
@export_enum("PRESENTE", "PASADO") var epoca := 0
## Elías lleva ropa de calle (F1, F2) en lugar del uniforme de preso.
@export var vestuario_civil := false
## Sonido de los pasos: hormigon, metal, charco, baldosa.
@export var superficie_pasos: StringName = &"hormigon"
## Sonido de fondo en bucle (assets/audio). Vacío = silencio.
@export var ambiente: StringName = &""
@export var volumen_ambiente := -8.0
## Segunda capa de ambiente (zumbido eléctrico, goteo, lluvia...).
@export var capa_ambiente: StringName = &""
@export var volumen_capa := -14.0

var jugador: Jugador
var en_cinematica := false
var _saltar := false
var _t_saltar := 0.0
var _camaras_cine: Array[Camera3D] = []


func _ready() -> void:
	jugador = get_tree().get_first_node_in_group(&"jugador") as Jugador
	if jugador:
		jugador.fijar_vestuario(vestuario_civil)
		jugador.superficie = superficie_pasos
	if ambiente != &"":
		Audio.ambiente(ambiente, volumen_ambiente, 2.5)
	else:
		Audio.ambiente(&"", 0.0, 1.0)
	if capa_ambiente != &"":
		Audio.capa(&"nivel", capa_ambiente, volumen_capa, 2.5)
	else:
		Audio.capa(&"nivel", &"", 0.0, 1.0)
	# Puntos de sonido ambiental (Marker3D con los metadatos sonido/volumen/alcance).
	var sonidos := get_node_or_null(^"Sonidos")
	if sonidos:
		for m in sonidos.get_children():
			if m.has_meta(&"sonido"):
				Audio.emisor(m as Node3D, StringName(m.get_meta(&"sonido")), m.get_meta(&"volumen", -8.0),
						m.get_meta(&"alcance", 12.0))
	Juego.registrar_nivel(self)


## Busca el PuntoEntrada con ese id (o el primero que haya).
func punto_entrada(punto: StringName) -> Node3D:
	var primero: Node3D = null
	for p in get_tree().get_nodes_in_group(&"punto_entrada"):
		if primero == null:
			primero = p
		if (p as PuntoEntrada).id == punto:
			return p
	return primero


## Se llama al entrar en el nivel (después de colocar al jugador). Para sobrescribir.
func al_entrar(_punto: StringName) -> void:
	pass


## Se llama al morir, antes de «CONTINUAR» (escena de consecuencia de los flashbacks, G6).
func al_morir() -> void:
	pass


# --------------------------------------------------------------- Cinemáticas ---

func _process(delta: float) -> void:
	if not en_cinematica:
		return
	if Input.is_action_pressed(&"interactuar") or Input.is_action_pressed(&"ui_accept"):
		_t_saltar += delta
		if _t_saltar > 0.7 and not _saltar:
			_saltar = true
			Interfaz.ocultar_aviso()
	else:
		_t_saltar = 0.0


## Quita el control, pone las bandas de cine (C3) y permite saltar (C2).
func empezar_cinematica(barras := true, saltable := true) -> void:
	en_cinematica = saltable
	_saltar = false
	_t_saltar = 0.0
	if jugador:
		jugador.bloquear(true)
	if barras:
		RenderRig.establecer_barras(1.0, 0.7)
	if saltable:
		Interfaz.mostrar_aviso("Mantener: saltar")


## Devuelve el control y la cámara del jugador.
func terminar_cinematica(mezcla := 0.6) -> void:
	en_cinematica = false
	_saltar = false
	Interfaz.ocultar_aviso()
	RenderRig.establecer_barras(0.0, 0.6)
	for cam in _camaras_cine:
		if is_instance_valid(cam):
			RenderRig.desactivar_camara(cam, mezcla)
	_camaras_cine.clear()
	if jugador and jugador.camara:
		RenderRig.activar_camara(jugador.camara.camara, mezcla)
		jugador.bloquear(false)


func saltando() -> bool:
	return _saltar


## Corta (o funde, con mezcla > 0) a una cámara del nivel.
func plano(cam: Camera3D, mezcla := 0.0) -> void:
	if cam == null:
		return
	_camaras_cine.append(cam)
	RenderRig.activar_camara(cam, 0.0 if _saltar else mezcla)


## Espera unos segundos (se acorta si el jugador salta la cinemática).
func espera(segundos: float) -> void:
	if Interfaz.prueba_automatica:
		_saltar = true
	var t := 0.0
	while t < segundos and not _saltar:
		await get_tree().process_frame
		if not get_tree().paused:
			t += get_process_delta_time()


## Subtítulo + espera. Al saltar no se muestra.
func decir(quien: String, texto: String, segundos := 3.0) -> void:
	if _saltar:
		return
	Interfaz.subtitulo(texto, segundos, quien)
	await espera(segundos)


## Lista de líneas [quién, texto, segundos] (datos/guion.gd).
func dialogo(lineas: Array) -> void:
	for l in lineas:
		await decir(l[0], l[1], l[2])


## Megafonía: chasquido del altavoz + líneas.
func megafonia(lineas: Array) -> void:
	Audio.efecto(&"megafonia", -4.0)
	await get_tree().create_timer(0.6, false).timeout
	for l in lineas:
		Interfaz.subtitulo(l[1], l[2], l[0])


## Mueve una cámara de un sitio a otro (travelling, grúa). [param desde] y [param hasta]
## son Node3D (marcadores) o Transform3D.
func mover_camara(cam: Camera3D, desde: Variant, hasta: Variant, segundos: float,
		transicion := Tween.TRANS_SINE) -> void:
	var a: Transform3D = desde.global_transform if desde is Node3D else desde
	var b: Transform3D = hasta.global_transform if hasta is Node3D else hasta
	cam.global_transform = a
	if _saltar:
		cam.global_transform = b
		return
	var tw := create_tween()
	tw.tween_method(func(k: float) -> void: cam.global_transform = a.interpolate_with(b, k),
			0.0, 1.0, segundos).set_trans(transicion).set_ease(Tween.EASE_IN_OUT)
	while tw.is_running():
		if _saltar:
			tw.kill()
			cam.global_transform = b
			return
		await get_tree().process_frame


## Hace que una cámara mire a un punto durante unos segundos (seguimiento).
func seguir_con_camara(cam: Camera3D, objetivo: Node3D, segundos: float, altura := 1.4) -> void:
	var t := 0.0
	while t < segundos and not _saltar:
		if is_instance_valid(objetivo):
			var punto := objetivo.global_position + Vector3.UP * altura
			var deseo := cam.global_transform.looking_at(punto, Vector3.UP)
			cam.global_transform = cam.global_transform.interpolate_with(deseo, 1.0 - exp(-4.0 * get_process_delta_time()))
		await get_tree().process_frame
		t += get_process_delta_time()


## Muestra un rótulo de capítulo (H5).
func rotulo(numero: String, titulo: String) -> void:
	await Interfaz.rotulo_capitulo(numero, titulo)


## Pasa al nivel siguiente en el orden de la demo.
func siguiente_nivel(punto := &"inicio") -> void:
	var i := Juego.ORDEN.find(id)
	if i >= 0 and i + 1 < Juego.ORDEN.size():
		Juego.ir_a(Juego.ORDEN[i + 1], punto)
