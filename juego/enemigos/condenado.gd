class_name ElCondenado
extends Enemigo
## EL CONDENADO (K8): una manifestación que vive en los espejos. Normalmente está en la
## capa «solo_espejo» (11): se le ve en el reflejo, detrás del jugador, pero al darse la
## vuelta no hay nadie. El script del nivel decide dónde aparece y cuándo ataca.

## Distancia a la espalda del jugador a la que se coloca en los reflejos.
@export var distancia_espalda := 1.6

var _siguiendo := false


func _init() -> void:
	personaje = "el_condenado"
	anim_quieto = &"quieto"
	anim_andar = &"acechar"
	anim_correr = &"acechar"
	ritmo_andar = 1.1
	ritmo_correr = 1.1
	velocidad_andar = 1.1
	velocidad_correr = 1.1
	anim_ataque = &"atacar"
	anim_muerte_jugador = &"muerte_arrastrado"
	distancia_pareja = 0.8
	vision_distancia = 0.0
	oido = 0.0
	estado_inicial = Estado.GUION
	luces_al_detectar = false
	impacto = 0.7


func _ready() -> void:
	super()
	solo_en_espejos(true)


## true: solo se le ve reflejado (y no choca con nada). false: está «de verdad» en la sala.
func solo_en_espejos(valor: bool) -> void:
	modelo.capas = 1 << 10 if valor else 1
	collision_layer = 0 if valor else 4


## El punzón lo hace retroceder: vuelve a los espejos.
func _al_recibir_punzon() -> void:
	cambiar_estado(Estado.GUION)
	solo_en_espejos(true)
	seguir_al_jugador(true)


## Se coloca detrás del jugador y lo sigue (solo visible en los espejos).
func seguir_al_jugador(valor: bool) -> void:
	_siguiendo = valor
	visible = true


func _physics_process(delta: float) -> void:
	if _siguiendo and jugador and estado == Estado.GUION:
		var atras := jugador.modelo().global_basis.z
		atras.y = 0.0
		var punto := jugador.global_position + atras.normalized() * distancia_espalda
		global_position = global_position.lerp(Vector3(punto.x, jugador.global_position.y, punto.z), 1.0 - exp(-3.0 * delta))
		girar_hacia(jugador.global_position, delta)
		modelo.reproducir(&"quieto", 0.4)
		return
	super(delta)


## Aparece de verdad detrás del jugador y lo mata (tercer error en el puzle de espejos).
func atacar_por_la_espalda() -> void:
	_siguiendo = false
	solo_en_espejos(false)
	visible = true
	var atras := jugador.modelo().global_basis.z
	atras.y = 0.0
	global_position = jugador.global_position + atras.normalized() * 1.1
	mirar_a(jugador.global_position)
	Audio.efecto(&"condenado_grito", 4.0)
	cambiar_estado(Estado.PERSEGUIR)
	atacar()


func recibir_disparo(_arma: StringName, _punto: Vector3) -> void:
	pass
