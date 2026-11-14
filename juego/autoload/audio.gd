extends Node
## Director de sonido (autoload «Audio»).
##
## Buses: Master > Musica, Ambiente, Efectos, Voces. Los sonidos están en
## res://assets/audio/<nombre>.ogg (o .wav) y se piden por su nombre:
##     Audio.ambiente(&"lluvia", -6.0, 2.0)      # bucle de fondo, con fundido de 2 s
##     Audio.efecto(&"cerradura")                 # sonido sin posición
##     Audio.efecto_3d(&"pasos_metal", posicion)  # sonido en un punto del mundo
##     Audio.silencio_absoluto()                  # corte seco (transición pasado → presente)
## Si falta un archivo, se avisa en la consola y el juego sigue sin ese sonido.

const CARPETA := "res://assets/audio/"
const BUSES := ["Musica", "Ambiente", "Efectos", "Voces"]

var _cache := {}
var _ambiente_a: AudioStreamPlayer
var _ambiente_b: AudioStreamPlayer
var _musica: AudioStreamPlayer
var _capas := {}
var _efectos: Array[AudioStreamPlayer] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for nombre in BUSES:
		if AudioServer.get_bus_index(nombre) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, nombre)
			AudioServer.set_bus_send(i, &"Master")
	# Reverberación suave en ambiente y efectos: espacios de hormigón.
	var reverb := AudioEffectReverb.new()
	reverb.room_size = 0.7
	reverb.damping = 0.4
	reverb.wet = 0.18
	reverb.dry = 0.9
	AudioServer.add_bus_effect(AudioServer.get_bus_index(&"Efectos"), reverb)
	_ambiente_a = _crear_reproductor(&"Ambiente")
	_ambiente_b = _crear_reproductor(&"Ambiente")
	_musica = _crear_reproductor(&"Musica")
	for i in 12:
		_efectos.append(_crear_reproductor(&"Efectos"))
	# Los buses ya existen: aplica sus volúmenes guardados.
	Settings.aplicar()


func _crear_reproductor(bus: StringName) -> AudioStreamPlayer:
	var r := AudioStreamPlayer.new()
	r.bus = bus
	add_child(r)
	return r


## Devuelve el sonido por su nombre (o null si no existe).
func cargar(nombre: StringName) -> AudioStream:
	if _cache.has(nombre):
		return _cache[nombre]
	var flujo: AudioStream = null
	for extension: String in [".ogg", ".wav"]:
		var ruta := CARPETA + String(nombre) + extension
		if ResourceLoader.exists(ruta):
			flujo = load(ruta)
			break
	if flujo == null:
		push_warning("Audio: falta el sonido «%s»" % nombre)
	_cache[nombre] = flujo
	return flujo


## Cambia el sonido de fondo con un fundido cruzado. nombre vacío = silencio.
func ambiente(nombre: StringName, volumen_db := 0.0, fundido := 1.5) -> void:
	var saliente := _ambiente_a if _ambiente_a.playing else _ambiente_b
	var entrante := _ambiente_b if saliente == _ambiente_a else _ambiente_a
	if saliente.playing and saliente.stream == cargar(nombre) and nombre != &"":
		return
	_fundir(saliente, -60.0, fundido, true)
	if nombre == &"":
		return
	var flujo := cargar(nombre)
	if flujo == null:
		return
	entrante.stream = flujo
	entrante.volume_db = -60.0
	entrante.play()
	_fundir(entrante, volumen_db, fundido, false)


## Capa de ambiente adicional con nombre propio (zumbido de una zona, latido, lluvia...).
func capa(clave: StringName, nombre: StringName, volumen_db := 0.0, fundido := 1.0) -> void:
	var r: AudioStreamPlayer = _capas.get(clave)
	if r == null:
		r = _crear_reproductor(&"Ambiente")
		_capas[clave] = r
	if nombre == &"":
		_fundir(r, -60.0, fundido, true)
		return
	var flujo := cargar(nombre)
	if flujo == null:
		return
	if r.stream != flujo or not r.playing:
		r.stream = flujo
		r.volume_db = -60.0
		r.play()
	_fundir(r, volumen_db, fundido, false)


