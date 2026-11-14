@tool
extends Control
## Marcas de conteo (grupos de cuatro rayas y una diagonal), parte del logotipo (L2).

@export var grupos := 6
@export var color := Color(0.78, 0.75, 0.68)
@export var grosor := 3.0


func _draw() -> void:
	var alto := size.y
	var ancho_grupo := size.x / maxf(grupos, 1)
	for g in grupos:
		var x0 := g * ancho_grupo + ancho_grupo * 0.12
		var paso := ancho_grupo * 0.15
		for k in 4:
			var x := x0 + k * paso
			var temblor := sin(float(g * 7 + k) * 1.7) * 2.0
			draw_line(Vector2(x + temblor, alto * 0.08), Vector2(x - temblor * 0.5, alto * 0.92), color, grosor)
		draw_line(Vector2(x0 - paso * 0.5, alto * 0.78), Vector2(x0 + paso * 3.6, alto * 0.2), color, grosor)
