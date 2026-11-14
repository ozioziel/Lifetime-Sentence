extends Nivel
## Recuerdo F1 «La huida» (PASADO). Motivo: esconder la carpeta (G5).
## Si lo detienen antes de esconderla → escena de consecuencia → CONTINUAR desde el punto
## de control del recuerdo (G6). Con la carpeta escondida, la verja lo acorrala (N3) y el
## golpe metálico lo devuelve al presente (D6).

@onready var _patrulleros: Array[Node] = [$Enemigos/Patrullero1, $Enemigos/Patrullero2]
@onready var _refuerzos: Array[Node] = [$Enemigos/Refuerzo1, $Enemigos/Refuerzo2, $Enemigos/Refuerzo3]
@onready var _giratorio1: OmniLight3D = $Luces/Giratorio1
@onready var _giratorio2: OmniLight3D = $Luces/Giratorio2

var _t := 0.0
var _terminado := false


func _process(delta: float) -> void:
	super(delta)
	# Luces giratorias de los coches patrulla.
	_t += delta
	_giratorio1.light_energy = 3.5 * maxf(sin(_t * 9.0), 0.0)
	_giratorio2.light_energy = 3.5 * maxf(sin(_t * 9.0 + PI), 0.0)


func al_entrar(punto: StringName) -> void:
	match punto:
		&"mitad":
			_desde_la_mitad()
		_:
			_inicio()


func _inicio() -> void:
	empezar_cinematica(true)
	jugador.modelo().reproducir(&"quieto", 0.0)
	plano($Camaras/Cartel)
	await espera(2.2)
	Audio.efecto(&"silbato", 2.0)
	await decir(Guion.F1_INICIO[0][0], Guion.F1_INICIO[0][1], 1.2)
	jugador.modelo().reproducir(&"mirar_atras", 0.1)
	plano($Camaras/Policias)
	for p in _patrulleros:
		(p as Enemigo).activar(Enemigo.Estado.QUIETO)
	await espera(1.6)
	terminar_cinematica(0.3)
	for p in _patrulleros:
		var e := p as Enemigo
		e.ultima_posicion = jugador.global_position
		e.cambiar_estado(Enemigo.Estado.PERSEGUIR)
	Interfaz.subtitulo(Guion.F1_INICIO[1][1], Guion.F1_INICIO[1][2], Guion.F1_INICIO[1][0])
	Interfaz.objetivo("Huye. Esconde la carpeta antes de que te atrapen.", 8.0)


func _desde_la_mitad() -> void:
	# Al reintentar desde la mitad, los perseguidores vienen ya detrás.
	var detras := [Vector3(0.6, 0, -27.0), Vector3(-1.2, 0, -24.5)]
	for i in _patrulleros.size():
		var e := _patrulleros[i] as Enemigo
		e.global_position = detras[i]
		e.activar(Enemigo.Estado.PERSEGUIR)
		e.ultima_posicion = jugador.global_position
	Interfaz.objetivo("Esconde la carpeta antes de que te atrapen.", 6.0)


## Silbato: llega un refuerzo por delante (el primero que esté al menos 10 m por delante).
func refuerzos(_desde: Vector3) -> void:
	for r in _refuerzos:
		var e := r as Enemigo
		if e.estado != Enemigo.Estado.INACTIVO:
			continue
		if e.global_position.z < jugador.global_position.z - 10.0:
			await get_tree().create_timer(1.2, false).timeout
			e.activar(Enemigo.Estado.PERSEGUIR)
			e.ultima_posicion = jugador.global_position
			Audio.efecto_3d(&"silbato", e.global_position, 2.0, 50.0, 1.1)
			return


func punto_mitad(_z: Node) -> void:
	Juego.punto_de_control(&"mitad", true)


func carpeta_escondida(_n: Node) -> void:
	Juego.poner_bandera(&"carpeta_escondida")
	Audio.efecto(&"carpeta", -2.0)
	Interfaz.subtitulo(Guion.F1_ESCONDIDA[0][1], Guion.F1_ESCONDIDA[0][2])
	Interfaz.objetivo("Corre.", 4.0)


func verja(_z: Node) -> void:
	if _terminado or jugador.muerto:
		return
	_terminado = true
	if not Juego.bandera(&"carpeta_escondida"):
		# Acorralado con la carpeta encima: fracaso (G6).
		empezar_cinematica(true, false)
		plano($Camaras/VerjaContra)
		jugador.modelo().reproducir(&"cegado", 0.1)
		await espera(1.6)
		Juego.morir()
		return
	# N3 → D6: acorralado ante la verja que se cierra.
	empezar_cinematica(true, false)
	for p in _patrulleros + _refuerzos:
		var e := p as Enemigo
		if e.estado != Enemigo.Estado.INACTIVO:
			e.cambiar_estado(Enemigo.Estado.GUION)
			e.mirar_a(jugador.global_position)
	plano($Camaras/Verja)
	jugador.modelo().reproducir(&"empujar", 0.1)
	Audio.efecto(&"verja", 2.0)
	await espera(1.4)
	plano($Camaras/VerjaContra)
	jugador.modelo().reproducir(&"cegado", 0.1)
	for l in Guion.F1_VERJA:
		await decir(l[0], l[1], l[2])
	plano($Camaras/Verja)
	await espera(0.6)
	# Golpe metálico, silencio absoluto y corte a las rejas del presente.
	Juego.volver_al_presente(&"cap1", &"desde_f1")


## Escena de consecuencia (G6): el motivo se pierde.
func al_morir() -> void:
	RenderRig.establecer_barras(0.0, 0.0)
	await Interfaz.texto_central(Guion.F1_CONSECUENCIA, 3.2, 28)
