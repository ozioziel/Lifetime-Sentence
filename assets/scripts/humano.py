"""Constructor de personajes humanos low-poly (estilo PS1) para Blender.

Cada personaje se construye con «piezas»: tubos de pocos lados hechos con anillos
(torso, piernas, brazos, cabeza, pelo...), como se modelaba en la época. Cada pieza
tiene su zona en un atlas de textura de 256 x 256 píxeles que se pinta con numpy
según la posición 3D de cada píxel (así la ropa, la cara o las manchas caen en el
sitio correcto). Todas las piezas se unen en una malla con un esqueleto y pesos.

El resultado es un objeto normal de Blender: se puede editar, reposar y volver a
texturizar a mano.
"""
import math

import bpy
import numpy as np
from mathutils import Matrix, Vector

import comun as C

ATLAS = 512
PX = ATLAS // 512           # escala de los detalles medidos en píxeles (manchas, textos, bloques)
# Zonas del atlas en píxeles (x0, y0, x1, y1), con y hacia abajo.
REGIONES = {k: tuple(ATLAS // 256 * c for c in v) for k, v in {
    "cabeza": (0, 0, 128, 64),
    "pelo": (128, 0, 256, 64),
    "torso": (0, 64, 128, 160),
    "pelvis": (128, 64, 256, 96),
    "manga": (128, 96, 192, 128),
    "brazo": (192, 96, 256, 160),
    "cuello_ropa": (128, 128, 192, 160),
    "pierna": (0, 160, 128, 224),
    "pie": (128, 160, 192, 192),
    "mano": (192, 160, 256, 192),
    "extra1": (128, 192, 256, 256),
    "extra2": (0, 224, 128, 256),
}.items()}
# Zonas pintadas a resolución completa; el resto se pinta a la mitad (píxel grueso, como la PS1).
# Dirección de arte (creador, 13-11-2026): estilo PS1 de Silent Hill 1, con polígonos visibles,
# texturas medio pixeladas y caras angulosas. Nada de suavizar: todas las zonas a media resolución.
REGIONES_DETALLE = set()

# Nivel de detalle de la malla. PS1 estricto: 1.0, 0 y SOMBREADO_SUAVE = False (lo que pide el creador).
DETALLE_LADOS = 1.0         # multiplica los lados (vértices por anillo) de cada pieza
DETALLE_ANILLOS = 0         # anillos intermedios (curva suave) entre cada par de anillos
SOMBREADO_SUAVE = False     # True = sombreado suave con aristas vivas por encima de ANGULO_ARISTA grados
INTERPOLACION = "Closest"   # filtrado de la textura de los personajes («Closest» = píxel duro de la PS1)
ANGULO_ARISTA = 48


# ------------------------------------------------------------------- Piezas ---

def anillo(c, rx, ryf, ryb=None, dz=None, perfil=None, forma=None):
    """Sección de una pieza. c: centro. rx: radio lateral. ryf/ryb: radio delante/detrás.

    dz(u): desplazamiento a lo largo del eje de la pieza. perfil(u): escala del radio.
    u = 0 es la espalda, 0.5 el frente, 0.25 y 0.75 los lados.
    forma: lista de vértices explícitos (lado, frente, dz) para u = k/n; sustituye a la elipse.
    Sirve para modelar «a mano» piezas angulosas (la cabeza estilo PS1).
    """
    return {"c": Vector(c), "rx": rx, "ryf": ryf, "ryb": ryf if ryb is None else ryb,
            "dz": dz, "perfil": perfil, "forma": forma}


def forma_simetrica(mitad):
    """Completa un anillo de vértices explícitos a partir de su mitad: de la espalda (k=0) al frente
    (último), y lo refleja al otro lado. Cada punto: (lado, frente, dz)."""
    otra = [(-x, y, dz) for x, y, dz in reversed(mitad[1:-1])]
    return list(mitad) + otra


def _catmull(p0, p1, p2, p3, t):
    t2, t3 = t * t, t * t * t
    return 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)


def _mezcla_funcion(fa, fb, t, neutro):
    if fa is None and fb is None:
        return None
    fa = fa or (lambda u: neutro)
    fb = fb or (lambda u: neutro)
    return lambda u: fa(u) * (1 - t) + fb(u) * t


def refinar(anillos, pasos):
    """Añade anillos intermedios siguiendo una curva (Catmull-Rom) para siluetas redondeadas.
    Los radios se limitan al rango de sus vecinos para no crear bultos."""
    if pasos <= 0 or len(anillos) < 2:
        return list(anillos)
    n = len(anillos)
    salida = []
    for i in range(n - 1):
        a, b = anillos[i], anillos[i + 1]
        p0, p3 = anillos[max(i - 1, 0)], anillos[min(i + 2, n - 1)]
        salida.append(a)
        for s in range(1, pasos + 1):
            t = s / (pasos + 1)
            nuevo = {"c": _catmull(p0["c"], a["c"], b["c"], p3["c"], t)}
            for clave in ("rx", "ryf", "ryb"):
                v = _catmull(p0[clave], a[clave], b[clave], p3[clave], t)
                bajo, alto = min(a[clave], b[clave]), max(a[clave], b[clave])
                nuevo[clave] = min(max(v, bajo * 0.98), alto * 1.02)
            nuevo["dz"] = _mezcla_funcion(a["dz"], b["dz"], t, 0.0)
            nuevo["perfil"] = _mezcla_funcion(a["perfil"], b["perfil"], t, 1.0)
            fa, fb = a.get("forma"), b.get("forma")
            nuevo["forma"] = ([tuple(pa[j] * (1 - t) + pb[j] * t for j in range(3)) for pa, pb in zip(fa, fb)]
                              if fa and fb and len(fa) == len(fb) else None)
            salida.append(nuevo)
    salida.append(anillos[-1])
    return salida


