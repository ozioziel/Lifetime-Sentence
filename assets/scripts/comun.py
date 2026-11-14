"""Funciones comunes para generar los assets de Lifetime Sentence en Blender.

Todos los scripts de esta carpeta se ejecutan con Blender en segundo plano:

    blender --background --factory-startup --python assets/scripts/<script>.py

Generan archivos .blend normales que el equipo puede abrir y editar a mano.
Hecho con IA (Claude). Registrado en Materiales/recursos_y_creditos.md.
"""
import math
import os
import random
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector

RAIZ = Path(__file__).resolve().parents[1]          # carpeta assets/
DIR_TEX = RAIZ / "texturas"
BLENDER_VERSION = bpy.app.version


# ----------------------------------------------------------------- Escena ---

def reiniciar():
    """Deja Blender vacío y con unidades métricas."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    escena = bpy.context.scene
    escena.unit_settings.system = "METRIC"
    return escena


def coleccion(nombre, padre=None):
    col = bpy.data.collections.new(nombre)
    (padre or bpy.context.scene.collection).children.link(col)
    return col


def guardar_blend(ruta):
    """Guarda el .blend con rutas relativas (para que la carpeta assets se pueda mover)."""
    ruta = str(ruta)
    os.makedirs(os.path.dirname(ruta), exist_ok=True)
    bpy.context.preferences.filepaths.save_version = 0      # sin copias .blend1
    bpy.ops.wm.save_as_mainfile(filepath=ruta, compress=True)
    try:
        bpy.ops.file.make_paths_relative()
    except RuntimeError as error:
        print("Aviso make_paths_relative:", error)
    bpy.ops.wm.save_as_mainfile(filepath=ruta, compress=True)
    print("GUARDADO", ruta)


def argumentos():
    """Argumentos que van detrás de «--» en la línea de órdenes de Blender."""
    if "--" in sys.argv:
        return sys.argv[sys.argv.index("--") + 1:]
    return []


# --------------------------------------------------------------- Texturas ---

def ruido(alto, ancho, semilla, octavas=5, persistencia=0.55, celdas=4):
    """Ruido de valor entre 0 y 1 que se repite sin costuras (array alto x ancho)."""
    rng = np.random.default_rng(semilla)
    total = np.zeros((alto, ancho))
    amplitud, suma = 1.0, 0.0
    for octava in range(octavas):
        cy = max(1, min(int(celdas * 2 ** octava), alto))
        cx = max(1, min(int(celdas * 2 ** octava * ancho / alto), ancho))
        rejilla = rng.random((cy, cx))
        py = np.arange(alto) * cy / alto
        px = np.arange(ancho) * cx / ancho
        y0 = np.floor(py).astype(int) % cy
        x0 = np.floor(px).astype(int) % cx
        y1, x1 = (y0 + 1) % cy, (x0 + 1) % cx
        fy = (py - np.floor(py))[:, None]
        fx = (px - np.floor(px))[None, :]
        fy = fy * fy * (3 - 2 * fy)
        fx = fx * fx * (3 - 2 * fx)
        a = rejilla[np.ix_(y0, x0)]
        b = rejilla[np.ix_(y0, x1)]
        c = rejilla[np.ix_(y1, x0)]
        d = rejilla[np.ix_(y1, x1)]
        total += ((a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy) * amplitud
        suma += amplitud
        amplitud *= persistencia
    return total / suma


def suave(valor, minimo, maximo):
    t = np.clip((valor - minimo) / (maximo - minimo), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def mezclar(base, color, mascara):
    """Mezcla un color (o imagen) sobre la imagen base según una máscara 0..1."""
    color = np.asarray(color, dtype=float)
    return base * (1 - mascara[..., None]) + color * mascara[..., None]


def lienzo(alto, ancho, color):
    return np.ones((alto, ancho, 3)) * np.asarray(color, dtype=float)


def grano(alto, ancho, semilla, fuerza=0.03):
    return np.random.default_rng(semilla).normal(0.0, fuerza, (alto, ancho))[..., None]


def chorreones(alto, ancho, semilla, cantidad, largo):
    """Manchas verticales de humedad que bajan desde arriba (máscara 0..1)."""
    rng = np.random.default_rng(semilla)
    mascara = np.zeros((alto, ancho))
    for _ in range(cantidad):
        x = rng.integers(0, ancho)
        y0 = rng.integers(0, alto)
        longitud = int(rng.uniform(0.2, 1.0) * largo * alto)
        ancho_ch = rng.integers(1, 3)
        intensidad = rng.uniform(0.4, 1.0)
        for y in range(longitud):
            yy = (y0 + y) % alto
            mascara[yy, (x + np.arange(ancho_ch)) % ancho] = np.maximum(
                mascara[yy, (x + np.arange(ancho_ch)) % ancho],
                (1 - y / max(longitud, 1)) * intensidad)
    return mascara


def manchas(alto, ancho, semilla, cantidad, radio_min, radio_max, irregular=0.5):
    """Manchas redondeadas irregulares (máscara 0..1)."""
    rng = np.random.default_rng(semilla)
    yy, xx = np.mgrid[0:alto, 0:ancho]
    mascara = np.zeros((alto, ancho))
    deformacion = ruido(alto, ancho, semilla + 99, octavas=3, celdas=4)
    for _ in range(cantidad):
        cy, cx = rng.uniform(0, alto), rng.uniform(0, ancho)
        r = rng.uniform(radio_min, radio_max)
        dy = np.minimum(np.abs(yy - cy), alto - np.abs(yy - cy))
        dx = np.minimum(np.abs(xx - cx), ancho - np.abs(xx - cx))
        d = np.sqrt(dx * dx + dy * dy) / r + (deformacion - 0.5) * irregular
        mascara = np.maximum(mascara, suave(1.0 - d, 0.0, 0.35))
    return mascara


def posterizar(imagen, niveles=24):
    return np.round(np.clip(imagen, 0, 1) * niveles) / niveles


def guardar_png(ruta_relativa, imagen):
    """Guarda un array alto x ancho x 3 (fila 0 = arriba, valores sRGB 0..1) en assets/texturas."""
    alto, ancho = imagen.shape[:2]
    rgba = np.ones((alto, ancho, 4), dtype=np.float32)
    rgba[..., :3] = np.clip(imagen[..., :3], 0.0, 1.0)
    if imagen.shape[2] == 4:
        rgba[..., 3] = np.clip(imagen[..., 3], 0.0, 1.0)
    ruta = DIR_TEX / ruta_relativa
    ruta.parent.mkdir(parents=True, exist_ok=True)
    temporal = bpy.data.images.new("_tmp_guardar", ancho, alto, alpha=True)
    temporal.pixels.foreach_set(np.flipud(rgba).ravel())
    temporal.filepath_raw = str(ruta)
    temporal.file_format = "PNG"
    temporal.save()
    bpy.data.images.remove(temporal)
    return ruta


def leer_png(ruta):
    """Lee un PNG como array alto x ancho x 3 (fila 0 = arriba, valores 0..1)."""
    img = bpy.data.images.load(str(ruta), check_existing=False)
    ancho, alto = img.size
    pix = np.array(img.pixels[:], dtype=np.float32).reshape(alto, ancho, 4)[::-1, :, :3]
    bpy.data.images.remove(img)
    return pix


_MUESTRAS = {}


def muestra(nombre, alto, ancho, color_objetivo=None, repeticiones=1.0, contraste=1.0):
    """Textura de referencia (assets/texturas/referencia/<nombre>.png) repetida sobre alto x ancho.

    color_objetivo: el color medio se ajusta a este (las muestras traen la luz de la imagen).
    repeticiones: cuántas veces cabe la muestra a lo ancho.
    """
    if nombre not in _MUESTRAS:
        _MUESTRAS[nombre] = leer_png(DIR_TEX / "referencia" / f"{nombre}.png")
    fuente = _MUESTRAS[nombre]
    # El PNG es un mosaico 2 x 2 en espejo; se usa solo el recorte original (sin simetrías).
    fuente = fuente[:fuente.shape[0] // 2, :fuente.shape[1] // 2]
    fh, fw = fuente.shape[:2]
    paso = fw * repeticiones / ancho          # píxeles de la muestra por píxel de salida
    ys = (np.arange(alto) * paso).astype(int)
    xs = (np.arange(ancho) * paso).astype(int)
    img = fuente[np.ix_(ys % fh, xs % fw)]
    if color_objetivo is not None:
        media = img.reshape(-1, 3).mean(axis=0) + 1e-4
        img = (img - media) * contraste + media
        img = img * (np.asarray(color_objetivo) / media)
    return np.clip(img, 0, 1)


def cargar_imagen(ruta):
    imagen = bpy.data.images.load(str(ruta), check_existing=True)
    imagen.reload()
    return imagen


# -------------------------------------------------------------- Materiales ---

def _bsdf(material):
    return next(n for n in material.node_tree.nodes if n.type == "BSDF_PRINCIPLED")


def material(nombre, imagen=None, color=(0.5, 0.5, 0.5), rugosidad=0.85, metalico=0.0,
             especular=0.3, emision=None, fuerza_emision=0.0, alfa=False, tinte=None,
             escala_uv=None):
    """Material con textura pixelada (interpolación «Closest», como la PS1).

    imagen: ruta de un PNG o imagen de Blender. tinte: color que multiplica la textura.
    """
    mat = bpy.data.materials.get(nombre)
    if mat:
        return mat
    mat = bpy.data.materials.new(nombre)
    arbol = mat.node_tree
    bsdf = _bsdf(mat)
    bsdf.inputs["Roughness"].default_value = rugosidad
    bsdf.inputs["Metallic"].default_value = metalico
    bsdf.inputs["Specular IOR Level"].default_value = especular
    if imagen is not None:
        if not isinstance(imagen, bpy.types.Image):
            imagen = cargar_imagen(imagen)
        tex = arbol.nodes.new("ShaderNodeTexImage")
        tex.image = imagen
        tex.interpolation = "Closest"
        tex.location = (-500, 250)
        salida_color = tex.outputs["Color"]
        if escala_uv:
            coord = arbol.nodes.new("ShaderNodeTexCoord")
            mapeo = arbol.nodes.new("ShaderNodeMapping")
            mapeo.inputs["Scale"].default_value = (escala_uv, escala_uv, 1.0)
            arbol.links.new(coord.outputs["UV"], mapeo.inputs["Vector"])
            arbol.links.new(mapeo.outputs["Vector"], tex.inputs["Vector"])
            coord.location, mapeo.location = (-1000, 250), (-750, 250)
        if tinte is not None:
            mezcla = arbol.nodes.new("ShaderNodeMix")
            mezcla.data_type = "RGBA"
            mezcla.blend_type = "MULTIPLY"
            mezcla.inputs["Factor"].default_value = 1.0
            arbol.links.new(salida_color, mezcla.inputs["A"])
            mezcla.inputs["B"].default_value = (*tinte, 1.0)
            mezcla.location = (-250, 250)
            salida_color = mezcla.outputs["Result"]
        arbol.links.new(salida_color, bsdf.inputs["Base Color"])
        if alfa:
            arbol.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
            mat.surface_render_method = "DITHERED"
    else:
        bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    if emision is not None:
        bsdf.inputs["Emission Color"].default_value = (*emision, 1.0)
        bsdf.inputs["Emission Strength"].default_value = fuerza_emision
    return mat


def material_emisivo(nombre, color, fuerza):
    """Material que solo emite luz (tubos fluorescentes, ventanas, tragaluz)."""
    mat = bpy.data.materials.get(nombre)
    if mat:
        return mat
    mat = bpy.data.materials.new(nombre)
    arbol = mat.node_tree
    for nodo in list(arbol.nodes):
        if nodo.type == "BSDF_PRINCIPLED":
            arbol.nodes.remove(nodo)
    emision = arbol.nodes.new("ShaderNodeEmission")
    emision.inputs["Color"].default_value = (*color, 1.0)
    emision.inputs["Strength"].default_value = fuerza
    salida = next(n for n in arbol.nodes if n.type == "OUTPUT_MATERIAL")
    arbol.links.new(emision.outputs["Emission"], salida.inputs["Surface"])
    return mat


# ------------------------------------------------------------------ Mallas ---

class Malla:
    """Acumula vértices, caras, UV, materiales y pesos, y crea un objeto de Blender."""

    def __init__(self):
        self.vertices = []
        self.caras = []          # (índices, uvs, material)
        self.grupos = {}         # nombre de hueso -> {índice: peso}

    def vertice(self, posicion, pesos=None):
        self.vertices.append(Vector(posicion))
        indice = len(self.vertices) - 1
        if pesos:
            for hueso, peso in pesos.items():
                if peso > 0.001:
                    self.grupos.setdefault(hueso, {})[indice] = peso
        return indice

    def cara(self, indices, uvs, material=0):
        self.caras.append((list(indices), [tuple(uv) for uv in uvs], material))

    # --- Primitivas para escenario (UV proyectada desde el mundo) ---------------

    def caja(self, minimo, maximo, material=0, escala_uv=0.5, caras_omitidas=(), pesos=None,
             desplazamiento_uv=(0.0, 0.0)):
        """Caja alineada a los ejes. UV = posición del mundo x escala (densidad de píxel constante).

        caras_omitidas: subconjunto de {"-x","+x","-y","+y","-z","+z"}.
        """
        x0, y0, z0 = minimo
        x1, y1, z1 = maximo
        p = [Vector(v) for v in [
            (x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
            (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]]
        caras = {
            "-y": ([0, 1, 5, 4], "xz"), "+y": ([2, 3, 7, 6], "xz"),
            "-x": ([3, 0, 4, 7], "yz"), "+x": ([1, 2, 6, 5], "yz"),
            "-z": ([3, 2, 1, 0], "xy"), "+z": ([4, 5, 6, 7], "xy"),
        }
        du, dv = desplazamiento_uv
        for nombre, (orden, plano) in caras.items():
            if nombre in caras_omitidas:
                continue
            indices = [self.vertice(p[i], pesos) for i in orden]
            uvs = []
            for i in orden:
                v = p[i]
                if plano == "xz":
                    uvs.append((v.x * escala_uv + du, v.z * escala_uv + dv))
                elif plano == "yz":
                    uvs.append((v.y * escala_uv + du, v.z * escala_uv + dv))
                else:
                    uvs.append((v.x * escala_uv + du, v.y * escala_uv + dv))
            self.cara(indices, uvs, material)

    def cuadrilatero(self, a, b, c, d, material=0, uvs=None):
        indices = [self.vertice(p) for p in (a, b, c, d)]
        self.cara(indices, uvs or [(0, 0), (1, 0), (1, 1), (0, 1)], material)

    def cilindro(self, centro_base, radio, alto, lados=8, material=0, escala_uv=0.5, tapas=True,
                 eje="z"):
        """Cilindro de pocos lados (barrotes, postes, tuberías)."""
        cx, cy, cz = centro_base
        anillos = []
        for nivel in (0.0, alto):
            anillo = []
            for k in range(lados):
                a = 2 * math.pi * k / lados
                if eje == "z":
                    pos = (cx + radio * math.cos(a), cy + radio * math.sin(a), cz + nivel)
                elif eje == "x":
                    pos = (cx + nivel, cy + radio * math.cos(a), cz + radio * math.sin(a))
                else:
                    pos = (cx + radio * math.cos(a), cy + nivel, cz + radio * math.sin(a))
                anillo.append(self.vertice(pos))
            anillos.append(anillo)
        perimetro = 2 * math.pi * radio
        for k in range(lados):
            k2 = (k + 1) % lados
            u0 = k / lados * perimetro * escala_uv
            u1 = (k + 1) / lados * perimetro * escala_uv
            self.cara([anillos[0][k], anillos[0][k2], anillos[1][k2], anillos[1][k]],
                      [(u0, 0), (u1, 0), (u1, alto * escala_uv), (u0, alto * escala_uv)], material)
        if tapas:
            self.cara(list(reversed(anillos[0])), [(0.5, 0.5)] * lados, material)
            self.cara(anillos[1], [(0.5, 0.5)] * lados, material)

    def unir(self, otra):
        """Añade otra Malla a esta (copiando pesos)."""
        base = len(self.vertices)
        self.vertices.extend(otra.vertices)
        for indices, uvs, mat in otra.caras:
            self.caras.append(([i + base for i in indices], uvs, mat))
        for hueso, pesos in otra.grupos.items():
            destino = self.grupos.setdefault(hueso, {})
            for i, w in pesos.items():
                destino[i + base] = w

    def a_objeto(self, nombre, materiales, coleccion_destino=None, plano=True):
        malla = bpy.data.meshes.new(nombre)
        malla.from_pydata([tuple(v) for v in self.vertices], [],
                          [c[0] for c in self.caras])
        capa_uv = malla.uv_layers.new(name="UVMap")
        bucle = 0
        for poligono, (_, uvs, mat) in zip(malla.polygons, self.caras):
            poligono.material_index = mat
            for uv in uvs:
                capa_uv.data[bucle].uv = uv
                bucle += 1
            poligono.use_smooth = not plano
        for mat in materiales:
            malla.materials.append(mat)
        malla.validate(clean_customdata=False)
        malla.update()
        objeto = bpy.data.objects.new(nombre, malla)
        (coleccion_destino or bpy.context.scene.collection).objects.link(objeto)
        for hueso, pesos in self.grupos.items():
            grupo = objeto.vertex_groups.new(name=hueso)
            por_peso = {}
            for indice, peso in pesos.items():
                por_peso.setdefault(round(peso, 4), []).append(indice)
            for peso, indices in por_peso.items():
                grupo.add(indices, peso, "REPLACE")
        return objeto


# --------------------------------------------------------------- Utilidades ---

def vaciar(nombre, coleccion_destino, posicion=(0, 0, 0)):
    objeto = bpy.data.objects.new(nombre, None)
    objeto.location = posicion
    coleccion_destino.objects.link(objeto)
    return objeto


def aleatorio(semilla):
    return random.Random(semilla)


def configurar_render(escena, ancho=1280, alto=720, muestras=48, transformacion="AgX",
                      exposicion=0.0, aspecto="AgX - Medium High Contrast"):
    """Ajustes de EEVEE para renders cinematográficos (niebla volumétrica, sombras, reflejos)."""
    escena.render.engine = "BLENDER_EEVEE"
    escena.render.resolution_x = ancho
    escena.render.resolution_y = alto
    escena.render.resolution_percentage = 100
    escena.render.image_settings.file_format = "PNG"
    eevee = escena.eevee
    eevee.taa_render_samples = muestras
    for propiedad, valor in [("use_shadows", True), ("use_raytracing", True),
                             ("use_volumetric_shadows", True), ("volumetric_samples", 96),
                             ("volumetric_tile_size", "4"), ("volumetric_end", 140.0),
                             ("volumetric_start", 0.1), ("volumetric_shadow_samples", 24),
                             ("volumetric_light_clamp", 0.0), ("shadow_ray_count", 2),
                             ("shadow_step_count", 8), ("volumetric_sample_distribution", 0.85)]:
        try:
            setattr(eevee, propiedad, valor)
        except (AttributeError, TypeError) as error:
            print("Aviso EEVEE", propiedad, error)
    try:
        escena.view_settings.view_transform = transformacion
    except TypeError as error:
        print("Aviso transformación de vista:", error)
    try:
        escena.view_settings.look = aspecto
    except TypeError:
        pass
    escena.view_settings.exposure = exposicion


def renderizar(escena, ruta):
    escena.render.filepath = str(ruta)
    os.makedirs(os.path.dirname(str(ruta)), exist_ok=True)
    bpy.ops.render.render(write_still=True)
    print("RENDER", ruta)
