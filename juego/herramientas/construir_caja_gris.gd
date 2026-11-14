extends SceneTree
## Construye la escena de prueba «caja gris» (etapa 1, bloque 1.1).
##
## Genera niveles/pruebas/caja_gris.tscn: una celda de 2 x 3 m, un pasillo de
## 1,6 m de ancho con un recodo en L, rejas, luces fluorescentes, zonas de
## cámara, puntos de captura y una ruta para medir el rendimiento.
##
## Es una herramienta de arranque. Una vez generada, la escena se edita con
## normalidad en el editor (las paredes son cajas CSG que se pueden mover y
## redimensionar). ATENCIÓN: volver a ejecutarla sobrescribe la escena.
##
##   Godot --headless --path juego --script res://herramientas/construir_caja_gris.gd

const ALTO := 2.4
const CELDAS := 7
const CELDA_JUGADOR := 2
const RUTA_ESCENA := "res://niveles/pruebas/caja_gris.tscn"
const DIR_MODELOS := "res://assets/modelos/provisional/"
const DIR_MATERIALES := "res://assets/materiales/provisional/"

var _raiz: Node3D
var _pared: Material
var _suelo: Material
var _techo: Material
var _metal_oxidado: Material
var _metal_pintado: Material


# Se construye en _initialize() y no en _init(): aquí ya existen los autoloads
# (Settings, RenderRig), que los scripts de los componentes necesitan para compilar.
func _initialize() -> void:
	_pared = load(DIR_MATERIALES + "pared_celda.tres")
	_suelo = load(DIR_MATERIALES + "suelo.tres")
	_techo = load(DIR_MATERIALES + "techo.tres")
	_metal_oxidado = load(DIR_MATERIALES + "metal_oxidado.tres")
	_metal_pintado = load(DIR_MATERIALES + "metal_pintado.tres")

	_raiz = Node3D.new()
	_raiz.name = "CajaGris"
	_crear_entorno()
	_crear_geometria()
	_crear_rejas()
	_crear_luces()
	_crear_zonas()
	_crear_jugador()
	_crear_puntos_captura()
	_crear_ruta()

	var escena := PackedScene.new()
	var err := escena.pack(_raiz)
	if err == OK:
		err = ResourceSaver.save(escena, RUTA_ESCENA)
	print("caja_gris.tscn: ", error_string(err))
	_raiz.free()
	quit()


## Añade un nodo y lo marca como parte de la escena (para que se guarde).
func _colgar(nodo: Node, padre: Node) -> void:
	padre.add_child(nodo)
	nodo.owner = _raiz


func _grupo(nombre: String) -> Node3D:
	var nodo := Node3D.new()
	nodo.name = nombre
	_colgar(nodo, _raiz)
	return nodo


# ------------------------------------------------------------------ Entorno ---

func _crear_entorno() -> void:
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color.BLACK
	# Luz ambiente muy baja y fría: la oscuridad es real, pero se distingue el camino.
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.36, 0.47, 0.55)
	entorno.ambient_light_energy = 0.22
	entorno.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	# Niebla por distancia, como en la PS1: oculta el fondo y da frío.
	entorno.fog_enabled = true
	entorno.fog_mode = Environment.FOG_MODE_DEPTH
	entorno.fog_light_color = Color(0.06, 0.09, 0.11)
	entorno.fog_density = 1.0
	entorno.fog_depth_begin = 2.0
	entorno.fog_depth_end = 20.0
	# Brillo y niebla volumétrica: aquí solo se ajustan sus valores. Quien los
	# enciende es RenderRig, según la calidad gráfica (solo en ALTA).
	entorno.glow_intensity = 0.7
	entorno.glow_bloom = 0.08
	entorno.volumetric_fog_density = 0.035
	entorno.volumetric_fog_albedo = Color(0.75, 0.85, 0.9)
	entorno.volumetric_fog_length = 24.0

	var nodo := WorldEnvironment.new()
	nodo.name = "Entorno"
	nodo.environment = entorno
	_colgar(nodo, _raiz)


# ---------------------------------------------------------------- Geometría ---