class Pieza:
    def __init__(self, nombre, anillos, lados, region, huesos, frente=(0, -1, 0),
                 tapa_inicio=False, tapa_fin=False, region_uv=None, material=0, arrugas=0.0,
                 detalle=True):
        """detalle=False conserva los lados y anillos tal cual (piezas facetadas a propósito o copias)."""
        if detalle:
            lados = max(lados, int(round(lados * DETALLE_LADOS / 2)) * 2)
            anillos = refinar(anillos, DETALLE_ANILLOS)
        self.nombre = nombre
        self.material = material
        self.arrugas = arrugas
        self.anillos = anillos
        self.lados = lados
        self.region = region
        self.region_uv = region_uv or REGIONES[region]
        self.huesos = huesos          # [(hueso, f0, f1), ...] a lo largo de la pieza
        self.frente = Vector(frente).normalized()
        self.tapa_inicio = tapa_inicio
        self.tapa_fin = tapa_fin

    # --- Geometría -------------------------------------------------------------
    def _ejes(self):
        n = len(self.anillos)
        ejes = []
        for i in range(n):
            a = self.anillos[max(i - 1, 0)]["c"]
            b = self.anillos[min(i + 1, n - 1)]["c"]
            t = (b - a)
            t = t.normalized() if t.length > 1e-6 else Vector((0, 0, 1))
            frente = self.frente - t * self.frente.dot(t)
            if frente.length < 1e-4:
                frente = Vector((0, 0, 1)) - t * t.z
            frente.normalize()
            lado = frente.cross(t).normalized()
            ejes.append((t, lado, frente))
        return ejes

    def fracciones(self):
        longitudes = [0.0]
        for i in range(1, len(self.anillos)):
            longitudes.append(longitudes[-1] + (self.anillos[i]["c"] - self.anillos[i - 1]["c"]).length)
        total = longitudes[-1] or 1.0
        return [l / total for l in longitudes]

    def punto(self, i, u, ejes=None):
        ejes = ejes or self._ejes()
        r = self.anillos[i]
        t, lado, frente = ejes[i]
        forma = r.get("forma")
        if forma:
            # Vértices explícitos; entre dos de ellos, interpolación lineal (para pintar la textura).
            m = len(forma)
            pos = (u % 1.0) * m
            i0 = int(math.floor(pos)) % m
            i1 = (i0 + 1) % m
            s = pos - math.floor(pos)
            x, y, d = (forma[i0][j] * (1 - s) + forma[i1][j] * s for j in range(3))
            p = r["c"] + lado * x + frente * y + t * d
            if r["dz"]:
                p += t * r["dz"](u)
            return p
        ang = 2 * math.pi * u
        escala = r["perfil"](u) if r["perfil"] else 1.0
        ry = r["ryf"] if -math.cos(ang) >= 0 else r["ryb"]
        p = r["c"] + lado * (r["rx"] * math.sin(ang) * escala) + frente * (ry * -math.cos(ang) * escala)
        if r["dz"]:
            p += t * r["dz"](u)
        return p

    def pesos(self, f):
        """Pesos de los huesos para la fracción f (0..1) de la pieza, con mezcla en las uniones."""
        if len(self.huesos) == 1:
            return {self.huesos[0][0]: 1.0}
        mezcla = 0.12
        pesos = {}
        for hueso, f0, f1 in self.huesos:
            a = 1.0 if f0 <= 0.0 else np.clip((f - (f0 - mezcla / 2)) / mezcla, 0, 1)
            b = 1.0 if f1 >= 1.0 else np.clip(((f1 + mezcla / 2) - f) / mezcla, 0, 1)
            w = float(a * b)
            if w > 0:
                pesos[hueso] = pesos.get(hueso, 0.0) + w
        total = sum(pesos.values()) or 1.0
        return {h: w / total for h, w in pesos.items()}

    def uv(self, u, f):
        x0, y0, x1, y1 = self.region_uv
        margen = 0.5
        uu = (x0 + margen + u * (x1 - x0 - 2 * margen)) / ATLAS
        vv = 1.0 - (y1 - margen - f * (y1 - y0 - 2 * margen)) / ATLAS
        return (uu, vv)

    def construir(self, malla):
        ejes = self._ejes()
        fr = self.fracciones()
        n = self.lados
        filas = []
        rnd = C.aleatorio(sum(ord(ch) for ch in self.nombre) * 31 + n)
        for i, r in enumerate(self.anillos):
            pesos = self.pesos(fr[i])
            fila = []
            for k in range(n):
                p = self.punto(i, k / n, ejes)
                if self.arrugas and 0 < i < len(self.anillos) - 1:
                    # Tela arrugada: cada vértice se separa o se acerca un poco al eje (facetas PS1).
                    p = r["c"] + (p - r["c"]) * (1.0 + rnd.uniform(-1.0, 1.0) * self.arrugas)
                fila.append(malla.vertice(p, pesos))
            filas.append(fila)
        caras = []
        for i in range(len(filas) - 1):
            for k in range(n):
                k2 = (k + 1) % n
                indices = [filas[i][k], filas[i][k2], filas[i + 1][k2], filas[i + 1][k]]
                uvs = [self.uv(k / n, fr[i]), self.uv((k + 1) / n, fr[i]),
                       self.uv((k + 1) / n, fr[i + 1]), self.uv(k / n, fr[i + 1])]
                caras.append((indices, uvs))
        # Orientación: la normal debe apuntar hacia fuera del eje de la pieza.
        if caras:
            indices, _ = caras[0]
            a, b, c = (malla.vertices[j] for j in indices[:3])
            normal = (b - a).cross(c - a)
            centro = sum((malla.vertices[j] for j in indices), Vector()) / 4
            eje = (self.anillos[0]["c"] + self.anillos[1]["c"]) / 2
            invertir = normal.dot(centro - eje) < 0
        else:
            invertir = False
        for indices, uvs in caras:
            if invertir:
                indices, uvs = indices[::-1], uvs[::-1]
            malla.cara(indices, uvs, self.material)
        # Tapas.
        for extremo, activa in ((0, self.tapa_inicio), (len(filas) - 1, self.tapa_fin)):
            if not activa:
                continue
            t = ejes[extremo][0]
            sentido = -1.0 if extremo == 0 else 1.0
            r = self.anillos[extremo]
            radio = min(r["rx"], r["ryf"], r["ryb"])
            fila = filas[extremo]
            if r.get("forma"):
                # Anillo explícito: la tapa nace del centro de sus vértices (sin pico).
                centro = sum((malla.vertices[j] for j in fila), Vector()) / len(fila) + t * sentido * radio * 0.1
            else:
                centro = r["c"] + t * sentido * radio * 0.35
            ic = malla.vertice(centro, self.pesos(fr[extremo]))
            for k in range(n):
                k2 = (k + 1) % n
                tri = [ic, fila[k], fila[k2]]
                a, b, c = (malla.vertices[j] for j in tri)
                normal = (b - a).cross(c - a)
                uvs = [self.uv((k + 0.5) / n, fr[extremo]), self.uv(k / n, fr[extremo]),
                       self.uv((k + 1) / n, fr[extremo])]
                if normal.dot(t * sentido) < 0:
                    tri, uvs = tri[::-1], uvs[::-1]
                malla.cara(tri, uvs, self.material)

    # --- Posición 3D de cada píxel de su zona del atlas (para pintar) ------------
    def posiciones(self, alto, ancho):
        ejes = self._ejes()
        fr = np.array(self.fracciones())
        U = (np.arange(ancho) + 0.5) / ancho
        F = 1.0 - (np.arange(alto) + 0.5) / alto
        # Posición de cada columna u en cada anillo; luego se interpola por filas (vectorizado).
        R = np.array([[tuple(self.punto(i, u, ejes)) for u in U] for i in range(len(self.anillos))])
        i = np.clip(np.searchsorted(fr, F) - 1, 0, len(fr) - 2)
        t = ((F - fr[i]) / np.maximum(fr[i + 1] - fr[i], 1e-6))[:, None, None]
        P = R[i] * (1 - t) + R[i + 1] * t
        UU, FF = np.meshgrid(U, F)
        return UU, FF, P


def espejo(pieza, nombre=None):
    """Copia una pieza del lado izquierdo (.L, +X) al derecho (.R, -X)."""
    anillos = []
    for r in pieza.anillos:
        c = Vector((-r["c"].x, r["c"].y, r["c"].z))
        anillos.append({**r, "c": c})
    huesos = [(h.replace(".L", ".R"), f0, f1) for h, f0, f1 in pieza.huesos]
    return Pieza(nombre or pieza.nombre.replace(".L", ".R"), anillos, pieza.lados, pieza.region,
                 huesos, (-pieza.frente.x, pieza.frente.y, pieza.frente.z),
                 pieza.tapa_inicio, pieza.tapa_fin, pieza.region_uv, pieza.material, pieza.arrugas,
                 detalle=False)


# --------------------------------------------------------------- Esqueleto ---

def esqueleto_humano(e):
    """Huesos (cabeza, cola, padre) a partir de las proporciones e (ver proporciones())."""
    h = e["alto"]
    hb = e["hombro_x"]
    z_hombro = e["z_hombro"] * h
    # Brazos en «A»: hacia abajo y afuera, 55 grados bajo la horizontal.
    dir_brazo = Vector((math.cos(math.radians(55)), 0.0, -math.sin(math.radians(55))))
    hombro = Vector((hb, 0.0, z_hombro))
    codo = hombro + dir_brazo * (0.29 * h * e["brazos"])
    dir_antebrazo = (dir_brazo + Vector((0, -0.08, 0))).normalized()
    muneca = codo + dir_antebrazo * (0.26 * h * e["brazos"])
    fin_mano = muneca + dir_antebrazo * (0.18 * h * e["manos"])
    cadera_x = e["cadera_x"]
    huesos = {
        "cadera": ((0, 0, 0.92 * h), (0, 0, 1.02 * h), None),
        "columna": ((0, 0, 1.02 * h), (0, 0, 1.22 * h), "cadera"),
        "pecho": ((0, 0, 1.22 * h), (0, 0, (e["z_hombro"] + 0.02) * h), "columna"),
        "cuello": ((0, 0, (e["z_hombro"] + 0.03) * h), (0, 0, (e["z_hombro"] + 0.13) * h), "pecho"),
        "cabeza": ((0, 0, (e["z_hombro"] + 0.13) * h), (0, 0, (e["z_hombro"] + 0.37) * h), "cuello"),
        "clavicula.L": ((0.02 * h, 0, (e["z_hombro"] - 0.01) * h), tuple(hombro - Vector((0.02, 0, 0))), "pecho"),
        "brazo.L": (tuple(hombro), tuple(codo), "clavicula.L"),
        "antebrazo.L": (tuple(codo), tuple(muneca), "brazo.L"),
        "mano.L": (tuple(muneca), tuple(fin_mano), "antebrazo.L"),
        "muslo.L": ((cadera_x, 0, 0.93 * h), (cadera_x + 0.005, 0, 0.50 * h), "cadera"),
        "pierna.L": ((cadera_x + 0.005, 0, 0.50 * h), (cadera_x + 0.008, 0.02 * h, 0.085 * h), "muslo.L"),
        "pie.L": ((cadera_x + 0.008, 0.02 * h, 0.085 * h), (cadera_x + 0.01, -0.13 * h, 0.02 * h), "pierna.L"),
    }
    for nombre in list(huesos):
        if nombre.endswith(".L"):
            cab, cola, padre = huesos[nombre]
            espejo_v = lambda v: (-v[0], v[1], v[2])  # noqa: E731
            huesos[nombre.replace(".L", ".R")] = (
                espejo_v(cab), espejo_v(cola), padre.replace(".L", ".R") if padre.endswith(".L") else padre)
    return huesos


