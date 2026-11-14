"""Animaciones básicas (v1) de todos los personajes, listas para importar en Godot.

Cada animación es una ACCIÓN de Blender guardada dentro del .blend de su personaje
(assets/personajes/<nombre>.blend), en una pista NLA silenciada y con «usuario falso»:
no cambia la pose del archivo, así que los planos y los figurantes no se mueven. El
exportador glTF (y por tanto Godot) las exporta todas como animaciones separadas.

Convenciones:
  - 30 fotogramas por segundo. Las animaciones empiezan en el fotograma 0.
  - Animaciones «en el sitio»: el personaje no avanza; Godot mueve el cuerpo. Las de
    andar y correr están hechas para una velocidad concreta (ver manifiesto) y así los
    pies no patinan. Excepción: «pasar_por_encima» avanza la cadera (desplazamiento).
  - Los ciclos terminan en «_loop»: Godot los importa en bucle automáticamente.
  - El protagonista y los humanos se mueven con fluidez (interpolación suave). Las
    manifestaciones del presente se animan «a pocos fotogramas» (decisión AN2): poses
    cada 4 fotogramas, sin interpolar, a saltos.
  - Las poses se calculan en Python: cadena de huesos (FK) e IK de dos huesos para
    piernas y brazos (pies plantados, manos en su objetivo).

Genera también assets/animaciones/manifiesto.json (lista de animaciones por personaje,
duración, bucle, velocidad de diseño y parejas de animaciones sincronizadas).

Uso (después de generar los personajes con personajes.py y elenco.py):
    blender --background --factory-startup --python assets/scripts/animaciones.py [-- elias_preso el_uniforme ...]
"""
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import comun as C  # noqa: E402

FPS = 30
HUESOS = ("cadera", "columna", "pecho", "cuello", "cabeza",
          "clavicula.L", "brazo.L", "antebrazo.L", "mano.L",
          "clavicula.R", "brazo.R", "antebrazo.R", "mano.R",
          "muslo.L", "pierna.L", "pie.L", "muslo.R", "pierna.R", "pie.R")
LADOS = (("L", 1.0), ("R", -1.0))
U = Vector((0.0, 0.0, 1.0))


# =============================================================== Utilidades ===

def V(izq, adelante, arriba):
    """Vector en el marco del personaje (mira a -Y): izquierda (+X), adelante (-Y), arriba (+Z)."""
    return Vector((izq, -adelante, arriba))


def R(yaw=0.0, pitch=0.0, roll=0.0):
    """Rotación en grados. yaw: gira a su izquierda; pitch: inclina hacia delante; roll: hacia su izquierda."""
    return (Matrix.Rotation(math.radians(yaw), 3, "Z") @ Matrix.Rotation(math.radians(pitch), 3, "X")
            @ Matrix.Rotation(math.radians(roll), 3, "Y"))


def suave(x):
    x = min(max(x, 0.0), 1.0)
    return x * x * (3.0 - 2.0 * x)


def k(t, claves):
    """Interpola con suavizado entre claves (t, valor); el valor puede ser un número o una tupla."""
    if t <= claves[0][0]:
        return claves[0][1]
    for (t0, v0), (t1, v1) in zip(claves, claves[1:]):
        if t <= t1:
            s = suave((t - t0) / (t1 - t0)) if t1 > t0 else 1.0
            if isinstance(v0, (tuple, list)):
                return tuple(a + (b - a) * s for a, b in zip(v0, v1))
            return v0 + (v1 - v0) * s
    return claves[-1][1]


def kv(t, claves, escala=1.0):
    """Como k(), para posiciones (izq, adelante, arriba) en el marco del personaje."""
    return V(*k(t, claves)) * escala


def onda(t, veces=1.0, fase=0.0):
    return math.sin(2.0 * math.pi * (t * veces + fase))


def ik(raiz, objetivo, l1, l2, polo):
    """IK de dos huesos: devuelve (codo/rodilla, extremo alcanzado)."""
    d = objetivo - raiz
    dist = d.length
    eje = d.normalized() if dist > 1e-6 else Vector((0.0, 0.0, -1.0))
    dist = max(min(dist, (l1 + l2) * 0.9995), abs(l1 - l2) + 1e-4)
    cos_a = (l1 * l1 + dist * dist - l2 * l2) / (2.0 * l1 * dist)
    ang = math.acos(max(-1.0, min(1.0, cos_a)))
    p = polo - eje * polo.dot(eje)
    if p.length < 1e-6:
        p = eje.orthogonal()
    p.normalize()
    codo = raiz + eje * (math.cos(ang) * l1) + p * (math.sin(ang) * l1)
    return codo, raiz + eje * dist


# ================================================================== Poses ===

class Pose:
    """Pose de un esqueleto humano calculada en Python (sin depender del depsgraph)."""

    def __init__(self, arm):
        self.arm = arm
        huesos = arm.data.bones
        self.rest = {n: huesos[n].matrix_local.copy() for n in HUESOS}
        self.rest_inv = {n: m.inverted() for n, m in self.rest.items()}
        self.padre = {n: (huesos[n].parent.name if huesos[n].parent else None) for n in HUESOS}
        self.hijos = {n: [m for m in HUESOS if self.padre[m] == n] for n in HUESOS}
        self.largo = {n: huesos[n].length for n in HUESOS}
        self.tobillo0 = {l: huesos[f"pie.{l}"].head_local.copy() for l in "LR"}
        self.pie0 = {l: (huesos[f"pie.{l}"].tail_local - huesos[f"pie.{l}"].head_local).normalized() for l in "LR"}
        self.pierna = self.largo["muslo.L"] + self.largo["pierna.L"]
        self.esc = self.pierna / 0.845              # 1 = proporciones de Elías
        self.reiniciar()
        brazos_colgando(self)
        self.mano0 = {l: self.pos(f"mano.{l}") for l in "LR"}
        self.reiniciar()

    # --- Estado ----------------------------------------------------------------
    def reiniciar(self):
        self.B = {n: Matrix.Identity(4) for n in HUESOS}
        self.M = {}
        self.yaw_cadera = 0.0
        self.yaw_pecho = 0.0
        self.rot_pecho = Matrix.Identity(3)

    def _base(self, n):
        p = self.padre[n]
        if p is None:
            return self.rest[n].copy()
        return self.m(p) @ (self.rest_inv[p] @ self.rest[n])

    def m(self, n):
        if n not in self.M:
            self.M[n] = self._base(n) @ self.B[n]
        return self.M[n]

    def _invalidar(self, n):
        self.M.pop(n, None)
        for h in self.hijos[n]:
            self._invalidar(h)

    def pos(self, n):
        """Posición actual de la cabeza (raíz) del hueso."""
        return self.m(n).translation.copy()

    def aplicar(self):
        for n in HUESOS:
            self.arm.pose.bones[n].matrix_basis = self.B[n]

    # --- Huesos ----------------------------------------------------------------
    def dirigir(self, n, direccion, giro=0.0):
        """Orienta el hueso hacia una dirección del mundo; giro (grados) sobre su propio eje."""
        self._invalidar(n)
        base = self._base(n)
        b3 = base.to_3x3()
        actual = (b3 @ Vector((0.0, 1.0, 0.0))).normalized()
        destino = Vector(direccion).normalized()
        nueva = actual.rotation_difference(destino).to_matrix() @ b3
        if giro:
            nueva = Matrix.Rotation(math.radians(giro), 3, destino) @ nueva
        self.B[n] = (b3.inverted() @ nueva).to_4x4()
        self.M[n] = base @ self.B[n]

    def cadera(self, dx=0.0, dy=0.0, dz=0.0, yaw=0.0, pitch=0.0, roll=0.0):
        """Desplaza (metros: izquierda, adelante, arriba) y gira la cadera, raíz del esqueleto."""
        self._invalidar("cadera")
        r0 = self.rest["cadera"]
        centro = r0.translation.copy()
        mdes = (Matrix.Translation(V(dx, dy, dz)) @ Matrix.Translation(centro) @ R(yaw, pitch, roll).to_4x4()
                @ Matrix.Translation(-centro) @ r0)
        self.B["cadera"] = self.rest_inv["cadera"] @ mdes
        self.M["cadera"] = mdes
        self.yaw_cadera = self.yaw_pecho = yaw
        self.rot_pecho = R(yaw, pitch, roll)

    def tronco(self, pitch=0.0, roll=0.0, giro=0.0, reparto=0.45):
        """Inclinación del tronco (grados, respecto a la vertical) y giro respecto a la cadera."""
        y0 = self.yaw_cadera
        self.dirigir("columna", R(y0 + giro * 0.5, pitch * reparto, roll * reparto) @ U, giro * 0.5)
        self.dirigir("pecho", R(y0 + giro, pitch, roll) @ U, giro * 0.5)
        self.yaw_pecho = y0 + giro
        self.rot_pecho = R(y0 + giro, pitch, roll)

    def cabeza(self, pitch=0.0, roll=0.0, giro=0.0):
        """pitch absoluto (positivo = mira abajo); giro respecto al pecho (positivo = a su izquierda)."""
        y0 = self.yaw_pecho
        self.dirigir("cuello", R(y0 + giro * 0.35, pitch * 0.45, roll * 0.4) @ U, giro * 0.35)
        self.dirigir("cabeza", R(y0 + giro, pitch, roll) @ U, giro * 0.65)

    def clavicula(self, lado, subir=0.0, adelante=0.0):
        s = 1.0 if lado == "L" else -1.0
        self.dirigir(f"clavicula.{lado}", self.rot_pecho @ V(s, adelante, 0.06 + subir))

    def brazo_fk(self, lado, brazo, antebrazo, mano):
        """Direcciones (izq, adelante, arriba) del lado izquierdo; el derecho se refleja."""
        s = 1.0 if lado == "L" else -1.0
        r = R(self.yaw_pecho)
        self.dirigir(f"brazo.{lado}", r @ V(s * brazo[0], brazo[1], brazo[2]))
        self.dirigir(f"antebrazo.{lado}", r @ V(s * antebrazo[0], antebrazo[1], antebrazo[2]))
        self.dirigir(f"mano.{lado}", r @ V(s * mano[0], mano[1], mano[2]))

    def brazo_ik(self, lado, objetivo, polo=None, mano=None, giro_mano=0.0):
        s = 1.0 if lado == "L" else -1.0
        if polo is None:
            polo = R(self.yaw_pecho) @ V(s * 0.45, -0.6, -0.35)
        hombro = self.pos(f"brazo.{lado}")
        codo, fin = ik(hombro, Vector(objetivo), self.largo[f"brazo.{lado}"], self.largo[f"antebrazo.{lado}"],
                       Vector(polo))
        self.dirigir(f"brazo.{lado}", codo - hombro)
        self.dirigir(f"antebrazo.{lado}", fin - codo)
        self.dirigir(f"mano.{lado}", mano if mano is not None else (fin - codo), giro_mano)

    def pierna_ik(self, lado, objetivo, polo=None, pitch=0.0, yaw=0.0):
        """objetivo: posición del tobillo. pitch del pie: positivo = punta hacia abajo."""
        s = 1.0 if lado == "L" else -1.0
        if polo is None:
            polo = R(self.yaw_cadera) @ V(s * 0.12, 1.0, 0.0)
        raiz = self.pos(f"muslo.{lado}")
        rodilla, fin = ik(raiz, Vector(objetivo), self.largo[f"muslo.{lado}"], self.largo[f"pierna.{lado}"],
                          Vector(polo))
        self.dirigir(f"muslo.{lado}", rodilla - raiz)
        self.dirigir(f"pierna.{lado}", fin - rodilla)
        self.dirigir(f"pie.{lado}", R(yaw) @ (Matrix.Rotation(math.radians(pitch), 3, "X") @ self.pie0[lado]))

    # --- Atajos ----------------------------------------------------------------
    def tobillo(self, lado, izq=0.0, adelante=0.0, arriba=0.0, separacion=1.0):
        """Tobillo en reposo desplazado (metros, escalados al tamaño del personaje)."""
        b = self.tobillo0[lado]
        s = 1.0 if lado == "L" else -1.0
        return Vector((b.x * separacion, b.y, b.z)) + V(s * izq, adelante, arriba) * self.esc

    def colgando(self, lado):
        return self.mano0[lado].copy()


# ============================================================ Posturas base ===

def brazos_colgando(po, t=0.0, p=None):
    p = p or {}
    abre = p.get("abrir", 0.13)
    adel = p.get("brazos_adelante", 0.05)
    codo = p.get("codo", 0.2)
    mov = 0.012 * onda(t, p.get("respiraciones", 2))
    for lado, _ in LADOS:
        po.brazo_fk(lado, (abre, adel + mov, -1.0), (abre * 0.5, adel + codo, -1.0),
                    (abre * 0.4, adel + codo * 0.85, -1.0))


