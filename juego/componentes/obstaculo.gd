@tool
class_name Obstaculo
extends Interactuable
## Obstáculos del PASADO (K1 y S1):
##   SALTABLE: «pasar por encima» (cajas, cubos, un capó). Se puede repetir. Los
##             perseguidores pierden un instante al cruzarlo.
##   DERRIBABLE: «derribar» un cubo o una pila de cajas; la «Pieza» cae y frena a los
##             perseguidores que pasan junto a ella.

enum Tipo { SALTABLE, DERRIBABLE }

@export var tipo: Tipo = Tipo.SALTABLE
## Metros que avanza Elías al pasar por encima.
@export var distancia := 1.9
## Nodo visual que cae al derribarlo.
@export var pieza: NodePath


func _init() -> void:
	epoca = Epoca.PASADO
	radio = 1.6


func _ready() -> void:
	if tipo == Tipo.SALTABLE:
		texto = "Pasar por encima"
		una_vez = false
	else:
		texto = "Derribar"
		una_vez = true
		persistente = false
	super()
	if not Engine.is_editor_hint():
		add_to_group(&"obstaculo_saltable" if tipo == Tipo.SALTABLE else &"obstaculo_derribable")


func _al_usar(jugador: Jugador) -> bool:
	if tipo == Tipo.SALTABLE:
		var dir := global_position - jugador.global_position
		dir.y = 0.0
		if dir.length() < 0.05:
			dir = -jugador.modelo().global_basis.z
		dir = dir.normalized()
		var largo := clampf(dir.dot(global_position - jugador.global_position) * 2.0, distancia, distancia + 0.8)
		jugador.modelo().rotation.y = atan2(-dir.x, -dir.z)
		Audio.efecto_3d(&"saltar_obstaculo", global_position, -2.0, 15.0)
		await jugador.desplazar_con_animacion(&"pasar_por_encima", dir * largo, 0.95)
		return true
	jugador.ocupado = true
	jugador.modelo().reproducir(&"derribar", 0.1)
	await get_tree().create_timer(0.35, false).timeout
	derribar(jugador.global_position)
	await get_tree().create_timer(0.6, false).timeout
	jugador.ocupado = false
	return true


## Tira la pieza hacia el lado contrario a [param desde].
func derribar(desde: Vector3) -> void:
	add_to_group(&"obstaculo_derribado")
	Audio.efecto_3d(&"derribar", global_position, 2.0, 30.0)
	var p := get_node_or_null(pieza) as Node3D
	if p == null:
		return
	var lejos := global_position - desde
	lejos.y = 0.0
	lejos = lejos.normalized() if lejos.length() > 0.01 else Vector3.FORWARD
	var eje := Vector3.UP.cross(lejos).normalized()
	var tw := create_tween()
	var inicio := p.global_transform
	tw.tween_method(func(t: float) -> void:
		var giro := Basis(eje, t * PI * 0.5)
		p.global_transform = Transform3D(giro * inicio.basis, inicio.origin + lejos * t * 0.45 + Vector3.DOWN * t * 0.1),
		0.0, 1.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
