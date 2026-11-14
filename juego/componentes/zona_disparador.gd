@tool
class_name ZonaDisparador
extends Area3D
## Zona invisible que, al entrar el jugador, llama a una función del script del nivel
## (sustos, cinemáticas, apariciones, cambios de música...). En el editor se ve naranja.

signal activada(jugador: Jugador)

@export var tamano := Vector3(2.0, 2.5, 2.0):
	set(valor):
		tamano = valor.max(Vector3(0.1, 0.1, 0.1))
		_actualizar_forma()
## Función del script del nivel (recibe este nodo).
@export var metodo_nivel: StringName = &""
@export var una_vez := true
## Bandera de Juego para no repetirla al recargar (vacío = se repite al recargar).
@export var bandera: StringName = &""

var _forma: CollisionShape3D
var _vista: MeshInstance3D
var _usada := false


func _ready() -> void:
	_actualizar_forma()
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	if bandera != &"" and Juego.bandera(bandera):
		_usada = true
	body_entered.connect(_al_entrar)


func _al_entrar(cuerpo: Node3D) -> void:
	var j := cuerpo as Jugador
	if j == null or (una_vez and _usada) or j.muerto:
		return
	_usada = true
	if bandera != &"":
		Juego.poner_bandera(bandera)
	activada.emit(j)
	if metodo_nivel != &"" and Juego.nivel and Juego.nivel.has_method(metodo_nivel):
		Juego.nivel.call(metodo_nivel, self)


func _actualizar_forma() -> void:
	if not is_inside_tree():
		return
	if _forma == null:
		_forma = CollisionShape3D.new()
		_forma.shape = BoxShape3D.new()
		add_child(_forma, false, Node.INTERNAL_MODE_BACK)
	(_forma.shape as BoxShape3D).size = tamano
	if Engine.is_editor_hint():
		if _vista == null:
			_vista = MeshInstance3D.new()
			var m := StandardMaterial3D.new()
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(1.0, 0.55, 0.1, 0.14)
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			var malla := BoxMesh.new()
			malla.material = m
			_vista.mesh = malla
			add_child(_vista, false, Node.INTERNAL_MODE_BACK)
		(_vista.mesh as BoxMesh).size = tamano
