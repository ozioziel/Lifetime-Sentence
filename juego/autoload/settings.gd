extends Node
## Ajustes del jugador (autoload «Settings»).
##
## Guarda y carga las preferencias en user://ajustes.cfg y avisa al resto del
## juego con la señal [signal cambiado] cuando algo se modifica.
##
## Leer un ajuste:    [code]Settings.sensibilidad_raton[/code]
## Cambiar un ajuste: [code]Settings.establecer(&"invertir_y", true)[/code]

## Se emite al cambiar cualquier ajuste. [param nombre] es la variable modificada.
signal cambiado(nombre: StringName)

## Preajustes gráficos. BAJO: pensado para portátiles con gráfica integrada.
## ALTO: añade sombras en todas las luces, brillo y niebla volumétrica.
enum Calidad { BAJO, ALTO }

const RUTA_ARCHIVO := "user://ajustes.cfg"
const SECCION := "ajustes"
## Variables que se guardan en disco.
const GUARDABLES: Array[StringName] = [
	&"sensibilidad_raton", &"sensibilidad_mando", &"invertir_y",
	&"agacharse_alternar", &"volumen_general", &"calidad", &"pantalla_completa",
	&"volumen_musica", &"volumen_ambiente", &"volumen_efectos", &"volumen_voces",
	&"subtitulos", &"vibracion_mando", &"advertencias_vistas", &"controles",
]

## Radianes de giro por píxel de movimiento del ratón.
var sensibilidad_raton := 0.0022
## Radianes por segundo con la palanca derecha al máximo.
var sensibilidad_mando := 2.4
## Invierte el eje vertical de la cámara.
var invertir_y := false
## true: pulsar una vez para agacharse y otra para levantarse. false: mantener.
var agacharse_alternar := true
## Volumen general, de 0 a 1.
var volumen_general := 1.0
var calidad: Calidad = Calidad.BAJO
var pantalla_completa := false
## Volumen de cada bus de audio, de 0 a 1.
var volumen_musica := 0.8
var volumen_ambiente := 1.0
var volumen_efectos := 1.0
var volumen_voces := 1.0
var subtitulos := true
var vibracion_mando := true
## true cuando ya se han mostrado las advertencias iniciales una vez.
var advertencias_vistas := false
## Teclas reasignadas: {"accion": codigo_fisico}. Vacío = controles por defecto.
var controles := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	cargar()
	_leer_argumentos()
	aplicar()


## Cambia un ajuste, lo aplica, lo guarda y avisa con [signal cambiado].
func establecer(nombre: StringName, valor: Variant) -> void:
	if not nombre in GUARDABLES:
		push_warning("Settings: ajuste desconocido «%s»" % nombre)
		return
	set(nombre, valor)
	aplicar()
	guardar()
	cambiado.emit(nombre)


## Aplica al motor los ajustes que dependen de él (ventana y audio).
func aplicar() -> void:
	var modo := DisplayServer.WINDOW_MODE_WINDOWED
	if pantalla_completa:
		modo = DisplayServer.WINDOW_MODE_FULLSCREEN
	if DisplayServer.window_get_mode() != modo:
		DisplayServer.window_set_mode(modo)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volumen_general, 0.0001)))
	for par in [[&"Musica", volumen_musica], [&"Ambiente", volumen_ambiente],
			[&"Efectos", volumen_efectos], [&"Voces", volumen_voces]]:
		var bus := AudioServer.get_bus_index(par[0])
		if bus != -1:
			AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(par[1], 0.0001)))
	_aplicar_controles()


## Teclas por defecto de las acciones que se pueden reasignar desde Opciones.
const REASIGNABLES := {
	&"mover_adelante": KEY_W, &"mover_atras": KEY_S, &"mover_izquierda": KEY_A,
	&"mover_derecha": KEY_D, &"correr": KEY_SHIFT, &"agacharse": KEY_C,
	&"interactuar": KEY_E, &"lanzar": KEY_G,
}


## Cambia la tecla principal de una acción (solo teclado; el mando no cambia).
func reasignar(accion: StringName, tecla: Key) -> void:
	controles[String(accion)] = int(tecla)
	_aplicar_controles()
	guardar()
	cambiado.emit(&"controles")


func restaurar_controles() -> void:
	controles = {}
	for accion: StringName in REASIGNABLES:
		_cambiar_tecla(accion, REASIGNABLES[accion])
	guardar()
	cambiado.emit(&"controles")


## Tecla principal (la primera de teclado) de una acción.
func tecla_de(accion: StringName) -> Key:
	if not InputMap.has_action(accion):
		return KEY_NONE
	for evento in InputMap.action_get_events(accion):
		if evento is InputEventKey:
			var e := evento as InputEventKey
			return e.physical_keycode if e.physical_keycode != KEY_NONE else e.keycode
	return KEY_NONE


func _aplicar_controles() -> void:
	for accion: String in controles:
		_cambiar_tecla(StringName(accion), int(controles[accion]))


## Sustituye la PRIMERA tecla de teclado de la acción y conserva el resto (flechas, mando).
func _cambiar_tecla(accion: StringName, tecla: int) -> void:
	if not InputMap.has_action(accion):
		return
	var eventos := InputMap.action_get_events(accion)
	var resto: Array[InputEvent] = []
	var quitada := false
	for evento in eventos:
		if evento is InputEventKey and not quitada:
			quitada = true
			continue
		resto.append(evento)
	InputMap.action_erase_events(accion)
	var nuevo := InputEventKey.new()
	nuevo.physical_keycode = tecla as Key
	InputMap.action_add_event(accion, nuevo)
	for evento in resto:
		InputMap.action_add_event(accion, evento)


func guardar() -> void:
	var archivo := ConfigFile.new()
	for nombre in GUARDABLES:
		archivo.set_value(SECCION, nombre, get(nombre))
	var err := archivo.save(RUTA_ARCHIVO)
	if err != OK:
		push_warning("Settings: no se pudo guardar (%s)" % error_string(err))


func cargar() -> void:
	var archivo := ConfigFile.new()
	if archivo.load(RUTA_ARCHIVO) != OK:
		return  # Primera ejecución: se usan los valores por defecto.
	for nombre in GUARDABLES:
		if archivo.has_section_key(SECCION, nombre):
			set(nombre, archivo.get_value(SECCION, nombre))


## Permite forzar ajustes al lanzar el juego, sin guardarlos:
##   juego.exe -- --calidad=alto --ventana
func _leer_argumentos() -> void:
	for argumento in OS.get_cmdline_user_args():
		match argumento:
			"--calidad=bajo":
				calidad = Calidad.BAJO
			"--calidad=alto":
				calidad = Calidad.ALTO
			"--ventana":
				pantalla_completa = false
			"--pantalla-completa":
				pantalla_completa = true
