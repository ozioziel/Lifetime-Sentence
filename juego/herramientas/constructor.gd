class_name Constructor
extends RefCounted
## Utilidades para montar niveles desde código (herramientas/niveles/*.gd).
##
## Los constructores generan los .tscn de niveles/<id>/. Después TODO se puede editar a
## mano en el editor de Godot (C-13): mover luces, cambiar textos, ajustar enemigos...
## Ojo: si se vuelve a ejecutar el constructor de un nivel, se sobrescribe su .tscn.

const SHADER_PS1 := preload("res://render/ps1_superficie.gdshader")
# Las escenas con scripts que usan autoloads se cargan al usarlas (no con preload): así
# compilan cuando los autoloads ya existen.
const JUGADOR := "res://jugador/jugador.tscn"
const FLUORESCENTE := "res://componentes/luz_fluorescente.tscn"
const ZONA_CAMARA := "res://componentes/camera_zone.tscn"

var raiz: Node3D
var arbol: SceneTree
var _materiales := {}


## Crea el nodo raíz del nivel (todavía sin script: primero se monta la geometría, se
## hornea la navegación y después se añaden el script y los componentes).
func nuevo_nivel(id: StringName) -> Node3D:
	raiz = Node3D.new()
	raiz.name = String(id)
	return raiz


## Pone el script del nivel y sus propiedades (después de hornear).
func finalizar(script: String, props := {}) -> void:
	raiz.set_script(load(script))
	for clave: String in props:
		raiz.set(clave, props[clave])


func poseer(nodo: Node) -> void:
	if nodo != raiz:
		nodo.owner = raiz


func agregar(padre: Node, nodo: Node, nombre: String) -> Node:
	nodo.name = nombre
	padre.add_child(nodo, true)
	poseer(nodo)
	return nodo


func grupo(padre: Node, nombre: String) -> Node3D:
	return agregar(padre, Node3D.new(), nombre) as Node3D


## Instancia una escena (.glb o .tscn).
func instancia(ruta: String, padre: Node, nombre: String, pos := Vector3.ZERO, rot_y := 0.0,
		escala := 1.0) -> Node3D:
	var n := (load(ruta) as PackedScene).instantiate() as Node3D
	n.name = nombre
	padre.add_child(n, true)
	n.owner = raiz
	n.position = pos
	n.rotation_degrees.y = rot_y
	n.scale = Vector3.ONE * escala
	return n


## Nodo con un script de componente y sus propiedades.
func componente(script: String, padre: Node, nombre: String, pos := Vector3.ZERO, rot_y := 0.0,
		props := {}, tipo := "Node3D") -> Node:
	var n: Node = ClassDB.instantiate(tipo)
	n.set_script(load(script))
	for clave: String in props:
		n.set(clave, props[clave])
	agregar(padre, n, nombre)
	if n is Node3D:
		(n as Node3D).position = pos
		(n as Node3D).rotation_degrees.y = rot_y
	return n


# --------------------------------------------------------------- Materiales ---

## Material PS1 con una textura (ruta res://) o solo color. triplanar: la textura se
## proyecta desde el mundo (repeticiones por metro = escala).
func material(textura: String, color := Color.WHITE, escala := 0.5, triplanar := true,
		emision := Color.BLACK, energia := 0.0) -> ShaderMaterial:
	var clave := "%s|%s|%s|%s|%s|%s" % [textura, color, escala, triplanar, emision, energia]
	if _materiales.has(clave):
		return _materiales[clave]
	var m := ShaderMaterial.new()
	m.shader = SHADER_PS1
	if textura != "":
		m.set_shader_parameter(&"textura", load(textura))
	m.set_shader_parameter(&"color", color)
	m.set_shader_parameter(&"triplanar", triplanar)
	m.set_shader_parameter(&"escala_uv", escala)
	m.set_shader_parameter(&"rugosidad", 0.9)
	m.set_shader_parameter(&"especular", 0.25)
	if energia > 0.0:
		m.set_shader_parameter(&"emision", Vector3(emision.r, emision.g, emision.b))
		m.set_shader_parameter(&"energia_emision", energia)
	_materiales[clave] = m
	return m


# ------------------------------------------------------------------ Geometría ---

