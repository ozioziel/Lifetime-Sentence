class_name Enemigo
extends CharacterBody3D
## Base de todos los enemigos: máquina de estados legible, vista (cono + línea de visión),
## oído (señal Juego.ruido), patrulla por puntos, persecución con NavigationAgent3D y
## ataque emparejado con la muerte del jugador (animaciones sincronizadas, K3).
##
## Cada enemigo hereda de aquí y cambia solo lo que lo hace distinto
## (uniforme.gd, policia.gd, aislado.gd, vigilante.gd, condenado.gd, sentencia.gd).
## Los parámetros se ajustan en el Inspector.

signal detecto_jugador
signal estado_cambiado(nuevo: int)

enum Estado { INACTIVO, QUIETO, PATRULLA, INVESTIGAR, PERSEGUIR, ATACAR, ATURDIDO, MUERTO, GUION, ESPECIAL }

@export_group("Modelo")
@export var personaje := "el_uniforme"
@export var escala_modelo := 1.0
@export var anim_quieto: StringName = &"quieto"
@export var anim_andar: StringName = &"andar"
@export var anim_correr: StringName = &"perseguir"
## Velocidad (m/s) para la que se diseñó cada ciclo (ver manifiesto de animaciones).
@export var ritmo_andar := 1.0
@export var ritmo_correr := 2.4

@export_group("Movimiento")
@export var velocidad_andar := 1.0
@export var velocidad_correr := 2.4
@export var velocidad_giro := 6.0
## Nodo cuyos hijos (Marker3D) son los puntos de la patrulla, en orden.
@export var ruta: NodePath
@export var espera_en_punto := 2.0
@export var estado_inicial: Estado = Estado.PATRULLA
## Hacia dónde mira al empezar, en grados (0 = hacia -Z).
@export_range(-180.0, 180.0) var orientacion_inicial := 0.0

@export_group("Sentidos")
@export var vision_distancia := 11.0
@export_range(10.0, 360.0) var vision_angulo := 100.0
## Multiplica el radio de los ruidos (0 = sordo).
@export var oido := 1.0
## Segundos sin ver al jugador antes de dejar de perseguirlo.
@export var memoria := 4.0

@export_group("Ataque")
@export var distancia_ataque := 1.2
## Animación del enemigo al atrapar y la del jugador (emparejadas).
@export var anim_ataque: StringName = &"agarrar"
@export var anim_muerte_jugador: StringName = &"muerte_cuello"
## Metros entre los dos personajes en la animación emparejada.
@export var distancia_pareja := 0.6
## Fracción de la animación en la que se corta a negro.
@export var impacto := 0.75
## El punzón se rompe al usarlo contra este enemigo (El Uniforme).
@export var rompe_punzon := false
## Enciende las luces rojas al detectar (A4).
@export var luces_al_detectar := true

var estado: Estado = Estado.PATRULLA
var jugador: Jugador
var modelo: ModeloPersonaje
var agente: NavigationAgent3D
var ultima_posicion := Vector3.ZERO
var destino := Vector3.ZERO
var _puntos: Array[Vector3] = []
var _indice := 0
var _t_estado := 0.0
var _t_sin_ver := 0.0
var _t_visto := 99.0
var _espera := 0.0
var _gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _escondite_visto: Node = null
var _detectado_una_vez := false


