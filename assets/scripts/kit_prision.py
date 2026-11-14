"""Kit modular de la Penitenciaría Estatal N.º 314 (estilo PS1).

Genera assets/kit/kit_prision.blend: piezas reutilizables, cada una en su colección,
y sus texturas en assets/texturas/escenario/. Los escenarios enlazan estas piezas
(Archivo > Vincular), así que al editar el kit se actualizan todos los escenarios.

Medidas del módulo de celdas (eje X a lo largo del muro, +Y hacia el patio, Z arriba):
  - 3 celdas de 2,8 m + 1 pilar de 1,2 m = 9,6 m de largo.
  - Planta de 3,2 m de alto. La pasarela mide 1,6 m de fondo.
  - Origen: suelo de la pasarela, en el plano del muro, al principio del pilar.

Uso:
    blender --background --factory-startup --python assets/scripts/kit_prision.py
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy  # noqa: E402
import numpy as np  # noqa: E402
from mathutils import Vector  # noqa: E402

import comun as C  # noqa: E402

MODULO = 9.6        # largo de un módulo (3 celdas + pilar)
PLANTA = 3.2        # alto de una planta
PASARELA = 1.6      # fondo de la pasarela
CELDA = 2.8         # ancho de una celda
PILAR = 1.2         # ancho del pilar
LOSA = 0.25         # grosor de la losa de la pasarela
ESCALA = 1 / 1.6    # UV: la textura se repite cada 1,6 m (encaja con el módulo y la planta)


# ------------------------------------------------------------------ Texturas ---

def tex_hormigon(nombre, base, semilla, tam=128, verde=0.25, chorros=30, encofrado=True):
    n1 = C.ruido(tam, tam, semilla, octavas=5, celdas=4)
    n2 = C.ruido(tam, tam, semilla + 1, octavas=3, celdas=12)
    img = C.lienzo(tam, tam, base) * (0.72 + 0.5 * n1[..., None])
    img *= (0.9 + 0.2 * n2[..., None])
    musgo = C.suave(C.ruido(tam, tam, semilla + 2, 3, celdas=3), 0.6, 0.8) * verde
    img = C.mezclar(img, (0.17, 0.22, 0.2), musgo)
    img = C.mezclar(img, np.array(base) * 0.4, C.chorreones(tam, tam, semilla + 3, chorros, 0.9) * 0.55)
    if encofrado:
        for y in range(0, tam, tam // 2):
            img[y:y + 1] *= 0.6
            img[y + 1:y + 2] *= 0.85
    poros = np.random.default_rng(semilla + 4).random((tam, tam)) > 0.985
    img[poros] *= 0.5
    img += C.grano(tam, tam, semilla + 5, 0.02)
    return C.guardar_png(f"escenario/{nombre}.png", C.posterizar(img, 36))


def tex_losa(semilla=60, tam=128):
    n = C.ruido(tam, tam, semilla, 5, celdas=4)
    img = C.lienzo(tam, tam, (0.2, 0.215, 0.22)) * (0.7 + 0.6 * n[..., None])
    charcos = C.suave(C.ruido(tam, tam, semilla + 1, 3, celdas=3), 0.5, 0.7)
    img = C.mezclar(img, (0.05, 0.065, 0.075), charcos * 0.8)
    for linea in range(0, tam, tam // 4):
        img[linea] *= 0.55
        img[:, linea] *= 0.55
    img += C.grano(tam, tam, semilla + 2, 0.02)
    return C.guardar_png("escenario/losa_pasarela.png", C.posterizar(img, 36))


def tex_oxido(nombre, base, semilla, tam=64, oxido=0.85):
    n = C.ruido(tam, tam, semilla, 4, celdas=6)
    img = C.lienzo(tam, tam, base) * (0.65 + 0.7 * n[..., None])
    mancha = C.suave(C.ruido(tam, tam, semilla + 1, 4, celdas=6), 0.48, 0.66)
    img = C.mezclar(img, (0.33, 0.15, 0.06), mancha * oxido)
    img = C.mezclar(img, (0.18, 0.07, 0.03), C.suave(C.ruido(tam, tam, semilla + 2, 2, celdas=10), 0.62, 0.72) * oxido * 0.7)
    img += C.grano(tam, tam, semilla + 3, 0.02)
    return C.guardar_png(f"escenario/{nombre}.png", C.posterizar(img, 32))


def tex_tela_colgante(nombre, color, semilla, ancho=64, alto=128, agujeros=0.35, sangre=0.0):
    """Tela rasgada con transparencia (estandartes, sábanas)."""
    n = C.ruido(alto, ancho, semilla, 4, celdas=4)
    img = C.lienzo(alto, ancho, color) * (0.6 + 0.6 * n[..., None])
    pliegues = np.abs(np.sin(np.linspace(0, 7 * np.pi, ancho)))[None, :]
    img *= (0.8 + 0.25 * pliegues[..., None])
    img = C.mezclar(img, np.array(color) * 0.35, C.chorreones(alto, ancho, semilla + 1, 18, 0.7) * 0.6)
    if sangre:
        img = C.mezclar(img, (0.2, 0.02, 0.015), C.manchas(alto, ancho, semilla + 2, 5, 2, 8) * sangre)
    # Transparencia: borde inferior desgarrado y agujeros.
    filas = np.arange(alto)[:, None] / alto
    corte = 0.82 + 0.16 * C.ruido(1, ancho, semilla + 3, 3, celdas=4)[0][None, :]
    alfa = (filas < corte).astype(float)
    huecos = C.suave(C.ruido(alto, ancho, semilla + 4, 4, celdas=5), 0.78 - agujeros * 0.2, 0.8 - agujeros * 0.2)
    alfa *= 1 - huecos * (filas > 0.15)
    rgba = np.concatenate([np.clip(img + C.grano(alto, ancho, semilla + 5, 0.02), 0, 1),
                           alfa[..., None]], axis=2)
    return C.guardar_png(f"escenario/{nombre}.png", rgba)


def tex_vidrio(semilla=90, tam=64):
    n = C.ruido(tam, tam, semilla, 3, celdas=4)
    img = C.lienzo(tam, tam, (0.62, 0.72, 0.8)) * (0.75 + 0.35 * n[..., None])
    img = C.mezclar(img, (0.25, 0.28, 0.3), C.suave(C.ruido(tam, tam, semilla + 1, 3, celdas=3), 0.55, 0.8) * 0.7)
    img[:, :2] = img[:2, :] = (0.08, 0.09, 0.1)
    img[:, tam // 2:tam // 2 + 1] = img[tam // 2:tam // 2 + 1, :] = (0.12, 0.13, 0.14)
    return C.guardar_png("escenario/vidrio_tragaluz.png", C.posterizar(img, 24))


def materiales():
    m = {}
    m["muro"] = C.material("MAT_Hormigon_Muro", tex_hormigon("hormigon_muro", (0.33, 0.36, 0.38), 10),
                           rugosidad=0.88, especular=0.25)
    m["pilar"] = C.material("MAT_Hormigon_Pilar", tex_hormigon("hormigon_pilar", (0.3, 0.32, 0.33), 20,
                                                               verde=0.15, chorros=45),
                            rugosidad=0.9, especular=0.2)
    m["losa_bajo"] = C.material("MAT_Hormigon_Oscuro", tex_hormigon("hormigon_oscuro", (0.18, 0.19, 0.2), 30,
                                                                    verde=0.1, encofrado=False),
                                rugosidad=0.92, especular=0.2)
    m["losa"] = C.material("MAT_Losa_Mojada", tex_losa(), rugosidad=0.26, especular=0.55)
    m["oxido"] = C.material("MAT_Hierro_Oxidado", tex_oxido("hierro_oxidado", (0.16, 0.15, 0.15), 40),
                            rugosidad=0.62, metalico=0.55, especular=0.4)
    m["metal"] = C.material("MAT_Metal_Pintado", tex_oxido("metal_pintado", (0.16, 0.19, 0.19), 45, oxido=0.5),
                            rugosidad=0.55, metalico=0.4, especular=0.4)
    m["interior"] = C.material("MAT_Celda_Interior", tex_hormigon("celda_interior", (0.12, 0.13, 0.13), 50,
                                                                  verde=0.05, encofrado=False),
                               rugosidad=0.95, especular=0.1)
    m["lampara"] = C.material_emisivo("MAT_Lampara_Celda", (1.0, 0.88, 0.68), 6.5)
    m["interior_luz"] = C.material("MAT_Celda_Iluminada", tex_hormigon("celda_iluminada", (0.5, 0.42, 0.32), 55,
                                                                      verde=0.05, encofrado=False),
                                   rugosidad=0.9, especular=0.1, emision=(1.0, 0.72, 0.42),
                                   fuerza_emision=0.9)
    m["bombilla"] = C.material_emisivo("MAT_Bombilla_Celda", (1.0, 0.82, 0.55), 18.0)
    m["lampara_apagada"] = C.material("MAT_Lampara_Apagada", color=(0.05, 0.05, 0.045), rugosidad=0.3,
                                      especular=0.6)
    m["placa"] = C.material("MAT_Placa_Celda", color=(0.42, 0.4, 0.34), rugosidad=0.5, metalico=0.3)
    m["estandarte"] = C.material("MAT_Estandarte", tex_tela_colgante("estandarte_rojo", (0.42, 0.06, 0.05), 70,
                                                                     sangre=0.4),
                                 rugosidad=0.95, especular=0.1, alfa=True)
    m["sabana"] = C.material("MAT_Sabana", tex_tela_colgante("sabana_sucia", (0.62, 0.6, 0.55), 75,
                                                             agujeros=0.25, sangre=0.25),
                             rugosidad=0.95, especular=0.1, alfa=True)
    m["vidrio"] = C.material("MAT_Vidrio_Tragaluz", tex_vidrio(), rugosidad=0.3, especular=0.5,
                             emision=(0.55, 0.68, 0.8), fuerza_emision=1.6)
    m["fluorescente"] = C.material_emisivo("MAT_Tubo_Fluorescente", (0.78, 0.93, 0.95), 45.0)
    m["ventana_torre"] = C.material_emisivo("MAT_Ventana_Torre", (1.0, 0.8, 0.52), 2.2)
    return m


# ------------------------------------------------------------------ Piezas ---

def caja_invertida(malla, minimo, maximo, material, omitir=()):
    """Caja con las caras mirando hacia dentro (interiores de celda)."""
    inicio = len(malla.caras)
    malla.caja(minimo, maximo, material, ESCALA, caras_omitidas=omitir)
    for i in range(inicio, len(malla.caras)):
        indices, uvs, mat = malla.caras[i]
        malla.caras[i] = (indices[::-1], uvs[::-1], mat)


def barandilla(malla, x0, x1, y, mat, alto=1.05, separacion=1.4):
    n = max(1, round((x1 - x0) / separacion))
    for i in range(n + 1):
        x = x0 + (x1 - x0) * i / n
        malla.caja((x - 0.03, y - 0.03, 0.0), (x + 0.03, y + 0.03, alto), mat, 2.0)
    malla.caja((x0, y - 0.035, alto - 0.05), (x1, y + 0.035, alto + 0.01), mat, 2.0)
    malla.caja((x0, y - 0.015, 0.52), (x1, y + 0.015, 0.56), mat, 2.0)
    malla.caja((x0, y - 0.01, 0.02), (x1, y + 0.01, 0.14), mat, 2.0)


def reja_puerta(malla, x0, x1, y, alto, mat):
    """Barrotes de una puerta de celda."""
    barrotes = int((x1 - x0) / 0.11)
    for i in range(barrotes + 1):
        x = x0 + (x1 - x0) * i / barrotes
        malla.cilindro((x, y, 0.0), 0.017, alto, lados=6, material=mat, escala_uv=2.0, tapas=False)
    for z in (0.12, alto * 0.5, alto - 0.12):
        malla.caja((x0, y - 0.022, z - 0.03), (x1, y + 0.022, z + 0.03), mat, 2.0)
    for x in (x0, x1):
        malla.caja((x - 0.04, y - 0.04, 0.0), (x + 0.04, y + 0.04, alto), mat, 2.0)


def modulo_celdas(m, lamparas=(True, False, True), iluminadas=(False, False, False),
                  nombre="Kit_Modulo_Celdas"):
    """3 celdas + pilar + pasarela + barandilla. Ver medidas al principio del archivo.

    lamparas: lámpara exterior encendida en cada celda. iluminadas: celda con luz dentro.
    """
    malla = C.Malla()
    mats = ["muro", "pilar", "losa", "losa_bajo", "oxido", "interior", "lampara", "lampara_apagada",
            "placa", "interior_luz", "bombilla"]
    i = {k: n for n, k in enumerate(mats)}
    techo = PLANTA - LOSA
    # Pilar: columna en el borde de la pasarela + machón en el muro.
    malla.caja((0.2, 1.2, -LOSA), (PILAR - 0.2, 1.95, techo), i["pilar"], ESCALA)
    malla.caja((0.0, -0.4, -LOSA), (PILAR, 0.0, techo), i["pilar"], ESCALA)
    # Losa de la pasarela (arriba mojada, abajo hormigón oscuro).
    malla.caja((0.0, 0.0, -LOSA), (MODULO, PASARELA, 0.0), i["losa_bajo"], ESCALA, caras_omitidas=("+z",))
    malla.caja((0.0, 0.0, -0.001), (MODULO, PASARELA, 0.0), i["losa"], ESCALA,
               caras_omitidas=("-x", "+x", "-y", "+y", "-z"))
    barandilla(malla, PILAR - 0.2, MODULO, PASARELA - 0.05, i["oxido"])
    for c in range(3):
        x0 = PILAR + c * CELDA
        puerta_a, puerta_b = x0 + 0.9, x0 + 1.9
        # Muro con hueco de puerta.
        malla.caja((x0, -0.3, 0.0), (puerta_a, 0.0, techo), i["muro"], ESCALA)
        malla.caja((puerta_b, -0.3, 0.0), (x0 + CELDA, 0.0, techo), i["muro"], ESCALA)
        malla.caja((puerta_a, -0.3, 2.2), (puerta_b, 0.0, techo), i["muro"], ESCALA)
        reja_puerta(malla, puerta_a + 0.02, puerta_b - 0.02, -0.12, 2.2, i["oxido"])
        # Interior oscuro con un camastro.
        mat_int = i["interior_luz"] if iluminadas[c] else i["interior"]
        caja_invertida(malla, (x0 + 0.12, -3.3, 0.0), (x0 + CELDA - 0.12, -0.3, 2.8), mat_int,
                       omitir=("+y",))
        if iluminadas[c]:
            malla.caja((x0 + 1.2, -2.0, 2.72), (x0 + 1.6, -1.6, 2.8), i["bombilla"], 2.0)
        malla.caja((x0 + 0.2, -3.2, 0.38), (x0 + 0.95, -1.3, 0.5), i["oxido"], 2.0)
        malla.caja((x0 + 0.22, -3.18, 0.5), (x0 + 0.93, -1.32, 0.6), i["interior"], ESCALA)
        # Lámpara junto a la puerta y placa con el número sobre ella.
        mat_l = i["lampara"] if lamparas[c] else i["lampara_apagada"]
        malla.caja((x0 + 2.05, 0.0, 1.92), (x0 + 2.42, 0.07, 2.08), mat_l, 2.0)
        malla.caja((x0 + 2.0, 0.0, 1.88), (x0 + 2.47, 0.04, 2.12), i["oxido"], 2.0,
                   caras_omitidas=("-y", "+y"))
        malla.caja((puerta_a + 0.3, 0.0, 2.32), (puerta_b - 0.3, 0.025, 2.48), i["placa"], 2.0)
    return malla, [m[k] for k in mats]


def tramo_puente(m):
    """Tramo de puente de 2 m (eje X). Se repite con un modificador Array."""
    malla = C.Malla()
    mats = ["metal", "oxido", "losa_bajo"]
    malla.caja((0.0, -0.9, -0.18), (2.0, 0.9, 0.0), 0, 0.8)
    for y in (-0.65, 0.65):
        malla.caja((0.0, y - 0.06, -0.62), (2.0, y + 0.06, -0.18), 1, 1.0)
        malla.caja((0.0, y - 0.15, -0.66), (2.0, y + 0.15, -0.6), 1, 1.0)
    malla.caja((0.95, -0.7, -0.6), (1.05, 0.7, -0.18), 1, 1.0)
    for y in (-0.86, 0.86):
        for x in (0.0,):
            malla.caja((x - 0.03, y - 0.03, 0.0), (x + 0.03, y + 0.03, 1.05), 1, 2.0)
        malla.caja((0.0, y - 0.035, 1.0), (2.0, y + 0.035, 1.06), 1, 2.0)
        malla.caja((0.0, y - 0.015, 0.5), (2.0, y + 0.015, 0.54), 1, 2.0)
    return malla, [m[k] for k in mats]


def tela_colgante(material, ancho, alto, columnas, filas, semilla, ondulacion=0.12):
    """Tela colgando (estandarte o sábana): plano con ondas y borde irregular."""
    rnd = C.aleatorio(semilla)
    malla = C.Malla()
    vertices = []
    for f in range(filas + 1):
        fila = []
        for c in range(columnas + 1):
            x = (c / columnas - 0.5) * ancho
            z = -alto * f / filas
            y = math.sin(c / columnas * math.pi * 2.3 + f * 0.4) * ondulacion * (0.3 + f / filas)
            y += rnd.uniform(-0.03, 0.03) * (f / filas)
            if f == filas:
                z += rnd.uniform(0.0, 0.6)
            fila.append(malla.vertice((x, y, z)))
        vertices.append(fila)
    for f in range(filas):
        for c in range(columnas):
            idx = [vertices[f][c], vertices[f + 1][c], vertices[f + 1][c + 1], vertices[f][c + 1]]
            uvs = [(c / columnas, 1 - f / filas), (c / columnas, 1 - (f + 1) / filas),
                   ((c + 1) / columnas, 1 - (f + 1) / filas), ((c + 1) / columnas, 1 - f / filas)]
            malla.cara(idx, uvs, 0)
    return malla, [material]


def tragaluz(m):
    """Módulo de tragaluz de 4,8 x 4,8 m: marco (proyecta sombra) y vidrio (no)."""
    marco = C.Malla()
    for i in range(3):
        p = i * 2.4
        marco.caja((p - 0.12, -0.12, -0.5), (p + 0.12, 4.92, 0.0), 0, 1.0)
        marco.caja((-0.12, p - 0.12, -0.5), (4.92, p + 0.12, 0.0), 0, 1.0)
    for i in range(8):
        p = 0.3 + i * 0.6
        marco.caja((p - 0.025, 0.0, -0.08), (p + 0.025, 4.8, 0.0), 0, 2.0)
    vidrio = C.Malla()
    vidrio.caja((0.0, 0.0, 0.05), (4.8, 4.8, 0.08), 0, 1 / 2.4)
    return (marco, [m["metal"]]), (vidrio, [m["vidrio"]])


def fluorescente(m):
    malla = C.Malla()
    malla.caja((-0.65, -0.14, -0.08), (0.65, 0.14, 0.0), 0, 2.0)
    malla.caja((-0.6, -0.08, -0.12), (0.6, -0.03, -0.08), 1, 2.0)
    malla.caja((-0.6, 0.03, -0.12), (0.6, 0.08, -0.08), 1, 2.0)
    return malla, [m["metal"], m["fluorescente"]]


def torre_vigilancia(m):
    """Torre central: fuste octogonal, cabina con ventanas iluminadas, megáfonos."""
    malla = C.Malla()
    mats = ["pilar", "metal", "ventana_torre", "oxido", "losa_bajo"]
    lados = 8

    def prisma(r, z0, z1, mat, escala=ESCALA):
        malla.cilindro((0, 0, z0), r, z1 - z0, lados=lados, material=mat, escala_uv=escala)
    prisma(2.3, 0.0, 34.0, 0)
    prisma(2.9, 33.5, 34.3, 4)
    prisma(3.25, 34.3, 35.6, 0)
    prisma(3.15, 35.6, 38.3, 2)
    for k in range(lados):
        a = 2 * math.pi * (k + 0.5) / lados
        x, y = math.cos(a) * 3.2, math.sin(a) * 3.2
        malla.caja((x - 0.12, y - 0.12, 35.6), (x + 0.12, y + 0.12, 38.3), 1, 2.0)
    prisma(3.6, 38.3, 38.8, 0)
    malla.cilindro((0, 0, 38.8), 2.6, 1.2, lados=lados, material=4, escala_uv=ESCALA)
    # Pasarela perimetral con barandilla.
    malla.cilindro((0, 0, 34.0), 4.4, 0.3, lados=lados, material=4, escala_uv=ESCALA)
    for k in range(lados * 2):
        a = 2 * math.pi * k / (lados * 2)
        x, y = math.cos(a) * 4.3, math.sin(a) * 4.3
        malla.caja((x - 0.03, y - 0.03, 34.3), (x + 0.03, y + 0.03, 35.35), 3, 2.0)
    malla.cilindro((0, 0, 35.3), 4.3, 0.06, lados=lados * 2, material=3, escala_uv=2.0, tapas=False)
    # Megáfonos (conos de 6 lados) en tres direcciones.
    for ang in (0.4, 2.5, 4.4):
        base = Vector((math.cos(ang) * 3.3, math.sin(ang) * 3.3, 39.6))
        eje = Vector((math.cos(ang), math.sin(ang), -0.35)).normalized()
        anillos = []
        for t, r in ((0.0, 0.12), (1.1, 0.55)):
            c = base + eje * t
            lado = eje.cross(Vector((0, 0, 1))).normalized()
            arriba = lado.cross(eje).normalized()
            anillos.append([malla.vertice(c + (lado * math.cos(2 * math.pi * j / 6) + arriba * math.sin(2 * math.pi * j / 6)) * r)
                            for j in range(6)])
        for j in range(6):
            j2 = (j + 1) % 6
            malla.cara([anillos[0][j], anillos[0][j2], anillos[1][j2], anillos[1][j]],
                       [(0, 0), (1, 0), (1, 1), (0, 1)], 1)
        malla.caja((base.x - 0.08, base.y - 0.08, base.z - 0.6), (base.x + 0.08, base.y + 0.08, base.z), 3, 2.0)
    return malla, [m[k] for k in mats]


# -------------------------------------------------------------------- Kit ---

def crear_kit():
    C.reiniciar()
    m = materiales()
    raiz = bpy.context.scene.collection

    def pieza(nombre, malla_y_mats, posicion=(0, 0, 0), sin_sombra=False):
        col = C.coleccion(nombre, raiz)
        malla, mats = malla_y_mats
        obj = malla.a_objeto(nombre, mats, col)
        obj.data.name = f"M_{nombre}"
        obj.location = posicion
        if sin_sombra:
            obj.visible_shadow = False
        return obj

    x = 0.0
    pieza("Kit_Modulo_Celdas", modulo_celdas(m, (True, False, False), (False, True, False)), (x, 0, 0)); x += 12
    pieza("Kit_Modulo_Celdas_B", modulo_celdas(m, (False, False, True), (True, False, False)), (x, 0, 0)); x += 12
    pieza("Kit_Modulo_Celdas_C", modulo_celdas(m, (False, True, False), (False, False, True)), (x, 0, 0)); x += 12
    pieza("Kit_Modulo_Celdas_D", modulo_celdas(m, (True, False, True), (False, False, False)), (x, 0, 0)); x += 12
    pieza("Kit_Puente_Tramo", tramo_puente(m), (x, 0, 0)); x += 4
    pieza("Kit_Estandarte", tela_colgante(m["estandarte"], 2.2, 7.5, 6, 18, 71), (x, 0, 8)); x += 4
    pieza("Kit_Sabana", tela_colgante(m["sabana"], 1.3, 2.0, 4, 8, 76, ondulacion=0.06), (x, 0, 3)); x += 3
    marco, vidrio = tragaluz(m)
    pieza("Kit_Tragaluz_Marco", marco, (x, 0, 0))
    pieza("Kit_Tragaluz_Vidrio", vidrio, (x, 0, 0), sin_sombra=True); x += 7
    pieza("Kit_Fluorescente", fluorescente(m), (x, 0, 3)); x += 3
    pieza("Kit_Torre_Vigilancia", torre_vigilancia(m), (x + 5, 0, 0))
    C.guardar_blend(C.RAIZ / "kit" / "kit_prision.blend")


if __name__ == "__main__":
    crear_kit()
