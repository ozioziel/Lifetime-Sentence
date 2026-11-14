class_name LaSentencia
extends Enemigo
## LA SENTENCIA (K9, L1 «El Mazo»): jefe-puzle. Arrastra una hoja hecha con una puerta de
## celda. Va hacia los ruidos (los mecanismos que hay que accionar hacen ruido) y destroza
## las coberturas que se interponen. La escopeta la hace tambalearse y gana tiempo, pero
## el ruido la enfurece (§7.1). Si te alcanza, golpe vertical.

## Segundos de furia (más rápida) tras recibir un disparo o un ruido fuerte.
@export var duracion_furia := 6.0

var _furia := 0.0
var _arrastre: AudioStreamPlayer3D
var _golpeando := false


func _init() -> void:
	personaje = "la_sentencia"
	escala_modelo = 1.25
	anim_quieto = &"quieto"
	anim_andar = &"andar"
	anim_correr = &"andar"
	ritmo_andar = 0.8
	ritmo_correr = 0.8
	velocidad_andar = 1.0
	velocidad_correr = 1.55
	anim_ataque = &"golpe_vertical"
	anim_muerte_jugador = &"muerte_golpe"
	distancia_pareja = 1.6
	distancia_ataque = 2.0
	vision_distancia = 9.0
	vision_angulo = 140.0
	oido = 1.6
	memoria = 6.0
	velocidad_giro = 3.0
	impacto = 0.62
	luces_al_detectar = false


func _ready() -> void:
	super()
	_arrastre = Audio.emisor(self, &"arrastre", -2.0, 45.0)


func _physics_process(delta: float) -> void:
	_furia = maxf(_furia - delta, 0.0)
	super(delta)
	if _arrastre:
		var andando := Vector3(velocity.x, 0, velocity.z).length() > 0.2
		_arrastre.volume_db = lerpf(_arrastre.volume_db, 0.0 if andando else -50.0, 1.0 - exp(-6.0 * delta))
	if not _golpeando and estado in [Estado.PERSEGUIR, Estado.INVESTIGAR]:
		_comprobar_coberturas()


func velocidad_persecucion() -> float:
	return velocidad_correr * (1.35 if _furia > 0.0 else 1.0)


func _animar_movimiento(velocidad: float) -> void:
	modelo.reproducir(anim_andar, 0.25, clampf(velocidad / ritmo_andar * 0.8, 0.6, 2.2))


func oir(posicion: Vector3, radio: float, _origen: Node) -> void:
	if radio >= 25.0:
		_furia = duracion_furia
	ultima_posicion = posicion
	destino = posicion
	if estado != Estado.PERSEGUIR:
		_espera = 0.0
		cambiar_estado(Estado.INVESTIGAR)


func _al_llegar_al_ruido() -> void:
	modelo.reproducir(&"furia", 0.2)
	Audio.efecto_3d(&"sentencia_rugido", global_position + Vector3.UP * 2.0, 4.0, 60.0)


## Si una cobertura (grupo «cobertura») está entre ella y su objetivo, la destroza.
func _comprobar_coberturas() -> void:
	for c in get_tree().get_nodes_in_group(&"cobertura"):
		var n := c as Node3D
		if n.global_position.distance_to(global_position) > 2.6:
			continue
		var hacia := n.global_position - global_position
		hacia.y = 0.0
		if adelante().angle_to(hacia.normalized()) < deg_to_rad(70.0):
			_destrozar(n)
			return


func _destrozar(cobertura: Node3D) -> void:
	_golpeando = true
	var antes := estado
	cambiar_estado(Estado.GUION)
	_parar()
	mirar_a(cobertura.global_position)
	modelo.reproducir(&"golpe_barrido", 0.1)
	await get_tree().create_timer(0.8, false).timeout
	if cobertura.has_method(&"destruir"):
		cobertura.destruir()
	else:
		cobertura.queue_free()
	Audio.efecto_3d(&"cobertura_rota", cobertura.global_position, 6.0, 50.0)
	Particulas.polvo(get_tree().current_scene, cobertura.global_position + Vector3.UP * 0.8)
	if jugador and jugador.camara and jugador.global_position.distance_to(global_position) < 12.0:
		jugador.camara.sacudir(0.5)
	await get_tree().create_timer(0.9, false).timeout
	_golpeando = false
	if estado == Estado.GUION:
		cambiar_estado(antes)


func atacar() -> void:
	if jugador and jugador.camara:
		jugador.camara.sacudir(0.8)
	super()


## Escopeta: se tambalea y gana tiempo, pero se enfurece (§7.1).
func recibir_disparo(arma: StringName, punto: Vector3) -> void:
	Particulas.sangre(get_tree().current_scene, punto)
	Audio.efecto_3d(&"impacto_carne", punto, 2.0, 30.0)
	if arma != &"escopeta" or estado in [Estado.ATACAR, Estado.MUERTO]:
		_furia = duracion_furia
		return
	cambiar_estado(Estado.ATURDIDO)
	_parar()
	modelo.reproducir(&"tambalearse", 0.05)
	await get_tree().create_timer(2.4, false).timeout
	_furia = duracion_furia
	if estado == Estado.ATURDIDO:
		ultima_posicion = jugador.global_position if jugador else global_position
		cambiar_estado(Estado.PERSEGUIR)