def crear_esqueleto(nombre, huesos, coleccion_destino):
    datos = bpy.data.armatures.new(nombre)
    datos.display_type = "STICK"
    arm = bpy.data.objects.new(nombre, datos)
    arm.show_in_front = True
    coleccion_destino.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    arm.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    for nombre_h, (cab, cola, _) in huesos.items():
        hueso = datos.edit_bones.new(nombre_h)
        hueso.head = cab
        hueso.tail = cola
    for nombre_h, (_, _, padre) in huesos.items():
        if padre:
            datos.edit_bones[nombre_h].parent = datos.edit_bones[padre]
    bpy.ops.object.mode_set(mode="OBJECT")
    return arm


def apuntar(arm, hueso, direccion, giro=0.0):
    """Pone un hueso (en pose) apuntando en una dirección del mundo. Girar = radianes sobre su eje."""
    bpy.context.view_layer.update()
    pb = arm.pose.bones[hueso]
    m = arm.matrix_world.inverted() @ (arm.matrix_world @ pb.matrix)
    actual = (m.to_3x3() @ Vector((0, 1, 0))).normalized()
    destino = (arm.matrix_world.to_3x3().inverted() @ Vector(direccion)).normalized()
    rot = actual.rotation_difference(destino).to_matrix()
    nueva = (rot @ m.to_3x3())
    if giro:
        nueva = Matrix.Rotation(giro, 3, destino) @ nueva
    nueva = nueva.to_4x4()
    nueva.translation = m.translation
    pb.matrix = nueva
    bpy.context.view_layer.update()


# ------------------------------------------------------------- Proporciones ---

def proporciones(**cambios):
    """Proporciones de un hombre adulto de 1,76 m. Se pueden cambiar con argumentos."""
    e = {
        "alto": 1.0,            # factor de altura (1 = 1,76 m)
        "hombro_x": 0.19,
        "z_hombro": 1.43,
        "cadera_x": 0.095,
        "brazos": 1.0,          # largo de brazos
        "manos": 1.0,
        "grosor": 1.0,          # multiplica los radios del cuerpo
        "grosor_brazos": 1.0,
        "grosor_piernas": 1.0,
        "pecho": 1.0,
        "barriga": 1.0,
        "cabeza": 1.0,          # tamaño de la cabeza
        "cuello": 1.0,
    }
    e.update(cambios)
    return e


# -------------------------------------------------------------- Ropa y forma ---

def ropa(**cambios):
    """Opciones de forma de la ropa."""
    r = {
        "camisa_suelta": True,    # faldón de la camisa por fuera del pantalón
        "z_faldon": 0.80,         # altura del borde inferior de la camisa/chaqueta
        "vuelo_faldon": 1.06,     # cuánto se abre el borde inferior
        "manga": "corta",         # "corta", "larga" o "ninguna"
        "largo_manga": 0.55,      # fracción del brazo que cubre la manga corta
        "pantalon_ancho": 1.15,   # anchura del pantalón en el tobillo
        "abrigo_largo": None,     # altura del bajo de un abrigo (p. ej. 0.45) o None
        "cuello_alto": False,
        "zapato": 1.0,            # tamaño del zapato
        "holgura": 1.0,           # ropa del torso más ancha (camisa suelta de presidiario)
        "sin_rostro": False,      # cabeza lisa, sin nariz ni barbilla (El Uniforme)
        "material_cabeza": 0,     # índice de material de la cabeza
        "arrugas": 0.035,         # irregularidad de la tela (facetas)
        "vuelo_manga": 1.0,       # cuánto se abre el final de la manga corta
        "vuelo_abrigo": 1.0,      # cuánto se abre el bajo de un abrigo largo
    }
    r.update(cambios)
    return r


