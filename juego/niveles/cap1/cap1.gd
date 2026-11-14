extends Nivel
## Capítulo I «Resiliencia» — Bloque A (storyboard §6).
##   1.1 Despertar: negro, un fluorescente arranca, Elías en el suelo (cenital, saltable).
##   1.2 Celda: alambre del somier → ganzúa → la reja cede. Pared de marcas (guardar).
##   1.3 Pasillo: cadáveres, expediente 4827, punzón, cartel «SE BUSCA» imposible.
##   1.4 D5 → recuerdo F1 «La huida».
##   1.6 D6 de vuelta: rejas oxidadas, silencio absoluto.
##   1.7 Ala B: llaves a lo lejos, El Uniforme, Recuento, taquillas.
##   1.8 Puerta monumental: volante (hace ruido), arrastre lejano → Patio Central.

const LuzF := preload("res://componentes/luz_fluorescente.gd")

@onready var _uniforme: Enemigo = $Enemigos/Uniforme
@onready var _pared_celda: Interactuable = $Interactivos/ParedCelda
@onready var _puerta_fondo: Interactuable = $Interactivos/PuertaFondo
@onready var _cartel: Interactuable = $Interactivos/Cartel
@onready var _fluor_celda: Node3D = $Luces/FluorA0


func al_entrar(punto: StringName) -> void:
	_pared_celda.activo = Juego.bandera(&"celda_abierta")
	if Juego.bandera(&"f1_completado"):
		_puerta_fondo.abrir_cerradura()
		$Decorado/Cartel.visible = false
		$Decorado/GoteoCartel.emitting = false
		_cartel.activo = false
	if Juego.bandera(&"puerta_monumental"):
		_abrir_puerta_monumental(true)
	if punto in [&"ala_b", &"pared_ala_b"] and Juego.bandera(&"ala_b_iniciada"):
		_uniforme.activar(Enemigo.Estado.PATRULLA)
	match punto:
		&"inicio":
			_despertar()
		&"desde_f1":
			_regreso_de_f1()
		&"pared_celda", &"pared_ala_a", &"pared_ala_b":
			Interfaz.objetivo(Juego.lugar_actual())


# ---------------------------------------------------------------- 1.1 Despertar ---

func _despertar() -> void:
	empezar_cinematica(true)
	_fluor_celda.set(&"estado", LuzF.Estado.APAGADA)
	jugador.ocupado = true
	jugador.modelo().posar(&"levantarse", 0.0)
	RenderRig.fundir(1.0, 0.0)
	plano($Camaras/Cenital)
	Audio.efecto(&"respiracion_despertar", -4.0)
	await espera(1.6)
	Audio.efecto(&"fluorescente_arranque", -2.0)
	_fluor_celda.set(&"estado", LuzF.Estado.AVERIADA)
	RenderRig.fundir(0.0, 1.8)
	await espera(2.2)
	_fluor_celda.set(&"estado", LuzF.Estado.ESTABLE)
	await espera(0.6)
	jugador.modelo().reproducir(&"levantarse", 0.1)
	plano($Camaras/Celda, 1.2)
	await espera(2.7)
	RenderRig.fundir(0.0, 0.0)
	_fluor_celda.set(&"estado", LuzF.Estado.ESTABLE)
	jugador.ocupado = false
	terminar_cinematica(0.8)
	rotulo("I", "RESILIENCIA")
	await get_tree().create_timer(6.5, false).timeout
	Interfaz.objetivo("La reja está cerrada. Busca algo con lo que forzarla.")


# ---------------------------------------------------------------- 1.2 La celda ---

func celda_abierta(_n: Node) -> void:
	Juego.poner_bandera(&"celda_abierta")
	_pared_celda.activo = true
	Interfaz.mensaje("Las marcas de la pared: rayar una más guarda la partida.", 4.5)
	await get_tree().create_timer(5.0, false).timeout
	Interfaz.objetivo("Sal al pasillo.")


# ------------------------------------------------------------- 1.3 El pasillo ---

func arrastre_lejano(_z: Node) -> void:
	# Primer anuncio de La Sentencia (N8): un arrastre metálico muy lejos.
	Audio.efecto(&"arrastre_lejano", -10.0)


func examinar_cartel(_n: Node) -> void:
	empezar_cinematica(true, false)
	plano($Camaras/Cartel, 0.6)
	Audio.efecto(&"latido", -2.0)
	await espera(1.4)
	Interfaz.subtitulo("(Es tu cara.)", 2.0)
	await espera(1.2)
	# D5: la lluvia entra antes que la imagen; el encuadre pasa de frío a ámbar.
	Juego.pasar_al_pasado(&"f1", &"inicio")


# ---------------------------------------------------------- 1.6 Regreso (D6) ---

func _regreso_de_f1() -> void:
	Juego.poner_bandera(&"f1_completado")
	empezar_cinematica(false, false)
	plano($Camaras/Reja)
	await espera(2.4)
	terminar_cinematica(0.4)
	Interfaz.objetivo("La puerta del fondo ya no está cerrada.")


# ---------------------------------------------------------------- 1.7 Ala B ---

func entrar_ala_b(_z: Node) -> void:
	if Juego.bandera(&"ala_b_iniciada"):
		return
	Juego.poner_bandera(&"ala_b_iniciada")
	megafonia(Guion.MEGAFONIA_CAP1)
	await get_tree().create_timer(2.0, false).timeout
	_uniforme.activar(Enemigo.Estado.PATRULLA)
	empezar_cinematica(true)
	plano($Camaras/Uniforme)
	await espera(3.0)
	terminar_cinematica(0.6)
	Interfaz.objetivo("Llaves. Escóndete. Cuando callen, no te muevas.", 7.0)


# ---------------------------------------------------- 1.8 Puerta monumental ---

func puerta_monumental(_n: Node) -> void:
	Juego.poner_bandera(&"puerta_monumental")
	empezar_cinematica(true, false)
	plano($Camaras/Monumental, 0.4)
	await espera(0.5)
	_abrir_puerta_monumental(false)
	await espera(3.4)
	Audio.efecto(&"arrastre_lejano", -2.0)
	Interfaz.subtitulo("(Algo enorme se arrastra, muy lejos. Hierro contra hormigón.)", 3.5)
	await espera(3.0)
	terminar_cinematica(0.5)


func _abrir_puerta_monumental(instantaneo: bool) -> void:
	var hoja := $Decorado/PuertaMonumental/Hoja as Node3D
	$Interactivos/Volante.activo = false
	if instantaneo:
		hoja.position.y = 2.75
		return
	Audio.efecto(&"puerta_monumental", 2.0)
	if jugador and jugador.camara:
		jugador.camara.sacudir(0.3)
	var tw := create_tween()
	tw.tween_property(hoja, "position:y", 2.75, 3.2).set_trans(Tween.TRANS_SINE)


func salir_al_patio(_z: Node) -> void:
	empezar_cinematica(true, false)
	await espera(0.8)
	Juego.ir_a(&"cap2", &"inicio", 1.8)