## Caja visible con colisión opcional. centro = centro de la caja.
func caja(padre: Node, nombre: String, centro: Vector3, tamano: Vector3, mat: Material,
		colision := true, rot_y := 0.0, sombra := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = tamano
	malla.material = mat
	mi.mesh = malla
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if sombra else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	agregar(padre, mi, nombre)
	mi.position = centro
	mi.rotation_degrees.y = rot_y
	if colision:
		var cuerpo := StaticBody3D.new()
		agregar(mi, cuerpo, "Colision")
		var forma := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = tamano
		forma.shape = b
		agregar(cuerpo, forma, "Forma")
	return mi


## Colisión invisible (muro invisible, límite del nivel).
func muro_invisible(padre: Node, nombre: String, centro: Vector3, tamano: Vector3, rot_y := 0.0) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	agregar(padre, cuerpo, nombre)
	cuerpo.position = centro
	cuerpo.rotation_degrees.y = rot_y
	var forma := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = tamano
	forma.shape = b
	agregar(cuerpo, forma, "Forma")
	return cuerpo


## Habitación cerrada (suelo, techo y 4 paredes) entre [param minimo] y [param maximo].
## [param huecos]: lista de [lado, centro_a_lo_largo, ancho, alto] para dejar puertas
## (lado: "n" = -Z, "s" = +Z, "o" = -X, "e" = +X).
func habitacion(padre: Node, nombre: String, minimo: Vector3, maximo: Vector3, mat_pared: Material,
		mat_suelo: Material, mat_techo: Material, grosor := 0.3, huecos := []) -> Node3D:
	var g := grupo(padre, nombre)
	var c := (minimo + maximo) * 0.5
	var t := maximo - minimo
	caja(g, "Suelo", Vector3(c.x, minimo.y - grosor * 0.5, c.z), Vector3(t.x + grosor * 2, grosor, t.z + grosor * 2), mat_suelo)
	caja(g, "Techo", Vector3(c.x, maximo.y + grosor * 0.5, c.z), Vector3(t.x + grosor * 2, grosor, t.z + grosor * 2), mat_techo, true, 0.0, false)
	for lado in ["n", "s", "o", "e"]:
		var a_lo_largo_x: bool = lado == "n" or lado == "s"
		var largo: float = t.x if a_lo_largo_x else t.z
		var fijo: float
		match lado:
			"n": fijo = minimo.z - grosor * 0.5
			"s": fijo = maximo.z + grosor * 0.5
			"o": fijo = minimo.x - grosor * 0.5
			"e": fijo = maximo.x + grosor * 0.5
		var inicio: float = minimo.x if a_lo_largo_x else minimo.z
		var tramos: Array = [[inicio, inicio + largo]]
		var dinteles := []
		for h in huecos:
			if h[0] != lado:
				continue
			var a: float = h[1] - h[2] * 0.5
			var b: float = h[1] + h[2] * 0.5
			var nuevos := []
			for tr in tramos:
				if b <= tr[0] or a >= tr[1]:
					nuevos.append(tr)
					continue
				if a > tr[0]:
					nuevos.append([tr[0], a])
				if b < tr[1]:
					nuevos.append([b, tr[1]])
			tramos = nuevos
			dinteles.append([a, b, h[3]])
		var i := 0
		for tr in tramos:
			var mitad: float = (tr[0] + tr[1]) * 0.5
			var ancho: float = tr[1] - tr[0]
			if ancho < 0.01:
				continue
			var centro := Vector3(mitad, c.y, fijo) if a_lo_largo_x else Vector3(fijo, c.y, mitad)
			var tam := Vector3(ancho, t.y, grosor) if a_lo_largo_x else Vector3(grosor, t.y, ancho)
			caja(g, "Pared_%s_%d" % [lado, i], centro, tam, mat_pared)
			i += 1
		for d in dinteles:
			var alto_dintel: float = t.y - d[2]
			if alto_dintel <= 0.01:
				continue
			var mitad: float = (d[0] + d[1]) * 0.5
			var ancho: float = d[1] - d[0]
			var y: float = minimo.y + d[2] + alto_dintel * 0.5
			var centro := Vector3(mitad, y, fijo) if a_lo_largo_x else Vector3(fijo, y, mitad)
			var tam := Vector3(ancho, alto_dintel, grosor) if a_lo_largo_x else Vector3(grosor, alto_dintel, ancho)
			caja(g, "Dintel_%s_%d" % [lado, i], centro, tam, mat_pared)
			i += 1
	return g


## Lámina plana con textura (carteles, manchas de sangre, marcas en la pared, papeles).
## rot: grados (x, y, z). Una lámina sin rotar mira hacia +Z; con rot.x = -90 queda en el suelo.
func lamina(padre: Node, nombre: String, textura: String, pos: Vector3, tamano: Vector2,
		rot := Vector3.ZERO, recorte := 0.4, energia := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = tamano
	var m := ShaderMaterial.new()
	m.shader = SHADER_PS1
	m.set_shader_parameter(&"textura", load(textura))
	m.set_shader_parameter(&"recorte_alfa", recorte)
	m.set_shader_parameter(&"rugosidad", 0.85)
	m.set_shader_parameter(&"especular", 0.2)
	if energia > 0.0:
		m.set_shader_parameter(&"emision_desde_textura", true)
		m.set_shader_parameter(&"energia_emision", energia)
	q.material = m
	mi.mesh = q
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	agregar(padre, mi, nombre)
	mi.position = pos
	mi.rotation_degrees = rot
	return mi


## Texto en el mundo (rótulos, números de los espejos...).
func rotulo(padre: Node, nombre: String, texto: String, pos: Vector3, rot_y := 0.0, tamano := 0.12,
		color := Color(0.85, 0.82, 0.75)) -> Label3D:
	var l := Label3D.new()
	l.text = texto
	l.pixel_size = tamano / 32.0
	l.font_size = 32
	l.modulate = color
	l.outline_size = 0
	l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	l.shaded = true
	agregar(padre, l, nombre)
	l.position = pos
	l.rotation_degrees.y = rot_y
	return l


# --------------------------------------------------------------------- Luces ---

func omni(padre: Node, nombre: String, pos: Vector3, color: Color, energia: float, alcance: float,
		sombras := false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energia
	l.omni_range = alcance
	l.omni_attenuation = 1.2
	l.shadow_enabled = sombras
	agregar(padre, l, nombre)
	l.position = pos
	return l


func foco(padre: Node, nombre: String, pos: Vector3, mirar: Vector3, color: Color, energia: float,
		alcance: float, angulo := 40.0, sombras := true) -> SpotLight3D:
	var l := SpotLight3D.new()
	l.light_color = color
	l.light_energy = energia
	l.spot_range = alcance
	l.spot_angle = angulo
	l.spot_attenuation = 0.8
	l.shadow_enabled = sombras
	agregar(padre, l, nombre)
	l.transform = mirando(pos, mirar)
	return l


## Luminaria fluorescente (componente con parpadeos). tubo=false si ya está modelada.
func fluorescente(padre: Node, nombre: String, pos: Vector3, estado := 0, energia := 2.6,
		alcance := 7.0, tubo := false, sombras_baja := false, color := Color(0.78, 0.93, 0.88)) -> Node3D:
	var f := (load(FLUORESCENTE) as PackedScene).instantiate() as Node3D
	f.set(&"estado", estado)
	f.set(&"energia", energia)
	f.set(&"alcance", alcance)
	f.set(&"mostrar_tubo", tubo)
	f.set(&"sombras_en_calidad_baja", sombras_baja)
	f.set(&"color", color)
	padre.add_child(f, true)
	f.name = nombre
	f.owner = raiz
	f.position = pos
	return f


func luz_alarma(padre: Node, nombre: String, pos: Vector3, alcance := 9.0) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.set_script(load("res://componentes/luz_alarma.gd"))
	l.omni_range = alcance
	agregar(padre, l, nombre)
	l.position = pos
	return l


## Entorno del nivel: fondo, luz ambiente, niebla y (en calidad ALTA) niebla volumétrica.
func entorno(fondo: Color, ambiente: Color, energia_ambiente: float, niebla_color: Color,
		niebla_densidad: float, volumetrica := 0.0, volumetrica_color := Color(0.6, 0.65, 0.7),
		brillo := 0.35) -> WorldEnvironment:
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = fondo
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = ambiente
	e.ambient_light_energy = energia_ambiente
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 1.0
	e.fog_enabled = niebla_densidad > 0.0
	e.fog_light_color = niebla_color
	e.fog_density = niebla_densidad
	e.fog_sky_affect = 1.0
	e.volumetric_fog_density = volumetrica
	e.volumetric_fog_albedo = volumetrica_color
	e.volumetric_fog_emission = Color(0, 0, 0)
	e.volumetric_fog_length = 40.0
	e.volumetric_fog_detail_spread = 2.0
	e.volumetric_fog_ambient_inject = 0.15
	e.glow_intensity = brillo
	e.glow_bloom = 0.05
	e.glow_hdr_threshold = 1.2
	we.environment = e
	agregar(raiz, we, "Entorno")
	return we


# ----------------------------------------------------------- Juego y cámaras ---

func jugador(pos := Vector3.ZERO) -> Node3D:
	var j := (load(JUGADOR) as PackedScene).instantiate() as Node3D
	raiz.add_child(j, true)
	j.name = "Jugador"
	j.owner = raiz
	j.position = pos
	return j


func punto_entrada(padre: Node, id: StringName, pos: Vector3, rot_y := 0.0) -> Marker3D:
	return componente("res://componentes/punto_entrada.gd", padre, "Entrada_" + String(id), pos, rot_y,
			{"id": id}, "Marker3D") as Marker3D


## Cámara de cinemática. Mira a [param mirar].
func camara(padre: Node, nombre: String, pos: Vector3, mirar: Vector3, fov := 55.0) -> Camera3D:
	var c := Camera3D.new()
	c.fov = fov
	c.near = 0.05
	c.far = 220.0
	agregar(padre, c, nombre)
	c.transform = mirando(pos, mirar)
	return c


## Marcador (para trayectorias de cámara, puntos de ruta...).
func marcador(padre: Node, nombre: String, pos: Vector3, mirar := Vector3.INF) -> Marker3D:
	var m := Marker3D.new()
	agregar(padre, m, nombre)
	m.position = pos
	if mirar != Vector3.INF and not pos.is_equal_approx(mirar):
		m.transform = mirando(pos, mirar)
	return m


## Transformación local en [param pos] mirando hacia [param mirar] (coordenadas del padre).
func mirando(pos: Vector3, mirar: Vector3) -> Transform3D:
	var dir := mirar - pos
	if dir.length() < 0.0001:
		return Transform3D(Basis.IDENTITY, pos)
	var arriba := Vector3.UP if absf(dir.normalized().y) < 0.98 else Vector3.FORWARD
	return Transform3D(Basis.looking_at(dir, arriba), pos)


## Punto de sonido ambiental (lo crea el nivel al empezar: goteos, zumbidos, viento...).
func sonido(padre: Node, nombre: String, pos: Vector3, nombre_sonido: String, volumen := -8.0,
		alcance := 12.0) -> Marker3D:
	var m := marcador(padre, nombre, pos)
	m.set_meta(&"sonido", nombre_sonido)
	m.set_meta(&"volumen", volumen)
	m.set_meta(&"alcance", alcance)
	return m


## Goteo de agua (partículas finas que caen).
func goteo(padre: Node, nombre: String, pos: Vector3, cantidad := 4) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = cantidad
	p.lifetime = 0.9
	p.direction = Vector3.DOWN
	p.spread = 2.0
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 0.4
	p.gravity = Vector3(0, -9.8, 0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.2, 0.0, 0.02)
	var gota := BoxMesh.new()
	gota.size = Vector3(0.005, 0.028, 0.005)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.32, 0.37, 0.4)
	gota.material = m
	p.mesh = gota
	agregar(padre, p, nombre)
	p.position = pos
	return p


func zona_camara(padre: Node, nombre: String, centro: Vector3, tamano: Vector3, distancia: float,
		altura: float, lateral: float, fov: float, prioridad := 0) -> Node3D:
	var z := (load(ZONA_CAMARA) as PackedScene).instantiate() as Node3D
	z.set(&"tamano", tamano)
	z.set(&"distancia", distancia)
	z.set(&"altura", altura)
	z.set(&"desplazamiento_lateral", lateral)
	z.set(&"fov", fov)
	z.set(&"prioridad", prioridad)
	padre.add_child(z, true)
	z.name = nombre
	z.owner = raiz
	z.position = centro
	return z


func disparador(padre: Node, nombre: String, centro: Vector3, tamano: Vector3, metodo: StringName,
		una_vez := true, bandera := &"") -> Area3D:
	return componente("res://componentes/zona_disparador.gd", padre, nombre, centro, 0.0,
			{"tamano": tamano, "metodo_nivel": metodo, "una_vez": una_vez, "bandera": bandera}, "Area3D") as Area3D


## Personaje decorativo (cadáver, figurante, silueta): modelo en una pose fija o en bucle.
func figura(padre: Node, nombre: String, personaje: String, pos: Vector3, rot_y := 0.0,
		animacion := &"quieto", pose := -1.0, escala := 1.0, capas := 1) -> Node3D:
	return componente("res://personajes/modelo_personaje.gd", padre, nombre, pos, rot_y,
			{"personaje": personaje, "animacion_inicial": animacion, "pose_fija": pose, "escala": escala,
			"capas": capas}) as Node3D


## Enemigo con su script. [param ruta] = nodo con los puntos de patrulla.
func enemigo(script: String, padre: Node, nombre: String, pos: Vector3, rot_y := 0.0, props := {}) -> CharacterBody3D:
	var e := CharacterBody3D.new()
	e.set_script(load(script))
	for clave: String in props:
		e.set(clave, props[clave])
	agregar(padre, e, nombre)
	e.position = pos
	e.set(&"orientacion_inicial", rot_y)
	return e


func ruta(padre: Node, nombre: String, puntos: Array) -> Node3D:
	var g := grupo(padre, nombre)
	var i := 0
	for p in puntos:
		marcador(g, "P%d" % i, p)
		i += 1
	return g


# --------------------------------------------------------------- Navegación ---

## Región de navegación. Toma como fuente los nodos del grupo «navegable» (y sus hijos).
## [param limite]: solo se hornea dentro de esa caja (AABB vacía = todo).
func navegacion(nombre: String, limite := AABB(), radio := 0.25) -> NavigationRegion3D:
	var region := NavigationRegion3D.new()
	var nm := NavigationMesh.new()
	nm.agent_radius = radio
	nm.agent_height = 1.75
	nm.agent_max_climb = 0.25
	nm.agent_max_slope = 40.0
	nm.cell_size = 0.25
	nm.cell_height = 0.25
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = 1
	nm.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	nm.geometry_source_group_name = &"navegable"
	if limite.size != Vector3.ZERO:
		nm.filter_baking_aabb = limite
	region.navigation_mesh = nm
	agregar(raiz, region, nombre)
	return region


func navegable(nodo: Node) -> void:
	nodo.add_to_group(&"navegable", true)


## Pieza suelta de un kit (ver componentes/pieza_kit.gd). colision: 0 ninguna, 1 caja, 2 malla.
func pieza(padre: Node, nombre: String, kit: String, nombre_pieza: String, pos: Vector3, rot_y := 0.0,
		colision := 1, escala := 1.0) -> Node3D:
	var p := componente("res://componentes/pieza_kit.gd", padre, nombre, pos, rot_y,
			{"kit": kit, "pieza": nombre_pieza, "colision": colision}) as Node3D
	p.scale = Vector3.ONE * escala
	return p


# ------------------------------------------------------------------ Guardar ---

## Hornea la navegación. Se llama cuando solo hay geometría (sin scripts que se ejecuten):
## el nivel entra un momento en el árbol, se hornea y sale.
func hornear() -> void:
	arbol.root.add_child(raiz)
	for region in raiz.find_children("*", "NavigationRegion3D", true, false):
		(region as NavigationRegion3D).bake_navigation_mesh(false)
		var nm := (region as NavigationRegion3D).navigation_mesh
		print("  navegación %s: %d polígonos" % [region.name, nm.get_polygon_count()])
	arbol.root.remove_child(raiz)


## Guarda el .tscn.
func guardar(ruta_tscn: String) -> int:
	DirAccess.make_dir_recursive_absolute(ruta_tscn.get_base_dir())
	var escena := PackedScene.new()
	var err := escena.pack(raiz)
	if err != OK:
		push_error("No se pudo empaquetar %s: %s" % [ruta_tscn, error_string(err)])
		return err
	err = ResourceSaver.save(escena, ruta_tscn)
	print("GUARDADO ", ruta_tscn, " -> ", error_string(err))
	raiz.free()
	return err
