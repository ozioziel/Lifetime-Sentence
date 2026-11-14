class_name CamaraJugador
extends Node3D
## Cámara en tercera persona, sobre el hombro, que no atraviesa paredes.
##
## El encuadre (distancia, altura, desplazamiento lateral y campo de visión)
## tiene unos valores por defecto y cambia suavemente cuando el jugador entra
## en una CameraZone. Así cada espacio tiene su propio encuadre: muy cerca en
## los pasillos, abierto en el exterior, lejos en el Patio Central.
##
## Si una pared obliga a la cámara a pegarse al personaje, este se deshace en
## un patrón de puntos para no tapar la vista.

@export var objetivo: Jugador

@export_group("Encuadre por defecto")
## Metros entre la cámara y el punto que sigue.
@export var distancia := 1.9
## Altura del punto que sigue, sobre los pies del jugador.
@export var altura := 1.5
## Desplazamiento lateral: positivo deja al personaje a la izquierda del plano.
@export var desplazamiento_lateral := 0.38
## Campo de visión vertical, en grados.
@export var fov := 62.0
## Segundos que tarda en volver a estos valores al salir de una zona.
@export var tiempo_transicion := 0.8

@export_group("Comportamiento")
## Mayor = la cámara sigue al jugador con menos retraso.
@export var suavizado_seguimiento := 14.0
@export_range(-89.0, 0.0) var inclinacion_minima := -55.0
@export_range(0.0, 89.0) var inclinacion_maxima := 50.0
## Fracción de la altura que se conserva al agacharse.
@export_range(0.3, 1.0) var factor_altura_agachado := 0.66

@export_group("Paredes")
@export_flags_3d_physics var mascara_colision := 1
## Radio de la esfera con la que la cámara «palpa» las paredes.
@export var radio_colision := 0.14
## Rapidez con la que la cámara vuelve a alejarse cuando ya no hay pared detrás.
@export var velocidad_recuperacion := 6.0
## Si una pared obliga a la cámara a acercarse más que esto, el personaje empieza
## a deshacerse en puntos para no tapar la vista...
@export var distancia_inicio_disolucion := 0.95
## ...y a esta distancia ya es invisible.
@export var distancia_fin_disolucion := 0.5

## Giro horizontal actual, en radianes. El jugador lo usa para saber qué es «adelante».
var yaw := 0.0
## true mientras el jugador apunta un arma: encuadre cerrado sobre el hombro.
var apuntando := false
var _sacudida := 0.0
var _pitch := -0.12
var _raton := Vector2.ZERO
var _zonas: Array[CameraZone] = []
var _posicion := Vector3.ZERO

# Valores de encuadre que se están aplicando (mezcla entre zona y por defecto).
var _distancia := 1.9
var _altura := 1.5
var _lateral := 0.38
var _fov := 62.0
var _factor_agachado := 1.0

var _distancia_real := 1.9
var _disolucion := 0.0
var _esfera := SphereShape3D.new()
var _barrido := PhysicsShapeQueryParameters3D.new()

@onready var _pivote: Node3D = $Pivote
## Cámara virtual: RenderRig copia su posición a la cámara real.
@onready var camara: Camera3D = $Pivote/Camara


func _ready() -> void:
	# Se mueve cada fotograma, no cada paso de física: sin interpolación.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	top_level = true
	_distancia = distancia
	_altura = altura
	_lateral = desplazamiento_lateral
	_fov = fov
	_distancia_real = distancia
	_esfera.radius = radio_colision
	_barrido.shape = _esfera
	_barrido.collision_mask = mascara_colision
	if objetivo:
		_barrido.exclude = [objetivo.get_rid()]
	saltar_al_objetivo()
	RenderRig.activar_camara(camara)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _exit_tree() -> void:
	RenderRig.desactivar_camara(camara)


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_raton += (evento as InputEventMouseMotion).relative


func _process(delta: float) -> void:
	if objetivo == null:
		return
	_leer_giro(delta)
	_mezclar_encuadre(delta)

	var destino := objetivo.get_global_transform_interpolated().origin
	_posicion = _posicion.lerp(destino, 1.0 - exp(-suavizado_seguimiento * delta))
	_colocar(delta)
	_actualizar_disolucion(delta)


## Entra una zona de cámara. La llama CameraZone; no hace falta usarla a mano.
func entrar_zona(zona: CameraZone) -> void:
	if not _zonas.has(zona):
		_zonas.append(zona)


func salir_zona(zona: CameraZone) -> void:
	_zonas.erase(zona)


## Fija hacia dónde mira la cámara (radianes). Útil tras un teletransporte.
func fijar_orientacion(nuevo_yaw: float, nuevo_pitch := -0.12) -> void:
	yaw = nuevo_yaw
	_pitch = clampf(nuevo_pitch, deg_to_rad(inclinacion_minima), deg_to_rad(inclinacion_maxima))


## Coloca la cámara en su sitio al instante, sin suavizado.
func saltar_al_objetivo() -> void:
	if objetivo == null:
		return
	_posicion = objetivo.global_position
	_colocar(0.0, true)


## Sacude la cámara (disparos, golpes). [param fuerza] de 0 a 1.
func sacudir(fuerza: float) -> void:
	_sacudida = maxf(_sacudida, fuerza)


