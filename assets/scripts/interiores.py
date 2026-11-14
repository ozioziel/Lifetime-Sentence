"""Interiores de la Penitenciaría y del pasado: kit de muebles y cuatro escenarios con su plano.

Escenarios (cada uno con su plano renderizado):
  - enfermeria      Capítulo III: camas, quirófano, vitrinas, espejos, sangre. El Condenado acecha.
  - comisaria       F2 «El interrogatorio»: sala con mesa, lámpara colgante y espejo unidireccional.
  - ejecucion       Capítulo IV: sala de ejecución con plataforma, hoja, mecanismos y pilares (jefe).
  - nucleo          Final: núcleo de control, pantallas, escudo de la institución y El Director.

Genera assets/kit/kit_interiores.blend, assets/escenarios/<nombre>.blend,
assets/escenas/plano_<nombre>.blend y assets/renders/plano_<nombre>.png.

Uso:
    blender --background --factory-startup --python assets/scripts/interiores.py -- kit enfermeria comisaria ejecucion nucleo [--borrador]
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy  # noqa: E402
import numpy as np  # noqa: E402
from mathutils import Vector  # noqa: E402

import comun as C  # noqa: E402
import elenco as EL  # noqa: E402
import humano as H  # noqa: E402
import kit_prision as K  # noqa: E402
import plano_patio as PP  # noqa: E402

KIT = C.RAIZ / "kit" / "kit_interiores.blend"

# ================================================================ Rótulos ===

FUENTE = {
    "A": "010101111101101", "B": "110101110101110", "C": "011100100100011", "D": "110101101101110",
    "E": "111100110100111", "F": "111100110100100", "G": "011100101101011", "H": "101101111101101",
    "I": "111010010010111", "J": "001001001101010", "K": "101101110101101", "L": "100100100100111",
    "M": "101111111101101", "N": "110101101101101", "O": "010101101101010", "P": "110101110100100",
    "Q": "010101101110011", "R": "110101110101101", "S": "011100010001110", "T": "111010010010010",
    "U": "101101101101111", "V": "101101101101010", "W": "101101111111101", "X": "101101010101101",
    "Y": "101101010010010", "Z": "111001010100111", "0": "111101101101111", "1": "010110010010111",
    "2": "110001010100111", "3": "110001010001110", "4": "101101111001001", "5": "111100110001110",
    "6": "011100110101010", "7": "111001010010010", "8": "010101010101010", "9": "010101011001110",
    " ": "000000000000000", ".": "000000000000010", "-": "000000111000000", "º": "010101010000111",
}
ACENTOS = {"Á": "A", "É": "E", "Í": "I", "Ó": "O", "Ú": "U"}


def rotulo(texto, color_texto, color_fondo, escala=2, margen=3, semilla=1, gastado=0.25):
    """Imagen de un cartel con texto pixelado (fila 0 = arriba)."""
    ancho = (len(texto) * 4 - 1) * escala + 2 * margen
    alto = 7 * escala + 2 * margen
    img = C.lienzo(alto, ancho, color_fondo) * (0.85 + 0.25 * C.ruido(alto, ancho, semilla, 3)[..., None])
    for i, letra in enumerate(texto):
        base = ACENTOS.get(letra, letra)
        glifo = FUENTE.get(base, FUENTE[" "])
        for k, bit in enumerate(glifo):
            if bit == "1":
                fy, fx = divmod(k, 3)
                y0 = margen + (fy + 2) * escala
                x0 = margen + (i * 4 + fx) * escala
                img[y0:y0 + escala, x0:x0 + escala] = color_texto
        if letra in ACENTOS:
            x0 = margen + (i * 4 + 1) * escala
            img[margen:margen + escala, x0 + escala // 2:x0 + escala // 2 + escala] = color_texto
    sucio = C.suave(C.ruido(alto, ancho, semilla + 1, 3, celdas=4), 0.55, 0.8) * gastado
    return C.mezclar(img, np.array(color_fondo) * 0.4, sucio)


# =============================================================== Texturas ===

def tex_azulejo_yeso(nombre, color_azulejo, color_yeso, semilla, fraccion_azulejo=0.55, tam=128):
    """Pared que cubre 3,2 m: azulejos abajo y yeso arriba, sucia y agrietada."""
    img = C.lienzo(tam, tam, color_yeso) * (0.75 + 0.45 * C.ruido(tam, tam, semilla, 5, celdas=4)[..., None])
    limite = int(tam * (1 - fraccion_azulejo))
    lado = 8
    zona = img[limite:]
    zona[:] = np.array(color_azulejo) * (0.9 + 0.15 * C.ruido(tam - limite, tam, semilla + 1, 2, celdas=16)[..., None])
    for y in range(0, tam - limite, lado):
        zona[y] = np.array(color_azulejo) * 0.55
    for x in range(0, tam, lado):
        zona[:, x] = np.array(color_azulejo) * 0.55
    img[limite - 2:limite] *= 0.6
    img = C.mezclar(img, (0.25, 0.22, 0.16), C.chorreones(tam, tam, semilla + 2, 40, 0.9) * 0.55)
    grietas = np.abs(C.ruido(tam, tam, semilla + 3, 4, celdas=5) - 0.5) < 0.005
    img[grietas] *= 0.7
    img = C.mezclar(img, (0.06, 0.06, 0.05), C.suave(np.arange(tam)[:, None] * np.ones((1, tam)), tam - 10, tam) * 0.6)
    return C.guardar_png(f"escenario/{nombre}.png", C.posterizar(img + C.grano(tam, tam, semilla, 0.02), 36))


def tex_ajedrez(nombre, a, b, semilla, celdas=8, tam=128):
    """Linóleo o baldosa en damero, gastado y con manchas."""
    yy, xx = np.mgrid[0:tam, 0:tam]
    patron = ((yy // (tam // celdas) + xx // (tam // celdas)) % 2).astype(bool)
    img = np.where(patron[..., None], np.array(a), np.array(b)).astype(float)
    img *= (0.75 + 0.45 * C.ruido(tam, tam, semilla, 5, celdas=4))[..., None]
    img = C.mezclar(img, (0.08, 0.07, 0.05), C.suave(C.ruido(tam, tam, semilla + 1, 4, celdas=3), 0.55, 0.8) * 0.6)
    return C.guardar_png(f"escenario/{nombre}.png", C.posterizar(img + C.grano(tam, tam, semilla, 0.02), 36))


def tex_sangre(semilla=500, tam=128):
    """Charco y salpicaduras de sangre con transparencia."""
    rgba = np.zeros((tam, tam, 4))
    n = C.ruido(tam, tam, semilla, 4, celdas=4)
    rgba[..., :3] = np.array((0.22, 0.015, 0.01)) * (0.6 + 0.6 * n[..., None])
    yy, xx = np.mgrid[0:tam, 0:tam]
    d = np.sqrt((yy - tam / 2) ** 2 + (xx - tam / 2) ** 2) / (tam / 2)
    charco = C.suave(0.75 - d + (n - 0.5) * 0.6, 0.0, 0.08)
    gotas = C.manchas(tam, tam, semilla + 1, 14, 1.5, 4) * (d > 0.5)
    rgba[..., 3] = np.clip(charco + gotas, 0, 1)
    return C.guardar_png("escenario/sangre_charco.png", rgba)


def tex_pantalla(semilla=510, tam=64):
    """Monitor CRT: ruido, líneas de barrido y una imagen de cámara de vigilancia."""
    n = C.ruido(tam, tam, semilla, 3, celdas=6)
    img = C.lienzo(tam, tam, (0.45, 0.6, 0.55)) * (0.4 + 0.6 * n[..., None])
    img[::2] *= 0.55
    img[tam // 2:, tam // 4:tam // 2] *= 0.4
    img[:, :2] = img[:, -2:] = img[:2] = img[-2:] = 0.02
    return C.guardar_png("escenario/pantalla_crt.png", img)


def tex_emblema(semilla=520):
    """Estandarte con el escudo de la Penitenciaría Estatal N.º 314 (balanza y rejas)."""
    alto, ancho = 256, 128
    img = C.lienzo(alto, ancho, (0.38, 0.05, 0.04)) * (0.7 + 0.45 * C.ruido(alto, ancho, semilla, 4)[..., None])
    oro = np.array((0.7, 0.58, 0.28))
    yy, xx = np.mgrid[0:alto, 0:ancho]
    cy, cx = 100, 64
    d = np.sqrt((yy - cy) ** 2 + (xx - cx) ** 2)
    img[(d > 40) & (d < 46)] = oro
    img[(np.abs(xx - cx) < 3) & (yy > cy - 32) & (yy < cy + 30)] = oro            # fiel de la balanza
    img[(np.abs(yy - (cy - 20)) < 2) & (np.abs(xx - cx) < 28)] = oro               # brazo
    for s in (-1, 1):
        plato = (np.abs(yy - (cy + 2 - np.abs(xx - cx - s * 22) * 0.0)) < 2) & (np.abs(xx - cx - s * 22) < 9)
        img[plato] = oro
        img[(np.abs(xx - cx - s * 22) < 1.2) & (yy > cy - 20) & (yy < cy + 2)] = oro
    for x in range(cx - 30, cx + 31, 10):
        img[(np.abs(xx - x) < 1.5) & (yy > cy + 14) & (yy < cy + 34)] = oro          # rejas
    texto = rotulo("PENITENCIARÍA", tuple(oro), (0.38, 0.05, 0.04), escala=2, margen=0, gastado=0.0)
    h, w = texto.shape[:2]
    img[170:170 + h, (ancho - w) // 2:(ancho - w) // 2 + w] = texto
    texto = rotulo("314", tuple(oro), (0.38, 0.05, 0.04), escala=3, margen=0, gastado=0.0)
    h, w = texto.shape[:2]
    img[195:195 + h, (ancho - w) // 2:(ancho - w) // 2 + w] = texto
    img = C.mezclar(img, (0.1, 0.02, 0.02), C.chorreones(alto, ancho, semilla + 1, 25, 0.8) * 0.5)
    rgba = np.concatenate([img, np.ones((alto, ancho, 1))], axis=2)
    filas = np.arange(alto)[:, None] / alto
    corte = 0.86 + 0.12 * C.ruido(1, ancho, semilla + 2, 3, celdas=4)[0][None, :]
    rgba[..., 3] = (filas < corte).astype(float)
    return C.guardar_png("escenario/estandarte_emblema.png", rgba)


def materiales():
    m = {}
    m["pared_enf"] = C.material("MAT_Pared_Enfermeria", tex_azulejo_yeso("pared_enfermeria", (0.55, 0.64, 0.58),
                                                                         (0.62, 0.6, 0.54), 530), rugosidad=0.5,
                                especular=0.45)
    m["pared_comi"] = C.material("MAT_Pared_Comisaria", tex_azulejo_yeso("pared_comisaria", (0.3, 0.2, 0.12),
                                                                         (0.6, 0.5, 0.33), 531, 0.38),
                                 rugosidad=0.8, especular=0.3)
    m["linoleo"] = C.material("MAT_Linoleo", tex_ajedrez("linoleo", (0.36, 0.4, 0.36), (0.22, 0.25, 0.23), 532),
                              rugosidad=0.35, especular=0.5)
    m["linoleo_marron"] = C.material("MAT_Linoleo_Marron", tex_ajedrez("linoleo_marron", (0.32, 0.22, 0.15),
                                                                       (0.2, 0.14, 0.1), 533, 6), rugosidad=0.45)
    m["yeso"] = C.material("MAT_Yeso_Techo", K.tex_hormigon("yeso_techo", (0.5, 0.49, 0.45), 534, verde=0.05,
                                                            chorros=15, encofrado=False), rugosidad=0.9)
    m["hormigon"] = C.material("MAT_Hormigon_Ejecucion", K.tex_hormigon("hormigon_ejecucion", (0.24, 0.24, 0.25),
                                                                        535, verde=0.12, chorros=60), rugosidad=0.7,
                               especular=0.4)
    m["suelo_hormigon"] = C.material("MAT_Suelo_Ejecucion", K.tex_losa(), rugosidad=0.3, especular=0.55)
    m["metal_blanco"] = C.material("MAT_Metal_Hospital", K.tex_oxido("metal_hospital", (0.62, 0.63, 0.6), 536, oxido=0.4),
                                   rugosidad=0.45, metalico=0.3)
    m["oxido"] = C.material("MAT_Hierro_Oxidado_I", K.tex_oxido("hierro_oxidado_i", (0.16, 0.15, 0.15), 537),
                            rugosidad=0.6, metalico=0.55)
    m["madera"] = C.material("MAT_Madera_Oscura", K.tex_hormigon("madera_oscura", (0.22, 0.13, 0.08), 538, verde=0.0,
                                                                 chorros=10, encofrado=True), rugosidad=0.55,
                             especular=0.45)
    m["sabana"] = C.material("MAT_Sabana_Sangre", K.tex_tela_colgante("sabana_sangre", (0.7, 0.68, 0.62), 539,
                                                                      agujeros=0.0, sangre=0.7), rugosidad=0.9)
    m["cortina"] = C.material("MAT_Cortina", K.tex_tela_colgante("cortina_hospital", (0.42, 0.5, 0.46), 540,
                                                                 agujeros=0.3, sangre=0.3), rugosidad=0.9, alfa=True)
    m["sangre"] = C.material("MAT_Sangre", tex_sangre(), rugosidad=0.15, especular=0.7, alfa=True)
    m["espejo"] = C.material("MAT_Espejo", color=(0.6, 0.62, 0.62), rugosidad=0.04, metalico=1.0)
    m["cristal"] = C.material("MAT_Cristal_Oscuro", color=(0.02, 0.025, 0.03), rugosidad=0.05, especular=0.9)
    m["bombilla"] = C.material_emisivo("MAT_Bombilla_Calida", (1.0, 0.75, 0.42), 30.0)
    m["fluor"] = C.material_emisivo("MAT_Fluor_Frio", (0.8, 0.95, 0.9), 35.0)
    m["fluor_off"] = C.material("MAT_Fluor_Apagado", color=(0.1, 0.1, 0.1), rugosidad=0.3)
    m["rojo"] = C.material_emisivo("MAT_Emergencia_Roja", (1.0, 0.06, 0.04), 25.0)
    m["pantalla"] = C.material("MAT_Pantalla_CRT", tex_pantalla(), rugosidad=0.2, emision=(0.45, 0.6, 0.55),
                               fuerza_emision=0.0)
    arbol = m["pantalla"].node_tree
    tex = next(n for n in arbol.nodes if n.type == "TEX_IMAGE")
    bsdf = next(n for n in arbol.nodes if n.type == "BSDF_PRINCIPLED")
    arbol.links.new(tex.outputs["Color"], bsdf.inputs["Emission Color"])
    bsdf.inputs["Emission Strength"].default_value = 3.0
    m["alfombra"] = C.material("MAT_Alfombra", K.tex_hormigon("alfombra_roja", (0.3, 0.04, 0.03), 541, verde=0.0,
                                                              chorros=15, encofrado=False), rugosidad=0.95)
    m["emblema"] = C.material("MAT_Estandarte_Emblema", tex_emblema(), rugosidad=0.9, alfa=True)
    m["cuero"] = C.material("MAT_Cuero_Correas", color=(0.08, 0.05, 0.03), rugosidad=0.5)
    m["papel"] = C.material("MAT_Papeles", K.tex_hormigon("papeles", (0.7, 0.67, 0.58), 542, verde=0.0, chorros=5,
                                                          encofrado=True), rugosidad=0.9)
    for nombre, texto, fg, bg in (("enfermeria", "ENFERMERÍA", (0.1, 0.12, 0.1), (0.7, 0.72, 0.66)),
                                  ("silencio", "SILENCIO", (0.75, 0.73, 0.66), (0.15, 0.25, 0.2)),
                                  ("interrogatorio", "INTERROGATORIO", (0.85, 0.82, 0.7), (0.25, 0.12, 0.07)),
                                  ("sala_cero", "SALA 0", (0.8, 0.78, 0.7), (0.35, 0.05, 0.04)),
                                  ("direccion", "DIRECCIÓN", (0.7, 0.58, 0.28), (0.1, 0.05, 0.04))):
        ruta = C.guardar_png(f"escenario/rotulo_{nombre}.png", rotulo(texto, fg, bg, semilla=len(texto)))
        m[f"rotulo_{nombre}"] = C.material(f"MAT_Rotulo_{nombre}", ruta, rugosidad=0.6)
    for mat in m.values():
        mat.use_fake_user = True
    return m


# ================================================================ Muebles ===

def caja(malla, a, b, mat, esc=1.0):
    malla.caja(a, b, mat, esc)


def cama_hospital(i):
    mm = C.Malla()
    caja(mm, (0.0, 0.0, 0.5), (0.95, 2.0, 0.56), i["metal_blanco"], 2.0)
    caja(mm, (0.03, 0.03, 0.56), (0.92, 1.97, 0.7), i["sabana"], 1.0)
    caja(mm, (0.15, 1.65, 0.7), (0.8, 1.92, 0.8), i["sabana"], 1.0)
    for y, alto in ((0.0, 0.95), (1.97, 1.15)):
        caja(mm, (0.0, y, 0.0), (0.95, y + 0.04, alto), i["metal_blanco"], 2.0)
    for x in (0.02, 0.9):
        for y in (0.02, 1.95):
            caja(mm, (x, y, 0.0), (x + 0.04, y + 0.04, 0.5), i["metal_blanco"], 2.0)
    return mm


def cuerpo_tapado(i, largo=1.75):
    """Bulto humano bajo una sábana ensangrentada."""
    mm = C.Malla()
    caja(mm, (0.12, 0.1, 0.0), (0.58, largo - 0.35, 0.22), i["sabana"], 1.0)
    caja(mm, (0.18, largo - 0.33, 0.0), (0.52, largo - 0.08, 0.2), i["sabana"], 1.0)
    caja(mm, (0.05, 0.4, 0.0), (0.65, 1.0, 0.16), i["sabana"], 1.0)
    return mm


def mesa_operaciones(i):
    mm = C.Malla()
    caja(mm, (-0.35, -1.0, 0.85), (0.35, 1.0, 0.92), i["metal_blanco"], 2.0)
    caja(mm, (-0.12, -0.12, 0.0), (0.12, 0.12, 0.85), i["metal_blanco"], 2.0)
    caja(mm, (-0.4, -0.4, 0.0), (0.4, 0.4, 0.06), i["metal_blanco"], 2.0)
    for y in (-0.6, 0.2):
        caja(mm, (-0.37, y, 0.88), (0.37, y + 0.06, 0.95), i["cuero"], 2.0)
    return mm


def lampara_quirofano(i):
    mm = C.Malla()
    mm.cilindro((0, 0, 0.0), 0.02, 1.2, lados=6, material=i["metal_blanco"], tapas=False)
    mm.cilindro((0, 0, -0.18), 0.45, 0.18, lados=12, material=i["metal_blanco"])
    for k in range(5):
        a = 2 * math.pi * k / 5
        mm.cilindro((math.cos(a) * 0.25, math.sin(a) * 0.25, -0.2), 0.07, 0.03, lados=8, material=i["bombilla"])
    return mm


def carrito(i):
    mm = C.Malla()
    for z in (0.35, 0.85):
        caja(mm, (0.0, 0.0, z), (0.6, 0.4, z + 0.03), i["metal_blanco"], 2.0)
    for x in (0.0, 0.57):
        for y in (0.0, 0.37):
            caja(mm, (x, y, 0.0), (x + 0.03, y + 0.03, 0.88), i["metal_blanco"], 2.0)
    for k in range(6):
        caja(mm, (0.08 + k * 0.08, 0.1, 0.88), (0.1 + k * 0.08, 0.32, 0.9), i["oxido"], 4.0)
    return mm


def vitrina(i):
    mm = C.Malla()
    caja(mm, (0.0, 0.0, 0.0), (1.2, 0.4, 0.05), i["metal_blanco"], 2.0)
    caja(mm, (0.0, 0.0, 1.95), (1.2, 0.4, 2.0), i["metal_blanco"], 2.0)
    for x in (0.0, 1.17):
        caja(mm, (x, 0.0, 0.0), (x + 0.03, 0.4, 2.0), i["metal_blanco"], 2.0)
    caja(mm, (0.0, 0.37, 0.0), (1.2, 0.4, 2.0), i["metal_blanco"], 2.0)
    for z in (0.5, 1.0, 1.5):
        caja(mm, (0.03, 0.0, z), (1.17, 0.37, z + 0.02), i["metal_blanco"], 2.0)
        for k in range(7):
            mm.cilindro((0.12 + k * 0.15, 0.18, z + 0.02), 0.035, 0.12 + 0.05 * (k % 3), lados=6,
                        material=i["cristal"] if k % 2 else i["papel"])
    caja(mm, (0.0, -0.01, 0.05), (1.2, 0.0, 1.95), i["cristal"], 1.0)
    return mm


def gotero(i):
    mm = C.Malla()
    mm.cilindro((0, 0, 0), 0.015, 1.9, lados=6, material=i["metal_blanco"])
    caja(mm, (-0.25, -0.02, 0.0), (0.25, 0.02, 0.03), i["metal_blanco"], 2.0)
    caja(mm, (-0.08, -0.03, 1.55), (0.08, 0.03, 1.8), i["cristal"], 2.0)
    return mm


def espejo_pared(i):
    mm = C.Malla()
    caja(mm, (-0.45, 0.0, 0.0), (0.45, 0.04, 1.2), i["oxido"], 2.0)
    mm.cuadrilatero(Vector((-0.4, -0.001, 0.05)), Vector((0.4, -0.001, 0.05)), Vector((0.4, -0.001, 1.15)),
                    Vector((-0.4, -0.001, 1.15)), i["espejo"])
    return mm


def mesa_metal(i):
    mm = C.Malla()
    caja(mm, (-0.8, -0.45, 0.72), (0.8, 0.45, 0.76), i["oxido"], 2.0)
    for x in (-0.76, 0.72):
        for y in (-0.42, 0.38):
            caja(mm, (x, y, 0.0), (x + 0.04, y + 0.04, 0.72), i["oxido"], 2.0)
    caja(mm, (-0.3, -0.1, 0.76), (0.1, 0.2, 0.79), i["papel"], 2.0)
    mm.cilindro((0.45, 0.1, 0.76), 0.06, 0.02, lados=8, material=i["cristal"])
    return mm


def silla(i):
    mm = C.Malla()
    caja(mm, (-0.22, -0.22, 0.44), (0.22, 0.22, 0.48), i["oxido"], 2.0)
    caja(mm, (-0.22, 0.18, 0.48), (0.22, 0.22, 0.95), i["oxido"], 2.0)
    for x in (-0.21, 0.18):
        for y in (-0.21, 0.18):
            caja(mm, (x, y, 0.0), (x + 0.03, y + 0.03, 0.44), i["oxido"], 2.0)
    return mm


def lampara_colgante(i):
    mm = C.Malla()
    mm.cilindro((0, 0, 0.3), 0.008, 1.2, lados=4, material=i["oxido"], tapas=False)
    anillos = []
    for z, r in ((0.3, 0.05), (0.08, 0.28)):
        anillos.append([mm.vertice((math.cos(2 * math.pi * k / 10) * r, math.sin(2 * math.pi * k / 10) * r, z))
                        for k in range(10)])
    for k in range(10):
        mm.cara([anillos[0][k], anillos[0][(k + 1) % 10], anillos[1][(k + 1) % 10], anillos[1][k]],
                [(0, 0), (1, 0), (1, 1), (0, 1)], i["oxido"])
    mm.cilindro((0, 0, 0.1), 0.05, 0.1, lados=8, material=i["bombilla"])
    return mm


def archivador(i):
    mm = C.Malla()
    caja(mm, (0.0, 0.0, 0.0), (0.5, 0.65, 1.35), i["metal_blanco"], 2.0)
    for z in (0.12, 0.45, 0.78, 1.1):
        caja(mm, (0.05, -0.01, z), (0.45, 0.0, z + 0.25), i["oxido"], 2.0)
    return mm


def palanca(i):
    """Mecanismo 1 (jefe): caja de mando con palanca grande."""
    mm = C.Malla()
    caja(mm, (-0.4, 0.0, 0.6), (0.4, 0.35, 1.6), i["oxido"], 2.0)
    EL.barra(mm, (0.0, -0.05, 1.1), (0.0, -0.6, 1.7), 0.035, i["oxido"], None)
    mm.cilindro((0.0, -0.62, 1.66), 0.07, 0.1, lados=8, material=i["rojo"])
    return mm


def volante(i):
    """Mecanismo 2 (jefe): válvula de rueda sobre una tubería."""
    mm = C.Malla()
    mm.cilindro((0.0, 0.0, 0.0), 0.12, 2.6, lados=8, material=i["oxido"])
    mm.cilindro((0.0, -0.35, 1.3), 0.06, 0.35, lados=8, material=i["oxido"], eje="y")
    for k in range(10):
        a0, a1 = 2 * math.pi * k / 10, 2 * math.pi * (k + 1) / 10
        EL.barra(mm, (math.cos(a0) * 0.45, -0.4, 1.3 + math.sin(a0) * 0.45),
                 (math.cos(a1) * 0.45, -0.4, 1.3 + math.sin(a1) * 0.45), 0.03, i["oxido"], None, lados=4)
    for k in range(4):
        a = math.pi * k / 2
        EL.barra(mm, (0, -0.4, 1.3), (math.cos(a) * 0.45, -0.4, 1.3 + math.sin(a) * 0.45), 0.02, i["oxido"], None,
                 lados=4)
    return mm


def torno(i):
    """Mecanismo 3 (jefe): torno con cadena que sube hacia el techo."""
    mm = C.Malla()
    caja(mm, (-0.6, -0.3, 0.0), (0.6, 0.3, 0.5), i["oxido"], 2.0)
    mm.cilindro((-0.5, 0.0, 0.85), 0.25, 1.0, lados=10, material=i["oxido"], eje="x")
    for x in (-0.55, 0.55):
        caja(mm, (x - 0.05, -0.1, 0.5), (x + 0.05, 0.1, 1.1), i["oxido"], 2.0)
    for k in range(30):
        z = 1.1 + k * 0.25
        caja(mm, (-0.03, -0.02, z), (0.03, 0.02, z + 0.2), i["oxido"], 4.0)
    return mm


def lampara_roja(i):
    mm = C.Malla()
    caja(mm, (-0.12, 0.0, -0.12), (0.12, 0.12, 0.12), i["oxido"], 2.0)
    mm.cilindro((0.0, -0.08, 0.0), 0.09, 0.1, lados=8, material=i["rojo"], eje="y")
    return mm


def cadena_colgante(i, largo=5.0):
    mm = C.Malla()
    eslabones = int(largo / 0.12)
    for k in range(eslabones):
        z = -k * 0.12
        if k % 2:
            caja(mm, (-0.035, -0.008, z - 0.1), (0.035, 0.008, z), i["oxido"], 4.0)
        else:
            caja(mm, (-0.008, -0.035, z - 0.1), (0.008, 0.035, z), i["oxido"], 4.0)
    caja(mm, (-0.06, -0.06, -largo - 0.25), (0.06, 0.06, -largo), i["oxido"], 4.0)
    return mm


def plataforma_ejecucion(i):
    """Tarima con escalones, bloque con correas y una hoja enorme entre dos postes."""
    mm = C.Malla()
    caja(mm, (-3.0, -3.0, 0.0), (3.0, 3.0, 1.2), i["hormigon"], 0.5)
    for k in range(4):
        caja(mm, (-1.0, -3.0 - 0.3 * (k + 1), 0.0), (1.0, -3.0 - 0.3 * k, 1.2 - 0.3 * (k + 1)), i["hormigon"], 0.5)
    caja(mm, (-1.2, -0.4, 1.2), (1.2, 0.4, 1.8), i["madera"], 1.0)
    for x in (-0.6, 0.2):
        caja(mm, (x, -0.42, 1.55), (x + 0.12, 0.42, 1.82), i["cuero"], 2.0)
    for x in (-1.6, 1.6):
        caja(mm, (x - 0.15, -0.15, 1.2), (x + 0.15, 0.15, 8.0), i["oxido"], 1.0)
    caja(mm, (-1.9, -0.2, 7.8), (1.9, 0.2, 8.3), i["oxido"], 1.0)
    # La hoja, inclinada, en lo alto.
    p = [Vector((-1.45, -0.04, 6.3)), Vector((1.45, -0.04, 5.6)), Vector((1.45, -0.04, 7.3)),
         Vector((-1.45, -0.04, 7.3))]
    q = [v + Vector((0, 0.08, 0)) for v in p]
    for a, b in ((p, None), (q, None)):
        mm.cuadrilatero(*a, i["oxido"])
    for k in range(4):
        mm.cuadrilatero(p[k], p[(k + 1) % 4], q[(k + 1) % 4], q[k], i["oxido"])
    return mm


def pilar(i, alto=9.0, roto=False):
    mm = C.Malla()
    if roto:
        caja(mm, (-0.6, -0.6, 0.0), (0.6, 0.6, 1.6), i["hormigon"], 0.5)
        for k, (x, y) in enumerate(((0.9, 0.3), (-0.8, 0.7), (0.4, -0.9))):
            caja(mm, (x - 0.3, y - 0.25, 0.0), (x + 0.3, y + 0.25, 0.3 + 0.1 * k), i["hormigon"], 0.5)
    else:
        caja(mm, (-0.6, -0.6, 0.0), (0.6, 0.6, alto), i["hormigon"], 0.5)
    return mm


def muro_pantallas(i, columnas=8, filas=5):
    mm = C.Malla()
    caja(mm, (0.0, 0.0, 0.0), (columnas * 0.7 + 0.1, 0.5, filas * 0.55 + 0.1), i["oxido"], 1.0)
    for c in range(columnas):
        for f in range(filas):
            x, z = 0.1 + c * 0.7, 0.1 + f * 0.55
            caja(mm, (x, -0.05, z), (x + 0.6, 0.0, z + 0.45), i["oxido"], 2.0)
            mm.cuadrilatero(Vector((x + 0.06, -0.051, z + 0.05)), Vector((x + 0.54, -0.051, z + 0.05)),
                            Vector((x + 0.54, -0.051, z + 0.4)), Vector((x + 0.06, -0.051, z + 0.4)),
                            i["pantalla"] if (c * 7 + f * 3) % 5 else i["cristal"])
    return mm


def escritorio_director(i):
    mm = C.Malla()
    caja(mm, (-3.0, -1.0, 0.0), (3.0, 1.0, 1.6), i["madera"], 0.5)
    caja(mm, (-3.2, -1.15, 1.6), (3.2, 1.15, 1.75), i["madera"], 0.5)
    caja(mm, (-1.5, -0.6, 1.75), (-0.5, 0.2, 1.8), i["papel"], 2.0)
    return mm


def rotulo_pared(i, clave, ancho, alto):
    mm = C.Malla()
    mm.cuadrilatero(Vector((-ancho / 2, 0, 0)), Vector((ancho / 2, 0, 0)), Vector((ancho / 2, 0, alto)),
                    Vector((-ancho / 2, 0, alto)), i[clave])
    return mm


def charco(i, radio=1.0):
    mm = C.Malla()
    mm.cuadrilatero(Vector((-radio, -radio, 0.004)), Vector((radio, -radio, 0.004)), Vector((radio, radio, 0.004)),
                    Vector((-radio, radio, 0.004)), i["sangre"])
    return mm


PIEZAS = {
    "Cama_Hospital": cama_hospital, "Cuerpo_Tapado": cuerpo_tapado, "Mesa_Operaciones": mesa_operaciones,
    "Lampara_Quirofano": lampara_quirofano, "Carrito_Instrumental": carrito, "Vitrina": vitrina,
    "Gotero": gotero, "Espejo_Pared": espejo_pared, "Mesa_Metal": mesa_metal, "Silla": silla,
    "Lampara_Colgante": lampara_colgante, "Archivador": archivador, "Mecanismo_Palanca": palanca,
    "Mecanismo_Volante": volante, "Mecanismo_Torno": torno, "Lampara_Roja": lampara_roja,
    "Cadena_Colgante": cadena_colgante, "Plataforma_Ejecucion": plataforma_ejecucion,
    "Pilar_Hormigon": pilar, "Pilar_Roto": lambda i: pilar(i, roto=True), "Muro_Pantallas": muro_pantallas,
    "Escritorio_Director": escritorio_director, "Charco_Sangre": charco,
    "Rotulo_Enfermeria": lambda i: rotulo_pared(i, "rotulo_enfermeria", 1.4, 0.3),
    "Rotulo_Silencio": lambda i: rotulo_pared(i, "rotulo_silencio", 1.1, 0.3),
    "Rotulo_Interrogatorio": lambda i: rotulo_pared(i, "rotulo_interrogatorio", 1.6, 0.25),
    "Rotulo_Sala_Cero": lambda i: rotulo_pared(i, "rotulo_sala_cero", 1.2, 0.4),
    "Rotulo_Direccion": lambda i: rotulo_pared(i, "rotulo_direccion", 1.6, 0.35),
}


def crear_kit():
    C.reiniciar()
    m = materiales()
    claves = list(m)
    i = {k: n for n, k in enumerate(claves)}
    lista = [m[k] for k in claves]
    x = 0.0
    for nombre, funcion in PIEZAS.items():
        col = C.coleccion(f"Kit_{nombre}")
        malla = funcion(i)
        obj = malla.a_objeto(f"Kit_{nombre}", lista, col)
        obj.data.name = f"M_Kit_{nombre}"
        obj.location = (x, 0, 0)
        x += 4.0
    C.guardar_blend(KIT)


# ================================================================ Montaje ===

class Escena:
    """Ayuda a montar un escenario: enlaza piezas del kit, crea salas, luces y niebla."""

    def __init__(self, nombre):
        self.escena = C.reiniciar()
        with bpy.data.libraries.load(str(KIT), link=True, relative=True) as (origen, destino):
            destino.meshes = [n for n in origen.meshes if n.startswith("M_Kit_")]
            destino.materials = [n for n in origen.materials if n.startswith("MAT_")]
        self.mallas = {x.name: x for x in destino.meshes}
        self.mats = {x.name: x for x in destino.materials}
        self.col = C.coleccion(nombre)
        self.nombre = nombre

    def poner(self, pieza, pos, rot=0.0, escala=1.0, nombre=None):
        obj = bpy.data.objects.new(nombre or pieza, self.mallas[f"M_Kit_{pieza}"])
        self.col.objects.link(obj)
        obj.location = pos
        obj.rotation_euler = (0, 0, rot)
        obj.scale = (escala,) * 3 if not isinstance(escala, tuple) else escala
        return obj

    def sala(self, x0, y0, x1, y1, alto, suelo, pared, techo, huecos=(), esc_pared=1 / 3.2, grosor=0.3,
             nombre="Sala"):
        """Suelo, techo y cuatro paredes. huecos: (lado 's','n','o','e', centro, ancho, alto)."""
        mm = C.Malla()
        mm.caja((x0 - grosor, y0 - grosor, -0.3), (x1 + grosor, y1 + grosor, 0.0), 0, 1 / 1.6)
        if techo:
            mm.caja((x0 - grosor, y0 - grosor, alto), (x1 + grosor, y1 + grosor, alto + 0.3), 2, 1 / 1.6)
        for lado in "snoe":
            h = [hh for hh in huecos if hh[0] == lado]
            if lado in "sn":
                y = y0 - grosor if lado == "s" else y1
                tramos = self._tramos(x0 - grosor, x1 + grosor, h)
                for a, b, zb in tramos:
                    mm.caja((a, y, zb), (b, y + grosor, alto), 1, esc_pared)
            else:
                x = x0 - grosor if lado == "o" else x1
                tramos = self._tramos(y0, y1, h)
                for a, b, zb in tramos:
                    mm.caja((x, a, zb), (x + grosor, b, alto), 1, esc_pared)
        return mm.a_objeto(nombre, [self.mats[suelo], self.mats[pared], self.mats[techo or suelo]], self.col)

    @staticmethod
    def _tramos(a, b, huecos):
        """Divide una pared en tramos dejando huecos (puertas): (inicio, fin, z_base)."""
        tramos, actual = [], a
        for _, centro, ancho, alto in sorted(huecos, key=lambda t: t[1]):
            tramos.append((actual, centro - ancho / 2, 0.0))
            tramos.append((centro - ancho / 2, centro + ancho / 2, alto))
            actual = centro + ancho / 2
        tramos.append((actual, b, 0.0))
        return [t for t in tramos if t[1] - t[0] > 0.01]

    def luz(self, nombre, tipo, energia, color, pos, apuntar=None, **p):
        d = bpy.data.lights.new(nombre, tipo)
        d.energy = energia
        d.color = color
        for k, v in p.items():
            setattr(d, k, v)
        o = bpy.data.objects.new(nombre, d)
        self.col.objects.link(o)
        o.location = pos
        if apuntar:
            o.rotation_euler = (Vector(apuntar) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
        return o

    def malla_kit_prision(self, nombre):
        """Enlaza una malla del kit de la prisión (sábana, estandarte, fluorescente)."""
        if nombre not in bpy.data.meshes:
            with bpy.data.libraries.load(str(C.RAIZ / "kit" / "kit_prision.blend"), link=True,
                                         relative=True) as (origen, destino):
                destino.meshes = [nombre]
        return bpy.data.meshes[nombre]

    def tela(self, pieza, nombre, pos, rot=0.0, escala=(1.0, 1.0, 1.0)):
        obj = bpy.data.objects.new(nombre, self.malla_kit_prision(f"M_Kit_{pieza}"))
        self.col.objects.link(obj)
        obj.location = pos
        obj.rotation_euler = (0, 0, rot)
        obj.scale = escala
        return obj

    def fluorescente(self, nombre, pos, energia=60.0, encendido=True, giro=0.0, color=(0.8, 0.95, 0.9)):
        """Luminaria del kit de la prisión; apagada usa el material sin emisión."""
        obj = self.tela("Fluorescente", nombre, pos, giro)
        if not encendido:
            ranura = obj.material_slots[1]
            ranura.link = "OBJECT"
            ranura.material = self.mats["MAT_Fluor_Apagado"]
            return obj
        d = bpy.data.lights.new(f"{nombre}_Luz", "AREA")
        d.energy = energia
        d.color = color
        d.shape = "RECTANGLE"
        d.size, d.size_y = 1.25, 0.25
        luz = bpy.data.objects.new(f"{nombre}_Luz", d)
        self.col.objects.link(luz)
        luz.location = (pos[0], pos[1], pos[2] - 0.14)
        luz.rotation_euler = (0, 0, giro)
        return obj

    def niebla(self, minimo, maximo, densidad, color):
        mm = C.Malla()
        mm.caja(minimo, maximo)
        obj = mm.a_objeto(f"Niebla_{self.nombre}", [], self.col)
        mat = bpy.data.materials.new(f"MAT_Niebla_{self.nombre}")
        arbol = mat.node_tree
        for nodo in list(arbol.nodes):
            if nodo.type == "BSDF_PRINCIPLED":
                arbol.nodes.remove(nodo)
        v = arbol.nodes.new("ShaderNodeVolumePrincipled")
        v.inputs["Color"].default_value = (*color, 1)
        v.inputs["Density"].default_value = densidad
        v.inputs["Anisotropy"].default_value = 0.45
        arbol.links.new(v.outputs["Volume"], next(n for n in arbol.nodes if n.type == "OUTPUT_MATERIAL").inputs["Volume"])
        obj.data.materials.append(mat)
        obj.display_type = "BOUNDS"

    def mundo(self, color):
        mundo = bpy.data.worlds.new(f"Mundo_{self.nombre}")
        self.escena.world = mundo
        fondo = next(n for n in mundo.node_tree.nodes if n.type == "BACKGROUND")
        fondo.inputs["Color"].default_value = (*color, 1.0)

    def guardar(self):
        C.guardar_blend(C.RAIZ / "escenarios" / f"{self.nombre.lower()}.blend")


def plano(nombre_escenario, montar, camara, exposicion, borrador):
    """Plano: enlaza el escenario, coloca personajes (montar) y renderiza."""
    escena = C.reiniciar()
    ruta = C.RAIZ / "escenarios" / f"{nombre_escenario.lower()}.blend"
    col = PP.enlazar_coleccion(ruta, nombre_escenario)
    escena.collection.children.link(col)
    with bpy.data.libraries.load(str(ruta), link=True, relative=True) as (origen, destino):
        destino.worlds = [f"Mundo_{nombre_escenario}"]
    escena.world = destino.worlds[0]
    montar(escena)
    pos, objetivo, lente = camara
    escena.camera = PP.camara(f"Camara_{nombre_escenario}", pos, objetivo, lente)
    if borrador:
        C.configurar_render(escena, 640, 360, muestras=12, exposicion=exposicion)
    else:
        C.configurar_render(escena, 1672, 941, muestras=48, exposicion=exposicion)
    try:
        escena.eevee.shadow_pool_size = "1024"
    except (TypeError, AttributeError):
        pass
    nombre = nombre_escenario.lower()
    C.guardar_blend(C.RAIZ / "escenas" / f"plano_{nombre}.blend")
    C.renderizar(escena, C.RAIZ / "renders" / f"plano_{nombre}{'_borrador' if borrador else ''}.png")


# ================================================================== Poses ===

def pose_sentado(arm, posicion, angulo, h=1.0):
    """Sentado en una silla de 0,47 m, con los antebrazos sobre la mesa."""
    arm.location = (posicion[0], posicion[1], posicion[2] - 0.38 * h)
    arm.rotation_euler = (0, 0, math.radians(angulo))
    bpy.context.view_layer.update()
    f = PP.mirar(angulo)
    izq = Vector((0, 0, 1)).cross(f)
    arriba = Vector((0, 0, 1))
    H.apuntar(arm, "columna", arriba + f * 0.1)
    H.apuntar(arm, "pecho", arriba + f * 0.2)
    H.apuntar(arm, "cabeza", arriba + f * 0.35)
    for lado, s in (("L", 1), ("R", -1)):
        H.apuntar(arm, f"muslo.{lado}", f + izq * 0.08 * s - arriba * 0.05)
        H.apuntar(arm, f"pierna.{lado}", -arriba + f * 0.15)
        H.apuntar(arm, f"pie.{lado}", f)
        H.apuntar(arm, f"brazo.{lado}", -arriba + f * 0.5 + izq * 0.1 * s)
        H.apuntar(arm, f"antebrazo.{lado}", f - izq * 0.35 * s)
        H.apuntar(arm, f"mano.{lado}", f - izq * 0.3 * s)


def pose_agachado(arm, posicion, angulo, asomar=0.0):
    """Agachado tras una cobertura, asomando la cabeza."""
    arm.location = (posicion[0], posicion[1], posicion[2] - 0.38)
    arm.rotation_euler = (0, 0, math.radians(angulo))
    bpy.context.view_layer.update()
    f = PP.mirar(angulo)
    izq = Vector((0, 0, 1)).cross(f)
    arriba = Vector((0, 0, 1))
    H.apuntar(arm, "columna", arriba + f * 0.5)
    H.apuntar(arm, "pecho", arriba + f * 0.6)
    H.apuntar(arm, "cabeza", arriba + f * 0.2 + izq * asomar)
    H.apuntar(arm, "muslo.L", f * 1.0 - arriba * 0.25 + izq * 0.15)
    H.apuntar(arm, "pierna.L", -arriba - f * 0.6)
    H.apuntar(arm, "muslo.R", f * 0.4 - arriba * 0.9 - izq * 0.15)
    H.apuntar(arm, "pierna.R", -f * 1.0 - arriba * 0.3)
    H.apuntar(arm, "pie.R", -arriba * 0.3 - f * 0.4)
    for lado, s in (("L", 1), ("R", -1)):
        H.apuntar(arm, f"brazo.{lado}", -arriba + f * 0.6 + izq * 0.2 * s)
        H.apuntar(arm, f"antebrazo.{lado}", f - arriba * 0.3)


def pose_acecho(arm, posicion, angulo, alcanzar=0.8):
    """Enemigo que avanza encorvado, cabeza ladeada y un brazo extendido hacia la víctima."""
    arm.location = posicion
    arm.rotation_euler = (0, 0, math.radians(angulo))
    bpy.context.view_layer.update()
    f = PP.mirar(angulo)
    izq = Vector((0, 0, 1)).cross(f)
    arriba = Vector((0, 0, 1))
    H.apuntar(arm, "columna", arriba + f * 0.3)
    H.apuntar(arm, "pecho", arriba + f * 0.6)
    H.apuntar(arm, "cuello", arriba + f * 0.9)
    H.apuntar(arm, "cabeza", arriba * 0.6 + f * 0.7 + izq * 0.35)
    H.apuntar(arm, "brazo.R", -arriba * 0.3 + f * alcanzar - izq * 0.25)
    H.apuntar(arm, "antebrazo.R", -arriba * 0.1 + f - izq * 0.1)
    H.apuntar(arm, "mano.R", f - arriba * 0.2)
    H.apuntar(arm, "brazo.L", -arriba + f * 0.35 + izq * 0.2)
    H.apuntar(arm, "antebrazo.L", -arriba + f * 0.4)
    H.apuntar(arm, "muslo.L", -arriba + f * 0.3 + izq * 0.05)
    H.apuntar(arm, "pierna.L", -arriba - f * 0.1)
    H.apuntar(arm, "muslo.R", -arriba - f * 0.2 - izq * 0.05)
    H.apuntar(arm, "pierna.R", -arriba - f * 0.4)


def pose_apoyado_en_mesa(arm, posicion, angulo):
    """El interrogador, inclinado sobre la mesa con las manos apoyadas."""
    arm.location = posicion
    arm.rotation_euler = (0, 0, math.radians(angulo))
    bpy.context.view_layer.update()
    f = PP.mirar(angulo)
    izq = Vector((0, 0, 1)).cross(f)
    arriba = Vector((0, 0, 1))
    H.apuntar(arm, "columna", arriba + f * 0.55)
    H.apuntar(arm, "pecho", arriba + f * 1.1)
    H.apuntar(arm, "cuello", arriba + f * 0.6)
    H.apuntar(arm, "cabeza", arriba + f * 0.25)
    for lado, s in (("L", 1), ("R", -1)):
        H.apuntar(arm, f"brazo.{lado}", -arriba + f * 0.55 + izq * 0.3 * s)
        H.apuntar(arm, f"antebrazo.{lado}", -arriba + f * 0.25 + izq * 0.05 * s)
        H.apuntar(arm, f"mano.{lado}", f - arriba * 0.4)
        H.apuntar(arm, f"muslo.{lado}", -arriba - f * 0.12 + izq * 0.06 * s)
        H.apuntar(arm, f"pierna.{lado}", -arriba - f * 0.05)


# ============================================================== Escenarios ===

def enfermeria(borrador):
    e = Escena("Enfermeria")
    ancho, fondo, alto = 14.0, 9.0, 3.4
    e.sala(0, 0, ancho, fondo, alto, "MAT_Linoleo", "MAT_Pared_Enfermeria", "MAT_Yeso_Techo",
           huecos=[("s", 2.2, 1.4, 2.3)])
    # Por convenio, las piezas «de pared» miran a -Y con giro 0 (pared norte),
    # a +X con giro π/2 (pared oeste), a -X con giro -π/2 (pared este) y a +Y con giro π (pared sur).
    e.poner("Rotulo_Enfermeria", (2.2, 0.01, 2.45), math.pi)
    # Camas en fila contra la pared este, con el cabecero en la pared.
    for k, y in enumerate((0.5, 2.3, 4.1, 5.9, 7.7)):
        e.poner("Cama_Hospital", (ancho - 2.0, y + 0.95, 0), -math.pi / 2, nombre=f"Cama_{k}")
        e.poner("Gotero", (ancho - 0.4, y + 1.15, 0), nombre=f"Gotero_{k}")
    e.poner("Cuerpo_Tapado", (ancho - 1.95, 2.3 + 0.95, 0.7), -math.pi / 2, nombre="Cuerpo_Cama")
    e.poner("Cuerpo_Tapado", (ancho - 1.95, 5.9 + 0.95, 0.7), -math.pi / 2, nombre="Cuerpo_Cama_2")
    # Cortinas entre camas (sábana del kit de la prisión), corridas a medias.
    for k, y in enumerate((1.85, 3.65, 5.45, 7.25)):
        e.tela("Sabana", f"Cortina_{k}", (ancho - 1.0 - 0.3 * (k % 2), y, 2.7), 0.0, (1.4, 1.0, 1.25))
    e.poner("Mesa_Operaciones", (6.5, 5.0, 0), 0.0)
    e.poner("Cuerpo_Tapado", (6.15, 4.1, 0.95), nombre="Cuerpo_Mesa")
    e.poner("Lampara_Quirofano", (6.5, 5.0, alto - 1.2))
    e.poner("Carrito_Instrumental", (7.3, 3.6, 0), 0.3)
    e.poner("Gotero", (5.7, 5.8, 0), nombre="Gotero_Mesa")
    e.poner("Charco_Sangre", (6.5, 5.3, 0), escala=1.3)
    e.poner("Charco_Sangre", (8.5, 6.8, 0), 1.0, escala=0.7, nombre="Charco_2")
    e.poner("Charco_Sangre", (ancho - 2.6, 3.2, 0), 2.0, escala=0.6, nombre="Charco_3")
    for k in range(4):
        e.poner("Vitrina", (0.42, 1.6 + k * 1.3, 0), math.pi / 2, nombre=f"Vitrina_{k}")
    for k, x in enumerate((3.6, 5.0, 6.4, 7.8)):
        e.poner("Espejo_Pared", (x, fondo - 0.04, 0.9), 0.0, nombre=f"Espejo_{k}")
    e.poner("Rotulo_Silencio", (9.8, fondo - 0.01, 2.4), 0.0)
    for k, (x, y, on) in enumerate(((3.5, 2.5, True), (3.5, 6.5, False), (9.5, 2.5, True), (9.5, 6.5, True))):
        e.fluorescente(f"Fluor_{k}", (x, y, alto), 70.0, on)
    e.luz("Quirofano", "SPOT", 600.0, (1.0, 0.95, 0.85), (6.5, 5.0, alto - 1.45), (6.5, 5.0, 0),
          spot_size=math.radians(55), spot_blend=0.4, shadow_soft_size=0.3)
    e.luz("Emergencia", "POINT", 60.0, (1.0, 0.05, 0.04), (2.2, 0.3, 2.6))
    e.mundo((0.008, 0.01, 0.01))
    e.niebla((0, 0, 0), (ancho, fondo, alto), 0.035, (0.8, 0.9, 0.85))
    e.guardar()

    def montar(escena):
        _, elias = PP.personaje("elias_preso", "Elias_Preso", escena)
        PP.posar_elias(elias, (4.6, 3.3, 0.0), 90, mirar_arriba=-0.1)
        _, cond = PP.personaje("el_condenado", "El_Condenado", escena)
        pose_acecho(cond, (9.4, 3.2, 0.0), -90)
    plano("Enfermeria", montar, ((2.1, 0.7, 1.55), (8.0, 4.6, 1.25), 24), 0.4, borrador)


def comisaria(borrador):
    e = Escena("Comisaria")
    e.sala(0, 0, 4.5, 4.2, 3.0, "MAT_Linoleo_Marron", "MAT_Pared_Comisaria", "MAT_Yeso_Techo",
           huecos=[("o", 3.4, 1.0, 2.2)])
    e.poner("Rotulo_Interrogatorio", (-0.31, 3.4, 2.35), -math.pi / 2)
    # Espejo unidireccional en la pared este.
    mm = C.Malla()
    mm.cuadrilatero(Vector((4.49, 0.8, 0.9)), Vector((4.49, 3.4, 0.9)), Vector((4.49, 3.4, 2.2)),
                    Vector((4.49, 0.8, 2.2)), 0)
    mm.a_objeto("Espejo_Unidireccional", [e.mats["MAT_Espejo"]], e.col)
    e.poner("Mesa_Metal", (2.2, 2.1, 0), math.pi / 2)
    e.poner("Silla", (1.45, 2.1, 0), math.pi / 2, nombre="Silla_Elias")
    e.poner("Silla", (3.1, 2.6, 0), -math.pi / 2 - 0.4, nombre="Silla_Interrogador")
    e.poner("Lampara_Colgante", (2.2, 2.1, 1.7))
    e.poner("Archivador", (0.55, 0.7, 0), math.pi)
    e.luz("Bombilla", "POINT", 160.0, (1.0, 0.72, 0.4), (2.2, 2.1, 1.75), shadow_soft_size=0.05)
    e.luz("Rebote", "AREA", 25.0, (0.95, 0.7, 0.45), (2.2, 2.1, 0.8), (2.2, 2.1, 3.0), size=1.5)
    e.mundo((0.01, 0.007, 0.004))
    e.niebla((0, 0, 0), (4.5, 4.2, 3.0), 0.08, (1.0, 0.85, 0.65))
    e.guardar()

    def montar(escena):
        _, elias = PP.personaje("elias_civil", "Elias_Civil", escena)
        pose_sentado(elias, (1.45, 2.1, 0.0), 90)
        _, inter = PP.personaje("interrogador", "Interrogador", escena)
        pose_apoyado_en_mesa(inter, (3.0, 2.0, 0.0), -90)
    plano("Comisaria", montar, ((0.4, 0.35, 2.3), (2.6, 2.4, 0.95), 24), 0.2, borrador)


def ejecucion(borrador):
    e = Escena("Ejecucion")
    ancho, fondo, alto = 22.0, 16.0, 9.0
    e.sala(0, 0, ancho, fondo, alto, "MAT_Suelo_Ejecucion", "MAT_Hormigon_Ejecucion", "MAT_Hormigon_Ejecucion",
           huecos=[("s", 11.0, 3.0, 4.0)], esc_pared=0.5)
    e.poner("Plataforma_Ejecucion", (11.0, 10.0, 0.0))
    e.poner("Rotulo_Sala_Cero", (11.0, fondo - 0.01, 6.5), 0.0)
    for k, (x, y, roto) in enumerate(((3.5, 11.0, False), (17.0, 4.0, True), (5.5, 13.5, False), (17.0, 12.0, False),
                                      (9.2, 5.0, True), (16.0, 7.5, False))):
        e.poner("Pilar_Roto" if roto else "Pilar_Hormigon", (x, y, 0.0), escala=0.8 if k == 4 else 1.0,
                nombre=f"Pilar_{k}")
    # Los tres mecanismos que debilitan a La Sentencia, cada uno bajo una lámpara roja.
    for k, (pieza, pos, rot, lamp, hacia) in enumerate((
            ("Mecanismo_Palanca", (0.4, 6.0, 0.0), math.pi / 2, (0.12, 6.0, 3.2), (1, 0, 0)),
            ("Mecanismo_Volante", (ancho - 0.3, 8.0, 0.0), -math.pi / 2, (ancho - 0.12, 8.0, 3.2), (-1, 0, 0)),
            ("Mecanismo_Torno", (16.0, fondo - 1.0, 0.0), 0.0, (16.0, fondo - 0.12, 3.2), (0, -1, 0)))):
        e.poner(pieza, pos, rot)
        e.poner("Lampara_Roja", lamp, rot, nombre=f"Lampara_Roja_{k}")
        e.luz(f"Roja_{k}", "POINT", 220.0, (1.0, 0.05, 0.03), tuple(Vector(lamp) + Vector(hacia) * 0.4))
    for k, (x, y, largo) in enumerate(((7.0, 9.0, 5.5), (9.5, 13.0, 4.0), (14.0, 8.0, 6.0), (12.5, 14.0, 3.5),
                                       (18.0, 10.0, 5.0))):
        e.poner("Cadena_Colgante", (x, y, alto), nombre=f"Cadena_{k}")
    for k, (x, y, r) in enumerate(((11.0, 9.6, 1.6), (11.0, 6.0, 0.8), (13.5, 7.0, 0.6))):
        e.poner("Charco_Sangre", (x, y, 1.2 if k == 0 else 0.0), k, escala=r, nombre=f"Charco_{k}")
    e.luz("Cenital", "SPOT", 3500.0, (0.7, 0.8, 0.95), (11.0, 9.0, alto - 0.2), (11.0, 10.0, 0.0),
          spot_size=math.radians(50), spot_blend=0.5, shadow_soft_size=0.2)
    e.luz("Relleno", "AREA", 700.0, (0.5, 0.6, 0.75), (11.0, 3.0, alto - 0.3), (11.0, 8.0, 0.0), size=8.0)
    e.luz("Hoja", "SPOT", 900.0, (0.75, 0.8, 0.9), (8.0, 0.5, 2.5), (11.0, 10.0, 6.5),
          spot_size=math.radians(20), spot_blend=0.6)
    e.mundo((0.006, 0.006, 0.008))
    e.niebla((0, 0, 0), (ancho, fondo, alto), 0.03, (0.75, 0.8, 0.85))
    e.guardar()

    def montar(escena):
        _, elias = PP.personaje("elias_preso", "Elias_Preso", escena)
        pose_agachado(elias, (8.2, 4.6, 0.0), 80, asomar=0.25)
        _, sent = PP.personaje("la_sentencia", "La_Sentencia", escena)
        sent.location = (11.4, 5.4, 0.0)
        sent.rotation_euler = (0, 0, math.radians(-80))
        PP.luz("Contra_Sentencia", "SPOT", 700.0, (1.0, 0.25, 0.18), (13.5, 8.5, 5.0), (11.4, 5.4, 2.0),
               spot_size=math.radians(25), spot_blend=0.5)
    plano("Ejecucion", montar, ((4.6, 1.4, 2.0), (11.5, 9.0, 3.6), 20), 0.6, borrador)


def nucleo(borrador):
    e = Escena("Nucleo")
    ancho, fondo, alto = 16.0, 50.0, 22.0
    e.sala(0, 0, ancho, fondo, alto, "MAT_Suelo_Ejecucion", "MAT_Hormigon_Ejecucion", "MAT_Hormigon_Ejecucion",
           esc_pared=0.25)
    alfombra = C.Malla()
    alfombra.caja((ancho / 2 - 1.5, 2.0, 0.0), (ancho / 2 + 1.5, fondo - 6.0, 0.02), 0, 1 / 2.0)
    alfombra.a_objeto("Alfombra", [e.mats["MAT_Alfombra"]], e.col)
    tarima = C.Malla()
    tarima.caja((1.0, fondo - 8.0, 0.0), (ancho - 1.0, fondo, 2.5), 0, 0.5)
    for k in range(5):
        tarima.caja((ancho / 2 - 2.0, fondo - 8.0 - 0.4 * (k + 1), 0.0), (ancho / 2 + 2.0, fondo - 8.0 - 0.4 * k,
                    2.5 - 0.5 * (k + 1)), 0, 0.5)
    tarima.a_objeto("Tarima", [e.mats["MAT_Hormigon_Ejecucion"]], e.col)
    e.poner("Escritorio_Director", (ancho / 2, fondo - 5.0, 2.5))
    e.poner("Muro_Pantallas", (ancho / 2 - 2.85, fondo - 0.6, 3.5))
    e.poner("Muro_Pantallas", (1.2, fondo - 0.6, 3.5), nombre="Muro_Pantallas_2", escala=0.8)
    e.poner("Muro_Pantallas", (ancho - 5.8, fondo - 0.6, 3.5), nombre="Muro_Pantallas_3", escala=0.8)
    e.poner("Rotulo_Direccion", (ancho / 2, fondo - 0.65, 10.0), 0.0)
    # Pilares con lámparas rojas a los lados y estandartes de la institución entre ellos.
    for k, y in enumerate(range(6, int(fondo) - 8, 7)):
        for s, x, giro in ((0, 1.3, math.pi / 2), (1, ancho - 1.3, -math.pi / 2)):
            e.poner("Pilar_Hormigon", (x, y, 0.0), escala=(1.0, 1.0, alto / 9.0), nombre=f"Pilar_{k}_{s}")
            borde = x + (0.72 if s == 0 else -0.72)
            e.poner("Lampara_Roja", (borde, y, 4.0), giro, nombre=f"Lampara_{k}_{s}")
            e.luz(f"Roja_{k}_{s}", "POINT", 40.0, (1.0, 0.06, 0.04), (borde + (0.4 if s == 0 else -0.4), y, 4.0))
            e.tela("Estandarte", f"Estandarte_{k}_{s}", (0.35 if s == 0 else ancho - 0.35, y + 3.5, alto - 2.0),
                   giro, (1.0, 1.0, 1.4))
    mm = C.Malla()
    mm.cuadrilatero(Vector((-3.0, 0, -12.0)), Vector((3.0, 0, -12.0)), Vector((3.0, 0, 0.0)),
                    Vector((-3.0, 0, 0.0)), 0)
    emb = mm.a_objeto("Estandarte_Emblema", [e.mats["MAT_Estandarte_Emblema"]], e.col)
    emb.location = (ancho / 2, fondo - 0.8, alto - 1.0)
    for k, y in enumerate(range(8, int(fondo) - 8, 7)):
        e.luz(f"Ventana_{k}", "SPOT", 1800.0, (0.65, 0.75, 0.95), (ancho / 2 + (6 if k % 2 else -6), y, alto - 1.0),
              (ancho / 2, y + 3, 0.0), spot_size=math.radians(25), spot_blend=0.3)
    e.luz("Pantallas", "AREA", 400.0, (0.5, 0.75, 0.65), (ancho / 2, fondo - 3.0, 6.0), (ancho / 2, fondo - 10, 2.0),
          size=6.0)
    e.luz("Clave_Director", "SPOT", 3000.0, (0.8, 0.85, 0.95), (ancho / 2, fondo - 14.0, 14.0),
          (ancho / 2, fondo - 7.0, 3.5), spot_size=math.radians(22), spot_blend=0.5, shadow_soft_size=0.3)
    # Desde el techo (fuera de cuadro): si nace abajo, su foco se ve en la niebla delante del Director.
    e.luz("Emblema", "SPOT", 6000.0, (1.0, 0.75, 0.55), (ancho / 2, fondo - 12.0, alto - 1.0),
          (ancho / 2, fondo - 0.8, 15.0), spot_size=math.radians(30), spot_blend=0.4)
    e.mundo((0.005, 0.006, 0.008))
    e.niebla((0, 0, 0), (ancho, fondo, alto), 0.025, (0.75, 0.8, 0.9))
    e.guardar()

    def montar(escena):
        _, elias = PP.personaje("elias_preso", "Elias_Preso", escena)
        PP.posar_elias(elias, (ancho / 2 - 0.5, 28.5, 0.0), 180, mirar_arriba=0.45)
        _, director = PP.personaje("el_director", "El_Director", escena)
        director.location = (ancho / 2, fondo - 7.0, 2.5)
        director.rotation_euler = (0, 0, 0.0)
    plano("Nucleo", montar, ((ancho / 2 + 0.9, 24.0, 1.1), (ancho / 2, fondo - 7.0, 5.5), 28), 0.5, borrador)


ESCENARIOS = {"enfermeria": enfermeria, "comisaria": comisaria, "ejecucion": ejecucion, "nucleo": nucleo}

if __name__ == "__main__":
    args = C.argumentos()
    borrador = "--borrador" in args
    if "kit" in args:
        crear_kit()
    for nombre in args:
        if nombre in ESCENARIOS:
            print("== Escenario:", nombre)
            ESCENARIOS[nombre](borrador)