func _crear_geometria() -> void:
	var geo := CSGCombiner3D.new()
	geo.name = "Geometria"
	geo.use_collision = true
	geo.collision_layer = 1
	geo.collision_mask = 0
	_colgar(geo, _raiz)

	var largo := CELDAS * 2.0  # Longitud del pasillo A: 14 m.

	_caja(geo, "Suelo", Vector3(-0.2, -0.2, -3.2), Vector3(largo + 1.8, 0.0, 11.8), _suelo)
	_caja(geo, "TechoCeldasYPasilloA", Vector3(-0.2, ALTO, -3.2),
			Vector3(largo + 1.8, ALTO + 0.2, 1.8), _techo)
	_caja(geo, "TechoPasilloB", Vector3(largo - 0.2, ALTO, 1.8),
			Vector3(largo + 1.8, ALTO + 0.2, 11.8), _techo)

	# Celdas: muro del fondo y tabiques entre celdas.
	_caja(geo, "MuroFondoCeldas", Vector3(-0.2, 0.0, -3.2), Vector3(largo + 0.1, ALTO, -3.0), _pared)
	for i in CELDAS + 1:
		var x := i * 2.0
		_caja(geo, "Tabique%d" % i, Vector3(x - 0.1, 0.0, -3.0), Vector3(x + 0.1, ALTO, 0.0), _pared)

	# Pasillo A (a lo largo del eje X).
	_caja(geo, "MuroOestePasilloA", Vector3(-0.2, 0.0, 0.0), Vector3(0.0, ALTO, 1.8), _pared)
	_caja(geo, "MuroSurPasilloA", Vector3(0.0, 0.0, 1.6), Vector3(largo - 0.2, ALTO, 1.8), _pared)

	# Recodo y pasillo B (a lo largo del eje Z).
	_caja(geo, "MuroNorteRecodo", Vector3(largo + 0.1, 0.0, -0.2),
			Vector3(largo + 1.8, ALTO, 0.0), _pared)
	_caja(geo, "MuroEste", Vector3(largo + 1.6, 0.0, 0.0), Vector3(largo + 1.8, ALTO, 11.8), _pared)
	_caja(geo, "MuroOestePasilloB", Vector3(largo - 0.2, 0.0, 1.6),
			Vector3(largo, ALTO, 11.6), _pared)
	_caja(geo, "MuroFondoPasilloB", Vector3(largo - 0.2, 0.0, 11.6),
			Vector3(largo + 1.6, ALTO, 11.8), _pared)

	# Paso bajo: obliga a agacharse (hueco de 1,25 m).
	_caja(geo, "ConductoCaido", Vector3(largo, 1.25, 6.0), Vector3(largo + 1.6, ALTO, 8.0),
			_metal_pintado)


## Caja CSG definida por dos esquinas opuestas.
func _caja(padre: Node, nombre: String, minimo: Vector3, maximo: Vector3,
		material: Material) -> void:
	var caja := CSGBox3D.new()
	caja.name = nombre
	caja.size = maximo - minimo
	caja.position = (minimo + maximo) * 0.5
	caja.material = material
	_colgar(caja, padre)


# -------------------------------------------------------------------- Rejas ---

func _crear_rejas() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_MODELOS))
	var rejas := _grupo("Rejas")
	var malla_completa := _guardar_malla(_malla_reja(1.8, false), "reja_1m8.tres")
	var malla_fija := _guardar_malla(_malla_reja(1.0, false), "reja_1m0.tres")
	var malla_puerta := _guardar_malla(_malla_reja(0.8, true), "puerta_reja_0m8.tres")

	for i in CELDAS:
		var x := i * 2.0
		if i != CELDA_JUGADOR:
			_reja(rejas, "Reja%d" % i, malla_completa, Vector3(x + 1.0, 0.0, 0.0), 1.8)
			continue
		# Celda del jugador: hueco de puerta de 0,8 m y la puerta abierta del todo.
		_reja(rejas, "RejaFija%d" % i, malla_fija, Vector3(x + 1.4, 0.0, 0.0), 1.0)
		var puerta := MeshInstance3D.new()
		puerta.name = "PuertaAbierta"
		puerta.mesh = malla_puerta
		puerta.position = Vector3(x + 0.9, 0.0, 0.04)
		puerta.rotation_degrees = Vector3(0.0, 172.0, 0.0)
		_colgar(puerta, rejas)


func _reja(padre: Node, nombre: String, malla: Mesh, posicion: Vector3, ancho: float) -> void:
	var visual := MeshInstance3D.new()
	visual.name = nombre
	visual.mesh = malla
	visual.position = posicion
	_colgar(visual, padre)

	var cuerpo := StaticBody3D.new()
	cuerpo.name = "Colision"
	cuerpo.collision_layer = 1
	cuerpo.collision_mask = 0
	_colgar(cuerpo, visual)
	var forma := CollisionShape3D.new()
	forma.name = "Forma"
	var caja := BoxShape3D.new()
	caja.size = Vector3(ancho, ALTO, 0.08)
	forma.shape = caja
	forma.position = Vector3(0.0, ALTO * 0.5, 0.0)
	_colgar(forma, cuerpo)


