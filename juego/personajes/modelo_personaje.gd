@tool
class_name ModeloPersonaje
extends Node3D
## Modelo animado de un personaje (cualquier .glb de assets/personajes).
##
## CÓMO USARLO: añadir un Node3D con este script y elegir «Personaje» en el Inspector.
## El modelo se gira 180° para mirar hacia -Z (el «adelante» de Godot).
##     modelo.reproducir(&"andar", 0.2, 1.3)       # en bucle, mezcla de 0,2 s, 1,3x
##     await modelo.reproducir_una_vez(&"recoger")  # espera a que termine
##     modelo.posar(&"morir", 1.0)                  # se queda en el último fotograma (cadáveres)
## Las animaciones se crearon en Blender (assets/scripts/animaciones.py); los nombres
## están en assets/animaciones/manifiesto.json.

signal animacion_terminada(nombre: StringName)

const CARPETA := "res://assets/personajes/"

## Nombre del archivo sin extensión: elias_preso, el_uniforme, aislado_a...
@export var personaje := "elias_preso":
	set(valor):
		personaje = valor
		if is_inside_tree():
			_cargar()
## Animación al empezar (vacío = ninguna).
@export var animacion_inicial: StringName = &"quieto"
## Escala del modelo (La Sentencia y El Director son más grandes que un humano).
@export var escala := 1.0:
	set(valor):
		escala = valor
		if _modelo:
			_modelo.scale = Vector3.ONE * escala
## Fotograma fijo (0-1) de la animación inicial; negativo = reproducirla normalmente.
## Sirve para cadáveres y figuras inmóviles.
@export_range(-1.0, 1.0) var pose_fija := -1.0
## Capas de render del modelo (11 = solo visible en los espejos).
@export_flags_3d_render var capas := 1:
	set(valor):
		capas = valor
		_aplicar_capas()

var animador: AnimationPlayer
var esqueleto: Skeleton3D
var _modelo: Node3D
var _materiales: Array[ShaderMaterial] = []
var _actual: StringName = &""


func _ready() -> void:
	_cargar()


func _cargar() -> void:
	if _modelo:
		_modelo.queue_free()
		_modelo = null
	var ruta := CARPETA + personaje + ".glb"
	if not ResourceLoader.exists(ruta):
		push_warning("ModeloPersonaje: no existe %s" % ruta)
		return
	_modelo = (load(ruta) as PackedScene).instantiate() as Node3D
	_modelo.name = "Modelo"
	_modelo.rotation.y = PI
	_modelo.scale = Vector3.ONE * escala
	add_child(_modelo, false, Node.INTERNAL_MODE_FRONT)
	var lista := _modelo.find_children("*", "AnimationPlayer", true, false)
	animador = lista[0] as AnimationPlayer if not lista.is_empty() else null
	var huesos := _modelo.find_children("*", "Skeleton3D", true, false)
	esqueleto = huesos[0] as Skeleton3D if not huesos.is_empty() else null
	_materiales.clear()
	for nodo in _modelo.find_children("*", "MeshInstance3D", true, false):
		var malla := nodo as MeshInstance3D
		malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for i in malla.mesh.get_surface_count():
			var m := malla.mesh.surface_get_material(i) as ShaderMaterial
			if m and not _materiales.has(m):
				_materiales.append(m)
	_aplicar_capas()
	if animador:
		animador.animation_finished.connect(func(n: StringName) -> void: animacion_terminada.emit(n))
		if animacion_inicial != &"" and animador.has_animation(animacion_inicial):
			if pose_fija >= 0.0:
				posar(animacion_inicial, pose_fija)
			elif not Engine.is_editor_hint():
				reproducir(animacion_inicial, 0.0)
				# Desfase aleatorio: que no respiren todos a la vez.
				animador.seek(randf() * animador.current_animation_length, true)


func _aplicar_capas() -> void:
	if _modelo == null:
		return
	for nodo in _modelo.find_children("*", "VisualInstance3D", true, false):
		(nodo as VisualInstance3D).layers = capas


func tiene(nombre: StringName) -> bool:
	return animador != null and animador.has_animation(nombre)


## Reproduce una animación (en bucle si se exportó como bucle). velocidad: 1 = normal.
func reproducir(nombre: StringName, mezcla := 0.2, velocidad := 1.0) -> void:
	if not tiene(nombre):
		return
	if _actual == nombre and animador.is_playing():
		animador.speed_scale = velocidad
		return
	_actual = nombre
	animador.play(nombre, mezcla)
	animador.speed_scale = velocidad


## Reproduce una animación sin bucle y espera a que termine.
func reproducir_una_vez(nombre: StringName, mezcla := 0.15, velocidad := 1.0) -> void:
	if not tiene(nombre):
		await get_tree().process_frame
		return
	_actual = nombre
	animador.play(nombre, mezcla)
	animador.speed_scale = velocidad
	var duracion := animador.get_animation(nombre).length / maxf(velocidad, 0.01)
	await get_tree().create_timer(duracion, false).timeout


## Cambia solo la velocidad de reproducción (al andar más deprisa o más despacio).
func fijar_velocidad(velocidad: float) -> void:
	if animador:
		animador.speed_scale = velocidad


func actual() -> StringName:
	return _actual


## Deja el modelo quieto en un punto (0-1) de una animación: cadáveres, figuras, pausas.
func posar(nombre: StringName, punto := 1.0) -> void:
	if not tiene(nombre):
		return
	_actual = nombre
	animador.play(nombre, 0.0)
	animador.seek(animador.get_animation(nombre).length * clampf(punto, 0.0, 1.0), true)
	animador.pause()


## Duración en segundos de una animación (0 si no existe).
func duracion(nombre: StringName) -> float:
	return animador.get_animation(nombre).length if tiene(nombre) else 0.0


## 0 = visible, 1 = invisible. El modelo se deshace en puntos (cámara pegada a una pared).
func fijar_disolucion(valor: float) -> void:
	for material in _materiales:
		material.set_shader_parameter(&"disolucion", valor)


## Crea (o devuelve) un punto que sigue a un hueso: para focos, armas, linternas...
func punto_hueso(hueso: StringName) -> BoneAttachment3D:
	if esqueleto == null:
		return null
	var nombre := "Punto_" + String(hueso).replace(".", "_")
	var existente := esqueleto.get_node_or_null(nombre)
	if existente:
		return existente as BoneAttachment3D
	var punto := BoneAttachment3D.new()
	punto.name = nombre
	punto.bone_name = hueso
	esqueleto.add_child(punto)
	return punto


## Posición global de un hueso (para apuntar, mirar...).
func posicion_hueso(hueso: StringName) -> Vector3:
	if esqueleto == null:
		return global_position
	var i := esqueleto.find_bone(hueso)
	if i < 0:
		return global_position
	return esqueleto.global_transform * esqueleto.get_bone_global_pose(i).origin