func _ready() -> void:
	add_to_group(&"enemigo")
	collision_layer = 4
	collision_mask = 1
	if get_node_or_null(^"Colision") == null:
		var forma := CollisionShape3D.new()
		forma.name = "Colision"
		var capsula := CapsuleShape3D.new()
		capsula.radius = 0.3 * escala_modelo
		capsula.height = 1.8 * escala_modelo
		forma.shape = capsula
		forma.position.y = 0.9 * escala_modelo
		add_child(forma)
	modelo = get_node_or_null(^"Modelo") as ModeloPersonaje
	if modelo == null:
		modelo = ModeloPersonaje.new()
		modelo.name = "Modelo"
		modelo.personaje = personaje
		modelo.escala = escala_modelo
		modelo.animacion_inicial = anim_quieto
		add_child(modelo)
	modelo.rotation.y = deg_to_rad(orientacion_inicial)
	agente = NavigationAgent3D.new()
	agente.path_desired_distance = 0.6
	agente.target_desired_distance = 0.7
	agente.radius = 0.35
	agente.path_max_distance = 3.0
	add_child(agente)
	var r := get_node_or_null(ruta)
	if r:
		for hijo in r.get_children():
			if hijo is Node3D:
				_puntos.append((hijo as Node3D).global_position)
	Juego.ruido.connect(_al_oir)
	Juego.alarma.connect(_al_alarma)
	cambiar_estado(estado_inicial)
	if estado_inicial == Estado.INACTIVO:
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED


## Activa un enemigo que estaba esperando (aparición guionizada).
func activar(nuevo_estado: Estado = Estado.PATRULLA) -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	cambiar_estado(nuevo_estado)


func cambiar_estado(nuevo: Estado) -> void:
	if estado == Estado.MUERTO and nuevo != Estado.MUERTO:
		return
	var anterior := estado
	estado = nuevo
	_t_estado = 0.0
	if nuevo == Estado.PERSEGUIR and anterior != Estado.PERSEGUIR:
		_al_detectar()
	if anterior == Estado.PERSEGUIR and nuevo != Estado.PERSEGUIR and nuevo != Estado.ATACAR:
		_al_perder()
	estado_cambiado.emit(nuevo)


func _physics_process(delta: float) -> void:
	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group(&"jugador") as Jugador
	_t_estado += delta
	_t_visto += delta
	match estado:
		Estado.QUIETO:
			_estado_quieto(delta)
		Estado.PATRULLA:
			_estado_patrulla(delta)
		Estado.INVESTIGAR:
			_estado_investigar(delta)
		Estado.PERSEGUIR:
			_estado_perseguir(delta)
		Estado.ESPECIAL:
			_estado_especial(delta)
		_:
			velocity.x = 0.0
			velocity.z = 0.0
	if is_on_floor():
		velocity.y = -0.5
	else:
		velocity.y -= _gravedad * delta
	move_and_slide()


# ------------------------------------------------------------------ Estados ---

func _estado_quieto(_delta: float) -> void:
	_parar()
	_vigilar()


func _estado_patrulla(delta: float) -> void:
	if _puntos.is_empty():
		_estado_quieto(delta)
		return
	if _espera > 0.0:
		_espera -= delta
		_parar()
	elif mover_hacia(_puntos[_indice], velocidad_andar, delta):
		_indice = (_indice + 1) % _puntos.size()
		_espera = espera_en_punto
	_vigilar()


func _estado_investigar(delta: float) -> void:
	if mover_hacia(destino, velocidad_andar * 1.3, delta):
		_parar()
		if _t_estado > 0.0 and _espera <= 0.0:
			_espera = 3.0
			_al_llegar_al_ruido()
		_espera -= delta
		if _espera <= 0.0:
			cambiar_estado(Estado.PATRULLA if not _puntos.is_empty() else Estado.QUIETO)
	_vigilar()


func _estado_perseguir(delta: float) -> void:
	if jugador == null or jugador.muerto:
		cambiar_estado(Estado.QUIETO)
		return
	if jugador.oculto:
		# Si lo vio esconderse, va a por él.
		if _escondite_visto and is_instance_valid(_escondite_visto):
			if mover_hacia((_escondite_visto as Node3D).global_position, velocidad_correr, delta, 1.1):
				_sacar_del_escondite()
			return
		_t_sin_ver += delta
	elif puede_ver_jugador():
		ultima_posicion = jugador.global_position
		_t_sin_ver = 0.0
		_t_visto = 0.0
	else:
		_t_sin_ver += delta
	if _t_sin_ver > memoria:
		destino = ultima_posicion
		cambiar_estado(Estado.INVESTIGAR)
		return
	var objetivo := jugador.global_position if _t_sin_ver < 0.6 else ultima_posicion
	mover_hacia(objetivo, velocidad_persecucion(), delta, 0.2)
	if not jugador.oculto and global_position.distance_to(jugador.global_position) <= distancia_ataque \
			and absf(jugador.global_position.y - global_position.y) < 1.2:
		atacar()


