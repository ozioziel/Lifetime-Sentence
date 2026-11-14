extends Nivel
## Capítulo IV «La Sentencia» (K9, L1).
##   Antesala: escopeta, orden de ejecución (la fuga de Elías disparó el protocolo) y pared de
##   guardado → rótulo «IV — LA SENTENCIA» → la sala: La Sentencia aparece, cae el rastrillo.
##   Tres mecanismos (palanca, volante, torno) que se accionan manteniendo el botón y hacen
##   ruido: ella acude y destroza las coberturas. La escopeta la hace tambalearse (§7.1).
##   Con los tres, la puerta de los sectores inferiores se abre → huida → final.

@onready var _sentencia: LaSentencia = $Enemigos/Sentencia
@onready var _hoja: Node3D = $Decorado/PuertaSalida/Hoja
@onready var _rastrillo: Node3D = $Decorado/Rastrillo

var _mecanismos := 0
var _abierta := false
var _escapando := false


func al_entrar(punto: StringName) -> void:
	_mecanismos = 0
	for m in [$Interactivos/Palanca, $Interactivos/Volante, $Interactivos/Torno]:
		if (m as Mecanismo).completado:
			_mecanismos += 1
	_actualizar_puerta(true)
	if punto == &"inicio" and not Juego.bandera(&"cap4_intro"):
		_intro()
	else:
		Interfaz.objetivo("La sala de ejecución.", 5.0)


func _intro() -> void:
	Juego.poner_bandera(&"cap4_intro")
	empezar_cinematica(true)
	plano($Camaras/Antesala)
	await espera(1.6)
	rotulo("IV", "LA SENTENCIA")
	megafonia(Guion.MEGAFONIA_CAP4)
	await espera(5.0)
	terminar_cinematica(0.6)
	Interfaz.objetivo("Antes de entrar: la escopeta del guardia.", 6.0)


func entrar_sala(_z: Node) -> void:
	if Juego.bandera(&"sentencia_vista"):
		_bajar_rastrillo(true)
		_sentencia.activar(Enemigo.Estado.INVESTIGAR)
		_sentencia.destino = jugador.global_position
		return
	Juego.poner_bandera(&"sentencia_vista")
	# Al morir no se repite la presentación.
	Juego.punto_de_control(&"inicio", false)
	empezar_cinematica(true)
	plano($Camaras/Sala)
	Audio.efecto(&"arrastre_lejano", 2.0)
	await espera(1.8)
	_sentencia.activar(Enemigo.Estado.GUION)
	_sentencia.mirar_a(Vector3(11.0, 0, 0))
	_sentencia.modelo.reproducir(&"andar", 0.2, 0.8)
	var tw := create_tween()
	tw.tween_property(_sentencia, "global_position", Vector3(11.0, 0, -12.8), 2.6)
	plano($Camaras/Sentencia)
	await espera(2.6)
	_sentencia.modelo.reproducir(&"furia", 0.1)
	Audio.efecto(&"sentencia_rugido", 4.0)
	plano($Camaras/SentenciaCerca)
	if jugador.camara:
		jugador.camara.sacudir(0.6)
	await espera(1.6)
	plano($Camaras/Rastrillo)
	_bajar_rastrillo(false)
	await espera(1.4)
	terminar_cinematica(0.4)
	_sentencia.cambiar_estado(Enemigo.Estado.INVESTIGAR)
	_sentencia.destino = jugador.global_position
	Interfaz.subtitulo(Guion.CAP4_PISTA[1], Guion.CAP4_PISTA[2])
	Interfaz.objetivo("Tres mecanismos: palanca, volante, torno.", 7.0)


func _bajar_rastrillo(instantaneo: bool) -> void:
	if instantaneo:
		_rastrillo.position.y = 0.0
		return
	Audio.efecto(&"rastrillo", 4.0)
	var tw := create_tween()
	tw.tween_property(_rastrillo, "position:y", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	if jugador.camara:
		jugador.camara.sacudir(0.5)


func mecanismo_activado(m: Node) -> void:
	_mecanismos += 1
	Audio.efecto(&"engranajes", 2.0)
	get_tree().call_group(&"luz_alarma", &"encender")
	if jugador.camara:
		jugador.camara.sacudir(0.3)
	_actualizar_puerta(false)
	Interfaz.mensaje("Mecanismo %d de 3" % _mecanismos)
	_sentencia.oir((m as Node3D).global_position, 30.0, m)
	if _mecanismos >= 3:
		_abierta = true
		Interfaz.objetivo("¡La puerta de los sectores inferiores!", 6.0)
	await get_tree().create_timer(2.5, false).timeout
	get_tree().call_group(&"luz_alarma", &"apagar")


func _actualizar_puerta(instantaneo: bool) -> void:
	var altura := 3.5 * clampf(_mecanismos / 3.0, 0.0, 1.0)
	if instantaneo:
		_hoja.position.y = altura
		_abierta = _mecanismos >= 3
		return
	Audio.efecto_3d(&"puerta_monumental", _hoja.global_position + Vector3(19.5, 1.8, -15.8), 0.0, 40.0)
	var tw := create_tween()
	tw.tween_property(_hoja, "position:y", altura, 2.0).set_trans(Tween.TRANS_SINE)


func escapar(_z: Node) -> void:
	if not _abierta or _escapando or jugador.muerto:
		return
	_escapando = true
	empezar_cinematica(true, false)
	_sentencia.cambiar_estado(Enemigo.Estado.GUION)
	plano($Camaras/Salida)
	_sentencia.modelo.reproducir(&"golpe_barrido", 0.1)
	Audio.efecto(&"sentencia_rugido", 4.0)
	jugador.andar_hasta(Vector3(19.5, 0, -15.6), 3.2, &"correr")
	await espera(1.2)
	Audio.efecto(&"golpe_metalico", 4.0)
	if jugador.camara:
		jugador.camara.sacudir(0.8)
	Juego.ir_a(&"final", &"inicio", 1.6)
