extends Node3D
## Recorre en bucle las «postales» del fondo cinematográfico (menú y créditos, C-21):
## un travelling lento por cada escenario, con saltos momentáneos entre pasado y presente
## (destellos de la otra época, estática) y cortes con un instante de negro.

signal postal_cambiada(indice: int)

@export var duracion := 9.0
## Orden de las postales (vacío = todas en orden).
@export var orden: PackedInt32Array = []

var _sets: Array[Node3D] = []
var _activa := true


func _ready() -> void:
	for hijo in get_children():
		if hijo is Node3D and String(hijo.name).begins_with("Set"):
			_sets.append(hijo)
	_bucle()


func detener() -> void:
	_activa = false


func _bucle() -> void:
	var i := 0
	while _activa and is_inside_tree():
		var indice: int = orden[i % orden.size()] if not orden.is_empty() else i % _sets.size()
		await _mostrar(_sets[indice], indice)
		i += 1


func _mostrar(s: Node3D, indice: int) -> void:
	var cam := s.get_node(^"Camara") as Camera3D
	var desde := (s.get_node(^"Desde") as Node3D).global_transform
	var hasta := (s.get_node(^"Hasta") as Node3D).global_transform
	var epoca: int = s.get_meta(&"epoca", 0)
	var perfil := RenderRig.epoca_pasado if epoca == 1 else RenderRig.epoca_presente
	var otra := RenderRig.epoca_presente if epoca == 1 else RenderRig.epoca_pasado
	# Corte con estática y un instante de negro.
	RenderRig.fundir(1.0, 0.0)
	Audio.efecto(&"estatica", -10.0)
	cam.global_transform = desde
	RenderRig.activar_camara(cam)
	RenderRig.aplicar_epoca(perfil, 0.0)
	postal_cambiada.emit(indice)
	await get_tree().create_timer(0.12).timeout
	if not is_inside_tree():
		return
	RenderRig.fundir(0.0, 0.9)
	var t := 0.0
	var siguiente_salto := randf_range(2.2, 4.0)
	while t < duracion and _activa and is_inside_tree():
		await get_tree().process_frame
		if not is_inside_tree():
			return
		var dt := get_process_delta_time()
		t += dt
		var k := smoothstep(0.0, 1.0, t / duracion)
		cam.global_transform = desde.interpolate_with(hasta, k)
		siguiente_salto -= dt
		if siguiente_salto <= 0.0:
			siguiente_salto = randf_range(2.5, 4.5)
			# Salto momentáneo a la otra época.
			RenderRig.aplicar_epoca(otra, 0.0)
			Audio.efecto(&"estatica", -16.0, randf_range(0.8, 1.2))
			await get_tree().create_timer(randf_range(0.07, 0.16)).timeout
			if not is_inside_tree():
				return
			RenderRig.aplicar_epoca(perfil, 0.0)
	RenderRig.desactivar_camara(cam)
