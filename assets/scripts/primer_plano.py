"""Primer plano de revisión de un personaje con la luz de estudio de las láminas (manos, cara, armas).

Uso:
    blender --background --factory-startup --python assets/scripts/primer_plano.py -- <personaje> <salida.png> x y z tx ty tz [lente]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import comun as C  # noqa: E402
from previsualizar import cargar_personaje, estudio, medir  # noqa: E402

args = C.argumentos()
nombre, salida = args[0], args[1]
x, y, z, tx, ty, tz = map(float, args[2:8])
lente = float(args[8]) if len(args) > 8 else 50.0
escena = C.reiniciar()
minimo, maximo = medir(cargar_personaje(nombre))
estudio(escena, maximo.z - minimo.z)
datos = bpy.data.cameras.new("Primer_Plano")
datos.lens = lente
cam = bpy.data.objects.new("Primer_Plano", datos)
escena.collection.objects.link(cam)
cam.location = (x, y, z)
cam.rotation_euler = (Vector((tx, ty, tz)) - Vector((x, y, z))).to_track_quat("-Z", "Y").to_euler()
escena.camera = cam
C.configurar_render(escena, 640, 480, muestras=16, exposicion=0.3)
escena.eevee.use_raytracing = False
C.renderizar(escena, salida)
