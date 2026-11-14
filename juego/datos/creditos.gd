class_name Creditos
extends RefCounted
## Textos de la pantalla «Créditos y licencias» (Q3) y de los créditos finales (C-20).
## Las atribuciones de terceros se añaden aquí EXACTAMENTE como las pida cada licencia
## (ver Materiales/recursos_y_creditos.md). A día de hoy no hay recursos de terceros.

const NOMBRES := ["Oziel Rodman Ramos Torrez", "Christopher Barea Salazar"]

const TEXTO := """[center][font_size=34]LIFETIME SENTENCE — Demo[/font_size]
GUILD Game Jam 2026 · «Al otro lado de la ley»[/center]

[b]CREADO POR[/b]
Oziel Rodman Ramos Torrez
Christopher Barea Salazar

[b]DECLARACIÓN DE USO DE INTELIGENCIA ARTIFICIAL[/b]
Este juego se ha desarrollado con asistencia de inteligencia artificial:
· [b]Claude (Anthropic)[/b], mediante Claude Code: programación (GDScript), shaders, montaje de niveles, modelos 3D, texturas, animaciones, sonido procedural, textos y documentación, bajo la dirección del equipo.
· [b]ChatGPT (OpenAI)[/b]: arte conceptual de referencia. Algunos recortes de esas imágenes se usan directamente como material (el cartel «SE BUSCA» y muestras de tela y piel).
El concepto, la historia, la dirección y las decisiones de diseño son del equipo.

[b]HERRAMIENTAS[/b]
Godot Engine 4.7 (licencia MIT) · Blender 5.2 · Python (numpy, Pillow).
Todos los modelos, texturas, animaciones y sonidos se han creado para este proyecto.
No se usan recursos de terceros. Las tipografías son las del sistema operativo (no se distribuyen con el juego).

[b]AVISO DE LICENCIA DE GODOT ENGINE[/b]
"""


## Texto completo, con el aviso de Godot y de sus componentes de terceros.
static func texto_completo() -> String:
	var t := TEXTO
	t += "This game uses Godot Engine, available under the following license:\n\n"
	t += Engine.get_license_text()
	t += "\n\n[b]Componentes de terceros incluidos en Godot Engine[/b]\n"
	for componente in Engine.get_copyright_info():
		var nombre: String = componente.get("name", "")
		var partes: Array = componente.get("parts", [])
		for parte in partes:
			var copias: PackedStringArray = parte.get("copyright", PackedStringArray())
			t += "· %s — %s (%s)\n" % [nombre, ", ".join(copias), parte.get("license", "")]
	return t
