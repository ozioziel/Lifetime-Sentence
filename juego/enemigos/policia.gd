class_name Policia
extends Enemigo
## Policías y guardias del PASADO (E1): persecución «de goma elástica».
##   PATRULLERO: corre detrás de Elías; si se aleja, acelera; si está cerca, afloja un poco
##               (siempre se puede escapar corriendo bien). Al verlo por primera vez toca el
##               silbato y pide refuerzos. Lo derriba con un placaje.
##   TACTICO:    corta una calle: quieto, vigila y, si te ve, avisa (silbato).
##   GUARDIA:    guardia de la prisión en el pasado (F3). Si te ve fuera de la fila, te persigue.
## Los obstáculos saltados o derribados (K1/S1) los frenan un momento.

enum Tipo { PATRULLERO, TACTICO, GUARDIA }

@export var tipo: Tipo = Tipo.PATRULLERO
## Silba al ver a Elías por primera vez (refuerzos).
@export var silba := true
## Lleva una linterna encendida (en la lluvia del pasado se ven los haces).
@export var linterna := true

var _silbo := false
var _frenado := 0.0
var _obstaculos_pasados: Array[Node] = []
var _linterna: SpotLight3D


func _ready() -> void:
	match tipo:
		Tipo.PATRULLERO:
			if personaje == "el_uniforme":
				personaje = "policia_patrullero"
			anim_correr = &"correr"
			ritmo_andar = 1.5
			ritmo_correr = 4.8
			velocidad_andar = 1.5
			velocidad_correr = 5.0
			anim_ataque = &"placaje"
			anim_muerte_jugador = &"muerte_placaje"
			distancia_pareja = 1.3
			distancia_ataque = 1.45
		Tipo.TACTICO:
			personaje = "policia_tactico"
			ritmo_andar = 1.2
			velocidad_andar = 1.2
			velocidad_correr = 1.2
			anim_correr = &"andar"
			estado_inicial = Estado.QUIETO
		Tipo.GUARDIA:
			personaje = "guardia_penitenciario"
			anim_correr = &"correr"
			ritmo_andar = 1.4
			ritmo_correr = 4.2
			velocidad_andar = 1.4
			velocidad_correr = 4.6
			anim_ataque = &"quieto"
			anim_muerte_jugador = &"muerte_placaje"
			distancia_pareja = 1.0
			distancia_ataque = 1.2
	luces_al_detectar = false
	impacto = 0.85
	super()
	if tipo != Tipo.TACTICO:
		add_to_group(&"perseguidor")
	if linterna:
		_linterna = SpotLight3D.new()
		_linterna.light_color = Color(1.0, 0.95, 0.82)
		_linterna.light_energy = 4.0
		_linterna.spot_range = 16.0
		_linterna.spot_angle = 17.0
		_linterna.shadow_enabled = false
		_linterna.light_volumetric_fog_energy = 4.0
		_linterna.top_level = true
		add_child(_linterna)


func _physics_process(delta: float) -> void:
	_frenado = maxf(_frenado - delta, 0.0)
	if estado == Estado.PERSEGUIR:
		_comprobar_obstaculos()
	super(delta)
	if _linterna:
		_linterna.visible = visible
		var origen := modelo.posicion_hueso(&"mano.R") + Vector3.UP * 0.05
		var mirar := origen + adelante() * 6.0 + Vector3.DOWN * 1.2
		if jugador and estado == Estado.PERSEGUIR:
			mirar = jugador.global_position + Vector3.UP * 1.2
		_linterna.global_position = origen
		if origen.distance_to(mirar) > 0.1:
			_linterna.look_at(mirar, Vector3.UP)


func velocidad_persecucion() -> float:
	if _frenado > 0.0:
		return 0.6
	if tipo == Tipo.TACTICO:
		return 0.0
	if jugador == null:
		return velocidad_correr
	# Goma elástica: lejos acelera, cerca afloja (Elías corre a 5,4 m/s).
	var d := global_position.distance_to(jugador.global_position)
	if d > 14.0:
		return velocidad_correr * 1.2
	if d > 7.0:
		return velocidad_correr * 1.04
	return velocidad_correr * 0.93


func _estado_perseguir(delta: float) -> void:
	if tipo == Tipo.TACTICO:
		_parar()
		if jugador:
			girar_hacia(jugador.global_position, delta)
		if not puede_ver_jugador() and _t_estado > 3.0:
			cambiar_estado(Estado.QUIETO)
		return
	super(delta)


func _al_detectar() -> void:
	super()
	if silba and not _silbo:
		_silbo = true
		_silbar()


func _silbar() -> void:
	Audio.efecto_3d(&"silbato", global_position, 4.0, 60.0)
	if tipo != Tipo.GUARDIA:
		Interfaz.subtitulo(Guion.F1_SILBATO[1], Guion.F1_SILBATO[2], Guion.F1_SILBATO[0])
	if Juego.nivel and Juego.nivel.has_method(&"refuerzos"):
		Juego.nivel.refuerzos(global_position)
	if tipo == Tipo.PATRULLERO and modelo.tiene(&"silbato"):
		var antes := estado
		cambiar_estado(Estado.GUION)
		modelo.reproducir(&"silbato", 0.1)
		await get_tree().create_timer(0.9, false).timeout
		if estado == Estado.GUION:
			cambiar_estado(antes)


## Los obstáculos frenan al perseguidor un instante (al pasar por encima o al chocar
## con algo derribado).
func _comprobar_obstaculos() -> void:
	for o in get_tree().get_nodes_in_group(&"obstaculo_saltable") + get_tree().get_nodes_in_group(&"obstaculo_derribado"):
		if _obstaculos_pasados.has(o):
			continue
		var n := o as Node3D
		if n.global_position.distance_to(global_position) < 1.3:
			_obstaculos_pasados.append(o)
			_frenado = 1.4 if o.is_in_group(&"obstaculo_derribado") else 0.8
			if o.is_in_group(&"obstaculo_derribado"):
				Audio.efecto_3d(&"tropiezo", global_position, 0.0, 20.0)


func recibir_disparo(_arma: StringName, _punto: Vector3) -> void:
	pass
