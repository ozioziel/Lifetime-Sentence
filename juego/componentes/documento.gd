@tool
class_name Documento
extends Interactuable
## Documento legible (H3). El texto está en datos/documentos.gd con el mismo «Id».
## Una vez leído se puede releer desde la pausa (Documentos).

@export var id_documento: StringName = &"carta_hermana"


func _init() -> void:
	texto = "Leer"
	sonido = &"papel"


func _al_usar(_jugador: Jugador) -> bool:
	await Juego.leer_documento(id_documento)
	return true
