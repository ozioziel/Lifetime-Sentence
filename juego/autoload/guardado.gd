extends Node
## Partidas guardadas (autoload «Guardado»).
##
## Tres ranuras en user://partida_1.json ... partida_3.json (decisión W2). Se guarda en
## las paredes con marcas de conteo (componente ParedMarcas). Al morir se carga la última.
## Cada archivo es un JSON legible con el estado que entrega Juego.datos_partida().

const RANURAS := 3
const PLANTILLA := "user://partida_%d.json"


func ruta(ranura: int) -> String:
	return PLANTILLA % ranura


func guardar(ranura: int, datos: Dictionary) -> bool:
	var copia := datos.duplicate(true)
	copia["guardado_unix"] = Time.get_unix_time_from_system()
	copia["guardado_texto"] = Time.get_datetime_string_from_system(false, true)
	var archivo := FileAccess.open(ruta(ranura), FileAccess.WRITE)
	if archivo == null:
		push_warning("Guardado: no se pudo escribir la ranura %d" % ranura)
		return false
	archivo.store_string(JSON.stringify(copia, "\t"))
	return true


func cargar(ranura: int) -> Dictionary:
	if not FileAccess.file_exists(ruta(ranura)):
		return {}
	var texto := FileAccess.get_file_as_string(ruta(ranura))
	var datos: Variant = JSON.parse_string(texto)
	return datos if datos is Dictionary else {}


func existe(ranura: int) -> bool:
	return FileAccess.file_exists(ruta(ranura))


func hay_alguna() -> bool:
	for i in range(1, RANURAS + 1):
		if existe(i):
			return true
	return false


## Ranura guardada más reciente (0 si no hay ninguna).
func mas_reciente() -> int:
	var mejor := 0
	var fecha := -1.0
	for i in range(1, RANURAS + 1):
		var datos := cargar(i)
		if datos.is_empty():
			continue
		var t: float = datos.get("guardado_unix", 0.0)
		if t > fecha:
			fecha = t
			mejor = i
	return mejor


## Texto corto para los menús: «Cap. II — Patio Central · 14/11 21:05».
func descripcion(ranura: int) -> String:
	var datos := cargar(ranura)
	if datos.is_empty():
		return "— vacía —"
	return "%s  ·  %s" % [datos.get("lugar", "?"), String(datos.get("guardado_texto", "")).replace("T", " ")]
