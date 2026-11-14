class_name Proyectil
extends RigidBody3D
## Botella o lata lanzada por el jugador (K5). Al chocar hace ruido donde cae: los
## enemigos que se guían por el oído (Los Aislados, El Uniforme) van hacia allí.

## botella o lata.
var tipo := &"botella"
var _roto := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	contact_monitor = true
	max_contacts_reported = 2
	continuous_cd = true
	mass = 0.4
	var forma := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 0.06
	forma.shape = esfera
	add_child(forma)
	var malla := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.radial_segments = 6
	cilindro.rings = 1
	if tipo == &"botella":
		cilindro.top_radius = 0.025
		cilindro.bottom_radius = 0.04
		cilindro.height = 0.26
	else:
		cilindro.top_radius = 0.033
		cilindro.bottom_radius = 0.033
		cilindro.height = 0.12
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.16, 0.3, 0.16) if tipo == &"botella" else Color(0.55, 0.52, 0.48)
	material.metallic = 0.0 if tipo == &"botella" else 0.6
	material.roughness = 0.3
	cilindro.material = material
	malla.mesh = cilindro
	add_child(malla)
	body_entered.connect(_impacto)
	get_tree().create_timer(6.0, false).timeout.connect(queue_free)


func lanzar(origen: Vector3, velocidad: Vector3) -> void:
	global_position = origen
	linear_velocity = velocidad
	angular_velocity = Vector3(randf_range(-9, 9), randf_range(-4, 4), randf_range(-9, 9))
	Audio.efecto_3d(&"lanzar", origen, -6.0, 10.0)


func _impacto(_cuerpo: Node) -> void:
	if _roto:
		return
	_roto = true
	var donde := global_position
	if tipo == &"botella":
		Audio.efecto_3d(&"botella_rota", donde, 4.0, 40.0)
		Particulas.cristales(get_tree().current_scene, donde)
		Juego.emitir_ruido(donde, 16.0, self)
		queue_free()
	else:
		Audio.efecto_3d(&"lata", donde, 2.0, 35.0)
		Juego.emitir_ruido(donde, 13.0, self)
		linear_velocity *= 0.3
