@tool
class_name ParedMarcas
extends Interactuable
## Punto de guardado (K4, §7.2): pared con marcas de conteo de días. Elías raya una
## marca más y la partida queda guardada en la ranura que se elija (3 ranuras).
## «Punto» = PuntoEntrada en el que aparecerá el jugador al cargar.

@export var punto: StringName = &"inicio"


func _init() -> void:
	texto = "Rayar una marca (guardar)"
	radio = 1.5


func _al_usar(jugador: Jugador) -> bool:
	jugador.ocupado = true
	Audio.efecto_3d(&"rayar_pared", global_position, 0.0, 10.0)
	await jugador.modelo().reproducir_una_vez(&"marcar_pared", 0.15)
	jugador.ocupado = false
	var ranura: int = await Interfaz.elegir_ranura(true)
	if ranura > 0:
		Juego.guardar_ranura(ranura, punto)
		Interfaz.mensaje("Partida guardada. Una marca más.")
	return true
