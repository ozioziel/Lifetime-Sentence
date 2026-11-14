extends SceneTree
## Configura project.godot: ventana, render, física, capas, controles y autoloads.
##
## Es una herramienta de arranque. Después de ejecutarla, todo se puede cambiar
## con normalidad desde el editor (Proyecto > Configuración del proyecto).
## Solo hace falta volver a ejecutarla si se quiere restaurar esta configuración:
##
##   Godot --headless --path juego --script res://herramientas/configurar_proyecto.gd
##
## Atención: sobrescribe los controles y ajustes que aquí se definen.


func _init() -> void:
	_aplicacion()
	_pantalla()
	_render()
	_fisica()
	_capas()
	_controles()
	_autoloads()
	var err := ProjectSettings.save()
	print("project.godot guardado: ", error_string(err))
	quit()


func _poner(nombre: String, valor: Variant) -> void:
	ProjectSettings.set_setting(nombre, valor)


func _aplicacion() -> void:
	_poner("application/config/name", "Lifetime Sentence")
	_poner("application/config/description",
			"Demo de terror psicológico retro PS1. GUILD Game Jam 2026.")
	_poner("application/config/version", "1.0.0")
	_poner("application/run/main_scene", "res://ui/arranque.tscn")
	_poner("application/config/icon", "res://icono.png")
	_poner("application/boot_splash/bg_color", Color.BLACK)
	_poner("application/boot_splash/show_image", false)


func _pantalla() -> void:
	# La interfaz se diseña a 1280 x 720 y se adapta a cualquier ventana.
	# La imagen 3D NO usa esta resolución: se dibuja a 480 x 270 en RenderRig.
	_poner("display/window/size/viewport_width", 1280)
	_poner("display/window/size/viewport_height", 720)
	_poner("display/window/stretch/mode", "canvas_items")
	_poner("display/window/stretch/aspect", "expand")
	_poner("display/window/vsync/vsync_mode", 1)


func _render() -> void:
	# Renderizador Forward+: elegido tras la prueba de rendimiento del bloque 1.1
	# (118 fps de media con calidad ALTA en una Intel HD 520). Es el único con
	# niebla volumétrica. Si el equipo no admite Vulkan ni Direct3D 12, Godot
	# pasa solo al renderizador Compatibility.
	_poner("rendering/renderer/rendering_method", "forward_plus")
	_poner("rendering/environment/defaults/default_clear_color", Color.BLACK)
	_poner("rendering/anti_aliasing/quality/msaa_3d", 0)
	# Sombras duras: más baratas y más propias de la época.
	_poner("rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality", 0)
	# Texturas pixeladas: sin compresión con pérdida ni mipmaps al importar.
	_poner("importer_defaults/texture", {
		"compress/mode": 0,
		"detect_3d/compress_to": 0,
		"mipmaps/generate": false,
	})
	# Parámetros globales de los shaders PS1 (los controla RenderRig).
	_poner("shader_globals/ps1_vibracion", {"type": "float", "value": 1.0})
	_poner("shader_globals/ps1_resolucion", {"type": "vec2", "value": Vector2(480, 270)})
	_poner("shader_globals/ps1_afin", {"type": "float", "value": 0.0})


func _fisica() -> void:
	_poner("physics/common/physics_ticks_per_second", 60)
	_poner("physics/common/physics_interpolation", true)


func _capas() -> void:
	var fisica := ["mundo", "jugador", "enemigos", "interactuables", "zonas", "bloqueo_vision"]
	for i in fisica.size():
		_poner("layer_names/3d_physics/layer_%d" % (i + 1), fisica[i])
	_poner("layer_names/3d_render/layer_1", "general")
	# Capa 11: lo que solo se ve en los espejos (El Condenado, capítulo III).
	_poner("layer_names/3d_render/layer_11", "solo_espejo")


func _controles() -> void:
	_accion("mover_adelante", [_tecla(KEY_W), _tecla(KEY_UP), _eje(JOY_AXIS_LEFT_Y, -1.0)], 0.25)
	_accion("mover_atras", [_tecla(KEY_S), _tecla(KEY_DOWN), _eje(JOY_AXIS_LEFT_Y, 1.0)], 0.25)
	_accion("mover_izquierda", [_tecla(KEY_A), _tecla(KEY_LEFT), _eje(JOY_AXIS_LEFT_X, -1.0)], 0.25)
	_accion("mover_derecha", [_tecla(KEY_D), _tecla(KEY_RIGHT), _eje(JOY_AXIS_LEFT_X, 1.0)], 0.25)
	_accion("mirar_arriba", [_eje(JOY_AXIS_RIGHT_Y, -1.0)], 0.2)
	_accion("mirar_abajo", [_eje(JOY_AXIS_RIGHT_Y, 1.0)], 0.2)
	_accion("mirar_izquierda", [_eje(JOY_AXIS_RIGHT_X, -1.0)], 0.2)
	_accion("mirar_derecha", [_eje(JOY_AXIS_RIGHT_X, 1.0)], 0.2)
	_accion("correr", [_tecla(KEY_SHIFT), _boton(JOY_BUTTON_RIGHT_SHOULDER),
			_boton(JOY_BUTTON_LEFT_STICK)])
	_accion("agacharse", [_tecla(KEY_C), _tecla(KEY_CTRL), _boton(JOY_BUTTON_B)])
	_accion("interactuar", [_tecla(KEY_E), _boton(JOY_BUTTON_A)])
	_accion("pausa", [_tecla(KEY_ESCAPE), _boton(JOY_BUTTON_START)])
	# Armas (§7.1) y objetos arrojadizos (K5).
	_accion("apuntar", [_raton(MOUSE_BUTTON_RIGHT), _eje(JOY_AXIS_TRIGGER_LEFT, 1.0)], 0.3)
	_accion("disparar", [_raton(MOUSE_BUTTON_LEFT), _eje(JOY_AXIS_TRIGGER_RIGHT, 1.0)], 0.3)
	_accion("recargar", [_tecla(KEY_R), _boton(JOY_BUTTON_X)])
	_accion("lanzar", [_tecla(KEY_G), _boton(JOY_BUTTON_Y)])


func _accion(nombre: String, eventos: Array, zona_muerta := 0.2) -> void:
	_poner("input/" + nombre, {"deadzone": zona_muerta, "events": eventos})


func _tecla(codigo: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.device = -1
	e.physical_keycode = codigo
	return e


func _boton(indice: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.device = -1
	e.button_index = indice
	return e


func _raton(boton_: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.device = -1
	e.button_index = boton_
	return e


func _eje(eje: JoyAxis, valor: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.device = -1
	e.axis = eje
	e.axis_value = valor
	return e


func _autoloads() -> void:
	# El orden importa: Settings debe existir antes que Audio y RenderRig.
	for nombre in ["Settings", "Audio", "RenderRig", "Juego", "Guardado", "Interfaz", "DebugTools"]:
		ProjectSettings.clear("autoload/" + nombre)
	_poner("autoload/Settings", "*res://autoload/settings.gd")
	_poner("autoload/Audio", "*res://autoload/audio.gd")
	_poner("autoload/RenderRig", "*res://render/render_rig.tscn")
	_poner("autoload/Juego", "*res://autoload/juego.gd")
	_poner("autoload/Guardado", "*res://autoload/guardado.gd")
	_poner("autoload/Interfaz", "*res://autoload/interfaz.gd")
	_poner("autoload/DebugTools", "*res://autoload/debug_tools.gd")
