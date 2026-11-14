"""Resto del elenco de Lifetime Sentence, según las láminas de enemigos de Materiales/.

PRESENTE: Los Aislados (dos variantes), El Vigilante, El Condenado, La Sentencia, El Director.
PASADO: policía patrullero, policía táctico, guardia penitenciario, interrogador, verdugo, alcaide.

Usa el mismo constructor que Elías y El Uniforme (humano.py) y los accesorios de personajes.py.

Uso:
    blender --background --factory-startup --python assets/scripts/elenco.py -- todos
    blender --background --factory-startup --python assets/scripts/elenco.py -- la_sentencia el_vigilante
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy  # noqa: E402
import numpy as np  # noqa: E402
from mathutils import Vector  # noqa: E402

import comun as C  # noqa: E402
import humano as H  # noqa: E402
import personajes as PJ  # noqa: E402

PIEL_MEDIA = (0.68, 0.5, 0.4)
PIEL_MUERTA = (0.6, 0.58, 0.56)


# ======================================================== Geometría auxiliar ===

def barra(malla, a, b, radio, mat, pesos, lados=6, radio_b=None, tapas=True):
    """Cilindro orientado entre dos puntos (porras, mangos, linternas)."""
    a, b = Vector(a), Vector(b)
    eje = (b - a).normalized()
    ref = Vector((0, 0, 1)) if abs(eje.z) < 0.9 else Vector((1, 0, 0))
    u = eje.cross(ref).normalized()
    v = eje.cross(u).normalized()
    rb = radio if radio_b is None else radio_b
    anillos = []
    for centro, r in ((a, radio), (b, rb)):
        anillos.append([malla.vertice(centro + (u * math.cos(2 * math.pi * j / lados) +
                                                v * math.sin(2 * math.pi * j / lados)) * r, pesos)
                        for j in range(lados)])
    for j in range(lados):
        j2 = (j + 1) % lados
        malla.cara([anillos[0][j], anillos[0][j2], anillos[1][j2], anillos[1][j]],
                   [(0, 0), (1, 0), (1, 1), (0, 1)], mat)
    if tapas:
        malla.cara(anillos[0][::-1], [(0.5, 0.5)] * lados, mat)
        malla.cara(anillos[1], [(0.5, 0.5)] * lados, mat)


def caja_orientada(malla, centro, ex, ey, ez, mat, pesos, uv=None):
    """Caja con ejes arbitrarios: ex, ey, ez son los semiejes (vectores)."""
    c = Vector(centro)
    ex, ey, ez = Vector(ex), Vector(ey), Vector(ez)
    p = [c + sx * ex + sy * ey + sz * ez for sz in (-1, 1) for sy in (-1, 1) for sx in (-1, 1)]
    idx = [malla.vertice(q, pesos) for q in p]
    caras = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    for cara in caras:
        malla.cara([idx[i] for i in cara], uv or [(0, 0), (1, 0), (1, 1), (0, 1)], mat)


def ejes_mano(huesos, lado="R"):
    """Muñeca, punto de agarre, eje de la mano y eje «adelante» perpendicular."""
    muneca = Vector(huesos[f"mano.{lado}"][0])
    fin = Vector(huesos[f"mano.{lado}"][1])
    eje = (fin - muneca).normalized()
    agarre = muneca + (fin - muneca) * 0.55
    adelante = Vector((0, -1, 0))
    adelante = (adelante - eje * adelante.dot(eje)).normalized()
    return muneca, agarre, eje, adelante


# ============================================================= Pintura ===

FUENTE = {   # letras de 3 x 5 píxeles para textos pixelados («POLICÍA»)
    "P": ["111", "101", "111", "100", "100"], "O": ["111", "101", "101", "101", "111"],
    "L": ["100", "100", "100", "100", "111"], "I": ["111", "010", "010", "010", "111"],
    "C": ["111", "100", "100", "100", "111"], "A": ["111", "101", "111", "101", "101"],
    "Í": ["111", "010", "010", "010", "111"],
}


def escribir(img, texto, x, y, escala, color):
    """Escribe texto pixelado en img (fila 0 = arriba)."""
    for i, letra in enumerate(texto):
        glifo = FUENTE[letra]
        for fy, fila in enumerate(glifo):
            for fx, bit in enumerate(fila):
                if bit == "1":
                    y0, x0 = y + fy * escala, x + (i * 4 + fx) * escala
                    img[y0:y0 + escala, x0:x0 + escala] = color
        if letra == "Í":
            y0, x0 = y - 2 * escala, x + (i * 4 + 1) * escala
            img[y0:y0 + escala, x0:x0 + escala] = color


def bigote(img, U, P, datos, color):
    """Bigote espeso y algo caído hacia las comisuras, sobre el labio."""
    X, Y, Z = H.coordenadas_cara(P, datos)
    m = (C.suave(0.006 - np.abs(Z - 0.081 + np.abs(X) * 0.2), 0, 0.002) * C.suave(0.022 - np.abs(X), 0, 0.004)
         * C.suave(Y, 0.04, 0.06))
    pelos = 0.8 + 0.3 * C.ruido(U.shape[0], U.shape[1], 77, 2, celdas=24)
    return C.mezclar(img, np.array(color) * pelos[..., None], m)


def pixelar(img, mascara, bloque=6, semilla=1):
    """Emborrona una zona en bloques (rostros borrados de Los Aislados y El Condenado)."""
    salida = img.copy()
    alto, ancho = img.shape[:2]
    for y in range(0, alto, bloque):
        for x in range(0, ancho, bloque):
            zona = mascara[y:y + bloque, x:x + bloque]
            if zona.any():
                media = img[y:y + bloque, x:x + bloque].reshape(-1, 3).mean(axis=0)
                salida[y:y + bloque, x:x + bloque][zona] = media
    return salida + C.grano(alto, ancho, semilla, 0.02) * mascara[..., None]


def cara(tipo, U, F, P, s, datos, piel, pelo=(0.08, 0.06, 0.05), **op):
    """Rostros: «normal», «bigote», «borroso», «borroso_sangre», «piedra», «calvo», «vacio»."""
    alto, ancho = U.shape
    X, Y, Z = H.coordenadas_cara(P, datos)
    frente = C.suave(Y, 0.035, 0.06)
    if tipo == "vacio":
        return H.pintar_cara(U, F, P, piel, s, datos, sin_rostro=True)
    color_pelo = piel if tipo == "calvo" else pelo
    img = H.pintar_cara_detallada(U, F, P, piel, s, datos, color_pelo=color_pelo,
                                  barba=op.get("barba", 0.3), sangre=op.get("sangre", 0.0),
                                  suciedad=op.get("suciedad", 0.3), expresion=op.get("expresion", "tenso"))
    if op.get("bigote"):
        img = bigote(img, U, P, datos, np.array(pelo) * 1.2)
    if tipo == "calvo":
        # Pelo rapado o canoso en herradura (sienes y nuca), mezclado con la piel; brillo en la calva.
        atras = C.suave(-Y, 0.0, 0.08)
        z_alto = 0.15 + 0.022 * atras
        z_bajo = 0.1 - 0.03 * atras
        herradura = C.suave(Z - z_bajo, 0, 0.008) * C.suave(z_alto - Z, 0, 0.014) * C.suave(0.03 - Y, 0, 0.03)
        puntos = C.ruido(alto, ancho, s + 3, 2, celdas=40)
        tono = np.array(pelo) * (0.85 + 0.3 * C.ruido(alto, ancho, s, 3, celdas=16))[..., None]
        img = C.mezclar(img, tono, herradura * (0.35 + 0.25 * puntos))
        img *= (1 + 0.12 * np.exp(-((X / 0.05) ** 2) - ((Z - 0.21) / 0.03) ** 2))[..., None]
        img *= (1 - 0.2 * C.suave(0.03 - Z, -0.02, 0.03) * frente)[..., None]
    if tipo in ("borroso", "borroso_sangre"):
        rostro = (Y > 0.03) & (Z > 0.02) & (Z < 0.17) & (np.abs(X) < 0.065)
        img = pixelar(img, rostro, bloque=4 * H.PX, semilla=s)
        for lado in (-1, 1):
            hueco = frente * C.suave(1 - np.sqrt(((X - lado * 0.03) / 0.013) ** 2 + ((Z - 0.133) / 0.01) ** 2), 0, 0.4)
            img = C.mezclar(img, (0.05, 0.035, 0.03), hueco)
            if tipo == "borroso_sangre":
                lagrima = (frente * C.suave(0.004 - np.abs(X - lado * 0.03), 0, 0.002) * C.suave(0.13 - Z, 0, 0.01)
                           * C.suave(Z - 0.06, 0, 0.02))
                img = C.mezclar(img, (0.3, 0.03, 0.02), lagrima)
    if tipo == "piedra":
        grietas = np.abs(C.ruido(alto, ancho, s + 5, 4, celdas=6) - 0.5) < 0.018
        img[grietas] *= 0.45
        for lado in (-1, 1):
            hueco = frente * C.suave(1 - np.sqrt(((X - lado * 0.03) / 0.016) ** 2 + ((Z - 0.133) / 0.012) ** 2), 0, 0.3)
            img = C.mezclar(img, (0.02, 0.02, 0.02), hueco)
        boca = frente * C.suave(0.004 - np.abs(Z - 0.07), 0, 0.002) * C.suave(0.02 - np.abs(X), 0, 0.004)
        img = C.mezclar(img, (0.08, 0.07, 0.07), boca)
    return img


def tela(alto, ancho, color, s, **op):
    return H.tela(alto, ancho, color, s, arrugas=op.get("arrugas", 0.25), suciedad=op.get("suciedad", 0.35),
                  manchas_oscuras=op.get("manchas", 0.6), color_mancha=op.get("mancha", (0.05, 0.04, 0.035)))


def pintor_ropa(e, datos, cfg):
    """Pintor configurable para ropa de uniforme, traje, abrigo o vendas.

    cfg: piel, pelo, cara (tipo), cara_op, camisa, mangas, pantalon, zapatos, manos ("piel" o color),
    decoraciones (lista de tuplas) y sangre / suciedad generales.
    """
    h = e["alto"]

    def pintar(region, U, F, P, s):
        alto, ancho = U.shape
        piel = cfg.get("piel", PIEL_MEDIA)
        if region == "cabeza":
            return cara(cfg.get("cara", "normal"), U, F, P, s, datos, piel, cfg.get("pelo", (0.08, 0.06, 0.05)),
                        **cfg.get("cara_op", {}))
        if region == "pelo":
            if "pintar_pelo" in cfg:
                return cfg["pintar_pelo"](U, F, P, s)
            return H.pintar_pelo(alto, ancho, cfg.get("pelo", (0.08, 0.06, 0.05)), s + 1)
        if region == "brazo":
            if cfg.get("brazos", "piel") == "piel":
                return H.piel(alto, ancho, piel, s + 2)
            return tela(alto, ancho, cfg["brazos"], s + 2)
        if region == "mano":
            manos = cfg.get("manos", "piel")
            if manos == "piel":
                img = H.piel(alto, ancho, piel, s + 3)
                img[F > 0.75] *= 0.85
                return img
            return tela(alto, ancho, manos, s + 3, arrugas=0.05, suciedad=0.15)
        if region == "pie":
            img = tela(alto, ancho, cfg.get("zapatos", (0.05, 0.045, 0.04)), s + 4, arrugas=0.04, suciedad=0.15)
            img[F < 0.15] *= 0.6
            return img
        if region in ("pelvis", "pierna"):
            img = tela(alto, ancho, cfg.get("pantalon", (0.15, 0.15, 0.16)), s + 5, **cfg.get("tela_op", {}))
            if region == "pierna":
                img[F > 0.95] *= 0.7
                for deco in cfg.get("decoraciones", []):
                    if deco[0] == "rodilleras" and P is not None:
                        z = P[..., 2] / h
                        rod = (np.abs(z - 0.53) < 0.05) & (np.abs(U - 0.5) < 0.22)
                        img[rod] = deco[1]
            return _comunes(img, alto, ancho, s)
        color = cfg.get("camisa", (0.3, 0.3, 0.3))
        if region == "manga":
            color = cfg.get("mangas", color)
        img = tela(alto, ancho, color, s + 6, **cfg.get("tela_op", {}))
        if region == "manga":
            img[F > 0.88] *= 0.7
        if region == "torso" and P is not None:
            z = P[..., 2] / h
            du = U - 0.5
            for deco in cfg.get("decoraciones", []):
                img = decorar(img, deco, U, z, du, alto, ancho, s, piel)
        return _comunes(img, alto, ancho, s)

    def _comunes(img, alto, ancho, s):
        if cfg.get("sangre"):
            m = C.manchas(alto, ancho, s + 9, int(4 * cfg["sangre"]) + 1, 1.5 * H.PX, 6 * H.PX)
            img = C.mezclar(img, (0.27, 0.03, 0.02), m * min(cfg["sangre"], 1.0) * 0.85)
        return img
    return pintar


def decorar(img, deco, U, z, du, alto, ancho, s, piel):
    tipo = deco[0]
    if tipo == "cuello_piel":                        # piel visible en el cuello
        m = z > deco[1]
        img[m] = H.piel(alto, ancho, piel, s + 20)[m]
    elif tipo == "botones":                          # (color, separacion_u, z0, z1)
        _, color, sep, z0, z1 = deco
        m = (np.abs(np.abs(du) - sep) < 0.007) & (np.abs(((z - z0) % 0.08) - 0.04) < 0.007) & (z > z0) & (z < z1)
        img[m] = color
    elif tipo == "placa":                            # (color, u, z)
        _, color, u, zz = deco
        m = (np.abs(U - u) < 0.022) & (np.abs(z - zz) < 0.025)
        img[m] = color
        img[m & (np.abs(U - u) < 0.008) & (np.abs(z - zz) < 0.009)] = np.array(color) * 0.4
    elif tipo == "corbata":                          # (color, z0, z1)
        _, color, z0, z1 = deco
        ancho_c = 0.016 + (z1 - z) * 0.03
        m = (np.abs(du) < ancho_c) & (z > z0) & (z < z1)
        img[m] = color
        nudo = (np.abs(du) < 0.014) & (np.abs(z - z1 + 0.015) < 0.015)
        img[nudo] = np.array(color) * 0.8
    elif tipo == "cuello_camisa":                    # (color, z0, ancho)
        _, color, z0, a = deco
        m = (z > z0) & (np.abs(du) < a * (z - z0) / 0.08 + 0.01) & (z < 1.48)
        img[m] = color
    elif tipo == "abertura":                         # chaqueta abierta: (color_interior, z0, z1, ancho)
        _, color, z0, z1, a = deco
        m = (z > z0) & (z < z1) & (np.abs(du) < a * (1.0 + (z - z0) * 1.5))
        img[m] = tela(alto, ancho, color, s + 21, arrugas=0.1)[m]
        borde = (z > z0) & (z < z1) & (np.abs(np.abs(du) - a * (1.0 + (z - z0) * 1.5)) < 0.012)
        img[borde] *= 0.5
    elif tipo == "tirantes":                         # (color,)
        m = ((np.abs(np.abs(du) - 0.075) < 0.012) | (np.abs(np.abs(U - 0.0 + 0.0) - 0.06) < 0.012)
             | (np.abs(np.abs(U - 1.0) - 0.06) < 0.012)) & (z > 1.0) & (z < 1.46)
        img[m] = deco[1]
    elif tipo == "panel":                            # chaleco o peto: (color, z0, z1, ancho_u)
        _, color, z0, z1, a = deco
        m = (z > z0) & (z < z1) & ((np.abs(du) < a) | (np.abs(np.minimum(U, 1 - U)) < a))
        img[m] = tela(alto, ancho, color, s + 22, arrugas=0.08)[m]
    elif tipo == "texto":                            # (texto, color, u_centro, z)
        _, texto, color, u, zz = deco
        filas = np.where(np.any(np.abs(z - zz) < 0.004, axis=1))[0]
        if len(filas):
            y = int(filas[0]) - 2
            x = int(u * ancho) - len(texto) * 2 * H.PX
            escribir(img, texto, x, max(y, 2), H.PX, color)
    elif tipo == "bolsillos":                        # (color,)
        for u in (0.41, 0.59):
            m = (np.abs(U - u) < 0.035) & (np.abs(z - 1.31) < 0.003)
            img[m] = deco[1]
            m = (np.abs(np.abs(U - u) - 0.035) < 0.003) & (z > 1.24) & (z < 1.31)
            img[m] = deco[1]
    elif tipo == "cadena_reloj":
        m = (np.abs(z - (1.12 - (np.abs(du - 0.05) * 0.8))) < 0.004) & (du > 0.0) & (du < 0.12)
        img[m] = (0.75, 0.62, 0.3)
    elif tipo == "vendas":                           # (color_oscuro,) líneas horizontales irregulares
        lineas = np.abs(np.sin((z * 60 + C.ruido(alto, ancho, s + 23, 2, celdas=3) * 3) * np.pi)) < 0.12
        img[lineas] = np.array(deco[1])
    elif tipo == "faldon_oscuro":
        img[z < deco[1]] *= 0.8
    return img


# ============================================================= Personajes ===

def mats(*definiciones):
    """Crea materiales de accesorios: (nombre, color, semilla, opciones)."""
    salida = []
    for d in definiciones:
        nombre, color, semilla = d[:3]
        op = d[3] if len(d) > 3 else {}
        salida.append(PJ.material_ruido(nombre, color, semilla, **op))
    return salida


def construir(nombre, e, r, cfg, extras=None, materiales=(), pelo=None, mechones=0, semilla=50,
              pieza_extra=None):
    piezas, huesos, datos = H.piezas_humano(e, r, semilla=semilla)
    if pelo is not None:
        piezas.append(H.pieza_pelo(datos, semilla=semilla + 1, volumen=pelo))
    if pieza_extra:
        piezas.append(pieza_extra(datos))
    atlas = H.pintar_atlas(piezas, pintor_ropa(e, datos, cfg), semilla=semilla)
    col = C.coleccion(nombre)
    uv_piel = H.uv_de_region("mano", 0.5, 0.3)

    def todo(malla):
        if mechones:
            H.pelo_mechones(malla, datos, semilla=semilla + 2, cantidad=mechones, volumen=1.0, largo=0.8)
        if cfg.get("cara") != "vacio" and not cfg.get("sin_orejas"):
            H.orejas(malla, datos, uv_piel)
        if extras:
            extras(malla, huesos, datos)
    arm, obj = H.construir_personaje(nombre, piezas, huesos, atlas, col, todo, materiales_extra=materiales)
    return col, arm, e


def cinto(malla, e, mat_cuero, mat_hebilla, z=1.0):
    g, h = e["grosor"], e["alto"]
    PJ.cinturon(malla, e, z, mat_cuero, mat_hebilla, 0.168 * g * h, 0.11 * g * h * e["barriga"], 0.117 * g * h)


# --- PASADO -----------------------------------------------------------------------

def policia_patrullero():
    e = H.proporciones(alto=1.02, grosor=1.08, barriga=1.1, grosor_brazos=1.1, cabeza=1.03)
    r = H.ropa(manga="larga", camisa_suelta=False, holgura=1.05, pantalon_ancho=1.05, arrugas=0.03)
    azul = (0.1, 0.12, 0.2)
    cfg = {"piel": PIEL_MEDIA, "pelo": (0.07, 0.05, 0.04), "cara": "bigote",
           "cara_op": {"bigote": True, "barba": 0.2, "suciedad": 0.15, "expresion": "tenso"},
           "camisa": azul, "pantalon": (0.08, 0.09, 0.14), "zapatos": (0.03, 0.03, 0.03),
           "decoraciones": [("cuello_piel", 1.49), ("placa", (0.72, 0.6, 0.28), 0.6, 1.33),
                            ("bolsillos", (0.05, 0.06, 0.1)), ("botones", (0.55, 0.47, 0.25), 0.0, 0.95, 1.42),
                            ("corbata", (0.04, 0.045, 0.07), 1.12, 1.44)]}
    m = mats(("Policia_Gorra", (0.08, 0.09, 0.15), 101), ("Policia_Visera", (0.02, 0.02, 0.02), 102,
             {"rugosidad": 0.4, "especular": 0.5}), ("Policia_Placa", (0.72, 0.6, 0.28), 103,
             {"rugosidad": 0.35, "metalico": 0.9}), ("Policia_Cuero", (0.03, 0.03, 0.03), 104, {"rugosidad": 0.45}),
             ("Policia_Porra", (0.04, 0.04, 0.04), 105, {"rugosidad": 0.4}),
             ("Policia_Linterna", (0.12, 0.12, 0.13), 106, {"metalico": 0.8, "rugosidad": 0.4}))
    m.append(C.material_emisivo("MAT_Linterna_Luz", (1.0, 0.95, 0.8), 25.0))

    def extras(malla, huesos, datos):
        PJ.gorra_de_plato(malla, datos, 1, 2, 3)
        cinto(malla, e, 4, 3)
        h = e["alto"]
        caja_orientada(malla, (-0.19 * h, 0.0, 0.95 * h), (0.025, 0, 0), (0, 0.05, 0), (0, 0, 0.07), 4, {"cadera": 1})
        _, agarre, eje, adelante = ejes_mano(huesos, "R")
        barra(malla, agarre - adelante * 0.08, agarre + adelante * 0.5, 0.018, 5, {"mano.R": 1})
        _, agarre, eje, adelante = ejes_mano(huesos, "L")
        barra(malla, agarre - adelante * 0.05, agarre + adelante * 0.2, 0.022, 6, {"mano.L": 1}, radio_b=0.032)
        barra(malla, agarre + adelante * 0.2, agarre + adelante * 0.205, 0.03, 7, {"mano.L": 1})
    return construir("Policia_Patrullero", e, r, cfg, extras, m, pelo=0.9, semilla=110)


def policia_tactico():
    e = H.proporciones(alto=1.04, grosor=1.24, grosor_brazos=1.25, grosor_piernas=1.2, cabeza=1.05)
    r = H.ropa(manga="larga", camisa_suelta=False, holgura=1.15, pantalon_ancho=1.08, arrugas=0.025,
               zapato=1.12)
    negro = (0.06, 0.07, 0.1)
    cfg = {"piel": PIEL_MEDIA, "cara": "normal", "cara_op": {"barba": 0.35, "expresion": "tenso"},
           "camisa": negro, "pantalon": (0.06, 0.065, 0.09), "zapatos": (0.02, 0.02, 0.02),
           "manos": (0.03, 0.03, 0.035), "sin_orejas": True,
           "decoraciones": [("cuello_piel", 1.5), ("panel", (0.035, 0.04, 0.055), 0.98, 1.44, 0.2),
                            ("texto", "POLICÍA", (0.85, 0.85, 0.82), 0.5, 1.3),
                            ("rodilleras", (0.03, 0.03, 0.035))]}
    m = mats(("Tactico_Casco", (0.07, 0.08, 0.11), 121, {"rugosidad": 0.35, "especular": 0.5}),
             ("Tactico_Cuero", (0.025, 0.025, 0.03), 122), ("Tactico_Porra", (0.03, 0.03, 0.03), 123))
    m.append(C.material("MAT_Tactico_Visor", color=(0.05, 0.06, 0.08), rugosidad=0.1, especular=0.9))
    escudo_img = C.lienzo(128, 64, (0.08, 0.09, 0.12)) * (0.8 + 0.3 * C.ruido(128, 64, 124, 3)[..., None])
    escudo_img[:3] = escudo_img[-3:] = escudo_img[:, :3] = escudo_img[:, -3:] = (0.03, 0.03, 0.04)
    escribir(escudo_img, "POLICÍA", 4, 62, 2, (0.85, 0.85, 0.82))
    m.append(C.material("MAT_Tactico_Escudo", C.guardar_png("personajes/acc_escudo_policia.png", escudo_img),
                        rugosidad=0.3, especular=0.6))

    def extras(malla, huesos, datos):
        zc, k = datos["zc"], datos["k"]
        cupula(malla, Vector((0, 0.004 * k, zc + 0.13 * k)), 0.105 * k, 0.12 * k, 0.13 * k, 1, {"cabeza": 1})
        # Visor: placa curva delante de la cara.
        for i in range(6):
            a0, a1 = math.radians(-60 + 20 * i), math.radians(-40 + 20 * i)
            pts = []
            for a in (a0, a1):
                pts.append(Vector((math.sin(a) * 0.115 * k, -math.cos(a) * 0.125 * k, zc + 0.06 * k)))
            arriba = [p + Vector((0, -0.01 * k, 0.11 * k)) for p in pts]
            idx = [malla.vertice(q, {"cabeza": 1}) for q in (pts[0], pts[1], arriba[1], arriba[0])]
            malla.cara(idx, [(0, 0), (1, 0), (1, 1), (0, 1)], 4)
        cinto(malla, e, 2, 2)
        _, agarre, eje, adelante = ejes_mano(huesos, "R")
        barra(malla, agarre - adelante * 0.08, agarre + adelante * 0.55, 0.02, 3, {"mano.R": 1})
        # Escudo sobre el antebrazo izquierdo.
        codo, muneca = Vector(huesos["antebrazo.L"][0]), Vector(huesos["antebrazo.L"][1])
        centro = (codo + muneca) / 2 + Vector((0.04, -0.1, 0))
        largo = (muneca - codo).normalized()
        normal = Vector((0, -1, 0))
        derecha = normal.cross(largo).normalized()
        caja_orientada(malla, centro + normal * -0.012, derecha * 0.25, largo * 0.5, normal * 0.01, 1,
                       {"antebrazo.L": 1})
        frente = centro + normal * 0.002
        esquinas = [frente - derecha * 0.25 + largo * 0.5, frente + derecha * 0.25 + largo * 0.5,
                    frente + derecha * 0.25 - largo * 0.5, frente - derecha * 0.25 - largo * 0.5]
        idx = [malla.vertice(q, {"antebrazo.L": 1}) for q in esquinas]
        malla.cara([idx[3], idx[2], idx[1], idx[0]], [(0, 1), (1, 1), (1, 0), (0, 0)], 5)
    return construir("Policia_Tactico", e, r, cfg, extras, m, semilla=120)


def cupula(malla, centro, rx, ry, rz, mat, pesos, lados=12, anillos=5, desde=-0.15):
    """Casco: media esfera desde la elevación «desde» (radianes) hasta arriba."""
    filas = []
    for i in range(anillos + 1):
        phi = desde + (math.pi / 2 - desde) * i / anillos
        if i == anillos:
            filas.append([malla.vertice(centro + Vector((0, 0, rz)), pesos)] * lados)
            break
        fila = []
        for j in range(lados):
            a = 2 * math.pi * j / lados
            fila.append(malla.vertice(centro + Vector((math.sin(a) * math.cos(phi) * rx,
                                                       -math.cos(a) * math.cos(phi) * ry,
                                                       math.sin(phi) * rz)), pesos))
        filas.append(fila)
    for i in range(anillos):
        for j in range(lados):
            j2 = (j + 1) % lados
            caras = [filas[i][j], filas[i][j2], filas[i + 1][j2], filas[i + 1][j]]
            if i == anillos - 1:
                caras = [filas[i][j], filas[i][j2], filas[i + 1][j]]
            a, b, c = (malla.vertices[t] for t in caras[:3])
            if (b - a).cross(c - a).dot(a - centro) < 0:
                caras = caras[::-1]
            malla.cara(caras, [(0, 0), (1, 0), (1, 1), (0, 1)][:len(caras)], mat)


def guardia():
    e = H.proporciones(alto=1.01, grosor=1.1, barriga=1.14, grosor_brazos=1.1)
    r = H.ropa(manga="larga", camisa_suelta=False, holgura=1.05, pantalon_ancho=1.05, arrugas=0.03)
    caqui = (0.5, 0.45, 0.32)
    cfg = {"piel": PIEL_MEDIA, "pelo": (0.06, 0.05, 0.045), "cara": "bigote",
           "cara_op": {"bigote": True, "barba": 0.25, "suciedad": 0.2},
           "camisa": caqui, "pantalon": (0.2, 0.19, 0.17), "zapatos": (0.04, 0.035, 0.03),
           "tela_op": {"suciedad": 0.45, "manchas": 0.8},
           "decoraciones": [("cuello_piel", 1.49), ("botones", (0.3, 0.27, 0.2), 0.0, 0.95, 1.42),
                            ("bolsillos", np.array(caqui) * 0.6), ("placa", (0.62, 0.52, 0.25), 0.62, 1.33),
                            ("corbata", (0.1, 0.08, 0.06), 1.1, 1.45)]}
    m = mats(("Guardia_Gorra", (0.12, 0.12, 0.13), 131), ("Guardia_Visera", (0.02, 0.02, 0.02), 132,
             {"rugosidad": 0.4, "especular": 0.5}), ("Guardia_Placa", (0.65, 0.55, 0.28), 133,
             {"metalico": 0.9, "rugosidad": 0.35}), ("Guardia_Cuero", (0.06, 0.04, 0.03), 134),
             ("Guardia_Porra", (0.04, 0.035, 0.03), 135), ("Llaves_Laton_G", (0.5, 0.4, 0.22), 136,
             {"metalico": 0.9, "rugosidad": 0.45}))

    def extras(malla, huesos, datos):
        PJ.gorra_de_plato(malla, datos, 1, 2, 3)
        cinto(malla, e, 4, 3)
        _, agarre, eje, adelante = ejes_mano(huesos, "R")
        barra(malla, agarre - adelante * 0.08, agarre + adelante * 0.5, 0.018, 5, {"mano.R": 1})
        h = e["alto"]
        base = Vector((0.17 * h, -0.05 * h, 0.95 * h))
        for i in range(5):
            barra(malla, base + Vector((0.004 * i, 0, 0)), base + Vector((0.004 * i, -0.006, -0.08 - 0.01 * i)),
                  0.006, 6, {"cadera": 1}, lados=4)
    return construir("Guardia_Penitenciario", e, r, cfg, extras, m, pelo=0.9, semilla=130)


def interrogador():
    e = H.proporciones(alto=1.0, grosor=1.12, barriga=1.18, grosor_brazos=1.12, cuello=1.15)
    r = H.ropa(manga="larga", camisa_suelta=False, holgura=1.04, pantalon_ancho=1.05, arrugas=0.035)
    cfg = {"piel": (0.7, 0.53, 0.42), "pelo": (0.05, 0.04, 0.035), "cara": "bigote",
           "cara_op": {"bigote": True, "barba": 0.3, "suciedad": 0.1, "expresion": "neutro"},
           "camisa": (0.78, 0.76, 0.7), "pantalon": (0.28, 0.28, 0.3), "zapatos": (0.07, 0.05, 0.04),
           "tela_op": {"suciedad": 0.4, "manchas": 0.4, "mancha": (0.45, 0.4, 0.3)},
           "decoraciones": [("cuello_piel", 1.49), ("botones", (0.85, 0.85, 0.8), 0.0, 0.95, 1.4),
                            ("tirantes", (0.15, 0.1, 0.07)), ("corbata", (0.5, 0.06, 0.05), 1.05, 1.45)]}
    m = mats(("Interrogador_Cuero", (0.08, 0.05, 0.03), 141))

    def extras(malla, huesos, datos):
        cinto(malla, e, 1, 1)
    return construir("Interrogador", e, r, cfg, extras, m, pelo=0.95, semilla=140)


def verdugo():
    e = H.proporciones(alto=1.05, grosor=1.28, barriga=1.2, pecho=1.12, grosor_brazos=1.38,
                       grosor_piernas=1.2, cuello=1.35, manos=1.15)
    r = H.ropa(manga="corta", camisa_suelta=False, holgura=1.0, pantalon_ancho=1.05, largo_manga=0.45,
               arrugas=0.03)
    cfg = {"piel": (0.66, 0.48, 0.38), "pelo": (0.05, 0.04, 0.035), "cara": "normal",
           "cara_op": {"barba": 0.55, "suciedad": 0.4, "expresion": "neutro"},
           "camisa": (0.5, 0.48, 0.44), "pantalon": (0.18, 0.17, 0.16), "zapatos": (0.04, 0.035, 0.03),
           "manos": (0.06, 0.045, 0.035), "sangre": 0.7,
           "decoraciones": [("cuello_piel", 1.49), ("botones", (0.3, 0.28, 0.25), 0.0, 1.0, 1.42)]}
    delantal = C.lienzo(128, 64, (0.24, 0.13, 0.07)) * (0.75 + 0.45 * C.ruido(128, 64, 151, 4)[..., None])
    delantal = C.mezclar(delantal, (0.22, 0.02, 0.015), C.manchas(128, 64, 152, 9, 3, 12) * 0.85)
    delantal = C.mezclar(delantal, (0.1, 0.05, 0.03), C.chorreones(128, 64, 153, 25, 0.8) * 0.6)
    m = mats(("Verdugo_Gorra", (0.08, 0.075, 0.07), 154), ("Verdugo_Visera", (0.02, 0.02, 0.02), 155),
             ("Verdugo_Placa", (0.45, 0.4, 0.3), 156, {"metalico": 0.7}),
             ("Hacha_Mango", (0.25, 0.15, 0.08), 157), ("Hacha_Hoja", (0.3, 0.3, 0.32), 158,
             {"metalico": 0.85, "rugosidad": 0.4}))
    m.append(C.material("MAT_Verdugo_Delantal", C.guardar_png("personajes/acc_delantal.png", delantal),
                        rugosidad=0.55, especular=0.4))
    m.append(C.material("MAT_Sangre_Hoja", color=(0.25, 0.02, 0.015), rugosidad=0.3, especular=0.6))

    def extras(malla, huesos, datos):
        PJ.gorra_de_plato(malla, datos, 1, 2, 3)
        h, g = e["alto"], e["grosor"]
        # Delantal de cuero: placa curva desde el pecho hasta las rodillas.
        filas = []
        for z in (1.38, 1.15, 0.95, 0.75, 0.52):
            ancho = 0.17 if z > 1.2 else 0.2
            fila = []
            for t in (-1, -0.5, 0, 0.5, 1):
                x = t * ancho * g * h
                y = -(0.135 * g * h * e["barriga"]) * (1 - 0.3 * t * t) - 0.012
                if z < 0.9:
                    y -= 0.03 * (0.9 - z) / 0.4
                fila.append(malla.vertice((x, y, z * h), {"columna" if z > 1.1 else "cadera": 1}))
            filas.append(fila)
        for i in range(len(filas) - 1):
            for j in range(4):
                malla.cara([filas[i][j], filas[i + 1][j], filas[i + 1][j + 1], filas[i][j + 1]],
                           [(j / 4, 1 - i / 4), (j / 4, 1 - (i + 1) / 4), ((j + 1) / 4, 1 - (i + 1) / 4),
                            ((j + 1) / 4, 1 - i / 4)], 6)
        # Hacha de ejecución colgando de la mano derecha.
        muneca, agarre, eje, adelante = ejes_mano(huesos, "R")
        fin = agarre + eje * 0.85
        barra(malla, agarre - eje * 0.12, fin, 0.022, 4, {"mano.R": 1})
        lado = adelante
        hoja_c = fin - eje * 0.08 + lado * 0.13
        caja_orientada(malla, hoja_c, lado * 0.13, eje * 0.12, eje.cross(lado).normalized() * 0.012, 5,
                       {"mano.R": 1})
        caja_orientada(malla, hoja_c + lado * 0.12, lado * 0.025, eje * 0.15, eje.cross(lado).normalized() * 0.006,
                       7, {"mano.R": 1})
    return construir("Verdugo", e, r, cfg, extras, m, pelo=0.95, semilla=150)


def alcaide():
    e = H.proporciones(alto=0.99, grosor=1.24, barriga=1.38, pecho=1.08, cabeza=1.06, cuello=1.35,
                       grosor_brazos=1.15, grosor_piernas=1.15)
    r = H.ropa(manga="larga", camisa_suelta=True, z_faldon=0.74, vuelo_faldon=1.04, holgura=1.05,
               pantalon_ancho=1.08, arrugas=0.02)
    traje = (0.11, 0.11, 0.12)
    cfg = {"piel": (0.72, 0.56, 0.47), "pelo": (0.32, 0.31, 0.3), "cara": "calvo",
           "cara_op": {"barba": 0.15, "suciedad": 0.05, "expresion": "neutro"},
           "camisa": traje, "pantalon": traje, "zapatos": (0.03, 0.025, 0.02),
           "tela_op": {"suciedad": 0.15, "manchas": 0.2},
           "decoraciones": [("cuello_piel", 1.495), ("abertura", (0.07, 0.07, 0.075), 1.12, 1.49, 0.05),
                            ("cuello_camisa", (0.78, 0.77, 0.72), 1.36, 0.05),
                            ("corbata", (0.48, 0.05, 0.04), 1.2, 1.45), ("cadena_reloj",),
                            ("botones", (0.05, 0.05, 0.05), 0.03, 1.0, 1.12)]}
    return construir("Alcaide", e, r, cfg, None, (), semilla=160)


PRESOS = {
    # variante: proporciones, piel, pelo (None = calvo), barba, semilla
    "a": ({"alto": 1.0, "grosor": 1.0, "grosor_brazos": 1.05}, (0.7, 0.52, 0.42), (0.07, 0.05, 0.04), 0.4, 240),
    "b": ({"alto": 0.97, "grosor": 1.18, "barriga": 1.2, "grosor_brazos": 1.2, "cuello": 1.25},
          (0.5, 0.36, 0.27), None, 0.6, 250),
    "c": ({"alto": 1.04, "grosor": 0.88, "grosor_brazos": 0.9, "grosor_piernas": 0.92, "hombro_x": 0.19},
          (0.78, 0.62, 0.52), (0.3, 0.2, 0.12), 0.15, 260),
}


def preso_generico(variante="a"):
    """Presos del pasado (F3, la prisión en funcionamiento): uniforme naranja limpio y rostro normal."""
    prop, piel, pelo, barba, s = PRESOS[variante]
    e = H.proporciones(**prop)
    r = H.ropa(manga="corta", camisa_suelta=True, z_faldon=0.78, vuelo_faldon=1.1, holgura=1.12,
               pantalon_ancho=1.15, largo_manga=0.6, arrugas=0.05)
    piezas, huesos, datos = H.piezas_humano(e, r, semilla=s)
    if pelo is not None:
        piezas.append(H.pieza_pelo(datos, semilla=s + 1, volumen=0.97))

    def rostro(U, F, P):
        return cara("calvo" if pelo is None else "normal", U, F, P, s + 2, datos, piel, pelo or (0.05, 0.04, 0.035),
                    barba=barba, suciedad=0.25, expresion="neutro")
    pintor = PJ.pintor_preso(e, datos, s + 3, sangre=0.0, rostro=rostro, piel_color=piel, numero=True)
    atlas = H.pintar_atlas(piezas, pintor, semilla=s + 4)
    nombre = f"Preso_Generico_{variante.upper()}"
    col = C.coleccion(nombre)
    uv_piel = H.uv_de_region("mano", 0.5, 0.3)

    def extras(malla):
        H.orejas(malla, datos, uv_piel)
    arm, obj = H.construir_personaje(nombre, piezas, huesos, atlas, col, extras)
    return col, arm, e


# --- PRESENTE -----------------------------------------------------------------------

def aislado(variante="a"):
    e = H.proporciones(alto=0.99, grosor=0.8, grosor_brazos=0.72, grosor_piernas=0.78, cabeza=0.98,
                       cuello=0.85, hombro_x=0.18)
    r = H.ropa(manga="corta", camisa_suelta=True, z_faldon=0.78, vuelo_faldon=1.1, holgura=1.12,
               pantalon_ancho=1.15, arrugas=0.07, largo_manga=0.55)
    piezas, huesos, datos = H.piezas_humano(e, r, semilla=170)
    if variante == "a":
        piezas.append(H.pieza_pelo(datos, semilla=171, volumen=0.97))

    def rostro(U, F, P):
        return cara("borroso", U, F, P, 172, datos, PIEL_MUERTA, (0.12, 0.11, 0.1), barba=0.4, suciedad=0.6,
                    sangre=0.6 if variante == "b" else 0.2)
    pintor = PJ.pintor_preso(e, datos, 173, naranja=(0.6, 0.32, 0.17), sangre=1.0 if variante == "b" else 0.6,
                             rostro=rostro, piel_color=PIEL_MUERTA, numero=False, desgarros=0.9)
    atlas = H.pintar_atlas(piezas, pintor, semilla=174)
    nombre = f"Aislado_{variante.upper()}"
    col = C.coleccion(nombre)
    uv_piel = H.uv_de_region("mano", 0.5, 0.3)

    def extras(malla):
        H.orejas(malla, datos, uv_piel)
    arm, obj = H.construir_personaje(nombre, piezas, huesos, atlas, col, extras)
    return col, arm, e


def el_vigilante():
    e = H.proporciones(alto=1.45, grosor=0.6, grosor_brazos=0.55, grosor_piernas=0.6, brazos=1.28,
                       manos=1.25, cabeza=0.75, cuello=1.3, hombro_x=0.17)
    r = H.ropa(manga="ninguna", camisa_suelta=False, holgura=0.95, pantalon_ancho=0.9, arrugas=0.05,
               sin_rostro=True, material_cabeza=4)
    vendas = (0.42, 0.38, 0.33)
    cfg = {"piel": (0.45, 0.43, 0.41), "cara": "vacio", "camisa": vendas, "pantalon": vendas,
           "brazos": vendas, "manos": (0.3, 0.29, 0.28), "zapatos": (0.3, 0.29, 0.28),
           "tela_op": {"suciedad": 0.55, "manchas": 1.0, "mancha": (0.15, 0.1, 0.08)},
           "decoraciones": [("vendas", (0.22, 0.2, 0.17))]}
    m = mats(("Vigilante_Caseta", (0.24, 0.24, 0.25), 181, {"rugosidad": 0.7}),
             ("Vigilante_Tejado", (0.12, 0.12, 0.13), 182))
    m.append(C.material_emisivo("MAT_Vigilante_Ventana", (1.0, 0.92, 0.75), 14.0))
    m.append(C.material("MAT_Vacio_V", color=(0.0, 0.0, 0.0), rugosidad=1.0, especular=0.0))

    def extras(malla, huesos, datos):
        zc, k = datos["zc"], datos["k"]
        c = Vector((0, 0.0, zc + 0.12 * k))
        s = 0.13 * k
        p = {"cabeza": 1}
        malla.caja((c.x - s, c.y - s, c.z - s * 0.9), (c.x + s, c.y + s, c.z - s * 0.2), 1, pesos=p, escala_uv=4)
        malla.caja((c.x - s * 0.95, c.y - s * 0.95, c.z - s * 0.2), (c.x + s * 0.95, c.y + s * 0.95, c.z + s * 0.5),
                   3, pesos=p, escala_uv=4)
        for x in (-s, s):
            for y in (-s, s):
                malla.caja((c.x + x - 0.012, c.y + y - 0.012, c.z - s * 0.2), (c.x + x + 0.012, c.y + y + 0.012,
                           c.z + s * 0.5), 1, pesos=p, escala_uv=4)
        # Tejado a cuatro aguas.
        base = [Vector((c.x + x, c.y + y, c.z + s * 0.5)) for x, y in ((-s * 1.25, -s * 1.25), (s * 1.25, -s * 1.25),
                                                                      (s * 1.25, s * 1.25), (-s * 1.25, s * 1.25))]
        punta = malla.vertice(c + Vector((0, 0, s * 1.3)), p)
        idx = [malla.vertice(q, p) for q in base]
        for j in range(4):
            malla.cara([idx[j], idx[(j + 1) % 4], punta], [(0, 0), (1, 0), (0.5, 1)], 2)
        malla.cara(idx[::-1], [(0, 0), (1, 0), (1, 1), (0, 1)], 2)
    return construir("El_Vigilante", e, r, cfg, extras, m, semilla=180)


def el_condenado():
    e = H.proporciones(hombro_x=0.205, grosor=1.0, grosor_brazos=1.15, grosor_piernas=1.12, cabeza=1.08,
                       cuello=1.08)
    r = H.ropa(manga="corta", camisa_suelta=True, z_faldon=0.78, vuelo_faldon=1.15, pantalon_ancho=1.25,
               holgura=1.17, largo_manga=0.62, vuelo_manga=1.2, arrugas=0.05)
    piezas, huesos, datos = H.piezas_humano(e, r, semilla=11)
    piezas.append(H.pieza_pelo(datos, semilla=7, volumen=1.0))
    piel = (0.66, 0.6, 0.56)

    def rostro(U, F, P):
        return cara("borroso_sangre", U, F, P, 191, datos, piel, PJ.PELO_CASTANO, barba=0.4, sangre=1.0)
    pintor = PJ.pintor_preso(e, datos, 11, naranja=(0.68, 0.36, 0.2), sangre=1.6, rostro=rostro,
                             piel_color=piel, numero=True, desgarros=0.3)
    atlas = H.pintar_atlas(piezas, pintor, semilla=192)
    col = C.coleccion("El_Condenado")
    uv_piel = H.uv_de_region("mano", 0.5, 0.3)

    def extras(malla):
        H.pelo_mechones(malla, datos, semilla=9, cantidad=16, volumen=1.04)
        H.orejas(malla, datos, uv_piel)
    arm, obj = H.construir_personaje("El_Condenado", piezas, huesos, atlas, col, extras)
    return col, arm, e


def capucha_sentencia(datos):
    """Capucha alta y rígida (mantas de presidio atadas con correas), de la lámina del presente."""
    zc, k = datos["zc"], datos["k"]
    anillos = []
    for z, rx, ry, y in ((-0.02, 0.1, 0.11, 0.0), (0.12, 0.13, 0.135, -0.005), (0.3, 0.13, 0.135, -0.012),
                         (0.45, 0.12, 0.125, -0.02), (0.53, 0.1, 0.11, -0.022)):
        anillos.append(H.anillo((0, y * k, zc + z * k), rx * k, ry * k, ry * k))
    return H.Pieza("pelo", anillos, 4, "pelo", [("cabeza", 0, 1)], tapa_fin=True, arrugas=0.05)


def la_sentencia():
    e = H.proporciones(alto=1.5, grosor=1.28, grosor_brazos=1.3, grosor_piernas=1.2, manos=1.45, cabeza=1.0,
                       cuello=1.4, hombro_x=0.22)
    r = H.ropa(manga="larga", camisa_suelta=False, abrigo_largo=0.1, cuello_alto=True, sin_rostro=True,
               material_cabeza=6, pantalon_ancho=1.1, zapato=1.15, arrugas=0.05, vuelo_abrigo=0.8)
    abrigo = (0.3, 0.12, 0.09)

    def pintar_capucha(U, F, P, s):
        alto, ancho = U.shape
        img = H.tela(alto, ancho, (0.36, 0.32, 0.27), s, arrugas=0.3, suciedad=0.5, manchas_oscuras=1.0)
        for f in (0.25, 0.6):
            img[np.abs(F - f) < 0.05] = (0.07, 0.05, 0.04)
        img = C.mezclar(img, (0.3, 0.03, 0.02), C.chorreones(alto, ancho, s + 1, 22, 0.8) * 0.8)
        return img
    cfg = {"piel": (0.4, 0.37, 0.35), "cara": "vacio", "camisa": abrigo, "pantalon": (0.12, 0.1, 0.09),
           "zapatos": (0.05, 0.04, 0.035), "manos": (0.32, 0.29, 0.27), "sangre": 1.0,
           "pintar_pelo": pintar_capucha, "sin_orejas": True,
           "tela_op": {"suciedad": 0.6, "manchas": 1.0, "mancha": (0.22, 0.03, 0.02)},
           "decoraciones": [("faldon_oscuro", 0.4)]}
    puerta = C.lienzo(128, 64, (0.3, 0.29, 0.29)) * (0.7 + 0.5 * C.ruido(128, 64, 201, 4)[..., None])
    for x in range(6, 64, 10):
        puerta[8:120, x:x + 3] = (0.12, 0.1, 0.09)
    puerta[8:11] = puerta[60:63] = puerta[117:120] = (0.12, 0.1, 0.09)
    puerta = C.mezclar(puerta, (0.35, 0.16, 0.07), C.suave(C.ruido(128, 64, 202, 4, celdas=5), 0.5, 0.7) * 0.8)
    puerta = C.mezclar(puerta, (0.28, 0.02, 0.015), C.chorreones(128, 64, 203, 20, 0.6) * 0.9)
    puerta[:, 58:] = (0.55, 0.55, 0.57)                            # filo
    m = mats(("Sentencia_Cuero", (0.06, 0.04, 0.03), 204), ("Sentencia_Hebilla", (0.5, 0.45, 0.38), 205,
             {"metalico": 0.85}), ("Sentencia_Mango", (0.18, 0.12, 0.08), 206))
    m.append(C.material("MAT_Sentencia_Hoja", C.guardar_png("personajes/acc_hoja_puerta.png", puerta),
                        rugosidad=0.45, metalico=0.6, especular=0.5))
    m.append(C.material("MAT_Mazo", color=(0.2, 0.17, 0.15), rugosidad=0.6))
    m.append(C.material("MAT_Vacio_S", color=(0.0, 0.0, 0.0), rugosidad=1.0, especular=0.0))

    def extras(malla, huesos, datos):
        h, g = e["alto"], e["grosor"]
        PJ.cinturon(malla, e, 0.98, 1, 2, 0.17 * g * h * 1.05, 0.115 * g * h, 0.12 * g * h)
        # Hoja hecha con una puerta de celda (1,6 x 0,7 m), con lomo de mazo. Sale de la mano hacia
        # atrás y abajo, unos 30 grados: la arrastra por el suelo al andar y su silueta asoma tras ella.
        muneca, agarre, eje, adelante = ejes_mano(huesos, "R")
        d = (eje * 0.5 - adelante * 0.87).normalized()
        normal = eje.cross(adelante).normalized()                   # cara plana de la hoja (hacia un lado)
        arriba = (-eje - d * (-eje).dot(d)).normalized()            # hacia el lomo
        barra(malla, agarre - d * 0.14, agarre + d * 0.5, 0.032, 3, {"mano.R": 1}, lados=6)
        tope = agarre + d * 0.5
        caja_orientada(malla, tope + d * 0.8 + arriba * 0.24, d * 0.8, arriba * 0.35, normal * 0.028, 4,
                       {"mano.R": 1})
        caja_orientada(malla, tope + d * 0.12 + arriba * 0.72, d * 0.16, arriba * 0.14, normal * 0.13, 5,
                       {"mano.R": 1})
    return construir("La_Sentencia", e, r, cfg, extras, m, semilla=200, pieza_extra=capucha_sentencia)


def el_director():
    e = H.proporciones(alto=2.2, grosor=1.18, grosor_brazos=1.1, brazos=1.12, manos=1.65, cabeza=0.95,
                       cuello=1.2, hombro_x=0.215)
    r = H.ropa(manga="larga", camisa_suelta=False, abrigo_largo=0.08, cuello_alto=True, pantalon_ancho=1.1,
               arrugas=0.03, vuelo_abrigo=0.88)
    abrigo = (0.055, 0.06, 0.065)
    cfg = {"piel": (0.52, 0.5, 0.48), "cara": "piedra", "cara_op": {"barba": 0.0, "suciedad": 0.5},
           "camisa": abrigo, "pantalon": abrigo, "zapatos": (0.02, 0.02, 0.02), "manos": "piel",
           "tela_op": {"suciedad": 0.25, "manchas": 0.3},
           "decoraciones": [("botones", (0.4, 0.36, 0.25), 0.06, 0.6, 1.42),
                            ("placa", (0.6, 0.5, 0.25), 0.62, 1.35)]}
    m = mats(("Director_Gorra", (0.05, 0.055, 0.06), 211), ("Director_Visera", (0.015, 0.015, 0.015), 212,
             {"rugosidad": 0.4, "especular": 0.5}), ("Director_Insignia", (0.62, 0.52, 0.26), 213,
             {"metalico": 0.9, "rugosidad": 0.35}))

    def extras(malla, huesos, datos):
        PJ.gorra_de_plato(malla, datos, 1, 2, 3, escala=1.02)
    return construir("El_Director", e, r, cfg, extras, m, semilla=210)


# ================================================================== Poses ===

def pose_encorvado(arm, e):
    """Los Aislados: encorvados, cabeza caída, brazos colgando hacia delante."""
    H.apuntar(arm, "columna", (0, -0.25, 1.0))
    H.apuntar(arm, "pecho", (0, -0.55, 1.0))
    H.apuntar(arm, "cuello", (0.05, -0.9, 1.0))
    H.apuntar(arm, "cabeza", (0.25, -0.7, 0.6))
    for lado, s in (("L", 1), ("R", -1)):
        H.apuntar(arm, f"brazo.{lado}", (s * 0.12, -0.35, -1.0))
        H.apuntar(arm, f"antebrazo.{lado}", (s * 0.05, -0.3, -1.0))
        H.apuntar(arm, f"mano.{lado}", (s * 0.05, -0.2, -1.0))
        H.apuntar(arm, f"muslo.{lado}", (s * 0.04, -0.2, -1.0))
        H.apuntar(arm, f"pierna.{lado}", (s * 0.02, 0.2, -1.0))


def pose_sentencia(arm, e):
    H.apuntar(arm, "pecho", (0, -0.2, 1.0))
    H.apuntar(arm, "cabeza", (0, -0.25, 1.0))
    H.apuntar(arm, "brazo.L", (0.15, -0.05, -1.0))
    H.apuntar(arm, "antebrazo.L", (0.1, -0.2, -1.0))
    H.apuntar(arm, "brazo.R", (-0.25, 0.0, -1.0))
    H.apuntar(arm, "antebrazo.R", (-0.2, -0.1, -1.0))
    H.apuntar(arm, "mano.R", (-0.15, 0.15, -1.0))


PERSONAJES = {
    "policia_patrullero": (policia_patrullero, None),
    "policia_tactico": (policia_tactico, None),
    "guardia_penitenciario": (guardia, None),
    "interrogador": (interrogador, None),
    "verdugo": (verdugo, None),
    "alcaide": (alcaide, None),
    "preso_generico_a": (lambda: preso_generico("a"), None),
    "preso_generico_b": (lambda: preso_generico("b"), None),
    "preso_generico_c": (lambda: preso_generico("c"), None),
    "aislado_a": (lambda: aislado("a"), pose_encorvado),
    "aislado_b": (lambda: aislado("b"), pose_encorvado),
    "el_vigilante": (el_vigilante, None),
    "el_condenado": (el_condenado, None),
    "la_sentencia": (la_sentencia, pose_sentencia),
    "el_director": (el_director, None),
}


def generar(nombre):
    C.reiniciar()
    funcion, pose = PERSONAJES[nombre]
    col, arm, e = funcion()
    PJ.poner_de_pie(arm, e)
    if pose:
        pose(arm, e)
    bpy.context.view_layer.update()
    C.guardar_blend(C.RAIZ / "personajes" / f"{nombre}.blend")


if __name__ == "__main__":
    pedidos = C.argumentos() or ["todos"]
    if "todos" in pedidos:
        pedidos = list(PERSONAJES)
    for pedido in pedidos:
        print("== Personaje:", pedido)
        generar(pedido)
