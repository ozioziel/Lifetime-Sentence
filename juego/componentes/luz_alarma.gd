class_name LuzAlarma
extends OmniLight3D
## Luz roja de emergencia (A4): apagada hasta que salta la alarma o te detectan.
## Todas las del grupo «luz_alarma» se encienden con Juego.dar_alarma().

@export var energia := 2.2
@export var parpadeo := 1.6
@export var encendida_al_empezar := false

var _encendida := false
var _t := 0.0


func _ready() -> void:
	add_to_group(&"luz_alarma")
	light_color = Color(1.0, 0.08, 0.04)
	shadow_enabled = false
	light_energy = 0.0
	if encendida_al_empezar:
		encender()


func encender() -> void:
	_encendida = true


func apagar() -> void:
	_encendida = false
	light_energy = 0.0


func _process(delta: float) -> void:
	if not _encendida:
		return
	_t += delta * parpadeo
	light_energy = energia * (0.35 + 0.65 * absf(sin(_t * PI)))