def piezas_humano(e, r, semilla=1):
    """Lista de piezas (cuerpo, cabeza y pelo) y huesos de un humano."""
    h = e["alto"]
    g = e["grosor"]
    huesos = esqueleto_humano(e)
    piezas = []
    zh = e["z_hombro"]

    # --- Torso (camisa / chaqueta) ---------------------------------------------
    pe, ba = e["pecho"], e["barriga"]
    g = g * r["holgura"]
    anillos_torso = []
    if r["abrigo_largo"]:
        zb = r["abrigo_largo"]
        va = r["vuelo_abrigo"]
        anillos_torso += [
            anillo((0, 0.0, zb * h), 0.23 * va * g * h, 0.17 * va * g * h, 0.17 * va * g * h),
            anillo((0, 0.0, (zb + 0.20) * h), 0.21 * va * g * h, 0.14 * va * g * h, 0.15 * va * g * h),
            anillo((0, 0.0, 0.80 * h), 0.19 * g * h, 0.125 * g * h, 0.13 * g * h),
        ]
    elif r["camisa_suelta"]:
        zf = r["z_faldon"]
        v = r["vuelo_faldon"]
        anillos_torso += [
            anillo((0, 0.0, (zf + 0.012) * h), 0.15 * g * h, 0.10 * g * h, 0.105 * g * h),
            anillo((0, 0.0, zf * h), 0.17 * v * g * h, 0.115 * v * g * h, 0.12 * v * g * h),
        ]
    else:
        anillos_torso += [anillo((0, 0.0, 0.90 * h), 0.155 * g * h, 0.10 * g * h, 0.108 * g * h)]
    anillos_torso += [
        anillo((0, 0.0, 0.88 * h), 0.168 * g * h, 0.11 * g * h, 0.117 * g * h),
        anillo((0, 0.0, 0.97 * h), 0.165 * g * h, 0.105 * g * h, 0.112 * g * h),
        anillo((0, -0.005 * h, 1.07 * h), 0.155 * g * h, 0.105 * ba * g * h, 0.10 * g * h),
        anillo((0, -0.008 * h, 1.19 * h), 0.165 * g * h, 0.118 * pe * g * h, 0.105 * g * h),
        anillo((0, -0.008 * h, 1.31 * h), 0.182 * g * h, 0.125 * pe * g * h, 0.11 * g * h),
        anillo((0, 0.0, (zh - 0.04) * h), 0.192 * g * h, 0.118 * g * h, 0.108 * g * h),
        anillo((0, 0.004 * h, (zh + 0.0) * h), 0.188 * g * h, 0.098 * g * h, 0.098 * g * h),
        anillo((0, 0.008 * h, (zh + 0.025) * h), 0.15 * g * h, 0.082 * g * h, 0.085 * g * h),
        anillo((0, 0.012 * h, (zh + 0.045) * h), 0.075 * h * e["cuello"], 0.062 * h, 0.066 * h),
        anillo((0, 0.012 * h, (zh + 0.12) * h), 0.06 * h * e["cuello"], 0.056 * h, 0.06 * h),
    ]
    g = g / r["holgura"]
    if r["camisa_suelta"] and not r["abrigo_largo"]:
        # El primer anillo (borde interior del faldón) va por dentro: lo dejamos al principio.
        pass
    fr_torso = [(a["c"].z / h) for a in anillos_torso]
    huesos_torso = [("cadera", 0.0, 0.25), ("columna", 0.25, 0.55), ("pecho", 0.55, 0.88),
                    ("cuello", 0.88, 1.0)]
    piezas.append(Pieza("torso", anillos_torso, 12, "torso", huesos_torso, arrugas=r["arrugas"]))

    # Cuello alto de abrigo (anillo de tela alrededor del cuello).
    if r["cuello_alto"]:
        piezas.append(Pieza("cuello_ropa", [
            anillo((0, 0.012 * h, (zh + 0.03) * h), 0.095 * h, 0.075 * h, 0.085 * h),
            anillo((0, 0.014 * h, (zh + 0.12) * h), 0.075 * h, 0.07 * h, 0.08 * h),
            anillo((0, 0.016 * h, (zh + 0.13) * h), 0.068 * h, 0.062 * h, 0.072 * h),
        ], 10, "cuello_ropa", [("cuello", 0, 1)]))

    # --- Pelvis (pantalón) --------------------------------------------------------
    piezas.append(Pieza("pelvis", [
        anillo((0, 0.0, 1.03 * h), 0.15 * g * h, 0.10 * g * h, 0.105 * g * h),
        anillo((0, 0.0, 0.93 * h), 0.16 * g * h, 0.105 * g * h, 0.118 * g * h),
        anillo((0, 0.0, 0.85 * h), 0.13 * g * h, 0.085 * g * h, 0.10 * g * h),
        anillo((0, 0.0, 0.80 * h), 0.07 * g * h, 0.05 * g * h, 0.06 * g * h),
    ], 10, "pelvis", [("cadera", 0, 1)], tapa_fin=True))

    # --- Piernas --------------------------------------------------------------------
    gp = e["grosor_piernas"] * g
    cx = e["cadera_x"]
    pa = r["pantalon_ancho"]
    anillos_pierna = [
        anillo((cx, 0.0, 0.96 * h), 0.085 * gp * h, 0.085 * gp * h, 0.09 * gp * h),
        anillo((cx + 0.002, 0.0, 0.84 * h), 0.084 * gp * h, 0.088 * gp * h, 0.092 * gp * h),
        anillo((cx + 0.003, 0.0, 0.70 * h), 0.073 * gp * h, 0.078 * gp * h, 0.08 * gp * h),
        anillo((cx + 0.005, -0.003 * h, 0.53 * h), 0.06 * gp * h, 0.066 * gp * h, 0.06 * gp * h),
        anillo((cx + 0.006, 0.0, 0.44 * h), 0.062 * gp * h, 0.06 * gp * h, 0.072 * gp * h),
        anillo((cx + 0.007, 0.008 * h, 0.28 * h), 0.055 * gp * h * (0.5 + pa / 2), 0.055 * gp * h, 0.06 * gp * h),
        anillo((cx + 0.008, 0.016 * h, 0.12 * h), 0.05 * pa * h, 0.052 * pa * h, 0.055 * pa * h),
        anillo((cx + 0.008, 0.018 * h, 0.075 * h), 0.053 * pa * h, 0.056 * pa * h, 0.058 * pa * h),
        anillo((cx + 0.008, 0.018 * h, 0.07 * h), 0.04 * h, 0.042 * h, 0.044 * h),
    ]
    pierna = Pieza("pierna.L", anillos_pierna, 10, "pierna",
                   [("muslo.L", 0.0, 0.47), ("pierna.L", 0.47, 1.0)], arrugas=r["arrugas"] * 0.8)
    piezas += [pierna, espejo(pierna)]

    # --- Pies (zapatos) ------------------------------------------------------------
    z = r["zapato"]
    anillos_pie = [
        anillo((cx + 0.008, 0.055 * h, 0.05 * h), 0.038 * z * h, 0.035 * h, 0.035 * h),
        anillo((cx + 0.008, 0.035 * h, 0.06 * h), 0.046 * z * h, 0.055 * h, 0.05 * h),
        anillo((cx + 0.009, -0.03 * h, 0.048 * h), 0.05 * z * h, 0.045 * h, 0.04 * h),
        anillo((cx + 0.01, -0.10 * z * h, 0.035 * h), 0.047 * z * h, 0.032 * h, 0.03 * h),
        anillo((cx + 0.01, -0.145 * z * h, 0.025 * h), 0.035 * z * h, 0.022 * h, 0.022 * h),
    ]
    pie = Pieza("pie.L", anillos_pie, 8, "pie", [("pie.L", 0, 1)], frente=(0, 0, 1),
                tapa_inicio=True, tapa_fin=True)
    piezas += [pie, espejo(pie)]

    # --- Brazos ----------------------------------------------------------------------
    hombro = Vector(huesos["brazo.L"][0])
    codo = Vector(huesos["brazo.L"][1])
    muneca = Vector(huesos["antebrazo.L"][1])
    gb = e["grosor_brazos"] * g
    inicio = hombro + Vector((-0.032 * h, 0, -0.03 * h))

    def en(a, b, t):
        return a.lerp(b, t)
    anillos_brazo = [
        anillo(inicio, 0.04 * gb * h, 0.048 * gb * h),
        anillo(en(hombro, codo, 0.12), 0.058 * gb * h, 0.062 * gb * h),
        anillo(en(hombro, codo, 0.5), 0.048 * gb * h, 0.052 * gb * h),
        anillo(en(hombro, codo, 0.95), 0.04 * gb * h, 0.042 * gb * h),
        anillo(en(codo, muneca, 0.25), 0.043 * gb * h, 0.042 * gb * h),
        anillo(en(codo, muneca, 0.7), 0.035 * gb * h, 0.032 * gb * h),
        anillo(muneca, 0.03 * gb * h, 0.025 * gb * h),
    ]
    fr_codo = 0.52
    brazo = Pieza("brazo.L", anillos_brazo, 8, "brazo",
                  [("brazo.L", 0.0, fr_codo), ("antebrazo.L", fr_codo, 1.0)], frente=(0, -1, 0))
    piezas += [brazo, espejo(brazo)]

    # Manga: corta (camisa de presidiario) o larga (chaqueta, uniforme).
    if r["manga"] != "ninguna":
        if r["manga"] == "corta":
            # Manga holgada pero ceñida al brazo (unos 2 cm de aire): sin efecto «globo».
            lm = r["largo_manga"]
            hs = 1.0 + (r["holgura"] - 1.0) * 0.5
            vm = 1.0 + (r["vuelo_manga"] - 1.0) * 0.5
            anillos_manga = [
                anillo(inicio + Vector((0.012 * h, 0, 0.0)), 0.05 * gb * h, 0.06 * gb * h),
                anillo(en(hombro, codo, 0.15), 0.064 * gb * hs * h, 0.068 * gb * hs * h),
                anillo(en(hombro, codo, lm), 0.058 * gb * hs * vm * h, 0.061 * gb * hs * vm * h),
                anillo(en(hombro, codo, lm - 0.025), 0.05 * gb * h, 0.052 * gb * h),
            ]
            huesos_manga = [("brazo.L", 0, 1)]
        else:
            anillos_manga = [
                anillo(inicio + Vector((0.012 * h, 0, 0.0)), 0.046 * gb * h, 0.058 * gb * h),
                anillo(en(hombro, codo, 0.15), 0.068 * gb * h, 0.07 * gb * h),
                anillo(en(hombro, codo, 0.55), 0.058 * gb * h, 0.062 * gb * h),
                anillo(en(hombro, codo, 0.98), 0.052 * gb * h, 0.054 * gb * h),
                anillo(en(codo, muneca, 0.35), 0.052 * gb * h, 0.05 * gb * h),
                anillo(en(codo, muneca, 0.9), 0.047 * gb * h, 0.045 * gb * h),
                anillo(en(codo, muneca, 0.86), 0.036 * gb * h, 0.033 * gb * h),
            ]
            huesos_manga = [("brazo.L", 0.0, 0.5), ("antebrazo.L", 0.5, 1.0)]
        manga = Pieza("manga.L", anillos_manga, 10, "manga", huesos_manga, arrugas=r["arrugas"] * 1.4)
        piezas += [manga, espejo(manga)]

    # --- Manos: palma, cuatro dedos y pulgar, con pocos polígonos -----------------------
    piezas += manos(muneca, Vector(huesos["mano.L"][1]), e["manos"] * h)

    # --- Cabeza: modelada vértice a vértice al estilo PS1 (ver CABEZA_PS1) -----------------------
    k = e["cabeza"] * h
    zc = (zh + 0.10) * h       # barbilla
    anillos_cabeza = cabeza_ps1(zc, k, e.get("mandibula", 1.0), r["sin_rostro"])
    piezas.append(Pieza("cabeza", anillos_cabeza, 12, "cabeza", [("cabeza", 0, 1)],
                        tapa_inicio=True, tapa_fin=True, material=r["material_cabeza"], detalle=False))
    datos_cabeza = {"zc": zc, "k": k, "anillos": anillos_cabeza}
    return piezas, huesos, datos_cabeza


