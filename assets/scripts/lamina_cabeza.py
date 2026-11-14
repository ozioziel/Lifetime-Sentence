"""Lámina de revisión de la cabeza de un personaje: frente, tres cuartos, perfil y espalda.

Uso:
    blender --background --factory-startup --python assets/scripts/lamina_cabeza.py -- elias_preso [otro ...]
Resultado: assets/renders/personajes/<nombre>_cabeza.png
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy  # noqa: E402
import numpy as np  # noqa: E402
from mathutils import Vector  # noqa: E402

import comun as C  # noqa: E402
from previsualizar import cargar_personaje, estudio, leer_png, medir  # noqa: E402

VISTAS = (("frente", 0), ("tres_cuartos", 35), ("perfil", 90), ("espalda", 150))


def lamina(nombre):
    escena = C.reiniciar()
    objetos = cargar_personaje(nombre)
    minimo, maximo = medir(objetos)
    alto = maximo.z - minimo.z
    estudio(escena, alto)
    C.configurar_render(escena, 400, 460, muestras=16, exposicion=0.3)
    escena.eevee.use_raytracing = False
    cabeza = Vector((0, 0.0, maximo.z - alto * 0.085))
    datos = bpy.data.cameras.new("Cam_Cabeza")
    datos.lens = 85
    cam = bpy.data.objects.new("Cam_Cabeza", datos)
    escena.collection.objects.link(cam)
    escena.camera = cam
    carpeta = C.RAIZ / "renders" / "personajes" / "_tmp"
    vistas = []
    for etiqueta, angulo in VISTAS:
        a = math.radians(angulo)
        distancia = alto * 0.42
        cam.location = cabeza + Vector((math.sin(a) * distancia, -math.cos(a) * distancia, alto * 0.02))
        cam.rotation_euler = (cabeza - cam.location).to_track_quat("-Z", "Y").to_euler()
        ruta = carpeta / f"{nombre}_cabeza_{etiqueta}.png"
        C.renderizar(escena, ruta)
        vistas.append(leer_png(ruta))
    hoja = np.concatenate(vistas, axis=1)
    imagen = bpy.data.images.new("hoja_cabeza", hoja.shape[1], hoja.shape[0], alpha=True)
    rgba = np.ones((hoja.shape[0], hoja.shape[1], 4), dtype=np.float32)
    rgba[..., :3] = np.clip(hoja, 0, 1)
    imagen.pixels.foreach_set(rgba[::-1].ravel())
    destino = C.RAIZ / "renders" / "personajes" / f"{nombre}_cabeza.png"
    imagen.filepath_raw = str(destino)
    imagen.file_format = "PNG"
    imagen.save()
    print("LAMINA", destino)


if __name__ == "__main__":
    for n in C.argumentos():
        lamina(n)
