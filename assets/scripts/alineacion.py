"""Alineaciones del elenco (como las láminas «Enemigos y jefes» de Materiales/).

Uso:
    blender --background --factory-startup --python assets/scripts/alineacion.py -- pasado presente
Resultado: assets/renders/alineacion_<grupo>.png
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import comun as C  # noqa: E402
from previsualizar import cargar_personaje, medir  # noqa: E402

GRUPOS = {
    "pasado": ["elias_civil", "policia_patrullero", "policia_tactico", "guardia_penitenciario",
               "interrogador", "verdugo", "alcaide"],
    "presente": ["elias_preso", "aislado_a", "aislado_b", "el_uniforme", "el_vigilante", "el_condenado",
                 "la_sentencia", "el_director"],
    "figurantes": ["preso_generico_a", "preso_generico_b", "preso_generico_c", "guardia_penitenciario"],
}


def alinear(grupo):
    C.reiniciar()
    escena = bpy.context.scene
    x = 0.0
    alto_max = 0.0
    for nombre in GRUPOS[grupo]:
        objetos = cargar_personaje(nombre)
        minimo, maximo = medir(objetos)
        ancho = maximo.x - minimo.x
        raiz = [o for o in objetos if o.parent is None]
        for o in raiz:
            o.location.x += x - minimo.x
            o.rotation_euler.z = math.radians(-12)
        x += ancho + 0.45
        alto_max = max(alto_max, maximo.z - minimo.z)
    bpy.context.view_layer.update()
    ancho_total = x - 0.45
    for o in escena.objects:
        if o.parent is None:
            o.location.x -= ancho_total / 2

    mundo = bpy.data.worlds.new("Fondo")
    escena.world = mundo
    fondo = next(n for n in mundo.node_tree.nodes if n.type == "BACKGROUND")
    fondo.inputs["Color"].default_value = (0.014, 0.016, 0.02, 1)
    bpy.ops.mesh.primitive_plane_add(size=60)
    bpy.context.object.data.materials.append(C.material("MAT_Suelo_Al", color=(0.05, 0.055, 0.06),
                                                        rugosidad=0.5))
    referencia = 1.8

    def luz(nombre, energia, pos, color, tam):
        datos = bpy.data.lights.new(nombre, "AREA")
        datos.energy = energia
        datos.color = color
        datos.size = tam
        obj = bpy.data.objects.new(nombre, datos)
        escena.collection.objects.link(obj)
        obj.location = pos
        obj.rotation_euler = (Vector((0, 0, 1.0)) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
    luz("Principal", 260 * ancho_total, (ancho_total * 0.3, -9, 6), (0.85, 0.92, 1.0), ancho_total * 0.7)
    luz("Relleno", 60 * ancho_total, (-ancho_total * 0.4, -7, 2), (0.6, 0.7, 0.85), ancho_total * 0.6)
    luz("Contra", 120 * ancho_total, (0, 6, 7), (0.7, 0.85, 1.0), ancho_total)

    datos = bpy.data.cameras.new("Cam")
    datos.lens = 50
    cam = bpy.data.objects.new("Cam", datos)
    escena.collection.objects.link(cam)
    # Distancia para que quepan el ancho y el alto (lente 50 mm, sensor 36 mm, 1800 x 760).
    tan_h = 18.0 / 50.0
    tan_v = tan_h * 760 / 1800
    distancia = max(ancho_total / 2 / tan_h, alto_max / 2 / tan_v) * 1.12
    centro = Vector((0, 0, alto_max * 0.45))
    cam.location = centro + Vector((0, -distancia, alto_max * 0.08))
    cam.rotation_euler = (centro - cam.location).to_track_quat("-Z", "Y").to_euler()
    escena.camera = cam
    C.configurar_render(escena, 1800, 760, muestras=32, exposicion=0.4)
    escena.eevee.use_raytracing = False
    _ = referencia
    C.renderizar(escena, C.RAIZ / "renders" / f"alineacion_{grupo}.png")


if __name__ == "__main__":
    for g in C.argumentos() or ["pasado", "presente"]:
        alinear(g)
