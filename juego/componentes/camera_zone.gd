@tool
class_name CameraZone
extends Area3D
## Zona que cambia el encuadre de la cámara mientras el jugador está dentro.
##
## CÓMO USARLA: arrastrar componentes/camera_zone.tscn al nivel, colocarla y
## ajustar «Tamano» y los valores de «Encuadre» en el Inspector. En el editor
## se ve como una caja azul translúcida; en el juego es invisible.
## Si dos zonas se solapan, manda la de mayor «Prioridad».

## Tamaño de la zona en metros (ancho, alto, fondo).
@export var tamano := Vector3(4.0, 3.0, 4.0):
	set(valor):
		tamano = valor.max(Vector3(0.1, 0.1, 0.1))
		_actualizar_forma()

@export_group("Encuadre")
## Metros entre la cámara y el personaje. Menor = más claustrofóbico.
@export var distancia := 1.6
## Altura del punto que sigue la cámara, sobre los pies del jugador.
@export var altura := 1.45
## Positivo: el personaje queda a la izquierda del plano.
@export var desplazamiento_lateral := 0.35
## Campo de visión vertical, en grados. Mayor = más espacio visible.
@export var fov := 62.0
## Segundos que tarda la cámara en adoptar este encuadre.
@export var tiempo_transicion := 0.8
## Con zonas solapadas, se aplica la de número más alto.
@export var prioridad := 0

var _forma: CollisionShape3D
var _vista_editor: MeshInstance3D


func _ready() -> void:
	_actualizar_forma()
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 2  # Capa «jugador».
	monitoring = true
	monitorable = false
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)


func _al_entrar(cuerpo: Node3D) -> void:
	var jugador := cuerpo as Jugador
	if jugador and jugador.camara:
		jugador.camara.entrar_zona(self)


func _al_salir(cuerpo: Node3D) -> void:
	var jugador := cuerpo as Jugador
	if jugador and jugador.camara:
		jugador.camara.salir_zona(self)


func _actualizar_forma() -> void:
	if not is_inside_tree():
		return
	if _forma == null:
		_forma = CollisionShape3D.new()
		_forma.shape = BoxShape3D.new()
		add_child(_forma, false, Node.INTERNAL_MODE_BACK)
	(_forma.shape as BoxShape3D).size = tamano

	# Caja translúcida para verla en el editor (no existe en el juego).
	if Engine.is_editor_hint():
		if _vista_editor == null:
			_vista_editor = MeshInstance3D.new()
			var material := StandardMaterial3D.new()
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.albedo_color = Color(0.2, 0.75, 1.0, 0.14)
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
			var malla := BoxMesh.new()
			malla.material = material
			_vista_editor.mesh = malla
			_vista_editor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(_vista_editor, false, Node.INTERNAL_MODE_BACK)
		(_vista_editor.mesh as BoxMesh).size = tamano
