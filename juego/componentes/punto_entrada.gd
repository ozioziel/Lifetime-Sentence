@tool
class_name PuntoEntrada
extends Marker3D
## Punto donde aparece el jugador al entrar en un nivel, al cargar una partida o al
## cruzar una PuertaTransicion. La flecha azul (−Z) indica hacia dónde mira.

@export var id: StringName = &"inicio"


func _ready() -> void:
	gizmo_extents = 0.6
	if not Engine.is_editor_hint():
		add_to_group(&"punto_entrada")
