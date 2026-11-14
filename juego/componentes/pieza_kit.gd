@tool
class_name PiezaKit
extends Node3D
## Una pieza suelta de un kit modular de Blender (assets/kits/*.glb): una fachada, un cubo
## de basura, un archivador, una camilla... Se elige el kit y el nombre de la pieza en el
## Inspector; la pieza aparece con su origen en este nodo.
##
## Kits: kit_prision (módulos de celdas, puentes, torre...), kit_bloque_a, kit_ciudad
## (fachadas, farolas, verja, coche patrulla...) y kit_interiores (mobiliario, mecanismos).

enum Colision { NINGUNA, CAJA, MALLA }

@export_enum("kit_prision", "kit_bloque_a", "kit_ciudad", "kit_interiores") var kit := "kit_ciudad":
	set(valor):
		kit = valor
		_reconstruir()
@export var pieza := "Kit_Cubo":
	set(valor):
		pieza = valor
		_reconstruir()
@export var colision: Colision = Colision.CAJA:
	set(valor):
		colision = valor
		_reconstruir()
## Añade la colisión al grupo «navegable» (los enemigos la tienen en cuenta).
@export var navegable := true

static var _cache := {}
var _visual: Node3D


func _ready() -> void:
	_reconstruir()


func _reconstruir() -> void:
	if not is_inside_tree():
		return
	if _visual:
		_visual.queue_free()
		_visual = null
	var ruta := "res://assets/kits/%s.glb" % kit
	if not ResourceLoader.exists(ruta):
		return
	if not _cache.has(ruta):
		_cache[ruta] = load(ruta)
	var completo := (_cache[ruta] as PackedScene).instantiate()
	var original := completo.find_child(pieza, true, false) as Node3D
	if original == null:
		push_warning("PiezaKit: no existe «%s» en %s" % [pieza, kit])
		completo.free()
		return
	_visual = original.duplicate() as Node3D
	completo.free()
	_visual.name = "Visual"
	_visual.transform = Transform3D(_visual.transform.basis, Vector3.ZERO)
	add_child(_visual, false, Node.INTERNAL_MODE_FRONT)
	if Engine.is_editor_hint() or colision == Colision.NINGUNA:
		return
	for nodo in _visual.find_children("*", "MeshInstance3D", true, false) + ([_visual] if _visual is MeshInstance3D else []):
		var mi := nodo as MeshInstance3D
		if colision == Colision.MALLA:
			mi.create_trimesh_collision()
		else:
			var cuerpo := StaticBody3D.new()
			var forma := CollisionShape3D.new()
			var caja := BoxShape3D.new()
			var aabb := mi.get_aabb()
			caja.size = aabb.size.max(Vector3(0.05, 0.05, 0.05))
			forma.shape = caja
			forma.position = aabb.get_center()
			cuerpo.add_child(forma)
			mi.add_child(cuerpo)
		if navegable:
			for c in mi.get_children():
				if c is StaticBody3D:
					c.add_to_group(&"navegable")
