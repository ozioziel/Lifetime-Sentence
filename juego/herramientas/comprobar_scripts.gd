extends SceneTree
## Comprueba que todos los scripts del proyecto compilan (herramienta de desarrollo).
##   Godot --headless --path juego --script res://herramientas/comprobar_scripts.gd


func _initialize() -> void:
	var fallos := 0
	var lista: PackedStringArray = []
	_buscar("res://", lista)
	for ruta in lista:
		var s := load(ruta) as Script
		if s == null or not s.can_instantiate():
			fallos += 1
			print("FALLO: ", ruta)
	print("Scripts comprobados: %d, con errores: %d" % [lista.size(), fallos])
	quit(1 if fallos > 0 else 0)


func _buscar(carpeta: String, lista: PackedStringArray) -> void:
	for sub in DirAccess.get_directories_at(carpeta):
		if sub.begins_with(".") or sub == "addons":
			continue
		_buscar(carpeta.path_join(sub), lista)
	for archivo in DirAccess.get_files_at(carpeta):
		if archivo.ends_with(".gd"):
			lista.append(carpeta.path_join(archivo))