func musica(nombre: StringName, volumen_db := -6.0, fundido := 2.0) -> void:
	if nombre == &"":
		_fundir(_musica, -60.0, fundido, true)
		return
	var flujo := cargar(nombre)
	if flujo == null:
		return
	if _musica.stream != flujo or not _musica.playing:
		_musica.stream = flujo
		_musica.volume_db = -60.0
		_musica.play()
	_fundir(_musica, volumen_db, fundido, false)


## Sonido sin posición (interfaz, golpes de cinemática, respiración...).
func efecto(nombre: StringName, volumen_db := 0.0, tono := 1.0, bus := &"Efectos") -> AudioStreamPlayer:
	var flujo := cargar(nombre)
	if flujo == null:
		return null
	var r := _efectos[0]
	for candidato in _efectos:
		if not candidato.playing:
			r = candidato
			break
	r.bus = bus
	r.stream = flujo
	r.volume_db = volumen_db
	r.pitch_scale = tono
	r.play()
	return r


## Sonido en un punto del mundo. Se borra solo al terminar (si no es un bucle).
func efecto_3d(nombre: StringName, posicion: Vector3, volumen_db := 0.0, alcance := 25.0,
		tono := 1.0) -> AudioStreamPlayer3D:
	var flujo := cargar(nombre)
	var escena := get_tree().current_scene
	if flujo == null or escena == null:
		return null
	var r := AudioStreamPlayer3D.new()
	r.stream = flujo
	r.bus = &"Efectos"
	r.volume_db = volumen_db
	r.max_distance = alcance
	r.unit_size = 3.0
	r.pitch_scale = tono
	r.attenuation_filter_cutoff_hz = 6000.0
	escena.add_child(r)
	r.global_position = posicion
	r.play()
	r.finished.connect(r.queue_free)
	return r


## Emisor 3D que sigue a un nodo (llaves de El Uniforme, motor de un foco...). Devuelve el emisor.
func emisor(nodo: Node3D, nombre: StringName, volumen_db := 0.0, alcance := 20.0) -> AudioStreamPlayer3D:
	var flujo := cargar(nombre)
	var r := AudioStreamPlayer3D.new()
	r.stream = flujo
	r.bus = &"Efectos"
	r.volume_db = volumen_db
	r.max_distance = alcance
	r.unit_size = 3.0
	r.autoplay = flujo != null
	nodo.add_child(r)
	return r


## Corte seco a silencio absoluto (decisión D6). volver_en = segundos hasta recuperar el volumen.
func silencio_absoluto(volver_en := 1.5) -> void:
	for r in [_ambiente_a, _ambiente_b, _musica]:
		r.stop()
	for r in _capas.values():
		(r as AudioStreamPlayer).stop()
	for r in _efectos:
		r.stop()
	var master := AudioServer.get_bus_index(&"Master")
	AudioServer.set_bus_mute(master, true)
	await get_tree().create_timer(volver_en, true, false, true).timeout
	AudioServer.set_bus_mute(master, false)


## Para todo (al volver al menú, por ejemplo).
func parar_todo(fundido := 0.8) -> void:
	_fundir(_ambiente_a, -60.0, fundido, true)
	_fundir(_ambiente_b, -60.0, fundido, true)
	_fundir(_musica, -60.0, fundido, true)
	for r in _capas.values():
		_fundir(r, -60.0, fundido, true)


func _fundir(r: AudioStreamPlayer, volumen_db: float, duracion: float, parar_al_final: bool) -> void:
	if not r.playing and parar_al_final:
		return
	var tween := create_tween()
	tween.tween_property(r, "volume_db", volumen_db, maxf(duracion, 0.01))
	if parar_al_final:
		tween.tween_callback(r.stop)