def piernas_plantadas(po, p=None, adelante=None, arriba=(0.0, 0.0), pitch=(0.0, 0.0)):
    p = p or {}
    sep = p.get("separacion", 1.0)
    adelante = adelante or p.get("pies_adelante", (0.02, -0.03))
    for i, (lado, s) in enumerate(LADOS):
        po.pierna_ik(lado, po.tobillo(lado, adelante=adelante[i], arriba=arriba[i], separacion=sep),
                     pitch=pitch[i], yaw=s * p.get("pies_abiertos", 6.0))


def quieto(po, t, p=None):
    """De pie: respiración, peso que pasa de un pie a otro y cabeza que se mueve un poco."""
    p = p or {}
    e = po.esc
    resp = onda(t, p.get("respiraciones", 2))
    vaiven = onda(t)
    tiemblo = 0.0
    if p.get("temblor"):
        tiemblo = p["temblor"] * (onda(t, 9) * 0.6 + onda(t, 14, 0.3) * 0.4)
    po.cadera(dx=p.get("balanceo", 0.008) * e * vaiven, dy=p.get("cadera_y", 0.0) * e,
              dz=-p.get("bajar", 0.015) * e + 0.003 * e * resp,
              yaw=p.get("giro", 2.0) * vaiven + p.get("cadera_giro", 0.0), pitch=p.get("cadera_pitch", 0.0))
    po.tronco(pitch=p.get("inclinacion", 3.0) - p.get("pecho_resp", 1.2) * resp + tiemblo,
              roll=p.get("tronco_roll", 0.0) - 1.5 * vaiven * p.get("balanceo", 0.008) / 0.008 * 0.3,
              giro=-p.get("giro", 2.0) * vaiven + p.get("tronco_giro", 0.0))
    cab = p["cabeza"](t) if callable(p.get("cabeza")) else (
        p.get("cabeza_pitch", 3.0) + 1.0 * onda(t, 1, 0.2), p.get("cabeza_roll", 0.0),
        p.get("cabeza_giro", 3.0) * onda(t, 1, 0.6))
    po.cabeza(pitch=cab[0] + tiemblo, roll=cab[1], giro=cab[2] + p.get("cabeza_giro_extra", 0.0))
    for lado, _ in LADOS:
        po.clavicula(lado, subir=p.get("hombros", 0.0) + 0.025 * resp * p.get("hombros_resp", 1.0),
                     adelante=p.get("hombros_adelante", 0.0))
    if callable(p.get("brazos")):
        p["brazos"](po, t)
    else:
        brazos_colgando(po, t, p)
    piernas_plantadas(po, p)


def pie_ciclo(f, duty, recorrido, alzar, e, correr):
    """Trayectoria del tobillo en un ciclo de paso: (adelante, altura, pitch del pie)."""
    talon = 0.105 * e
    if f < duty:
        s = f / duty
        y = recorrido * (0.5 - s)
        if correr:
            pitch = k(s, [(0.0, 8.0), (0.3, 0.0), (0.6, 10.0), (1.0, 45.0)])
        else:
            pitch = k(s, [(0.0, -12.0), (0.15, 0.0), (0.55, 0.0), (1.0, 38.0)])
        z = talon * math.sin(math.radians(max(pitch, 0.0)))
    else:
        s = (f - duty) / (1.0 - duty)
        y = recorrido * (-0.5 + suave(s))
        inicio, fin = (45.0, 8.0) if correr else (38.0, -12.0)
        pitch = k(s, [(0.0, inicio), (0.45, 10.0), (0.85, fin * 0.6), (1.0, fin)])
        z = alzar * math.sin(math.pi * s) + talon * math.sin(math.radians(max(pitch, 0.0)))
    return y, z, pitch


def locomocion(po, t, p):
    """Ciclo de andar o correr en el sitio, para la velocidad p["v"] (m/s)."""
    e = po.esc
    v, T, duty = p["v"], p["T"], p["duty"]
    correr = duty < 0.5
    recorrido = v * T * duty
    fa = t - duty / 2.0
    bob = p.get("bob", 0.018) * e * math.cos(4.0 * math.pi * fa) * (-1.0 if correr else 1.0)
    lat = p.get("lateral", 0.015) * e * math.cos(2.0 * math.pi * fa)
    giro = -p.get("giro_cadera", 6.0) * math.cos(2.0 * math.pi * t)
    po.cadera(dx=lat, dz=-p.get("bajar", 0.06) * e + bob, yaw=giro, pitch=p.get("cadera_pitch", 0.0),
              roll=-p.get("cadera_roll", 3.0) * math.cos(2.0 * math.pi * fa))
    contra = p.get("contra", 1.6)
    incl = p.get("inclinacion", 4.0) + (2.0 * math.cos(4.0 * math.pi * fa) if correr else 0.0)
    po.tronco(pitch=incl, roll=p.get("tronco_roll", 2.0) * math.cos(2.0 * math.pi * fa),
              giro=-giro * contra + p.get("tronco_giro", 0.0))
    pecho_yaw = po.yaw_pecho
    cab = p["cabeza"](t) if callable(p.get("cabeza")) else (p.get("cabeza_pitch", 0.0), p.get("cabeza_roll", 0.0),
                                                            p.get("mirar", 0.0))
    po.cabeza(pitch=cab[0], roll=cab[1], giro=cab[2] - pecho_yaw)
    for lado, _ in LADOS:
        po.clavicula(lado, subir=p.get("hombros", 0.0), adelante=p.get("hombros_adelante", 0.0))
    if callable(p.get("brazos")):
        p["brazos"](po, t)
    else:
        A, codo, abre = p.get("brazo_amp", 25.0), p.get("codo", 20.0), p.get("abrir", 0.12)
        base = p.get("brazo_base", 0.0)
        for lado, _ in LADOS:
            ang = base - A * math.cos(2.0 * math.pi * (t + (0.0 if lado == "L" else 0.5)))
            c = codo + 0.5 * max(0.0, ang - base)
            po.brazo_fk(lado, (abre, math.sin(math.radians(ang)), -math.cos(math.radians(ang))),
                        (abre * 0.5, math.sin(math.radians(ang + c)), -math.cos(math.radians(ang + c))),
                        (abre * 0.4, math.sin(math.radians(ang + c * 1.1)), -math.cos(math.radians(ang + c * 1.1))))
    for lado, s in LADOS:
        f = (t + (0.0 if lado == "L" else 0.5)) % 1.0
        y, z, pitch = pie_ciclo(f, duty, recorrido, p.get("alzar", 0.1) * e, e, correr)
        if lado == "R" and p.get("cojera"):
            z *= 1.0 - p["cojera"]                     # la pierna derecha se arrastra
            pitch = pitch * (1.0 - p["cojera"]) + 25.0 * p["cojera"]
        objetivo = po.tobillo(lado, adelante=p.get("centro", -0.06) + y / e, arriba=z / e,
                              separacion=p.get("ancho", 1.0))
        po.pierna_ik(lado, objetivo, pitch=pitch, yaw=s * p.get("pies_abiertos", 4.0))


# ================================================================ Elías ===

ANDAR = {"v": 1.55, "T": 0.86, "duty": 0.58, "centro": -0.065}
CORRER = {"v": 3.5, "T": 0.66, "duty": 0.38, "bajar": 0.09, "alzar": 0.2, "bob": 0.03, "inclinacion": 12.0,
          "brazo_amp": 45.0, "codo": 80.0, "giro_cadera": 8.0, "centro": -0.07, "lateral": 0.008}
AGACHADO = {"bajar": 0.36, "inclinacion": 30.0, "cadera_pitch": 10.0, "cabeza_pitch": -4.0, "separacion": 1.45,
            "pies_adelante": (0.08, -0.12), "pies_abiertos": 12.0, "hombros_adelante": 0.12, "giro": 1.0}


def brazos_agachado(po, t):
    """Agachado: las manos cuelgan justo delante de las rodillas, listas para apoyarse."""
    for lado, s in LADOS:
        mov = 0.025 * onda(t, 1, 0.0 if lado == "L" else 0.5)
        po.brazo_ik(lado, V(s * 0.21, 0.36 + mov, 0.42) * po.esc, polo=V(s * 0.6, -0.4, 0.1), mano=V(0, 0.45, -1.0))


AGACHADO["brazos"] = brazos_agachado
AGACHADO_ANDAR = {"v": 0.95, "T": 1.1, "duty": 0.65, "bajar": 0.36, "inclinacion": 30.0, "cadera_pitch": 10.0,
                  "cabeza_pitch": -4.0, "alzar": 0.07, "bob": 0.01, "ancho": 1.4, "brazos": brazos_agachado,
                  "hombros_adelante": 0.12, "giro_cadera": 4.0, "centro": 0.0}


def mirar_atras(po, t):
    g = k(t, [(0.0, 0.0), (0.25, 1.0), (0.72, 1.0), (1.0, 0.0)])
    quieto(po, t, {"cadera_giro": 12.0 * g, "tronco_giro": 42.0 * g, "cabeza_giro_extra": 75.0 * g,
                   "hombros": 0.04 * g, "pies_adelante": (0.02, -0.03 - 0.04 * g)})


def levantarse(po, t):
    """Del suelo, boca abajo (inicio del juego), a de pie."""
    e = po.esc
    po.cadera(dy=k(t, [(0, 0.0), (0.22, 0.0), (0.45, -0.12), (0.65, -0.05), (0.85, 0.0), (1, 0.0)]) * e,
              dz=k(t, [(0, -0.78), (0.22, -0.7), (0.45, -0.5), (0.65, -0.42), (0.85, -0.12), (1, -0.015)]) * e,
              pitch=k(t, [(0, 88), (0.22, 75), (0.45, 32), (0.65, 8), (0.85, 4), (1, 0)]))
    po.tronco(pitch=k(t, [(0, 90), (0.22, 62), (0.45, 70), (0.65, 25), (0.85, 12), (1, 3)]))
    po.cabeza(pitch=k(t, [(0, 70), (0.22, 35), (0.45, 45), (0.65, 15), (1, 3)]))
    for lado, s in LADOS:
        po.clavicula(lado, subir=k(t, [(0, 0.25), (0.45, 0.15), (0.7, 0.0)]))
        fin = po.colgando(lado)
        objetivo = kv(t, [(0, (s * 0.28, 0.46, 0.04)), (0.22, (s * 0.27, 0.46, 0.04)), (0.45, (s * 0.2, 0.42, 0.04)),
                          (0.62, (s * (0.15 if s > 0 else 0.22), 0.3 if s > 0 else 0.25, 0.56 if s > 0 else 0.3)),
                          (0.82, (s * 0.2, 0.12, 0.82)), (1, (fin.x, -fin.y, fin.z))])
        polo = kv(t, [(0, (s * 0.7, -0.3, 0.7)), (0.45, (s * 0.6, -0.3, 0.5)), (0.7, (s * 0.45, -0.6, -0.3)),
                      (1, (s * 0.45, -0.6, -0.35))])
        po.brazo_ik(lado, objetivo if t < 0.99 else fin, polo=polo)
    for lado, s in LADOS:
        izquierda = lado == "L"
        tob = po.tobillo0[lado]
        claves = [(0, (s * 0.12, -0.83, 0.07)), (0.22, (s * 0.12, -0.8, 0.07)), (0.45, (s * 0.13, -0.5, 0.05))]
        if izquierda:
            claves += [(0.65, (0.12, 0.32, 0.085)), (0.85, (0.11, 0.06, 0.085))]
        else:
            claves += [(0.65, (-0.12, -0.42, 0.08)), (0.85, (-0.11, -0.06, 0.12))]
        claves.append((1, (tob.x, -tob.y, tob.z)))
        abajo = V(0, 0.15, -1.0)
        alante = V(s * 0.12, 1.0, 0.0)
        cambio = 0.55 if izquierda else 0.72
        polo = abajo.lerp(alante, suave((t - (cambio - 0.08)) / 0.16))
        pitch = k(t, [(0, 100), (0.45, 90), (0.6, 0 if izquierda else 80), (0.85, 0 if izquierda else 20), (1, 0)])
        po.pierna_ik(lado, kv(t, claves), polo=polo, pitch=pitch)


