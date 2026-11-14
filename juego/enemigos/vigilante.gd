class_name ElVigilante
extends Enemigo
## EL VIGILANTE (K7): recorre las pasarelas despacio con un foco en la cabeza que barre
## de lado a lado. Si el jugador queda dentro del haz más de un instante, da la ALARMA:
## luces rojas, megafonía y los demás enemigos acuden. No ataca: vigila.
## La pistola lo aturde (el foco se apaga 3 s).

## Segundos dentro del haz antes de dar la alarma.
@export var tolerancia := 1.0
@export var alcance_foco := 22.0
@export var apertura_foco := 16.0
## Barrido del foco a izquierda y derecha (grados) y su ritmo.
@export var barrido := 38.0
@export var ritmo_barrido := 0.32
## Inclinación extra del foco hacia abajo (grados).
@export var inclinacion := 18.0
## Punto del mundo hacia el que apunta el centro del barrido (INF = hacia donde mira).
@export var punto_mirada := Vector3.INF

var foco: SpotLight3D
var exposicion := 0.0
var _fase := 0.0
var _alarma_dada := false
var _zumbido: AudioStreamPlayer3D


func _init() -> void:
	personaje = "el_vigilante"
	anim_quieto = &"quieto"
	anim_andar = &"andar"
	anim_correr = &"andar"
	ritmo_andar = 0.9
	ritmo_correr = 0.9
	velocidad_andar = 0.9
	velocidad_correr = 0.9
	vision_distancia = 0.0
	oido = 0.6
	espera_en_punto = 3.0
	luces_al_detectar = false


func _ready() -> void:
	super()
	add_to_group(&"vigilante")
	foco = SpotLight3D.new()
	foco.name = "Foco"
	foco.light_color = Color(0.92, 0.95, 1.0)
	foco.light_energy = 9.0
	foco.spot_range = alcance_foco
	foco.spot_angle = apertura_foco
	foco.spot_attenuation = 0.6
	foco.shadow_enabled = true
	foco.light_volumetric_fog_energy = 3.0
	var cabeza := modelo.punto_hueso(&"cabeza")
	if cabeza:
		var soporte := Node3D.new()
		soporte.name = "SoporteFoco"
		cabeza.add_child(soporte)
		soporte.add_child(foco)
	else:
		add_child(foco)
		foco.position.y = 2.0
	foco.top_level = true
	_zumbido = Audio.emisor(self, &"foco_zumbido", -6.0, 18.0)
	_zumbido.position.y = 2.0


func _physics_process(delta: float) -> void:
	super(delta)
	_mover_foco(delta)
	_medir_exposicion(delta)


func _mover_foco(delta: float) -> void:
	if foco == null:
		return
	_fase += delta * ritmo_barrido * TAU
	var origen := modelo.posicion_hueso(&"cabeza") + Vector3.UP * 0.12
	var giro := deg_to_rad(sin(_fase) * barrido)
	var base := adelante()
	var caida := tan(deg_to_rad(inclinacion))
	if punto_mirada != Vector3.INF:
		var hacia := punto_mirada - origen
		var plano := Vector3(hacia.x, 0.0, hacia.z)
		base = plano.normalized()
		caida += -hacia.y / maxf(plano.length(), 0.1)
		if Vector3(velocity.x, 0, velocity.z).length() < 0.1:
			girar_hacia(origen + base, delta)
	var dir := (base.rotated(Vector3.UP, giro) + Vector3.DOWN * caida).normalized()
	foco.global_position = origen + dir * 0.25
	foco.look_at(origen + dir * 10.0, Vector3.UP)
	foco.visible = estado != Estado.ATURDIDO


func _medir_exposicion(delta: float) -> void:
	if jugador == null or not foco.visible or estado in [Estado.ATURDIDO, Estado.INACTIVO, Estado.GUION]:
		exposicion = maxf(exposicion - delta, 0.0)
		return
	var dentro := false
	if jugador.es_visible():
		var objetivo := jugador.punto_visible() - Vector3.UP * 0.3
		var hacia := objetivo - foco.global_position
		if hacia.length() < alcance_foco and rad_to_deg((-foco.global_basis.z).angle_to(hacia)) < apertura_foco * 0.85:
			dentro = linea_de_vision(foco.global_position, objetivo)
	if dentro:
		exposicion += delta
		if exposicion > 0.15:
			Interfaz.vibrar(0.15, 0.0, 0.1)
		if exposicion >= tolerancia and not _alarma_dada:
			_dar_alarma()
	else:
		exposicion = maxf(exposicion - delta * 0.6, 0.0)


func _dar_alarma() -> void:
	_alarma_dada = true
	foco.light_color = Color(1.0, 0.15, 0.1)
	cambiar_estado(Estado.GUION)
	_parar()
	modelo.reproducir(&"alerta", 0.1)
	Audio.efecto_3d(&"vigilante_alerta", global_position + Vector3.UP * 2.0, 6.0, 80.0)
	Interfaz.subtitulo(Guion.MEGAFONIA_ALARMA[1], Guion.MEGAFONIA_ALARMA[2], Guion.MEGAFONIA_ALARMA[0])
	Juego.dar_alarma(jugador.global_position)
	await get_tree().create_timer(6.0, false).timeout
	foco.light_color = Color(0.92, 0.95, 1.0)
	exposicion = 0.0
	_alarma_dada = false
	if estado == Estado.GUION:
		cambiar_estado(Estado.PATRULLA)


func _al_alarma(_posicion: Vector3) -> void:
	pass


func oir(_posicion: Vector3, _radio: float, _origen: Node) -> void:
	pass


func recibir_disparo(_arma: StringName, punto: Vector3) -> void:
	Audio.efecto_3d(&"impacto_carne", punto, 0.0, 20.0)
	Particulas.chispa(get_tree().current_scene, punto)
	exposicion = 0.0
	aturdir(3.0)
