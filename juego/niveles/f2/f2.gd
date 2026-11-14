extends Nivel
## Recuerdo F2 «El interrogatorio» (PASADO).
## Cinemática: el interrogador no quiere el dinero, quiere la carpeta, y amenaza a la
## hermana. Se va «a por un café»: hay que forzar las esposas y la puerta antes de que
## vuelva (K6, cuenta atrás) y salir por la puerta trasera sin que te atrapen.
## Fracaso → escena de consecuencia → CONTINUAR desde el punto de control (G6).

const TIEMPO := 95.0

@onready var _interrogador: ModeloPersonaje = $Figuras/Interrogador
@onready var _puerta_sala: Interactuable = $Interactivos/PuertaSala

var _tiempo := TIEMPO
var _contando := false
var _fracaso := false


func _process(delta: float) -> void:
	super(delta)
	if not _contando or get_tree().paused:
		return
	_tiempo -= delta
	Interfaz.cuenta_atras(_tiempo)
	_puerta_sala.limite_tiempo = maxf(_tiempo, 0.5)
	if _tiempo <= 0.0:
		_vuelve_el_interrogador()


func al_entrar(punto: StringName) -> void:
	match punto:
		&"pasillo":
			_interrogador.visible = false
			(_puerta_sala as Puerta).abrir(true)
			Interfaz.objetivo("La salida trasera, al fondo del pasillo. Que no te vean.", 6.0)
		_:
			if Juego.bandera(&"f2_interrogatorio_visto"):
				_interrogador.visible = false
				_esposado()
			else:
				_interrogatorio()


# ----------------------------------------------------------- Interrogatorio ---

func _interrogatorio() -> void:
	empezar_cinematica(true)
	_sentar_a_elias()
	plano($Camaras/Mesa)
	await espera(2.0)
	var lineas: Array = Guion.F2_INTERROGATORIO
	var planos := [$Camaras/Interrogador, $Camaras/Elias, $Camaras/Interrogador, $Camaras/Espejo,
			$Camaras/Interrogador, $Camaras/Elias, $Camaras/Mesa]
	for i in lineas.size():
		plano(planos[i])
		if i == 2:
			_interrogador.reproducir(&"golpe_mesa", 0.1)
			await espera(0.55)
			Audio.efecto(&"golpe_mesa", 4.0)
			RenderRig.fundir(0.25, 0.0)
			RenderRig.fundir(0.0, 0.2)
		elif i == 4:
			_interrogador.reproducir(&"andar", 0.2, 0.6)
			_interrogador.rotation.y = atan2(0.5, 0.9)
			var tw := create_tween()
			tw.tween_property(_interrogador, "position", Vector3(2.6, 0, -3.3), 3.0)
		await decir(lineas[i][0], lineas[i][1], lineas[i][2])
		if i == 2 or i == 4:
			_interrogador.reproducir(&"quieto", 0.3)
		if i == 4:
			_interrogador.rotation.y = atan2(1.2, -1.2)
	# Se va: cruza la puerta y la cierra con llave.
	plano($Camaras/Puerta)
	_interrogador.reproducir(&"andar", 0.2)
	_interrogador.rotation.y = PI * 0.5
	var tw2 := create_tween()
	tw2.tween_property(_interrogador, "position", Vector3(0.2, 0, -3.4), 2.4)
	tw2.tween_property(_interrogador, "position", Vector3(-1.0, 0, -3.4), 1.0)
	await espera(3.4)
	_interrogador.visible = false
	Audio.efecto(&"puerta_cerrojo", 2.0)
	await espera(1.0)
	Juego.poner_bandera(&"f2_interrogatorio_visto")
	# Punto de control del recuerdo: al reintentar no se repite la cinemática.
	Juego.punto_de_control(&"inicio", true)
	terminar_cinematica(0.4)
	_esposado()


func _sentar_a_elias() -> void:
	jugador.ocupado = true
	jugador.forzar_animacion(&"sentado")
	jugador.teletransportar(Vector3(1.4, 0, -2.1), -PI * 0.5)


# ------------------------------------------------------------------- Huida ---

func _esposado() -> void:
	_sentar_a_elias()
	jugador.bloquear(true)
	_tiempo = TIEMPO
	_contando = true
	Interfaz.subtitulo(Guion.F2_HUIDA[0][1], Guion.F2_HUIDA[0][2])
	await get_tree().create_timer(1.8, false).timeout
	if _fracaso:
		return
	var antes := Time.get_ticks_msec()
	var ok: bool = await Interfaz.ganzua(0.2, _tiempo)
	_tiempo -= (Time.get_ticks_msec() - antes) / 1000.0
	if not ok or _fracaso:
		_vuelve_el_interrogador()
		return
	Audio.efecto(&"esposas", 0.0)
	jugador.forzar_animacion(&"")
	jugador.ocupado = false
	jugador.bloquear(false)
	Interfaz.objetivo("Las esposas, fuera. Ahora la puerta, antes de que vuelva.", 6.0)


func ganzua_fallida(_it: Node) -> void:
	if _tiempo <= 0.5:
		_vuelve_el_interrogador()


func puerta_sala_abierta(_n: Node) -> void:
	_contando = false
	Interfaz.cuenta_atras(-1.0)
	Juego.punto_de_control(&"pasillo", true)
	Interfaz.objetivo("La salida trasera, al fondo del pasillo. Que no te vean.", 6.0)


## Silbato de un policía: el otro acude.
func refuerzos(_desde: Vector3) -> void:
	Interfaz.subtitulo(Guion.F2_ALARMA[1], Guion.F2_ALARMA[2], Guion.F2_ALARMA[0])
	for e in get_tree().get_nodes_in_group(&"perseguidor"):
		var p := e as Enemigo
		if p.estado != Enemigo.Estado.PERSEGUIR:
			p.ultima_posicion = jugador.global_position
			p.cambiar_estado(Enemigo.Estado.PERSEGUIR)


func _vuelve_el_interrogador() -> void:
	if _fracaso:
		return
	_fracaso = true
	_contando = false
	Interfaz.cuenta_atras(-1.0)
	Audio.efecto(&"puerta_cerrojo", 2.0)
	Interfaz.subtitulo("Interrogador: Se acabó el café.", 2.5)
	await get_tree().create_timer(1.5, false).timeout
	Juego.morir()


# ------------------------------------------------------------------ Salida ---

func salida(_n: Node) -> void:
	empezar_cinematica(true, false)
	plano($Camaras/Salida)
	jugador.modelo().reproducir(&"empujar", 0.1)
	await espera(1.0)
	# D6: portazo metálico y silencio; el ascensor del presente llega a la Enfermería.
	Juego.volver_al_presente(&"cap3", &"inicio")


## Escena de consecuencia (G6).
func al_morir() -> void:
	RenderRig.establecer_barras(0.0, 0.0)
	await Interfaz.texto_central(Guion.F2_CONSECUENCIA, 3.2, 28)