def empujar(po, t):
    """Empujar una puerta u objeto pesado que está delante."""
    e = po.esc
    g = k(t, [(0, 0), (0.3, 1), (0.78, 1), (1, 0)])
    emp = k(t, [(0, 0), (0.3, 0), (0.55, 1), (0.8, 1), (1, 0)])
    po.cadera(dy=(0.05 * g + 0.08 * emp) * e, dz=(-0.015 - 0.04 * g - 0.03 * emp) * e, pitch=5 * g)
    po.tronco(pitch=3 + 15 * g + 8 * emp)
    po.cabeza(pitch=3 + 4 * g)
    for lado, s in LADOS:
        po.clavicula(lado, adelante=0.18 * g)
    for lado, s in LADOS:
        meta = V(s * 0.17, 0.55 + 0.1 * emp, 1.25) * e
        po.brazo_ik(lado, po.colgando(lado).lerp(meta, g), polo=V(s * 0.5, -0.4, -0.6))
    po.pierna_ik("L", po.tobillo("L", adelante=0.3 * g), pitch=0)
    po.pierna_ik("R", po.tobillo("R", adelante=-0.12 * g, arriba=0.04 * g), pitch=25 * g)


def ganzua(po, t):
    """Arrodillado ante la cerradura (a 1 m del suelo): la mano derecha mueve la ganzúa."""
    e = po.esc
    po.cadera(dy=0.05 * e, dz=-0.43 * e, pitch=6)
    po.tronco(pitch=12 + 1.5 * onda(t, 2))
    po.cabeza(pitch=18 + 3 * onda(t, 1, 0.3), roll=8, giro=-6)
    for lado, _ in LADOS:
        po.clavicula(lado, adelante=0.15)
    cerradura = V(-0.02, 0.42, 0.98) * e
    po.brazo_ik("R", cerradura + V(-0.03 + 0.012 * onda(t, 4), 0.0, 0.01 * onda(t, 2, 0.25)) * e,
                polo=V(-0.6, -0.3, -0.5), mano=V(0.3, 1.0, 0.1), giro_mano=25 * onda(t, 2))
    po.brazo_ik("L", cerradura + V(0.05, -0.01, -0.02 + 0.005 * onda(t, 1)) * e, polo=V(0.6, -0.3, -0.5),
                mano=V(-0.2, 1.0, 0.0))
    po.pierna_ik("L", po.tobillo("L", izq=0.03, adelante=0.32), polo=V(0.15, 1.0, 0.3))
    po.pierna_ik("R", po.tobillo("R", izq=0.02, adelante=-0.42, arriba=-0.005), polo=V(-0.05, 0.3, -1.0), pitch=75)


def leer(po, t):
    """Sostiene un documento a la altura del pecho y lo lee."""
    def brazos(po_, t_):
        for lado, s in LADOS:
            po_.brazo_ik(lado, V(s * 0.11, 0.3, 1.12 + 0.006 * onda(t_, 2)) * po_.esc, polo=V(s * 0.5, -0.3, -0.7),
                         mano=V(0, 0.5, 1.0))
    quieto(po, t, {"cabeza": lambda t_: (27 + 2 * onda(t_, 1), 0.0, 4 * onda(t_, 1, 0.3)), "brazos": brazos,
                   "inclinacion": 6.0})


def recoger(po, t):
    """Agacharse y recoger algo del suelo con la mano derecha."""
    e = po.esc
    g = k(t, [(0, 0), (0.4, 1), (0.6, 1), (1, 0)])
    po.cadera(dy=-0.06 * g * e, dz=(-0.015 - 0.42 * g) * e, pitch=15 * g)
    po.tronco(pitch=3 + 38 * g)
    po.cabeza(pitch=3 + 25 * g)
    for lado, _ in LADOS:
        po.clavicula(lado, adelante=0.1 * g)
    mano_r = kv(t, [(0, (0, 0, 0)), (0.42, (-0.12, 0.38, 0.06)), (0.58, (-0.12, 0.38, 0.06)),
                    (0.85, (-0.15, 0.2, 1.05)), (1, (0, 0, 0))], e)
    colg = po.colgando("R")
    peso = k(t, [(0, 0), (0.3, 1), (0.9, 1), (1, 0)])
    po.brazo_ik("R", colg.lerp(mano_r, peso) if t < 0.99 else colg, polo=V(-0.5, -0.4, -0.3))
    mano_l = V(0.16, 0.3, 0.5) * e
    po.brazo_ik("L", po.colgando("L").lerp(mano_l, g), polo=V(0.6, -0.4, -0.2))
    po.pierna_ik("L", po.tobillo("L", adelante=0.04, separacion=1.25), pitch=0)
    po.pierna_ik("R", po.tobillo("R", adelante=0.1, separacion=1.25), pitch=0)


def lanzar(po, t):
    """Lanzar un objeto por encima del hombro (distracción por ruido)."""
    e = po.esc
    giro = k(t, [(0, 0), (0.35, -28), (0.5, 5), (0.7, 22), (1, 0)])
    po.cadera(dy=k(t, [(0, 0), (0.35, -0.04), (0.6, 0.1), (1, 0)]) * e, dz=-0.03 * e, yaw=giro * 0.4)
    po.tronco(pitch=k(t, [(0, 3), (0.35, -8), (0.6, 22), (1, 3)]), giro=giro * 0.6)
    po.cabeza(pitch=k(t, [(0, 3), (0.35, -5), (0.6, 5), (1, 3)]), giro=-giro * 0.6)
    po.clavicula("L")
    po.clavicula("R", subir=k(t, [(0, 0), (0.35, 0.2), (0.6, 0.05), (1, 0)]))
    mano_r = kv(t, [(0, (-0.25, 0.08, 0.89)), (0.35, (-0.32, -0.28, 1.62)), (0.48, (-0.15, 0.55, 1.58)),
                    (0.68, (0.08, 0.42, 0.92)), (1, (-0.25, 0.08, 0.89))], e)
    po.brazo_ik("R", mano_r, polo=kv(t, [(0, (-0.5, -0.5, -0.4)), (0.35, (-0.8, -0.2, 0.2)), (0.6, (-0.6, -0.5, -0.4)),
                                         (1, (-0.5, -0.5, -0.4))]))
    mano_l = kv(t, [(0, (0.25, 0.08, 0.89)), (0.35, (0.28, 0.45, 1.3)), (0.6, (0.22, 0.0, 0.95)),
                    (1, (0.25, 0.08, 0.89))], e)
    po.brazo_ik("L", mano_l)
    paso = k(t, [(0, 0), (0.3, 0), (0.45, 0.3), (0.85, 0.3), (1, 0)])
    po.pierna_ik("L", po.tobillo("L", adelante=paso, arriba=0.05 * math.sin(math.pi * min(1, max(0, (t - 0.3) / 0.15)))))
    po.pierna_ik("R", po.tobillo("R", adelante=-0.08), pitch=k(t, [(0, 0), (0.5, 20), (1, 0)]))


def esconderse(po, t):
    """Agacharse de golpe para esconderse (termina en la pose de agachado)."""
    g = suave(t / 0.85)
    p = {clave: valor for clave, valor in AGACHADO.items()}
    for clave in ("bajar", "inclinacion", "cadera_pitch", "hombros_adelante"):
        p[clave] = {"bajar": 0.015, "inclinacion": 3.0, "cadera_pitch": 0.0, "hombros_adelante": 0.0}[clave] * (1 - g) \
            + AGACHADO[clave] * g
    p["pies_adelante"] = (0.02 + 0.06 * g, -0.03 - 0.09 * g)
    p["separacion"] = 1.0 + 0.45 * g
    p["cabeza_pitch"] = 3.0 - 7.0 * g
    p["brazos"] = None if g < 0.5 else brazos_agachado
    quieto(po, 0.0, p)


def taquilla(po, t):
    """Dentro de una taquilla: pegado a la pared del fondo, respiración agitada, mira por las rendijas."""
    def brazos(po_, t_):
        for lado, s in LADOS:
            po_.brazo_ik(lado, V(s * 0.12, 0.18, 1.05 + 0.01 * onda(t_, 3)) * po_.esc, polo=V(s * 0.5, -0.4, -0.6))
    quieto(po, t, {"respiraciones": 6, "pecho_resp": 2.5, "hombros_resp": 1.6, "inclinacion": 1.0,
                   "brazos": brazos, "cabeza": lambda t_: (-2.0, 0.0, 6 * onda(t_, 1)), "balanceo": 0.002,
                   "separacion": 0.85})


def congelarse(po, t):
    """Quieto en el Recuento: tenso, conteniendo la respiración, con un leve temblor."""
    def brazos(po_, t_):
        for lado, s in LADOS:
            po_.brazo_ik(lado, V(s * 0.1, 0.2, 1.1 + 0.004 * onda(t_, 9)) * po_.esc, polo=V(s * 0.4, -0.5, -0.6))
    quieto(po, t, {"respiraciones": 1, "pecho_resp": 0.3, "hombros": 0.12, "hombros_resp": 0.2, "balanceo": 0.001,
                   "giro": 0.3, "brazos": brazos, "cabeza": lambda t_: (10.0, 0.0, 0.0), "temblor": 0.5,
                   "bajar": 0.03})


def marcar_pared(po, t):
    """Guardar partida: raya una marca más en la pared con el alambre."""
    e = po.esc
    trazo = 0.0
    for t0 in (0.25, 0.55):
        if t0 <= t <= t0 + 0.2:
            trazo = math.sin(math.pi * (t - t0) / 0.2)
    g = k(t, [(0, 0), (0.18, 1), (0.85, 1), (1, 0)])
    po.cadera(dy=0.03 * g * e, dz=-0.02 * e)
    po.tronco(pitch=3 + 8 * g)
    po.cabeza(pitch=3 + 18 * g, giro=-8 * g)
    for lado, _ in LADOS:
        po.clavicula(lado, adelante=0.1 * g)
    raya = V(-0.05 - 0.01 * (t > 0.5), 0.42, 1.32 - 0.15 * trazo) * e
    po.brazo_ik("R", po.colgando("R").lerp(raya, g), polo=V(-0.6, -0.3, -0.4))
    po.brazo_ik("L", po.colgando("L").lerp(V(0.25, 0.44, 1.38) * e, g), polo=V(0.6, -0.3, -0.4), mano=V(0, 0.2, 1))
    piernas_plantadas(po, {"pies_adelante": (0.05, -0.05)})


def palanca(po, t):
    """Tirar hacia abajo de una palanca alta con las dos manos y el peso del cuerpo."""
    e = po.esc
    g = k(t, [(0, 0), (0.25, 1), (0.85, 1), (1, 0)])
    tiro = k(t, [(0, 0), (0.3, 0), (0.65, 1), (0.85, 1), (1, 0)])
    po.cadera(dz=(-0.015 - 0.15 * tiro) * e, dy=0.03 * g * e)
    po.tronco(pitch=3 - 6 * g * (1 - tiro) + 18 * tiro)
    po.cabeza(pitch=3 - 25 * g * (1 - tiro) + 10 * tiro)
    for lado, s in LADOS:
        po.clavicula(lado, subir=0.15 * g * (1 - tiro))
    for lado, s in LADOS:
        meta = V(s * 0.06, 0.45, 1.6 - 0.6 * tiro) * e
        po.brazo_ik(lado, po.colgando(lado).lerp(meta, g), polo=V(s * 0.6, -0.4, -0.2))
    piernas_plantadas(po, {"pies_adelante": (0.08, -0.1), "separacion": 1.2})


def volante(po, t):
    """Girar un volante de válvula (a 1,3 m de altura, delante) mano sobre mano."""
    e = po.esc
    centro = V(0, 0.48, 1.3) * e
    radio = 0.38 * e
    giro = -120.0 * suave(t / 0.7) if t < 0.7 else -120.0 * (1 - suave((t - 0.7) / 0.3))
    agarre = 1.0 if t < 0.7 else 0.0
    po.cadera(dz=-0.04 * e, dy=0.02 * e, yaw=-5 * suave(t / 0.7) * agarre)
    po.tronco(pitch=8, giro=giro * 0.08)
    po.cabeza(pitch=8)
    for lado, s in LADOS:
        po.clavicula(lado, adelante=0.12)
    for lado, s in LADOS:
        ang = math.radians((150.0 if s > 0 else 30.0) + giro * agarre)
        punto = centro + Vector((math.cos(ang) * radio, 0.0, math.sin(ang) * radio))
        if agarre == 0.0:
            punto = punto + V(0, -0.08 * math.sin(math.pi * (t - 0.7) / 0.3), 0) * e
        po.brazo_ik(lado, punto, polo=V(s * 0.6, -0.4, -0.5))
    piernas_plantadas(po, {"pies_adelante": (0.1, -0.1), "separacion": 1.25})