## Reja de barrotes verticales con tres pletinas horizontales, en una sola malla.
func _malla_reja(ancho: float, origen_en_bisagra: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var inicio := -ancho if origen_en_bisagra else -ancho * 0.5
	var barrotes := int(round(ancho / 0.115))
	for i in barrotes + 1:
		var x := inicio + ancho * float(i) / float(barrotes)
		_st_caja(st, Vector3(x - 0.015, 0.0, -0.015), Vector3(x + 0.015, ALTO, 0.015))
	for y: float in [0.08, ALTO * 0.5, ALTO - 0.08]:
		_st_caja(st, Vector3(inicio, y - 0.03, -0.025), Vector3(inicio + ancho, y + 0.03, 0.025))
	var malla := st.commit()
	malla.surface_set_material(0, _metal_oxidado)
	return malla


func _st_caja(st: SurfaceTool, a: Vector3, b: Vector3) -> void:
	var p := [
		Vector3(a.x, a.y, a.z), Vector3(b.x, a.y, a.z), Vector3(b.x, b.y, a.z), Vector3(a.x, b.y, a.z),
		Vector3(a.x, a.y, b.z), Vector3(b.x, a.y, b.z), Vector3(b.x, b.y, b.z), Vector3(a.x, b.y, b.z),
	]
	_st_cara(st, p[0], p[1], p[2], p[3], Vector3.FORWARD)   # -Z
	_st_cara(st, p[4], p[5], p[6], p[7], Vector3.BACK)      # +Z
	_st_cara(st, p[0], p[3], p[7], p[4], Vector3.LEFT)      # -X
	_st_cara(st, p[1], p[2], p[6], p[5], Vector3.RIGHT)     # +X
	_st_cara(st, p[0], p[1], p[5], p[4], Vector3.DOWN)      # -Y
	_st_cara(st, p[3], p[2], p[6], p[7], Vector3.UP)        # +Y


## Añade un cuadrilátero con la normal indicada, corrigiendo el orden de los
## vértices para que la cara visible sea la de la normal (Godot: sentido horario).
func _st_cara(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		normal: Vector3) -> void:
	if (b - a).cross(c - a).dot(normal) > 0.0:
		var temporal := b
		b = d
		d = temporal
	for vertice: Vector3 in [a, b, c, a, c, d]:
		st.set_normal(normal)
		st.set_uv(Vector2.ZERO)
		st.add_vertex(vertice)


func _guardar_malla(malla: Mesh, nombre: String) -> Mesh:
	var ruta := DIR_MODELOS + nombre
	var err := ResourceSaver.save(malla, ruta)
	if err != OK:
		push_error("No se pudo guardar %s: %s" % [ruta, error_string(err)])
		return malla
	return load(ruta)


# -------------------------------------------------------------------- Luces ---

func _crear_luces() -> void:
	var luces := _grupo("Luces")
	var escena: PackedScene = load("res://componentes/luz_fluorescente.tscn")
	# Estado: 0 estable, 1 parpadeo leve, 2 averiada (ver LuzFluorescente.Estado).
	# [nombre, posición, giro en Y, estado, sombras en calidad baja]
	var datos := [
		["LuzCelda", Vector3(5.0, ALTO, -1.5), 90.0, 1, true],
		["LuzPasilloA1", Vector3(2.5, ALTO, 0.8), 0.0, 2, false],
		["LuzPasilloA2", Vector3(8.0, ALTO, 0.8), 0.0, 0, true],
		["LuzPasilloA3", Vector3(12.5, ALTO, 0.8), 0.0, 1, false],
		["LuzPasilloB1", Vector3(14.8, ALTO, 4.0), 90.0, 0, false],
		["LuzPasilloB2", Vector3(14.8, ALTO, 10.0), 90.0, 2, false],
	]
	for dato: Array in datos:
		var luz: Node3D = escena.instantiate()
		luz.name = dato[0]
		luz.position = dato[1]
		luz.rotation_degrees = Vector3(0.0, dato[2], 0.0)
		luz.set(&"estado", dato[3])
		luz.set(&"sombras_en_calidad_baja", dato[4])
		_colgar(luz, luces)


# ----------------------------------------------------------- Zonas de cámara ---

func _crear_zonas() -> void:
	var zonas := _grupo("ZonasCamara")
	var escena: PackedScene = load("res://componentes/camera_zone.tscn")
	# [nombre, centro, tamaño, distancia, altura, lateral, fov, prioridad]
	var datos := [
		["ZonaCelda", Vector3(5.0, 1.2, -1.5), Vector3(2.0, 2.4, 3.0), 1.15, 1.45, 0.28, 70.0, 1],
		["ZonaPasilloA", Vector3(7.0, 1.2, 0.8), Vector3(14.2, 2.4, 1.6), 1.55, 1.5, 0.34, 64.0, 0],
		["ZonaPasilloB", Vector3(14.8, 1.2, 5.8), Vector3(1.6, 2.4, 11.8), 1.55, 1.5, 0.34, 64.0, 0],
		["ZonaPasoBajo", Vector3(14.8, 0.7, 7.0), Vector3(1.6, 1.4, 2.6), 1.0, 1.2, 0.2, 68.0, 2],
	]
	for dato: Array in datos:
		var zona: Node3D = escena.instantiate()
		zona.name = dato[0]
		zona.position = dato[1]
		zona.set(&"tamano", dato[2])
		zona.set(&"distancia", dato[3])
		zona.set(&"altura", dato[4])
		zona.set(&"desplazamiento_lateral", dato[5])
		zona.set(&"fov", dato[6])
		zona.set(&"prioridad", dato[7])
		_colgar(zona, zonas)


# ------------------------------------------------------------------ Jugador ---

func _crear_jugador() -> void:
	var jugador: Node3D = load("res://jugador/jugador.tscn").instantiate()
	jugador.name = "Jugador"
	jugador.position = Vector3(5.0, 0.02, -1.6)
	jugador.set(&"orientacion_inicial", 180.0)  # Mirando hacia la puerta de la celda.
	_colgar(jugador, _raiz)


# ---------------------------------------------------- Puntos de captura y ruta ---

## Puntos donde las herramientas de prueba colocan al jugador para hacer capturas.
## La rotación indica hacia dónde mira la cámara.
func _crear_puntos_captura() -> void:
	var puntos := _grupo("PuntosCaptura")
	# [nombre, posición del jugador, giro (yaw), inclinación (pitch), agachado]
	var datos := [
		["Captura_1_celda", Vector3(5.0, 0.0, -1.3), PI, -0.08, false],
		["Captura_2_pasillo", Vector3(6.5, 0.0, 0.8), -PI * 0.5, -0.06, false],
		["Captura_3_rejas", Vector3(9.0, 0.0, 0.75), 0.9, -0.04, false],
		["Captura_4_recodo", Vector3(14.8, 0.0, 1.0), PI, -0.05, false],
		["Captura_5_agachado", Vector3(14.8, 0.0, 6.6), PI, 0.0, true],
	]
	for dato: Array in datos:
		var punto := Marker3D.new()
		punto.name = dato[0]
		punto.position = dato[1]
		punto.rotation = Vector3(dato[3], dato[2], 0.0)
		if dato[4]:
			punto.set_meta(&"agachado", true)
		_colgar(punto, puntos)
		punto.add_to_group(&"punto_captura", true)


## Recorrido de cámara para medir el rendimiento (grupo «ruta_benchmark»).
func _crear_ruta() -> void:
	var puntos: Array[Vector3] = [
		Vector3(4.5, 1.5, -2.2), Vector3(4.5, 1.5, 0.4), Vector3(6.5, 1.5, 0.9),
		Vector3(13.0, 1.5, 0.8), Vector3(14.6, 1.5, 1.2), Vector3(14.8, 1.5, 4.5),
		Vector3(14.8, 0.95, 6.2), Vector3(14.8, 0.95, 7.8), Vector3(14.8, 1.5, 9.2),
		Vector3(14.8, 1.5, 10.8),
	]
	var curva := Curve3D.new()
	for i in puntos.size():
		# Tiradores suaves para que la cámara no gire a saltos.
		var tirador := Vector3.ZERO
		if i > 0 and i < puntos.size() - 1:
			tirador = (puntos[i + 1] - puntos[i - 1]) * 0.2
		curva.add_point(puntos[i], -tirador, tirador)
	var ruta := Path3D.new()
	ruta.name = "RutaBenchmark"
	ruta.curve = curva
	_colgar(ruta, _raiz)
	ruta.add_to_group(&"ruta_benchmark", true)
