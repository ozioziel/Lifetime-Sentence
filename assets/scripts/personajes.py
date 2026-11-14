"""Personajes de Lifetime Sentence (estilo PS1), basados en las láminas de Materiales/.

Uso (genera un .blend por personaje en assets/personajes/):
    blender --background --factory-startup --python assets/scripts/personajes.py -- elias_preso el_uniforme
    blender --background --factory-startup --python assets/scripts/personajes.py -- todos

Cada archivo contiene una colección con el nombre del personaje (esqueleto + malla),
lista para enlazarla desde las escenas (Archivo > Vincular).
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

PIEL_CLARA = (0.72, 0.55, 0.45)
PELO_CASTANO = (0.1, 0.07, 0.055)
PIEL_MEDIA = (0.72, 0.53, 0.41)
PELO_OSCURO = (0.075, 0.055, 0.045)


# ------------------------------------------------------------ Accesorios ---

def material_ruido(nombre, color, semilla, rugosidad=0.8, metalico=0.0, especular=0.3, tam=32,
                   contraste=0.35):
    """Material con una textura pequeña de ruido (para gorras, metales, cuero...)."""
    n = C.ruido(tam, tam, semilla, octavas=3, celdas=4)
    img = C.lienzo(tam, tam, color) * (1 - contraste / 2 + contraste * n[..., None])
    img += C.grano(tam, tam, semilla, 0.02)
    ruta = C.guardar_png(f"personajes/acc_{nombre.lower()}.png", C.posterizar(img, 32))
    return C.material(f"MAT_{nombre}", ruta, rugosidad=rugosidad, metalico=metalico,
                      especular=especular)


def gorra_de_plato(malla, datos, mat_copa, mat_visera, mat_placa, escala=1.0, inclinacion=0.06,
                   hueso="cabeza"):
    """Gorra de plato policial: copa, banda, visera y placa."""
    zc, k = datos["zc"], datos["k"] * escala
    pesos = {hueso: 1.0}
    lados = 12
    z_banda = zc + 0.165 * k
    anillos = [
        (z_banda, 0.088 * k, 0.098 * k),
        (z_banda + 0.045 * k, 0.092 * k, 0.102 * k),
        (z_banda + 0.075 * k, 0.118 * k, 0.13 * k),
        (z_banda + 0.088 * k, 0.12 * k, 0.132 * k),
        (z_banda + 0.096 * k, 0.0, 0.0),
    ]
    filas = []
    for i, (z, rx, ry) in enumerate(anillos):
        fila = []
        for j in range(lados):
            a = 2 * math.pi * j / lados
            y = -math.cos(a) * ry + 0.008 * k
            zz = z + (-y) * inclinacion * (i >= 2)      # la copa se inclina hacia delante
            fila.append(malla.vertice((math.sin(a) * rx, y, zz), pesos))
        filas.append(fila)
    for i in range(len(filas) - 1):
        for j in range(lados):
            j2 = (j + 1) % lados
            mat = 0 if i >= 1 else 0
            idx = [filas[i][j], filas[i][j2], filas[i + 1][j2], filas[i + 1][j]]
            a, b, c = (malla.vertices[t] for t in idx[:3])
            centro = Vector((0, 0.008 * k, malla.vertices[idx[0]].z))
            if (b - a).cross(c - a).dot(a - centro) < 0:
                idx = idx[::-1]
            malla.cara(idx, [(0.2, 0.2), (0.8, 0.2), (0.8, 0.8), (0.2, 0.8)], mat_copa)
    # Visera: media luna inclinada hacia abajo y adelante.
    z_v = z_banda + 0.004 * k
    puntos = []
    for j in range(7):
        a = math.pi * (-0.38 + 0.76 * j / 6)      # semicírculo delantero (y negativa)
        puntos.append(Vector((math.sin(a) * 0.092 * k, -math.cos(a) * 0.1 * k + 0.008 * k, z_v)))
    exterior = [p + Vector((0, -0.065 * k * math.sin(math.pi * j / 6) - 0.01 * k, -0.025 * k))
                for j, p in enumerate(puntos)]
    for j in range(6):
        for grosor in (0.0, -0.006 * k):
            idx = [malla.vertice(puntos[j] + Vector((0, 0, grosor)), pesos),
                   malla.vertice(puntos[j + 1] + Vector((0, 0, grosor)), pesos),
                   malla.vertice(exterior[j + 1] + Vector((0, 0, grosor)), pesos),
                   malla.vertice(exterior[j] + Vector((0, 0, grosor)), pesos)]
            if grosor == 0.0:
                idx = idx[::-1]
            malla.cara(idx, [(0, 0), (1, 0), (1, 1), (0, 1)], mat_visera)
    # Placa.
    y_frente = -0.104 * k
    malla.caja((-0.018 * k, y_frente - 0.006 * k, z_banda + 0.04 * k),
               (0.018 * k, y_frente + 0.004 * k, z_banda + 0.075 * k),
               material=mat_placa, pesos=pesos, escala_uv=4.0)


def llavero(malla, mano_inicio, mano_fin, mat_aro, mat_llave, cantidad=7, escala=1.0, semilla=4):
    """Aro grande de llaves antiguas colgando de la mano."""
    rnd = C.aleatorio(semilla)
    eje = (Vector(mano_fin) - Vector(mano_inicio)).normalized()
    centro = Vector(mano_fin) + eje * 0.05 * escala
    pesos = {"mano.R": 1.0}
    r = 0.06 * escala
    segmentos = 10
    for j in range(segmentos):
        a0 = 2 * math.pi * j / segmentos
        a1 = 2 * math.pi * (j + 1) / segmentos
        p0 = centro + Vector((0, math.cos(a0) * r, math.sin(a0) * r))
        p1 = centro + Vector((0, math.cos(a1) * r, math.sin(a1) * r))
        g = 0.005 * escala
        malla.caja((min(p0.x, p1.x) - g, min(p0.y, p1.y) - g, min(p0.z, p1.z) - g),
                   (max(p0.x, p1.x) + g, max(p0.y, p1.y) + g, max(p0.z, p1.z) + g),
                   material=mat_aro, pesos=pesos, escala_uv=10)
    for i in range(cantidad):
        a = math.pi * (1.15 + 0.7 * i / max(cantidad - 1, 1)) + rnd.uniform(-0.1, 0.1)
        base = centro + Vector((0, math.cos(a) * r, math.sin(a) * r))
        largo = rnd.uniform(0.07, 0.11) * escala
        ancho = 0.009 * escala
        x = rnd.uniform(-0.012, 0.012) * escala
        y = base.y + rnd.uniform(-0.01, 0.01)
        malla.caja((base.x + x - 0.002 * escala, y - ancho, base.z - largo),
                   (base.x + x + 0.002 * escala, y + ancho, base.z),
                   material=mat_llave, pesos=pesos, escala_uv=10)
        # Cabeza (ojo) de la llave y dientes.
        malla.caja((base.x + x - 0.003 * escala, y - 0.018 * escala, base.z - 0.012 * escala),
                   (base.x + x + 0.003 * escala, y + 0.018 * escala, base.z + 0.01 * escala),
                   material=mat_llave, pesos=pesos, escala_uv=10)
        malla.caja((base.x + x - 0.0025 * escala, y + ancho, base.z - largo),
                   (base.x + x + 0.0025 * escala, y + ancho + 0.014 * escala, base.z - largo + 0.025 * escala),
                   material=mat_llave, pesos=pesos, escala_uv=10)


def cinturon(malla, e, z, mat_cuero, mat_hebilla, radio_x, radio_y_f, radio_y_b):
    h = e["alto"]
    lados = 10
    anillos = []
    for dz in (-0.022 * h, 0.022 * h):
        fila = []
        for j in range(lados):
            a = 2 * math.pi * j / lados
            ry = radio_y_f if -math.cos(a) >= 0 else radio_y_b
            fila.append(malla.vertice((math.sin(a) * radio_x * 1.04, -math.cos(a) * ry * 1.04,
                                       z * h + dz), {"cadera": 1.0}))
        anillos.append(fila)
    for j in range(lados):
        j2 = (j + 1) % lados
        idx = [anillos[0][j], anillos[0][j2], anillos[1][j2], anillos[1][j]]
        a, b, c = (malla.vertices[t] for t in idx[:3])
        if (b - a).cross(c - a).dot(Vector((a.x, a.y, 0))) < 0:
            idx = idx[::-1]
        malla.cara(idx, [(0, 0), (1, 0), (1, 1), (0, 1)], mat_cuero)
    malla.caja((-0.03 * h, -radio_y_f * 1.06 - 0.008 * h, z * h - 0.025 * h),
               (0.03 * h, -radio_y_f * 1.06 + 0.004 * h, z * h + 0.025 * h),
               material=mat_hebilla, pesos={"cadera": 1.0}, escala_uv=8)


# -------------------------------------------------------------- Pintores ---

def pintor_preso(e, datos, semilla, naranja=(0.76, 0.33, 0.11), sangre=0.6, rostro=None,
                 piel_color=PIEL_CLARA, numero=True, desgarros=0.0):
    """Uniforme naranja de presidiario (Elías en el presente; base de Los Aislados)."""
    h = e["alto"]

    def pintar(region, U, F, P, s):
        alto, ancho = U.shape
        if region == "cabeza":
            if rostro:
                return rostro(U, F, P)
            return H.pintar_cara_detallada(U, F, P, piel_color, s, datos, color_pelo=PELO_CASTANO,
                                           barba=0.38, sangre=sangre * 0.3, suciedad=0.35)
        if region == "pelo":
            return H.pintar_pelo(alto, ancho, PELO_CASTANO, s + 1)
        if region in ("brazo", "mano"):
            img = C.muestra("piel_brazo", alto, ancho, piel_color, repeticiones=2.0, contraste=0.8)
            img = img * 0.6 + H.piel(alto, ancho, piel_color, s + 2) * 0.4
            sucio = C.suave(C.ruido(alto, ancho, s + 3, 3, celdas=3), 0.5, 0.8)
            img = C.mezclar(img, np.array(piel_color) * 0.6, sucio * 0.35)
            if region == "mano":
                img *= (0.92 + 0.08 * (F > 0.5))[..., None]
            if sangre:
                img = C.mezclar(img, (0.3, 0.04, 0.03), C.manchas(alto, ancho, s + 4, 2, H.PX, 3 * H.PX) * sangre * 0.7)
            return img
        if region == "pie":
            img = H.tela(alto, ancho, (0.11, 0.09, 0.075), s + 5, arrugas=0.05, suciedad=0.2)
            img[F < 0.12] *= 0.6
            return img
        tono = {"pelvis": 0.8, "pierna": 0.8}.get(region, 1.0)
        color = np.array(naranja) * tono
        if region in ("pelvis", "pierna"):
            color = color * np.array((1.0, 0.85, 0.85))       # pantalón más rojizo, como en la lámina
        # Base: la tela real de las referencias (sucia, con regueros), más la mugre propia.
        repes = {"torso": 3.0, "pierna": 2.5, "pelvis": 2.5}.get(region, 1.5)
        img = C.muestra("camisa_naranja", alto, ancho, color, repeticiones=repes * 0.6, contraste=0.75)
        img = img * 0.45 + H.tela(alto, ancho, color, s + 6, arrugas=0.25, suciedad=0.45,
                                  manchas_oscuras=1.0, color_mancha=(0.1, 0.05, 0.03)) * 0.55
        if P is not None:
            z = P[..., 2] / h
            du = U - 0.5
            if region == "torso":
                cuello_piel = (z > 1.49) | ((z > 1.44) & (np.abs(du) < 0.1))
                img[cuello_piel] = H.piel(alto, ancho, piel_color, s + 7)[cuello_piel]
                cuello_v = (z > 1.33) & (z <= 1.475) & (np.abs(du) < 0.005 + (z - 1.33) * 0.42)
                camiseta = H.tela(alto, ancho, (0.8, 0.78, 0.72), s + 8, arrugas=0.05, suciedad=0.45)
                img[cuello_v] = camiseta[cuello_v]
                borde_v = (z > 1.33) & (z <= 1.475) & (np.abs(np.abs(du) - (0.005 + (z - 1.33) * 0.42)) < 0.012)
                img[borde_v] *= 0.72
                # Costuras laterales y faldón con dobladillo.
                costura = (np.abs(U - 0.25) < 0.006) | (np.abs(U - 0.75) < 0.006)
                img[costura] *= 0.7
                img[z < 0.835] *= 0.78
                if numero:
                    parche = (np.abs(U - 0.6) < 0.04) & (np.abs(z - 1.30) < 0.022)
                    img[parche] = (0.78, 0.74, 0.62)
                    # «4827»: cuatro grupos de píxeles oscuros.
                    for i in range(4):
                        digito = parche & (np.abs(U - (0.573 + i * 0.018)) < 0.005) & (np.abs(z - 1.30) < 0.012)
                        img[digito] = (0.12, 0.1, 0.08)
                    bolsillo = (np.abs(U - 0.6) < 0.045) & (np.abs(z - 1.26) < 0.002)
                    img[bolsillo] *= 0.6
            if region == "manga":
                img[F > 0.8] *= 0.7
            if region == "pierna":
                rodilla = np.exp(-((z - 0.52) / 0.04) ** 2) * C.suave(np.abs(U - 0.5), 0.3, 0.0)
                img = C.mezclar(img, np.array(naranja) * 0.4, rodilla * 0.5)
                img[F > 0.93] *= 0.6
            if region == "pelvis":
                img[z > 1.0] *= 0.8
        if sangre:
            m = C.manchas(alto, ancho, s + 9, int(4 * sangre) + 1, 1.5 * H.PX, 5 * H.PX)
            img = C.mezclar(img, (0.28, 0.035, 0.025), m * sangre * 0.8)
        if desgarros:
            agujero = C.suave(C.ruido(alto, ancho, s + 10, 3, celdas=5), 0.72, 0.76) * desgarros
            img = C.mezclar(img, piel_color, agujero * 0.9)
        return img
    return pintar


def pintor_civil(e, datos, semilla):
    """Ropa civil de Elías en el pasado: chaqueta granate, camiseta blanca, pantalón oscuro."""
    h = e["alto"]
    granate = (0.36, 0.12, 0.10)

    def pintar(region, U, F, P, s):
        alto, ancho = U.shape
        if region == "cabeza":
            return H.pintar_cara_detallada(U, F, P, PIEL_CLARA, s, datos, color_pelo=PELO_CASTANO,
                                           barba=0.3, cicatriz=True, sangre=0.35, suciedad=0.25)
        if region == "pelo":
            return H.pintar_pelo(alto, ancho, PELO_CASTANO, s + 1)
        if region in ("brazo", "mano"):
            return H.piel(alto, ancho, PIEL_CLARA, s + 2)
        if region == "pie":
            img = H.tela(alto, ancho, (0.09, 0.075, 0.065), s + 3, arrugas=0.05, suciedad=0.15)
            img[F < 0.12] *= 0.55
            return img
        if region in ("pelvis", "pierna"):
            img = H.tela(alto, ancho, (0.19, 0.19, 0.2), s + 4, arrugas=0.2, suciedad=0.3)
            if region == "pierna":
                img[F > 0.93] *= 0.7
            return img
        img = H.tela(alto, ancho, granate, s + 5, arrugas=0.3, suciedad=0.3)
        if P is not None and region == "torso":
            z = P[..., 2] / h
            du = U - 0.5
            img[z > 1.475] = H.piel(alto, ancho, PIEL_CLARA, s + 6)[z > 1.475]
            abierta = (np.abs(du) < 0.075 - (z - 1.0) * 0.06) & (z > 0.86) & (z <= 1.475)
            camiseta = H.tela(alto, ancho, (0.82, 0.8, 0.76), s + 7, arrugas=0.08, suciedad=0.3)
            img[abierta] = camiseta[abierta]
            solapa = (np.abs(np.abs(du) - (0.075 - (z - 1.0) * 0.06)) < 0.014) & (z > 0.86) & (z < 1.47)
            img[solapa] *= 0.6
            img[z < 0.875] *= 0.75
            sangre = C.manchas(alto, ancho, s + 8, 3, 1.5 * H.PX, 4 * H.PX)
            img = C.mezclar(img, (0.25, 0.03, 0.02), sangre * 0.6)
        if region == "manga":
            img[F > 0.85] *= 0.65
        if region == "cuello_ropa":
            img *= 0.85
        return img
    return pintar


def pintor_uniforme(e, datos, semilla):
    """El Uniforme: uniforme azul marino del policía, sin rostro."""
    h = e["alto"]
    azul = (0.105, 0.125, 0.175)

    def pintar(region, U, F, P, s):
        alto, ancho = U.shape
        if region == "cabeza":
            return H.pintar_cara(U, F, P, (0.5, 0.48, 0.46), s, datos, sin_rostro=True)
        if region == "pelo":
            return C.lienzo(alto, ancho, (0.02, 0.02, 0.025))
        if region in ("brazo", "mano"):
            img = H.piel(alto, ancho, (0.36, 0.35, 0.35), s + 2)
            img = C.mezclar(img, (0.16, 0.15, 0.16), C.suave(C.ruido(alto, ancho, s + 3, 3), 0.45, 0.8) * 0.6)
            return img
        if region == "pie":
            img = H.tela(alto, ancho, (0.035, 0.035, 0.04), s + 4, arrugas=0.05, suciedad=0.1)
            return img
        img = H.tela(alto, ancho, azul, s + 5, arrugas=0.32, suciedad=0.3, manchas_oscuras=0.6,
                     color_mancha=(0.05, 0.05, 0.06))
        if P is not None and region == "torso":
            z = P[..., 2] / h
            du = U - 0.5
            # Botonadura doble, placa en el pecho izquierdo, cuello oscuro.
            botones = (np.abs(np.abs(du) - 0.05) < 0.007) & (np.abs(((z - 0.95) % 0.09) - 0.045) < 0.008) & (z > 0.9) & (z < 1.38)
            img[botones] = (0.55, 0.45, 0.2)
            placa = (np.abs(U - 0.6) < 0.022) & (np.abs(z - 1.30) < 0.022)
            img[placa] = (0.68, 0.56, 0.24)
            img[placa & (np.abs(U - 0.6) < 0.008) & (np.abs(z - 1.30) < 0.008)] = (0.3, 0.24, 0.1)
            abertura = (np.abs(du) < 0.004) & (z < 0.95)
            img[abertura] *= 0.4
            img[z > 1.46] *= 0.6
            img[z < 0.5] *= 0.8
        if region == "manga":
            img[F > 0.86] *= 0.6
        return img
    return pintar


# ------------------------------------------------------------ Personajes ---

def poner_de_pie(arm, e, abrir_brazos=0.13, adelante=0.06, codo=0.18):
    """Pose neutra: brazos caídos junto al cuerpo, codos algo doblados."""
    for lado, s in (("L", 1), ("R", -1)):
        H.apuntar(arm, f"brazo.{lado}", (s * abrir_brazos, -adelante, -1.0))
        H.apuntar(arm, f"antebrazo.{lado}", (s * abrir_brazos * 0.5, -adelante - codo, -1.0))
        H.apuntar(arm, f"mano.{lado}", (s * abrir_brazos * 0.4, -adelante - codo * 0.8, -1.0))


def elias(variante="preso"):
    # Complexión de las láminas: hombros anchos, brazos y cuello fuertes, cabeza algo grande.
    e = H.proporciones(hombro_x=0.205, grosor=1.04, grosor_brazos=1.22, grosor_piernas=1.15,
                       cabeza=1.08, cuello=1.08)
    if variante == "preso":
        r = H.ropa(manga="corta", camisa_suelta=True, z_faldon=0.78, vuelo_faldon=1.15,
                   pantalon_ancho=1.25, holgura=1.17, largo_manga=0.62, vuelo_manga=1.2,
                   arrugas=0.045)
    else:
        r = H.ropa(manga="larga", camisa_suelta=True, z_faldon=0.84, vuelo_faldon=1.1,
                   pantalon_ancho=1.05, cuello_alto=True, holgura=1.12, arrugas=0.04)
    piezas, huesos, datos = H.piezas_humano(e, r, semilla=11)
    piezas.append(H.pieza_pelo(datos, semilla=7, volumen=1.0))
    pintor = pintor_preso(e, datos, 11) if variante == "preso" else pintor_civil(e, datos, 12)
    atlas = H.pintar_atlas(piezas, pintor, semilla=21)
    nombre = "Elias_Preso" if variante == "preso" else "Elias_Civil"
    col = C.coleccion(nombre)
    uv_pelo = H.uv_de_region("pelo", 0.5, 0.5)
    uv_piel = H.uv_de_region("mano", 0.5, 0.3)

    def extras(malla):
        # Pelo PS1 de las referencias: casco facetado y voluminoso con mechones gruesos; el flequillo
        # cae hacia un lado y se queda sobre las cejas.
        H.pelo_mechones(malla, datos, semilla=9, cantidad=10, volumen=1.0, raya=1.0)
        H.orejas(malla, datos, uv_piel)
    arm, obj = H.construir_personaje(nombre, piezas, huesos, atlas, col, extras)
    return col, arm, e


def el_uniforme():
    e = H.proporciones(alto=1.36, brazos=1.36, manos=1.4, grosor=0.9, grosor_brazos=0.82,
                       grosor_piernas=0.88, cabeza=0.88, cuello=1.1)
    r = H.ropa(manga="larga", camisa_suelta=False, abrigo_largo=0.40, cuello_alto=True,
               pantalon_ancho=1.0, zapato=1.05, sin_rostro=True, material_cabeza=7)
    piezas, huesos, datos = H.piezas_humano(e, r, semilla=31)
    atlas = H.pintar_atlas(piezas, pintor_uniforme(e, datos, 31), semilla=31)
    col = C.coleccion("El_Uniforme")
    mat_copa = material_ruido("Uniforme_Gorra", (0.09, 0.105, 0.15), 41)
    mat_visera = material_ruido("Uniforme_Visera", (0.02, 0.02, 0.025), 42, rugosidad=0.55, especular=0.35)
    mat_placa = material_ruido("Uniforme_Placa", (0.7, 0.57, 0.25), 43, rugosidad=0.35, metalico=0.9)
    mat_aro = material_ruido("Llaves_Hierro", (0.25, 0.22, 0.2), 44, rugosidad=0.5, metalico=0.9)
    mat_llave = material_ruido("Llaves_Laton", (0.5, 0.4, 0.22), 45, rugosidad=0.45, metalico=0.9,
                               contraste=0.6)
    mat_cuero = material_ruido("Uniforme_Cinturon", (0.03, 0.028, 0.03), 46, rugosidad=0.5)
    # Rostro vacío: negro absoluto, sin brillos (absorbe la luz).
    mat_vacio = C.material("MAT_Vacio", color=(0.0, 0.0, 0.0), rugosidad=1.0, especular=0.0)

    def extras(malla):
        gorra_de_plato(malla, datos, 1, 2, 3, escala=1.05)
        llavero(malla, huesos["mano.R"][0], huesos["mano.R"][1], 4, 5, cantidad=8, escala=1.3)
        cinturon(malla, e, 1.0, 6, 3, 0.168 * e["grosor"] * e["alto"], 0.11 * e["grosor"] * e["alto"],
                 0.117 * e["grosor"] * e["alto"])
    arm, obj = H.construir_personaje(
        "El_Uniforme", piezas, huesos, atlas, col, extras,
        materiales_extra=(mat_copa, mat_visera, mat_placa, mat_aro, mat_llave, mat_cuero, mat_vacio))
    return col, arm, e


PERSONAJES = {
    "elias_preso": lambda: elias("preso"),
    "elias_civil": lambda: elias("civil"),
    "el_uniforme": el_uniforme,
}


def generar(nombre):
    C.reiniciar()
    col, arm, e = PERSONAJES[nombre]()
    poner_de_pie(arm, e)
    bpy.context.view_layer.update()
    C.guardar_blend(C.RAIZ / "personajes" / f"{nombre}.blend")


if __name__ == "__main__":
    pedidos = C.argumentos() or ["todos"]
    if "todos" in pedidos:
        pedidos = list(PERSONAJES)
    for pedido in pedidos:
        print("== Personaje:", pedido)
        generar(pedido)
