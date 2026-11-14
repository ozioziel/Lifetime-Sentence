"""Exporta los assets de Blender al proyecto Godot (juego/assets/) en formato glTF binario (.glb).

  - personajes/<clave>.glb  malla, esqueleto y TODAS las animaciones (acciones).
  - kits/<kit>.glb          piezas sueltas de cada kit (Godot las usa por su nombre).
  - escenarios/<nombre>.glb geometría del escenario con los modificadores aplicados.

Se dejan fuera las luces, las cámaras, los volúmenes de niebla y la lluvia: en Godot se
rehacen con luces, niebla volumética y partículas propias (más baratas y animadas).

Uso:
    blender --background --factory-startup --python assets/scripts/exportar_godot.py [-- personajes kits escenarios]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy  # noqa: E402

import comun as C  # noqa: E402

DESTINO = C.RAIZ.parent / "juego" / "assets"
PERSONAJES = ["elias_preso", "elias_civil", "el_uniforme", "aislado_a", "aislado_b", "el_vigilante", "el_condenado",
              "la_sentencia", "el_director", "policia_patrullero", "policia_tactico", "guardia_penitenciario",
              "interrogador", "verdugo", "alcaide", "preso_generico_a", "preso_generico_b", "preso_generico_c"]
KITS = ["kit_prision", "kit_bloque_a", "kit_ciudad", "kit_interiores"]
ESCENARIOS = ["patio_central", "bloque_a", "bloque_a_juego", "callejon", "enfermeria", "comisaria", "ejecucion",
              "nucleo"]
EXCLUIR = ("Niebla", "Lluvia", "Volumen")


def exportar(ruta, animaciones=False):
    os.makedirs(os.path.dirname(ruta), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(ruta), export_format="GLB", export_apply=True, export_yup=True,
        export_animations=animaciones, export_animation_mode="ACTIONS",
        export_lights=False, export_cameras=False, use_visible=True,
        export_image_format="AUTO")
    print("EXPORTADO", ruta, os.path.getsize(ruta) // 1024, "KB")


def ocultar_excluidos():
    """Oculta (sin guardar) luces, cámaras, niebla y lluvia antes de exportar."""
    for obj in bpy.context.scene.objects:
        if obj.type in ("LIGHT", "CAMERA") or any(x in obj.name for x in EXCLUIR):
            obj.hide_set(True)
            obj.hide_viewport = True


def personajes():
    for clave in PERSONAJES:
        bpy.ops.wm.open_mainfile(filepath=str(C.RAIZ / "personajes" / f"{clave}.blend"))
        bpy.context.scene.render.fps = 30
        exportar(DESTINO / "personajes" / f"{clave}.glb", animaciones=True)


def kits():
    for kit in KITS:
        bpy.ops.wm.open_mainfile(filepath=str(C.RAIZ / "kit" / f"{kit}.blend"))
        ocultar_excluidos()
        exportar(DESTINO / "kits" / f"{kit}.glb")


def escenarios():
    for nombre in ESCENARIOS:
        bpy.ops.wm.open_mainfile(filepath=str(C.RAIZ / "escenarios" / f"{nombre}.blend"))
        ocultar_excluidos()
        exportar(DESTINO / "escenarios" / f"{nombre}.glb")


def escenario_suelto(nombre):
    """Exporta un solo escenario (p. ej. bloque_a_juego)."""
    bpy.ops.wm.open_mainfile(filepath=str(C.RAIZ / "escenarios" / f"{nombre}.blend"))
    ocultar_excluidos()
    exportar(DESTINO / "escenarios" / f"{nombre}.glb")


if __name__ == "__main__":
    partes = C.argumentos() or ["personajes", "kits", "escenarios"]
    for parte in partes:
        funcion = {"personajes": personajes, "kits": kits, "escenarios": escenarios}.get(parte)
        if funcion:
            funcion()
        else:
            escenario_suelto(parte)
