@tool
class_name Mecanismo
extends Interactuable
## Mecanismo que se acciona MANTENIENDO Interactuar: palanca, volante, torno, caja de
## fusibles... Mientras se acciona hace ruido (los enemigos lo oyen, K9) y gira su «Pieza».
## Al completarse emite «activado» y llama a «Metodo Nivel».

signal activado
signal progreso_cambiado(valor: float)

## Segundos de accionamiento continuo.
@export var duracion := 3.0
## Animación de Elías mientras lo acciona (volante, palanca, ganzua...).
@export var animacion_bucle: StringName = &"volante"
## Nodo que gira mientras se acciona.
@export var pieza: NodePath
@export var eje_giro := Vector3(0, 0, 1)
@export var vueltas := 2.0
## Metros a los que se oye mientras se acciona (0 = no hace ruido).
@export var ruido_radio := 16.0
@export var sonido_bucle: StringName = &"mecanismo"
## Si se suelta antes de terminar, el progreso se pierde poco a poco.
@export var pierde_progreso := false

var progreso := 0.0
var completado := false
var _sonido: AudioStreamPlayer3D
var _rotacion_inicial := Basis.IDENTITY


func _init() -> void:
	texto = "Accionar (mantener)"
	una_vez = true
	radio = 1.5


func _ready() -> void:
	super()
	var p := get_node_or_null(pieza) as Node3D
	if p:
		_rotacion_inicial = p.basis


func _restaurar_usado() -> void:
	completado = true
	progreso = 1.0
	_girar_pieza()


func texto_aviso(jugador: Jugador) -> String:
	if progreso > 0.01:
		return "%s  %d %%" % [texto, int(progreso * 100.0)]
	return super(jugador)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if pierde_progreso and not completado and not _en_uso and progreso > 0.0:
		progreso = maxf(progreso - delta * 0.08, 0.0)
		_girar_pieza()


func _al_usar(jugador: Jugador) -> bool:
	jugador.ocupado = true
	jugador.forzar_animacion(animacion_bucle)
	if sonido_bucle != &"":
		_sonido = Audio.efecto_3d(sonido_bucle, global_position, -2.0, 30.0)
	var t_ruido := 0.0
	while Input.is_action_pressed(&"interactuar") and progreso < 1.0 and not jugador.muerto:
		var delta := get_physics_process_delta_time()
		progreso = minf(progreso + delta / duracion, 1.0)
		progreso_cambiado.emit(progreso)
		_girar_pieza()
		Interfaz.mostrar_aviso(texto_aviso(jugador))
		t_ruido -= delta
		if t_ruido <= 0.0 and ruido_radio > 0.0:
			t_ruido = 0.5
			Juego.emitir_ruido(global_position, ruido_radio, self)
		await get_tree().physics_frame
	jugador.forzar_animacion(&"")
	jugador.ocupado = false
	Interfaz.ocultar_aviso()
	if is_instance_valid(_sonido):
		_sonido.stop()
		_sonido.queue_free()
	if progreso < 1.0:
		return false
	completado = true
	Audio.efecto_3d(&"mecanismo_fin", global_position, 2.0, 40.0)
	activado.emit()
	return true


func _girar_pieza() -> void:
	var p := get_node_or_null(pieza) as Node3D
	if p:
		p.basis = _rotacion_inicial * Basis(eje_giro.normalized(), progreso * vueltas * TAU)
