class_name PerfilEpoca
extends Resource
## Aspecto visual de una época (PRESENTE o PASADO).
##
## Cada perfil es un archivo .tres que se edita desde el Inspector. RenderRig
## lo aplica con [code]RenderRig.aplicar_epoca(perfil, duracion)[/code].

@export var nombre := "presente"

@export_group("Color")
## Tinte de las zonas oscuras. Gris medio (0.5, 0.5, 0.5) = sin cambio.
@export var tinte_sombras := Color(0.5, 0.5, 0.5)
## Tinte de las zonas claras. Gris medio = sin cambio.
@export var tinte_luces := Color(0.5, 0.5, 0.5)
@export_range(0.0, 2.0, 0.01) var saturacion := 1.0
@export_range(0.5, 2.0, 0.01) var contraste := 1.0
@export_range(-0.2, 0.2, 0.005) var brillo := 0.0

@export_group("PS1")
## Niveles de color por canal. 31 = PS1 (15 bits). 255 = sin reducción.
@export_range(2.0, 255.0, 1.0) var niveles_color := 31.0
@export_range(0.0, 2.0, 0.05) var fuerza_dither := 1.0
@export_range(0.0, 0.3, 0.005) var grano := 0.05
@export_range(0.0, 1.0, 0.01) var vineta := 0.4


## Devuelve los valores con los nombres de los parámetros del shader de posproceso.
func a_parametros() -> Dictionary:
	return {
		&"tinte_sombras": tinte_sombras,
		&"tinte_luces": tinte_luces,
		&"saturacion": saturacion,
		&"contraste": contraste,
		&"brillo": brillo,
		&"niveles_color": niveles_color,
		&"fuerza_dither": fuerza_dither,
		&"grano": grano,
		&"vineta": vineta,
	}
