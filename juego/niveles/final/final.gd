extends Nivel
## Final de la demo: El Director (aparición) y la última revelación (§4.5.2). La demo termina
## JUSTO ANTES del dilema, sin ninguna elección (N11, H6) → «FIN DE LA DEMO» → créditos (C-20).

@onready var _director: ModeloPersonaje = $Figuras/Director


func al_entrar(_punto: StringName) -> void:
	empezar_cinematica(true)
	RenderRig.fundir(1.0, 0.0)
	plano($Camaras/Entrada)
	await espera(0.8)
	RenderRig.fundir(0.0, 3.0)
	Audio.efecto(&"respiracion_despertar", -6.0)
	await espera(5.0)
	terminar_cinematica(1.2)
	Interfaz.objetivo("", 0.1)


func voz_inicio(_z: Node) -> void:
	megafonia([Guion.FINAL_DIRECTOR[0]])
	await get_tree().create_timer(5.5, false).timeout
	Interfaz.subtitulo(Guion.FINAL_DIRECTOR[1][1], Guion.FINAL_DIRECTOR[1][2], Guion.FINAL_DIRECTOR[1][0])


func escena_final(_z: Node) -> void:
	empezar_cinematica(true, false)
	jugador.andar_hasta(Vector3(8.0, 0, -34.0), 0.8)
	plano($Camaras/Escala, 1.5)
	await espera(2.0)
	_director.reproducir(&"mirar_abajo", 0.4)
	Audio.efecto(&"director_presencia", 0.0)
	plano($Camaras/Director)
	await espera(2.4)
	var lineas: Array = Guion.FINAL_DIRECTOR
	var planos := [null, null, $Camaras/Director, $Camaras/Escala, $Camaras/Elias, $Camaras/Director,
			$Camaras/Elias, $Camaras/Cenital, $Camaras/Carpeta, $Camaras/Elias]
	for i in range(2, lineas.size()):
		if planos[i]:
			plano(planos[i], 0.0)
		await decir(lineas[i][0], lineas[i][1], lineas[i][2])
	await espera(1.2)
	# Corte seco a negro, silencio, y fin. Sin elección.
	RenderRig.fundir(1.0, 0.0)
	Audio.parar_todo(0.0)
	Audio.silencio_absoluto(2.0)
	await get_tree().create_timer(2.2, false).timeout
	RenderRig.establecer_barras(0.0, 0.0)
	await Interfaz.texto_central("FIN DE LA DEMO", 3.5, 58)
	Juego.ir_a_creditos()
