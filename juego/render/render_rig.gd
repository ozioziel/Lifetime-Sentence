extends Node
## Tubería de render PS1 (autoload «RenderRig»).
##
## Todo el juego 3D se dibuja en una imagen interna de 480 x 270 píxeles
## (el SubViewport «VistaJuego»). Sobre ella se aplica el posproceso PS1 y
## después se amplía a la ventana con píxeles nítidos. La interfaz se dibuja
## aparte, a la resolución real de la pantalla, para que el texto sea legible.
##
## CÁMARAS. Las cámaras de los niveles (la del jugador, las de las cinemáticas)
## son «cámaras virtuales»: marcan dónde y cómo se mira. La única cámara que
## dibuja de verdad es la de este nodo, que copia cada fotograma a la cámara
## virtual activa. Para activar una:
##     RenderRig.activar_camara(mi_camara, 1.5)   # mezcla de 1,5 segundos
##     RenderRig.desactivar_camara(mi_camara)     # vuelve a la anterior
## Si ninguna está activada, se usa la primera Camera3D de la escena, así que
## cualquier escena con una cámara funciona al ejecutarla con F6.
##
## ÉPOCAS. El aspecto de PRESENTE y PASADO está en dos recursos PerfilEpoca:
##     RenderRig.aplicar_epoca(RenderRig.epoca_pasado, 1.0)

signal epoca_cambiada(perfil: PerfilEpoca)

## Resolución interna del juego. Decisión de arte A1: no cambiar sin consultarlo.
const RESOLUCION_INTERNA := Vector2i(480, 270)
@export var epoca_presente: PerfilEpoca
@export var epoca_pasado: PerfilEpoca
## Intensidad del temblor de vértices. 0 = apagado, 1 = auténtico.
@export_range(0.0, 4.0, 0.05) var vibracion_vertices := 1.0
## Deformación afín de las texturas. 0 = apagada (decisión A1).
@export_range(0.0, 1.0, 0.05) var distorsion_afin := 0.0

## Perfil de época que se está mostrando.
var epoca_actual: PerfilEpoca
## false desactiva vibración, trama y grano (solo para comparar; tecla F4).
var efectos_ps1 := true

var _pila_camaras: Array[Camera3D] = []
var _mezcla_origen := Transform3D.IDENTITY
var _mezcla_fov := 60.0
var _mezcla_t := 1.0
var _mezcla_duracion := 0.0
var _ultimo_entorno: Environment
var _tweens := {}

## Imagen interna del juego (480 x 270).
@onready var vista: SubViewport = $VistaJuego
## Cámara real. No moverla a mano: copia a la cámara virtual activa.
@onready var camara: Camera3D = $VistaJuego/Camara
@onready var _pantalla: TextureRect = $CapaJuego/Pantalla
@onready var _filtro: ColorRect = $VistaJuego/PostFX/Filtro


func _ready() -> void:
	# La ventana principal no dibuja 3D: solo muestra la imagen interna y la interfaz.
	var raiz := get_tree().root
	raiz.disable_3d = true
	raiz.audio_listener_enable_3d = false

	vista.size = RESOLUCION_INTERNA
	_pantalla.texture = vista.get_texture()
	RenderingServer.global_shader_parameter_set(&"ps1_resolucion", Vector2(RESOLUCION_INTERNA))
	_aplicar_globales()

	if epoca_presente:
		aplicar_epoca(epoca_presente, 0.0)
	Settings.cambiado.connect(_al_cambiar_ajuste)
	_aplicar_calidad()


func _process(delta: float) -> void:
	_sincronizar_camara(delta)
	_vigilar_entorno()


# ---------------------------------------------------------------- Cámaras ---

## Convierte [param cam] en la cámara activa. Con [param duracion] > 0 la vista
## se desplaza suavemente desde la cámara anterior.
func activar_camara(cam: Camera3D, duracion := 0.0) -> void:
	if cam == null or cam == camara:
		return
	_pila_camaras.erase(cam)
	_pila_camaras.append(cam)
	_iniciar_mezcla(duracion)


## Retira [param cam]. Si era la activa, se vuelve a la anterior.
func desactivar_camara(cam: Camera3D, duracion := 0.0) -> void:
	var era_activa := obtener_camara_activa() == cam
	_pila_camaras.erase(cam)
	if era_activa:
		_iniciar_mezcla(duracion)


## Devuelve la cámara virtual que se está mostrando (puede ser null).
func obtener_camara_activa() -> Camera3D:
	for i in range(_pila_camaras.size() - 1, -1, -1):
		var cam := _pila_camaras[i]
		if is_instance_valid(cam) and cam.is_inside_tree():
			return cam
		_pila_camaras.remove_at(i)
	return null


func _iniciar_mezcla(duracion: float) -> void:
	_mezcla_origen = camara.global_transform
	_mezcla_fov = camara.fov
	_mezcla_duracion = duracion
	_mezcla_t = 0.0 if duracion > 0.0 else 1.0


