class_name LuzFluorescente
extends Node3D
## Luminaria fluorescente de techo, con parpadeo y averías.
##
## CÓMO USARLA: arrastrar componentes/luz_fluorescente.tscn al nivel, pegarla
## al techo y elegir su «Estado» en el Inspector. El tubo se ilumina y se
## apaga a la vez que la luz.
##
## Las sombras cuestan rendimiento. En calidad BAJA solo las proyectan las
## luminarias marcadas con «Sombras En Calidad Baja».

enum Estado {
	ESTABLE,        ## Encendida sin variaciones.
	PARPADEO_LEVE,  ## Tiembla un poco y da algún bajón corto.
	AVERIADA,       ## Se apaga y se enciende de forma errática.
	APAGADA,
}

@export var estado: Estado = Estado.ESTABLE
@export var color := Color(0.78, 0.93, 0.88)
@export var energia := 2.6
## Metros que alcanza la luz.
@export var alcance := 8.0
## Apertura del cono de luz, en grados.
@export_range(10.0, 89.0) var apertura := 80.0

## false oculta el tubo (cuando la luminaria ya está modelada en el escenario de Blender).
@export var mostrar_tubo := true

@export_group("Sombras")
@export var proyecta_sombras := true
@export var sombras_en_calidad_baja := false

var _nivel := 1.0
var _encendida := true
var _temporizador := 0.0
var _bajon := 0.0
var _fija := false
var _material: ShaderMaterial

@onready var _luz: SpotLight3D = $Luz
@onready var _tubo: MeshInstance3D = $Tubo


func _ready() -> void:
	add_to_group(&"luz_fluorescente")
	# Cada luminaria necesita su propia copia del material para brillar por separado.
	_material = (_tubo.mesh.surface_get_material(0) as ShaderMaterial).duplicate()
	_tubo.material_override = _material
	_tubo.visible = mostrar_tubo
	_material.set_shader_parameter(&"emision", color)
	_luz.light_color = color
	_luz.spot_range = alcance
	_luz.spot_angle = apertura
	_temporizador = randf_range(0.2, 2.0)
	Settings.cambiado.connect(_al_cambiar_ajuste)
	_actualizar_sombras()
	_aplicar()


func _process(delta: float) -> void:
	var modo := Estado.ESTABLE if _fija and estado != Estado.APAGADA else estado
	match modo:
		Estado.ESTABLE:
			_nivel = 1.0
		Estado.APAGADA:
			_nivel = 0.0
		Estado.PARPADEO_LEVE:
			_temporizador -= delta
			_bajon = maxf(_bajon - delta, 0.0)
			if _temporizador <= 0.0:
				_temporizador = randf_range(1.5, 6.0)
				_bajon = randf_range(0.04, 0.12)
			_nivel = randf_range(0.9, 1.0) * (0.45 if _bajon > 0.0 else 1.0)
		Estado.AVERIADA:
			_temporizador -= delta
			if _temporizador <= 0.0:
				_encendida = not _encendida
				_temporizador = _duracion_averia(_encendida)
			_nivel = randf_range(0.82, 1.0) if _encendida else 0.0
	_aplicar()


## Deja la luz encendida y quieta (capturas de pantalla, cinemáticas).
func fijar_estable(valor: bool) -> void:
	_fija = valor


func _duracion_averia(encendida: bool) -> float:
	if encendida:
		# Casi siempre destellos cortos; a veces aguanta encendida un rato.
		return randf_range(0.03, 0.14) if randf() < 0.55 else randf_range(0.4, 2.6)
	return randf_range(0.03, 0.3) if randf() < 0.85 else randf_range(0.6, 1.5)


func _aplicar() -> void:
	_luz.light_energy = energia * _nivel
	_luz.visible = _nivel > 0.01
	_material.set_shader_parameter(&"energia_emision", 0.12 + 2.8 * _nivel)


func _al_cambiar_ajuste(nombre: StringName) -> void:
	if nombre == &"calidad":
		_actualizar_sombras()


func _actualizar_sombras() -> void:
	var alto := Settings.calidad == Settings.Calidad.ALTO
	_luz.shadow_enabled = proyecta_sombras and (alto or sombras_en_calidad_baja)
