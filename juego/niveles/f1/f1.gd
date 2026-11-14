extends Nivel
## Recuerdo F1 «La huida» (PASADO). Motivo: esconder la carpeta (G5).
## Si lo detienen antes de esconderla → escena de consecuencia → CONTINUAR desde el punto
## de control del recuerdo (G6). Con la carpeta escondida, la verja lo acorrala (N3) y el
## golpe metálico lo devuelve al presente (D6).
##
## Diseño de la persecución (para que se entienda a la primera y sea justa):
##   - Una sola dirección: calle abajo. La intro termina mirando hacia allí y las calles
##     laterales del cruce están cortadas por coches patrulla y tácticos.
##   - Los perseguidores siempre vienen por DETRÁS. Los refuerzos salen de las calles del
##     cruce cuando Elías ya ha pasado, y el último, de un portal, con la carpeta escondida.
##   - La alcantarilla está en mitad de la calle, iluminada y echando vapor; Elías la señala.
##   - Goma elástica (Policía): corriendo bien se gana la ventaja justa para esconder la
##     carpeta; chocar o pararse se paga.

## Segundos que tardan los policías en arrancar después de la intro (ventaja inicial).
@export var ventaja_inicial := 0.6

@onready var _patrulleros: Array[Node] = [$Enemigos/Patrullero1, $Enemigos/Patrullero2]
@onready var _refuerzos: Array[Node] = [$Enemigos/Refuerzo1, $Enemigos/Refuerzo2, $Enemigos/Refuerzo3]
@onready var _giratorios: Array[Node] = [$Luces/Giratorio1, $Luces/Giratorio2, $Luces/Giratorio3]

var _t := 0.0
var _terminado := false


func _process(delta: float) -> void:
	super(delta)
	# Luces giratorias de los coches patrulla.
	_t += delta
	for i in _giratorios.size():
		(_giratorios[i] as OmniLight3D).light_energy = 3.5 * maxf(sin(_t * 9.0 + PI * i), 0.0)


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
	# Durante la intro los policías se quedan donde están (si persiguieran ya, al recuperar
	# el control lo tendrían encima).
	for p in _patrulleros:
		var e := p as Enemigo
		e.activar(Enemigo.Estado.GUION)
		e.mirar_a(jugador.global_position)
	await espera(1.4)
	# Último plano: Elías se gira y mira calle abajo. Por ahí se huye.
	jugador.modelo().rotation.y = 0.0
	jugador.modelo().reproducir(&"quieto", 0.15)
	plano($Camaras/Calle)
	await espera(1.1)
	terminar_cinematica(0.3)
	jugador.teletransportar(jugador.global_position, 0.0)
	Interfaz.objetivo("Huye calle abajo. Esconde la carpeta antes de que te atrapen.", 8.0)
	await get_tree().create_timer(ventaja_inicial, false).timeout
	for p in _patrulleros:
		_perseguir(p as Enemigo)
	Interfaz.subtitulo(Guion.F1_INICIO[1][1], Guion.F1_INICIO[1][2], Guion.F1_INICIO[1][0])


func _desde_la_mitad() -> void:
	# Al reintentar desde la mitad, los perseguidores vienen ya detrás (a unos 15 m).
	var detras := [Vector3(0.6, 0, -27.0), Vector3(-1.2, 0, -25.0)]
	for i in _patrulleros.size():
		var e := _patrulleros[i] as Enemigo
		e.global_position = detras[i]
		_perseguir(e)
	jugador.teletransportar(jugador.global_position, 0.0)
	Interfaz.objetivo("Sigue calle abajo. Esconde la carpeta antes de que te atrapen.", 6.0)


func _perseguir(e: Enemigo) -> void:
	if jugador == null or jugador.muerto:
		return
	e.activar(Enemigo.Estado.PERSEGUIR)
	e.ultima_posicion = jugador.global_position


## Saca un refuerzo por detrás de Elías (en su punto de salida) con silbato.
func _sacar_refuerzo(indice: int) -> void:
	var e := _refuerzos[indice] as Enemigo
	if e.estado != Enemigo.Estado.INACTIVO or jugador.muerto:
		return
	var salida := get_node(NodePath("SalidasRefuerzos/Refuerzo%d" % (indice + 1))) as Node3D
	e.global_position = salida.global_position
	e.reset_physics_interpolation()
	e.mirar_a(jugador.global_position)
	_perseguir(e)
	Audio.efecto_3d(&"silbato", salida.global_position, 2.0, 50.0, 1.1)


## Pasado el cruce: dos agentes salen de las calles laterales, detrás de Elías.
func salen_refuerzos(_z: Node) -> void:
	_sacar_refuerzo(0)
	Interfaz.subtitulo(Guion.F1_REFUERZOS[1], Guion.F1_REFUERZOS[2], Guion.F1_REFUERZOS[0])
	await get_tree().create_timer(0.7, false).timeout
	_sacar_refuerzo(1)


## La alcantarilla iluminada ya está a la vista.
func ver_alcantarilla(_z: Node) -> void:
	if not Juego.bandera(&"carpeta_escondida"):
		Interfaz.subtitulo(Guion.F1_ALCANTARILLA[1], Guion.F1_ALCANTARILLA[2])


func punto_mitad(_z: Node) -> void:
	Juego.punto_de_control(&"mitad", true)


func carpeta_escondida(_n: Node) -> void:
	Juego.poner_bandera(&"carpeta_escondida")
	Audio.efecto(&"carpeta", -2.0)
	Interfaz.subtitulo(Guion.F1_ESCONDIDA[0][1], Guion.F1_ESCONDIDA[0][2])
	Interfaz.objetivo("Corre.", 4.0)
	# El último agente sale de un portal, por detrás, y lo empuja hacia la verja.
	await get_tree().create_timer(1.2, false).timeout
	_sacar_refuerzo(2)
	Interfaz.subtitulo(Guion.F1_ULTIMO[1], Guion.F1_ULTIMO[2], Guion.F1_ULTIMO[0])


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