# Cabeza low-poly al estilo PS1 (Silent Hill 1), modelada a mano: 12 vértices por anillo.
# Cada anillo: (altura desde la barbilla, [(lado, frente, dz) de la nuca (k=0) a la cara (k=6)]),
# en unidades de cabeza (k ~ 1 m). La otra mitad es simétrica. Claves del diseño:
#   - mandíbula marcada: baja en diagonal de la barbilla al ángulo bajo la oreja (anillos 0-1);
#   - nariz en cuña (frente, anillos 3-5) con la base plana en sombra;
#   - arco de las cejas saliente (anillo 6) sobre una cuenca hundida (anillo 5): los ojos quedan
#     en sombra y casi no se ven, como en las referencias.
CABEZA_PS1 = [
    (0.000, [(0, -0.052, 0.022), (0.032, -0.047, 0.022), (0.054, -0.024, 0.024), (0.06, 0.008, 0.022),
             (0.046, 0.04, 0.01), (0.022, 0.066, 0.002), (0, 0.074, 0.0)]),
    (0.032, [(0, -0.062, 0.006), (0.037, -0.056, 0.006), (0.06, -0.028, 0.006), (0.066, 0.008, 0.004),
             (0.051, 0.05, 0.0), (0.025, 0.08, 0.0), (0, 0.086, 0.0)]),
    (0.066, [(0, -0.072, 0), (0.042, -0.064, 0), (0.064, -0.034, 0), (0.069, 0.006, 0),
             (0.055, 0.053, 0), (0.026, 0.085, 0), (0, 0.093, 0)]),
    (0.095, [(0, -0.088, 0), (0.046, -0.078, 0), (0.069, -0.044, 0), (0.073, 0.004, 0),
             (0.058, 0.056, 0), (0.021, 0.084, 0), (0, 0.114, 0)]),
    (0.117, [(0, -0.095, 0), (0.049, -0.085, 0), (0.073, -0.05, 0), (0.077, 0.002, 0),
             (0.062, 0.059, 0), (0.023, 0.077, 0), (0, 0.103, 0)]),
    (0.134, [(0, -0.099, 0), (0.05, -0.089, 0), (0.075, -0.054, 0), (0.079, 0.0, 0),
             (0.061, 0.054, 0), (0.027, 0.069, 0), (0, 0.088, 0)]),
    (0.150, [(0, -0.101, 0), (0.051, -0.091, 0), (0.076, -0.056, 0), (0.08, 0.0, 0),
             (0.064, 0.061, 0), (0.031, 0.089, 0), (0, 0.093, 0)]),
    (0.180, [(0, -0.1, 0), (0.05, -0.09, 0), (0.075, -0.056, 0), (0.078, 0.0, 0),
             (0.062, 0.054, 0), (0.031, 0.08, 0), (0, 0.086, 0)]),
    (0.210, [(0, -0.088, 0), (0.042, -0.078, 0), (0.064, -0.047, 0), (0.067, 0.0, 0),
             (0.052, 0.044, 0), (0.026, 0.064, 0), (0, 0.068, 0)]),
    (0.232, [(0, -0.05, 0), (0.024, -0.044, 0), (0.036, -0.026, 0), (0.038, 0.0, 0),
             (0.03, 0.026, 0), (0.015, 0.036, 0), (0, 0.04, 0)]),
]

# Pelo: casco facetado y voluminoso (como en las referencias), con el borde bajo la nuca, sobre
# las orejas y en la frente. Mismo formato que CABEZA_PS1.
PELO_PS1 = [
    (0.150, [(0, -0.088, -0.085), (0.046, -0.08, -0.08), (0.082, -0.06, -0.045), (0.09, -0.004, -0.004),
             (0.078, 0.064, 0.003), (0.039, 0.098, 0.02), (0, 0.103, 0.017)]),
    (0.185, [(0, -0.117, -0.05), (0.058, -0.105, -0.045), (0.09, -0.066, -0.02), (0.096, -0.002, 0.0),
             (0.082, 0.064, 0.0), (0.044, 0.1, 0.0), (0, 0.106, 0.0)]),
    (0.215, [(0, -0.11, -0.01), (0.056, -0.098, -0.008), (0.086, -0.06, 0.0), (0.09, 0.0, 0.0),
             (0.076, 0.058, 0.0), (0.04, 0.09, 0.0), (0, 0.095, 0.0)]),
    (0.245, [(0, -0.075, 0), (0.04, -0.066, 0), (0.062, -0.04, 0), (0.066, 0.0, 0),
             (0.056, 0.04, 0), (0.03, 0.062, 0), (0, 0.066, 0)]),
    (0.262, [(0, -0.03, 0), (0.016, -0.026, 0), (0.026, -0.016, 0), (0.028, 0.0, 0),
             (0.024, 0.016, 0), (0.013, 0.026, 0), (0, 0.028, 0)]),
]


def _anillo_tabla(zc, k, z, mitad, escala_x=1.0, escala_y=1.0):
    forma = forma_simetrica([(x * k * escala_x, y * k * escala_y, dz * k) for x, y, dz in mitad])
    rx = max(abs(p[0]) for p in forma)
    ryf = max(p[1] for p in forma)
    ryb = max(-p[1] for p in forma)
    return anillo((0, 0, zc + z * k), rx, ryf, ryb, forma=forma)


def cabeza_ps1(zc, k, mandibula=1.0, sin_rostro=False):
    """Anillos de la cabeza PS1. mandibula ensancha o estrecha la mitad inferior de la cara.
    sin_rostro aplana nariz y cejas (cabezas lisas: El Uniforme, capuchas)."""
    anillos = []
    for z, mitad in CABEZA_PS1:
        puntos = []
        for j, (x, y, dz) in enumerate(mitad):
            if z <= 0.07:
                x *= mandibula
            if sin_rostro and 0.06 < z < 0.16 and j >= 5:
                y = 0.09 if j == 6 else 0.082
            puntos.append((x, y, dz))
        anillos.append(_anillo_tabla(zc, k, z, puntos))
    return anillos


def manos(muneca, fin_mano, s):
    """Mano izquierda (y su espejo): palma ancha y plana, cuatro dedos de 4 lados algo curvados hacia
    la palma y un pulgar que sale por delante. Todo pesa en el hueso de la mano. s = escala."""
    eje = (fin_mano - muneca).normalized()
    frente = Vector((0, -1, 0)) - eje * eje.dot(Vector((0, -1, 0)))
    frente.normalize()                                  # canto del pulgar (hacia delante)
    dorso = frente.cross(eje).normalized()              # la palma mira a -dorso (hacia el cuerpo)
    palma = Pieza("mano.L", [
        anillo(muneca - eje * 0.01 * s, 0.022 * s, 0.03 * s),
        anillo(muneca + eje * 0.03 * s, 0.024 * s, 0.043 * s),
        anillo(muneca + eje * 0.072 * s, 0.021 * s, 0.045 * s),
        anillo(muneca + eje * 0.09 * s, 0.016 * s, 0.04 * s),
    ], 8, "mano", [("mano.L", 0, 1)], frente=(0, -1, 0), tapa_fin=True)
    piezas = [palma]
    base = muneca + eje * 0.083 * s
    # (posición a lo ancho de la mano, largo, grosor): índice, corazón, anular y meñique.
    for i, (ancho, largo, grosor) in enumerate(((0.029, 0.066, 0.0105), (0.01, 0.074, 0.011),
                                                (-0.01, 0.068, 0.0105), (-0.028, 0.054, 0.009))):
        p0 = base + frente * ancho * s - dorso * 0.002 * s
        d1 = (eje + frente * ancho * 0.6).normalized()
        d2 = (eje - dorso * 0.45 + frente * ancho * 0.6).normalized()
        p1 = p0 + d1 * largo * 0.55 * s
        p2 = p1 + d2 * largo * 0.45 * s
        r = grosor * s
        piezas.append(Pieza(f"dedo{i}.L", [anillo(p0, r, r), anillo(p1, r * 0.95, r * 0.9),
                                            anillo(p2, r * 0.75, r * 0.7)],
                            4, "mano", [("mano.L", 0, 1)], frente=tuple(frente), tapa_fin=True))
    # Pulgar: nace en el canto delantero de la palma, cerca de la muñeca.
    p0 = muneca + eje * 0.034 * s + frente * 0.026 * s - dorso * 0.008 * s
    d1 = (eje * 0.8 + frente * 0.38 - dorso * 0.35).normalized()
    d2 = (eje * 0.92 + frente * 0.04 - dorso * 0.42).normalized()
    p1 = p0 + d1 * 0.03 * s
    p2 = p1 + d2 * 0.027 * s
    r = 0.0125 * s
    piezas.append(Pieza("pulgar.L", [anillo(p0, r, r * 1.1), anillo(p1, r * 0.95, r), anillo(p2, r * 0.75, r * 0.75)],
                        4, "mano", [("mano.L", 0, 1)], frente=tuple(frente), tapa_fin=True))
    return piezas + [espejo(p) for p in piezas]


