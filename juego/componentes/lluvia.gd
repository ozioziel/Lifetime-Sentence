class_name Lluvia
extends GPUParticles3D
## Lluvia intensa (A5, pasado). Sigue a la cámara activa para que siempre llueva
## alrededor de lo que se ve, sin cubrir todo el nivel de partículas.

@export var intensidad := 1.0
@export var color_gota := Color(0.72, 0.74, 0.76, 0.22)
## Si es mayor que 0, solo llueve cuando la cámara está a menos de esa distancia del punto
## donde se colocó la lluvia (para escenas con varios sitios, como el menú).
@export var radio_activo := 0.0

var _origen := Vector3.ZERO


func _ready() -> void:
	_origen = global_position
	amount = int(2200 * intensidad)
	lifetime = 0.9
	preprocess = 1.0
	local_coords = false
	visibility_aabb = AABB(Vector3(-14, -12, -14), Vector3(28, 24, 28))
	var proceso := ParticleProcessMaterial.new()
	proceso.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	proceso.emission_box_extents = Vector3(11, 0.5, 11)
	proceso.direction = Vector3(0.08, -1, 0.03)
	proceso.spread = 2.0
	proceso.initial_velocity_min = 15.0
	proceso.initial_velocity_max = 18.0
	proceso.gravity = Vector3(0, -6, 0)
	process_material = proceso
	var gota := QuadMesh.new()
	gota.size = Vector2(0.01, 0.38)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = color_gota
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	gota.material = m
	draw_pass_1 = gota
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _process(_delta: float) -> void:
	var cam := RenderRig.obtener_camara_activa()
	if cam == null:
		cam = RenderRig.camara
	if radio_activo > 0.0:
		emitting = cam.global_position.distance_to(_origen) < radio_activo
		visible = emitting
	global_position = cam.global_position + Vector3(0, 7.5, 0) - cam.global_basis.z * 4.0
