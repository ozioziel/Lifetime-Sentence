class_name Jugador
extends CharacterBody3D
## Elías, el protagonista. Camina, corre y se agacha; no salta (P4).
##
## El movimiento es relativo a la cámara: «adelante» es hacia donde mira.
## Las velocidades salen de un PerfilMovimiento distinto para cada época (D2):
##   PRESENTE: lento, carrera corta y ruidosa (se agota), puede agacharse, esconderse,
##             usar armas y lanzar objetos.
##   PASADO:   ágil, sin armas (§7.1); puede pasar por encima de obstáculos y derribarlos (K1, S1).
## También hace ruido al moverse (los enemigos lo oyen, K5/S5), interactúa con los
## objetos cercanos (indicador punto + botón, S4) y reproduce sus animaciones.

signal agachado_cambiado(agachado: bool)
signal murio

@export var movimiento_presente: PerfilMovimiento
@export var movimiento_pasado: PerfilMovimiento
@export var camara: CamaraJugador
## Hacia dónde miran el personaje y la cámara al empezar, en grados (0 = hacia -Z).
@export_range(-180.0, 180.0) var orientacion_inicial := 0.0

@export_group("Ruido (metros a los que se oye)")
@export var ruido_andar := 3.5
@export var ruido_correr := 10.0
@export var ruido_agachado := 0.8

@export_group("Carrera en el presente")
## Segundos que se puede correr en el presente antes de agotarse (D2: carrera corta).
@export var aguante_maximo := 4.5
@export var recuperacion_aguante := 0.8

## Perfil de movimiento en uso.
var perfil: PerfilMovimiento
var agachado := false
## false bloquea el control (cinemáticas, menús). La gravedad sigue actuando.
var control_activo := true
## true mientras está dentro de un escondite.
var oculto := false
## true mientras hace una acción (recoger, abrir, pasar por encima...).
var ocupado := false
var muerto := false
var en_pasado := false
var apuntando := false
## Objeto arrojadizo que lleva en la mano (K5). Vacío = nada.
var lanzable: StringName = &""
## Superficie de los pasos: hormigon, metal, charco, baldosa.
var superficie := &"hormigon"
## Ignora agarres durante unos segundos tras librarse con el punzón.
var invulnerable := 0.0

var _quiere_agacharse := false
var _agachado_forzado := false
var _gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _aguante := 4.5
var _agotado := false
var _t_ruido := 0.0
var _t_paso := 0.0
var _candidato: Interactuable = null
var _velocidad_horizontal := 0.0
var _modelo: ModeloPersonaje
var _t_disparo := 0.0
var _escondite: Node = null
var _anim_forzada: StringName = &""

@onready var _colision_de_pie: CollisionShape3D = $ColisionDePie
@onready var _colision_agachado: CollisionShape3D = $ColisionAgachado
@onready var _detector_techo: ShapeCast3D = $DetectorTecho
@onready var _modelo_preso: ModeloPersonaje = $Modelo
@onready var _modelo_civil: ModeloPersonaje = $ModeloCivil
@onready var _fogonazo: OmniLight3D = $Fogonazo


func _ready() -> void:
	add_to_group(&"jugador")
	perfil = movimiento_presente
	_modelo = _modelo_preso
	_modelo_civil.visible = false
	_aguante = aguante_maximo
	var angulo := deg_to_rad(orientacion_inicial)
	_modelo_preso.rotation.y = angulo
	_modelo_civil.rotation.y = angulo
	if camara:
		camara.fijar_orientacion(angulo)
		camara.saltar_al_objetivo()


func modelo() -> ModeloPersonaje:
	return _modelo


