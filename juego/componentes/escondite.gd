@tool
class_name Escondite
extends Interactuable
## Escondite (S2): taquilla, bajo un catre o un rincón en sombra. Dentro, los enemigos no
## ven al jugador... salvo que lo hayan visto entrar.
##
## Hijos: «Punto» (Marker3D donde se coloca Elías), «Salida» (Marker3D al salir) y,
## opcional, «Camara» (Camera3D: lo que se ve desde dentro, por ejemplo entre las rendijas).

enum Tipo { TAQUILLA, CATRE, RINCON }

@export var tipo: Tipo = Tipo.TAQUILLA

var ocupante: Jugador = null


func _init() -> void:
	texto = "Esconderse"
	radio = 1.3
	epoca = Epoca.PRESENTE


func _ready() -> void:
	super()
	if not Engine.is_editor_hint():
		add_to_group(&"escondite")


func _al_usar(jugador: Jugador) -> bool:
	var punto := get_node_or_null(^"Punto") as Node3D
	if punto == null:
		punto = self
	var anim := &"taquilla" if tipo == Tipo.TAQUILLA else &"agachado"
	await jugador.entrar_en_escondite(self, punto, anim, camara_escondite())
	ocupante = jugador
	activo = false
	Interfaz.mostrar_aviso("Salir")
	return true


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or ocupante == null:
		return
	if not ocupante.oculto or ocupante.muerto:
		ocupante = null
		activo = true
		return
	if Input.is_action_just_pressed(&"interactuar") and not Interfaz.modal_activo() and ocupante.control_activo:
		var j := ocupante
		ocupante = null
		Interfaz.ocultar_aviso()
		Audio.efecto(&"esconderse", -8.0, 0.9)
		j.salir_de_escondite()
		await get_tree().create_timer(0.5, false).timeout
		activo = true


func punto_salida() -> Node3D:
	var s := get_node_or_null(^"Salida") as Node3D
	return s if s else self


func camara_escondite() -> Camera3D:
	return get_node_or_null(^"Camara") as Camera3D


## Un enemigo que vio entrar al jugador lo saca de aquí.
func sacar() -> Jugador:
	var j := ocupante
	if j:
		ocupante = null
		Interfaz.ocultar_aviso()
		j.salir_de_escondite(true)
		activo = true
	return j
