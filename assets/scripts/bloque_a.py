"""Bloque A: celda de Elías y pasillo de celdas (referencia: Materiales/ac3d34e8-....png).

Genera:
  - assets/kit/kit_bloque_a.blend: tramo de pasillo con celdas a ambos lados (3 m) en dos variantes,
    y la celda de Elías (con camastro, letrina, ventanuco y marcas de conteo).
  - assets/escenarios/bloque_a.blend: la celda de Elías y 12 tramos de pasillo (36 m), con luz y niebla.
  - assets/escenas/plano_pasillo.blend + assets/renders/plano_pasillo.png: El Uniforme avanza por el
    pasillo; Elías mira hacia atrás.

Uso:
    blender --background --factory-startup --python assets/scripts/bloque_a.py [-- --borrador]
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy  # noqa: E402
import numpy as np  # noqa: E402
from mathutils import Vector  # noqa: E402

import comun as C  # noqa: E402
import kit_prision as K  # noqa: E402
import plano_patio as PP  # noqa: E402

TRAMO = 3.0          # largo de un tramo de pasillo
ANCHO = 2.2          # ancho del pasillo
ALTO = 2.8           # altura del techo
FONDO = 2.6          # fondo de cada celda
TRAMOS = 12
ESC_PARED = 1 / 3.2  # la textura de pared bicolor cubre 3,2 m de alto


# ------------------------------------------------------------------ Texturas ---

def tex_pared_bicolor(semilla=300, tam=128):
    """Pintura institucional: zócalo verde oscuro y parte alta gris verdosa, desconchada y sucia."""
    alto = tam
    n = C.ruido(alto, tam, semilla, 5, celdas=4)
    filas = np.arange(alto)[:, None] * np.ones((1, tam))
    limite = int(alto * (1 - 1.25 / 3.2))          # el zócalo llega a 1,25 m
    arriba = C.lienzo(alto, tam, (0.5, 0.54, 0.49)) * (0.75 + 0.45 * n[..., None])
    abajo = C.lienzo(alto, tam, (0.1, 0.22, 0.19)) * (0.7 + 0.5 * n[..., None])
    img = np.where((filas >= limite)[..., None], abajo, arriba)
    img[limite - 1:limite + 1] *= 0.45
    desconchado = C.suave(C.ruido(alto, tam, semilla + 1, 4, celdas=7), 0.62, 0.68)
    img = C.mezclar(img, (0.34, 0.35, 0.33), desconchado * 0.75)
    img = C.mezclar(img, (0.12, 0.11, 0.08), C.chorreones(alto, tam, semilla + 2, 40, 0.9) * 0.55)
    img = C.mezclar(img, (0.05, 0.05, 0.04), C.suave(filas, alto - 16, alto) * 0.7)
    img = C.mezclar(img, (0.25, 0.04, 0.03), C.manchas(alto, tam, semilla + 3, 3, 2, 6) * 0.6)
    img += C.grano(alto, tam, semilla + 4, 0.02)
    return C.guardar_png("escenario/pared_bicolor.png", C.posterizar(img, 36))


def tex_marcas_conteo(semilla=310):
    """Marcas de conteo de días rayadas en la pared (con transparencia)."""
    alto, ancho = 64, 128
    rgba = np.zeros((alto, ancho, 4))
    rgba[..., :3] = (0.82, 0.8, 0.72)
    rnd = np.random.default_rng(semilla)
    for fila in range(4):
        for grupo in range(6 - (fila == 3) * 3):
            x0 = 6 + grupo * 20
            y0 = 6 + fila * 14
            for i in range(4):
                x = x0 + i * 3 + int(rnd.integers(-1, 2))
                rgba[y0:y0 + 10, x, 3] = rnd.uniform(0.6, 0.9)
            for t in range(13):
                rgba[y0 + 9 - int(t * 0.7), x0 - 1 + t, 3] = 0.85
    return C.guardar_png("escenario/marcas_conteo.png", rgba)


def materiales_bloque():
    m = K.materiales()
    m["pared"] = C.material("MAT_Pared_Bicolor", tex_pared_bicolor(), rugosidad=0.75, especular=0.35)
    m["marcas"] = C.material("MAT_Marcas_Conteo", tex_marcas_conteo(), rugosidad=0.9, alfa=True)
    m["colchon"] = C.material("MAT_Colchon", K.tex_tela_colgante("colchon", (0.42, 0.4, 0.34), 320,
                                                                agujeros=0.0, sangre=0.3),
                              rugosidad=0.95)
    m["manta"] = C.material("MAT_Manta", K.tex_hormigon("manta_gris", (0.28, 0.27, 0.26), 321, verde=0.0,
                                                      chorros=10, encofrado=False), rugosidad=0.95)
    m["acero"] = C.material("MAT_Acero_Letrina", color=(0.42, 0.43, 0.44), rugosidad=0.35, metalico=0.9)
    m["luna"] = C.material_emisivo("MAT_Ventanuco_Luna", (0.55, 0.68, 0.85), 6.0)
    m["fluor_pasillo"] = C.material_emisivo("MAT_Fluor_Pasillo", (0.78, 0.95, 0.85), 40.0)
    return m


# -------------------------------------------------------------------- Piezas ---

def frente_celdas(malla, i, y, lado, x0, x1):
    """Frente de una celda: machón de pared, reja completa y dintel."""
    yy = (y, y + 0.25 * lado) if lado > 0 else (y - 0.25, y)
    malla.caja((x0, min(yy), 0.0), (x0 + 0.3, max(yy), ALTO), i["pared"], ESC_PARED)
    malla.caja((x0 + 0.3, min(yy), 2.3), (x1, max(yy), ALTO), i["pared"], ESC_PARED)
    K.reja_puerta(malla, x0 + 0.32, x1 - 0.02, y + 0.12 * lado, 2.3, i["oxido"])


def interior_celda(malla, i, y, lado, x0, x1, iluminada):
    y_a, y_b = sorted((y + 0.25 * lado, y + (FONDO + 0.25) * lado))
    mat = i["interior_luz"] if iluminada else i["interior"]
    K.caja_invertida(malla, (x0 + 0.05, y_a, 0.0), (x1 - 0.05, y_b, ALTO - 0.05), mat,
                     omitir=("-y",) if lado > 0 else ("+y",))
    # Camastro de hierro con colchón, y letrina.
    yc0, yc1 = sorted((y + (FONDO - 0.55) * lado, y + (FONDO + 0.2) * lado))
    malla.caja((x0 + 0.25, yc0, 0.4), (x0 + 2.2, yc1, 0.48), i["oxido"], 2.0)
    malla.caja((x0 + 0.28, yc0 + 0.02, 0.48), (x0 + 2.15, yc1 - 0.02, 0.6), i["colchon"], 1.0)
    for x in (x0 + 0.27, x0 + 2.18):
        malla.caja((x - 0.025, yc0, 0.0), (x + 0.025, yc0 + 0.05, 0.4), i["oxido"], 2.0)
    yl0, yl1 = sorted((y + 0.6 * lado, y + 1.0 * lado))
    malla.caja((x1 - 0.55, yl0, 0.0), (x1 - 0.15, yl1, 0.42), i["acero"], 2.0)
    if iluminada:
        malla.caja((x0 + 1.3, (y_a + y_b) / 2 - 0.1, ALTO - 0.15), (x0 + 1.7, (y_a + y_b) / 2 + 0.1, ALTO - 0.05),
                   i["bombilla"], 2.0)


def tramo_pasillo(m, iluminadas=(False, False), fluorescente_encendido=True, lados=(-1, 1)):
    """Tramo de 3 m de pasillo con una celda a cada lado (lados: cuáles llevan celda)."""
    malla = C.Malla()
    claves = ["pared", "oxido", "interior", "interior_luz", "colchon", "acero", "bombilla", "losa",
              "losa_bajo", "metal", "fluor_pasillo", "lampara_apagada"]
    i = {k: n for n, k in enumerate(claves)}
    medio = ANCHO / 2
    malla.caja((0.0, -medio - FONDO - 0.5, -0.3), (TRAMO, medio + FONDO + 0.5, 0.0), i["losa"], K.ESCALA)
    malla.caja((0.0, -medio - FONDO - 0.5, ALTO), (TRAMO, medio + FONDO + 0.5, ALTO + 0.3), i["losa_bajo"],
               K.ESCALA)
    for lado, iluminada in ((-1, iluminadas[0]), (1, iluminadas[1])):
        if lado not in lados:
            continue
        y = medio * lado
        frente_celdas(malla, i, y, lado, 0.0, TRAMO)
        interior_celda(malla, i, y, lado, 0.3, TRAMO, iluminada)
    # Fluorescente empotrado en el techo.
    malla.caja((1.0, -0.17, ALTO - 0.08), (2.0, 0.17, ALTO), i["metal"], 2.0)
    mat_tubo = i["fluor_pasillo"] if fluorescente_encendido else i["lampara_apagada"]
    for y in (-0.08, 0.04):
        malla.caja((1.05, y, ALTO - 0.11), (1.95, y + 0.04, ALTO - 0.08), mat_tubo, 2.0)
    return malla, [m[k] for k in claves]


def celda_elias(m, con_puerta=True):
    """Celda de Elías: 2,4 x 3 m, puerta de barrotes entornada, camastro, letrina, ventanuco y marcas.

    con_puerta=False: sin la puerta (para el juego, donde la puerta es una pieza aparte que se abre).
    """
    malla = C.Malla()
    claves = ["pared", "oxido", "colchon", "manta", "acero", "losa", "losa_bajo", "luna", "marcas", "interior"]
    i = {k: n for n, k in enumerate(claves)}
    ancho, fondo = 2.4, 3.0
    malla.caja((-0.3, -0.3, -0.3), (ancho + 0.3, fondo + 0.3, 0.0), i["losa"], K.ESCALA)
    malla.caja((-0.3, -0.3, ALTO), (ancho + 0.3, fondo + 0.3, ALTO + 0.3), i["losa_bajo"], K.ESCALA)
    malla.caja((-0.3, -0.3, 0.0), (0.0, fondo, ALTO), i["pared"], ESC_PARED)
    malla.caja((ancho, -0.3, 0.0), (ancho + 0.3, fondo, ALTO), i["pared"], ESC_PARED)
    # Pared del fondo con ventanuco enrejado.
    malla.caja((0.0, fondo, 0.0), (ancho, fondo + 0.3, 2.0), i["pared"], ESC_PARED)
    malla.caja((0.0, fondo, 2.45), (ancho, fondo + 0.3, ALTO), i["pared"], ESC_PARED)
    malla.caja((0.0, fondo, 2.0), (0.9, fondo + 0.3, 2.45), i["pared"], ESC_PARED)
    malla.caja((1.5, fondo, 2.0), (ancho, fondo + 0.3, 2.45), i["pared"], ESC_PARED)
    malla.caja((0.9, fondo + 0.28, 2.0), (1.5, fondo + 0.3, 2.45), i["luna"], 2.0)
    for x in (1.0, 1.1, 1.2, 1.3, 1.4):
        malla.cilindro((x, fondo + 0.15, 2.0), 0.015, 0.45, lados=6, material=i["oxido"], tapas=False)
    # Frente: reja fija y puerta entornada.
    malla.caja((0.0, -0.3, 2.3), (ancho, 0.0, ALTO), i["pared"], ESC_PARED)
    K.reja_puerta(malla, 0.02, 1.3, -0.15, 2.3, i["oxido"])
    if con_puerta:
        puerta = C.Malla()
        K.reja_puerta(puerta, 0.0, 1.05, 0.0, 2.3, i["oxido"])
        giro = math.radians(-55)
        for v in puerta.vertices:
            x, y = v.x, v.y
            v.x = 1.32 + x * math.cos(giro) - y * math.sin(giro)
            v.y = -0.15 + x * math.sin(giro) + y * math.cos(giro)
        malla.unir(puerta)
    # Camastro, manta arrugada, letrina y lavabo.
    malla.caja((0.05, 0.6, 0.42), (0.85, 2.85, 0.5), i["oxido"], 2.0)
    malla.caja((0.08, 0.63, 0.5), (0.82, 2.82, 0.64), i["colchon"], 1.0)
    malla.caja((0.1, 1.6, 0.64), (0.8, 2.5, 0.7), i["manta"], 1.0)
    for x, y in ((0.07, 0.62), (0.83, 0.62), (0.07, 2.83), (0.83, 2.83)):
        malla.caja((x - 0.02, y - 0.02, 0.0), (x + 0.02, y + 0.02, 0.42), i["oxido"], 2.0)
    malla.caja((ancho - 0.55, fondo - 0.6, 0.0), (ancho - 0.1, fondo - 0.05, 0.42), i["acero"], 2.0)
    malla.caja((ancho - 0.45, fondo - 0.25, 0.8), (ancho - 0.05, fondo - 0.02, 0.95), i["acero"], 2.0)
    # Marcas de conteo rayadas en la pared izquierda.
    malla.cuadrilatero(Vector((0.002, 0.9, 1.0)), Vector((0.002, 2.3, 1.0)), Vector((0.002, 2.3, 1.7)),
                       Vector((0.002, 0.9, 1.7)), i["marcas"])
    return malla, [m[k] for k in claves]


def tramo_inicio(m):
    """Primer tramo del pasillo en el juego: sin la celda del lado de Elías (su celda va ahí),
    con el hueco junto a ella tapado y el extremo del pasillo cerrado con un muro."""
    malla, mats = tramo_pasillo(m, (False, True), True, lados=(1,))
    medio = ANCHO / 2
    # Tapa el hueco entre la celda de Elías (hasta x = 2,6) y el machón del tramo siguiente.
    malla.caja((2.55, -medio - 0.28, 0.0), (3.0, -medio, ALTO), 0, ESC_PARED)
    # Muro del extremo del pasillo (x = 0).
    malla.caja((-0.35, -medio - 0.05, 0.0), (0.0, medio + 0.3, ALTO), 0, ESC_PARED)
    return malla, mats


def puerta_celda(m):
    """Puerta de barrotes de la celda de Elías, cerrada. Origen en la bisagra (gira sobre Z)."""
    malla = C.Malla()
    K.reja_puerta(malla, 0.0, 1.05, 0.0, 2.3, 0)
    # Cerradura: caja de chapa junto al borde libre.
    malla.caja((0.86, -0.07, 1.0), (1.02, 0.07, 1.22), 0, 2.0)
    return malla, [m["oxido"]]


def crear_kit():
    C.reiniciar()
    m = materiales_bloque()
    raiz = bpy.context.scene.collection

    def pieza(nombre, datos, x):
        col = C.coleccion(nombre, raiz)
        malla, mats = datos
        obj = malla.a_objeto(nombre, mats, col)
        obj.data.name = f"M_{nombre}"
        obj.location = (x, 0, 0)
    pieza("Kit_Pasillo_Tramo", tramo_pasillo(m, (False, True)), 0)
    pieza("Kit_Pasillo_Tramo_B", tramo_pasillo(m, (True, False), fluorescente_encendido=False), 4)
    pieza("Kit_Celda_Elias", celda_elias(m), 10)
    pieza("Kit_Celda_Elias_Cerrada", celda_elias(m, con_puerta=False), 14)
    pieza("Kit_Puerta_Celda", puerta_celda(m), 18)
    pieza("Kit_Pasillo_Tramo_Inicio", tramo_inicio(m), 22)
    C.guardar_blend(C.RAIZ / "kit" / "kit_bloque_a.blend")


# -------------------------------------------------------------------- Escenario ---

def crear_escenario():
    escena = C.reiniciar()
    with bpy.data.libraries.load(str(C.RAIZ / "kit" / "kit_bloque_a.blend"), link=True,
                                 relative=True) as (origen, destino):
        destino.meshes = [n for n in origen.meshes if n.startswith("M_Kit_")]
    mallas = {mm.name: mm for mm in destino.meshes}
    bloque = C.coleccion("Bloque_A")
    # Pasillo a lo largo de +X; los tramos A y B se alternan.
    for j, nombre in enumerate(("M_Kit_Pasillo_Tramo", "M_Kit_Pasillo_Tramo_B")):
        obj = bpy.data.objects.new(f"Pasillo_{'AB'[j]}", mallas[nombre])
        bloque.objects.link(obj)
        obj.location = (j * TRAMO, 0, 0)
        mod = obj.modifiers.new("Tramos", "ARRAY")
        mod.count = TRAMOS // 2
        mod.use_relative_offset = False
        mod.use_constant_offset = True
        mod.constant_offset_displace = (2 * TRAMO, 0, 0)
    # Celda de Elías al principio, abierta al pasillo por el lado sur.
    celda = bpy.data.objects.new("Celda_Elias", mallas["M_Kit_Celda_Elias"])
    bloque.objects.link(celda)
    celda.location = (-0.1, -ANCHO / 2 - 0.15, 0)
    celda.rotation_euler = (0, 0, math.pi)
    celda.location = (2.3, -ANCHO / 2 - 0.15 + 0.15, 0)
    # Muro del fondo con una puerta pesada.
    fondo = C.Malla()
    mats = {mm.name: mm for mm in bpy.data.materials}
    fondo.caja((TRAMOS * TRAMO, -ANCHO / 2 - 0.3, 0.0), (TRAMOS * TRAMO + 0.4, ANCHO / 2 + 0.3, ALTO), 0, ESC_PARED)
    fondo.caja((TRAMOS * TRAMO - 0.05, -0.6, 0.0), (TRAMOS * TRAMO, 0.6, 2.2), 1, 1.0)
    fondo.a_objeto("Fondo_Pasillo", [mats["MAT_Pared_Bicolor"], mats["MAT_Metal_Pintado"]], bloque)
    # Luz: un área bajo cada fluorescente encendido (tramos A), ambiente verdoso y niebla.
    for t in range(0, TRAMOS, 2):
        datos = bpy.data.lights.new(f"Fluor_{t:02d}", "AREA")
        datos.energy = 55.0
        datos.color = (0.78, 0.95, 0.86)
        datos.shape = "RECTANGLE"
        datos.size, datos.size_y = 0.9, 0.2
        obj = bpy.data.objects.new(f"Fluor_{t:02d}", datos)
        bloque.objects.link(obj)
        obj.location = (t * TRAMO + 1.5, 0.0, ALTO - 0.12)
    mundo = bpy.data.worlds.new("Mundo_Bloque_A")
    escena.world = mundo
    fondo_m = next(n for n in mundo.node_tree.nodes if n.type == "BACKGROUND")
    fondo_m.inputs["Color"].default_value = (0.012, 0.016, 0.015, 1.0)
    vol = C.Malla()
    vol.caja((-3.0, -ANCHO / 2, 0.0), (TRAMOS * TRAMO, ANCHO / 2, ALTO))
    obj_vol = vol.a_objeto("Niebla_Pasillo", [], bloque)
    mat = bpy.data.materials.new("MAT_Niebla_Pasillo")
    arbol = mat.node_tree
    for nodo in list(arbol.nodes):
        if nodo.type == "BSDF_PRINCIPLED":
            arbol.nodes.remove(nodo)
    v = arbol.nodes.new("ShaderNodeVolumePrincipled")
    v.inputs["Color"].default_value = (0.75, 0.85, 0.8, 1)
    v.inputs["Density"].default_value = 0.05
    v.inputs["Anisotropy"].default_value = 0.4
    arbol.links.new(v.outputs["Volume"], next(n for n in arbol.nodes if n.type == "OUTPUT_MATERIAL").inputs["Volume"])
    obj_vol.data.materials.append(mat)
    obj_vol.display_type = "BOUNDS"
    C.guardar_blend(C.RAIZ / "escenarios" / "bloque_a.blend")


def crear_escenario_juego():
    """Igual que el escenario, pero con la puerta de la celda como objeto aparte y cerrada
    (en Godot se abre tras la ganzúa). Se exporta a juego/assets/escenarios/bloque_a_juego.glb."""
    C.reiniciar()
    with bpy.data.libraries.load(str(C.RAIZ / "kit" / "kit_bloque_a.blend"), link=True,
                                 relative=True) as (origen, destino):
        destino.meshes = [n for n in origen.meshes if n.startswith("M_Kit_")]
    mallas = {mm.name: mm for mm in destino.meshes}
    bloque = C.coleccion("Bloque_A")
    # El primer tramo A se sustituye por el tramo de inicio (sin la celda que ocupa la de Elías).
    inicio = bpy.data.objects.new("Pasillo_Inicio", mallas["M_Kit_Pasillo_Tramo_Inicio"])
    bloque.objects.link(inicio)
    for j, nombre in enumerate(("M_Kit_Pasillo_Tramo", "M_Kit_Pasillo_Tramo_B")):
        obj = bpy.data.objects.new(f"Pasillo_{'AB'[j]}", mallas[nombre])
        bloque.objects.link(obj)
        obj.location = (2 * TRAMO if j == 0 else TRAMO, 0, 0)
        mod = obj.modifiers.new("Tramos", "ARRAY")
        mod.count = TRAMOS // 2 - (1 if j == 0 else 0)
        mod.use_relative_offset = False
        mod.use_constant_offset = True
        mod.constant_offset_displace = (2 * TRAMO, 0, 0)
    celda = bpy.data.objects.new("Celda_Elias", mallas["M_Kit_Celda_Elias_Cerrada"])
    bloque.objects.link(celda)
    celda.rotation_euler = (0, 0, math.pi)
    celda.location = (2.3, -ANCHO / 2, 0)
    # Bisagra de la puerta: (1,32, -0,15) en coordenadas de la celda, girada 180°.
    puerta = bpy.data.objects.new("Puerta_Celda_Elias", mallas["M_Kit_Puerta_Celda"])
    bloque.objects.link(puerta)
    puerta.rotation_euler = (0, 0, math.pi)
    puerta.location = (2.3 - 1.32, -ANCHO / 2 + 0.15, 0)
    fondo = C.Malla()
    mats = {mm.name: mm for mm in bpy.data.materials}
    fondo.caja((TRAMOS * TRAMO, -ANCHO / 2 - 0.3, 0.0), (TRAMOS * TRAMO + 0.4, ANCHO / 2 + 0.3, ALTO), 0, ESC_PARED)
    fondo.caja((TRAMOS * TRAMO - 0.05, -0.6, 0.0), (TRAMOS * TRAMO, 0.6, 2.2), 1, 1.0)
    fondo.a_objeto("Fondo_Pasillo", [mats["MAT_Pared_Bicolor"], mats["MAT_Metal_Pintado"]], bloque)
    C.guardar_blend(C.RAIZ / "escenarios" / "bloque_a_juego.blend")


# ------------------------------------------------------------------------ Plano ---

def crear_plano(borrador=False):
    escena = C.reiniciar()
    bloque = PP.enlazar_coleccion(C.RAIZ / "escenarios" / "bloque_a.blend", "Bloque_A")
    escena.collection.children.link(bloque)
    with bpy.data.libraries.load(str(C.RAIZ / "escenarios" / "bloque_a.blend"), link=True,
                                 relative=True) as (origen, destino):
        destino.worlds = ["Mundo_Bloque_A"]
    escena.world = destino.worlds[0]
    _, arm_elias = PP.personaje("elias_preso", "Elias_Preso", escena)
    _, arm_uniforme = PP.personaje("el_uniforme", "El_Uniforme", escena)
    # Elías camina hacia la cámara y mira atrás, por encima del hombro.
    PP.posar_elias(arm_elias, (1.9, -0.5, 0.0), -105, mirar_arriba=0.0)
    # Gira el tronco y la cabeza (sobre su propio eje) para mirar atrás por encima del hombro.
    PP.H.apuntar(arm_elias, "pecho", (0.0, 0.0, 1.0), giro=math.radians(-25))
    PP.H.apuntar(arm_elias, "cuello", (0.0, 0.0, 1.0), giro=math.radians(-35))
    PP.H.apuntar(arm_elias, "cabeza", (0.05, 0.05, 1.0), giro=math.radians(-60))
    PP.posar_uniforme(arm_uniforme, (10.5, 0.15, 0.0), 90)
    cam = PP.camara("Camara_Pasillo", (0.15, 0.45, 1.5), (12.0, 0.25, 1.3), 24)
    escena.camera = cam
    PP.luz("Clave_Elias", "AREA", 30.0, (0.8, 0.95, 0.88), (2.4, 0.3, 2.5), apuntar_a=(1.9, -0.5, 1.5), size=0.8)
    if borrador:
        C.configurar_render(escena, 640, 360, muestras=12, exposicion=0.6)
    else:
        C.configurar_render(escena, 1672, 941, muestras=48, exposicion=0.6)
    C.guardar_blend(C.RAIZ / "escenas" / "plano_pasillo.blend")
    sufijo = "_borrador" if borrador else ""
    C.renderizar(escena, C.RAIZ / "renders" / f"plano_pasillo{sufijo}.png")


if __name__ == "__main__":
    args = C.argumentos()
    crear_kit()
    if "--solo-juego" in args:
        # Solo la versión del juego (no toca el escenario ni el plano ya aprobados).
        crear_escenario_juego()
    else:
        crear_escenario()
        crear_escenario_juego()
        crear_plano(borrador="--borrador" in args)
