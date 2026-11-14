extends Nivel
## Capítulo II «Patio Central».
##   Revelación (grúa) → rótulo «II — PATIO CENTRAL» → pasarela de la planta 10 bajo el
##   foco de El Vigilante (si te pilla: alarma, luces rojas y El Uniforme) → colgados →
##   escalera de servicio → planta baja con Los Aislados (ruido, botellas) → 3 fusibles →
##   caja de fusibles (hace ruido) → ascensor antiguo → nota y fotografía → recuerdo F2.

const ASCENSOR := Vector3(8.6, 0, 33.0)
const FUSIBLES := {"Fusible1": "FusibleVisible_3", "Fusible2": "FusibleVisible_-8", "Fusible3": "FusibleVisible_12"}

@onready var _uniforme: Enemigo = $Enemigos/Uniforme
@onready var _ascensor: Interactuable = $Interactivos/Ascensor

var _t := 0.0
var _vistas := {}


func _ready() -> void:
	Juego.alarma.connect(_al_alarma)
	super()


func _process(delta: float) -> void:
	super(delta)
	_t += delta
	# Los colgados se mecen y giran despacio.
	var i := 0
	for g in get_tree().get_nodes_in_group(&"colgado"):
		var n := g as Node3D
		n.rotation.z = sin(_t * 0.55 + i * 1.7) * 0.035
		n.rotation.x = cos(_t * 0.43 + i) * 0.025
		n.rotation.y += delta * 0.04 * (1.0 if i % 2 == 0 else -1.0)
		i += 1
	# Siluetas (E6): si se las ha visto y se deja de mirar, ya no están.
	for s in get_tree().get_nodes_in_group(&"silueta"):
		var n := s as Node3D
		if not n.visible:
			continue
		var punto := n.global_position + Vector3.UP * 1.0
		var visible_ahora := RenderRig.camara.is_position_in_frustum(punto) \
				and RenderRig.camara.global_position.distance_to(punto) < 45.0
		if visible_ahora:
			_vistas[n] = _vistas.get(n, 0.0) + delta
		elif _vistas.get(n, 0.0) > 1.0:
			n.visible = false


func al_entrar(punto: StringName) -> void:
	for nombre: String in FUSIBLES:
		var it := get_node(^"Interactivos").get_node(nombre) as Interactuable
		if not it.activo:
			get_node(^"Decorado").get_node(FUSIBLES[nombre]).visible = false
	if Juego.bandera(&"energia_ascensor"):
		_dar_energia(true)
	match punto:
		&"inicio":
			_revelacion()
		&"planta_baja", &"pared_planta_baja":
			Interfaz.objetivo("Tres fusibles para el ascensor. Ellos oyen: camina despacio.", 7.0)
		_:
			Interfaz.objetivo(Juego.lugar_actual())


# -------------------------------------------------------------- Revelación ---

func _revelacion() -> void:
	empezar_cinematica(true)
	var cam := $Camaras/Grua as Camera3D
	plano(cam)
	jugador.andar_hasta(jugador.global_position + Vector3(0, 0, -2.2), 0.9)
	Audio.efecto(&"patio_revelacion", -2.0)
	await mover_camara(cam, $Camaras/Grua0, $Camaras/Grua1, 4.5)
	rotulo("II", "PATIO CENTRAL")
	await mover_camara(cam, $Camaras/Grua1, $Camaras/Grua2, 6.5)
	plano($Camaras/Vacio)
	await espera(3.0)
	plano($Camaras/Vigilante)
	await espera(3.2)
	megafonia(Guion.MEGAFONIA_CAP2)
	terminar_cinematica(0.8)
	Interfaz.objetivo("Avanza entre los pilares. Que el foco no te alcance.", 7.0)


func ver_colgados(_z: Node) -> void:
	empezar_cinematica(true)
	plano($Camaras/Colgados, 0.6)
	Audio.efecto(&"cuerda_cruje", -4.0)
	await espera(3.0)
	terminar_cinematica(0.6)


# ------------------------------------------------------------------- Alarma ---