func _estado_especial(_delta: float) -> void:
	pass


## Velocidad al perseguir (Policía la ajusta como una goma elástica).
func velocidad_persecucion() -> float:
	return velocidad_correr


## Mira alrededor: si ve al jugador, lo persigue.
func _vigilar() -> void:
	if puede_ver_jugador():
		ultima_posicion = jugador.global_position
		_t_visto = 0.0
		cambiar_estado(Estado.PERSEGUIR)


func _al_llegar_al_ruido() -> void:
	pass


func _al_detectar() -> void:
	detecto_jugador.emit()
	_t_sin_ver = 0.0
	if not _detectado_una_vez:
		_detectado_una_vez = true
	Audio.efecto(&"deteccion", -2.0)
	if luces_al_detectar and jugador and not jugador.en_pasado:
		get_tree().call_group(&"luz_alarma", &"encender")


func _al_perder() -> void:
	if luces_al_detectar:
		var otros := get_tree().get_nodes_in_group(&"enemigo").filter(
				func(e: Node) -> bool: return e != self and (e as Enemigo).estado == Estado.PERSEGUIR)
		if otros.is_empty():
			get_tree().call_group(&"luz_alarma", &"apagar")


# --------------------------------------------------------------- Movimiento ---

## Se mueve hacia [param punto] por la malla de navegación. Devuelve true al llegar.
func mover_hacia(punto: Vector3, velocidad: float, delta: float, margen := 0.6) -> bool:
	var plano := Vector3(punto.x, global_position.y, punto.z)
	if global_position.distance_to(plano) <= margen:
		_parar()
		return true
	agente.target_position = punto
	var siguiente := agente.get_next_path_position()
	var dir := siguiente - global_position
	dir.y = 0.0
	if dir.length() < 0.05 or agente.is_navigation_finished():
		dir = plano - global_position
		dir.y = 0.0
	if dir.length() < 0.01:
		_parar()
		return true
	dir = dir.normalized()
	velocity.x = dir.x * velocidad
	velocity.z = dir.z * velocidad
	girar_hacia(global_position + dir, delta)
	_animar_movimiento(velocidad)
	return false


func _parar() -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if modelo.actual() != anim_quieto and estado != Estado.ATACAR:
		modelo.reproducir(anim_quieto, 0.3)


func girar_hacia(punto: Vector3, delta: float) -> void:
	var hacia := punto - global_position
	hacia.y = 0.0
	if hacia.length() < 0.01:
		return
	var angulo := atan2(-hacia.x, -hacia.z)
	modelo.rotation.y = lerp_angle(modelo.rotation.y, angulo, 1.0 - exp(-velocidad_giro * delta))


func mirar_a(punto: Vector3) -> void:
	var hacia := punto - global_position
	hacia.y = 0.0
	if hacia.length() > 0.01:
		modelo.rotation.y = atan2(-hacia.x, -hacia.z)


func _animar_movimiento(velocidad: float) -> void:
	if velocidad > (velocidad_andar + velocidad_correr) * 0.5 and modelo.tiene(anim_correr):
		modelo.reproducir(anim_correr, 0.2, clampf(velocidad / ritmo_correr, 0.5, 2.0))
	else:
		modelo.reproducir(anim_andar, 0.25, clampf(velocidad / ritmo_andar, 0.4, 2.0))


func adelante() -> Vector3:
	return -modelo.global_basis.z


# ------------------------------------------------------------------ Sentidos ---

