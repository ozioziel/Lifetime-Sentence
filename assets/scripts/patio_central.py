"""Escenario: Patio Central (el pabellón monumental donde nace la megalofobia).

Monta assets/escenarios/patio_central.blend a partir del kit (assets/kit/kit_prision.blend),
que se ENLAZA: si se edita una pieza del kit, el patio se actualiza.

Los muros son objetos con modificadores Array: para cambiar el número de plantas o la
longitud del patio basta con cambiar «Count» en el modificador, sin tocar geometría.

Uso:
    blender --background --factory-startup --python assets/scripts/patio_central.py
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import comun as C  # noqa: E402
from kit_prision import MODULO, PLANTA  # noqa: E402

ANCHO = 26.0                    # distancia entre los planos de los muros de celdas
PLANTAS = 18                    # 18 x 3,2 = 57,6 m de alto
MODULOS = 8                     # 8 x 9,6 = 76,8 m de largo
LARGO = MODULOS * MODULO
ALTO = PLANTAS * PLANTA
KIT = C.RAIZ / "kit" / "kit_prision.blend"

# Puentes que cruzan el vacío: (planta, y).
PUENTES = [(4, 20.0), (6, -6.0), (8, 24.0), (12, 30.0), (14, 18.0), (16, 6.0), (10, 20.0)]
# Pasarelas radiales de la torre: (planta, lado).
PUENTES_TORRE = [(10, -1), (10, 1)]
TORRE = (0.0, -27.0)


def enlazar_mallas():
    """Enlaza (no copia) las mallas del kit."""
    with bpy.data.libraries.load(str(KIT), link=True, relative=True) as (origen, destino):
        destino.meshes = [n for n in origen.meshes if n.startswith("M_Kit_")]
    return {m.name: m for m in destino.meshes}


def objeto(nombre, malla, coleccion, posicion=(0, 0, 0), rotacion_z=0.0, escala=1.0):
    obj = bpy.data.objects.new(nombre, malla)
    coleccion.objects.link(obj)
    obj.location = posicion
    obj.rotation_euler = (0.0, 0.0, rotacion_z)
    obj.scale = (escala, escala, escala)
    return obj


def array(obj, cantidad, desplazamiento=None, relativo=(1.0, 0.0, 0.0), nombre="Array"):
    mod = obj.modifiers.new(nombre, "ARRAY")
    mod.count = cantidad
    if desplazamiento is not None:
        mod.use_relative_offset = False
        mod.use_constant_offset = True
        mod.constant_offset_displace = desplazamiento
    else:
        mod.relative_offset_displacement = relativo
    return mod


def muro_de_celdas(nombre, mallas, coleccion, posicion, rotacion_z, modulos, plantas):
    """Muro con 4 variantes de módulo que se alternan (a lo largo y por plantas pares/impares),
    para que las celdas iluminadas no formen columnas repetidas."""
    objs = []
    direccion = Vector((math.cos(rotacion_z), math.sin(rotacion_z), 0.0))
    for planta_par in (0, 1):
        for desfase in (0, 1):
            malla = mallas[(planta_par * 2 + desfase) % len(mallas)]
            cantidad = (modulos - desfase + 1) // 2
            if cantidad <= 0:
                continue
            pos = Vector(posicion) + direccion * (desfase * MODULO) + Vector((0, 0, planta_par * PLANTA))
            obj = objeto(f"{nombre}_{planta_par}{desfase}", malla, coleccion, pos, rotacion_z)
            array(obj, cantidad, desplazamiento=(2 * MODULO, 0.0, 0.0), nombre="Largo")
            array(obj, (plantas - planta_par + 1) // 2, desplazamiento=(0.0, 0.0, 2 * PLANTA), nombre="Plantas")
            objs.append(obj)
    return objs


def volumen_niebla(coleccion, minimo, maximo, densidad=0.011):
    malla = C.Malla()
    malla.caja(minimo, maximo)
    obj = malla.a_objeto("Niebla_Volumen", [], coleccion)
    mat = bpy.data.materials.new("MAT_Niebla_Patio")
    arbol = mat.node_tree
    for nodo in list(arbol.nodes):
        if nodo.type == "BSDF_PRINCIPLED":
            arbol.nodes.remove(nodo)
    vol = arbol.nodes.new("ShaderNodeVolumePrincipled")
    vol.inputs["Color"].default_value = (0.7, 0.79, 0.88, 1.0)
    vol.inputs["Density"].default_value = densidad
    vol.inputs["Anisotropy"].default_value = 0.62
    salida = next(n for n in arbol.nodes if n.type == "OUTPUT_MATERIAL")
    arbol.links.new(vol.outputs["Volume"], salida.inputs["Volume"])
    obj.data.materials.append(mat)
    obj.display_type = "BOUNDS"
    return obj


def luz(nombre, tipo, coleccion, energia, color, posicion, direccion=None, **props):
    datos = bpy.data.lights.new(nombre, tipo)
    datos.energy = energia
    datos.color = color
    for clave, valor in props.items():
        setattr(datos, clave, valor)
    obj = bpy.data.objects.new(nombre, datos)
    coleccion.objects.link(obj)
    obj.location = posicion
    if direccion is not None:
        obj.rotation_euler = Vector(direccion).to_track_quat("-Z", "Y").to_euler()
    return obj


def crear_patio():
    escena = C.reiniciar()
    mallas = enlazar_mallas()
    patio = C.coleccion("Patio_Central")
    col_muros = C.coleccion("Muros", patio)
    col_puentes = C.coleccion("Puentes", patio)
    col_detalles = C.coleccion("Detalles", patio)
    col_techo = C.coleccion("Techo_Tragaluz", patio)
    col_luz = C.coleccion("Luz_y_Niebla", patio)
    mod_a = mallas["M_Kit_Modulo_Celdas"]
    mod_b = mallas["M_Kit_Modulo_Celdas_B"]
    mod_c = mallas["M_Kit_Modulo_Celdas_C"]
    mod_d = mallas["M_Kit_Modulo_Celdas_D"]
    medio = ANCHO / 2

    # --- Muros de celdas: laterales (largo) y fondos (ancho) --------------------
    muro_de_celdas("Muro_Oeste", [mod_a, mod_b, mod_c, mod_d], col_muros, (-medio, LARGO / 2, 0),
                   -math.pi / 2, MODULOS, PLANTAS)
    muro_de_celdas("Muro_Este", [mod_c, mod_d, mod_a, mod_b], col_muros, (medio, -LARGO / 2, 0),
                   math.pi / 2, MODULOS, PLANTAS)
    muro_de_celdas("Muro_Norte", [mod_b, mod_a, mod_d, mod_c], col_muros, (medio + 1.4, LARGO / 2, 0),
                   math.pi, 3, PLANTAS)
    muro_de_celdas("Muro_Sur", [mod_d, mod_c, mod_b, mod_a], col_muros, (-medio - 1.4, -LARGO / 2, 0),
                   0.0, 3, PLANTAS)

    # --- Suelo del patio y techo con hueco para el tragaluz -----------------------
    mats = {m.name: m for m in bpy.data.materials}
    suelo = C.Malla()
    suelo.caja((-medio, -LARGO / 2, -0.6), (medio, LARGO / 2, 0.0), 0, 1 / 1.6)
    suelo.a_objeto("Suelo_Patio", [mats["MAT_Losa_Mojada"]], col_muros)
    techo = C.Malla()
    hx, hy = 7.2, 33.6
    z0, z1 = ALTO - 0.25, ALTO + 1.2
    for minimo, maximo in [((-medio - 3, -LARGO / 2 - 3, z0), (-hx, LARGO / 2 + 3, z1)),
                           ((hx, -LARGO / 2 - 3, z0), (medio + 3, LARGO / 2 + 3, z1)),
                           ((-hx, -LARGO / 2 - 3, z0), (hx, -hy, z1)),
                           ((-hx, hy, z0), (hx, LARGO / 2 + 3, z1))]:
        techo.caja(minimo, maximo, 0, 1 / 1.6)
    techo.a_objeto("Techo", [mats["MAT_Hormigon_Oscuro"]], col_techo)
    for nombre, malla in (("Tragaluz_Marco", mallas["M_Kit_Tragaluz_Marco"]),
                          ("Tragaluz_Vidrio", mallas["M_Kit_Tragaluz_Vidrio"])):
        obj = objeto(nombre, malla, col_techo, (-hx, -hy, ALTO + 0.6))
        array(obj, 3, desplazamiento=(4.8, 0, 0), nombre="Ancho")
        array(obj, 14, desplazamiento=(0, 4.8, 0), nombre="Largo")
        if "Vidrio" in nombre:
            obj.visible_shadow = False

    # --- Puentes ------------------------------------------------------------------
    tramo = mallas["M_Kit_Puente_Tramo"]
    for planta, y in PUENTES:
        obj = objeto(f"Puente_P{planta:02d}", tramo, col_puentes, (-medio + 1.2, y, planta * PLANTA))
        array(obj, 12, desplazamiento=(2.0, 0, 0), nombre="Tramos")
    tx, ty = TORRE
    for planta, lado in PUENTES_TORRE:
        x0 = 4.4 if lado > 0 else -(medio - 1.4)
        obj = objeto(f"Puente_Torre_P{planta:02d}_{'E' if lado > 0 else 'O'}", tramo, col_puentes,
                     (x0, ty, planta * PLANTA))
        array(obj, 4, desplazamiento=(2.0, 0, 0), nombre="Tramos")

    # --- Torre de vigilancia central ------------------------------------------------
    objeto("Torre_Vigilancia", mallas["M_Kit_Torre_Vigilancia"], col_detalles, (tx, ty, 0.0))

    # --- Estandartes rojos rasgados y sábanas colgadas ----------------------------------
    estandarte = mallas["M_Kit_Estandarte"]
    for i, (x, y, z, rot, esc) in enumerate([
            (-4.5, 24.0 - 0.95, 8 * PLANTA - 0.2, 0.0, 1.0),
            (6.0, 24.0 + 0.95, 8 * PLANTA - 0.2, 0.0, 0.9),
            (-2.0, 30.0 - 0.95, 12 * PLANTA - 0.2, 0.0, 1.25),
            (8.0, 30.0 - 0.95, 12 * PLANTA - 0.2, 0.0, 1.1),
            (-7.0, 18.0 - 0.95, 14 * PLANTA - 0.2, 0.0, 1.4),
            (4.0, 18.0 + 0.95, 14 * PLANTA - 0.2, 0.0, 1.2),
            (0.5, 6.0 - 0.95, 16 * PLANTA - 0.2, 0.0, 1.5),
            (-6.5, -6.0 + 0.95, 6 * PLANTA - 0.2, 0.0, 0.85),
            (medio - 2.2, 18.0, 15 * PLANTA + 1.0, math.pi / 2, 1.3),
            (medio - 2.2, -2.0, 13 * PLANTA + 1.0, math.pi / 2, 1.1),
            (-medio + 2.2, 30.0, 14 * PLANTA + 1.0, math.pi / 2, 1.2)]):
        objeto(f"Estandarte_{i:02d}", estandarte, col_detalles, (x, y, z), rot, esc)
    sabana = mallas["M_Kit_Sabana"]
    for i, (x, y, z, rot) in enumerate([
            (-medio + 1.62, 3.0, 8 * PLANTA + 1.05, math.pi / 2),
            (-medio + 1.62, 16.4, 7 * PLANTA + 1.05, math.pi / 2),
            (medio - 1.62, 9.0, 7 * PLANTA + 1.05, math.pi / 2),
            (medio - 1.62, 22.5, 11 * PLANTA + 1.05, math.pi / 2),
            (medio - 1.62, -4.0, 5 * PLANTA + 1.05, math.pi / 2),
            (-medio + 1.62, -12.0, 10 * PLANTA + 1.05, math.pi / 2)]):
        objeto(f"Sabana_{i:02d}", sabana, col_detalles, (x, y, z), rot)

    # --- Luz: sol entrando por el tragaluz, niebla y ambiente -----------------------
    mundo = bpy.data.worlds.new("Mundo_Patio")
    escena.world = mundo
    fondo = next(n for n in mundo.node_tree.nodes if n.type == "BACKGROUND")
    fondo.inputs["Color"].default_value = (0.018, 0.024, 0.032, 1.0)
    luz("Sol_Tragaluz", "SUN", col_luz, 14.0, (0.78, 0.87, 1.0), (0, 0, ALTO + 10),
        direccion=(0.1, 0.32, -1.0), angle=math.radians(1.5))
    luz("Cielo_Tragaluz", "AREA", col_luz, 12000.0, (0.62, 0.74, 0.9), (0, 0, ALTO - 0.6),
        direccion=(0, 0, -1), shape="RECTANGLE", size=13.0, size_y=66.0)
    luz("Cabina_Torre", "POINT", col_luz, 600.0, (1.0, 0.75, 0.45), (tx, ty, 37.0),
        shadow_soft_size=1.0)
    volumen_niebla(col_luz, (-medio + 0.05, -LARGO / 2, 0.0), (medio - 0.05, LARGO / 2, ALTO - 0.3))
    C.guardar_blend(C.RAIZ / "escenarios" / "patio_central.blend")


if __name__ == "__main__":
    crear_patio()
