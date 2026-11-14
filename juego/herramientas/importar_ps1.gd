@tool
extends EditorScenePostImport
## Se ejecuta al importar cada .glb que viene de Blender (assets/personajes, kits y escenarios).
##
##  1. Cambia los materiales de glTF por el material PS1 del juego
##     (render/ps1_superficie.gdshader): píxel nítido, vibración de vértices,
##     recorte por transparencia y emisión.
##  2. A los ESCENARIOS les da colisión exacta (trimesh), salvo a la decoración
##     colgante (estandartes, sábanas, cadenas...) por la que se puede pasar.
##
## Se activa desde el panel Importar de cada .glb («Import Script»). Si se cambia
## este archivo, hay que reimportar los .glb (botón «Reimportar»).

const SHADER := preload("res://render/ps1_superficie.gdshader")
## Partes de nombre de malla que NO llevan colisión.
const SIN_COLISION := ["Estandarte", "Sabana", "Cortina", "Cadena", "Charco", "Rotulo", "Lampara",
		"Tragaluz", "Fluor", "Gotero", "Bombilla", "Lluvia", "Cartel", "Emblema"]
## Brillo máximo de la emisión (Blender usa valores muy altos que en Godot deslumbran).
const EMISION_MAXIMA := 6.0

var _cache := {}


func _post_import(escena: Node) -> Object:
	var fuente := get_source_file()
	var con_colision := fuente.contains("/escenarios/")
	_recorrer(escena, escena, con_colision)
	return escena


func _recorrer(nodo: Node, raiz: Node, con_colision: bool) -> void:
	if nodo is MeshInstance3D:
		var instancia := nodo as MeshInstance3D
		_convertir_malla(instancia)
		if con_colision and not _excluido(instancia.name):
			_dar_colision(instancia, raiz)
	for hijo in nodo.get_children():
		_recorrer(hijo, raiz, con_colision)


func _excluido(nombre: String) -> bool:
	for parte in SIN_COLISION:
		if nombre.contains(parte):
			return true
	return false


func _convertir_malla(instancia: MeshInstance3D) -> void:
	var malla := instancia.mesh
	if malla == null:
		return
	for i in malla.get_surface_count():
		var nuevo := _convertir(malla.surface_get_material(i))
		if nuevo:
			malla.surface_set_material(i, nuevo)


func _convertir(material: Material) -> Material:
	if not (material is BaseMaterial3D):
		return material
	if _cache.has(material):
		return _cache[material]
	var base := material as BaseMaterial3D
	var ps1 := ShaderMaterial.new()
	ps1.shader = SHADER
	ps1.resource_name = base.resource_name
	ps1.set_shader_parameter(&"color", base.albedo_color)
	if base.albedo_texture:
		ps1.set_shader_parameter(&"textura", base.albedo_texture)
	ps1.set_shader_parameter(&"rugosidad", base.roughness)
	ps1.set_shader_parameter(&"metalico", base.metallic)
	ps1.set_shader_parameter(&"especular", 0.35)
	if base.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
		ps1.set_shader_parameter(&"recorte_alfa", 0.5)
	if base.emission_enabled:
		var e := base.emission
		ps1.set_shader_parameter(&"emision", Vector3(e.r, e.g, e.b))
		ps1.set_shader_parameter(&"energia_emision",
				minf(base.emission_energy_multiplier, EMISION_MAXIMA))
		if base.emission_texture:
			ps1.set_shader_parameter(&"emision_desde_textura", true)
	_cache[material] = ps1
	return ps1


func _dar_colision(instancia: MeshInstance3D, raiz: Node) -> void:
	instancia.create_trimesh_collision()
	for hijo in instancia.get_children():
		if hijo is StaticBody3D:
			hijo.owner = raiz
			for nieto in hijo.get_children():
				nieto.owner = raiz
