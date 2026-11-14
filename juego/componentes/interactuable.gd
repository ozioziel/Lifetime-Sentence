@tool
class_name Interactuable
extends Node3D
## Algo con lo que el jugador puede interactuar (indicador punto + botón, S4).
##
## CÓMO USARLO: añadir un Node3D con este script (o con uno de los que heredan de él:
## Documento, Recogible, ParedMarcas, Puerta, PuertaTransicion, Escondite, Mecanismo,
## Obstaculo...) y ajustar el Inspector. Para lógica propia del nivel no hace falta
## programar un componente nuevo: basta con poner en «Metodo Nivel» el nombre de una
## función del script del nivel; se llamará con este nodo como argumento.
##
## CERRADURAS: cualquier interactuable puede estar cerrado. Se abre con la ganzúa (K2),
## con un objeto clave, con un código o desde un script (abrir_cerradura()).

signal usado(jugador: Jugador)

enum Cerradura { NINGUNA, GANZUA, OBJETO, CODIGO, BLOQUEADA }
enum Epoca { CUALQUIERA, PRESENTE, PASADO }

## Verbo que aparece junto al botón: «Examinar», «Abrir», «Coger»...
@export var texto := "Examinar"
## Distancia (m) desde la que se puede usar.
@export var radio := 1.4
## Diferencia de altura máxima con el jugador.
@export var alto := 1.6
## Desplazamiento del punto de referencia respecto al nodo.
@export var desplazamiento := Vector3.ZERO
@export var activo := true
## Se desactiva tras el primer uso.
@export var una_vez := false
@export var epoca: Epoca = Epoca.CUALQUIERA
## Animación del jugador al usarlo (recoger, empujar, palanca...). Vacío = ninguna.
@export var animacion: StringName = &""
## Velocidad de esa animación (1 = normal; más alto = más rápida).
@export_range(0.25, 3.0) var velocidad_animacion := 1.0
## Sonido al usarlo (nombre en assets/audio).
@export var sonido: StringName = &""
## Función del script del nivel que se llama al usarlo (recibe este nodo).
@export var metodo_nivel: StringName = &""
## Bandera de Juego que se activa al usarlo (para recordar el estado al recargar).
@export var bandera: StringName = &""
## Texto que se muestra al usarlo (pensamiento de Elías). Vacío = nada.
@export_multiline var comentario := ""
## Recordar que ya se usó al recargar (solo con «Una Vez»).
@export var persistente := true

@export_group("Cerradura")
@export var cerradura: Cerradura = Cerradura.NINGUNA
## Ganzúa: 0 = fácil, 1 = difícil.
@export_range(0.0, 1.0) var dificultad := 0.4
## Ganzúa: segundos para abrirla (0 = sin límite).
@export var limite_tiempo := 0.0
## Objeto clave necesario (llave_archivo, fusible...).
@export var objeto_necesario: StringName = &""
## Código del teclado numérico.
@export var codigo := ""
## Texto al intentar usarlo cerrado.
@export_multiline var texto_cerrado := "Está cerrado."
## Bandera que guarda si ya se abrió (vacío = se calcula con el nombre del nodo).
@export var bandera_cerradura: StringName = &""

var _en_uso := false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group(&"interactuable")
	if una_vez and persistente and bandera == &"":
		bandera = StringName("usado_%s_%s" % [_id_escena(), name])
	if bandera != &"" and una_vez and Juego.bandera(bandera):
		activo = false
		_restaurar_usado()
	if cerradura != Cerradura.NINGUNA and Juego.bandera(_bandera_cerradura()):
		cerradura = Cerradura.NINGUNA
		_restaurar_abierto()


func _bandera_cerradura() -> StringName:
	if bandera_cerradura != &"":
		return bandera_cerradura
	return StringName("abierto_%s_%s" % [_id_escena(), name])