def punzon_clavar(po, t):
    """Clavar el punzón para librarse de un agarre."""
    e = po.esc
    po.cadera(dy=k(t, [(0, 0), (0.35, 0.12), (1, 0)]) * e, dz=-0.04 * e)
    po.tronco(pitch=k(t, [(0, 3), (0.2, -5), (0.38, 15), (1, 3)]))
    po.cabeza(pitch=k(t, [(0, 3), (0.38, -8), (1, 3)]))
    po.clavicula("L")
    po.clavicula("R", subir=k(t, [(0, 0), (0.38, 0.12), (1, 0)]))
    po.brazo_ik("R", kv(t, [(0, (-0.25, 0.08, 0.89)), (0.2, (-0.12, 0.12, 1.12)), (0.38, (-0.07, 0.62, 1.52)),
                            (0.6, (-0.12, 0.3, 1.2)), (1, (-0.25, 0.08, 0.89))], e),
                polo=V(-0.6, -0.4, -0.4))
    po.brazo_ik("L", kv(t, [(0, (0.25, 0.08, 0.89)), (0.3, (0.2, 0.32, 1.25)), (1, (0.25, 0.08, 0.89))], e))
    po.pierna_ik("L", po.tobillo("L", adelante=k(t, [(0, 0), (0.35, 0.18), (1, 0)])))
    po.pierna_ik("R", po.tobillo("R", adelante=-0.06), pitch=k(t, [(0, 0), (0.38, 18), (1, 0)]))


def apuntar_pistola(po, t, retroceso=0.0):
    e = po.esc
    po.cadera(dz=-0.04 * e, yaw=-10, dy=0.01 * e)
    po.tronco(pitch=5 - 6 * retroceso, giro=8)
    po.cabeza(pitch=2 - 4 * retroceso, giro=4)
    for lado, s in LADOS:
        po.clavicula(lado, adelante=0.14, subir=0.04 + 0.08 * retroceso)
    resp = 0.006 * onda(t, 1)
    arma = V(-0.04, 0.6 - 0.05 * retroceso, 1.42 + resp + 0.07 * retroceso) * e
    po.brazo_ik("R", arma, polo=V(-0.7, -0.2, -0.6), mano=V(0, 1.0, 0.15 + 0.6 * retroceso))
    po.brazo_ik("L", arma + V(0.03, -0.04, -0.035) * e, polo=V(0.7, -0.1, -0.7), mano=V(-0.3, 1.0, 0.0))
    piernas_plantadas(po, {"pies_adelante": (0.12, -0.12), "separacion": 1.25})


def apuntar_escopeta(po, t, retroceso=0.0, bombeo=0.0):
    e = po.esc
    po.cadera(dz=-0.05 * e, yaw=-18, dy=-0.02 * retroceso * e)
    po.tronco(pitch=6 - 10 * retroceso, giro=12)
    po.cabeza(pitch=4 - 4 * retroceso, roll=-10, giro=10)
    po.clavicula("L", adelante=0.1)
    po.clavicula("R", adelante=0.05, subir=0.06 + 0.1 * retroceso)
    culata = V(-0.13, 0.26 - 0.06 * retroceso, 1.33 + 0.05 * retroceso + 0.004 * onda(t, 1)) * e
    po.brazo_ik("R", culata, polo=V(-0.8, -0.2, -0.3), mano=V(0.2, 1.0, 0.0))
    guarda = culata + V(0.13, 0.36 - 0.15 * bombeo, -0.03 + 0.06 * retroceso) * e
    po.brazo_ik("L", guarda, polo=V(0.6, -0.1, -0.8), mano=V(-0.4, 0.8, -0.2))
    piernas_plantadas(po, {"pies_adelante": (0.15, -0.14), "separacion": 1.3})


def cegado(po, t):
    """Deslumbrado por el foco de El Vigilante: se tapa los ojos y retrocede."""
    e = po.esc
    po.cadera(dy=k(t, [(0, 0), (0.45, -0.18), (1, -0.2)]) * e, dz=k(t, [(0, -0.015), (0.5, -0.06), (1, -0.05)]) * e)
    po.tronco(pitch=k(t, [(0, 3), (0.22, -8), (0.6, 12), (1, 15)]))
    po.cabeza(pitch=k(t, [(0, 3), (0.2, -15), (0.6, 20), (1, 25)]), giro=k(t, [(0, 0), (0.6, -20), (1, -25)]))
    for lado, s in LADOS:
        po.clavicula(lado, subir=k(t, [(0, 0), (0.3, 0.2), (1, 0.15)]))
        po.brazo_ik(lado, kv(t, [(0, (s * 0.25, 0.08, 0.89)), (0.25, (s * 0.08, 0.22, 1.62)), (1, (s * 0.07, 0.2, 1.58))], e),
                    polo=V(s * 0.6, -0.1, -0.6))
    po.pierna_ik("L", po.tobillo("L", adelante=k(t, [(0, 0), (0.45, -0.05), (1, -0.05)])))
    po.pierna_ik("R", po.tobillo("R", adelante=k(t, [(0, 0), (0.35, -0.3), (1, -0.3)]),
                                 arriba=0.06 * math.sin(math.pi * min(1, t / 0.35))), pitch=k(t, [(0, 0), (0.35, -10), (0.5, 0)]))


def muerte_cuello(po, t):
    """El Uniforme lo alza del cuello (pareja: el_uniforme/agarrar, a 0,6 m delante)."""
    e = po.esc
    alza = k(t, [(0, 0.0), (0.12, 0.0), (0.42, 0.38), (1, 0.42)])
    po.cadera(dy=k(t, [(0, 0), (0.4, 0.05)]) * e, dz=(-0.015 + alza) * e, pitch=-5 * suave(t / 0.4))
    po.tronco(pitch=k(t, [(0, 3), (0.3, -10), (1, -12)]))
    po.cabeza(pitch=k(t, [(0, 0), (0.25, -30), (1, -40)]) + 4 * onda(t, 5) * suave((t - 0.4) / 0.2),
              roll=6 * onda(t, 2))
    for lado, s in LADOS:
        po.clavicula(lado, subir=0.15 * suave(t / 0.3))
    cuello = po.pos("cabeza")
    for lado, s in LADOS:
        meta = cuello + V(s * 0.06, 0.12, -0.04) * e + V(0, 0.02 * onda(t, 4, 0.25 * s), 0.02 * onda(t, 4)) * e
        po.brazo_ik(lado, po.colgando(lado).lerp(meta, suave(t / 0.2)), polo=V(s * 0.7, 0.0, -0.6))
    patada = suave((t - 0.4) / 0.15) * (1 - 0.6 * suave((t - 0.8) / 0.2))
    for lado, s in LADOS:
        raiz = po.pos(f"muslo.{lado}")
        colgado = raiz + V(s * 0.05, 0.08 + 0.18 * patada * onda(t, 3, 0.0 if s > 0 else 0.5), -0.8) * e
        suelo = po.tobillo(lado)
        po.pierna_ik(lado, suelo.lerp(colgado, suave((t - 0.15) / 0.3)), pitch=35 * suave((t - 0.15) / 0.3))


def muerte_placaje(po, t):
    """Placaje por la espalda: cae de bruces (pareja: policia_patrullero/placaje)."""
    e = po.esc
    po.cadera(dy=k(t, [(0, 0), (0.3, 0.2), (0.7, 0.65), (1, 0.75)]) * e,
              dz=k(t, [(0, -0.015), (0.3, -0.1), (0.7, -0.68), (1, -0.78)]) * e,
              pitch=k(t, [(0, 0), (0.25, 20), (0.7, 75), (1, 88)]))
    po.tronco(pitch=k(t, [(0, 3), (0.25, 35), (0.7, 82), (1, 92)]))
    po.cabeza(pitch=k(t, [(0, 0), (0.25, -12), (0.7, 40), (1, 70)]))
    for lado, s in LADOS:
        po.clavicula(lado, subir=k(t, [(0, 0), (0.6, 0.2), (1, 0.25)]))
        meta = kv(t, [(0, (s * 0.25, 0.08, 0.89)), (0.35, (s * 0.25, 0.75, 0.6)), (0.75, (s * 0.3, 1.1, 0.05)),
                      (1, (s * 0.32, 1.15, 0.04))], e)
        po.brazo_ik(lado, meta, polo=kv(t, [(0, (s * 0.45, -0.6, -0.35)), (0.7, (s * 0.7, -0.3, 0.6)), (1, (s * 0.7, -0.3, 0.6))]))
    for lado, s in LADOS:
        meta = kv(t, [(0, (s * 0.1, -0.02, 0.085)), (0.3, (s * 0.1, -0.12, 0.2)), (0.7, (s * 0.12, -0.15, 0.25)),
                      (1, (s * 0.13, -0.07, 0.06))], e)
        polo = V(s * 0.12, 1.0, 0).lerp(V(0, 0.2, -1.0), suave((t - 0.45) / 0.3))
        po.pierna_ik(lado, meta, polo=polo, pitch=k(t, [(0, 0), (0.7, 60), (1, 95)]))


def muerte_arrastrado(po, t):
    """Los Aislados lo arrastran al suelo: se dobla y cae de espaldas."""
    e = po.esc
    po.cadera(dy=k(t, [(0, 0), (0.3, -0.1), (0.7, -0.45), (1, -0.55)]) * e,
              dz=k(t, [(0, -0.015), (0.3, -0.25), (0.7, -0.65), (1, -0.8)]) * e,
              pitch=k(t, [(0, 0), (0.3, -10), (0.7, -55), (1, -85)]))
    po.tronco(pitch=k(t, [(0, 3), (0.3, -15), (0.7, -60), (1, -88)]), giro=8 * onda(t, 2))
    po.cabeza(pitch=k(t, [(0, 0), (0.3, 20), (0.7, -30), (1, -70)]), giro=15 * onda(t, 1.5))
    for lado, s in LADOS:
        po.clavicula(lado, subir=0.15)
        meta = kv(t, [(0, (s * 0.25, 0.08, 0.89)), (0.3, (s * 0.32, 0.4, 1.2)), (0.7, (s * 0.38, 0.3, 0.9)),
                      (1, (s * 0.45, 0.1, 0.4))], e)
        po.brazo_ik(lado, meta + V(0, 0, 0.05 * onda(t, 3, 0.2 * s)) * e, polo=V(s * 0.7, -0.4, 0.2))
    for lado, s in LADOS:
        meta = kv(t, [(0, (s * 0.1, -0.02, 0.085)), (0.3, (s * 0.12, 0.1, 0.085)), (0.7, (s * 0.15, 0.35, 0.06)),
                      (1, (s * 0.15, 0.4, 0.06))], e)
        po.pierna_ik(lado, meta, polo=V(s * 0.2, 1.0, 0.5), pitch=k(t, [(0, 0), (1, -30)]))


def muerte_golpe(po, t):
    """Golpe de La Sentencia: sale despedido hacia atrás y cae de espaldas."""
    e = po.esc
    po.cadera(dy=k(t, [(0, 0), (0.25, -0.35), (0.6, -0.9), (1, -1.1)]) * e,
              dz=k(t, [(0, -0.015), (0.25, 0.0), (0.6, -0.5), (1, -0.8)]) * e,
              pitch=k(t, [(0, 0), (0.25, -20), (0.6, -60), (1, -86)]), roll=k(t, [(0, 0), (0.6, 15), (1, 10)]))
    po.tronco(pitch=k(t, [(0, 3), (0.2, -25), (0.6, -70), (1, -88)]))
    po.cabeza(pitch=k(t, [(0, 0), (0.2, -30), (1, -75)]))
    for lado, s in LADOS:
        po.clavicula(lado, subir=0.1)
        meta = kv(t, [(0, (s * 0.25, 0.08, 0.89)), (0.25, (s * 0.55, 0.2, 1.4)), (0.6, (s * 0.6, -0.3, 0.8)),
                      (1, (s * 0.6, -0.8, 0.1))], e)
        po.brazo_ik(lado, meta, polo=V(s * 0.5, -0.5, 0.3))
    for lado, s in LADOS:
        meta = kv(t, [(0, (s * 0.1, -0.02, 0.085)), (0.25, (s * 0.12, 0.15, 0.2)), (0.6, (s * 0.14, 0.0, 0.3)),
                      (1, (s * 0.15, -0.2, 0.06))], e)
        po.pierna_ik(lado, meta, polo=V(s * 0.2, 1.0, 0.4), pitch=k(t, [(0, 0), (1, -20)]))


# --- Solo en el pasado (Elías civil) -----------------------------------------------

ANDAR_PASADO = {"v": 2.3, "T": 0.62, "duty": 0.55, "bajar": 0.07, "inclinacion": 7.0, "brazo_amp": 32.0,
                "codo": 35.0, "centro": -0.07}
CORRER_PASADO = {"v": 5.4, "T": 0.6, "duty": 0.3, "bajar": 0.11, "alzar": 0.26, "bob": 0.035, "inclinacion": 16.0,
                 "brazo_amp": 55.0, "codo": 88.0, "giro_cadera": 9.0, "centro": -0.07, "lateral": 0.006}
