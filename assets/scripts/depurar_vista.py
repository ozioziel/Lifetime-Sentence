"""Renderiza un .blend desde una cámara de depuración (para revisar detalles).

Uso:
    blender --background <archivo.blend> --python assets/scripts/depurar_vista.py -- salida.png x y z tx ty tz [lente]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import comun as C  # noqa: E402

args = C.argumentos()
salida = args[0]
x, y, z, tx, ty, tz = map(float, args[1:7])
lente = float(args[7]) if len(args) > 7 else 35.0
escena = bpy.context.scene
datos = bpy.data.cameras.new("Depurar")
datos.lens = lente
cam = bpy.data.objects.new("Depurar", datos)
escena.collection.objects.link(cam)
cam.location = (x, y, z)
cam.rotation_euler = (Vector((tx, ty, tz)) - Vector((x, y, z))).to_track_quat("-Z", "Y").to_euler()
escena.camera = cam
escena.render.resolution_x = 640
escena.render.resolution_y = 360
escena.eevee.taa_render_samples = 8
C.renderizar(escena, salida)
