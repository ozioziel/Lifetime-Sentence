class_name Maniqui
extends Node3D
## Maniquí PROVISIONAL del protagonista (etapa 1, bloque 1.1).
##
## Está hecho con cajas y se anima por código: balancea brazos y piernas al
## andar y se encoge al agacharse. Sirve para juzgar escala, cámara y
## movimiento. En el bloque 1.3 se sustituye por el modelo real con animaciones.

## Radianes de zancada por metro recorrido.
@export var frecuencia_paso := 3.3
## Amplitud máxima del balanceo de las piernas, en radianes.
@export var amplitud_paso := 0.75

var _fase := 0.0
var _agachado := 0.0
var _materiales: Array[ShaderMaterial] = []

@onready var _cadera: Node3D = $Cadera
@onready var _pierna_izq: Node3D = $PiernaIzq
@onready var _pierna_der: Node3D = $PiernaDer
@onready var _hombro_izq: Node3D = $Cadera/HombroIzq
@onready var _hombro_der: Node3D = $Cadera/HombroDer

@onready var _altura_cadera := _cadera.position.y


func _ready() -> void:
	# Reúne los materiales del modelo para poder disolverlo (ver fijar_disolucion).
	for nodo in find_children("*", "MeshInstance3D", true, false):
		var material := (nodo as MeshInstance3D).mesh.surface_get_material(0) as ShaderMaterial
		if material and not _materiales.has(material):
			_materiales.append(material)


## 0 = visible, 1 = invisible. Entre medias el modelo se deshace en puntos.
func fijar_disolucion(valor: float) -> void:
	for material in _materiales:
		material.set_shader_parameter(&"disolucion", valor)


## La llama Jugador en cada paso de física.
func actualizar(rapidez: float, agachado: bool, delta: float) -> void:
	_agachado = move_toward(_agachado, 1.0 if agachado else 0.0, delta * 5.0)
	_fase += rapidez * delta * frecuencia_paso

	var intensidad := clampf(rapidez / 3.5, 0.0, 1.0)
	var amplitud := amplitud_paso * (0.25 + 0.75 * intensidad) if rapidez > 0.1 else 0.0
	var balanceo := sin(_fase) * amplitud

	# Al agacharse baja la cadera, se acortan las piernas y el torso se inclina.
	var altura := lerpf(_altura_cadera, _altura_cadera * 0.6, _agachado)
	_cadera.position.y = altura + absf(cos(_fase)) * 0.03 * intensidad
	_cadera.rotation.x = lerpf(-0.06 * intensidad, -0.55, _agachado)

	for pierna: Node3D in [_pierna_izq, _pierna_der]:
		pierna.position.y = altura
		pierna.scale.y = lerpf(1.0, 0.6, _agachado)
	_pierna_izq.rotation.x = balanceo + 0.25 * _agachado
	_pierna_der.rotation.x = -balanceo - 0.25 * _agachado
	_hombro_izq.rotation.x = -balanceo * 0.8
	_hombro_der.rotation.x = balanceo * 0.8