def pieza_pelo(datos_cabeza, estilo="despeinado", semilla=3, volumen=1.0):
    """Casco de pelo facetado (PELO_PS1). volumen < 1 lo ciñe (personajes con gorra)."""
    zc, k = datos_cabeza["zc"], datos_cabeza["k"]
    anillos = [_anillo_tabla(zc, k, z, mitad, volumen, volumen) for z, mitad in PELO_PS1]
    return Pieza("pelo", anillos, 12, "pelo", [("cabeza", 0, 1)], tapa_fin=True, detalle=False)


def pelo_mechones(malla, datos_cabeza, semilla=5, cantidad=14, volumen=1.0, largo=1.0, raya=1.0):
    """Mechones gruesos en cuña (pocos polígonos, aristas marcadas) que rompen el borde del casco:
    flequillo peinado hacia un lado (raya: 1 o -1), mechones sobre las orejas y en la nuca."""
    zc, k = datos_cabeza["zc"], datos_cabeza["k"]
    rnd = C.aleatorio(semilla)
    centro = Vector((0, 0.004 * k, zc + 0.14 * k))
    radios = (0.096 * k * volumen, 0.108 * k * volumen, 0.118 * k * volumen, 0.125 * k)

    def superficie(theta, z, extra):
        # theta: 0 = frente; z: altura desde la barbilla (unidades de cabeza).
        s = max(-0.999, min(0.999, (z - 0.14) / 0.125))
        c = math.sqrt(1 - s * s)
        ry = radios[1] if math.cos(theta) > 0 else radios[2]
        d = Vector((math.sin(theta) * c, -math.cos(theta) * c, s))
        p = centro + Vector((d.x * radios[0], d.y * ry, d.z * radios[3]))
        n = Vector((d.x / radios[0], d.y / ry, d.z / radios[3])).normalized()
        return p + n * extra * k, n

    angulos = [(-math.pi + 2 * math.pi * (i + 0.5) / cantidad) for i in range(cantidad)]
    angulos += [rnd.uniform(-0.6, 0.6) for _ in range(max(2, cantidad // 4))]     # flequillo
    for theta in angulos:
        theta += rnd.uniform(-0.12, 0.12)
        frente = math.cos(theta)
        if frente > 0.6:          # flequillo: hasta encima de las cejas, peinado a un lado
            z1 = rnd.uniform(0.152, 0.168)
            barrido = raya * rnd.uniform(0.25, 0.5)
        elif frente > -0.35:      # sienes: hasta lo alto de la oreja
            z1 = rnd.uniform(0.135, 0.155)
            barrido = -math.copysign(rnd.uniform(0.05, 0.15), math.sin(theta))
        else:                     # nuca: el casco ya llega abajo; solo rompen el borde
            z1 = rnd.uniform(0.09, 0.115)
            barrido = rnd.uniform(-0.1, 0.1)
        z0 = rnd.uniform(0.2, 0.235)
        z1 = z0 - (z0 - z1) * largo
        ancho = rnd.uniform(0.04, 0.056) * volumen
        filas = []
        for j, tt in enumerate((0.0, 0.55, 1.0)):
            p, n = superficie(theta + barrido * tt, z0 + (z1 - z0) * tt, 0.004 + 0.005 * (1 - tt))
            p_sig, _ = superficie(theta + barrido * min(tt + 0.1, 1.0), z0 + (z1 - z0) * min(tt + 0.1, 1.0), 0.006)
            tangente = (p_sig - p).normalized() if (p_sig - p).length > 1e-6 else Vector((0, 0, -1))
            lado = tangente.cross(n).normalized()
            if j == 2:
                filas.append([p, p, p])
            else:
                w = ancho * k * (1 - 0.45 * tt)
                arista = p + n * 0.007 * k * (1 - 0.5 * tt)
                filas.append([p + lado * w, arista, p - lado * w])
        uv = uv_de_region("pelo", rnd.uniform(0.05, 0.95), rnd.uniform(0.3, 0.9))
        idx = [[malla.vertice(q, {"cabeza": 1.0}) for q in fila] for fila in filas]
        for j in range(2):
            for a, b in ((0, 1), (1, 2)):
                if j == 1:
                    caras = [idx[j][a], idx[j][b], idx[j + 1][a]]
                else:
                    caras = [idx[j][a], idx[j][b], idx[j + 1][b], idx[j + 1][a]]
                malla.cara(caras, [uv] * len(caras))


def mechones(malla, datos_cabeza, semilla=5, cantidad=9, color_uv=None):
    """Compatibilidad: mechones gruesos PS1."""
    pelo_mechones(malla, datos_cabeza, semilla=semilla, cantidad=cantidad)


def orejas(malla, datos_cabeza, uv_piel):
    """Orejas low-poly: hexágono despegado hacia atrás con la concha hundida (color de piel)."""
    zc, k = datos_cabeza["zc"], datos_cabeza["k"]
    n = 6
    pesos = {"cabeza": 1}
    for lado in (1, -1):
        base = Vector((lado * 0.074 * k, 0.012 * k, zc + 0.12 * k))
        anillos = []
        for despegue, escala in ((0.0, 0.85), (0.011, 1.0), (0.014, 0.7)):
            fila = []
            for j in range(n):
                a = 2 * math.pi * (j + 0.5) / n
                y = math.cos(a) * 0.016 * k * escala
                z = math.sin(a) * 0.026 * k * escala
                fila.append(malla.vertice(base + Vector((lado * (despegue + max(y, 0.0) * 0.35), y, z)), pesos))
            anillos.append(fila)
        concha = malla.vertice(base + Vector((lado * 0.008 * k, 0.003 * k, -0.002 * k)), pesos)
        for i in range(len(anillos) - 1):
            for j in range(n):
                j2 = (j + 1) % n
                cara = [anillos[i][j], anillos[i][j2], anillos[i + 1][j2], anillos[i + 1][j]]
                malla.cara(cara if lado > 0 else cara[::-1], [uv_piel] * 4)
        for j in range(n):
            tri = [anillos[-1][j], anillos[-1][(j + 1) % n], concha]
            malla.cara(tri if lado > 0 else tri[::-1], [uv_piel] * 3)


# ------------------------------------------------------------------ Pintura ---

def pintar_atlas(piezas, pintor, semilla=1):
    """Pinta el atlas 256 x 256. pintor(nombre_region, U, F, P, rnd) -> imagen alto x ancho x 3."""
    atlas = np.zeros((ATLAS, ATLAS, 3))
    atlas[:] = (0.5, 0.45, 0.4)
    hechas = set()
    for pieza in piezas:
        if pieza.region in hechas:
            continue
        hechas.add(pieza.region)
        x0, y0, x1, y1 = REGIONES[pieza.region]
        f = 1 if pieza.region in REGIONES_DETALLE else 2
        U, F, P = pieza.posiciones((y1 - y0) // f, (x1 - x0) // f)
        img = pintor(pieza.region, U, F, P, semilla)
        if f > 1:
            img = np.repeat(np.repeat(img, f, axis=0), f, axis=1)
        atlas[y0:y1, x0:x1] = img
    for region in ("extra1", "extra2"):
        if region not in hechas:
            x0, y0, x1, y1 = REGIONES[region]
            alto, ancho = (y1 - y0) // 2, (x1 - x0) // 2
            U, F = np.meshgrid((np.arange(ancho) + 0.5) / ancho, 1 - (np.arange(alto) + 0.5) / alto)
            img = pintor(region, U, F, None, semilla)
            atlas[y0:y1, x0:x1] = np.repeat(np.repeat(img, 2, axis=0), 2, axis=1)
    return atlas


def uv_de_region(region, u=0.5, f=0.5):
    """Coordenada UV de un punto (u, f) dentro de una zona del atlas."""
    x0, y0, x1, y1 = REGIONES[region]
    return ((x0 + u * (x1 - x0)) / ATLAS, 1.0 - (y1 - f * (y1 - y0)) / ATLAS)


def tela(alto, ancho, color, semilla, arrugas=0.18, suciedad=0.25, manchas_oscuras=0.0,
         color_mancha=(0.12, 0.08, 0.05)):
    """Tela con ruido, pliegues verticales y suciedad."""
    base = C.lienzo(alto, ancho, color)
    n = C.ruido(alto, ancho, semilla, octavas=4, celdas=4)
    pliegues = C.ruido(alto, ancho, semilla + 1, octavas=2, celdas=3)
    pliegues = np.abs(np.sin(np.linspace(0, 9 * np.pi, ancho)[None, :] + pliegues * 6))
    img = base * (0.82 + 0.3 * n[..., None]) * (1 - arrugas * (1 - pliegues[..., None]) * 0.6)
    sucio = C.suave(C.ruido(alto, ancho, semilla + 2, octavas=4, celdas=4), 0.5, 0.85)
    img = C.mezclar(img, np.array(color) * 0.42, sucio * suciedad)
    # Mugre que baja en regueros (más abajo, más sucio).
    regueros = C.chorreones(alto, ancho, semilla + 5, int(ancho * 0.25), 0.5)
    img = C.mezclar(img, np.array(color) * 0.5, regueros * suciedad * 0.6)
    if manchas_oscuras > 0:
        # Manchas irregulares (no círculos): umbral sobre ruido de detalle.
        n = C.ruido(alto, ancho, semilla + 3, octavas=5, celdas=5)
        m = C.suave(n, 0.74 - 0.06 * manchas_oscuras, 0.8 - 0.06 * manchas_oscuras)
        img = C.mezclar(img, color_mancha, m * 0.7)
    return img + C.grano(alto, ancho, semilla + 4, 0.022)


def piel(alto, ancho, color, semilla):
    n = C.ruido(alto, ancho, semilla, octavas=3, celdas=4)
    return C.lienzo(alto, ancho, color) * (0.9 + 0.18 * n[..., None]) + C.grano(alto, ancho, semilla, 0.012)


def pintar_cara(U, F, P, color_piel, semilla, datos, ojos=(0.66, 0.62, 0.57),
                iris=(0.12, 0.09, 0.07), cejas=(0.1, 0.07, 0.05), barba=0.25,
                cicatriz=False, sangre=0.0, sin_rostro=False, color_pelo=(0.06, 0.045, 0.04)):
    """Cara pintada sobre la zona de la cabeza (cilindro desplegado: u=0.5 es el frente)."""
    alto, ancho = U.shape
    img = piel(alto, ancho, color_piel, semilla)
    zc, k = datos["zc"], datos["k"]
    Z = (P[..., 2] - zc) / k            # 0 = barbilla, 0.23 = coronilla
    du = U - 0.5
    if sin_rostro:
        img = C.lienzo(alto, ancho, (0.012, 0.012, 0.016)) + C.grano(alto, ancho, semilla, 0.006)
        return img
    # Sombreado horneado: mandíbula y sienes algo más oscuras, pómulos más claros.
    sombra = 0.12 * C.suave(np.abs(du), 0.12, 0.3) + 0.1 * C.suave(0.06 - Z, -0.02, 0.06)
    img *= (1 - sombra)[..., None]
    img *= (1 + 0.07 * np.exp(-((np.abs(du) - 0.09) / 0.03) ** 2 - ((Z - 0.115) / 0.02) ** 2))[..., None]
    # Barba de varios días.
    if barba > 0:
        zona = C.suave(0.085 - Z, 0.0, 0.04) * C.suave(0.2 - np.abs(du), 0.0, 0.06)
        zona *= (1 - np.exp(-((du / 0.03) ** 2) - ((Z - 0.072) / 0.012) ** 2))   # deja el labio
        img = C.mezclar(img, np.array(color_piel) * 0.55, zona * barba)
    # Cejas.
    for lado in (-1, 1):
        ceja = (np.abs(du - lado * 0.066) < 0.032) & (np.abs(Z - 0.143 - (du * lado) * 0.08) < 0.007)
        img[ceja] = cejas
        ceno = np.exp(-((du - lado * 0.06) / 0.05) ** 2 - ((Z - 0.137) / 0.012) ** 2)
        img *= (1 - 0.22 * ceno)[..., None]
    # Cuencas y ojos.
    for lado in (-1, 1):
        cuenca = np.exp(-((du - lado * 0.066) / 0.03) ** 2 - ((Z - 0.128) / 0.012) ** 2)
        img *= (1 - 0.3 * cuenca)[..., None]
        ojo = (np.abs(du - lado * 0.066) < 0.015) & (np.abs(Z - 0.128) < 0.0045)
        img[ojo] = ojos
        pupila = (np.abs(du - lado * 0.06) < 0.0075) & (np.abs(Z - 0.128) < 0.0055)
        img[pupila] = iris
        parpado = (np.abs(du - lado * 0.066) < 0.02) & (np.abs(Z - 0.136) < 0.003)
        img[parpado] = np.array(color_piel) * 0.45
    # Nariz: sombras laterales y aletas.
    nariz_sombra = np.exp(-((np.abs(du) - 0.018) / 0.008) ** 2 - ((Z - 0.1) / 0.02) ** 2)
    img *= (1 - 0.25 * nariz_sombra)[..., None]
    base_nariz = (np.abs(du) < 0.02) & (np.abs(Z - 0.088) < 0.004)
    img[base_nariz] = np.array(color_piel) * 0.55
    # Boca.
    boca = (np.abs(du) < 0.03) & (np.abs(Z - 0.068) < 0.004)
    img[boca] = (0.32, 0.17, 0.14)
    labio = (np.abs(du) < 0.022) & (np.abs(Z - 0.061) < 0.003)
    img[labio] = np.array(color_piel) * 0.8
    # Herida en la mejilla (pasado).
    if cicatriz:
        corte = (np.abs(du + 0.075 - (Z - 0.1) * 0.6) < 0.006) & (np.abs(Z - 0.1) < 0.018)
        img[corte] = (0.45, 0.06, 0.05)
    if sangre > 0:
        m = C.manchas(alto, ancho, semilla + 7, int(5 * sangre) + 1, 1.5 * PX, 4 * PX)
        img = C.mezclar(img, (0.33, 0.04, 0.03), m * C.suave(0.25 - np.abs(du), 0, 0.1) * 0.8)
    # Pelo pintado en nuca y sienes (por si el pelo 3D deja huecos).
    pelo = (Z > 0.15) & (np.abs(du) > 0.13) | (Z > 0.19) | ((Z > 0.1) & (np.abs(du) > 0.28))
    img[pelo] = np.array(color_pelo) * (0.85 + 0.3 * C.ruido(alto, ancho, semilla + 11, 3, celdas=6))[pelo][..., None]
    return img


def coordenadas_cara(P, datos):
    """X (lado), Y (hacia delante) y Z (altura desde la barbilla) en unidades de cabeza."""
    zc, k = datos["zc"], datos["k"]
    return P[..., 0] / k, -P[..., 1] / k, (P[..., 2] - zc) / k


def _elipse(X, Z, x0, z0, rx, rz, borde=0.35):
    """Elipse de borde suave: 1 dentro, 0 fuera."""
    d = np.sqrt(((X - x0) / rx) ** 2 + ((Z - z0) / rz) ** 2)
    return C.suave(1.0 - d, 0.0, borde)


def _gauss(X, Z, x0, z0, sx, sz):
    return np.exp(-((X - x0) / sx) ** 2 - ((Z - z0) / sz) ** 2)


def _oscurecer(img, mascara, fuerza):
    return img * (1 - fuerza * mascara)[..., None]


def pintar_cara_detallada(U, F, P, color_piel, semilla, datos, color_pelo=(0.07, 0.05, 0.04),
                          barba=0.35, cicatriz=False, sangre=0.0, suciedad=0.3, expresion="tenso",
                          color_ojos=(0.08, 0.055, 0.04)):
    """Cara PS1 (Silent Hill 1): piel con luz horneada, cuencas en sombra con ojos pequeños que
    apenas se ven, cejas gruesas, nariz con sombra debajo, boca de un trazo y barba de días.
    Se pinta a media resolución: el píxel grueso es parte del estilo."""
    alto, ancho = U.shape
    X, Y, Z = coordenadas_cara(P, datos)
    cara = C.suave(Y, 0.035, 0.06)                     # 1 en la cara, 0 en la nuca
    cp = np.array(color_piel)
    tenso = expresion == "tenso"
    img = piel(alto, ancho, color_piel, semilla)
    # Luz horneada: frente y pómulos claros, laterales y nuca más oscuros, bajo la mandíbula en sombra.
    lateral = C.suave(np.abs(X), 0.03, 0.08)
    img = _oscurecer(img, lateral * (1 - 0.5 * cara), 0.25)
    img = _oscurecer(img, C.suave(0.035 - Z, -0.01, 0.035), 0.3)
    img *= (1 + 0.08 * cara * C.suave(Z, 0.15, 0.19))[..., None]
    for lado in (-1, 1):
        img *= (1 + 0.1 * cara * _gauss(X, Z, lado * 0.05, 0.112, 0.016, 0.01))[..., None]   # pómulo
        img = _oscurecer(img, cara * _gauss(X, Z, lado * 0.052, 0.08, 0.012, 0.018), 0.18)  # mejilla
    # Cuencas en sombra bajo el arco de las cejas: los ojos casi no se ven.
    for lado in (-1, 1):
        x0, z0 = lado * 0.03, 0.134
        img = _oscurecer(img, cara * _gauss(X, Z, x0, z0 + 0.003, 0.021, 0.012), 0.55)
        ojo = cara * _elipse(X, Z, x0, z0 - 0.001, 0.0105, 0.0038, 0.5)
        img = C.mezclar(img, (0.3, 0.26, 0.23), ojo * 0.55)
        iris = cara * _elipse(X, Z, x0 + lado * 0.001, z0 - 0.001, 0.0048, 0.0042, 0.45)
        img = C.mezclar(img, color_ojos, iris * 0.9)
        img = C.mezclar(img, (0.06, 0.045, 0.04), cara * C.suave(0.003 - np.abs(Z - z0 - 0.0035), 0, 0.002)
                        * C.suave(0.012 - np.abs(X - x0), 0, 0.004) * 0.6)
        # Ceja gruesa: arco oscuro; en tensión el extremo interior baja.
        s = np.clip((lado * X - 0.01) / 0.044, 0, 1)
        z_ceja = 0.149 + 0.005 * np.sin(np.pi * s * 0.9) - (0.004 * (1 - s) if tenso else 0.0)
        ceja = (cara * C.suave(0.0068 * (1 - 0.35 * s) - np.abs(Z - z_ceja), 0, 0.002)
                * C.suave(lado * X - 0.006, 0, 0.004) * C.suave(0.058 - lado * X, 0, 0.005))
        img = C.mezclar(img, np.array(color_pelo) * 1.1, ceja * 0.95)
    # Nariz: arista clara, sombra lateral y sombra debajo; fosas.
    img *= (1 + 0.1 * cara * _gauss(X, Z, 0, 0.112, 0.005, 0.02))[..., None]
    img = _oscurecer(img, cara * _gauss(X, Z, 0, 0.09, 0.016, 0.005), 0.35)
    for lado in (-1, 1):
        img = _oscurecer(img, cara * _gauss(X, Z, lado * 0.012, 0.11, 0.005, 0.016), 0.15)
        img = C.mezclar(img, cp * 0.3, cara * _elipse(X, Z, lado * 0.007, 0.094, 0.0045, 0.0025, 0.5) * 0.8)
    # Boca: un trazo oscuro con comisuras; labio inferior algo más claro y sombra bajo él.
    caida = 0.003 if tenso else 0.001
    ex = np.abs(X) / 0.02
    linea_z = 0.07 - caida * ex ** 2
    boca = cara * C.suave(0.0024 - np.abs(Z - linea_z), 0, 0.0016) * C.suave(1.0 - ex, 0, 0.2)
    img = C.mezclar(img, cp * np.array((0.42, 0.28, 0.25)), boca)
    img *= (1 + 0.07 * cara * _gauss(X, Z, 0, 0.064, 0.012, 0.003))[..., None]
    img = _oscurecer(img, cara * _gauss(X, Z, 0, 0.055, 0.014, 0.005), 0.18)
    # Barba de varios días: mandíbula y bigote, gris azulado y punteada.
    if barba:
        zona = C.suave(0.088 - Z, 0.0, 0.03) * C.suave(Y, -0.02, 0.03) * C.suave(Z, -0.01, 0.02)
        zona *= 1 - 0.7 * _gauss(X, Z, 0, 0.07, 0.016, 0.006)
        puntos = C.ruido(alto, ancho, semilla + 3, 2, celdas=24)
        img = C.mezclar(img, cp * 0.55 + np.array((0.0, 0.01, 0.03)), zona * barba * (0.45 + 0.4 * puntos))
    if suciedad:
        mugre = C.suave(C.ruido(alto, ancho, semilla + 4, 4, celdas=6), 0.55, 0.85)
        img = C.mezclar(img, cp * 0.5, mugre * suciedad)
    if cicatriz:
        corte = cara * C.suave(0.003 - np.abs(X + 0.042 - (Z - 0.1) * 0.3), 0, 0.0015) * C.suave(0.02 - np.abs(Z - 0.1), 0, 0.005)
        img = C.mezclar(img, (0.42, 0.05, 0.04), corte)
    if sangre:
        m = C.manchas(alto, ancho, semilla + 7, int(5 * sangre) + 1, 1.5 * PX, 4 * PX)
        img = C.mezclar(img, (0.3, 0.035, 0.025), m * cara * 0.8)
    # Pelo pintado bajo el casco (nuca y sienes), por si asoma el cráneo entre los mechones.
    nacimiento = np.where(Y > 0.05, 0.172, np.where(Y > -0.02, 0.148, 0.09))
    tono = pintar_pelo(alto, ancho, color_pelo, semilla + 9)
    return C.mezclar(img, tono, C.suave(Z - nacimiento, -0.002, 0.006))


def pintar_pelo(alto, ancho, color, semilla):
    """Pelo PS1: mechas gruesas con brillo arriba y oscuro hacia el borde."""
    n = C.ruido(alto, ancho, semilla, octavas=3, celdas=6)
    mechas = np.abs(np.sin(np.linspace(0, 18 * np.pi, ancho)[None, :] + n * 6))
    filas = np.linspace(1.0, 0.0, alto)[:, None]
    img = C.lienzo(alto, ancho, color) * (0.62 + 0.4 * mechas[..., None] * 0.6 + 0.3 * n[..., None]
                                          + 0.18 * filas[..., None])
    return img + C.grano(alto, ancho, semilla, 0.015)


# ------------------------------------------------------------ Ensamblado ---

def suavizar(malla, angulo=None):
    """Sombreado suave con las aristas vivas por encima de un ángulo (cuellos, viseras, cajas)."""
    import bmesh
    limite = math.radians(angulo or ANGULO_ARISTA)
    bm = bmesh.new()
    bm.from_mesh(malla)
    for cara in bm.faces:
        cara.smooth = True
    for arista in bm.edges:
        if len(arista.link_faces) != 2 or arista.calc_face_angle(0.0) > limite:
            arista.smooth = False
    bm.to_mesh(malla)
    bm.free()
    malla.update()


def construir_personaje(nombre, piezas, huesos, atlas, coleccion_destino, extras=None,
                        materiales_extra=(), rugosidad=0.85):
    """Crea esqueleto + malla con textura. extras(malla) añade geometría (accesorios)."""
    ruta = C.guardar_png(f"personajes/{nombre.lower()}.png", C.posterizar(atlas, 40))
    mat = C.material(f"MAT_{nombre}", ruta, rugosidad=rugosidad, especular=0.25)
    for nodo in mat.node_tree.nodes:
        if nodo.type == "TEX_IMAGE":
            nodo.interpolation = INTERPOLACION
    arm = crear_esqueleto(f"{nombre}_esqueleto", huesos, coleccion_destino)
    malla = C.Malla()
    for pieza in piezas:
        pieza.construir(malla)
    if extras:
        extras(malla)
    objeto = malla.a_objeto(f"{nombre}_malla", [mat, *materiales_extra], coleccion_destino)
    if SOMBREADO_SUAVE:
        suavizar(objeto.data)
    objeto.parent = arm
    mod = objeto.modifiers.new("Esqueleto", "ARMATURE")
    mod.object = arm
    return arm, objeto
