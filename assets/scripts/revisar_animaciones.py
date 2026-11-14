"""Vídeo de revisión de las animaciones de cada personaje (assets/renders/animaciones/<personaje>.mp4).

Abre el .blend del personaje SIN guardarlo, reproduce cada acción ante una luz de estudio y
renderiza un fotograma de cada dos (15 fps) con el nombre de la animación sobreimpreso.
Después une las imágenes con FFmpeg.

Uso:
    blender --background --factory-startup --python assets/scripts/revisar_animaciones.py -- elias_preso [otro ...]
"""
import math
import os
import shutil
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import comun as C  # noqa: E402
from previsualizar import estudio, medir  # noqa: E402

PASO = 2            # un fotograma de cada dos (30 → 15 fps)
ANCHO, ALTO = 480, 540


def motor_rapido(escena):
    """Workbench: mucho más rápido que EEVEE en este equipo; basta para revisar el movimiento."""
    escena.render.engine = "BLENDER_WORKBENCH"
    sombreado = escena.display.shading
    sombreado.light = "STUDIO"
    sombreado.color_type = "TEXTURE"
    sombreado.show_shadows = True
    sombreado.shadow_intensity = 0.6
    escena.display.render_aa = "FXAA"
    if escena.world:
        escena.world.color = (0.03, 0.035, 0.045)


def revisar(clave, solo=None, rapido=False):
    bpy.ops.wm.open_mainfile(filepath=str(C.RAIZ / "personajes" / f"{clave}.blend"))
    escena = bpy.context.scene
    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    objetos = [o for o in bpy.data.objects if o.type in ("MESH", "ARMATURE")]
    minimo, maximo = medir(objetos)
    alto = maximo.z - minimo.z
    estudio(escena, alto)
    datos = bpy.data.cameras.new("Cam_Revision")
    datos.lens = 35
    cam = bpy.data.objects.new("Cam_Revision", datos)
    escena.collection.objects.link(cam)
    centro = Vector((0.0, -0.5, alto * 0.45))
    a = math.radians(35)
    cam.location = centro + Vector((math.sin(a) * alto * 2.4, -math.cos(a) * alto * 2.4, alto * 0.15))
    cam.rotation_euler = (centro - cam.location).to_track_quat("-Z", "Y").to_euler()
    escena.camera = cam
    C.configurar_render(escena, ANCHO, ALTO, muestras=4, exposicion=0.3)
    escena.eevee.use_raytracing = False
    if rapido:
        motor_rapido(escena)
    r = escena.render
    r.use_stamp = True
    for propiedad in dir(r):
        if propiedad.startswith("use_stamp_") and propiedad not in ("use_stamp_note", "use_stamp_labels"):
            try:
                setattr(r, propiedad, False)
            except (AttributeError, TypeError):
                pass
    r.use_stamp_note = True
    r.use_stamp_labels = False
    r.stamp_font_size = 18
    carpeta = C.RAIZ / "renders" / "animaciones" / f"_tmp_{clave}"
    shutil.rmtree(carpeta, ignore_errors=True)
    os.makedirs(carpeta, exist_ok=True)
    ad = arm.animation_data_create()
    pistas = [p.name for p in ad.nla_tracks]
    n = 0
    for nombre in pistas:
        if solo and nombre not in solo:
            continue
        accion = bpy.data.actions[nombre]
        ad.action = accion
        if getattr(ad, "action_slot", None) is None and len(accion.slots):
            ad.action_slot = accion.slots[0]
        ultimo = int(accion.frame_range[1])
        repeticiones = 2 if nombre.endswith("_loop") and ultimo < 40 else 1
        for vuelta in range(repeticiones):
            for f in range(0, ultimo + 1, PASO):
                escena.frame_set(f)
                r.stamp_note_text = f"{clave}  ·  {nombre}"
                r.filepath = str(carpeta / f"f_{n:05d}.png")
                bpy.ops.render.render(write_still=True)
                n += 1
        # Pausa de medio segundo en la última pose.
        for _ in range(7):
            shutil.copyfile(carpeta / f"f_{n - 1:05d}.png", carpeta / f"f_{n:05d}.png")
            n += 1
    destino = C.RAIZ / "renders" / "animaciones" / f"{clave}.mp4"
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", str(30 // PASO), "-i",
                    str(carpeta / "f_%05d.png"), "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "20",
                    str(destino)], check=True)
    shutil.rmtree(carpeta, ignore_errors=True)
    print("VIDEO", destino, n, "fotogramas")


