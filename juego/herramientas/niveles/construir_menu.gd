extends Constructor
## Fondo cinematográfico del menú principal y de los créditos (C-21): cinco «postales» de
## los escenarios reales del juego, separadas 300 m entre sí, cada una con su cámara (Desde →
## Hasta), su época y sus manifestaciones. ui/fondo_cinematico.gd las recorre en bucle.

const ESC := "res://assets/escenarios/"
const FRIO := Color(0.6, 0.72, 0.75)
const SODIO := Color(1.0, 0.6, 0.27)


func construir() -> int:
	nuevo_nivel(&"FondoCinematico")
	_pasillo(grupo(raiz, "Set0"))
	_calle(grupo(raiz, "Set1"))
	_patio(grupo(raiz, "Set2"))
	_ejecucion(grupo(raiz, "Set3"))
	_enfermeria(grupo(raiz, "Set4"))
	finalizar("res://ui/fondo_cinematico.gd")
	return guardar("res://ui/fondo_cinematico.tscn")


func _postal(s: Node3D, x: float, epoca: int, desde: Vector3, hasta: Vector3, mirar_desde: Vector3,
		mirar_hasta: Vector3, entorno_: Environment, fov := 55.0) -> void:
	s.position = Vector3(x, 0, 0)
	s.set_meta(&"epoca", epoca)
	var cam := camara(s, "Camara", desde, mirar_desde, fov)
	cam.environment = entorno_
	marcador(s, "Desde", desde, mirar_desde)
	marcador(s, "Hasta", hasta, mirar_hasta)


func _entorno(ambiente: Color, energia: float, niebla: Color, densidad: float) -> Environment:
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0, 0, 0)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = ambiente
	e.ambient_light_energy = energia
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.fog_enabled = true
	e.fog_light_color = niebla
	e.fog_density = densidad
	e.glow_intensity = 0.4
	return e


func _pasillo(s: Node3D) -> void:
	instancia(ESC + "bloque_a_juego.glb", s, "Escenario")
	_postal(s, 0.0, 0, Vector3(1.6, 1.35, 0.35), Vector3(8.5, 1.25, -0.15), Vector3(20.0, 1.4, 0.0),
			Vector3(20.0, 1.5, 0.0), _entorno(Color(0.16, 0.19, 0.18), 0.9, Color(0.05, 0.07, 0.065), 0.04))
	for k in 4:
		fluorescente(s, "Fluor%d" % k, Vector3(1.5 + k * 6.0, 2.72, 0), [0, 2, 1, 0][k], 3.2, 7.5)
	luz_alarma(s, "Alarma", Vector3(18.0, 2.55, 0), 9.0).set(&"encendida_al_empezar", true)
	figura(s, "Uniforme", "el_uniforme", Vector3(20.0, 0, 0), 90.0, &"recuento")
	figura(s, "Cadaver", "aislado_a", Vector3(12.0, 0, 0.4), 60.0, &"morir", 1.0)
	omni(s, "Relleno", Vector3(19.0, 2.4, 0), FRIO, 1.2, 5.0)


func _calle(s: Node3D) -> void:
	instancia(ESC + "callejon.glb", s, "Escenario")
	_postal(s, 300.0, 1, Vector3(1.6, 1.2, -16.0), Vector3(0.4, 1.7, -8.0), Vector3(-1.0, 1.4, 2.0),
			Vector3(-2.0, 1.6, -0.7), _entorno(Color(0.22, 0.18, 0.15), 1.15, Color(0.1, 0.085, 0.075), 0.016), 52.0)
	var lluvia := componente("res://componentes/lluvia.gd", s, "Lluvia", Vector3(0, 6, -8), 0.0, {"radio_activo": 60.0},
			"GPUParticles3D")
	lluvia.set(&"radio_activo", 60.0)
	for z in [-3.5, -16.0]:
		omni(s, "Sodio%d" % int(-z), Vector3(-2.75, 4.15, z), SODIO, 2.8, 12.0)
	omni(s, "SodioInicio", Vector3(2.4, 4.0, 4.5), SODIO, 2.2, 10.0)
	figura(s, "Elias", "elias_civil", Vector3(-0.5, 0, -2.5), 180.0, &"correr_mirando_atras", 0.3)
	figura(s, "Policia", "policia_patrullero", Vector3(0.5, 0, 4.0), 180.0, &"correr", 0.6)
	foco(s, "Linterna", Vector3(0.6, 1.4, 3.6), Vector3(-0.4, 1.0, -3.0), Color(1.0, 0.95, 0.82), 4.0, 14.0, 17.0, false)