func puede_ver_jugador() -> bool:
	if jugador == null or not jugador.es_visible() or vision_distancia <= 0.0:
		return false
	var ojos := global_position + Vector3.UP * 1.6 * escala_modelo
	var objetivo := jugador.punto_visible()
	var hacia := objetivo - ojos
	var alcance := vision_distancia * (0.6 if jugador.agachado else 1.0)
	if hacia.length() > alcance:
		return false
	var plano := Vector3(hacia.x, 0.0, hacia.z).normalized()
	if vision_angulo < 359.0 and rad_to_deg(adelante().angle_to(plano)) > vision_angulo * 0.5:
		return false
	return linea_de_vision(ojos, objetivo)


func linea_de_vision(desde: Vector3, hasta: Vector3) -> bool:
	var rayo := PhysicsRayQueryParameters3D.create(desde, hasta, 1 | 32)
	rayo.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(rayo).is_empty()


func _al_oir(posicion: Vector3, radio: float, origen: Node) -> void:
	if origen == self or estado in [Estado.INACTIVO, Estado.MUERTO, Estado.ATURDIDO, Estado.GUION, Estado.ATACAR]:
		return
	if global_position.distance_to(posicion) > radio * oido:
		return
	oir(posicion, radio, origen)


## Ha oído algo. Por defecto va a investigar (si no está ya persiguiendo).
func oir(posicion: Vector3, _radio: float, _origen: Node) -> void:
	if estado == Estado.PERSEGUIR:
		return
	destino = posicion
	_espera = 0.0
	cambiar_estado(Estado.INVESTIGAR)


func _al_alarma(posicion: Vector3) -> void:
	if estado in [Estado.INACTIVO, Estado.MUERTO, Estado.GUION, Estado.ATACAR]:
		return
	ultima_posicion = posicion
	destino = posicion
	_t_sin_ver = 0.0
	cambiar_estado(Estado.PERSEGUIR)


# ------------------------------------------------------------------- Ataque ---

## Atrapa al jugador. Si lleva el punzón se libra; si no, muere con la animación emparejada.
func atacar() -> void:
	if estado == Estado.ATACAR or jugador == null or jugador.muerto:
		return
	cambiar_estado(Estado.ATACAR)
	_parar()
	mirar_a(jugador.global_position)
	var librado: bool = await jugador.intentar_defensa(self, rompe_punzon)
	if librado:
		_al_recibir_punzon()
		return
	# Coloca a los dos para que la animación emparejada encaje.
	var frente := adelante()
	jugador.global_position = global_position + frente * distancia_pareja
	jugador.reset_physics_interpolation()
	modelo.reproducir(anim_ataque, 0.05)
	Audio.efecto_3d(StringName("ataque_" + personaje), global_position, 2.0, 25.0)
	jugador.morir(anim_muerte_jugador, self, impacto)


func _al_recibir_punzon() -> void:
	aturdir(3.5)


func aturdir(segundos: float) -> void:
	if estado == Estado.MUERTO:
		return
	cambiar_estado(Estado.ATURDIDO)
	_parar()
	if modelo.tiene(&"aturdido"):
		modelo.reproducir(&"aturdido", 0.1)
	await get_tree().create_timer(segundos, false).timeout
	if estado == Estado.ATURDIDO:
		ultima_posicion = jugador.global_position if jugador else global_position
		destino = ultima_posicion
		cambiar_estado(Estado.INVESTIGAR)


## Un disparo le ha dado (§7.1). Por defecto aturde (las manifestaciones no mueren).
func recibir_disparo(_arma: StringName, punto: Vector3) -> void:
	Particulas.sangre(get_tree().current_scene, punto)
	Audio.efecto_3d(&"impacto_carne", punto, 0.0, 20.0)
	aturdir(3.5)


func _sacar_del_escondite() -> void:
	var escondite := _escondite_visto
	_escondite_visto = null
	if escondite and escondite.has_method(&"sacar"):
		var j: Jugador = escondite.sacar()
		if j:
			await get_tree().physics_frame
			atacar()


## Lo llama el jugador al esconderse: si este enemigo lo estaba viendo, recuerda dónde.
func ver_esconderse(escondite: Node) -> void:
	if estado == Estado.PERSEGUIR and _t_visto < 1.0:
		_escondite_visto = escondite
