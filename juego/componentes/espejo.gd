@tool
class_name Espejo
extends Node3D
## Espejo de verdad (K8): una segunda cámara, reflejada respecto al plano del espejo,
## dibuja la escena a baja resolución y la imagen se pega al cristal (técnica de «portal»).
## La capa de render 11 («solo_espejo») solo se ve aquí: lo que se pone en ella (El
## Condenado) aparece en el reflejo... y no detrás del jugador al darse la vuelta.
##
## El nodo mira hacia +Z local: colocar el espejo con su +Z apuntando a la sala.

@export var tamano := Vector2(0.9, 1.2):
	set(valor):
		tamano = valor
		_actualizar_malla()
## Alto en píxeles de la imagen del reflejo (baja, a lo PS1).
@export var resolucion := 110
## Distancia a la que se activa (por rendimiento solo se dibuja de cerca).
@export var distancia_activacion := 8.0
@export var tinte := Color(0.78, 0.82, 0.84)
## 0 = limpio, 1 = muy sucio (manchas oscuras).
@export_range(0.0, 1.0) var suciedad := 0.35

var _vista: SubViewport
var _camara: Camera3D
var _malla: MeshInstance3D
var _material: ShaderMaterial

const SHADER := """
shader_type spatial;
render_mode unshaded, cull_back;
uniform sampler2D reflejo : filter_nearest, source_color;
uniform vec4 tinte : source_color = vec4(0.78, 0.82, 0.84, 1.0);
uniform float suciedad = 0.35;
uniform float activo = 1.0;
float ruido(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = vec2(1.0 - UV.x, UV.y);
	vec3 c = texture(reflejo, uv).rgb * tinte.rgb * activo;
	vec2 celda = floor(UV * vec2(18.0, 24.0));
	float mancha = smoothstep(0.55, 1.0, ruido(celda)) * suciedad;
	float borde = smoothstep(0.0, 0.08, min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y)));
	ALBEDO = c * (1.0 - mancha * 0.7) * mix(0.35, 1.0, borde) + vec3(0.02, 0.025, 0.03);
}
"""


func _ready() -> void:
	_actualizar_malla()
	if Engine.is_editor_hint():
		return
	_vista = SubViewport.new()
	_vista.size = Vector2i(maxi(int(resolucion * tamano.x / tamano.y), 8), resolucion)
	_vista.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_vista.msaa_3d = Viewport.MSAA_DISABLED
	_vista.positional_shadow_atlas_size = 512
	add_child(_vista)
	_camara = Camera3D.new()
	_camara.cull_mask = 0xFFFFF
	_camara.current = true
	_vista.add_child(_camara)
	_material.set_shader_parameter(&"reflejo", _vista.get_texture())


func _actualizar_malla() -> void:
	if not is_inside_tree():
		return
	if _malla == null:
		_malla = MeshInstance3D.new()
		_malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_malla, false, Node.INTERNAL_MODE_FRONT)
		var shader := Shader.new()
		shader.code = SHADER
		_material = ShaderMaterial.new()
		_material.shader = shader
	var quad := QuadMesh.new()
	quad.size = tamano
	_malla.mesh = quad
	_malla.material_override = _material
	_material.set_shader_parameter(&"tinte", tinte)
	_material.set_shader_parameter(&"suciedad", suciedad)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or _vista == null:
		return
	var principal := RenderRig.camara
	var n := global_basis.z.normalized()
	var p0 := global_position
	var c := principal.global_position
	var lado := (c - p0).dot(n)
	var activo := lado > 0.05 and c.distance_to(p0) < distancia_activacion
	_vista.render_target_update_mode = SubViewport.UPDATE_ALWAYS if activo else SubViewport.UPDATE_DISABLED
	_material.set_shader_parameter(&"activo", 1.0 if activo else 0.15)
	if not activo:
		return
	_camara.environment = principal.environment
	# Cámara reflejada al otro lado del plano, mirando hacia la sala.
	var reflejada := c - 2.0 * n * lado
	var arriba := global_basis.y.normalized()
	var z := -n
	var x := arriba.cross(z).normalized()
	var y := z.cross(x).normalized()
	_camara.global_transform = Transform3D(Basis(x, y, z), reflejada)
	# Frustum descentrado: el plano cercano coincide exactamente con el cristal.
	var relativo := _camara.global_basis.inverse() * (p0 - reflejada)
	var distancia := maxf(-relativo.z, 0.05)
	_camara.keep_aspect = Camera3D.KEEP_HEIGHT
	_camara.set_frustum(tamano.y, Vector2(relativo.x, relativo.y), distancia, 60.0)