func _patio(s: Node3D) -> void:
	instancia(ESC + "patio_central.glb", s, "Escenario")
	_postal(s, 600.0, 0, Vector3(-11.0, 33.6, 30.0), Vector3(-3.0, 44.0, 6.0), Vector3(0.0, 24.0, -20.0),
			Vector3(0.0, 14.0, -30.0), _entorno(Color(0.2, 0.23, 0.28), 1.45, Color(0.1, 0.12, 0.15), 0.011), 60.0)
	for y in [8.0, 22.0, 40.0]:
		for z in [-25.0, 0.0, 22.0]:
			omni(s, "Vacio_%d_%d" % [int(y), int(z)], Vector3(0, y, z), Color(0.55, 0.64, 0.78), 1.1, 24.0)
	omni(s, "Torre", Vector3(-4.0, 37.2, 27.0), Color(1.0, 0.72, 0.42), 2.4, 10.0)
	for k in 3:
		var g := grupo(s, "Colgado%d" % k)
		g.position = Vector3(-5.0 + k * 5.0, 31.45, -20.0)
		caja(g, "Cuerda", Vector3(0, -0.4, 0), Vector3(0.025, 0.8, 0.025), material("", Color(0.32, 0.28, 0.22)), false)
		figura(g, "Cuerpo", ["preso_generico_a", "preso_generico_b", "preso_generico_c"][k], Vector3(0, -2.65, 0),
				k * 70.0, &"quieto", 0.0)
	figura(s, "Vigilante", "el_vigilante", Vector3(-3.75, 34.3, 27.0), -90.0, &"quieto")
	foco(s, "FocoVigilante", Vector3(-3.9, 36.4, 27.0), Vector3(-12.2, 32.5, 22.0), Color(0.92, 0.95, 1.0), 9.0, 30.0, 16.0, true)


func _ejecucion(s: Node3D) -> void:
	instancia(ESC + "ejecucion.glb", s, "Escenario")
	_postal(s, 900.0, 0, Vector3(6.0, 1.0, -2.0), Vector3(9.4, 1.6, -5.4), Vector3(11.0, 2.6, -12.0),
			Vector3(11.0, 2.4, -12.5), _entorno(Color(0.16, 0.12, 0.11), 1.0, Color(0.1, 0.05, 0.04), 0.03), 48.0)
	for p in [Vector3(0.4, 3.2, -6.0), Vector3(21.6, 3.2, -8.0), Vector3(16.0, 3.2, -15.6)]:
		omni(s, "Roja_%d" % int(p.x), p, Color(0.85, 0.12, 0.07), 2.6, 12.0)
	foco(s, "Patibulo", Vector3(11.0, 8.6, -9.4), Vector3(11.0, 0.0, -9.4), Color(0.85, 0.82, 0.75), 4.0, 12.0, 42.0, true)
	figura(s, "Sentencia", "la_sentencia", Vector3(11.0, 0, -12.6), 180.0, &"quieto", -1.0, 1.25)


func _enfermeria(s: Node3D) -> void:
	instancia(ESC + "enfermeria.glb", s, "Escenario")
	_postal(s, 1200.0, 0, Vector3(2.0, 1.6, -1.0), Vector3(4.2, 1.5, -4.6), Vector3(6.5, 1.0, -5.5),
			Vector3(5.7, 1.4, -8.6), _entorno(Color(0.17, 0.2, 0.19), 1.0, Color(0.07, 0.08, 0.075), 0.035), 55.0)
	for p in [Vector3(3.5, 3.3, -2.5), Vector3(9.5, 3.3, -6.5)]:
		fluorescente(s, "Fluor_%d" % int(p.x), p, 2, 3.0, 8.0)
	foco(s, "Quirofano", Vector3(6.5, 2.05, -5.0), Vector3(6.5, 0.0, -5.0), Color(1.0, 0.95, 0.85), 5.0, 4.0, 48.0, true)
	figura(s, "Condenado", "el_condenado", Vector3(5.7, 0, -7.6), 180.0, &"acechar")
	omni(s, "Relleno", Vector3(5.7, 2.6, -6.8), Color(0.7, 0.8, 0.78), 1.0, 5.0)
