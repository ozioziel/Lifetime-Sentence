@tool
class_name PuertaTransicion
extends Interactuable
## Puerta que lleva a otro sitio con un fundido a negro (como las puertas de los survival
## horror de PS1). Sirve para escaleras de servicio, despachos o para pasar a otro nivel.
##
## «Destino» = PuntoEntrada (o cualquier Node3D) de este mismo nivel. Si «Nivel Destino»
## tiene valor, se cambia de nivel y se aparece en «Punto Destino».

@export var destino: NodePath
@export var nivel_destino: StringName = &""
@export var punto_destino: StringName = &"inicio"
@export var sonido_puerta: StringName = &"puerta_pesada"
## Segundos en negro (el sonido de la puerta suena mientras).
@export var espera_en_negro := 0.7


func _init() -> void:
	texto = "Cruzar"
	radio = 1.6


func _al_usar(jugador: Jugador) -> bool:
	jugador.bloquear(true)
	Audio.efecto(sonido_puerta, -2.0)
	RenderRig.fundir(1.0, 0.35)
	await get_tree().create_timer(0.4, false).timeout
	if nivel_destino != &"":
		Juego.ir_a(nivel_destino, punto_destino, 0.0)
		return true
	var d := get_node_or_null(destino) as Node3D
	if d:
		jugador.teletransportar(d.global_position, d.global_rotation.y)
	await get_tree().create_timer(espera_en_negro, false).timeout
	RenderRig.fundir(0.0, 0.45)
	jugador.bloquear(false)
	return true
