class_name Aislado
extends Enemigo
## LOS AISLADOS (K5): presos encerrados abajo cuando empezó todo. Están ciegos: se guían
## por el oído y convergen en grupo hacia los ruidos. Quedarse quieto o agachado los
## despista; lanzar una botella los aleja. A un palmo te notan.
## La pistola los derriba (pueden morir) y el punzón los mata de un golpe (§7.1).

## Distancia a la que notan al jugador sin oírlo (el roce, la respiración).
@export var tacto := 1.3
## Metros a los que avisan a otros Aislados al oír algo.
@export var contagio := 9.0

var _t_grunido := 0.0


func _init() -> void:
	personaje = "aislado_a"
	anim_quieto = &"quieto"
	anim_andar = &"andar"
	anim_correr = &"correr"
	ritmo_andar = 0.7
	ritmo_correr = 2.6
	velocidad_andar = 0.7
	velocidad_correr = 2.6
	anim_ataque = &"atacar"
	anim_muerte_jugador = &"muerte_arrastrado"
	distancia_pareja = 0.7
	distancia_ataque = 1.0
	vision_distancia = 0.0
	oido = 1.0
	memoria = 3.0
	impacto = 0.8
	luces_al_detectar = false


func _ready() -> void:
	super()
	add_to_group(&"aislado")
	_t_grunido = randf_range(3.0, 9.0)


func _physics_process(delta: float) -> void:
	super(delta)
	if estado == Estado.MUERTO:
		return
	_t_grunido -= delta
	if _t_grunido <= 0.0:
		_t_grunido = randf_range(5.0, 12.0)
		Audio.efecto_3d(&"aislado_grunido", global_position + Vector3.UP * 1.4, -4.0, 16.0, randf_range(0.85, 1.1))
	# Al tacto: si el jugador está pegado, lo agarra.
	if jugador and not jugador.oculto and not jugador.muerto and estado not in [Estado.ATACAR, Estado.ATURDIDO, Estado.GUION, Estado.INACTIVO]:
		if global_position.distance_to(jugador.global_position) < tacto:
			ultima_posicion = jugador.global_position
			if estado != Estado.PERSEGUIR:
				cambiar_estado(Estado.PERSEGUIR)


func puede_ver_jugador() -> bool:
	return false


func _estado_perseguir(delta: float) -> void:
	# Sin vista: va hacia el último ruido; si llega y no hay nada, escucha.
	if jugador and not jugador.oculto and global_position.distance_to(jugador.global_position) <= distancia_ataque:
		atacar()
		return
	if mover_hacia(ultima_posicion, velocidad_correr, delta, 0.8):
		destino = ultima_posicion
		cambiar_estado(Estado.INVESTIGAR)


func oir(posicion: Vector3, radio: float, origen: Node) -> void:
	var d := global_position.distance_to(posicion)
	ultima_posicion = posicion
	destino = posicion
	# Ruido fuerte o cercano: corre hacia él. Si no, se acerca despacio.
	if d < radio * 0.55 or radio >= 14.0:
		if estado != Estado.PERSEGUIR:
			Audio.efecto_3d(&"aislado_alerta", global_position + Vector3.UP * 1.4, 0.0, 22.0)
		cambiar_estado(Estado.PERSEGUIR)
	elif estado != Estado.PERSEGUIR:
		_espera = 0.0
		cambiar_estado(Estado.INVESTIGAR)
	# Avisa a los cercanos (convergen en grupo).
	if origen is Jugador or origen is Proyectil or origen is Mecanismo:
		for otro in get_tree().get_nodes_in_group(&"aislado"):
			var a := otro as Aislado
			if a != self and a.estado in [Estado.QUIETO, Estado.PATRULLA] \
					and a.global_position.distance_to(global_position) < contagio:
				a.destino = posicion
				a._espera = 0.0
				a.cambiar_estado(Estado.INVESTIGAR)


## Solo acuden a las alarmas de su propia planta.
func _al_alarma(posicion: Vector3) -> void:
	if absf(posicion.y - global_position.y) < 3.0 and global_position.distance_to(posicion) < 30.0:
		super(posicion)


func _al_llegar_al_ruido() -> void:
	modelo.reproducir(&"escuchar", 0.2)


func _al_detectar() -> void:
	detecto_jugador.emit()


func _al_recibir_punzon() -> void:
	morir()


func recibir_disparo(_arma: StringName, punto: Vector3) -> void:
	Particulas.sangre(get_tree().current_scene, punto)
	Audio.efecto_3d(&"impacto_carne", punto, 0.0, 20.0)
	morir()


func morir() -> void:
	if estado == Estado.MUERTO:
		return
	cambiar_estado(Estado.MUERTO)
	velocity = Vector3.ZERO
	collision_layer = 0
	Audio.efecto_3d(&"aislado_muere", global_position + Vector3.UP, 0.0, 20.0)
	await modelo.reproducir_una_vez(&"morir", 0.1)
	modelo.posar(&"morir", 1.0)