## Distancia real entre la cámara y el punto que sigue (menor si hay una pared detrás).
func obtener_distancia_real() -> float:
	return _distancia_real


## Punto del mundo alrededor del cual gira la cámara (junto al hombro del personaje).
func obtener_punto_de_mira() -> Vector3:
	return _pivote.global_position


func _leer_giro(delta: float) -> void:
	var palanca := Input.get_vector(
			&"mirar_izquierda", &"mirar_derecha", &"mirar_arriba", &"mirar_abajo")
	var giro := _raton * Settings.sensibilidad_raton
	giro += palanca * Settings.sensibilidad_mando * delta
	_raton = Vector2.ZERO
	if not objetivo.control_activo:
		return
	var sentido := -1.0 if Settings.invertir_y else 1.0
	yaw = wrapf(yaw - giro.x, -PI, PI)
	_pitch = clampf(_pitch - giro.y * sentido,
			deg_to_rad(inclinacion_minima), deg_to_rad(inclinacion_maxima))


## Acerca el encuadre actual al de la zona activa (o al valor por defecto).
func _mezclar_encuadre(delta: float) -> void:
	var zona := _zona_activa()
	var d := distancia
	var a := altura
	var l := desplazamiento_lateral
	var f := fov
	var t := tiempo_transicion
	if zona:
		d = zona.distancia
		a = zona.altura
		l = zona.desplazamiento_lateral
		f = zona.fov
		t = zona.tiempo_transicion
	if apuntando:
		d = 1.05
		a = 1.58
		l = 0.52
		f = 46.0
		t = 0.18
	# Con este peso se recorre el 95 % del cambio en «t» segundos.
	var peso := 1.0 - exp(-3.0 * delta / maxf(t, 0.01))
	_distancia = lerpf(_distancia, d, peso)
	_altura = lerpf(_altura, a, peso)
	_lateral = lerpf(_lateral, l, peso)
	_fov = lerpf(_fov, f, peso)
	var objetivo_agachado := factor_altura_agachado if objetivo.agachado else 1.0
	_factor_agachado = lerpf(_factor_agachado, objetivo_agachado, 1.0 - exp(-8.0 * delta))


func _zona_activa() -> CameraZone:
	var mejor: CameraZone = null
	for zona in _zonas:
		if not is_instance_valid(zona):
			continue
		# A igual prioridad gana la última en la que se entró.
		if mejor == null or zona.prioridad >= mejor.prioridad:
			mejor = zona
	return mejor


## Coloca el pivote y la cámara. Las paredes se comprueban aquí mismo, en el
## fotograma en que la cámara gira, para que nunca llegue a verse a través de ellas.
func _colocar(delta: float, instantaneo := false) -> void:
	global_position = _posicion
	rotation = Vector3(0.0, yaw, 0.0)
	var espacio := get_world_3d().direct_space_state
	var altura_real := _altura * _factor_agachado
	var centro := _posicion + Vector3.UP * altura_real

	# 1. Desplazamiento lateral (hombro), recortado si hay una pared al lado.
	var lateral := _lateral
	if absf(lateral) > 0.001:
		var lado := signf(lateral)
		var direccion := global_transform.basis.x * lado
		var alcance := absf(lateral) + radio_colision + 0.1
		var rayo := PhysicsRayQueryParameters3D.create(
				centro, centro + direccion * alcance, mascara_colision)
		rayo.exclude = [objetivo.get_rid()]
		var golpe := espacio.intersect_ray(rayo)
		if not golpe.is_empty():
			var libre := maxf(centro.distance_to(golpe.position) - radio_colision - 0.1, 0.0)
			lateral = lado * minf(absf(lateral), libre)
	_pivote.position = Vector3(lateral, altura_real, 0.0)
	_pivote.rotation.x = _pitch

	# 2. Distancia: una esfera barre desde el pivote hacia atrás y se detiene en la pared.
	var pivote := _pivote.global_transform
	_barrido.transform = Transform3D(Basis.IDENTITY, pivote.origin)
	_barrido.motion = pivote.basis.z * _distancia
	var permitida := _distancia * espacio.cast_motion(_barrido)[0]
	if instantaneo or permitida < _distancia_real:
		_distancia_real = permitida  # Acercarse es inmediato...
	else:
		# ...y alejarse de nuevo es suave.
		var peso := 1.0 - exp(-velocidad_recuperacion * delta)
		_distancia_real = minf(permitida, lerpf(_distancia_real, permitida, peso))
	camara.position = Vector3(0.0, 0.0, _distancia_real)
	if _sacudida > 0.0:
		camara.position += Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * _sacudida * 0.07
		_sacudida = move_toward(_sacudida, 0.0, delta * 1.8)
	camara.fov = _fov


func _actualizar_disolucion(delta: float) -> void:
	var destino := clampf(inverse_lerp(
			distancia_inicio_disolucion, distancia_fin_disolucion, _distancia_real), 0.0, 1.0)
	_disolucion = lerpf(_disolucion, destino, 1.0 - exp(-12.0 * delta))
	objetivo.fijar_disolucion_modelo(_disolucion)