func _sincronizar_camara(delta: float) -> void:
	var origen := obtener_camara_activa()
	if origen == null:
		origen = get_tree().root.get_camera_3d()
	if origen == null or origen == camara:
		return
	var destino := origen.get_global_transform_interpolated()
	var fov := origen.fov
	if _mezcla_t < 1.0:
		_mezcla_t = minf(_mezcla_t + delta / maxf(_mezcla_duracion, 0.001), 1.0)
		var k := smoothstep(0.0, 1.0, _mezcla_t)
		destino = _mezcla_origen.interpolate_with(destino, k)
		fov = lerpf(_mezcla_fov, fov, k)
	camara.global_transform = destino
	camara.fov = fov
	camara.near = origen.near
	camara.far = origen.far
	camara.environment = origen.environment
	camara.attributes = origen.attributes
	# La capa 11 («solo_espejo») nunca se ve directamente: solo en los espejos.
	camara.cull_mask = origen.cull_mask & ~(1 << 10)


# ----------------------------------------------------------------- Épocas ---

## Cambia el aspecto visual al de [param perfil] en [param duracion] segundos.
func aplicar_epoca(perfil: PerfilEpoca, duracion := 0.0) -> void:
	if perfil == null:
		return
	epoca_actual = perfil
	var destino := perfil.a_parametros()
	if not efectos_ps1:
		destino[&"niveles_color"] = 255.0
		destino[&"fuerza_dither"] = 0.0
		destino[&"grano"] = 0.0
	for nombre: StringName in destino:
		_animar_parametro(nombre, destino[nombre], duracion)
	epoca_cambiada.emit(perfil)


## Bandas negras de cine. 0 = sin bandas, 1 = formato 2.39:1.
func establecer_barras(valor: float, duracion := 0.6) -> void:
	_animar_parametro(&"barras", valor, duracion)


## Fundido a negro. 0 = imagen normal, 1 = negro.
func fundir(valor: float, duracion := 0.5) -> void:
	_animar_parametro(&"fundido", valor, duracion)


## Activa o desactiva los efectos PS1 para comparar (tecla F4 en pruebas).
func alternar_efectos_ps1() -> void:
	efectos_ps1 = not efectos_ps1
	_aplicar_globales()
	aplicar_epoca(epoca_actual, 0.0)


func _animar_parametro(nombre: StringName, valor: Variant, duracion: float) -> void:
	var material := _filtro.material as ShaderMaterial
	if _tweens.has(nombre) and is_instance_valid(_tweens[nombre]):
		(_tweens[nombre] as Tween).kill()
	if duracion <= 0.0:
		material.set_shader_parameter(nombre, valor)
		return
	var inicio: Variant = material.get_shader_parameter(nombre)
	if inicio == null:
		inicio = valor
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(
			func(v: Variant) -> void: material.set_shader_parameter(nombre, v),
			inicio, valor, duracion)
	_tweens[nombre] = tween


func _aplicar_globales() -> void:
	var vibracion := vibracion_vertices if efectos_ps1 else 0.0
	RenderingServer.global_shader_parameter_set(&"ps1_vibracion", vibracion)
	RenderingServer.global_shader_parameter_set(&"ps1_afin", distorsion_afin)


# ---------------------------------------------------------------- Calidad ---

func _al_cambiar_ajuste(nombre: StringName) -> void:
	if nombre == &"calidad":
		_aplicar_calidad()


func _aplicar_calidad() -> void:
	var alto := Settings.calidad == Settings.Calidad.ALTO
	vista.positional_shadow_atlas_size = 2048 if alto else 1024
	_ajustar_entorno()


## Detecta cuándo cambia el entorno (al cargar otro nivel) para ajustarlo.
func _vigilar_entorno() -> void:
	var mundo := vista.find_world_3d()
	var entorno: Environment = mundo.environment if mundo else null
	if entorno != _ultimo_entorno:
		_ultimo_entorno = entorno
		_ajustar_entorno()


## Enciende o apaga los efectos caros del entorno según la calidad gráfica.
## En el Environment de cada nivel solo se ajustan sus valores (intensidad del
## brillo, densidad de la niebla); el interruptor lo lleva este nodo:
##  - Brillo: solo en calidad ALTA.
##  - Niebla volumétrica: solo en calidad ALTA, con el renderizador Forward+ y
##    si el nivel le ha dado una densidad mayor que 0.
func _ajustar_entorno() -> void:
	var entorno := _ultimo_entorno
	if entorno == null:
		return
	var alto := Settings.calidad == Settings.Calidad.ALTO
	var forward_plus := RenderingServer.get_current_rendering_method() == "forward_plus"
	entorno.glow_enabled = alto
	entorno.volumetric_fog_enabled = (
			alto and forward_plus and entorno.volumetric_fog_density > 0.0)
	# Luces grandes (luna, sol) que solo proyectan sombras en calidad ALTA.
	for luz in get_tree().get_nodes_in_group(&"sombra_alta"):
		(luz as Light3D).shadow_enabled = alto
