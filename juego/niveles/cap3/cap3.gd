extends Nivel
## Capítulo III «Enfermería».
##   Llegada en el ascensor → rótulo «III — ENFERMERÍA» → enfermería (gore estático, H4) y
##   registro de defunciones → puzle de espejos (K8): cubrirlos en el orden en que murieron
##   los cuatro testigos; El Condenado se ve en los reflejos, detrás de ti; tres errores y
##   ataca → archivo → nota del guardia (placa 31) → caja de seguridad (2915) → fotografía
##   → recuerdo F3 «El ingreso».

## Índices de los espejos en el orden correcto: 3115, 2290, 4011, 3876.
const ORDEN := [2, 0, 3, 1]

@onready var _condenado: ElCondenado = $Enemigos/Condenado

var _paso := 0
var _errores := 0
var _cubiertos := [false, false, false, false]


func al_entrar(punto: StringName) -> void:
	if Juego.bandera(&"espejos_resueltos"):
		for k in 4:
			_cubrir_visual(k, true)
			(get_node("Interactivos/CubrirEspejo%d" % k) as Interactuable).activo = false
		_condenado.visible = false
	else:
		_condenado.seguir_al_jugador(true)
	match punto:
		&"inicio":
			_llegada()
		_:
			$Decorado/Ascensor/Reja.position.y = 2.75
			Interfaz.objetivo(Juego.lugar_actual())


func _llegada() -> void:
	empezar_cinematica(true)
	plano($Camaras/Llegada)
	Audio.efecto(&"ascensor_llega", 0.0)
	if jugador.camara:
		jugador.camara.sacudir(0.4)
	await espera(1.6)
	Audio.efecto(&"reja_ascensor", 0.0)
	var tw := create_tween()
	tw.tween_property($Decorado/Ascensor/Reja, "position:y", 2.75, 1.2)
	await espera(1.4)
	rotulo("III", "ENFERMERÍA")
	await espera(1.0)
	terminar_cinematica(0.6)
	await get_tree().create_timer(5.0, false).timeout
	Interfaz.objetivo("La enfermería. Alguien guardaba aquí lo que no debía verse.", 6.0)


func ver_gore(_z: Node) -> void:
	empezar_cinematica(true)
	plano($Camaras/Gore, 0.8)
	Audio.efecto(&"latido", -4.0)
	await espera(3.2)
	terminar_cinematica(0.6)


func cerca_espejos(_z: Node) -> void:
	if not Juego.bandera(&"espejos_resueltos") and not Juego.bandera(&"espejos_vistos"):
		Juego.poner_bandera(&"espejos_vistos")
		Audio.efecto(&"susurro", -6.0)
		Interfaz.subtitulo("(En el espejo hay alguien detrás de ti.)", 3.0)


# ------------------------------------------------------------------ Espejos ---

func cubrir_espejo(n: Node) -> void:
	var k := int(String(n.name).trim_prefix("CubrirEspejo"))
	if _cubiertos[k] or Juego.bandera(&"espejos_resueltos"):
		return
	_cubrir_visual(k, true)
	Audio.efecto(&"tela", -2.0)
	if ORDEN[_paso] == k:
		_paso += 1
		if _paso >= ORDEN.size():
			_resuelto()
	else:
		_error()


func _cubrir_visual(k: int, cubierto: bool) -> void:
	_cubiertos[k] = cubierto
	get_node("Espejos/Sabana%d" % k).visible = cubierto
	get_node("Espejos/Espejo%d" % k).visible = not cubierto


func _error() -> void:
	_errores += 1
	await get_tree().create_timer(0.7, false).timeout
	# Susto: por un instante está DE VERDAD detrás de ti.
	Audio.efecto(&"condenado_grito", 0.0)
	_condenado.solo_en_espejos(false)
	if jugador.camara:
		jugador.camara.sacudir(0.6)
	await get_tree().create_timer(0.22, false).timeout
	_condenado.solo_en_espejos(true)
	# Las sábanas caen: vuelta a empezar.
	for k in 4:
		_cubrir_visual(k, false)
	_paso = 0
	if _errores >= 3:
		_condenado.atacar_por_la_espalda()
		return
	Interfaz.subtitulo(Guion.CONDENADO_ERROR[1], Guion.CONDENADO_ERROR[2])
	if _errores == 2:
		Interfaz.mensaje("(No en cualquier orden. En el orden en que se fueron.)", 4.0)


func _resuelto() -> void:
	Juego.poner_bandera(&"espejos_resueltos")
	_condenado.seguir_al_jugador(false)
	_condenado.visible = false
	for k in 4:
		(get_node("Interactivos/CubrirEspejo%d" % k) as Interactuable).activo = false
	await get_tree().create_timer(1.0, false).timeout
	Audio.efecto(&"cerrojo_lejano", 0.0)
	$Interactivos/PuertaArchivo.abrir_cerradura()
	Interfaz.subtitulo("(Silencio. Después, un cerrojo, en el pasillo.)", 3.5)
	Interfaz.objetivo("El archivo, junto al ascensor.", 6.0)


# ------------------------------------------------------- Caja de seguridad ---

func caja_abierta(_n: Node) -> void:
	Juego.dar_objeto(&"copias")
	empezar_cinematica(true, false)
	plano($Camaras/Foto, 0.5)
	Audio.efecto(&"caja_fuerte", 0.0)
	await decir("", "(Dentro, las copias. Y una fotografía: un guardia joven, en el patio, al sol.)", 3.8)
	await decir("", "(Al dorso: «Placa 31. El día que llegaste».)", 3.2)
	# D5 hacia F3: el bullicio del patio en el pasado entra antes que la imagen.
	Juego.pasar_al_pasado(&"f3", &"inicio", &"patio_pasado")