CORRER_MIRANDO = dict(CORRER_PASADO, tronco_giro=40.0, contra=1.0, mirar=115.0, brazo_amp=40.0)


def derribar(po, t):
    """Derribar cubos o cajas de un manotazo para cortar el paso (en plena huida)."""
    e = po.esc
    giro = k(t, [(0, 0), (0.3, -32), (0.55, 12), (1, 0)])
    po.cadera(dz=k(t, [(0, -0.05), (0.45, -0.12), (1, -0.05)]) * e, yaw=giro * 0.4, dx=-0.06 * suave(t / 0.3) * e)
    po.tronco(pitch=k(t, [(0, 10), (0.4, 25), (1, 10)]), giro=giro * 0.6, roll=k(t, [(0, 0), (0.4, -12), (1, 0)]))
    po.cabeza(pitch=k(t, [(0, 0), (0.4, 15), (1, 0)]), giro=k(t, [(0, 0), (0.3, -25), (0.6, 30), (1, 0)]))
    po.clavicula("L")
    po.clavicula("R", adelante=0.15 * suave(t / 0.3))
    po.brazo_ik("R", kv(t, [(0, (-0.25, 0.08, 0.89)), (0.3, (-0.5, 0.3, 0.85)), (0.5, (-0.55, -0.2, 0.55)),
                            (1, (-0.25, 0.08, 0.89))], e), polo=V(-0.6, -0.2, 0.3))
    po.brazo_ik("L", kv(t, [(0, (0.25, 0.08, 0.89)), (0.4, (0.35, 0.25, 1.05)), (1, (0.25, 0.08, 0.89))], e))
    po.pierna_ik("L", po.tobillo("L", adelante=0.05))
    po.pierna_ik("R", po.tobillo("R", izq=k(t, [(0, 0), (0.3, 0.25), (1, 0)]),
                                  arriba=0.08 * math.sin(math.pi * min(1, t / 0.3))))


def pasar_por_encima(po, t):
    """Saltar un obstáculo bajo (0,9 m) apoyando las manos. La cadera avanza 1,6 m (desplazamiento)."""
    e = po.esc
    avance = k(t, [(0, 0), (0.25, 0.35), (0.5, 0.85), (0.75, 1.35), (1, 1.6)])
    po.cadera(dy=avance * e, dz=k(t, [(0, -0.03), (0.2, -0.12), (0.45, 0.35), (0.7, 0.05), (0.85, -0.14), (1, -0.03)]) * e,
              roll=k(t, [(0, 0), (0.45, 25), (0.75, 0)]), pitch=k(t, [(0, 0), (0.25, 20), (0.6, 10), (1, 0)]))
    po.tronco(pitch=k(t, [(0, 5), (0.25, 30), (0.45, 25), (0.7, 10), (0.85, 22), (1, 5)]),
              roll=k(t, [(0, 0), (0.45, 18), (0.7, 0)]))
    po.cabeza(pitch=k(t, [(0, 0), (0.3, 20), (0.6, 5), (1, 0)]))
    for lado, s in LADOS:
        po.clavicula(lado, adelante=0.15 * suave(t / 0.25) * (1 - suave((t - 0.55) / 0.2)))
        apoyo = V(s * 0.15, 0.62, 0.92) * e
        libre = V(s * 0.3, avance + 0.2, 1.0) * e
        if t < 0.22:
            meta = po.colgando(lado).lerp(apoyo, suave(t / 0.22))
        elif t < 0.52:
            meta = apoyo
        else:
            meta = apoyo.lerp(libre, suave((t - 0.52) / 0.3))
        po.brazo_ik(lado, meta, polo=V(s * 0.6, -0.5, 0.2))
    for lado, s in LADOS:
        inicio = (0.0 if s > 0 else -0.05)
        meta = kv(t, [(0, (s * 0.1, inicio, 0.085)), (0.2, (s * 0.1, inicio + 0.05, 0.085)),
                      (0.45, (s * 0.25, 0.85, 0.95)), (0.7, (s * 0.15, 1.45, 0.4)), (0.85, (s * 0.11, 1.6, 0.085)),
                      (1, (s * 0.1, 1.6 + inicio, 0.085))], e)
        po.pierna_ik(lado, meta, polo=V(s * 0.3, 1.0, 0.3), pitch=k(t, [(0, 0), (0.2, 25), (0.5, -10), (0.85, 0)]))


def sentado(po, t):
    """Sentado en la silla del interrogatorio (asiento a 0,46 m) con los brazos sobre la mesa."""
    e = po.esc
    resp = onda(t, 2)
    po.cadera(dz=-0.41 * e + 0.003 * resp * e, dy=-0.05 * e, pitch=-8)
    po.tronco(pitch=8 - 1.2 * resp, giro=3 * onda(t, 1))
    po.cabeza(pitch=6 + 2 * onda(t, 1, 0.3), giro=8 * onda(t, 1, 0.6))
    for lado, s in LADOS:
        po.clavicula(lado, adelante=0.08, subir=0.02 * resp)
        po.brazo_ik(lado, V(s * 0.17, 0.42, 0.8) * e, polo=V(s * 0.6, -0.3, -0.5), mano=V(-s * 0.4, 1.0, -0.1))
    for lado, s in LADOS:
        po.pierna_ik(lado, po.tobillo(lado, izq=0.03, adelante=0.4), polo=V(s * 0.1, 1.0, 0.6))


def esconder_objeto(po, t):
    """Motivo de F1: agacharse y esconder la carpeta en un hueco bajo, delante."""
    e = po.esc
    g = k(t, [(0, 0), (0.35, 1), (0.7, 1), (1, 0)])
    emp = k(t, [(0, 0), (0.35, 0), (0.55, 1), (0.7, 1), (0.85, 0)])
    po.cadera(dy=-0.05 * g * e, dz=(-0.03 - 0.45 * g) * e, pitch=18 * g)
    po.tronco(pitch=5 + 40 * g)
    po.cabeza(pitch=5 + 20 * g, giro=-20 * k(t, [(0, 0), (0.75, 0), (0.85, 1), (1, 0)]))
    for lado, s in LADOS:
        po.clavicula(lado, adelante=0.15 * g)
        meta = V(s * 0.1, 0.45 + 0.12 * emp, 0.22) * e
        po.brazo_ik(lado, po.colgando(lado).lerp(meta, g), polo=V(s * 0.6, -0.4, -0.2))
    po.pierna_ik("L", po.tobillo("L", adelante=0.1, separacion=1.3))
    po.pierna_ik("R", po.tobillo("R", adelante=-0.1, separacion=1.3), pitch=30 * g)


# ======================================================= Manifestaciones ===

def brazos_uniforme(po, t, alcanzar=0.0):
    """El Uniforme: brazo izquierdo caído y rígido; el derecho, con el aro de llaves, algo adelantado."""
    po.brazo_fk("L", (0.07, 0.03 + alcanzar * 0.6, -1.0), (0.04, 0.06 + alcanzar, -1.0), (0.03, 0.06 + alcanzar, -1.0))
    po.brazo_fk("R", (0.09, 0.12 + alcanzar * 0.6, -1.0), (0.05, 0.6 + alcanzar, -0.85), (0.04, 0.55 + alcanzar, -0.9))


UNIFORME_QUIETO = {"balanceo": 0.002, "giro": 0.5, "respiraciones": 1, "pecho_resp": 0.4, "hombros_resp": 0.2,
                   "inclinacion": 1.0, "cabeza": lambda t: (6.0, 0.0, 0.0), "brazos": brazos_uniforme,
                   "separacion": 0.9}
UNIFORME_ANDAR = {"v": 1.0, "T": 1.3, "duty": 0.62, "bajar": 0.05, "bob": 0.008, "giro_cadera": 2.0, "contra": 0.5,
                  "inclinacion": 2.0, "alzar": 0.06, "lateral": 0.006, "cabeza_pitch": 5.0,
                  "brazos": lambda po, t: brazos_uniforme(po, t)}
UNIFORME_PERSEGUIR = {"v": 2.4, "T": 0.8, "duty": 0.52, "bajar": 0.08, "bob": 0.012, "giro_cadera": 3.0,
                      "contra": 0.5, "inclinacion": 10.0, "alzar": 0.09, "lateral": 0.008, "cabeza_pitch": -2.0,
                      "brazos": lambda po, t: brazos_uniforme(po, t, alcanzar=0.35)}


def recuento(po, t):
    """Las llaves callan: se detiene y barre el pasillo con la mirada, girando la cabeza despacio."""
    p = dict(UNIFORME_QUIETO)
    p["cabeza"] = lambda t_: (4.0, 0.0, 60.0 * onda(t_, 1))
    p["tronco_giro"] = 10.0 * onda(t, 1)
    quieto(po, t, p)


def agarrar_uniforme(po, t):
    """Alza a Elías del cuello con el brazo derecho (pareja: elias_preso/muerte_cuello, Elías a 0,6 m)."""
    e = po.esc
    po.cadera(dz=-0.04 * e, dy=k(t, [(0, 0), (0.12, 0.08), (1, 0.05)]) * e)
    po.tronco(pitch=k(t, [(0, 2), (0.12, 10), (0.45, -6), (1, -8)]))
    po.cabeza(pitch=k(t, [(0, 5), (0.45, -12), (1, -15)]))
    po.clavicula("L")
    po.clavicula("R", subir=k(t, [(0, 0), (0.45, 0.25), (1, 0.3)]))
    altura = k(t, [(0, 1.05), (0.15, 1.5), (0.45, 1.88), (1, 1.92)])     # cuello de Elías (m, absoluto)
    po.brazo_ik("R", V(-0.04, 0.6, altura), polo=V(-0.7, -0.3, -0.5), mano=V(0, 1.0, 0.3))
    po.brazo_ik("L", V(0.22, 0.12, 0.98 * e), polo=V(0.6, -0.4, -0.4))
    piernas_plantadas(po, {"pies_adelante": (0.08, -0.15), "separacion": 1.2})


def aturdido(po, t):
    """Aturdido por un disparo (3-4 s): retrocede a tirones y se recompone."""
    e = po.esc
    sacudida = (1 - suave(t / 0.8)) * onda(t, 6)
    po.cadera(dy=k(t, [(0, 0), (0.12, -0.25), (0.8, -0.25), (1, -0.2)]) * e, dz=k(t, [(0, -0.02), (0.12, -0.08), (1, -0.03)]) * e)
    po.tronco(pitch=k(t, [(0, 2), (0.1, -18), (0.4, 15), (0.8, 8), (1, 3)]) + 5 * sacudida, roll=8 * sacudida)
    po.cabeza(pitch=k(t, [(0, 4), (0.1, -25), (0.4, 30), (1, 6)]), roll=15 * sacudida, giro=20 * sacudida)
    for lado, s in LADOS:
        po.clavicula(lado, subir=0.1 * (1 - suave(t / 0.8)))
        meta = po.colgando(lado) + V(s * 0.25, -0.1, 0.35) * e * (1 - suave((t - 0.3) / 0.6))
        po.brazo_ik(lado, meta, polo=V(s * 0.6, -0.4, -0.3))
    po.pierna_ik("L", po.tobillo("L", adelante=k(t, [(0, 0), (0.12, -0.05), (1, 0)])))
    po.pierna_ik("R", po.tobillo("R", adelante=k(t, [(0, 0), (0.12, -0.3), (0.8, -0.3), (1, -0.05)])))


def brazos_aislado(po, t, adelante=20.0, amp=6.0):
    for lado, s in LADOS:
        a = math.radians(adelante + amp * onda(t, 1, 0.0 if s > 0 else 0.5))
        po.brazo_fk(lado, (0.1, math.sin(a), -math.cos(a)), (0.05, math.sin(a + 0.25), -math.cos(a + 0.25)),
                    (0.03, math.sin(a + 0.3), -math.cos(a + 0.3)))


AISLADO_QUIETO = {"bajar": 0.08, "inclinacion": 40.0, "cadera_pitch": 12.0, "respiraciones": 3, "pecho_resp": 2.0,
                  "balanceo": 0.015, "giro": 4.0,
                  "cabeza": lambda t: (25.0 + 8 * onda(t, 2, 0.1), 18.0 + 10 * onda(t, 3), 12 * onda(t, 1, 0.4)),
                  "brazos": lambda po, t: brazos_aislado(po, t, 25.0, 8.0), "separacion": 1.15}
AISLADO_ANDAR = {"v": 0.7, "T": 1.5, "duty": 0.65, "bajar": 0.09, "inclinacion": 38.0, "cadera_pitch": 10.0,
                 "cojera": 0.6, "alzar": 0.06, "bob": 0.012, "lateral": 0.03, "tronco_roll": 6.0,
                 "cabeza": lambda t: (20.0, 15.0, 8 * onda(t, 1)), "brazos": lambda po, t: brazos_aislado(po, t, 20.0, 10.0)}
