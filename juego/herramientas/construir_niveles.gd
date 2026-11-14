extends SceneTree
## Genera los niveles de la demo (niveles/<id>/<id>.tscn) a partir de los escenarios de
## Blender y de los componentes. Uso:
##   Godot --headless --path juego --script res://herramientas/construir_niveles.gd            # todos
##   Godot --headless --path juego --script res://herramientas/construir_niveles.gd -- cap1 f1 # algunos
## ¡Sobrescribe los .tscn! Si se han retocado niveles a mano en el editor, no volver a
## generarlos (o copiar antes los cambios).

const NIVELES := ["cap1", "f1", "cap2", "f2", "cap3", "f3", "cap4", "final", "menu"]

var _hecho := false


func _process(_delta: float) -> bool:
	if _hecho:
		return true
	_hecho = true
	var pedidos := OS.get_cmdline_user_args()
	var errores := 0
	for id in NIVELES:
		if not pedidos.is_empty() and not pedidos.has(id):
			continue
		var ruta := "res://herramientas/niveles/construir_%s.gd" % id
		if not ResourceLoader.exists(ruta):
			print("(sin constructor: %s)" % id)
			continue
		print("== Construyendo ", id)
		var c: Constructor = load(ruta).new()
		c.arbol = self
		if c.call(&"construir") != OK:
			errores += 1
	print("Terminado. Errores: ", errores)
	return true
