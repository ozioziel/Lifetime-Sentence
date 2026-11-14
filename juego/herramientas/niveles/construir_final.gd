extends Constructor
## Final de la demo (§5.1, N11): el despacho de Dirección (Núcleo). Un salón de 50 m con una
## alfombra roja hasta una tarima con un escritorio gigantesco; detrás, El Director (silueta
## colosal, aparición) a contraluz del muro de pantallas. Megafonía, revelación final y corte
## a negro justo antes del dilema → «FIN DE LA DEMO» → créditos.
## La sala de Blender ocupa x 0..16, z -50..0 (alto 22); la tarima, z -50..-40 (2,5 m).

const ESC := "res://assets/escenarios/"
const TEX_PAPEL := ESC + "nucleo_papeles.png"


func construir() -> int:
	nuevo_nivel(&"final")
	entorno(Color(0, 0, 0), Color(0.2, 0.16, 0.14), 1.3, Color(0.07, 0.05, 0.045), 0.012,
			0.025, Color(0.7, 0.45, 0.35), 0.8)
	var sala := instancia(ESC + "nucleo.glb", raiz, "Sala")
	navegable(sala)
	var deco := grupo(raiz, "Decorado")
	# La carpeta, sobre el borde del escritorio, iluminada.
	caja(deco, "Carpeta", Vector3(8.0, 4.33, -44.2), Vector3(0.9, 0.06, 0.65), material("", Color(0.55, 0.42, 0.28)), false)
	lamina(deco, "PapelesCarpeta", TEX_PAPEL, Vector3(8.05, 4.37, -44.2), Vector2(0.8, 0.55), Vector3(-90, 8, 0), 0.0)
	# Muro de pantallas encendido: el contraluz de la silueta de El Director.
	lamina(deco, "PantallasEncendidas", ESC + "nucleo_pantalla_crt.png", Vector3(8.0, 4.95, -49.3), Vector2(13.4, 2.9),
			Vector3.ZERO, 0.0, 3.0)
	hornear()

	finalizar("res://niveles/final/final.gd", {
		"id": &"final", "epoca": 0, "superficie_pasos": &"baldosa",
		"ambiente": &"nucleo_drone", "volumen_ambiente": -6.0, "capa_ambiente": &"pantallas_estatica",
		"volumen_capa": -18.0,
	})
	var l := grupo(raiz, "Luces")
	for k in 6:
		var z := -6.0 - k * 7.0
		omni(l, "LamparaO%d" % k, Vector3(2.4, 4.0, z), Color(1.0, 0.78, 0.55), 2.6, 9.0)
		omni(l, "LamparaE%d" % k, Vector3(13.6, 4.0, z), Color(1.0, 0.78, 0.55), 2.6, 9.0)
	omni(l, "Pantallas", Vector3(8.0, 6.0, -48.6), Color(0.75, 0.85, 1.0), 9.0, 24.0)
	foco(l, "Contraluz", Vector3(8.0, 14.0, -49.8), Vector3(8.0, 6.0, -44.0), Color(0.8, 0.85, 1.0), 10.0, 22.0, 40.0, true)
	omni(l, "Tarima", Vector3(8.0, 3.2, -39.5), Color(0.9, 0.6, 0.45), 2.0, 9.0)
	foco(l, "Carpeta", Vector3(8.0, 9.0, -41.0), Vector3(8.0, 4.3, -44.2), Color(1.0, 0.85, 0.6), 4.0, 8.0, 18.0, true)
	foco(l, "Alfombra", Vector3(8.0, 12.0, -20.0), Vector3(8.0, 0.0, -24.0), Color(0.9, 0.7, 0.55), 2.0, 16.0, 50.0, false)
	var f := grupo(raiz, "Figuras")
	figura(f, "Director", "el_director", Vector3(8.0, 2.5, -48.0), 180.0, &"quieto", -1.0, 4.6)
	var c := grupo(raiz, "Camaras")
	camara(c, "Entrada", Vector3(8.6, 1.0, -0.8), Vector3(8.0, 6.0, -48.0), 50.0)
	camara(c, "Director", Vector3(7.2, 0.5, -36.0), Vector3(8.0, 10.0, -47.0), 45.0)
	camara(c, "Elias", Vector3(8.6, 1.7, -35.2), Vector3(8.0, 1.6, -33.8), 34.0)
	camara(c, "Carpeta", Vector3(8.0, 5.2, -42.4), Vector3(8.0, 4.3, -44.2), 40.0)
	camara(c, "Escala", Vector3(13.5, 1.2, -30.0), Vector3(8.0, 6.0, -46.0), 55.0)
	camara(c, "Cenital", Vector3(8.0, 16.0, -33.0), Vector3(8.0, 0.0, -33.9), 50.0)
	var z := grupo(raiz, "Zonas")
	zona_camara(z, "ZonaSalon", Vector3(8.0, 3.0, -20.0), Vector3(16.0, 6.0, 40.0), 2.6, 1.6, 0.35, 62.0, 1)
	disparador(z, "Voz1", Vector3(8.0, 1.5, -12.0), Vector3(16.0, 3.0, 1.0), &"voz_inicio", true)
	disparador(z, "Escena", Vector3(8.0, 1.5, -33.5), Vector3(16.0, 3.0, 1.0), &"escena_final", true)
	var e := grupo(raiz, "Entradas")
	punto_entrada(e, &"inicio", Vector3(8.0, 0, -2.0), 0.0)
	jugador(Vector3(8.0, 0, -2.0))
	return guardar("res://niveles/final/final.tscn")
