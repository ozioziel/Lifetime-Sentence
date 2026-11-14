class_name ElUniforme
extends Enemigo
## EL UNIFORME (E2/E3): patrulla con un aro de llaves que suena. Cada cierto tiempo las
## llaves callan y empieza el RECUENTO: se detiene y cuenta. Durante el Recuento, quien
## se mueva dentro de su mirada es descubierto; quien se queda quieto, no.
## Si te atrapa te alza del cuello. El punzón te libra una vez y se rompe (§7.1).
## La pistola lo aturde 3-4 s; no muere.

## Segundos entre recuentos (mínimo y máximo).
@export var intervalo_recuento := Vector2(22.0, 36.0)
@export var duracion_recuento := 8.0
## Velocidad del jugador a partir de la cual «se mueve» durante el Recuento.
@export var umbral_movimiento := 0.25

var _t_recuento := 0.0
var _llaves: AudioStreamPlayer3D
var _contando := false


func _init() -> void:
	personaje = "el_uniforme"
	anim_quieto = &"quieto"
	anim_andar = &"andar"
	anim_correr = &"perseguir"
	ritmo_andar = 1.0
	ritmo_correr = 2.4
	velocidad_andar = 1.0
	velocidad_correr = 2.4
	anim_ataque = &"agarrar"
	anim_muerte_jugador = &"muerte_cuello"
	distancia_pareja = 0.6
	distancia_ataque = 1.0
	rompe_punzon = true
	vision_distancia = 10.0
	vision_angulo = 90.0
	impacto = 0.72


func _ready() -> void:
	super()
	_t_recuento = randf_range(intervalo_recuento.x, intervalo_recuento.y) * 0.6
	_llaves = Audio.emisor(self, &"llaves", -4.0, 22.0)
	_llaves.position.y = 1.0


func _physics_process(delta: float) -> void:
	super(delta)
	if estado == Estado.PATRULLA or estado == Estado.INVESTIGAR or estado == Estado.QUIETO:
		_t_recuento -= delta
		if _t_recuento <= 0.0:
			_empezar_recuento()
	# Las llaves solo suenan al andar (y nunca durante el Recuento).
	if _llaves:
		var andando := Vector3(velocity.x, 0, velocity.z).length() > 0.2 and not _contando
		_llaves.volume_db = lerpf(_llaves.volume_db, -2.0 if andando else -60.0, 1.0 - exp(-8.0 * delta))


func _empezar_recuento() -> void:
	_contando = true
	cambiar_estado(Estado.ESPECIAL)
	_parar()
	add_to_group(&"recuento_activo")
	modelo.reproducir(&"recuento", 0.3)
	Audio.efecto_3d(&"recuento", global_position, -2.0, 25.0)


func _estado_especial(delta: float) -> void:
	# RECUENTO
	velocity.x = 0.0
	velocity.z = 0.0
	if jugador and puede_ver_jugador():
		var v := Vector3(jugador.velocity.x, 0, jugador.velocity.z).length()
		if v > umbral_movimiento:
			_terminar_recuento()
			ultima_posicion = jugador.global_position
			cambiar_estado(Estado.PERSEGUIR)
			return
	if _t_estado >= duracion_recuento:
		_terminar_recuento()
		cambiar_estado(Estado.PATRULLA if not _puntos.is_empty() else Estado.QUIETO)


func _terminar_recuento() -> void:
	_contando = false
	remove_from_group(&"recuento_activo")
	_t_recuento = randf_range(intervalo_recuento.x, intervalo_recuento.y)


func _al_recibir_punzon() -> void:
	modelo.reproducir(&"aturdido", 0.1)
	aturdir(3.5)


func recibir_disparo(_arma: StringName, punto: Vector3) -> void:
	Audio.efecto_3d(&"impacto_carne", punto, 0.0, 20.0)
	Particulas.sangre(get_tree().current_scene, punto)
	if _contando:
		_terminar_recuento()
	aturdir(3.5)
