@tool
class_name Puerta
extends Interactuable
## Puerta que se abre girando sobre sus bisagras (o deslizándose, como la monumental).
##
## «Hoja» = nodo que se mueve; su origen debe estar en la bisagra. Si se deja vacío se
## usa el hijo llamado «Hoja». «Bloqueo» = colisión que se desactiva al abrir (si se deja
## vacío, el hijo «Bloqueo»). Admite todas las cerraduras de Interactuable.

@export var hoja: NodePath
@export var bloqueo: NodePath
## Grados que gira al abrirse (positivo = sentido antihorario visto desde arriba).
@export var angulo_apertura := 95.0
## Si no es cero, la puerta se desliza esta distancia (local) en lugar de girar.
@export var deslizamiento := Vector3.ZERO
@export var duracion := 1.1
@export var sonido_apertura: StringName = &"puerta_reja"

var abierta := false


func _init() -> void:
	texto = "Abrir"
	una_vez = true
	radio = 1.6


func _hoja() -> Node3D:
	if hoja != NodePath():
		return get_node_or_null(hoja) as Node3D
	return get_node_or_null(^"Hoja") as Node3D


func _bloqueo() -> Node:
	if bloqueo != NodePath():
		return get_node_or_null(bloqueo)
	return get_node_or_null(^"Bloqueo")


func _al_usar(_jugador: Jugador) -> bool:
	abrir()
	return true


func _restaurar_usado() -> void:
	abrir(true)


func abrir(instantaneo := false) -> void:
	if abierta:
		return
	abierta = true
	activo = false
	var h := _hoja()
	var b := _bloqueo()
	if b is CollisionObject3D:
		(b as CollisionObject3D).process_mode = Node.PROCESS_MODE_DISABLED
		(b as CollisionObject3D).collision_layer = 0
	elif b is CollisionShape3D:
		(b as CollisionShape3D).set_deferred(&"disabled", true)
	if h == null:
		return
	if not instantaneo:
		Audio.efecto_3d(sonido_apertura, global_position, 0.0, 20.0)
	if deslizamiento != Vector3.ZERO:
		var destino := h.position + deslizamiento
		if instantaneo:
			h.position = destino
		else:
			var tw := create_tween()
			tw.tween_property(h, "position", destino, duracion).set_trans(Tween.TRANS_SINE)
	else:
		var giro := h.rotation.y + deg_to_rad(angulo_apertura)
		if instantaneo:
			h.rotation.y = giro
		else:
			var tw := create_tween()
			tw.tween_property(h, "rotation:y", giro, duracion).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