def hoja(clave, solo=None, poses=5, lado=230):
    """Hoja de contactos: varias poses de cada animación (filas) en una sola imagen PNG."""
    import numpy as np
    from previsualizar import leer_png
    bpy.ops.wm.open_mainfile(filepath=str(C.RAIZ / "personajes" / f"{clave}.blend"))
    escena = bpy.context.scene
    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    objetos = [o for o in bpy.data.objects if o.type in ("MESH", "ARMATURE")]
    minimo, maximo = medir(objetos)
    alto = maximo.z - minimo.z
    estudio(escena, alto)
    datos = bpy.data.cameras.new("Cam_Hoja")
    datos.lens = 35
    cam = bpy.data.objects.new("Cam_Hoja", datos)
    escena.collection.objects.link(cam)
    centro = Vector((0.0, -0.25, alto * 0.45))
    a = math.radians(40)
    cam.location = centro + Vector((math.sin(a) * alto * 1.55, -math.cos(a) * alto * 1.55, alto * 0.1))
    cam.rotation_euler = (centro - cam.location).to_track_quat("-Z", "Y").to_euler()
    escena.camera = cam
    C.configurar_render(escena, lado, int(lado * 1.2), muestras=2, exposicion=0.3)
    escena.eevee.use_raytracing = False
    ad = arm.animation_data_create()
    filas = []
    carpeta = C.RAIZ / "renders" / "animaciones" / f"_tmp_hoja_{clave}"
    os.makedirs(carpeta, exist_ok=True)
    for nombre in [p.name for p in ad.nla_tracks]:
        if solo and nombre not in solo:
            continue
        accion = bpy.data.actions[nombre]
        ad.action = accion
        if getattr(ad, "action_slot", None) is None and len(accion.slots):
            ad.action_slot = accion.slots[0]
        ultimo = int(accion.frame_range[1])
        fila = []
        for i in range(poses):
            escena.frame_set(round(ultimo * i / (poses - 1)))
            ruta = carpeta / f"{nombre}_{i}.png"
            escena.render.filepath = str(ruta)
            bpy.ops.render.render(write_still=True)
            fila.append(leer_png(ruta))
        filas.append(np.concatenate(fila, axis=1))
        print("HOJA FILA", nombre)
    imagen = np.concatenate(filas, axis=0)
    destino = C.RAIZ / "renders" / "animaciones" / f"{clave}_hoja.png"
    img = bpy.data.images.new("hoja", imagen.shape[1], imagen.shape[0], alpha=True)
    rgba = np.ones((imagen.shape[0], imagen.shape[1], 4), dtype=np.float32)
    rgba[..., :3] = np.clip(imagen, 0, 1)
    img.pixels.foreach_set(rgba[::-1].ravel())
    img.filepath_raw = str(destino)
    img.file_format = "PNG"
    img.save()
    shutil.rmtree(carpeta, ignore_errors=True)
    print("HOJA", destino)


if __name__ == "__main__":
    args = C.argumentos()
    solo = None
    modo_hoja = "--hoja" in args
    rapido = "--rapido" in args
    args = [a for a in args if a not in ("--hoja", "--rapido")]
    if "--solo" in args:
        i = args.index("--solo")
        solo = set(args[i + 1:])
        args = args[:i]
    for clave in args:
        if modo_hoja:
            hoja(clave, solo)
        else:
            revisar(clave, solo, rapido)
