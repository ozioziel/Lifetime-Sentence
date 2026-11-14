class_name Particulas
extends RefCounted
## Efectos de partículas de un solo disparo (chispas, sangre, cristales, polvo).
## Usan CPUParticles3D para funcionar igual en todos los renderizadores.
##     Particulas.chispa(get_tree().current_scene, punto, normal)


static func _crear(padre: Node, posicion: Vector3, cantidad: int, color: Color, tamano: float,
		velocidad: float, vida: float, gravedad: float, direccion := Vector3.UP, dispersion := 60.0) -> CPUParticles3D:
	if padre == null:
		return null
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = cantidad
	p.lifetime = vida
	p.explosiveness = 0.95
	p.direction = direccion
	p.spread = dispersion
	p.initial_velocity_min = velocidad * 0.5
	p.initial_velocity_max = velocidad
	p.gravity = Vector3(0, -gravedad, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.0
	var caja := BoxMesh.new()
	caja.size = Vector3.ONE * tamano
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	caja.material = m
	p.mesh = caja
	padre.add_child(p)
	p.global_position = posicion
	p.emitting = true
	p.get_tree().create_timer(vida + 0.5, false).timeout.connect(p.queue_free)
	return p


static func chispa(padre: Node, posicion: Vector3, normal := Vector3.UP) -> void:
	_crear(padre, posicion, 10, Color(1.0, 0.75, 0.35), 0.018, 4.0, 0.25, 9.0, normal, 50.0)


static func sangre(padre: Node, posicion: Vector3, direccion := Vector3.UP) -> void:
	_crear(padre, posicion, 18, Color(0.32, 0.02, 0.02), 0.035, 2.5, 0.7, 9.8, direccion, 45.0)


static func cristales(padre: Node, posicion: Vector3) -> void:
	_crear(padre, posicion, 14, Color(0.4, 0.55, 0.42), 0.02, 2.6, 0.6, 9.8, Vector3.UP, 80.0)


static func polvo(padre: Node, posicion: Vector3) -> void:
	_crear(padre, posicion, 26, Color(0.45, 0.43, 0.4), 0.09, 2.2, 1.2, 2.0, Vector3.UP, 90.0)