func _al_alarma(posicion: Vector3) -> void:
	if absf(posicion.y - 32.0) > 4.0 or _uniforme.estado != Enemigo.Estado.INACTIVO:
		return
	# El Uniforme aparece por el extremo más lejano de la pasarela y viene a por ti.
	var norte := $Enemigos/UniformeNorte as Node3D
	var sur := $Enemigos/UniformeSur as Node3D
	var desde := norte if norte.global_position.distance_to(posicion) > sur.global_position.distance_to(posicion) else sur
	_uniforme.global_position = desde.global_position
	_uniforme.activar(Enemigo.Estado.PERSEGUIR)
	_uniforme.ultima_posicion = posicion
	Audio.efecto(&"llaves_carrera", 0.0)


# ----------------------------------------------------------------- Fusibles ---

func coger_fusible(n: Node) -> void:
	var k := Juego.sumar(&"fusibles")
	Juego.dar_objeto(&"fusible", false)
	if FUSIBLES.has(String(n.name)):
		get_node(^"Decorado").get_node(FUSIBLES[String(n.name)]).visible = false
	Interfaz.mensaje("Fusible de cerámica (%d/3)" % k)


func llegar_abajo(_z: Node) -> void:
	Interfaz.objetivo("Tres fusibles para el ascensor. Ellos oyen: camina despacio.", 7.0)


func caja_fusibles(_n: Node) -> void:
	if Juego.bandera(&"energia_ascensor"):
		Interfaz.mensaje("Ya hay corriente.")
		return
	var k := Juego.contador(&"fusibles")
	if k < 3:
		Interfaz.mensaje("La caja tiene tres huecos vacíos. Llevas %d de 3 fusibles." % k, 3.5)
		return
	await jugador.accion(&"palanca")
	Juego.poner_bandera(&"energia_ascensor")
	_dar_energia(false)
	# El zumbido del ascensor se oye en toda la planta baja: vienen.
	Juego.emitir_ruido(ASCENSOR, 26.0, self)
	Interfaz.objetivo("El ascensor tiene corriente. Rápido.", 5.0)


func _dar_energia(instantaneo: bool) -> void:
	_ascensor.activo = true
	var luz := $Luces/LuzAscensor as OmniLight3D
	if instantaneo:
		luz.light_energy = 2.4
		return
	Audio.efecto_3d(&"energia", ASCENSOR, 4.0, 40.0)
	for k in 5:
		luz.light_energy = 2.4 if k % 2 == 0 else 0.0
		await get_tree().create_timer(0.09, false).timeout
	luz.light_energy = 2.4


# ----------------------------------------------------------------- Ascensor ---

func entrar_ascensor(_n: Node) -> void:
	_ascensor.activo = false
	empezar_cinematica(true, false)
	for e in get_tree().get_nodes_in_group(&"aislado"):
		(e as Enemigo).cambiar_estado(Enemigo.Estado.GUION)
	await jugador.andar_hasta(ASCENSOR + Vector3(0.25, 0, 0.2), 1.3)
	jugador.mirar_a(ASCENSOR + Vector3(-3, 0, 0), true)
	plano($Camaras/AscensorFuera)
	var reja := $Decorado/Ascensor/Reja as Node3D
	Audio.efecto_3d(&"reja_ascensor", ASCENSOR, 2.0, 30.0)
	var tw := create_tween()
	tw.tween_property(reja, "position:z", 1.42, 1.1)
	await espera(1.4)
	plano($Camaras/AscensorDentro)
	Audio.efecto(&"ascensor_motor", 0.0)
	var cabina := $Decorado/Ascensor as Node3D
	var desde_y := cabina.position.y
	var jugador_y := jugador.global_position.y
	var tb := create_tween()
	tb.tween_method(func(y: float) -> void:
		cabina.position.y = desde_y + y
		jugador.global_position.y = jugador_y + y, 0.0, -2.6, 5.0).set_trans(Tween.TRANS_SINE)
	await espera(2.2)
	Interfaz.subtitulo("(Prendida en la reja hay una nota. Y una fotografía.)", 3.0)
	await espera(2.8)
	await Juego.leer_documento(&"nota_interrogatorio")
	Juego.dar_objeto(&"foto_interrogatorio", false)
	# D5 hacia F2: el zumbido de la sala de interrogatorios entra antes que la imagen.
	Juego.pasar_al_pasado(&"f2", &"inicio", &"interrogatorio_zumbido")