AISLADO_CORRER = {"v": 2.6, "T": 0.8, "duty": 0.45, "bajar": 0.12, "inclinacion": 45.0, "cadera_pitch": 12.0,
                  "alzar": 0.14, "bob": 0.02, "lateral": 0.02, "cabeza": lambda t: (-5.0, 10.0, 0.0),
                  "brazos": lambda po, t: brazos_aislado(po, t, 60.0, 18.0)}


def atacar_aislado(po, t):
    """Se abalanza y tira de la víctima hacia el suelo con las dos manos."""
    e = po.esc
    po.cadera(dy=k(t, [(0, 0), (0.35, 0.4), (1, 0.35)]) * e, dz=k(t, [(0, -0.08), (0.35, -0.2), (0.8, -0.32), (1, -0.3)]) * e,
              pitch=k(t, [(0, 12), (0.35, 30), (1, 35)]))
    po.tronco(pitch=k(t, [(0, 40), (0.35, 50), (0.8, 62), (1, 60)]))
    po.cabeza(pitch=k(t, [(0, 25), (0.35, -5), (1, 10)]), roll=15)
    for lado, s in LADOS:
        po.clavicula(lado, adelante=0.2, subir=0.1)
        po.brazo_ik(lado, kv(t, [(0, (s * 0.25, 0.3, 0.75)), (0.35, (s * 0.15, 0.78, 0.95)), (0.8, (s * 0.15, 0.55, 0.3)),
                                 (1, (s * 0.15, 0.55, 0.28))], e), polo=V(s * 0.7, -0.2, 0.0))
    po.pierna_ik("L", po.tobillo("L", adelante=k(t, [(0, 0), (0.35, 0.45), (1, 0.45)]),
                                 arriba=0.06 * math.sin(math.pi * min(1, t / 0.35))))
    po.pierna_ik("R", po.tobillo("R", adelante=k(t, [(0, 0), (0.35, 0.05), (1, 0.05)])), pitch=k(t, [(0, 0), (0.35, 30), (1, 25)]))


def escuchar(po, t):
    """Oye un ruido: se yergue un poco y ladea la cabeza hacia él."""
    g = k(t, [(0, 0), (0.3, 1), (0.75, 1), (1, 0)])
    p = dict(AISLADO_QUIETO)
    p["inclinacion"] = 40.0 - 12.0 * g
    p["cabeza"] = lambda t_: (25.0 - 20.0 * g, 18.0 - 30.0 * g, 50.0 * g)
    quieto(po, t, p)


def morir_aislado(po, t):
    """Cae al suelo de lado (la pistola sí lo mata)."""
    e = po.esc
    po.cadera(dz=k(t, [(0, -0.08), (0.35, -0.45), (1, -0.8)]) * e, dx=k(t, [(0, 0), (1, 0.25)]) * e,
              roll=k(t, [(0, 0), (0.35, 10), (1, 80)]), pitch=k(t, [(0, 12), (0.35, 25), (1, 10)]))
    po.tronco(pitch=k(t, [(0, 40), (0.35, 50), (1, 20)]), roll=k(t, [(0, 0), (1, 85)]))
    po.cabeza(pitch=k(t, [(0, 25), (1, 10)]), roll=k(t, [(0, 15), (1, 95)]))
    for lado, s in LADOS:
        po.clavicula(lado)
        po.brazo_ik(lado, po.colgando(lado).lerp(po.pos(f"brazo.{lado}") + V(s * 0.45, 0.1, -0.1) * e, suave(t)),
                    polo=V(s * 0.4, -0.6, 0.0))
    for lado, s in LADOS:
        meta = kv(t, [(0, (s * 0.1, -0.02, 0.085)), (0.35, (s * 0.12, 0.15, 0.085)), (1, (s * 0.15 + 0.3, 0.2, 0.08))], e)
        po.pierna_ik(lado, meta, polo=V(s * 0.2, 1.0, 0.3))


def vigilante_brazos(po, t, amp=4.0):
    for lado, s in LADOS:
        a = math.radians(6 + amp * onda(t, 1, 0.0 if s > 0 else 0.5))
        po.brazo_fk(lado, (0.07, math.sin(a), -math.cos(a)), (0.03, math.sin(a) + 0.05, -1.0), (0.02, 0.06, -1.0))


VIGILANTE_QUIETO = {"inclinacion": 10.0, "respiraciones": 1, "pecho_resp": 0.5, "balanceo": 0.004, "giro": 1.0,
                    "cabeza": lambda t: (8.0, 0.0, 65.0 * onda(t, 1)), "brazos": lambda po, t: vigilante_brazos(po, t, 2.0)}
VIGILANTE_ANDAR = {"v": 0.9, "T": 1.7, "duty": 0.65, "bajar": 0.06, "inclinacion": 12.0, "alzar": 0.08,
                   "bob": 0.015, "giro_cadera": 4.0, "lateral": 0.01,
                   "cabeza": lambda t: (8.0, 0.0, 35.0 * onda(t, 1)), "brazos": lambda po, t: vigilante_brazos(po, t, 10.0)}


def alerta_vigilante(po, t):
    """Detecta a alguien: gira la cabeza (el foco) hacia él de golpe y se tensa."""
    g = k(t, [(0, 0), (0.2, 1), (1, 1)])
    p = dict(VIGILANTE_QUIETO)
    p["inclinacion"] = 10.0 - 6.0 * g
    p["cabeza"] = lambda t_: (8.0 + 6.0 * g, 0.0, 30.0 * g)
    p["hombros"] = 0.1 * g
    p["brazos"] = lambda po_, t_: vigilante_brazos(po_, 0.25, 2.0)
    quieto(po, t, p)


CONDENADO_QUIETO = {"inclinacion": 14.0, "respiraciones": 2, "pecho_resp": 1.5, "balanceo": 0.01,
                    "cabeza": lambda t: (12.0 + 6 * onda(t, 3, 0.2), 14.0 + 6 * onda(t, 2), 8 * onda(t, 1, 0.3)),
                    "brazos": lambda po, t: brazos_aislado(po, t, 12.0, 4.0)}


def brazos_condenado(po, t):
    po.brazo_fk("R", (0.18, 0.85, 0.05), (0.1, 1.0, 0.05), (0.05, 1.0, -0.1))
    a = math.radians(10 + 8 * onda(t, 1, 0.5))
    po.brazo_fk("L", (0.1, math.sin(a), -math.cos(a)), (0.05, math.sin(a) + 0.15, -1.0), (0.04, 0.15, -1.0))


CONDENADO_ACECHAR = {"v": 1.1, "T": 1.2, "duty": 0.62, "bajar": 0.08, "inclinacion": 22.0, "cojera": 0.3,
                     "alzar": 0.07, "lateral": 0.025, "tronco_roll": 5.0,
                     "cabeza": lambda t: (15.0, 15.0, 0.0), "brazos": brazos_condenado}


def atacar_condenado(po, t):
    """Se lanza con los dos brazos hacia la cara de la víctima."""
    e = po.esc
    po.cadera(dy=k(t, [(0, 0), (0.35, 0.35), (1, 0.3)]) * e, dz=k(t, [(0, -0.05), (0.35, -0.12), (1, -0.1)]) * e)
    po.tronco(pitch=k(t, [(0, 14), (0.35, 28), (1, 20)]))
    po.cabeza(pitch=k(t, [(0, 12), (0.35, -10), (1, -5)]), roll=k(t, [(0, 14), (0.35, 0)]))
    for lado, s in LADOS:
        po.clavicula(lado, adelante=0.2, subir=0.1)
        po.brazo_ik(lado, kv(t, [(0, (s * 0.25, 0.1, 0.9)), (0.35, (s * 0.15, 0.78, 1.5)), (1, (s * 0.12, 0.7, 1.4))], e),
                    polo=V(s * 0.7, -0.3, -0.3))
    po.pierna_ik("L", po.tobillo("L", adelante=k(t, [(0, 0), (0.35, 0.4), (1, 0.4)]),
                                 arriba=0.07 * math.sin(math.pi * min(1, t / 0.35))))
    po.pierna_ik("R", po.tobillo("R", adelante=k(t, [(0, 0), (0.35, 0.0)])), pitch=k(t, [(0, 0), (0.35, 30), (1, 25)]))


def brazos_sentencia(po, t, balanceo=0.0):
    # Derecho: cuelga algo atrás, sujetando la hoja que arrastra. Izquierdo: cae y se balancea al andar.
    po.brazo_fk("R", (0.12, -0.08, -1.0), (0.07, 0.02, -1.0), (0.05, 0.05, -1.0))
    a = math.radians(5 + balanceo * onda(t, 1, 0.5))
    po.brazo_fk("L", (0.15, math.sin(a), -math.cos(a)), (0.08, math.sin(a) + 0.12, -1.0), (0.05, 0.12, -1.0))


SENTENCIA_QUIETO = {"respiraciones": 2, "pecho_resp": 3.0, "hombros_resp": 2.0, "inclinacion": 8.0,
                    "separacion": 1.4, "balanceo": 0.015, "cabeza": lambda t: (10.0 + 3 * onda(t, 2), 0.0, 0.0),
                    "brazos": lambda po, t: brazos_sentencia(po, t)}
SENTENCIA_ANDAR = {"v": 0.8, "T": 1.7, "duty": 0.68, "bajar": 0.07, "inclinacion": 10.0, "lateral": 0.045,
                   "tronco_roll": 6.0, "giro_cadera": 4.0, "contra": 0.8, "alzar": 0.08, "ancho": 1.35,
                   "bob": 0.02, "cabeza_pitch": 10.0, "brazos": lambda po, t: brazos_sentencia(po, t, 12.0)}


def golpe_vertical(po, t):
    """Alza la hoja por encima de la cabeza y la descarga delante (destruye coberturas)."""
    e = po.esc
    po.cadera(dz=k(t, [(0, -0.03), (0.4, 0.0), (0.62, -0.12), (0.85, -0.1), (1, -0.03)]) * e,
              dy=k(t, [(0, 0), (0.4, -0.05), (0.62, 0.15), (1, 0)]) * e)
    po.tronco(pitch=k(t, [(0, 8), (0.4, -15), (0.6, 35), (0.85, 30), (1, 8)]),
              giro=k(t, [(0, 0), (0.4, -15), (0.6, 5), (1, 0)]))
    po.cabeza(pitch=k(t, [(0, 10), (0.4, -10), (0.6, 25), (1, 10)]))
    po.clavicula("L")
    po.clavicula("R", subir=k(t, [(0, 0), (0.4, 0.35), (0.62, 0.0)]))
    colg = po.colgando("R")
    meta = kv(t, [(0, (colg.x, -colg.y, colg.z)), (0.4, (-0.2, -0.1, 2.85)), (0.55, (-0.15, 0.9, 1.6)),
                  (0.62, (-0.15, 1.0, 0.45)), (0.85, (-0.15, 0.95, 0.5)), (1, (colg.x, -colg.y, colg.z))])
    po.brazo_ik("R", meta, polo=V(-0.7, -0.2, 0.2), giro_mano=k(t, [(0, 0), (0.4, 90), (0.62, 90), (1, 0)]))
    po.brazo_ik("L", kv(t, [(0, (0.3, 0.08, 1.33)), (0.4, (0.35, 0.3, 1.8)), (0.62, (0.3, 0.3, 1.0)), (1, (0.3, 0.08, 1.33))]))
    po.pierna_ik("L", po.tobillo("L", adelante=k(t, [(0, 0.05), (0.4, 0.05), (0.6, 0.25), (1, 0.05)]), separacion=1.35))
    po.pierna_ik("R", po.tobillo("R", adelante=-0.1, separacion=1.35))


def golpe_barrido(po, t):
    """Barrido horizontal con la hoja, de derecha a izquierda."""
    e = po.esc
    giro = k(t, [(0, 0), (0.35, -45), (0.6, 10), (0.75, 40), (1, 0)])
    po.cadera(dz=-0.08 * e, yaw=giro * 0.35)
    po.tronco(pitch=12, giro=giro * 0.65)
    po.cabeza(pitch=10, giro=-giro * 0.4)
    po.clavicula("L")
    po.clavicula("R", subir=k(t, [(0, 0), (0.35, 0.15), (0.75, 0.1), (1, 0)]))
    colg = po.colgando("R")
    meta = kv(t, [(0, (colg.x, -colg.y, colg.z)), (0.35, (-0.85, -0.25, 1.45)), (0.55, (-0.2, 0.95, 1.25)),
                  (0.75, (0.7, 0.45, 1.15)), (1, (colg.x, -colg.y, colg.z))])
    po.brazo_ik("R", meta, polo=V(-0.4, -0.6, -0.4))
    po.brazo_ik("L", kv(t, [(0, (0.3, 0.08, 1.33)), (0.35, (0.4, 0.4, 1.4)), (0.75, (0.5, -0.2, 1.2)), (1, (0.3, 0.08, 1.33))]))
    po.pierna_ik("L", po.tobillo("L", adelante=0.08, separacion=1.45))
    po.pierna_ik("R", po.tobillo("R", adelante=-0.08, separacion=1.45))