## Nombre de la escena del nivel (= id del nivel). Sirve para las banderas automáticas.
func _id_escena() -> String:
	var escena := get_tree().current_scene if is_inside_tree() else null
	return String(escena.name) if escena else "nivel"


## Punto de referencia para medir la distancia.
func punto_global() -> Vector3:
	return global_transform * desplazamiento


func disponible(jugador: Jugador) -> bool:
	if not activo or _en_uso or not is_visible_in_tree():
		return false
	match epoca:
		Epoca.PRESENTE:
			return not jugador.en_pasado
		Epoca.PASADO:
			return jugador.en_pasado
	return true


func texto_aviso(_jugador: Jugador) -> String:
	if cerradura == Cerradura.GANZUA:
		return "%s (ganzúa)" % texto
	return texto


## Lo llama el jugador al pulsar Interactuar.
func usar(jugador: Jugador) -> void:
	if _en_uso:
		return
	_en_uso = true
	jugador.mirar_a(global_position)
	if cerradura != Cerradura.NINGUNA:
		var abierta := await _intentar_abrir(jugador)
		if not abierta:
			_en_uso = false
			return
	if animacion != &"":
		await jugador.accion(animacion, velocidad_animacion)
	if sonido != &"":
		Audio.efecto_3d(sonido, global_position, 0.0, 15.0)
	if comentario != "":
		Interfaz.subtitulo(comentario, 3.5)
	var ok: bool = await _al_usar(jugador)
	if not ok:
		_en_uso = false
		return
	if bandera != &"" and persistente:
		Juego.poner_bandera(bandera)
	usado.emit(jugador)
	if metodo_nivel != &"" and Juego.nivel and Juego.nivel.has_method(metodo_nivel):
		await Juego.nivel.call(metodo_nivel, self)
	if una_vez:
		activo = false
	_en_uso = false


## Lógica propia de cada componente (se puede esperar con await).
## Devuelve false si el uso no se completó (se soltó el botón, se canceló...).
func _al_usar(_jugador: Jugador) -> bool:
	return true


## Al recargar un nivel: deja el componente como quedó tras usarlo (una_vez).
func _restaurar_usado() -> void:
	pass


## Al recargar un nivel: deja la cerradura abierta.
func _restaurar_abierto() -> void:
	pass


## Abre la cerradura desde un script (mecanismo, fusibles...).
func abrir_cerradura() -> void:
	cerradura = Cerradura.NINGUNA
	Juego.poner_bandera(_bandera_cerradura())
	_restaurar_abierto()


func _intentar_abrir(jugador: Jugador) -> bool:
	match cerradura:
		Cerradura.BLOQUEADA:
			Audio.efecto_3d(&"puerta_bloqueada", global_position, -2.0, 12.0)
			Interfaz.mensaje(texto_cerrado)
			return false
		Cerradura.OBJETO:
			if not Juego.tiene(objeto_necesario):
				Audio.efecto_3d(&"puerta_bloqueada", global_position, -2.0, 12.0)
				Interfaz.mensaje(texto_cerrado)
				return false
			Audio.efecto_3d(&"cerradura_llave", global_position, 0.0, 12.0)
		Cerradura.GANZUA:
			if not Juego.tiene(&"alambre") and not jugador.en_pasado:
				Interfaz.mensaje(texto_cerrado + " Necesitas algo fino y duro.")
				return false
			jugador.forzar_animacion(&"ganzua")
			var ok: bool = await Interfaz.ganzua(dificultad, limite_tiempo)
			jugador.forzar_animacion(&"")
			if not ok:
				if limite_tiempo > 0.0 and Juego.nivel and Juego.nivel.has_method(&"ganzua_fallida"):
					Juego.nivel.ganzua_fallida(self)
				return false
		Cerradura.CODIGO:
			var ok: bool = await Interfaz.teclado_codigo(codigo, texto_cerrado)
			if not ok:
				return false
	cerradura = Cerradura.NINGUNA
	Juego.poner_bandera(_bandera_cerradura())
	return true
