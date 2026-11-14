"""El pasado: callejón lluvioso de «La huida» (referencia: Materiales/43f1fd2b-....png).

Genera:
  - assets/kit/kit_ciudad.blend: fachadas de ladrillo (dos variantes), farola de sodio, contenedor,
    cubo de basura, caja, verja, coche patrulla, cartel «SE BUSCA», prisión en la colina, lluvia.
  - assets/escenarios/callejon.blend: el callejón montado, con luz de sodio, luces de la patrulla y niebla.
  - assets/escenas/plano_callejon.blend + assets/renders/plano_callejon.png: Elías huye; los policías
    lo persiguen; al fondo, la patrulla y la prisión sobre la colina.

Uso:
    blender --background --factory-startup --python assets/scripts/callejon.py [-- --borrador]
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
import kit_prision as K  # noqa: E402
import plano_patio as PP  # noqa: E402

ANCHO_CALLE = 5.6
FACHADA = 6.0
PISO = 3.4
PISOS = 4


# ------------------------------------------------------------------ Texturas ---

def tex_ladrillo(semilla=400, tam=128):
    img = np.zeros((tam, tam, 3))
    rng = np.random.default_rng(semilla)
    alto_l, ancho_l = 8, 16
    for fila in range(tam // alto_l):
        desfase = (fila % 2) * ancho_l // 2
        for col in range(-1, tam // ancho_l + 1):
            x0 = col * ancho_l + desfase
            tono = np.array((0.36, 0.19, 0.13)) * rng.uniform(0.7, 1.15)
            y0 = fila * alto_l
            img[y0:y0 + alto_l - 1, max(x0, 0):max(min(x0 + ancho_l - 1, tam), 0)] = tono
    mortero = img.sum(axis=2) == 0
    img[mortero] = (0.16, 0.14, 0.12)
    n = C.ruido(tam, tam, semilla + 1, 4, celdas=4)
    img *= (0.75 + 0.45 * n[..., None])
    img = C.mezclar(img, (0.08, 0.06, 0.05), C.chorreones(tam, tam, semilla + 2, 35, 0.8) * 0.6)
    img += C.grano(tam, tam, semilla + 3, 0.025)
    return C.guardar_png("escenario/ladrillo.png", C.posterizar(img, 36))


def tex_asfalto(semilla=410, tam=128):
    n = C.ruido(tam, tam, semilla, 5, celdas=4)
    img = C.lienzo(tam, tam, (0.13, 0.13, 0.14)) * (0.65 + 0.6 * n[..., None])
    charcos = C.suave(C.ruido(tam, tam, semilla + 1, 3, celdas=3), 0.48, 0.62)
    img = C.mezclar(img, (0.03, 0.035, 0.045), charcos * 0.85)
    grietas = np.abs(C.ruido(tam, tam, semilla + 2, 4, celdas=5) - 0.5) < 0.012
    img[grietas] *= 0.4
    return C.guardar_png("escenario/asfalto.png", C.posterizar(img + C.grano(tam, tam, semilla, 0.02), 36))


def tex_ventanas_lejanas(semilla=420, alto=128, ancho=256):
    """Fachada lejana de la prisión: oscura con algunas ventanas encendidas."""
    img = C.lienzo(alto, ancho, (0.035, 0.035, 0.045)) * (0.8 + 0.4 * C.ruido(alto, ancho, semilla, 3)[..., None])
    rng = np.random.default_rng(semilla)
    for y in range(8, alto - 8, 12):
        for x in range(6, ancho - 6, 10):
            if rng.random() < 0.35:
                img[y:y + 5, x:x + 3] = np.array((0.95, 0.75, 0.45)) * rng.uniform(0.6, 1.0)
    return C.guardar_png("escenario/prision_lejana.png", img)


def tex_cartel():
    """Cartel «SE BUSCA» recortado del arte conceptual (autorizado en L3)."""
    fuente = C.leer_png(C.RAIZ.parent / "Materiales" / "43f1fd2b-88a8-4955-8ee6-d53549cea10e.png")
    recorte = fuente[215:545, 40:290]
    return C.guardar_png("referencia/cartel_se_busca.png", recorte)


def material_luz_volumen(nombre, color, fuerza, alfa):
    """Haz de luz falso: emisión semitransparente (focos de la prisión, lluvia)."""
    mat = bpy.data.materials.new(nombre)
    arbol = mat.node_tree
    for nodo in list(arbol.nodes):
        if nodo.type == "BSDF_PRINCIPLED":
            arbol.nodes.remove(nodo)
    em = arbol.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = (*color, 1)
    em.inputs["Strength"].default_value = fuerza
    tr = arbol.nodes.new("ShaderNodeBsdfTransparent")
    mezcla = arbol.nodes.new("ShaderNodeMixShader")
    mezcla.inputs["Fac"].default_value = alfa
    arbol.links.new(tr.outputs[0], mezcla.inputs[1])
    arbol.links.new(em.outputs[0], mezcla.inputs[2])
    salida = next(n for n in arbol.nodes if n.type == "OUTPUT_MATERIAL")
    arbol.links.new(mezcla.outputs[0], salida.inputs["Surface"])
    mat.surface_render_method = "BLENDED"
    return mat


def materiales_ciudad():
    m = {}
    m["ladrillo"] = C.material("MAT_Ladrillo", tex_ladrillo(), rugosidad=0.7, especular=0.4)
    m["asfalto"] = C.material("MAT_Asfalto_Mojado", tex_asfalto(), rugosidad=0.3, especular=0.5)
    m["metal"] = C.material("MAT_Metal_Escalera", K.tex_oxido("metal_escalera", (0.1, 0.1, 0.1), 430, oxido=0.6),
                            rugosidad=0.5, metalico=0.6)
    m["ventana"] = C.material("MAT_Ventana_Oscura", color=(0.02, 0.025, 0.03), rugosidad=0.1, especular=0.8)
    m["ventana_luz"] = C.material_emisivo("MAT_Ventana_Calida", (1.0, 0.68, 0.38), 1.2)
    m["sodio"] = C.material_emisivo("MAT_Farola_Sodio", (1.0, 0.62, 0.25), 60.0)
    m["contenedor"] = C.material("MAT_Contenedor", K.tex_oxido("contenedor", (0.12, 0.2, 0.15), 431, oxido=0.7),
                                 rugosidad=0.6, metalico=0.4)
    m["madera"] = C.material("MAT_Madera_Caja", K.tex_hormigon("madera", (0.3, 0.22, 0.14), 432, verde=0.0,
                                                             chorros=20, encofrado=True), rugosidad=0.8)
    m["coche"] = C.material("MAT_Coche_Patrulla", color=(0.03, 0.035, 0.05), rugosidad=0.25, especular=0.7,
                            metalico=0.3)
    m["coche_blanco"] = C.material("MAT_Coche_Puertas", color=(0.6, 0.6, 0.62), rugosidad=0.3, especular=0.6)
    m["neumatico"] = C.material("MAT_Neumatico", color=(0.02, 0.02, 0.02), rugosidad=0.8)
    m["faro"] = C.material_emisivo("MAT_Faro", (1.0, 0.95, 0.85), 40.0)
    m["rojo"] = C.material_emisivo("MAT_Sirena_Roja", (1.0, 0.05, 0.05), 45.0)
    m["azul"] = C.material_emisivo("MAT_Sirena_Azul", (0.1, 0.25, 1.0), 45.0)
    m["cartel"] = C.material("MAT_Cartel_Se_Busca", tex_cartel(), rugosidad=0.9)
    m["prision"] = C.material("MAT_Prision_Lejana", tex_ventanas_lejanas(), rugosidad=0.9)
    # Las ventanas encendidas de la textura emiten luz (se ven de noche a lo lejos).
    arbol = m["prision"].node_tree
    tex = next(n for n in arbol.nodes if n.type == "TEX_IMAGE")
    bsdf = next(n for n in arbol.nodes if n.type == "BSDF_PRINCIPLED")
    arbol.links.new(tex.outputs["Color"], bsdf.inputs["Emission Color"])
    bsdf.inputs["Emission Strength"].default_value = 3.0
    m["colina"] = C.material("MAT_Colina", color=(0.02, 0.022, 0.025), rugosidad=1.0)
    m["haz"] = material_luz_volumen("MAT_Haz_Foco", (0.85, 0.9, 1.0), 2.0, 0.12)
    m["lluvia"] = material_luz_volumen("MAT_Lluvia", (0.7, 0.75, 0.85), 0.6, 0.12)
    # Que se guarden aunque ninguna pieza del kit los use (el suelo los usa en el escenario).
    for mat in m.values():
        mat.use_fake_user = True
    return m


# -------------------------------------------------------------------- Piezas ---

def fachada(m, escalera=True, encendidas=(1, 5)):
    """Fachada de 6 m (eje X) y 4 pisos, mirando a -Y; origen en el suelo, esquina izquierda."""
    malla = C.Malla()
    claves = ["ladrillo", "ventana", "ventana_luz", "metal"]
    i = {k: n for n, k in enumerate(claves)}
    esc = 1 / 2.0
    malla.caja((0.0, 0.0, 0.0), (FACHADA, 0.4, 1.0), i["ladrillo"], esc)
    n = 0
    for p in range(PISOS):
        z0 = 1.0 + p * PISO
        filas = [(z0, z0 + 0.8), (z0 + 2.4, z0 + PISO)]
        for a, b in filas:
            malla.caja((0.0, 0.0, a), (FACHADA, 0.4, b), i["ladrillo"], esc)
        xs = [0.0, 1.0, 2.2, 3.8, 5.0, FACHADA]
        for k in range(0, len(xs) - 1, 2):
            malla.caja((xs[k], 0.0, z0 + 0.8), (xs[k + 1], 0.4, z0 + 2.4), i["ladrillo"], esc)
        for x0, x1 in ((1.0, 2.2), (3.8, 5.0)):
            mat = i["ventana_luz"] if n in encendidas else i["ventana"]
            malla.caja((x0, 0.25, z0 + 0.8), (x1, 0.3, z0 + 2.4), mat, 1.0)
            malla.caja((x0 - 0.05, -0.05, z0 + 0.75), (x1 + 0.05, 0.05, z0 + 0.82), i["ladrillo"], esc)
            n += 1
        if escalera and p > 0:
            # Plataforma de la escalera de incendios con barandilla y escala.
            malla.caja((0.6, -1.2, z0 - 0.1), (4.4, 0.0, z0), i["metal"], 2.0)
            for x in np.linspace(0.6, 4.4, 6):
                malla.caja((x - 0.02, -1.22, z0), (x + 0.02, -1.18, z0 + 0.95), i["metal"], 2.0)
            malla.caja((0.6, -1.23, z0 + 0.93), (4.4, -1.17, z0 + 0.98), i["metal"], 2.0)
            for t in range(8):
                malla.caja((3.6 + t * 0.04, -1.1, z0 - PISO + 0.1 + t * (PISO / 8)),
                           (3.9 + t * 0.04, -0.4, z0 - PISO + 0.14 + t * (PISO / 8)), i["metal"], 2.0)
    malla.caja((0.0, -0.3, PISOS * PISO + 1.0), (FACHADA, 0.4, PISOS * PISO + 1.3), i["ladrillo"], esc)
    malla.cilindro((5.7, -0.12, 0.0), 0.06, PISOS * PISO + 1.0, lados=6, material=i["metal"])
    return malla, [m[k] for k in claves]


def farola(m):
    """Farola de pared con brazo curvo (de la referencia)."""
    malla = C.Malla()
    malla.caja((-0.08, 0.0, -0.3), (0.08, 0.1, 0.3), 0, 2.0)
    malla.caja((-0.03, -1.0, 0.25), (0.03, 0.0, 0.31), 0, 2.0)
    malla.caja((-0.18, -1.2, 0.0), (0.18, -0.85, 0.3), 0, 2.0)
    malla.caja((-0.13, -1.15, -0.03), (0.13, -0.9, 0.0), 1, 2.0)
    return malla, [m["metal"], m["sodio"]]


def contenedor(m):
    malla = C.Malla()
    malla.caja((0.0, 0.0, 0.2), (1.9, 1.1, 1.25), 0, 1.0)
    malla.caja((-0.02, -0.02, 1.25), (1.92, 1.12, 1.32), 0, 1.0)
    for x in (0.15, 1.75):
        for y in (0.15, 0.95):
            malla.cilindro((x, y, 0.0), 0.08, 0.2, lados=6, material=1)
    return malla, [m["contenedor"], m["metal"]]


def cubo(m):
    malla = C.Malla()
    malla.cilindro((0, 0, 0), 0.28, 0.75, lados=8, material=0, escala_uv=1.0)
    malla.cilindro((0, 0, 0.75), 0.31, 0.06, lados=8, material=0, escala_uv=1.0)
    return malla, [m["metal"]]


def caja_madera(m):
    malla = C.Malla()
    malla.caja((0, 0, 0), (0.7, 0.6, 0.6), 0, 1.4)
    return malla, [m["madera"]]


def verja(m):
    malla = C.Malla()
    K.reja_puerta(malla, 0.0, ANCHO_CALLE, 0.0, 2.8, 0)
    return malla, [m["metal"]]


def coche_patrulla(m):
    """Coche patrulla de los 80/90, mirando a -Y."""
    malla = C.Malla()
    c = ["coche", "coche_blanco", "neumatico", "faro", "rojo", "azul", "ventana"]
    i = {k: n for n, k in enumerate(c)}
    malla.caja((-0.9, -2.3, 0.35), (0.9, 2.3, 0.95), i["coche"], 1.0)
    malla.caja((-0.91, -0.8, 0.4), (0.91, 0.9, 0.9), i["coche_blanco"], 1.0)
    malla.caja((-0.8, -0.6, 0.95), (0.8, 1.2, 1.45), i["ventana"], 1.0)
    malla.caja((-0.75, -0.55, 1.45), (0.75, 1.15, 1.5), i["coche"], 1.0)
    malla.caja((-0.55, 0.1, 1.5), (-0.05, 0.4, 1.62), i["rojo"], 2.0)
    malla.caja((0.05, 0.1, 1.5), (0.55, 0.4, 1.62), i["azul"], 2.0)
    for x in (-0.6, 0.6):
        malla.caja((x - 0.2, -2.32, 0.6), (x + 0.2, -2.28, 0.78), i["faro"], 2.0)
    for x in (-0.92, 0.92):
        for y in (-1.5, 1.5):
            malla.cilindro((x - 0.12 if x < 0 else x - 0.12, y, 0.35), 0.35, 0.24, lados=8,
                           material=i["neumatico"], eje="x")
    return malla, [m[k] for k in c]


def cartel(m):
    malla = C.Malla()
    malla.cuadrilatero(Vector((0, 0, 0)), Vector((0.62, 0, 0)), Vector((0.62, 0, 0.82)), Vector((0, 0, 0.82)), 0)
    return malla, [m["cartel"]]


def prision_colina(m):
    """Silueta lejana: colina y penitenciaría con ventanas encendidas y dos haces de foco."""
    malla = C.Malla()
    lados = 10
    anillos = []
    for z, r in ((0.0, 120.0), (25.0, 80.0), (40.0, 45.0)):
        anillos.append([malla.vertice((math.cos(2 * math.pi * k / lados) * r,
                                       math.sin(2 * math.pi * k / lados) * r * 0.5, z)) for k in range(lados)])
    for a in range(2):
        for k in range(lados):
            k2 = (k + 1) % lados
            malla.cara([anillos[a][k], anillos[a][k2], anillos[a + 1][k2], anillos[a + 1][k]],
                       [(0, 0), (1, 0), (1, 1), (0, 1)], 0)
    malla.cara(anillos[2], [(0.5, 0.5)] * lados, 0)
    for x0, x1, y0, y1, z1 in ((-40, 40, -10, 10, 62), (-15, 15, -8, 8, 80), (-55, -42, -6, 6, 70),
                               (42, 55, -6, 6, 70)):
        malla.caja((x0, y0, 40.0), (x1, y1, z1), 1, 1 / 40.0)
    for x, r in ((-25, 0.5), (30, -0.4)):
        base = Vector((x, -10, 75))
        punta = base + Vector((r * 60, -20, 140))
        eje = (punta - base).normalized()
        u = eje.cross(Vector((1, 0, 0))).normalized()
        v = eje.cross(u).normalized()
        anillo_a = [malla.vertice(base + (u * math.cos(t) + v * math.sin(t)) * 1.0)
                    for t in np.linspace(0, 2 * math.pi, 8, endpoint=False)]
        anillo_b = [malla.vertice(punta + (u * math.cos(t) + v * math.sin(t)) * 18.0)
                    for t in np.linspace(0, 2 * math.pi, 8, endpoint=False)]
        for k in range(8):
            malla.cara([anillo_a[k], anillo_a[(k + 1) % 8], anillo_b[(k + 1) % 8], anillo_b[k]],
                       [(0, 0), (1, 0), (1, 1), (0, 1)], 2)
    return malla, [m["colina"], m["prision"], m["haz"]]


def lluvia(m, cantidad=4500, caja=((-2.8, 2.5, 0), (2.8, 30, 14)), semilla=440):
    rnd = C.aleatorio(semilla)
    malla = C.Malla()
    (x0, y0, z0), (x1, y1, z1) = caja
    inclinacion = Vector((0.05, -0.12, 1.0)).normalized()
    for _ in range(cantidad):
        p = Vector((rnd.uniform(x0, x1), rnd.uniform(y0, y1), rnd.uniform(z0, z1)))
        largo = rnd.uniform(0.35, 0.7)
        lado = Vector((0.0035, 0, 0))
        q = p + inclinacion * largo
        malla.cuadrilatero(p - lado, p + lado, q + lado, q - lado, 0)
    return malla, [m["lluvia"]]


def crear_kit():
    C.reiniciar()
    m = materiales_ciudad()
    raiz = bpy.context.scene.collection
    x = 0.0
    for nombre, datos in (("Kit_Fachada_A", fachada(m, True, (1, 5))), ("Kit_Fachada_B", fachada(m, False, (2, 3, 6))),
                          ("Kit_Farola", farola(m)), ("Kit_Contenedor", contenedor(m)), ("Kit_Cubo", cubo(m)),
                          ("Kit_Caja", caja_madera(m)), ("Kit_Verja", verja(m)), ("Kit_Coche_Patrulla", coche_patrulla(m)),
                          ("Kit_Cartel_Se_Busca", cartel(m)), ("Kit_Prision_Colina", prision_colina(m)),
                          ("Kit_Lluvia", lluvia(m))):
        col = C.coleccion(nombre, raiz)
        malla, mats = datos
        obj = malla.a_objeto(nombre, mats, col)
        obj.data.name = f"M_{nombre}"
        obj.location = (x, 0, 0)
        x += 8
    C.guardar_blend(C.RAIZ / "kit" / "kit_ciudad.blend")


# -------------------------------------------------------------------- Escenario ---

def crear_escenario():
    escena = C.reiniciar()
    with bpy.data.libraries.load(str(C.RAIZ / "kit" / "kit_ciudad.blend"), link=True,
                                 relative=True) as (origen, destino):
        destino.meshes = [n for n in origen.meshes if n.startswith("M_Kit_")]
        destino.materials = ["MAT_Asfalto_Mojado"]
    mm = {x.name: x for x in destino.meshes}
    asfalto = destino.materials[0]
    col = C.coleccion("Callejon")

    def poner(nombre, malla, pos, rot=0.0, escala=1.0):
        obj = bpy.data.objects.new(nombre, mm[malla])
        col.objects.link(obj)
        obj.location = pos
        obj.rotation_euler = (0, 0, rot)
        obj.scale = (escala,) * 3
        return obj
    medio = ANCHO_CALLE / 2
    # Fachadas a ambos lados del callejón (eje +Y), alternando variantes.
    for j in range(6):
        y = -6.0 + j * FACHADA
        # La fachada mira a -Y en el kit: girada 90° mira a +X (lado oeste); -90°, a -X (lado este).
        poner(f"Fachada_O_{j}", "M_Kit_Fachada_" + "AB"[j % 2], (-medio, y, 0), math.pi / 2)
        poner(f"Fachada_E_{j}", "M_Kit_Fachada_" + "BA"[j % 2], (medio, y + FACHADA, 0), -math.pi / 2)
    suelo = C.Malla()
    suelo.caja((-medio - 1, -8, -0.3), (medio + 1, 40, 0.0), 0, 1 / 2.0)
    suelo.a_objeto("Suelo_Callejon", [asfalto], col)
    poner("Cartel_Se_Busca", "M_Kit_Cartel_Se_Busca", (-medio + 0.02, 0.4, 1.3), math.pi / 2)
    for i, (y, z) in enumerate(((3.5, 4.2), (16.0, 4.2))):
        poner(f"Farola_{i}", "M_Kit_Farola", (-medio, y, z), -math.pi / 2)
    poner("Contenedor", "M_Kit_Contenedor", (medio - 1.3, 5.5, 0), 0.05)
    for i, (x, y, rot) in enumerate(((medio - 0.5, 8.0, 0.3), (medio - 0.8, 3.0, 0.0), (-medio + 0.5, 10.5, 0.0))):
        poner(f"Cubo_{i}", "M_Kit_Cubo", (x, y, 0), rot)
    poner("Cubo_Volcado", "M_Kit_Cubo", (-0.6, 7.0, 0.3), 0.0).rotation_euler = (math.radians(85), 0, 0.6)
    for i, (x, y) in enumerate(((-medio + 0.6, 2.0), (-medio + 0.5, 12.8), (-medio + 0.9, 13.3))):
        poner(f"Caja_{i}", "M_Kit_Caja", (x, y, 0), 0.2 * i)
    poner("Coche_Patrulla", "M_Kit_Coche_Patrulla", (1.2, 21.0, 0), 0.15)
    poner("Prision_Colina", "M_Kit_Prision_Colina", (14.0, 150.0, -12.0), escala=0.75)
    poner("Lluvia", "M_Kit_Lluvia", (0, 0, 0))
    # Luces: sodio de las farolas, sirenas y faros de la patrulla, luna fría.
    def luz(nombre, tipo, energia, color, pos, apuntar=None, **p):
        d = bpy.data.lights.new(nombre, tipo)
        d.energy = energia
        d.color = color
        for k, v in p.items():
            setattr(d, k, v)
        o = bpy.data.objects.new(nombre, d)
        col.objects.link(o)
        o.location = pos
        if apuntar:
            o.rotation_euler = (Vector(apuntar) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
        return o
    luz("Sodio_0", "SPOT", 900.0, (1.0, 0.6, 0.25), (-medio + 1.05, 3.5, 4.1), (-0.5, 3.0, 0.0),
        spot_size=math.radians(110), spot_blend=0.8, shadow_soft_size=0.15)
    luz("Sodio_1", "SPOT", 700.0, (1.0, 0.6, 0.25), (-medio + 1.05, 16.0, 4.1), (0.0, 15.0, 0.0),
        spot_size=math.radians(110), spot_blend=0.8, shadow_soft_size=0.15)
    luz("Sirena_Roja", "POINT", 250.0, (1.0, 0.05, 0.05), (0.85, 21.2, 1.9), shadow_soft_size=0.2)
    luz("Sirena_Azul", "POINT", 250.0, (0.1, 0.25, 1.0), (1.6, 21.2, 1.9), shadow_soft_size=0.2)
    luz("Faros", "SPOT", 250.0, (1.0, 0.95, 0.85), (1.1, 18.6, 0.7), (0.0, 0.0, 0.3),
        spot_size=math.radians(45), spot_blend=0.5)
    luz("Luna", "SUN", 0.35, (0.55, 0.6, 0.85), (0, 0, 30), (0.3, 1.0, -1.0))
    mundo = bpy.data.worlds.new("Mundo_Callejon")
    escena.world = mundo
    fondo = next(n for n in mundo.node_tree.nodes if n.type == "BACKGROUND")
    fondo.inputs["Color"].default_value = (0.03, 0.025, 0.045, 1.0)
    vol = C.Malla()
    vol.caja((-medio, -6, 0.0), (medio, 34, 16))
    obj_vol = vol.a_objeto("Niebla_Lluvia", [], col)
    mat = bpy.data.materials.new("MAT_Niebla_Lluvia")
    arbol = mat.node_tree
    for nodo in list(arbol.nodes):
        if nodo.type == "BSDF_PRINCIPLED":
            arbol.nodes.remove(nodo)
    v = arbol.nodes.new("ShaderNodeVolumePrincipled")
    v.inputs["Color"].default_value = (0.8, 0.75, 0.8, 1)
    v.inputs["Density"].default_value = 0.018
    v.inputs["Anisotropy"].default_value = 0.5
    arbol.links.new(v.outputs["Volume"], next(n for n in arbol.nodes if n.type == "OUTPUT_MATERIAL").inputs["Volume"])
    obj_vol.data.materials.append(mat)
    obj_vol.display_type = "BOUNDS"
    C.guardar_blend(C.RAIZ / "escenarios" / "callejon.blend")


# ------------------------------------------------------------------------ Plano ---

def pose_correr(arm, angulo, mirar_atras=0.0, alcanzar=False):
    """Carrera: tronco inclinado, zancada larga, brazos en oposición."""
    arm.rotation_euler = (0, 0, math.radians(angulo))
    bpy.context.view_layer.update()
    f = PP.mirar(angulo)
    izq = Vector((0, 0, 1)).cross(f)
    arriba = Vector((0, 0, 1))
    H.apuntar(arm, "columna", arriba + f * 0.2)
    H.apuntar(arm, "pecho", arriba + f * 0.3)
    H.apuntar(arm, "cuello", arriba + f * 0.15)
    H.apuntar(arm, "cabeza", arriba + f * 0.1, giro=math.radians(mirar_atras))
    H.apuntar(arm, "muslo.L", -arriba + f * 0.75)
    H.apuntar(arm, "pierna.L", -arriba + f * 0.15)
    H.apuntar(arm, "pie.L", f + -arriba * 0.3)
    H.apuntar(arm, "muslo.R", -arriba - f * 0.55)
    H.apuntar(arm, "pierna.R", -arriba * 0.4 - f * 1.0)
    H.apuntar(arm, "pie.R", -f * 0.5 - arriba)
    if alcanzar:
        H.apuntar(arm, "brazo.R", f + arriba * 0.15 - izq * 0.1)
        H.apuntar(arm, "antebrazo.R", f + arriba * 0.25)
        H.apuntar(arm, "mano.R", f + arriba * 0.2)
    else:
        H.apuntar(arm, "brazo.R", -arriba + f * 0.8 - izq * 0.15)
        H.apuntar(arm, "antebrazo.R", arriba * 0.3 + f * 1.0)
        H.apuntar(arm, "mano.R", arriba * 0.4 + f * 0.8)
    H.apuntar(arm, "brazo.L", -arriba - f * 0.7 + izq * 0.15)
    H.apuntar(arm, "antebrazo.L", -arriba * 0.5 - f * 0.9)
    H.apuntar(arm, "mano.L", -arriba * 0.6 - f * 0.8)


def crear_plano(borrador=False):
    escena = C.reiniciar()
    callejon = PP.enlazar_coleccion(C.RAIZ / "escenarios" / "callejon.blend", "Callejon")
    escena.collection.children.link(callejon)
    with bpy.data.libraries.load(str(C.RAIZ / "escenarios" / "callejon.blend"), link=True,
                                 relative=True) as (origen, destino):
        destino.worlds = ["Mundo_Callejon"]
    escena.world = destino.worlds[0]
    _, elias = PP.personaje("elias_civil", "Elias_Civil", escena)
    elias.location = (-0.9, 1.9, 0.0)
    pose_correr(elias, -12, mirar_atras=70)
    for i, (x, y, alcanzar) in enumerate(((0.6, 5.0, True), (1.4, 8.6, False), (-0.6, 11.0, True))):
        _, poli = PP.personaje("policia_patrullero", "Policia_Patrullero", escena)
        poli.location = (x, y, 0.0)
        pose_correr(poli, 2 + i * 6, alcanzar=alcanzar)
    cam = PP.camara("Camara_Callejon", (0.35, -1.6, 1.35), (0.6, 30.0, 4.5), 24)
    escena.camera = cam
    PP.luz("Clave_Elias", "AREA", 60.0, (1.0, 0.65, 0.35), (-1.8, -0.2, 2.6), apuntar_a=(-0.9, 1.9, 1.4), size=1.0)
    if borrador:
        C.configurar_render(escena, 640, 360, muestras=12, exposicion=-0.2)
    else:
        C.configurar_render(escena, 1672, 941, muestras=48, exposicion=-0.2)
    C.guardar_blend(C.RAIZ / "escenas" / "plano_callejon.blend")
    sufijo = "_borrador" if borrador else ""
    C.renderizar(escena, C.RAIZ / "renders" / f"plano_callejon{sufijo}.png")


if __name__ == "__main__":
    args = C.argumentos()
    if "--solo-plano" not in args:
        crear_kit()
        crear_escenario()
    crear_plano(borrador="--borrador" in args)
