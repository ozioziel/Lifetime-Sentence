"""Extrae muestras de material (camisa, piel, pelo...) de las imágenes de referencia.

Las imágenes de Materiales/ son arte conceptual generado con ChatGPT y el creador
autorizó usarlas como material (decisión L3). Este script recorta zonas pequeñas y
las convierte en texturas que se repiten sin costuras (por espejo), para que los
personajes tengan exactamente el mismo «píxel» y suciedad que las referencias.

Uso (Python del entorno del proyecto, con Pillow):
    fuentes_arte\\.venv\\Scripts\\python.exe assets\\scripts\\extraer_muestras.py
Resultado: assets/texturas/referencia/*.png y una hoja de control muestras_control.png
"""
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parents[2]
MAT = RAIZ / "Materiales"
SALIDA = RAIZ / "assets" / "texturas" / "referencia"

COLLAGE = "94c42e3c-1e80-4862-bbea-0556961fab10.png"
PASILLO = "ac3d34e8-b862-4a94-91ee-6762fdfe9c29.png"
PASARELA = "1b065952-b2e1-4a9d-ba7d-63098a528d55.png"
CALLEJON = "43f1fd2b-88a8-4955-8ee6-d53549cea10e.png"
PRESENTE = "Imagen de ChatGPT 11 nov 2026, 09_54_07 p.m-2.png"

# nombre: (imagen, (x0, y0, x1, y1))
MUESTRAS = {
    "camisa_naranja": (COLLAGE, (262, 372, 418, 488)),
    "camisa_naranja_b": (PASILLO, (300, 470, 470, 610)),
    "pelo_oscuro": (COLLAGE, (338, 232, 428, 298)),
    "pelo_castano": (PASILLO, (560, 260, 760, 360)),
    "piel_brazo": (COLLAGE, (392, 500, 452, 608)),
    "piel_brazo_b": (PASILLO, (230, 650, 330, 780)),
    "chaqueta_granate": (CALLEJON, (230, 420, 420, 560)),
    "piel_cara_calida": (CALLEJON, (520, 300, 600, 380)),
    "uniforme_azul": (PRESENTE, (400, 760, 470, 880)),
}


def espejo(img):
    """Mosaico 2 x 2 con espejos: se repite sin costuras."""
    w, h = img.size
    tile = Image.new("RGB", (w * 2, h * 2))
    tile.paste(img, (0, 0))
    tile.paste(img.transpose(Image.FLIP_LEFT_RIGHT), (w, 0))
    tile.paste(img.transpose(Image.FLIP_TOP_BOTTOM), (0, h))
    tile.paste(img.transpose(Image.ROTATE_180), (w, h))
    return tile


def main():
    SALIDA.mkdir(parents=True, exist_ok=True)
    control = []
    for nombre, (archivo, caja) in MUESTRAS.items():
        img = Image.open(MAT / archivo).convert("RGB").crop(caja)
        espejo(img).save(SALIDA / f"{nombre}.png")
        control.append((nombre, img))
        print(nombre, img.size)
    ancho = sum(i.size[0] for _, i in control) + 10 * len(control)
    alto = max(i.size[1] for _, i in control)
    hoja = Image.new("RGB", (ancho, alto), (255, 0, 255))
    x = 0
    for _, img in control:
        hoja.paste(img, (x, 0))
        x += img.size[0] + 10
    hoja.save(SALIDA / "muestras_control.png")


if __name__ == "__main__":
    main()
