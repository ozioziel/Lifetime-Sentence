"""La prisión en el pasado (F3): el Patio Central en funcionamiento, con luz cálida, guardias y presos.

Referencia: Materiales/c21d90ea-....png (Elías, de civil, huye por una pasarela perseguido por guardias;
a la derecha, el patio con la torre, los puentes y los presos abajo).

El escenario ENLAZA las colecciones del Patio Central (muros, puentes, detalles y tragaluz): si se cambia
el patio, el pasado cambia con él. Solo son propias la luz cálida, la niebla de polvo y el mundo.
Los figurantes (presos y guardias) son instancias de colección de sus personajes: cuestan poco y se
pueden mover a mano; los tres personajes principales del plano van con override para posarlos.

Genera:
  assets/escenarios/prision_pasado.blend
  assets/escenas/plano_prision_pasado.blend
  assets/renders/plano_prision_pasado.png

Uso:
    blender --background --factory-startup --python assets/scripts/prision_pasado.py [-- --borrador]
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import callejon as CJ  # noqa: E402
import comun as C  # noqa: E402
import plano_patio as PP  # noqa: E402
from kit_prision import PASARELA, PLANTA  # noqa: E402
from patio_central import ALTO, ANCHO, LARGO, TORRE  # noqa: E402

X_MURO = -ANCHO / 2                 # frente de las celdas del muro oeste
PLANTA_HUIDA = 2                    # planta de la pasarela por la que huye Elías
Z = PLANTA_HUIDA * PLANTA
CALIDO = (1.0, 0.8, 0.55)


def luz(coleccion, nombre, tipo, energia, color, pos, apuntar=None, **p):
    d = bpy.data.lights.new(nombre, tipo)
    d.energy = energia
    d.color = color
    for k, v in p.items():
        setattr(d, k, v)
    o = bpy.data.objects.new(nombre, d)
    coleccion.objects.link(o)
    o.location = pos
    if apuntar is not None:
        o.rotation_euler = (Vector(apuntar) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
    return o


def niebla(coleccion, minimo, maximo, densidad, color):
    malla = C.Malla()
    malla.caja(minimo, maximo)
    obj = malla.a_objeto("Niebla_Polvo", [], coleccion)
    mat = bpy.data.materials.new("MAT_Niebla_Pasado")
    arbol = mat.node_tree
    for nodo in list(arbol.nodes):
        if nodo.type == "BSDF_PRINCIPLED":
            arbol.nodes.remove(nodo)
    v = arbol.nodes.new("ShaderNodeVolumePrincipled")
    v.inputs["Color"].default_value = (*color, 1)
    v.inputs["Density"].default_value = densidad
    v.inputs["Anisotropy"].default_value = 0.5
    salida = next(n for n in arbol.nodes if n.type == "OUTPUT_MATERIAL")
    arbol.links.new(v.outputs["Volume"], salida.inputs["Volume"])
    obj.data.materials.append(mat)
    obj.display_type = "BOUNDS"


def crear_escenario():
    C.reiniciar()
    raiz = C.coleccion("Prision_Pasado")
    with bpy.data.libraries.load(str(C.RAIZ / "escenarios" / "patio_central.blend"), link=True,
                                 relative=True) as (origen, destino):
        destino.collections = ["Muros", "Puentes", "Detalles", "Techo_Tragaluz"]
    for col in destino.collections:
        raiz.children.link(col)
    col_luz = C.coleccion("Luz_Calida", raiz)
    medio = ANCHO / 2

    mundo = bpy.data.worlds.new("Mundo_Prision_Pasado")
    bpy.context.scene.world = mundo
    fondo = next(n for n in mundo.node_tree.nodes if n.type == "BACKGROUND")
    fondo.inputs["Color"].default_value = (0.03, 0.025, 0.018, 1.0)
    # Tarde: sol dorado y oblicuo por el tragaluz, cielo cálido y polvo en suspensión.
    sol = luz(col_luz, "Sol_Tarde", "SUN", 15.0, (1.0, 0.86, 0.66), (0, 0, ALTO + 10), angle=math.radians(1.5))
    sol.rotation_euler = Vector((0.22, 0.3, -1.0)).to_track_quat("-Z", "Y").to_euler()
    luz(col_luz, "Cielo_Tragaluz", "AREA", 6000.0, (0.95, 0.85, 0.7), (0, 0, ALTO - 0.6), (0, 0, 0),
        shape="RECTANGLE", size=13.0, size_y=66.0)
    # Rebote cálido del suelo del patio y de las celdas iluminadas.
    luz(col_luz, "Rebote_Patio", "AREA", 1800.0, CALIDO, (0, 0, 1.0), (0, 0, ALTO),
        shape="RECTANGLE", size=20.0, size_y=70.0)
    tx, ty = TORRE
    luz(col_luz, "Cabina_Torre", "POINT", 900.0, (1.0, 0.75, 0.45), (tx, ty, 37.0), shadow_soft_size=1.0)
    niebla(col_luz, (-medio + 0.05, -LARGO / 2, 0.0), (medio - 0.05, LARGO / 2, ALTO - 0.3), 0.009,
           (1.0, 0.88, 0.7))
    C.guardar_blend(C.RAIZ / "escenarios" / "prision_pasado.blend")


# ================================================================ Plano ===

def figurante(escena, coleccion, nombre, pos, angulo):
    """Instancia de colección (figurante sin posar, muy barato)."""
    obj = bpy.data.objects.new(nombre, None)
    obj.instance_type = "COLLECTION"
    obj.instance_collection = coleccion
    obj.location = pos
    obj.rotation_euler = (0, 0, math.radians(angulo))
    escena.collection.objects.link(obj)
    return obj


def fluorescente_calido(escena, nombre, pos, energia):
    malla = bpy.data.meshes.get("M_Kit_Fluorescente")
    if malla is None:
        with bpy.data.libraries.load(str(C.RAIZ / "kit" / "kit_prision.blend"), link=True,
                                     relative=True) as (origen, destino):
            destino.meshes = ["M_Kit_Fluorescente"]
        malla = destino.meshes[0]
    obj = bpy.data.objects.new(nombre, malla)
    escena.collection.objects.link(obj)
    obj.location = pos
    obj.rotation_euler = (0, 0, math.pi / 2)
    d = bpy.data.lights.new(f"{nombre}_Luz", "AREA")
    d.energy, d.color, d.shape = energia, (1.0, 0.78, 0.48), "RECTANGLE"
    d.size, d.size_y = 0.25, 1.25
    o = bpy.data.objects.new(f"{nombre}_Luz", d)
    escena.collection.objects.link(o)
    o.location = Vector(pos) - Vector((0, 0, 0.14))


def crear_plano(borrador):
    escena = C.reiniciar()
    ruta = C.RAIZ / "escenarios" / "prision_pasado.blend"
    escena.collection.children.link(PP.enlazar_coleccion(ruta, "Prision_Pasado"))
    with bpy.data.libraries.load(str(ruta), link=True, relative=True) as (origen, destino):
        destino.worlds = ["Mundo_Prision_Pasado"]
    escena.world = destino.worlds[0]

    # Protagonistas: Elías huye hacia la cámara mirando atrás; dos guardias lo persiguen.
    y0 = 2.0
    _, elias = PP.personaje("elias_civil", "Elias_Civil", escena)
    elias.location = (X_MURO + 0.7, y0 + 3.6, Z)
    CJ.pose_correr(elias, 4, mirar_atras=70)
    _, guardia = PP.personaje("guardia_penitenciario", "Guardia_Penitenciario", escena)
    guardia.location = (X_MURO + 1.2, y0 + 6.6, Z)
    CJ.pose_correr(guardia, -3, alcanzar=True)

    # Figurantes: presos en el patio, guardias en puentes, pasarelas y junto a la torre.
    cols = {n: PP.enlazar_coleccion(C.RAIZ / "personajes" / f"{a}.blend", n) for a, n in (
        ("preso_generico_a", "Preso_Generico_A"), ("preso_generico_b", "Preso_Generico_B"),
        ("preso_generico_c", "Preso_Generico_C"), ("guardia_penitenciario", "Guardia_Penitenciario"),
        ("policia_patrullero", "Policia_Patrullero"))}
    presos = ["Preso_Generico_A", "Preso_Generico_B", "Preso_Generico_C"]
    rnd = random.Random(314)
    for i in range(34):
        x, y = rnd.uniform(-10.5, 10.5), rnd.uniform(-20.0, 36.0)
        if abs(x - TORRE[0]) < 4 and abs(y - TORRE[1]) < 4:
            continue
        figurante(escena, cols[presos[i % 3]], f"Preso_{i:02d}", (x, y, 0.0), rnd.uniform(-180, 180))
    for i, (x, y) in enumerate(((-2.0, 6.0), (4.0, 14.0), (-6.0, 22.0), (6.0, 30.0), (1.0, -10.0))):
        figurante(escena, cols["Guardia_Penitenciario"], f"Guardia_Patio_{i}", (x, y, 0.0), rnd.uniform(-180, 180))
    # Guardias asomados a las barandillas de las pasarelas de enfrente (miran al patio, hacia -X).
    for i, (planta, y) in enumerate(((1, 6.0), (2, 18.0), (3, -4.0), (4, 26.0), (5, 10.0), (6, 30.0), (3, 34.0))):
        figurante(escena, cols["Guardia_Penitenciario"], f"Guardia_Este_{i}",
                  (ANCHO / 2 - PASARELA + 0.45, y, planta * PLANTA), -90)
    # Presos en sus pasarelas y guardias de ronda en los puentes.
    for i, (planta, y) in enumerate(((3, 12.0), (4, 3.0), (5, 22.0), (6, 16.0))):
        figurante(escena, cols[presos[i % 3]], f"Preso_Este_{i}", (ANCHO / 2 - PASARELA + 0.5, y, planta * PLANTA), -90)
    for i, (planta, y, x) in enumerate(((4, 20.0, -3.0), (4, 20.0, 5.5), (6, -6.0, 1.0), (8, 24.0, -2.0),
                                         (8, 24.0, 6.0), (10, 20.0, 0.0), (12, 30.0, 3.0))):
        figurante(escena, cols["Guardia_Penitenciario"], f"Guardia_Puente_{i}", (x, y + 0.05, planta * PLANTA),
                  180 if i % 2 else 0)
    figurante(escena, cols["Policia_Patrullero"], "Policia_Torre", (TORRE[0] + 1.5, TORRE[1] + 2.5, 10 * PLANTA), 0)
    # Más perseguidores al fondo de la pasarela.
    figurante(escena, cols["Guardia_Penitenciario"], "Guardia_Fondo_1", (X_MURO + 0.5, y0 + 10.5, Z), 0)
    figurante(escena, cols["Policia_Patrullero"], "Policia_Fondo", (X_MURO + 0.95, y0 + 13.0, Z), 4)

    techo = Z + PLANTA - 0.27
    fluorescente_calido(escena, "Fluor_Pasarela_A", (X_MURO + 0.75, y0 + 2.4, techo), 80.0)
    fluorescente_calido(escena, "Fluor_Pasarela_B", (X_MURO + 0.75, y0 + 8.4, techo), 65.0)
    fluorescente_calido(escena, "Fluor_Pasarela_C", (X_MURO + 0.75, y0 + 14.4, techo), 50.0)
    PP.luz("Relleno_Elias", "AREA", 35.0, (1.0, 0.85, 0.65), (X_MURO + 2.5, y0 + 1.2, Z + 1.8),
           apuntar_a=(X_MURO + 0.7, y0 + 3.6, Z + 1.5), size=1.5)

    escena.camera = PP.camara("Camara_Huida", (X_MURO + 1.2, y0, Z + 1.5), (-4.5, y0 + 20.0, Z + 3.8), 20)
    if borrador:
        C.configurar_render(escena, 640, 360, muestras=12, exposicion=0.7)
    else:
        C.configurar_render(escena, 1672, 941, muestras=48, exposicion=0.7)
    C.guardar_blend(C.RAIZ / "escenas" / "plano_prision_pasado.blend")
    C.renderizar(escena, C.RAIZ / "renders" / f"plano_prision_pasado{'_borrador' if borrador else ''}.png")


if __name__ == "__main__":
    args = C.argumentos()
    if "--solo-plano" not in args:
        crear_escenario()
    crear_plano("--borrador" in args)