def tambalearse(po, t):
    """Un cartucho de escopeta la hace tambalearse hacia atrás."""
    e = po.esc
    sac = (1 - suave(t)) * onda(t, 4)
    po.cadera(dy=k(t, [(0, 0), (0.2, -0.35), (0.7, -0.3), (1, -0.1)]) * e, dz=k(t, [(0, -0.03), (0.2, -0.1), (1, -0.03)]) * e)
    po.tronco(pitch=k(t, [(0, 8), (0.15, -20), (0.6, 15), (1, 8)]) + 4 * sac, roll=6 * sac)
    po.cabeza(pitch=k(t, [(0, 10), (0.15, -30), (0.6, 20), (1, 10)]))
    for lado, s in LADOS:
        po.clavicula(lado, subir=0.15 * (1 - suave(t)))
    brazos_sentencia(po, t)
    po.brazo_ik("L", po.colgando("L") + V(0.35, 0.1, 0.4) * e * (1 - suave((t - 0.2) / 0.7)), polo=V(0.6, -0.3, -0.4))
    po.pierna_ik("L", po.tobillo("L", adelante=k(t, [(0, 0.05), (0.2, -0.1), (1, 0.05)]), separacion=1.35))
    po.pierna_ik("R", po.tobillo("R", adelante=k(t, [(0, -0.1), (0.2, -0.45), (0.8, -0.4), (1, -0.1)]), separacion=1.35))


def furia(po, t):
    """El ruido la enfurece: se yergue, abre los brazos y sacude la cabeza."""
    e = po.esc
    g = k(t, [(0, 0), (0.3, 1), (0.8, 1), (1, 0)])
    sac = g * onda(t, 6)
    po.cadera(dz=-0.03 * e + 0.04 * g * e)
    po.tronco(pitch=8 - 23 * g + 3 * sac, roll=4 * sac)
    po.cabeza(pitch=10 - 40 * g, roll=12 * sac, giro=10 * sac)
    for lado, s in LADOS:
        po.clavicula(lado, subir=0.25 * g)
    colg = po.colgando("R")
    po.brazo_ik("R", colg.lerp(V(-0.75, 0.2, 1.75) * e, g), polo=V(-0.3, -0.5, -0.6))
    po.brazo_ik("L", po.colgando("L").lerp(V(0.85, 0.2, 1.9) * e, g), polo=V(0.3, -0.5, -0.6))
    po.pierna_ik("L", po.tobillo("L", adelante=0.05, separacion=1.4))
    po.pierna_ik("R", po.tobillo("R", adelante=-0.08, separacion=1.4))


DIRECTOR_QUIETO = {"respiraciones": 1, "pecho_resp": 0.6, "balanceo": 0.002, "giro": 0.3, "inclinacion": 1.0,
                   "cabeza": lambda t: (5.0, 0.0, 0.0), "abrir": 0.1, "codo": 0.12}


def mirar_abajo(po, t):
    """El Director baja la cabeza despacio hacia Elías."""
    p = dict(DIRECTOR_QUIETO)
    g = k(t, [(0, 0), (0.8, 1), (1, 1)])
    p["cabeza"] = lambda t_: (5.0 + 32.0 * g, 0.0, -6.0 * g)
    p["inclinacion"] = 1.0 + 6.0 * g
    quieto(po, t, p)


# ========================================================= Humanos del pasado ===

def brazos_porra(po, t, amp=20.0):
    """Policía y guardia: la porra en la mano derecha, el brazo izquierdo se balancea."""
    a_l = math.radians(amp * -math.cos(2 * math.pi * t))
    a_r = math.radians(5 + amp * 0.5 * math.cos(2 * math.pi * t))
    po.brazo_fk("L", (0.12, math.sin(a_l), -math.cos(a_l)), (0.06, math.sin(a_l) + 0.3, -1.0), (0.05, 0.3, -1.0))
    po.brazo_fk("R", (0.14, math.sin(a_r), -math.cos(a_r)), (0.08, math.sin(a_r) + 0.35, -1.0), (0.06, 0.6, -0.8))


POLICIA_ANDAR = {"v": 1.5, "T": 0.86, "duty": 0.58, "bajar": 0.06, "centro": -0.065,
                 "brazos": lambda po, t: brazos_porra(po, t, 20.0)}
POLICIA_CORRER = {"v": 4.8, "T": 0.62, "duty": 0.33, "bajar": 0.11, "alzar": 0.24, "bob": 0.032,
                  "inclinacion": 15.0, "brazo_amp": 50.0, "codo": 85.0, "giro_cadera": 9.0, "centro": -0.07,
                  "lateral": 0.006}
GUARDIA_ANDAR = {"v": 1.4, "T": 0.9, "duty": 0.6, "bajar": 0.06, "centro": -0.065,
                 "brazos": lambda po, t: brazos_porra(po, t, 18.0)}
GUARDIA_CORRER = {"v": 4.2, "T": 0.64, "duty": 0.35, "bajar": 0.1, "alzar": 0.22, "bob": 0.03,
                  "inclinacion": 13.0, "brazo_amp": 45.0, "codo": 80.0, "giro_cadera": 8.0, "centro": -0.07}


def silbato(po, t):
    """Toca el silbato para llamar refuerzos y señala la huida con el otro brazo."""
    e = po.esc
    g = k(t, [(0, 0), (0.2, 1), (0.85, 1), (1, 0)])
    sopla = 0.5 + 0.5 * onda(t, 3)
    po.cadera(dz=-0.03 * e, yaw=8 * g)
    po.tronco(pitch=3 - 4 * g * sopla, giro=5 * g)
    po.cabeza(pitch=3 - 8 * g, giro=-10 * g)
    for lado, s in LADOS:
        po.clavicula(lado, subir=0.05 * g * sopla)
    boca = po.pos("cabeza") + V(-0.02, 0.12, 0.07) * e
    po.brazo_ik("R", po.colgando("R").lerp(boca, g), polo=V(-0.7, -0.2, -0.5))
    po.brazo_ik("L", po.colgando("L").lerp(V(0.35, 0.8, 1.48) * e, g), polo=V(0.6, -0.3, -0.5), mano=V(0.1, 1, 0.05))
    piernas_plantadas(po, {"pies_adelante": (0.1, -0.1), "separacion": 1.2})


def placaje(po, t):
    """Placaje: se lanza hacia delante con los brazos abiertos (pareja: elias_civil/muerte_placaje)."""
    e = po.esc
    po.cadera(dy=k(t, [(0, 0), (0.35, 0.6), (0.8, 1.2), (1, 1.3)]) * e,
              dz=k(t, [(0, -0.05), (0.2, -0.15), (0.45, -0.25), (0.8, -0.68), (1, -0.78)]) * e,
              pitch=k(t, [(0, 10), (0.35, 50), (0.8, 80), (1, 88)]))
    po.tronco(pitch=k(t, [(0, 12), (0.35, 60), (0.8, 85), (1, 92)]))
    po.cabeza(pitch=k(t, [(0, 0), (0.35, 20), (1, 60)]))
    for lado, s in LADOS:
        po.clavicula(lado, adelante=0.2, subir=0.15)
        po.brazo_ik(lado, kv(t, [(0, (s * 0.3, 0.3, 1.0)), (0.35, (s * 0.35, 1.2, 0.95)), (0.8, (s * 0.25, 1.8, 0.35)),
                                 (1, (s * 0.25, 1.9, 0.1))], e), polo=V(s * 0.7, -0.3, 0.2))
    for lado, s in LADOS:
        meta = kv(t, [(0, (s * 0.1, 0.0, 0.085)), (0.2, (s * 0.1, 0.05 if s > 0 else -0.1, 0.085)),
                      (0.45, (s * 0.12, 0.2, 0.3)), (0.8, (s * 0.12, 0.6, 0.25)), (1, (s * 0.13, 0.5, 0.06))], e)
        po.pierna_ik(lado, meta, polo=V(s * 0.1, 1.0, 0.0).lerp(V(0, 0.2, -1.0), suave((t - 0.5) / 0.3)),
                     pitch=k(t, [(0, 0), (0.45, 40), (1, 95)]))


def tactico_brazos(po, t):
    """Escudo en el antebrazo izquierdo, delante del pecho; porra en la derecha."""
    e = po.esc
    po.brazo_ik("L", V(0.05, 0.42, 1.15 + 0.008 * onda(t, 2)) * e, polo=V(0.9, -0.1, -0.4), mano=V(-1.0, 0.3, 0.2))
    a = math.radians(10 + 6 * onda(t, 1))
    po.brazo_fk("R", (0.14, math.sin(a), -math.cos(a)), (0.08, math.sin(a) + 0.35, -1.0), (0.06, 0.6, -0.8))


TACTICO_QUIETO = {"bajar": 0.05, "inclinacion": 6.0, "separacion": 1.3, "pies_adelante": (0.1, -0.12),
                  "brazos": tactico_brazos, "cabeza": lambda t: (2.0, 0.0, 6 * onda(t, 1))}
TACTICO_ANDAR = {"v": 1.2, "T": 0.95, "duty": 0.6, "bajar": 0.08, "inclinacion": 8.0, "ancho": 1.25,
                 "giro_cadera": 3.0, "contra": 0.8, "brazos": tactico_brazos, "centro": -0.05}


def brazos_atras(po, t):
    """Manos a la espalda (alcaide, interrogador paseando)."""
    for lado, s in LADOS:
        po.brazo_ik(lado, V(s * 0.06, -0.2, 0.98 + 0.005 * onda(t, 2)) * po.esc, polo=V(s * 0.8, 0.0, -0.4))


def interrogador_apoyado(po, t):
    """Inclinado sobre la mesa (0,76 m), con las manos apoyadas."""
    def brazos(po_, t_):
        for lado, s in LADOS:
            po_.brazo_ik(lado, V(s * 0.24, 0.45, 0.8) * po_.esc, polo=V(s * 0.7, -0.4, 0.0), mano=V(0, 0.4, -1.0))
    quieto(po, t, {"inclinacion": 35.0, "cadera_pitch": 10.0, "bajar": 0.03, "brazos": brazos,
                   "cabeza": lambda t_: (5.0 + 3 * onda(t_, 1), 0.0, 8 * onda(t_, 1, 0.3)), "hombros_adelante": 0.1})


def golpe_mesa(po, t):
    """Levanta la mano derecha y golpea la mesa."""
    e = po.esc
    g = k(t, [(0, 0), (0.3, 1), (0.45, 0), (1, 0)])
    impacto = k(t, [(0, 0), (0.42, 0), (0.48, 1), (0.8, 1), (1, 0)])
    po.cadera(dz=-0.03 * e, pitch=10)
    po.tronco(pitch=35 - 12 * g + 5 * impacto)
    po.cabeza(pitch=5 - 10 * g + 8 * impacto)
    for lado, s in LADOS:
        po.clavicula(lado, adelante=0.1, subir=0.1 * g)
    po.brazo_ik("L", V(0.24, 0.45, 0.8) * e, polo=V(0.7, -0.4, 0.0), mano=V(0, 0.4, -1.0))
    po.brazo_ik("R", V(-0.22, 0.45 - 0.1 * g, 0.8 + 0.55 * g) * e, polo=V(-0.7, -0.4, 0.0), mano=V(0, 0.4, -1.0))
    piernas_plantadas(po)


def hablar(po, t):
    """El alcaide habla y gesticula con la mano derecha."""
    def brazos(po_, t_):
        gesto = 0.5 + 0.5 * onda(t_, 3)
        po_.brazo_ik("R", V(-0.25, 0.35 + 0.08 * gesto, 1.05 + 0.1 * gesto) * po_.esc, polo=V(-0.7, -0.3, -0.4),
                     mano=V(-0.2, 1.0, 0.4))
        po_.brazo_ik("L", V(0.06, -0.2, 0.98) * po_.esc, polo=V(0.8, 0.0, -0.4))
    quieto(po, t, {"brazos": brazos, "cabeza": lambda t_: (0.0 + 4 * onda(t_, 3), 0.0, 10 * onda(t_, 1)),
                   "inclinacion": -2.0, "cadera_pitch": -3.0})


