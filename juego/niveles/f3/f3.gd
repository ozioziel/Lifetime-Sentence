extends Nivel
## Recuerdo F3 «El ingreso» (PASADO): la prisión viva y cálida.
## Elías llega en una fila de presos nuevos. El guardia de la placa 31 le susurra y deja caer
## la llave de los grilletes. Hay que salirse de la fila cuando el escolta de atrás mire a
## otro lado y cruzar el patio hasta la puerta de servicio sin que ningún guardia lo vea.
## Si lo atrapan → consecuencia (G6). La puerta de servicio → golpe metálico → presente (D6).

const VELOCIDAD_FILA := 0.75
const FIN_FILA := 6.0

@onready var _escolta1: Enemigo = $Enemigos/Escolta1
@onready var _escolta2: Enemigo = $Enemigos/Escolta2
@onready var _guardia31: ModeloPersonaje = $Figuras/Guardia31
@onready var _llave: Interactuable = $Interactivos/Llave

var _fila_activa := false
var _escapado := false
var _hueco := Vector3(-4.0, 0, 34.0)
var _t_distraccion := 0.0
var _distraido := false
var _atrapado := false
var _t := 0.0


func _process(delta: float) -> void:
	super(delta)
	_t += delta
	# Paseantes: dan vueltas lentas por el patio.
	var i := 0
	for p in get_tree().get_nodes_in_group(&"paseante"):
		var n := p as Node3D
		var a := _t * 0.12 + i * 1.6
		var centro := Vector3(-2.0 + i * 2.5, 0, -6.0 + i * 4.0)
		var antes := n.position
		n.position = centro + Vector3(cos(a), 0, sin(a)) * (4.0 + i)
		var dir := n.position - antes
		if dir.length() > 0.0001:
			n.rotation.y = atan2(-dir.x, -dir.z)
		i += 1
	if _fila_activa and not get_tree().paused:
		_mover_fila(delta)


func al_entrar(punto: StringName) -> void:
	_escolta1.cambiar_estado(Enemigo.Estado.GUION)
	_escolta2.cambiar_estado(Enemigo.Estado.GUION)
	match punto:
		&"mitad":
			_escapado = true
			_retirar_fila()
			Interfaz.objetivo("La puerta de servicio, al fondo del patio. Que no te vean.", 6.0)
		_:
			if Juego.bandera(&"f3_visto"):
				_empezar_fila(true)
			else:
				_ingreso()


func _ingreso() -> void:
	empezar_cinematica(true)
	plano($Camaras/Patio)
	await espera(2.5)
	plano($Camaras/Fila)
	for l in Guion.F3_INICIO:
		await decir(l[0], l[1], l[2])
	plano($Camaras/Guardia)
	_guardia31.reproducir(&"quieto", 0.2)
	for l in Guion.F3_GUARDIA_AYUDA:
		await decir(l[0], l[1], l[2])
	plano($Camaras/Llave)
	Audio.efecto(&"llave_cae", 0.0)
	await espera(1.6)
	Juego.poner_bandera(&"f3_visto")
	Juego.punto_de_control(&"inicio", true)
	terminar_cinematica(0.5)
	_empezar_fila(false)


func _empezar_fila(rapido: bool) -> void:
	_llave.activo = true
	_fila_activa = true
	_t_distraccion = 4.0
	if rapido:
		Interfaz.subtitulo(Guion.F3_GUARDIA_AYUDA[1][1], 3.5, Guion.F3_GUARDIA_AYUDA[1][0])
	Interfaz.objetivo("Coge la llave. Sal de la fila cuando el guardia de atrás no mire.", 7.0)


# --------------------------------------------------------------- La fila ---

func _mover_fila(delta: float) -> void:
	var avance := Vector3(0, 0, -VELOCIDAD_FILA * delta)
	var primero := $Figuras/Fila0 as Node3D
	if primero.position.z <= FIN_FILA:
		avance = Vector3.ZERO
	for f in get_tree().get_nodes_in_group(&"fila"):
		var n := f as ModeloPersonaje
		n.position += avance
		n.reproducir(&"andar" if avance != Vector3.ZERO else &"quieto", 0.3, 0.5)
	_guardia31.position += avance
	_guardia31.reproducir(&"andar" if avance != Vector3.ZERO else &"quieto", 0.3, 0.55)
	for e in [_escolta1, _escolta2]:
		if e.estado == Enemigo.Estado.GUION:
			e.global_position += avance
			e.modelo.reproducir(&"andar" if avance != Vector3.ZERO else &"quieto", 0.3, 0.55)
	_hueco += avance
	if _escapado:
		return
	# El escolta de atrás se distrae a ratos con una pelea del patio.
	_t_distraccion -= delta
	if _t_distraccion <= 0.0:
		_distraido = not _distraido
		_t_distraccion = 3.8 if _distraido else 6.0
		if _distraido:
			Audio.efecto_3d(&"pelea_patio", Vector3(8.0, 1.0, _escolta2.global_position.z - 3.0), 0.0, 40.0)
	var giro := deg_to_rad(-80.0) if _distraido else 0.0
	_escolta2.modelo.rotation.y = lerp_angle(_escolta2.modelo.rotation.y, giro, 1.0 - exp(-5.0 * delta))
	var fuera := jugador.global_position.distance_to(_hueco)
	if fuera > 7.0:
		_escapado = true
		Interfaz.objetivo("La puerta de servicio, al fondo del patio. Que no te vean.", 6.0)
		return
	if fuera > 2.2 and not _atrapado:
		for e in [_escolta1, _escolta2]:
			if e == _escolta2 and _distraido:
				continue
			if e.puede_ver_jugador():
				_atrapado = true
				Interfaz.subtitulo("Guardia: ¡Eh, tú! ¡A la fila!", 2.2)
				e.ultima_posicion = jugador.global_position
				e.cambiar_estado(Enemigo.Estado.PERSEGUIR)
				return


func _retirar_fila() -> void:
	_fila_activa = false
	for f in get_tree().get_nodes_in_group(&"fila"):
		(f as Node3D).position.z -= 24.0
	_guardia31.position.z -= 24.0
	for e in [_escolta1, _escolta2]:
		e.global_position.z -= 24.0


func mitad_patio(_z: Node) -> void:
	if _escapado:
		Juego.punto_de_control(&"mitad", true)


func ver_verdugo(_z: Node) -> void:
	empezar_cinematica(true)
	plano($Camaras/Verdugo, 0.5)
	Audio.efecto(&"latido", -6.0)
	await espera(2.6)
	terminar_cinematica(0.5)


# ------------------------------------------------------------------ Salida ---

func puerta_servicio(_n: Node) -> void:
	empezar_cinematica(true, false)
	plano($Camaras/Puerta)
	jugador.modelo().reproducir(&"empujar", 0.1)
	await espera(1.2)
	# D6: la puerta de hierro golpea; silencio; la sala de ejecución del presente.
	Juego.volver_al_presente(&"cap4", &"inicio")


## Escena de consecuencia (G6).
func al_morir() -> void:
	RenderRig.establecer_barras(0.0, 0.0)
	await Interfaz.texto_central(Guion.F3_CONSECUENCIA, 3.2, 28)
