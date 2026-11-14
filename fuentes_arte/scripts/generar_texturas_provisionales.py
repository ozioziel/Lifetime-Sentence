"""Genera las texturas PROVISIONALES de la caja gris (etapa 1, bloque 1.1).

Son texturas pequeñas (64-128 px), de pocos colores, pensadas para verse
pixeladas como en una PS1. Se sustituirán por las definitivas en el bloque 1.2.

Uso (desde la carpeta del proyecto):
    fuentes_arte\\.venv\\Scripts\\python.exe fuentes_arte\\scripts\\generar_texturas_provisionales.py

Hecho con IA (Claude). Registrado en Materiales/recursos_y_creditos.md.
"""
from pathlib import Path

import numpy as np
from PIL import Image

RAIZ = Path(__file__).resolve().parents[2]
SALIDA = RAIZ / "juego" / "assets" / "texturas" / "provisional"


def ruido(tam: int, semilla: int, octavas: int = 5, persistencia: float = 0.55,
          celdas_base: int = 4) -> np.ndarray:
    """Ruido de valor entre 0 y 1 que se repite sin costuras."""
    rng = np.random.default_rng(semilla)
    total = np.zeros((tam, tam))
    amplitud, suma = 1.0, 0.0
    for octava in range(octavas):
        celdas = min(celdas_base * 2 ** octava, tam)
        rejilla = rng.random((celdas, celdas))
        pos = np.arange(tam) * celdas / tam
        i0 = np.floor(pos).astype(int) % celdas
        i1 = (i0 + 1) % celdas
        f = pos - np.floor(pos)
        f = f * f * (3 - 2 * f)
        fx, fy = f[None, :], f[:, None]
        a, b = rejilla[np.ix_(i0, i0)], rejilla[np.ix_(i0, i1)]
        c, d = rejilla[np.ix_(i1, i0)], rejilla[np.ix_(i1, i1)]
        total += ((a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy) * amplitud
        suma += amplitud
        amplitud *= persistencia
    return total / suma


def mezclar(base: np.ndarray, color, mascara: np.ndarray) -> np.ndarray:
    """Mezcla un color sobre la imagen según una máscara 0..1."""
    return base * (1 - mascara[..., None]) + np.array(color) * mascara[..., None]


def suave(valor: np.ndarray, minimo: float, maximo: float) -> np.ndarray:
    t = np.clip((valor - minimo) / (maximo - minimo), 0, 1)
    return t * t * (3 - 2 * t)


def guardar(nombre: str, imagen: np.ndarray, colores: int = 24) -> None:
    """Añade grano de píxel, reduce a una paleta corta (aspecto PS1) y guarda el PNG."""
    grano = np.random.default_rng(len(nombre)).normal(0.0, 0.022, imagen.shape[:2])
    imagen = imagen + grano[..., None]
    datos = (np.clip(imagen, 0, 1) * 255).astype(np.uint8)
    img = Image.fromarray(datos, "RGB")
    img = img.quantize(colors=colores, method=Image.Quantize.MEDIANCUT,
                       dither=Image.Dither.NONE).convert("RGB")
    SALIDA.mkdir(parents=True, exist_ok=True)
    img.save(SALIDA / nombre)
    print("  ", nombre, img.size)


def capa(tam: int, color) -> np.ndarray:
    return np.ones((tam, tam, 3)) * np.array(color)


def chorreones(tam: int, semilla: int, cantidad: int, largo: float) -> np.ndarray:
    """Manchas verticales de humedad que bajan desde arriba."""
    rng = np.random.default_rng(semilla)
    mascara = np.zeros((tam, tam))
    for _ in range(cantidad):
        x = rng.integers(0, tam)
        longitud = int(rng.uniform(0.2, 1.0) * largo * tam)
        ancho = rng.integers(1, 4)
        for y in range(longitud):
            mascara[y, (x + np.arange(ancho)) % tam] = max(
                mascara[y, x], (1 - y / max(longitud, 1)) * rng.uniform(0.5, 1.0))
    return mascara


def concreto() -> None:
    tam = 128
    n1, n2 = ruido(tam, 11), ruido(tam, 12, celdas_base=16, octavas=3)
    img = capa(tam, (0.40, 0.43, 0.44)) * (0.78 + 0.44 * n1[..., None])
    img = mezclar(img, (0.20, 0.23, 0.25), suave(ruido(tam, 13, octavas=3), 0.55, 0.75) * 0.7)
    img = mezclar(img, (0.16, 0.19, 0.20), chorreones(tam, 14, 16, 0.8) * 0.45)
    img *= (0.9 + 0.2 * n2[..., None])
    # Juntas horizontales del encofrado.
    for y in (0, 64):
        img[y, :, :] *= 0.62
        img[y + 1, :, :] *= 0.85
    rng = np.random.default_rng(15)
    poros = rng.random((tam, tam)) > 0.985
    img[poros] *= 0.45
    guardar("concreto.png", img)


def pared_celda() -> None:
    """Pared institucional: zócalo verde abajo y pintura clara sucia arriba."""
    tam = 128
    n = ruido(tam, 21)
    fino = ruido(tam, 22, celdas_base=16, octavas=3)
    filas = np.arange(tam)[:, None] * np.ones((1, tam))
    limite = 70  # Fila donde empieza el zócalo (la imagen va de techo a suelo).

    arriba = capa(tam, (0.47, 0.48, 0.42)) * (0.78 + 0.4 * n[..., None])
    arriba = mezclar(arriba, (0.24, 0.24, 0.20), chorreones(tam, 23, 22, 0.55) * 0.55)
    abajo = capa(tam, (0.16, 0.27, 0.23)) * (0.72 + 0.5 * n[..., None])

    img = np.where((filas >= limite)[..., None], abajo, arriba)
    # Desconchones que dejan ver el concreto.
    desconchado = suave(ruido(tam, 24, octavas=4, celdas_base=8), 0.6, 0.66)
    img = mezclar(img, (0.36, 0.37, 0.36), desconchado * (0.35 + 0.5 * (filas >= limite)))
    # Franja oscura de separación y suciedad junto al suelo.
    img[limite - 1:limite + 1, :, :] *= 0.5
    suciedad = suave(filas, tam - 22, tam) * 0.6
    img = mezclar(img, (0.07, 0.08, 0.08), suciedad)
    img *= (0.9 + 0.2 * fino[..., None])
    guardar("pared_celda.png", img)


def suelo() -> None:
    tam = 128
    n, fino = ruido(tam, 31), ruido(tam, 32, celdas_base=16, octavas=3)
    img = capa(tam, (0.20, 0.22, 0.23)) * (0.7 + 0.6 * n[..., None])
    # Charcos y zonas húmedas, más oscuras y azuladas.
    img = mezclar(img, (0.07, 0.10, 0.12), suave(ruido(tam, 33, octavas=3), 0.52, 0.7) * 0.8)
    img *= (0.88 + 0.24 * fino[..., None])
    # Juntas de losas de 1 m (64 px).
    for linea in (0, 64):
        img[linea, :, :] *= 0.5
        img[:, linea, :] *= 0.5
    guardar("suelo.png", img)


def techo() -> None:
    tam = 128
    n = ruido(tam, 41)
    img = capa(tam, (0.30, 0.31, 0.30)) * (0.75 + 0.5 * n[..., None])
    # Manchas de humedad parduzcas con borde.
    mancha = ruido(tam, 42, octavas=3)
    img = mezclar(img, (0.22, 0.19, 0.13), suave(mancha, 0.56, 0.7) * 0.75)
    img = mezclar(img, (0.12, 0.11, 0.09),
                  (suave(mancha, 0.54, 0.58) - suave(mancha, 0.58, 0.62)).clip(0, 1) * 0.6)
    guardar("techo.png", img)


def metal_oxidado() -> None:
    tam = 64
    n = ruido(tam, 51, celdas_base=8, octavas=4)
    img = capa(tam, (0.15, 0.16, 0.17)) * (0.7 + 0.6 * n[..., None])
    oxido = suave(ruido(tam, 52, celdas_base=8, octavas=4), 0.5, 0.68)
    img = mezclar(img, (0.36, 0.18, 0.08), oxido * 0.85)
    img = mezclar(img, (0.20, 0.09, 0.04), suave(ruido(tam, 53, celdas_base=16, octavas=2), 0.62, 0.7) * 0.6)
    guardar("metal_oxidado.png", img, colores=16)


def metal_pintado() -> None:
    tam = 64
    n = ruido(tam, 61, celdas_base=8, octavas=4)
    img = capa(tam, (0.20, 0.24, 0.23)) * (0.75 + 0.5 * n[..., None])
    img = mezclar(img, (0.33, 0.17, 0.08), suave(ruido(tam, 62, celdas_base=8, octavas=4), 0.6, 0.7) * 0.8)
    # Remaches.
    for x in (8, 24, 40, 56):
        for y in (6, 58):
            img[y - 1:y + 1, x - 1:x + 1, :] *= 1.5
    guardar("metal_pintado.png", img, colores=16)


if __name__ == "__main__":
    print("Generando texturas provisionales en", SALIDA)
    concreto()
    pared_celda()
    suelo()
    techo()
    metal_oxidado()
    metal_pintado()
    print("Listo.")
