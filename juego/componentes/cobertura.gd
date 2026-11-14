@tool
class_name Cobertura
extends StaticBody3D
## Cobertura destructible (K9): pilas de cajas, barricadas, sacos. Bloquea la vista y el
## paso; La Sentencia la destroza si se interpone. El aspecto lo dan sus hijos (mallas).

@export var tamano := Vector3(1.4, 1.3, 1.0):
	set(valor):
		tamano = valor
		_actualizar()

var _forma: CollisionShape3D


func _ready() -> void:
	_actualizar()
	if not Engine.is_editor_hint():
		add_to_group(&"cobertura")
		collision_layer = 1 | 32


func _actualizar() -> void:
	if not is_inside_tree():
		return
	if _forma == null:
		_forma = CollisionShape3D.new()
		_forma.shape = BoxShape3D.new()
		add_child(_forma, false, Node.INTERNAL_MODE_BACK)
	(_forma.shape as BoxShape3D).size = tamano
	_forma.position = Vector3(0, tamano.y * 0.5, 0)


## La destroza: desaparece su aspecto y su colisión deja de existir.
func destruir() -> void:
	remove_from_group(&"cobertura")
	collision_layer = 0
	collision_mask = 0
	for hijo in get_children():
		if hijo is Node3D:
			var n := hijo as Node3D
			var tw := create_tween()
			tw.tween_property(n, "position", n.position + Vector3(randf_range(-0.6, 0.6), -0.4, randf_range(-0.6, 0.6)), 0.35)
			tw.parallel().tween_property(n, "rotation", Vector3(randf_range(-1, 1), randf_range(-2, 2), randf_range(-1, 1)), 0.35)
			tw.tween_callback(n.hide)
