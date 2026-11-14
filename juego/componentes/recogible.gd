@tool
class_name Recogible
extends Interactuable
## Algo que se coge: objeto clave, arma, munición, el punzón o un objeto para lanzar.
## Al cogerlo desaparece (sus hijos visuales incluidos) y no vuelve a aparecer al recargar.

enum Tipo { OBJETO_CLAVE, PUNZON, PISTOLA, ESCOPETA, MUNICION_PISTOLA, MUNICION_ESCOPETA, BOTELLA, LATA }

@export var tipo: Tipo = Tipo.OBJETO_CLAVE
## Objeto clave (si tipo = OBJETO_CLAVE): alambre, carpeta, fusible, llave_archivo...
@export var objeto: StringName = &""
## Munición que da (si es munición).
@export var cantidad := 6


func _init() -> void:
	texto = "Coger"
	animacion = &"recoger"
	una_vez = true


func _ready() -> void:
	# Los objetos para lanzar vuelven a aparecer al recargar: no se recuerdan.
	if tipo in [Tipo.BOTELLA, Tipo.LATA]:
		persistente = false
	super()


func _restaurar_usado() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


func disponible(jugador: Jugador) -> bool:
	if tipo in [Tipo.BOTELLA, Tipo.LATA] and jugador.lanzable != &"":
		return false
	return super(jugador)


func _al_usar(jugador: Jugador) -> bool:
	match tipo:
		Tipo.OBJETO_CLAVE:
			Juego.dar_objeto(objeto)
		Tipo.PUNZON:
			Juego.dar_punzon()
		Tipo.PISTOLA:
			Juego.dar_arma(&"pistola")
		Tipo.ESCOPETA:
			Juego.dar_arma(&"escopeta")
		Tipo.MUNICION_PISTOLA:
			Juego.dar_municion(&"pistola", cantidad)
		Tipo.MUNICION_ESCOPETA:
			Juego.dar_municion(&"escopeta", cantidad)
		Tipo.BOTELLA:
			jugador.coger_lanzable(&"botella")
		Tipo.LATA:
			jugador.coger_lanzable(&"lata")
	visible = false
	activo = false
	return true