PRESO_ANDAR = {"v": 1.3, "T": 0.9, "duty": 0.6, "bajar": 0.06, "inclinacion": 6.0, "brazo_amp": 18.0,
               "centro": -0.065}


# ================================================================= Catálogo ===

def an(nombre, segundos, funcion, bucle=False, escalonado=False, **info):
    return {"nombre": nombre, "segundos": segundos, "funcion": funcion, "bucle": bucle, "escalonado": escalonado,
            "info": info}


def ciclo(nombre, params, escalonado=False, **info):
    return an(nombre, params["T"], lambda po, t: locomocion(po, t, params), True, escalonado,
              velocidad=params["v"], **info)


def quieto_loop(params=None, segundos=3.0, escalonado=False):
    return an("quieto_loop", segundos, lambda po, t: quieto(po, t, params), True, escalonado)


def elias_comun():
    return [
        quieto_loop(),
        an("mirar_atras", 1.8, mirar_atras),
        an("ganzua_loop", 2.0, ganzua, True),
        an("empujar", 1.4, empujar),
        an("leer_loop", 3.0, leer, True),
        an("recoger", 1.4, recoger),
    ]


CATALOGO = {
    "elias_preso": elias_comun() + [
        ciclo("andar_loop", ANDAR),
        ciclo("correr_loop", CORRER),
        an("agachado_loop", 3.0, lambda po, t: quieto(po, t, AGACHADO), True),
        ciclo("agachado_andar_loop", AGACHADO_ANDAR),
        an("levantarse", 2.8, levantarse),
        an("lanzar", 1.1, lanzar),
        an("esconderse", 0.7, esconderse),
        an("taquilla_loop", 3.0, taquilla, True),
        an("congelarse_loop", 2.0, congelarse, True),
        an("marcar_pared", 2.4, marcar_pared),
        an("palanca", 1.6, palanca),
        an("volante_loop", 2.4, volante, True),
        an("punzon_clavar", 0.8, punzon_clavar),
        an("pistola_apuntar_loop", 2.0, lambda po, t: apuntar_pistola(po, t), True),
        an("pistola_disparar", 0.5, lambda po, t: apuntar_pistola(po, t, retroceso=k(t, [(0, 0), (0.12, 1), (0.7, 0)]))),
        an("escopeta_apuntar_loop", 2.0, lambda po, t: apuntar_escopeta(po, t), True),
        an("escopeta_disparar", 0.9, lambda po, t: apuntar_escopeta(
            po, t, retroceso=k(t, [(0, 0), (0.08, 1), (0.4, 0)]), bombeo=k(t, [(0, 0), (0.45, 0), (0.6, 1), (0.8, 0)]))),
        an("cegado", 1.2, cegado),
        an("muerte_cuello", 2.4, muerte_cuello, pareja="el_uniforme/agarrar", distancia=0.6),
        an("muerte_placaje", 1.2, muerte_placaje, pareja="policia_patrullero/placaje", distancia=1.3),
        an("muerte_arrastrado", 1.6, muerte_arrastrado, pareja="aislado_a/atacar", distancia=0.7),
        an("muerte_golpe", 1.3, muerte_golpe, pareja="la_sentencia/golpe_vertical", distancia=1.6),
    ],
    "elias_civil": elias_comun() + [
        ciclo("andar_loop", ANDAR_PASADO),
        ciclo("correr_loop", CORRER_PASADO),
        ciclo("correr_mirando_atras_loop", CORRER_MIRANDO),
        an("derribar", 1.0, derribar),
        an("pasar_por_encima", 1.2, pasar_por_encima, desplazamiento=1.6),
        an("sentado_loop", 3.0, sentado, True),
        an("esconder_objeto", 1.6, esconder_objeto),
        an("muerte_placaje", 1.2, muerte_placaje, pareja="policia_patrullero/placaje", distancia=1.3),
    ],
    "el_uniforme": [
        quieto_loop(UNIFORME_QUIETO, escalonado=True),
        ciclo("andar_loop", UNIFORME_ANDAR, escalonado=True),
        an("recuento_loop", 4.0, recuento, True, True),
        ciclo("perseguir_loop", UNIFORME_PERSEGUIR, escalonado=True),
        an("agarrar", 2.4, agarrar_uniforme, escalonado=True, pareja="elias_preso/muerte_cuello", distancia=0.6),
        an("aturdido", 3.5, aturdido, escalonado=True),
    ],
    "el_vigilante": [
        an("quieto_loop", 4.0, lambda po, t: quieto(po, t, VIGILANTE_QUIETO), True, True),
        ciclo("andar_loop", VIGILANTE_ANDAR, escalonado=True),
        an("alerta", 1.2, alerta_vigilante, escalonado=True),
        an("aturdido", 3.0, aturdido, escalonado=True),
    ],
    "el_condenado": [
        quieto_loop(CONDENADO_QUIETO, escalonado=True),
        ciclo("acechar_loop", CONDENADO_ACECHAR, escalonado=True),
        an("atacar", 1.0, atacar_condenado, escalonado=True),
    ],
    "la_sentencia": [
        quieto_loop(SENTENCIA_QUIETO, segundos=3.5, escalonado=True),
        ciclo("andar_loop", SENTENCIA_ANDAR, escalonado=True),
        an("golpe_vertical", 2.2, golpe_vertical, escalonado=True, pareja="elias_preso/muerte_golpe", distancia=1.6),
        an("golpe_barrido", 1.8, golpe_barrido, escalonado=True),
        an("tambalearse", 1.6, tambalearse, escalonado=True),
        an("furia", 1.6, furia, escalonado=True),
    ],
    "el_director": [
        quieto_loop(DIRECTOR_QUIETO, segundos=5.0, escalonado=True),
        an("mirar_abajo", 2.5, mirar_abajo, escalonado=True),
    ],
    "policia_patrullero": [
        quieto_loop({"brazos": lambda po, t: brazos_porra(po, 0.25, 4.0)}),
        ciclo("andar_loop", POLICIA_ANDAR),
        ciclo("correr_loop", POLICIA_CORRER),
        an("silbato", 1.6, silbato),
        an("placaje", 1.1, placaje, pareja="elias_civil/muerte_placaje", distancia=1.3),
    ],
    "policia_tactico": [
        quieto_loop(TACTICO_QUIETO),
        ciclo("andar_loop", TACTICO_ANDAR),
    ],
    "guardia_penitenciario": [
        quieto_loop({"brazos": lambda po, t: brazos_porra(po, 0.25, 4.0)}),
        ciclo("andar_loop", GUARDIA_ANDAR),
        ciclo("correr_loop", GUARDIA_CORRER),
    ],
    "interrogador": [
        an("quieto_loop", 3.0, interrogador_apoyado, True),
        ciclo("andar_loop", dict(PRESO_ANDAR, v=1.0, T=1.0, brazos=brazos_atras)),
        an("golpe_mesa", 1.4, golpe_mesa),
    ],
    "verdugo": [
        quieto_loop({"abrir": 0.16, "inclinacion": 5.0, "separacion": 1.2}),
        ciclo("andar_loop", dict(PRESO_ANDAR, v=1.0, T=1.15, inclinacion=6.0, brazo_amp=10.0, ancho=1.15)),
    ],
    "alcaide": [
        quieto_loop({"brazos": brazos_atras, "inclinacion": -2.0, "cadera_pitch": -3.0}),
        an("hablar", 2.6, hablar),
    ],
}
for _preso in ("preso_generico_a", "preso_generico_b", "preso_generico_c"):
    CATALOGO[_preso] = [quieto_loop(), ciclo("andar_loop", PRESO_ANDAR)]
for _aislado in ("aislado_a", "aislado_b"):
    CATALOGO[_aislado] = [
        quieto_loop(AISLADO_QUIETO, escalonado=True),
        ciclo("andar_loop", AISLADO_ANDAR, escalonado=True),
        ciclo("correr_loop", AISLADO_CORRER, escalonado=True),
        an("atacar", 1.3, atacar_aislado, escalonado=True, pareja="elias_preso/muerte_arrastrado", distancia=0.7),
        an("escuchar", 1.6, escuchar, escalonado=True),
        an("morir", 1.4, morir_aislado, escalonado=True),
    ]


# ================================================================= Horneado ===

def curvas(accion):
    for capa in accion.layers:
        for tira in capa.strips:
            for bolsa in tira.channelbags:
                yield from bolsa.fcurves


def hornear(arm, po, datos):
    """Crea la acción, muestrea la pose, inserta claves y la guarda en una pista NLA silenciada."""
    nombre = datos["nombre"]
    fotogramas = max(2, int(round(datos["segundos"] * FPS)))
    paso = 4 if datos["escalonado"] else 2
    muestras = list(range(0, fotogramas + 1, paso))
    if muestras[-1] != fotogramas:
        muestras.append(fotogramas)
    ad = arm.animation_data_create()
    accion = bpy.data.actions.new(nombre)
    ad.action = accion
    previo = {}
    for f in muestras:
        po.reiniciar()
        datos["funcion"](po, f / fotogramas)
        po.aplicar()
        for n in HUESOS:
            pb = arm.pose.bones[n]
            q = pb.rotation_quaternion.copy()
            if n in previo and previo[n].dot(q) < 0.0:
                q.negate()
                pb.rotation_quaternion = q
            previo[n] = q
            pb.keyframe_insert("rotation_quaternion", frame=f, group=n)
        arm.pose.bones["cadera"].keyframe_insert("location", frame=f, group="cadera")
    interpolacion = "CONSTANT" if datos["escalonado"] else "BEZIER"
    for fc in curvas(accion):
        for clave in fc.keyframe_points:
            clave.interpolation = interpolacion
        fc.update()
    ad.action = None
    pista = ad.nla_tracks.new()
    pista.name = nombre
    pista.strips.new(nombre, 0, accion)
    pista.mute = True
    accion.use_fake_user = True
    return fotogramas


def limpiar(arm, nombres):
    """Quita acciones y pistas anteriores con esos nombres (para poder regenerar)."""
    ad = arm.animation_data
    if ad:
        ad.action = None
        for pista in list(ad.nla_tracks):
            if pista.name in nombres:
                ad.nla_tracks.remove(pista)
    for accion in list(bpy.data.actions):
        if accion.name in nombres or accion.name.split(".")[0] in nombres:
            bpy.data.actions.remove(accion)


def animar_personaje(clave):
    ruta = C.RAIZ / "personajes" / f"{clave}.blend"
    bpy.ops.wm.open_mainfile(filepath=str(ruta))
    escena = bpy.context.scene
    escena.render.fps = FPS
    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    lista = CATALOGO[clave]
    limpiar(arm, {a["nombre"] for a in lista})
    original = {pb.name: pb.matrix_basis.copy() for pb in arm.pose.bones}
    po = Pose(arm)
    salida = []
    for datos in lista:
        fotogramas = hornear(arm, po, datos)
        registro = {"nombre": datos["nombre"], "fotogramas": fotogramas, "segundos": round(fotogramas / FPS, 3),
                    "bucle": datos["bucle"], "a_pocos_fotogramas": datos["escalonado"]}
        registro.update(datos["info"])
        salida.append(registro)
        print(f"  {clave}: {datos['nombre']} ({fotogramas} fotogramas)")
    for pb in arm.pose.bones:
        pb.matrix_basis = original[pb.name]
    escena.frame_start, escena.frame_end = 0, max(r["fotogramas"] for r in salida)
    C.guardar_blend(ruta)
    return salida


def actualizar_manifiesto(resultados):
    ruta = C.RAIZ / "animaciones" / "manifiesto.json"
    os.makedirs(ruta.parent, exist_ok=True)
    datos = {}
    if ruta.exists():
        datos = json.loads(ruta.read_text(encoding="utf-8")).get("personajes", {})
    datos.update(resultados)
    manifiesto = {
        "fps": FPS,
        "nota": ("Animaciones en el sitio (Godot mueve el cuerpo). 'velocidad' = m/s para la que se diseñó el ciclo: "
                 "si el personaje va a otra velocidad, escalar la velocidad de reproducción. 'desplazamiento' = metros "
                 "que avanza la cadera (pasar_por_encima). 'pareja' = animación sincronizada del otro personaje y "
                 "'distancia' = metros entre ambos, cara a cara."),
        "personajes": datos,
    }
    ruta.write_text(json.dumps(manifiesto, ensure_ascii=False, indent=2), encoding="utf-8")
    print("MANIFIESTO", ruta)


if __name__ == "__main__":
    pedidos = C.argumentos() or list(CATALOGO)
    resultados = {}
    for clave in pedidos:
        print("== Animando:", clave)
        resultados[clave] = animar_personaje(clave)
    actualizar_manifiesto(resultados)
