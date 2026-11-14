"""Lámina de revisión de un personaje: frente, 3/4, perfil, espalda y cara.

Uso:
    blender --background --factory-startup --python assets/scripts/previsualizar.py -- elias_preso el_uniforme
Resultado: assets/renders/personajes/<nombre>.png
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy  # noqa: E402
import numpy as np  # noqa: E402
from mathutils import Vector  # noqa: E402

import comun as C  # noqa: E402


def cargar_personaje(nombre):
    ruta = str(C.RAIZ / "personajes" / f"{nombre}.blend")
    with bpy.data.libraries.load(ruta, link=False) as (origen, destino):
        destino.collections = list(origen.collections)
    for col in destino.collections:
        if col.name not in bpy.context.scene.collection.children:
            bpy.context.scene.collection.children.link(col)
    objetos = [o for c in destino.collections for o in c.all_objects]
    return objetos


def medir(objetos):
    mallas = [o for o in objetos if o.type == "MESH"]
    bpy.context.view_layer.update()
    puntos = []
    for o in mallas:
        evaluado = o.evaluated_get(bpy.context.evaluated_depsgraph_get())
        for v in evaluado.to_mesh().vertices:
            puntos.append(o.matrix_world @ v.co)
        evaluado.to_mesh_clear()
    minimo = Vector((min(p.x for p in puntos), min(p.y for p in puntos), min(p.z for p in puntos)))
    maximo = Vector((max(p.x for p in puntos), max(p.y for p in puntos), max(p.z for p in puntos)))
    return minimo, maximo


def estudio(escena, alto):
    mundo = bpy.data.worlds.new("Estudio")
    escena.world = mundo
    fondo = next(n for n in mundo.node_tree.nodes if n.type == "BACKGROUND")
    fondo.inputs["Color"].default_value = (0.012, 0.014, 0.018, 1)
    fondo.inputs["Strength"].default_value = 1.0
    bpy.ops.mesh.primitive_plane_add(size=12, location=(0, 0, 0))
    suelo = bpy.context.object
    suelo.data.materials.append(C.material("MAT_Suelo_Estudio", color=(0.05, 0.055, 0.06),
                                           rugosidad=0.6))

    def luz(nombre, tipo, energia, pos, color, tam=1.0):
        datos = bpy.data.lights.new(nombre, tipo)
        datos.energy = energia
        datos.color = color
        if tipo == "AREA":
            datos.size = tam
        obj = bpy.data.objects.new(nombre, datos)
        obj.location = pos
        escena.collection.objects.link(obj)
        direccion = Vector((0, 0, alto * 0.55)) - Vector(pos)
        obj.rotation_euler = direccion.to_track_quat("-Z", "Y").to_euler()
        return obj
    luz("Principal", "AREA", 260 * alto, (2.2 * alto, -2.6 * alto, 2.4 * alto), (0.85, 0.92, 1.0), 1.6 * alto)
    luz("Relleno", "AREA", 70 * alto, (-2.6 * alto, -1.6 * alto, 1.2 * alto), (0.6, 0.7, 0.85), 2.0 * alto)
    luz("Contra", "AREA", 300 * alto, (-0.8 * alto, 2.6 * alto, 2.6 * alto), (0.7, 0.85, 1.0), 1.0 * alto)


def camara(escena, objetivo, distancia, angulo, alto_cam, lente=50):
    datos = bpy.data.cameras.new("Cam")
    datos.lens = lente
    obj = bpy.data.objects.new("Cam", datos)
    escena.collection.objects.link(obj)
    a = math.radians(angulo)
    obj.location = objetivo + Vector((math.sin(a) * distancia, -math.cos(a) * distancia, alto_cam))
    direccion = objetivo - obj.location
    obj.rotation_euler = direccion.to_track_quat("-Z", "Y").to_euler()
    escena.camera = obj
    return obj


def leer_png(ruta):
    img = bpy.data.images.load(str(ruta))
    ancho, alto = img.size
    pix = np.array(img.pixels[:]).reshape(alto, ancho, 4)[::-1, :, :3]
    bpy.data.images.remove(img)
    return pix


def lamina(nombre):
    C.reiniciar()
    escena = bpy.context.scene
    objetos = cargar_personaje(nombre)
    minimo, maximo = medir(objetos)
    alto = maximo.z - minimo.z
    estudio(escena, alto)
    C.configurar_render(escena, 420, 640, muestras=24, exposicion=0.3)
    escena.eevee.use_raytracing = False
    carpeta = C.RAIZ / "renders" / "personajes" / "_tmp"
    centro = Vector((0, 0, alto * 0.52))
    vistas = []
    for angulo in (0, 35, 90, 180):
        cam = camara(escena, centro, alto * 2.35, angulo, 0.0)
        ruta = carpeta / f"{nombre}_{angulo}.png"
        C.renderizar(escena, ruta)
        vistas.append(leer_png(ruta))
        bpy.data.objects.remove(cam)
    # Primer plano de la cara.
    cabeza = Vector((0, -0.02 * alto, maximo.z - alto * 0.075))
    cam = camara(escena, cabeza, alto * 0.42, 20, alto * 0.01, lente=60)
    ruta = carpeta / f"{nombre}_cara.png"
    C.renderizar(escena, ruta)
    vistas.append(leer_png(ruta))
    hoja = np.concatenate(vistas, axis=1)
    destino = C.RAIZ / "renders" / "personajes" / f"{nombre}.png"
    C.guardar_png_absoluto = None
    imagen = bpy.data.images.new("hoja", hoja.shape[1], hoja.shape[0], alpha=True)
    rgba = np.ones((hoja.shape[0], hoja.shape[1], 4), dtype=np.float32)
    rgba[..., :3] = np.clip(hoja, 0, 1)
    imagen.pixels.foreach_set(rgba[::-1].ravel())
    imagen.filepath_raw = str(destino)
    imagen.file_format = "PNG"
    imagen.save()
    print("LAMINA", destino)


if __name__ == "__main__":
    for n in C.argumentos():
        lamina(n)