func _physics_process(delta: float) -> void:
	invulnerable = maxf(invulnerable - delta, 0.0)
	_t_disparo = maxf(_t_disparo - delta, 0.0)
	if muerto:
		velocity = Vector3(0.0, velocity.y - _gravedad * delta if not is_on_floor() else -0.5, 0.0)
		move_and_slide()
		return
	var puede := control_activo and not ocupado and not oculto
	var entrada := Vector2.ZERO
	if puede:
		entrada = Input.get_vector(&"mover_izquierda", &"mover_derecha", &"mover_adelante", &"mover_atras")
	_actualizar_agachado(puede)
	_actualizar_apuntado(puede, delta)

	# Dirección de avance según hacia dónde mira la cámara.
	var orientacion := Basis(Vector3.UP, camara.yaw if camara else 0.0)
	var direccion := orientacion * Vector3(entrada.x, 0.0, entrada.y)
	var corriendo := false
	var velocidad_maxima := perfil.velocidad_andar
	if agachado:
		velocidad_maxima = perfil.velocidad_agachado
	elif puede and Input.is_action_pressed(&"correr") and entrada.length() > 0.3 and not _agotado:
		velocidad_maxima = perfil.velocidad_correr
		corriendo = true
	if apuntando:
		velocidad_maxima = 0.0
	_actualizar_aguante(corriendo, delta)

	var objetivo := direccion * velocidad_maxima
	var ritmo := perfil.aceleracion if entrada.length() > 0.05 else perfil.frenado
	if oculto or ocupado:
		objetivo = Vector3.ZERO
		ritmo = 30.0
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(objetivo, ritmo * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if is_on_floor():
		velocity.y = -0.5
	else:
		velocity.y -= _gravedad * delta
	if not oculto:
		move_and_slide()

	_velocidad_horizontal = Vector3(velocity.x, 0.0, velocity.z).length()
	if apuntando and camara:
		_modelo.rotation.y = lerp_angle(_modelo.rotation.y, camara.yaw, 1.0 - exp(-18.0 * delta))
	elif _velocidad_horizontal > 0.2 and not ocupado:
		var angulo := atan2(-horizontal.x, -horizontal.z)
		var peso := 1.0 - exp(-perfil.velocidad_giro * delta)
		_modelo.rotation.y = lerp_angle(_modelo.rotation.y, angulo, peso)
	_animar(corriendo)
	_hacer_ruido(corriendo, delta)
	_buscar_interactuable(puede)
	if puede:
		_leer_acciones()


# -------------------------------------------------------------- Animaciones ---

func _animar(corriendo: bool) -> void:
	if ocupado or muerto or _anim_forzada != &"":
		if _anim_forzada != &"" and not ocupado:
			_modelo.reproducir(_anim_forzada, 0.25)
		return
	if oculto:
		return
	var civil := _modelo == _modelo_civil
	var v := _velocidad_horizontal
	if apuntando:
		var arma: StringName = Juego.arma_activa()
		_modelo.reproducir(&"escopeta_apuntar" if arma == &"escopeta" else &"pistola_apuntar", 0.15)
		return
	if agachado:
		if v < 0.12:
			_modelo.reproducir(&"agachado", 0.25)
		else:
			_modelo.reproducir(&"agachado_andar", 0.2, v / 0.95)
		return
	var v_andar := 2.3 if civil else 1.55
	var v_correr := 5.4 if civil else 3.5
	if v < 0.15:
		if _recuento_cerca():
			_modelo.reproducir(&"congelarse", 0.3)
		else:
			_modelo.reproducir(&"quieto", 0.3)
	elif corriendo or v > (v_andar + v_correr) * 0.5:
		var nombre := &"correr"
		if civil and _perseguidor_cerca():
			nombre = &"correr_mirando_atras"
		_modelo.reproducir(nombre, 0.2, clampf(v / v_correr, 0.6, 1.4))
	else:
		_modelo.reproducir(&"andar", 0.2, clampf(v / v_andar, 0.5, 1.5))


## Reproduce una acción de una vez (recoger, palanca...). El jugador no se mueve mientras.
func accion(nombre: StringName, velocidad := 1.0) -> void:
	ocupado = true
	velocity = Vector3.ZERO
	await _modelo.reproducir_una_vez(nombre, 0.15, velocidad)
	ocupado = false


## Mantiene una animación en bucle (ganzúa, volante...) hasta llamar con vacío.
func forzar_animacion(nombre: StringName) -> void:
	_anim_forzada = nombre
	if nombre != &"":
		_modelo.reproducir(nombre, 0.2)


func _recuento_cerca() -> bool:
	for e in get_tree().get_nodes_in_group(&"recuento_activo"):
		if (e as Node3D).global_position.distance_to(global_position) < 14.0:
			return true
	return false


func _perseguidor_cerca() -> bool:
	for e in get_tree().get_nodes_in_group(&"perseguidor"):
		if (e as Node3D).global_position.distance_to(global_position) < 9.0:
			return true
	return false


# -------------------------------------------------------------------- Ruido ---

func _hacer_ruido(corriendo: bool, delta: float) -> void:
	var v := _velocidad_horizontal
	if v < 0.2 or oculto:
		_t_paso = 0.0
		return
	# Pasos: cada zancada suena y hace ruido.
	var zancada := 0.75 if not corriendo else 1.15
	if agachado:
		zancada = 0.6
	_t_paso += v * delta
	if _t_paso >= zancada:
		_t_paso = 0.0
		var volumen := -14.0 if agachado else (-4.0 if corriendo else -9.0)
		Audio.efecto_3d(StringName("paso_" + String(superficie)), global_position, volumen, 18.0,
				randf_range(0.9, 1.1))
		var radio := ruido_agachado if agachado else (ruido_correr if corriendo else ruido_andar)
		if not en_pasado:
			Juego.emitir_ruido(global_position, radio, self)


func _actualizar_aguante(corriendo: bool, delta: float) -> void:
	if en_pasado:
		_aguante = aguante_maximo
		_agotado = false
		return
	if corriendo:
		_aguante -= delta
		if _aguante <= 0.0:
			_agotado = true
			Audio.efecto(&"jadeo", -4.0)
	else:
		_aguante = minf(_aguante + delta * recuperacion_aguante, aguante_maximo)
		if _agotado and _aguante > aguante_maximo * 0.6:
			_agotado = false


# -------------------------------------------------------------- Interacción ---

func _buscar_interactuable(puede: bool) -> void:
	var mejor: Interactuable = null
	if puede and not apuntando:
		var mejor_puntos := INF
		var frente := -_modelo.global_basis.z
		var cam_frente := -camara.global_basis.z if camara else frente
		for nodo in get_tree().get_nodes_in_group(&"interactuable"):
			var it := nodo as Interactuable
			if it == null or not it.disponible(self):
				continue
			var hacia := it.punto_global() - global_position
			if absf(hacia.y) > it.alto:
				continue
			hacia.y = 0.0
			var d := hacia.length()
			if d > it.radio:
				continue
			var dir := hacia / maxf(d, 0.001)
			var alineado := maxf(dir.dot(Vector3(frente.x, 0, frente.z).normalized()),
					dir.dot(Vector3(cam_frente.x, 0, cam_frente.z).normalized()))
			if d > 0.6 and alineado < 0.2:
				continue
			var puntos := d - alineado * 0.6
			if puntos < mejor_puntos:
				mejor_puntos = puntos
				mejor = it
	if mejor != _candidato:
		_candidato = mejor
		if mejor:
			Interfaz.mostrar_aviso(mejor.texto_aviso(self))
		else:
			Interfaz.ocultar_aviso()


func _leer_acciones() -> void:
	if Input.is_action_just_pressed(&"interactuar") and _candidato and not apuntando:
		var it := _candidato
		_candidato = null
		Interfaz.ocultar_aviso()
		it.usar(self)
		return
	if Input.is_action_just_pressed(&"lanzar") and lanzable != &"" and not en_pasado:
		_lanzar()


## Gira el cuerpo hacia un punto (al interactuar, en cinemáticas).
func mirar_a(punto: Vector3, instantaneo := false) -> void:
	var hacia := punto - global_position
	hacia.y = 0.0
	if hacia.length() < 0.01:
		return
	var angulo := atan2(-hacia.x, -hacia.z)
	if instantaneo:
		_modelo.rotation.y = angulo
	else:
		var tw := create_tween()
		tw.tween_method(func(a: float) -> void: _modelo.rotation.y = lerp_angle(_modelo.rotation.y, a, 0.35),
				angulo, angulo, 0.25)


# ------------------------------------------------------------------ Lanzar ---

func coger_lanzable(tipo: StringName) -> void:
	lanzable = tipo
	Interfaz.mensaje("Llevas %s. %s para lanzarla y hacer ruido lejos de ti." % [
			"una botella" if tipo == &"botella" else "una lata", Interfaz.glifo(&"lanzar")], 4.0)


func _lanzar() -> void:
	var tipo := lanzable
	lanzable = &""
	ocupado = true
	if camara:
		_modelo.rotation.y = camara.yaw
	_modelo.reproducir(&"lanzar", 0.1)
	await get_tree().create_timer(0.45, false).timeout
	var proyectil := Proyectil.new()
	proyectil.tipo = tipo
	get_tree().current_scene.add_child(proyectil)
	var origen := global_position + Vector3.UP * 1.5 - _modelo.global_basis.z * 0.4
	var direccion := -camara.camara.global_basis.z if camara else -_modelo.global_basis.z
	proyectil.lanzar(origen, (direccion + Vector3.UP * 0.35).normalized() * 11.0)
	await get_tree().create_timer(maxf(_modelo.duracion(&"lanzar") - 0.45, 0.1), false).timeout
	ocupado = false


# -------------------------------------------------------------------- Armas ---

func _actualizar_apuntado(puede: bool, _delta: float) -> void:
	var quiere: bool = puede and not en_pasado and Juego.tiene_arma() and Input.is_action_pressed(&"apuntar")
	if quiere != apuntando:
		apuntando = quiere
		if camara:
			camara.apuntando = apuntando
		Interfaz.mostrar_municion(apuntando, Juego.texto_municion())
		Interfaz.mostrar_mira(apuntando)
		if apuntando and agachado:
			_poner_agachado(false)
	if not apuntando:
		return
	Interfaz.mostrar_municion(true, Juego.texto_municion())
	if Input.is_action_just_pressed(&"recargar"):
		Juego.recargar()
	if Input.is_action_just_pressed(&"disparar") and _t_disparo <= 0.0:
		_disparar()


func _disparar() -> void:
	var arma: StringName = Juego.arma_activa()
	if Juego.recargando():
		return
	if not Juego.disparar_bala():
		Audio.efecto(&"arma_vacia", -4.0)
		_t_disparo = 0.3
		if not await Juego.recargar():
			Interfaz.mensaje("Sin munición.")
		return
	_t_disparo = 0.55 if arma == &"pistola" else 1.0
	_modelo.reproducir_una_vez(&"escopeta_disparar" if arma == &"escopeta" else &"pistola_disparar", 0.05)
	Audio.efecto(StringName("disparo_%s" % arma), 2.0, randf_range(0.95, 1.05))
	Interfaz.vibrar(0.9, 1.0, 0.18)
	if camara:
		camara.sacudir(0.35 if arma == &"escopeta" else 0.18)
	_fogonazo.light_energy = 6.0
	var tw := create_tween()
	tw.tween_property(_fogonazo, "light_energy", 0.0, 0.08)
	Juego.emitir_ruido(global_position, Juego.ARMAS[arma]["ruido"], self)
	# Disparo: rayo desde el centro de la cámara (sin mira automática).
	var cam := camara.camara if camara else null
	if cam == null:
		return
	var origen := cam.global_position
	var fin := origen - cam.global_basis.z * 45.0
	var rayo := PhysicsRayQueryParameters3D.create(origen, fin, 1 | 4)
	rayo.exclude = [get_rid()]
	rayo.collide_with_areas = false
	var golpe := get_world_3d().direct_space_state.intersect_ray(rayo)
	if golpe.is_empty():
		return
	var cuerpo: Object = golpe["collider"]
	var objetivo := cuerpo as Node
	while objetivo and not objetivo.has_method(&"recibir_disparo"):
		objetivo = objetivo.get_parent()
	if objetivo:
		objetivo.recibir_disparo(arma, golpe["position"])
	else:
		Audio.efecto_3d(&"impacto_bala", golpe["position"], -2.0, 25.0)
	Particulas.chispa(get_tree().current_scene, golpe["position"], golpe["normal"])


# ------------------------------------------------------- Agarres y muerte ---

## Un enemigo lo ha atrapado. Si tiene el punzón se libra (§7.1); si no, muere.
## Devuelve true si se ha librado.
func intentar_defensa(atacante: Node3D, rompe_punzon := false) -> bool:
	if muerto or invulnerable > 0.0:
		return invulnerable > 0.0
	if Juego.usos_punzon() <= 0 or en_pasado:
		return false
	Juego.gastar_punzon(rompe_punzon)
	ocupado = true
	mirar_a(atacante.global_position, true)
	Audio.efecto(&"punzon", 0.0)
	if camara:
		camara.sacudir(0.4)
	await _modelo.reproducir_una_vez(&"punzon_clavar", 0.05)
	ocupado = false
	invulnerable = 2.5
	if rompe_punzon:
		Interfaz.mensaje("El punzón se ha roto.")
	else:
		Interfaz.mensaje("Punzón: quedan %d usos." % Juego.usos_punzon())
	return true


## Muere con la animación indicada (muerte_cuello, muerte_placaje, muerte_arrastrado,
## muerte_golpe). [param impacto] = fracción de la animación en la que se corta a negro (K3).
func morir(animacion: StringName, atacante: Node3D = null, impacto := 0.8) -> void:
	if muerto:
		return
	muerto = true
	control_activo = false
	apuntando = false
	if camara:
		camara.apuntando = false
	Interfaz.mostrar_municion(false)
	Interfaz.mostrar_mira(false)
	Interfaz.ocultar_aviso()
	if oculto:
		salir_de_escondite(true)
	if atacante:
		mirar_a(atacante.global_position, true)
	if camara:
		camara.sacudir(0.5)
	murio.emit()
	var duracion := _modelo.duracion(animacion)
	_modelo.reproducir(animacion, 0.05)
	await get_tree().create_timer(maxf(duracion * impacto, 0.5), false).timeout
	Juego.morir()


# ---------------------------------------------------------------- Escondites ---

## Entra en un escondite: se coloca en [param punto], adopta [param animacion] y
## (si lo hay) pasa a la cámara del escondite.
func entrar_en_escondite(escondite: Node, punto: Node3D, animacion: StringName, cam: Camera3D) -> void:
	ocupado = true
	_escondite = escondite
	get_tree().call_group(&"enemigo", &"ver_esconderse", escondite)
	await _modelo.reproducir_una_vez(&"esconderse", 0.1)
	global_position = punto.global_position
	_modelo.rotation.y = punto.global_rotation.y
	reset_physics_interpolation()
	oculto = true
	ocupado = false
	_colision_de_pie.disabled = true
	_colision_agachado.disabled = true
	_modelo.reproducir(animacion, 0.2)
	if cam:
		RenderRig.activar_camara(cam, 0.35)
	Audio.efecto(&"esconderse", -6.0)


func salir_de_escondite(inmediato := false) -> void:
	if not oculto:
		return
	var escondite := _escondite
	_escondite = null
	oculto = false
	_colision_de_pie.disabled = agachado
	_colision_agachado.disabled = not agachado
	if escondite and escondite.has_method(&"punto_salida"):
		var salida: Node3D = escondite.punto_salida()
		global_position = salida.global_position
		reset_physics_interpolation()
	if escondite and escondite.has_method(&"camara_escondite"):
		var cam: Camera3D = escondite.camara_escondite()
		if cam:
			RenderRig.desactivar_camara(cam, 0.0 if inmediato else 0.35)
	if camara:
		RenderRig.activar_camara(camara.camara, 0.0 if inmediato else 0.35)


# ---------------------------------------------------------------- Utilidades ---

## Cambia entre el movimiento del PRESENTE y el del PASADO.
func usar_epoca_pasado(pasado: bool) -> void:
	en_pasado = pasado
	perfil = movimiento_pasado if pasado else movimiento_presente
	if not perfil.puede_agacharse:
		_quiere_agacharse = false
		if agachado:
			_poner_agachado(false)


## Ropa de Elías: false = uniforme de preso (4827), true = ropa de calle (F1, F2).
func fijar_vestuario(civil: bool) -> void:
	var nuevo := _modelo_civil if civil else _modelo_preso
	if nuevo == _modelo:
		return
	nuevo.rotation.y = _modelo.rotation.y
	_modelo.visible = false
	_modelo = nuevo
	_modelo.visible = true


## Mueve al jugador a un punto sin recorrer el camino (cinemáticas, inicio de nivel).
func teletransportar(posicion: Vector3, angulo_modelo := 0.0) -> void:
	global_position = posicion
	velocity = Vector3.ZERO
	_modelo.rotation.y = angulo_modelo
	reset_physics_interpolation()
	if camara:
		camara.fijar_orientacion(angulo_modelo)
		camara.saltar_al_objetivo()


## Bloquea o devuelve el control (cinemáticas). La cámara deja de girar con el ratón.
func bloquear(valor: bool) -> void:
	control_activo = not valor
	if valor:
		apuntando = false
		if camara:
			camara.apuntando = false
		Interfaz.ocultar_aviso()
		Interfaz.mostrar_municion(false)
		Interfaz.mostrar_mira(false)
		_candidato = null


## Anda (guionizado) hasta un punto. Para cinemáticas cortas.
func andar_hasta(destino: Vector3, velocidad := 1.4, animacion := &"andar") -> void:
	ocupado = true
	var desde := global_position
	var plano := Vector3(destino.x, desde.y, destino.z)
	var distancia := desde.distance_to(plano)
	mirar_a(destino, true)
	var ritmo := velocidad / (2.3 if _modelo == _modelo_civil else 1.55)
	if animacion == &"correr":
		ritmo = velocidad / (5.4 if _modelo == _modelo_civil else 3.5)
	_modelo.reproducir(animacion, 0.2, ritmo)
	var tw := create_tween()
	tw.tween_property(self, "global_position", plano, distancia / maxf(velocidad, 0.1))
	await tw.finished
	_modelo.reproducir(&"quieto", 0.3)
	ocupado = false


## Desplazamiento guionizado mientras suena una animación (pasar por encima).
func desplazar_con_animacion(animacion: StringName, desplazamiento: Vector3, duracion: float) -> void:
	ocupado = true
	_colision_de_pie.disabled = true
	var tw := create_tween()
	tw.tween_property(self, "global_position", global_position + desplazamiento, duracion)
	await _modelo.reproducir_una_vez(animacion, 0.05)
	_colision_de_pie.disabled = agachado
	ocupado = false


## Hace que el modelo se deshaga en puntos (0 = visible, 1 = invisible).
func fijar_disolucion_modelo(valor: float) -> void:
	_modelo.fijar_disolucion(valor)


## Obliga al jugador a permanecer agachado (pasos bajos guionizados, pruebas).
func forzar_agachado(valor: bool) -> void:
	_agachado_forzado = valor


func _actualizar_agachado(puede: bool) -> void:
	if not perfil.puede_agacharse:
		_quiere_agacharse = false
	elif puede and not apuntando:
		if Settings.agacharse_alternar:
			if Input.is_action_just_pressed(&"agacharse"):
				_quiere_agacharse = not _quiere_agacharse
		else:
			_quiere_agacharse = Input.is_action_pressed(&"agacharse")
	var deseo := _quiere_agacharse or _agachado_forzado
	if deseo and not agachado:
		_poner_agachado(true)
	elif not deseo and agachado and _hay_sitio_para_levantarse():
		_poner_agachado(false)


func _poner_agachado(valor: bool) -> void:
	agachado = valor
	if not valor:
		_quiere_agacharse = false
	if not oculto:
		_colision_de_pie.disabled = valor
		_colision_agachado.disabled = not valor
	agachado_cambiado.emit(valor)


## Comprueba que no haya techo bajo antes de ponerse de pie.
func _hay_sitio_para_levantarse() -> bool:
	_detector_techo.force_shapecast_update()
	return not _detector_techo.is_colliding()


## Visible para los enemigos: no está escondido ni muerto. Agachado en sombra cuenta menos.
func es_visible() -> bool:
	return not oculto and not muerto


## Altura de los ojos (para los conos de visión de los enemigos).
func punto_visible() -> Vector3:
	return global_position + Vector3.UP * (0.9 if agachado else 1.5)
