"""Sonido procedural de Lifetime Sentence (todo original, sin muestras de terceros).

Genera los efectos y ambientes del juego en juego/assets/audio/<nombre>.ogg con síntesis
(numpy + scipy): ruido filtrado, osciladores, parciales inarmónicos (metal), formantes
(voces deformadas de las manifestaciones) y reverberación por convolución.
Los ambientes se hacen en bucle sin cortes (fundido cruzado del final con el principio) y
se marcan como bucle en su .import.

Uso:
    python assets/scripts/generar_audio.py            # todos
    python assets/scripts/generar_audio.py lluvia ... # solo esos
Requiere ffmpeg en el PATH (convierte WAV → OGG Vorbis).
"""
import os
import subprocess
import sys
import tempfile

import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DESTINO = os.path.join(RAIZ, "juego", "assets", "audio")
rng = np.random.default_rng(4827)


# ----------------------------------------------------------------- Utilidades ---

def n_(seg):
    return int(SR * seg)


def t_(seg):
    return np.arange(n_(seg)) / SR


def ruido(seg):
    return rng.uniform(-1, 1, n_(seg))


def rosa(seg):
    b, a = [0.049922035, -0.095993537, 0.050612699, -0.004408786], [1, -2.494956002, 2.017265875, -0.522189400]
    return normalizar(signal.lfilter(b, a, ruido(seg)), 1.0)


def marron(seg):
    x = np.cumsum(ruido(seg))
    return normalizar(paso_alto(x, 20), 1.0)


def _sos(tipo, f, orden=2):
    nyq = SR / 2
    if tipo == "band":
        lo, hi = max(f[0], 10) / nyq, min(f[1], nyq * 0.98) / nyq
        return signal.butter(orden, [lo, hi], btype="band", output="sos")
    return signal.butter(orden, min(max(f, 10), nyq * 0.98) / nyq, btype=tipo, output="sos")


def paso_bajo(x, f, orden=2):
    if np.ndim(f):
        return paso_bajo_variable(x, np.asarray(f, dtype=float), orden)
    return signal.sosfilt(_sos("low", f, orden), x)


def paso_bajo_variable(x, f, orden=2, bloque=0.05):
    """Paso bajo con frecuencia de corte que cambia con el tiempo (por bloques)."""
    out = np.zeros(len(x))
    nb = max(n_(bloque), 1)
    zi = None
    for i in range(0, len(x), nb):
        j = min(i + nb, len(x))
        sos = _sos("low", float(np.mean(f[i:j])), orden)
        if zi is None:
            zi = signal.sosfilt_zi(sos) * x[i]
        out[i:j], zi = signal.sosfilt(sos, x[i:j], zi=zi)
    return out


def paso_alto(x, f, orden=2):
    return signal.sosfilt(_sos("high", f, orden), x)


def banda(x, f0, f1, orden=2):
    return signal.sosfilt(_sos("band", (f0, f1), orden), x)


def resonante(x, f, q=8.0, bloque=0.02):
    if not np.ndim(f):
        b, a = signal.iirpeak(min(f, SR / 2 * 0.95), q, SR)
        return signal.lfilter(b, a, x)
    # Frecuencia variable: por bloques, conservando el estado del filtro.
    f = np.asarray(f, dtype=float)
    out = np.zeros(len(x))
    nb = max(n_(bloque), 1)
    zi = None
    for i in range(0, len(x), nb):
        j = min(i + nb, len(x))
        b, a = signal.iirpeak(min(max(float(np.mean(f[i:j])), 20.0), SR / 2 * 0.95), q, SR)
        if zi is None:
            zi = signal.lfilter_zi(b, a) * x[i]
        out[i:j], zi = signal.lfilter(b, a, x[i:j], zi=zi)
    return out


def env(n, a=0.005, d=0.1, s=0.0, r=0.1, sostener=None):
    """ADSR de n muestras. sostener = segundos de sostenido (si no, lo que quede)."""
    na, nd, nr = n_(a), n_(d), n_(r)
    ns = n - na - nd - nr if sostener is None else n_(sostener)
    ns = max(ns, 0)
    e = np.concatenate([np.linspace(0, 1, max(na, 1)), np.linspace(1, s, max(nd, 1)), np.full(ns, s),
                        np.linspace(s, 0, max(nr, 1))])
    return ajustar(e, n)


def caida(n, tau):
    return np.exp(-np.arange(n) / (SR * max(tau, 1e-4)))


def ajustar(x, n):
    if len(x) >= n:
        return x[:n]
    return np.concatenate([x, np.zeros(n - len(x))])


def normalizar(x, pico=0.9):
    m = np.max(np.abs(x)) if len(x) else 0
    return x * (pico / m) if m > 1e-9 else x


def mezclar(*partes):
    n = max(len(p) for p in partes)
    return sum(ajustar(p, n) for p in partes)


def en(x, seg, total=None):
    """Coloca x a partir de 'seg' segundos dentro de un buffer de 'total' segundos."""
    total_n = n_(total) if total else n_(seg) + len(x)
    out = np.zeros(total_n)
    i = n_(seg)
    j = min(i + len(x), total_n)
    out[i:j] += x[: j - i]
    return out


def osc(f, seg, forma="seno", fase=0.0):
    t = t_(seg)
    f = np.broadcast_to(np.asarray(f, dtype=float), t.shape) if np.ndim(f) else np.full(t.shape, float(f))
    ph = 2 * np.pi * np.cumsum(f) / SR + fase
    if forma == "seno":
        return np.sin(ph)
    if forma == "sierra":
        return 2 * ((ph / (2 * np.pi)) % 1.0) - 1
    if forma == "cuadrada":
        return np.sign(np.sin(ph))
    if forma == "triangulo":
        return 2 * np.abs(2 * ((ph / (2 * np.pi)) % 1.0) - 1) - 1
    raise ValueError(forma)


def reverb(x, seg=1.8, mezcla=0.35, brillo=4000.0, previo=0.02):
    ir = ruido(seg) * caida(n_(seg), seg / 6.0)
    ir = paso_bajo(ir, brillo)
    ir = np.concatenate([np.zeros(n_(previo)), ir])
    ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
    mojado = signal.fftconvolve(x, ir)[: len(x) + n_(seg)]
    seco = ajustar(x, len(mojado))
    return seco * (1 - mezcla) + normalizar(mojado, np.max(np.abs(x)) + 1e-9) * mezcla


def bucle(x, cruce=1.5):
    """Hace un bucle sin cortes: funde el final con el principio."""
    nc = n_(cruce)
    cuerpo = x[: len(x) - nc].copy()
    cola = x[len(x) - nc:]
    rampa = np.linspace(0, 1, nc)
    cuerpo[:nc] = cuerpo[:nc] * rampa + cola * (1 - rampa)
    return cuerpo


def metal(f0, seg, brillo=1.0, decaimiento=1.0, parciales=(1.0, 2.76, 5.40, 8.93, 13.3, 3.17, 6.8)):
    """Golpe metálico inarmónico (rejas, puertas, campanas)."""
    x = np.zeros(n_(seg))
    for k, r in enumerate(parciales):
        amp = 1.0 / (1 + k * 0.6 / brillo)
        x += amp * osc(f0 * r * rng.uniform(0.99, 1.01), seg) * caida(n_(seg), seg * decaimiento / (1 + k * 0.7))
    golpe = banda(ruido(0.04), 800, 9000) * caida(n_(0.04), 0.008)
    return normalizar(mezclar(x * 0.6, golpe * 0.8))


def golpe_sordo(f=60, seg=0.6, ruido_mix=0.4):
    t = t_(seg)
    tono_ = np.sin(2 * np.pi * np.cumsum(f * (1 + 2.5 * np.exp(-t * 30))) / SR) * caida(n_(seg), seg / 4)
    clic = paso_bajo(ruido(0.05), 2500) * caida(n_(0.05), 0.01)
    return normalizar(mezclar(tono_, clic * ruido_mix))


def voz(seg, f0, formantes, vibrato=0.0, aspereza=0.0, curva=None):
    """Voz deformada: pulso glotal (sierra) por filtros de formantes."""
    t = t_(seg)
    f = np.full(t.shape, float(f0)) if curva is None else np.interp(t, np.linspace(0, seg, len(curva)), curva)
    f = f * (1 + vibrato * np.sin(2 * np.pi * 5.5 * t))
    fuente = osc(f, seg, "sierra") + aspereza * ruido(seg)
    x = sum(resonante(fuente, fm, q) * g for fm, q, g in formantes)
    return normalizar(x)


def guardar(nombre, x, es_bucle=False, pico=0.85):
    os.makedirs(DESTINO, exist_ok=True)
    x = normalizar(np.nan_to_num(x), pico)
    tmp = os.path.join(tempfile.gettempdir(), f"ls_audio_{nombre}.wav")
    wavfile.write(tmp, SR, (x * 32767).astype(np.int16))
    ogg = os.path.join(DESTINO, f"{nombre}.ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "4", ogg], check=True)
    os.remove(tmp)
    imp = ogg + ".import"
    if not os.path.exists(imp):
        with open(imp, "w", encoding="utf-8", newline="\n") as fh:
            fh.write('[remap]\n\nimporter="oggvorbisstr"\ntype="AudioStreamOggVorbis"\n\n[params]\n\n'
                     f'loop={"true" if es_bucle else "false"}\nloop_offset=0.0\nbpm=0.0\nbeat_count=0\nbar_beats=4\n')
    print("  ", nombre, f"{len(x) / SR:.1f} s", "(bucle)" if es_bucle else "")


SONIDOS = {}


def sonido(nombre, es_bucle=False):
    def deco(fn):
        SONIDOS[nombre] = (fn, es_bucle)
        return fn
    return deco


# ------------------------------------------------------------------ Ambientes ---

@sonido("zumbido_pabellon", True)
def _():
    s = 24.0
    t = t_(s)
    hum = sum(osc(50 * k, s) / k for k in (1, 2, 3, 4)) * 0.25 * (1 + 0.1 * np.sin(2 * np.pi * 0.13 * t))
    aire = paso_bajo(rosa(s), 400) * 0.6
    golpes = np.zeros(n_(s))
    for _i in range(5):
        golpes += en(reverb(metal(rng.uniform(90, 160), 2.0, 0.6) * 0.25, 3.0, 0.8, 1500), rng.uniform(1, s - 4), s)
    return bucle(mezclar(hum, aire, golpes))


@sonido("goteo_lejano", True)
def _():
    s = 20.0
    x = paso_bajo(rosa(s), 300) * 0.12
    for _i in range(14):
        f = rng.uniform(900, 1700)
        gota = osc(f * np.exp(-t_(0.12) * 9), 0.12) * caida(n_(0.12), 0.025)
        x += en(reverb(gota * 0.5, 2.0, 0.7, 3000), rng.uniform(0.2, s - 2.5), s)
    return bucle(x)


@sonido("goteo", True)
def _():
    s = 6.0
    x = np.zeros(n_(s))
    for k in range(6):
        f = rng.uniform(1100, 1600)
        gota = osc(f * np.exp(-t_(0.1) * 10), 0.1) * caida(n_(0.1), 0.02)
        x += en(gota, 0.4 + k * 0.95 + rng.uniform(-0.1, 0.1), s)
    return bucle(reverb(x, 1.2, 0.4, 5000), 0.5)


@sonido("lluvia", True)
def _():
    s = 20.0
    base = banda(rosa(s), 400, 7000) * 0.7 + paso_bajo(marron(s), 250) * 0.4
    gotas = np.zeros(n_(s))
    for _i in range(900):
        g = banda(ruido(0.015), 2000, 9000) * caida(n_(0.015), 0.003) * rng.uniform(0.1, 0.5)
        gotas += en(g, rng.uniform(0, s - 0.1), s)
    return bucle(mezclar(base, gotas))


@sonido("ciudad_noche", True)
def _():
    s = 24.0
    t = t_(s)
    trafico = paso_bajo(marron(s), 180) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.05 * t))
    sirena = osc(700 + 250 * np.sin(2 * np.pi * 0.35 * t), s, "triangulo") * 0.05
    sirena = paso_bajo(sirena, 1200) * np.clip(np.sin(2 * np.pi * t / s) * 1.5, 0, 1)
    return bucle(reverb(mezclar(trafico, sirena), 3.0, 0.6, 1200))


@sonido("patio_viento", True)
def _():
    s = 28.0
    t = t_(s)
    viento = banda(marron(s) * 0.5 + rosa(s) * 0.5, 120, 900) * (0.5 + 0.5 * np.sin(2 * np.pi * 0.07 * t + 1) ** 2)
    silbido = resonante(rosa(s), 620, 30) * 0.15 * (0.5 + 0.5 * np.sin(2 * np.pi * 0.11 * t))
    crujidos = np.zeros(n_(s))
    for _i in range(6):
        c = metal(rng.uniform(140, 260), 2.5, 0.4, 1.5) * 0.18
        crujidos += en(c, rng.uniform(1, s - 5), s)
    return bucle(reverb(mezclar(viento, silbido, crujidos), 4.5, 0.7, 2500), 2.0)


@sonido("comisaria_ambiente", True)
def _():
    s = 20.0
    zumbido = sum(osc(60 * k, s) / k for k in (2, 3, 4)) * 0.12
    aire = paso_bajo(rosa(s), 900) * 0.25
    return bucle(mezclar(zumbido, aire))


@sonido("interrogatorio_zumbido", True)
def _():
    s = 12.0
    t = t_(s)
    zumbido = (osc(120, s, "sierra") * 0.3 + osc(240, s) * 0.2) * (1 + 0.05 * np.sin(2 * np.pi * 7 * t))
    return bucle(mezclar(paso_bajo(zumbido, 1800), paso_bajo(rosa(s), 500) * 0.2))


@sonido("enfermeria_ambiente", True)
def _():
    s = 24.0
    hum = sum(osc(50 * k, s) / k for k in (1, 3)) * 0.2
    aire = paso_bajo(rosa(s), 500) * 0.3
    respiro = np.zeros(n_(s))
    for k in range(4):
        r = banda(ruido(1.6), 300, 1500) * np.sin(np.linspace(0, np.pi, n_(1.6))) ** 2 * 0.15
        respiro += en(r, 3 + k * 5.5, s)
    return bucle(reverb(mezclar(hum, aire, respiro), 1.6, 0.4, 3000))


@sonido("murmullo_presos", True)
def _():
    s = 20.0
    x = np.zeros(n_(s))
    for _i in range(40):
        dur = rng.uniform(0.6, 2.2)
        f0 = rng.uniform(95, 170)
        v = voz(dur, f0, [(rng.uniform(450, 800), 5, 1.0), (rng.uniform(1000, 1700), 6, 0.6)], 0.02, 0.4)
        v *= np.sin(np.linspace(0, np.pi, len(v))) * rng.uniform(0.2, 0.6)
        x += en(paso_bajo(v, 2200), rng.uniform(0, s - dur), s)
    return bucle(reverb(x, 2.5, 0.6, 2000))


@sonido("patio_pasado", True)
def _():
    s = 24.0
    t = t_(s)
    aire = banda(rosa(s), 150, 1200) * 0.35 * (0.7 + 0.3 * np.sin(2 * np.pi * 0.08 * t))
    palomas = np.zeros(n_(s))
    for _i in range(8):
        d = 0.5
        p = voz(d, rng.uniform(380, 460), [(900, 4, 1.0)], 0.06, 0.1) * np.sin(np.linspace(0, np.pi, n_(d))) * 0.12
        palomas += en(p, rng.uniform(0.5, s - 1), s)
    return bucle(reverb(mezclar(aire, palomas), 3.5, 0.55, 3000))


@sonido("sala_ejecucion", True)
def _():
    s = 24.0
    t = t_(s)
    dron = paso_bajo(osc(41, s, "sierra") + osc(41.6, s, "sierra") + osc(61.5, s, "sierra") * 0.5, 220)
    dron *= 0.8 + 0.2 * np.sin(2 * np.pi * 0.09 * t)
    cadenas = np.zeros(n_(s))
    for _i in range(10):
        cadenas += en(metal(rng.uniform(800, 1600), 0.4, 1.4, 0.3) * 0.2, rng.uniform(0, s - 1), s)
    return bucle(reverb(mezclar(dron * 0.6, cadenas), 3.0, 0.6, 3000))


@sonido("latido_lento", True)
def _():
    s = 6.0
    x = np.zeros(n_(s))
    for k in range(5):
        x += en(golpe_sordo(48, 0.35), k * 1.2, s) + en(golpe_sordo(44, 0.3) * 0.7, k * 1.2 + 0.28, s)
    return bucle(paso_bajo(x, 300), 0.3)


@sonido("nucleo_drone", True)
def _():
    s = 30.0
    t = t_(s)
    capas = [osc(f, s, "sierra") for f in (36.7, 36.9, 55.0, 73.4, 110.2)]
    dron = paso_bajo(sum(capas), 260 + 140 * (0.5 + 0.5 * np.sin(2 * np.pi * 0.033 * t)))
    coro = paso_bajo(voz(s, 110, [(500, 6, 1.0), (850, 6, 0.6)], 0.01, 0.1), 900) * 0.18
    return bucle(reverb(mezclar(dron * 0.7, coro), 5.0, 0.6, 1500), 3.0)


@sonido("pantallas_estatica", True)
def _():
    s = 8.0
    t = t_(s)
    x = banda(ruido(s), 1500, 9000) * 0.3 * (0.7 + 0.3 * np.sin(2 * np.pi * 0.9 * t))
    return bucle(mezclar(x, osc(15600, s) * 0.02))


@sonido("menu_drone", True)
def _():
    s = 32.0
    t = t_(s)
    dron = paso_bajo(osc(55, s, "sierra") + osc(55.4, s, "sierra") + osc(82.5, s, "triangulo") * 0.6, 300)
    dron *= 0.75 + 0.25 * np.sin(2 * np.pi * t / 16)
    tension = paso_bajo(osc(233.1, s, "sierra") * 0.12, 700) * np.clip(np.sin(2 * np.pi * t / s * 2), 0, 1) ** 2
    lluvia_lejana = banda(rosa(s), 600, 5000) * 0.06
    golpe = en(reverb(metal(70, 3.5, 0.5, 1.6) * 0.5, 5, 0.8, 1200), 9.0, s)
    return bucle(reverb(mezclar(dron, tension, lluvia_lejana, golpe), 4.0, 0.55, 1800), 3.0)


@sonido("creditos_drone", True)
def _():
    s = 30.0
    t = t_(s)
    acordes = sum(osc(f, s, "triangulo") for f in (110, 130.8, 164.8, 220)) * 0.15
    acordes = paso_bajo(acordes, 900) * (0.6 + 0.4 * np.sin(2 * np.pi * t / 15) ** 2)
    return bucle(reverb(mezclar(acordes, paso_bajo(rosa(s), 300) * 0.1), 5.0, 0.6, 2000), 3.0)


@sonido("foco_zumbido", True)
def _():
    s = 8.0
    return bucle(mezclar(osc(100, s, "sierra") * 0.3, osc(200, s) * 0.2, banda(ruido(s), 2000, 6000) * 0.05))


@sonido("zumbido_quirofano", True)
def _():
    s = 10.0
    t = t_(s)
    return bucle(paso_bajo(osc(120, s, "cuadrada") * 0.2 * (1 + 0.2 * np.sin(2 * np.pi * 0.4 * t)), 1500))


@sonido("radio_policia", True)
def _():
    s = 16.0
    x = banda(ruido(s), 500, 3500) * 0.08
    for k in range(4):
        d = rng.uniform(1.2, 2.4)
        habla = voz(d, rng.uniform(110, 140), [(700, 4, 1), (1200, 5, 0.7), (2400, 6, 0.4)], 0.03, 0.6)
        habla *= (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * rng.uniform(3, 6) * t_(d))))
        x += en(banda(habla, 400, 3000) * 0.35 + banda(ruido(d), 500, 3500) * 0.12, 0.5 + k * 3.8, s)
        x += en(osc(1400, 0.08) * 0.2, 0.5 + k * 3.8 + d, s)
    return bucle(x, 0.4)


@sonido("radio_antigua", True)
def _():
    s = 16.0
    notas = [220, 247, 262, 247, 196, 220, 165, 196]
    x = np.zeros(n_(s))
    for k, f in enumerate(notas * 2):
        nota = (osc(f, 1.0, "triangulo") + osc(f * 2, 1.0) * 0.3) * env(n_(1.0), 0.02, 0.3, 0.5, 0.3)
        x += en(nota, k * 1.0, s)
    x = banda(x, 300, 2500) + banda(ruido(s), 1000, 5000) * 0.08
    crepitar = (rng.uniform(0, 1, n_(s)) > 0.9995) * rng.uniform(-1, 1, n_(s))
    return bucle(mezclar(x * 0.5, paso_alto(crepitar, 2000) * 0.5), 0.3)


@sonido("sirena", True)
def _():
    s = 12.0
    t = t_(s)
    f = 650 + 350 * (0.5 + 0.5 * np.sin(2 * np.pi * t / 3.0))
    x = paso_bajo(osc(f, s, "sierra"), 1800) * 0.5
    return bucle(reverb(x, 3.0, 0.6, 1500))


@sonido("canalon", True)
def _():
    s = 8.0
    return bucle(mezclar(banda(rosa(s), 300, 2500), banda(ruido(s), 2000, 6000) * 0.3))


@sonido("maquina_escribir", True)
def _():
    s = 8.0
    x = np.zeros(n_(s))
    tt = 0.2
    while tt < s - 0.3:
        clac = banda(ruido(0.03), 1500, 6000) * caida(n_(0.03), 0.005) + osc(320, 0.03) * caida(n_(0.03), 0.01) * 0.3
        x += en(clac * rng.uniform(0.5, 1.0), tt, s)
        tt += rng.uniform(0.08, 0.25) if rng.random() > 0.08 else rng.uniform(0.6, 1.2)
    return bucle(reverb(x, 0.8, 0.3, 4000), 0.2)


@sonido("telefono_lejano", True)
def _():
    s = 8.0
    t = t_(1.2)
    timbre = (osc(440, 1.2) + osc(480, 1.2)) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 20 * t)))
    x = en(timbre, 0.3, s) + en(timbre, 1.9, s)
    return bucle(reverb(paso_bajo(x, 2000) * 0.4, 1.5, 0.5, 2000), 0.2)


@sonido("respiracion_celda", True)
def _():
    s = 9.0
    x = np.zeros(n_(s))
    for k in range(4):
        inh = banda(ruido(1.0), 400, 2200) * np.sin(np.linspace(0, np.pi, n_(1.0))) ** 2
        exh = banda(ruido(1.2), 250, 1400) * np.sin(np.linspace(0, np.pi, n_(1.2))) ** 2 * 0.8
        x += en(inh, k * 2.2, s) + en(exh, k * 2.2 + 1.0, s)
    return bucle(x, 0.3)


@sonido("aislados_lejos", True)
def _():
    s = 20.0
    x = np.zeros(n_(s))
    for _i in range(7):
        d = rng.uniform(1.5, 3.0)
        curva = np.linspace(rng.uniform(90, 120), rng.uniform(60, 80), 8)
        g = voz(d, 100, [(380, 4, 1.0), (900, 5, 0.5)], 0.04, 0.5, curva) * np.sin(np.linspace(0, np.pi, n_(d)))
        x += en(paso_bajo(g, 1200) * 0.4, rng.uniform(0, s - d), s)
    return bucle(reverb(x, 4.0, 0.75, 1200), 1.5)


@sonido("cadenas_viento", True)
def _():
    s = 14.0
    x = np.zeros(n_(s))
    for _i in range(18):
        x += en(metal(rng.uniform(900, 2000), 0.5, 1.5, 0.4) * rng.uniform(0.1, 0.3), rng.uniform(0, s - 1), s)
    return bucle(reverb(x, 2.5, 0.6, 4000), 0.5)


@sonido("llaves", True)
def _():
    s = 2.6
    x = np.zeros(n_(s))
    for paso in range(2):
        base = paso * 1.3
        for _i in range(9):
            x += en(metal(rng.uniform(2200, 4200), 0.25, 2.0, 0.25) * rng.uniform(0.2, 0.6), base + rng.uniform(0, 0.25), s)
    return bucle(reverb(x, 0.8, 0.3, 6000), 0.1)


@sonido("arrastre", True)
def _():
    s = 6.0
    t = t_(s)
    roce = banda(ruido(s), 300, 2800) * (0.6 + 0.4 * np.abs(np.sin(2 * np.pi * 0.85 * t)))
    chirrido = resonante(ruido(s), 1100, 12) * 0.3 * (0.5 + 0.5 * np.sin(2 * np.pi * 0.31 * t))
    return bucle(reverb(mezclar(roce, chirrido), 1.5, 0.4, 3000), 0.4)


@sonido("mecanismo", True)
def _():
    s = 4.0
    t = t_(s)
    engr = banda(ruido(s), 200, 1500) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 9 * t)))
    return bucle(mezclar(engr * 0.6, osc(55, s, "sierra") * 0.3), 0.2)


@sonido("ganzua_esfuerzo", True)
def _():
    s = 2.0
    t = t_(s)
    return bucle(resonante(ruido(s), 2800 + 300 * np.sin(2 * np.pi * 3 * t[0]), 25) * 0.6, 0.1)


# ------------------------------------------------------------------- Pasos ---

def _paso(brillo, grave, cola=0.0, chapoteo=False):
    golpe = banda(ruido(0.12), grave, brillo) * caida(n_(0.12), 0.025)
    cuerpo = golpe_sordo(70, 0.12, 0.2) * 0.4
    x = mezclar(golpe, cuerpo)
    if cola:
        x = mezclar(x, metal(rng.uniform(350, 500), cola, 0.6, 0.6) * 0.25)
    if chapoteo:
        x = mezclar(x, banda(ruido(0.25), 800, 6000) * caida(n_(0.25), 0.06) * 0.7)
    return x


@sonido("paso_hormigon")
def _():
    return reverb(_paso(3000, 150), 0.6, 0.25, 3000)


@sonido("paso_metal")
def _():
    return reverb(_paso(5000, 300, cola=0.35), 1.2, 0.35, 4000)


@sonido("paso_charco")
def _():
    return _paso(4000, 200, chapoteo=True)


@sonido("paso_baldosa")
def _():
    return reverb(_paso(6000, 400), 0.5, 0.2, 5000)


# -------------------------------------------------------------- Interfaz ---

@sonido("ui_mover")
def _():
    return osc(900, 0.05, "triangulo") * caida(n_(0.05), 0.012)


@sonido("ui_aceptar")
def _():
    return reverb(mezclar(metal(420, 0.6, 0.6, 0.6) * 0.5, golpe_sordo(80, 0.3) * 0.5), 1.0, 0.3)


@sonido("ui_pausa")
def _():
    return reverb(golpe_sordo(55, 0.8) * 0.8, 1.5, 0.4, 1500)


@sonido("rotulo")
def _():
    x = mezclar(golpe_sordo(38, 2.5, 0.2), metal(65, 4.0, 0.4, 1.4) * 0.5)
    return reverb(x, 4.0, 0.6, 1400)


@sonido("continuar")
def _():
    return reverb(mezclar(paso_bajo(osc(55, 3.0, "sierra"), 200) * env(n_(3.0), 0.5, 2.5), metal(110, 3.0, 0.3) * 0.3), 3.0, 0.5, 1200)


@sonido("papel")
def _():
    x = np.zeros(n_(0.5))
    for _i in range(8):
        x += en(banda(ruido(0.05), 2000, 8000) * caida(n_(0.05), 0.015) * rng.uniform(0.3, 1.0), rng.uniform(0, 0.4), 0.5)
    return x


@sonido("teclado_tecla")
def _():
    return mezclar(osc(1200, 0.07, "cuadrada") * caida(n_(0.07), 0.03) * 0.3, banda(ruido(0.02), 2000, 6000) * 0.4)


@sonido("teclado_ok")
def _():
    return mezclar(en(osc(1500, 0.12, "cuadrada") * 0.3, 0), en(osc(2000, 0.15, "cuadrada") * 0.3, 0.15))


@sonido("teclado_error")
def _():
    return paso_bajo(osc(140, 0.5, "cuadrada"), 1500) * env(n_(0.5), 0.005, 0.1, 0.8, 0.1) * 0.5


@sonido("estatica")
def _():
    return banda(ruido(0.35), 800, 9000) * env(n_(0.35), 0.005, 0.05, 0.7, 0.15)


# ----------------------------------------------------------------- Puertas ---

@sonido("puerta_reja")
def _():
    t = t_(1.6)
    chirrido = resonante(ruido(1.6), 900 + 500 * np.sin(np.pi * t / 1.6), 30) * env(n_(1.6), 0.2, 1.0, 0.4, 0.3) * 0.5
    golpe = en(metal(180, 2.0, 0.8), 1.3, 3.5)
    return reverb(mezclar(chirrido, golpe), 2.0, 0.45, 3000)


@sonido("puerta_pesada")
def _():
    return reverb(mezclar(banda(ruido(1.2), 100, 900) * env(n_(1.2), 0.1, 0.8, 0.3, 0.2), en(golpe_sordo(50, 1.0), 1.0, 2.5),
                          en(metal(95, 2.0, 0.5) * 0.4, 1.0, 3.0)), 2.2, 0.5, 2000)


@sonido("puerta_madera")
def _():
    t = t_(1.0)
    cruj = resonante(ruido(1.0), 500 + 200 * t, 20) * env(n_(1.0), 0.1, 0.7, 0.2, 0.2) * 0.4
    return reverb(mezclar(cruj, en(golpe_sordo(90, 0.4), 0.8, 1.5)), 1.0, 0.3)


@sonido("puerta_metal")
def _():
    return reverb(mezclar(metal(150, 1.5, 0.7) * 0.6, golpe_sordo(70, 0.5) * 0.5), 1.5, 0.4)


@sonido("puerta_bloqueada")
def _():
    x = np.zeros(n_(0.8))
    for k in range(3):
        x += en(mezclar(metal(260, 0.3, 1.0, 0.3), golpe_sordo(90, 0.2)) * 0.7, k * 0.18, 0.8)
    return x


@sonido("puerta_cerrojo")
def _():
    return reverb(mezclar(metal(600, 0.4, 1.2, 0.4) * 0.6, en(metal(380, 0.6, 0.8) * 0.8, 0.15, 0.8)), 1.0, 0.35)


@sonido("cerradura_llave")
def _():
    return mezclar(en(metal(1800, 0.2, 1.5, 0.3) * 0.5, 0.0, 0.6), en(metal(900, 0.3, 1.0, 0.4) * 0.7, 0.25, 0.6))


@sonido("cerradura_abrir")
def _():
    return reverb(mezclar(en(metal(1300, 0.25, 1.4, 0.3) * 0.6, 0.0, 0.8), en(metal(500, 0.5, 1.0) * 0.8, 0.12, 0.8)), 0.8, 0.3)


@sonido("ganzua_meter")
def _():
    return banda(ruido(0.4), 2500, 8000) * env(n_(0.4), 0.02, 0.3, 0.1, 0.05) * 0.5


@sonido("ganzua_clic")
def _():
    return metal(3200, 0.08, 2.0, 0.2) * 0.6


@sonido("ganzua_rota")
def _():
    return mezclar(metal(2600, 0.3, 2.0, 0.3), banda(ruido(0.05), 3000, 9000) * caida(n_(0.05), 0.01))


@sonido("rayar_pared")
def _():
    x = np.zeros(n_(2.4))
    for k in range(5):
        r = banda(ruido(0.35), 1500, 7000) * np.sin(np.linspace(0, np.pi, n_(0.35))) * 0.6
        x += en(r, 0.2 + k * 0.42, 2.4)
    return x


@sonido("escalera_servicio")
def _():
    s = 2.4
    x = en(_paso(3000, 150) * 0.6, 0.0, s)
    for k in range(6):
        x += en(_paso(4500, 250, 0.25) * 0.5, 0.35 + k * 0.32, s)
    return reverb(x, 1.5, 0.4, 3000)


@sonido("reja_ascensor")
def _():
    t = t_(1.3)
    roce = banda(ruido(1.3), 400, 3000) * env(n_(1.3), 0.05, 1.0, 0.6, 0.2) * 0.5
    return reverb(mezclar(roce, en(metal(320, 1.5, 0.8), 1.1, 3.0)), 1.5, 0.4)


@sonido("rastrillo")
def _():
    caer = banda(ruido(0.5), 300, 3000) * np.linspace(0.2, 1.0, n_(0.5)) * 0.5
    return reverb(mezclar(caer, en(metal(85, 3.0, 0.7, 1.2), 0.45, 4.0), en(golpe_sordo(45, 1.2), 0.45, 4.0)), 3.0, 0.5, 2000)


@sonido("puerta_monumental")
def _():
    s = 4.0
    t = t_(s)
    engr = banda(ruido(s), 80, 900) * (0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 6 * t))) * env(n_(s), 0.3, 3.0, 0.5, 0.6)
    return reverb(mezclar(engr, paso_bajo(osc(40, s, "sierra"), 150) * 0.5, en(golpe_sordo(40, 1.5), 3.2, 5.0)), 3.5, 0.55, 1500)


# ---------------------------------------------------------- Metal y golpes ---

@sonido("golpe_metalico")
def _():
    x = mezclar(metal(110, 4.5, 1.2, 1.6), golpe_sordo(55, 1.0) * 0.7)
    return reverb(x, 3.5, 0.45, 5000)


@sonido("impacto_muerte")
def _():
    return reverb(mezclar(golpe_sordo(40, 1.4, 0.6), paso_bajo(ruido(0.3), 800) * caida(n_(0.3), 0.06)), 2.0, 0.4, 1500)


@sonido("golpe_mesa")
def _():
    return reverb(mezclar(metal(210, 1.0, 0.8, 0.6) * 0.7, golpe_sordo(75, 0.5)), 1.2, 0.35)


@sonido("mecanismo_fin")
def _():
    return reverb(mezclar(golpe_sordo(50, 0.8), metal(120, 2.0, 0.6) * 0.6), 2.5, 0.5, 2500)


@sonido("engranajes")
def _():
    s = 2.5
    t = t_(s)
    return reverb(banda(ruido(s), 150, 1500) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 11 * t))) * env(n_(s), 0.05, 2.0, 0.4, 0.3), 2.5, 0.5, 2000)


@sonido("cobertura_rota")
def _():
    x = np.zeros(n_(1.6))
    for _i in range(14):
        x += en(banda(ruido(0.12), 200, 3500) * caida(n_(0.12), 0.04) * rng.uniform(0.3, 1.0), rng.uniform(0, 0.6), 1.6)
    return reverb(mezclar(x, golpe_sordo(60, 0.8)), 1.5, 0.4, 2500)


@sonido("derribar")
def _():
    x = mezclar(metal(240, 1.2, 0.7, 0.6) * 0.7, golpe_sordo(80, 0.5))
    for _i in range(5):
        x = mezclar(x, en(banda(ruido(0.08), 500, 5000) * caida(n_(0.08), 0.02) * 0.5, rng.uniform(0.1, 0.6), 1.2))
    return reverb(x, 1.2, 0.35, 4000)


@sonido("tropiezo")
def _():
    return mezclar(golpe_sordo(70, 0.4), banda(ruido(0.2), 300, 2500) * caida(n_(0.2), 0.05) * 0.6)


@sonido("verja")
def _():
    x = np.zeros(n_(1.5))
    for k in range(4):
        x += en(metal(rng.uniform(300, 500), 0.8, 1.0, 0.6) * 0.6, k * 0.15, 1.5)
    return reverb(x, 1.6, 0.4)


@sonido("caja_fuerte")
def _():
    t = t_(1.4)
    chir = resonante(ruido(1.4), 700 + 300 * t, 25) * env(n_(1.4), 0.1, 1.0, 0.3, 0.2) * 0.5
    return reverb(mezclar(en(metal(900, 0.3, 1.2) * 0.6, 0, 1.4), en(chir, 0.3, 2.0)), 1.0, 0.3)


@sonido("cerrojo_lejano")
def _():
    return reverb(paso_bajo(mezclar(metal(500, 0.5, 1.0), en(metal(300, 0.8, 0.8), 0.15, 1.0)), 2500) * 0.6, 3.0, 0.75, 1800)


@sonido("llave_cae")
def _():
    x = np.zeros(n_(1.0))
    for k, (tt, a) in enumerate([(0.0, 1.0), (0.18, 0.5), (0.31, 0.3), (0.4, 0.15)]):
        x += en(metal(2600 + k * 120, 0.25, 1.8, 0.3) * a, tt, 1.0)
    return reverb(x, 1.5, 0.35, 6000)


@sonido("esposas")
def _():
    return mezclar(en(metal(2000, 0.15, 2.0, 0.3), 0, 0.5), en(metal(1500, 0.3, 1.5, 0.3), 0.12, 0.5))


@sonido("cuerda_cruje")
def _():
    s = 2.5
    x = np.zeros(n_(s))
    for k in range(3):
        t = t_(0.6)
        c = resonante(ruido(0.6), 300 + 120 * np.sin(np.pi * t[0]), 15) * np.sin(np.linspace(0, np.pi, n_(0.6))) * 0.6
        x += en(c, 0.2 + k * 0.75, s)
    return reverb(x, 2.0, 0.5, 2000)


@sonido("energia")
def _():
    s = 2.0
    t = t_(s)
    zumbido = osc(50 + 70 * np.clip(t / 0.8, 0, 1), s, "sierra") * env(n_(s), 0.6, 0.6, 0.6, 0.6) * 0.5
    return reverb(mezclar(en(banda(ruido(0.15), 1000, 8000) * 0.8, 0, s), paso_bajo(zumbido, 1500)), 1.5, 0.4)


@sonido("ascensor_motor")
def _():
    s = 6.0
    t = t_(s)
    motor = paso_bajo(osc(45 + 10 * np.clip(t / 2, 0, 1), s, "sierra"), 400) * env(n_(s), 0.8, 4.0, 0.7, 1.0)
    chirrido = resonante(ruido(s), 1600, 30) * 0.08 * (0.5 + 0.5 * np.sin(2 * np.pi * 0.7 * t))
    return reverb(mezclar(motor, chirrido, en(metal(130, 1.5, 0.6) * 0.4, 0.1, s)), 2.0, 0.4)


@sonido("ascensor_llega")
def _():
    return reverb(mezclar(golpe_sordo(45, 1.2), metal(140, 2.0, 0.6) * 0.5), 2.0, 0.45)


@sonido("arrastre_lejano")
def _():
    s = 5.0
    t = t_(s)
    roce = banda(ruido(s), 200, 1800) * (0.5 + 0.5 * np.abs(np.sin(2 * np.pi * 0.7 * t))) * env(n_(s), 1.0, 3.0, 0.6, 1.0)
    return reverb(paso_bajo(roce, 1200) * 0.6, 5.0, 0.85, 1200)


@sonido("alarma")
def _():
    s = 3.0
    t = t_(s)
    claxon = paso_bajo(osc(440, s, "cuadrada") * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 2.5 * t))), 2500)
    return reverb(claxon * env(n_(s), 0.01, 0.1, 0.8, 0.6) * 0.6, 3.0, 0.5, 2500)


@sonido("silbato")
def _():
    s = 1.4
    t = t_(s)
    f = 2900 + 120 * np.sign(np.sin(2 * np.pi * 28 * t))
    x = osc(f, s) * env(n_(s), 0.03, 0.2, 0.8, 0.3) * 0.6 + banda(ruido(s), 2500, 4000) * 0.1
    return reverb(x, 1.5, 0.35, 6000)


@sonido("megafonia")
def _():
    clic = banda(ruido(0.06), 500, 4000) * caida(n_(0.06), 0.01)
    retro = resonante(ruido(0.9), 1250, 60) * env(n_(0.9), 0.3, 0.4, 0.3, 0.2) * 0.4
    return reverb(mezclar(clic, en(retro, 0.1, 1.2)), 2.5, 0.6, 3000)


@sonido("deteccion")
def _():
    s = 2.5
    cuerdas = sum(paso_bajo(osc(f * (1 + 0.004 * k), s, "sierra"), 3000) for k, f in enumerate((233, 247, 349, 370)))
    cuerdas *= env(n_(s), 0.01, 0.4, 0.5, 1.5)
    return reverb(mezclar(cuerdas * 0.4, golpe_sordo(45, 0.8) * 0.6), 2.5, 0.5, 4000)


@sonido("latido")
def _():
    return paso_bajo(mezclar(golpe_sordo(50, 0.35), en(golpe_sordo(45, 0.3) * 0.7, 0.26, 0.7)), 300)


@sonido("patio_revelacion")
def _():
    s = 7.0
    t = t_(s)
    oleada = paso_bajo(sum(osc(f, s, "sierra") for f in (55, 82.4, 110, 164.8)), 200 + 1500 * np.clip(t / 5, 0, 1))
    oleada *= env(n_(s), 3.0, 2.0, 0.6, 2.0)
    return reverb(mezclar(oleada * 0.5, en(metal(60, 5.0, 0.4, 1.8) * 0.6, 3.0, s)), 6.0, 0.7, 1800)


@sonido("director_presencia")
def _():
    s = 6.0
    sub = paso_bajo(osc(31, s, "sierra") + osc(46.5, s, "sierra"), 160) * env(n_(s), 1.0, 2.0, 0.6, 2.5)
    coro = voz(s, 82, [(400, 5, 1.0), (800, 5, 0.6), (2500, 8, 0.2)], 0.008, 0.15) * env(n_(s), 2.0, 1.0, 0.6, 2.5) * 0.3
    return reverb(mezclar(sub, coro, golpe_sordo(35, 2.0) * 0.6), 5.0, 0.65, 1500)


@sonido("tela")
def _():
    return banda(ruido(0.6), 600, 5000) * np.sin(np.linspace(0, np.pi, n_(0.6))) ** 1.5 * 0.7


@sonido("susurro")
def _():
    s = 2.5
    x = np.zeros(n_(s))
    for _i in range(6):
        d = rng.uniform(0.2, 0.5)
        x += en(banda(ruido(d), 2500, 7000) * np.sin(np.linspace(0, np.pi, n_(d))) * 0.5, rng.uniform(0, s - d), s)
    return reverb(x, 2.0, 0.55, 6000)


@sonido("recuento")
def _():
    s = 4.0
    x = np.zeros(n_(s))
    for k in range(6):
        d = 0.35
        x += en(voz(d, 90, [(600, 5, 1.0), (1200, 6, 0.4)], 0.0, 0.8) * np.sin(np.linspace(0, np.pi, n_(d))) * 0.4, 0.3 + k * 0.6, s)
    return reverb(paso_bajo(x, 1800), 2.5, 0.6, 2000)


@sonido("llaves_carrera")
def _():
    x = np.zeros(n_(1.5))
    for _i in range(16):
        x += en(metal(rng.uniform(2200, 4200), 0.2, 2.0, 0.25) * rng.uniform(0.3, 0.7), rng.uniform(0, 1.2), 1.5)
    return reverb(x, 1.2, 0.4, 5000)


@sonido("pelea_patio")
def _():
    s = 3.5
    x = np.zeros(n_(s))
    for _i in range(10):
        d = rng.uniform(0.3, 0.8)
        curva = np.linspace(rng.uniform(180, 260), rng.uniform(140, 200), 6)
        x += en(voz(d, 200, [(800, 4, 1), (1400, 5, 0.6)], 0.05, 0.5, curva) * np.sin(np.linspace(0, np.pi, n_(d))) * 0.4,
                rng.uniform(0, s - d), s)
    return reverb(x, 2.5, 0.6, 2500)


@sonido("pelota", True)
def _():
    s = 4.0
    x = np.zeros(n_(s))
    for k in range(5):
        x += en(golpe_sordo(140, 0.15, 0.6) * 0.6, 0.3 + k * 0.8, s)
    return bucle(reverb(x, 2.0, 0.5, 3000), 0.3)


# -------------------------------------------------------------- Jugador ---

@sonido("recoger")
def _():
    return mezclar(banda(ruido(0.3), 800, 5000) * env(n_(0.3), 0.02, 0.2, 0.1, 0.05) * 0.5, metal(1400, 0.2, 1.5, 0.3) * 0.2)


@sonido("recoger_arma")
def _():
    return mezclar(en(metal(1100, 0.2, 1.4, 0.3), 0, 0.6), en(metal(700, 0.3, 1.0, 0.3), 0.15, 0.6))


@sonido("carpeta")
def _():
    return mezclar(SONIDOS["papel"][0](), en(golpe_sordo(120, 0.2) * 0.5, 0.3, 0.6))


@sonido("esconderse")
def _():
    t = t_(0.9)
    return mezclar(resonante(ruido(0.9), 600 + 300 * t, 18) * env(n_(0.9), 0.05, 0.7, 0.2, 0.1) * 0.4,
                   en(metal(380, 0.6, 0.8) * 0.5, 0.7, 1.4))


@sonido("lanzar")
def _():
    return banda(ruido(0.4), 300, 3000) * np.sin(np.linspace(0, np.pi, n_(0.4))) * 0.6


@sonido("botella_rota")
def _():
    x = np.zeros(n_(1.0))
    for _i in range(18):
        x += en(metal(rng.uniform(2500, 6000), 0.25, 2.0, 0.2) * rng.uniform(0.2, 0.6), rng.uniform(0, 0.15), 1.0)
    return reverb(mezclar(x, banda(ruido(0.2), 2000, 9000) * caida(n_(0.2), 0.04)), 1.2, 0.35, 7000)


@sonido("lata")
def _():
    x = np.zeros(n_(1.2))
    for k, a in enumerate((1.0, 0.6, 0.35, 0.2)):
        x += en(metal(rng.uniform(900, 1300), 0.3, 1.2, 0.3) * a, k * 0.2, 1.2)
    return reverb(x, 1.2, 0.35, 5000)


@sonido("saltar_obstaculo")
def _():
    return mezclar(banda(ruido(0.4), 400, 3000) * np.sin(np.linspace(0, np.pi, n_(0.4))) * 0.5, en(_paso(3000, 150), 0.45, 0.8))


@sonido("jadeo")
def _():
    s = 2.4
    x = np.zeros(n_(s))
    for k in range(4):
        x += en(banda(ruido(0.35), 500, 2600) * np.sin(np.linspace(0, np.pi, n_(0.35))) ** 2 * 0.7, k * 0.55, s)
    return x


@sonido("respiracion_despertar")
def _():
    jadeo = banda(ruido(0.8), 400, 3000) * np.concatenate([np.linspace(0, 1, n_(0.15)), np.linspace(1, 0, n_(0.65))]) ** 2
    return reverb(mezclar(jadeo, en(SONIDOS["jadeo"][0]() * 0.5, 0.9, 3.5)), 1.2, 0.3)


@sonido("fluorescente_arranque")
def _():
    s = 2.5
    x = np.zeros(n_(s))
    for k in range(5):
        x += en(banda(ruido(0.04), 1000, 6000) * 0.6, k * 0.22 + rng.uniform(0, 0.08), s)
    zumbido = (osc(100, s, "sierra") * 0.2 + osc(200, s) * 0.15) * np.clip((t_(s) - 1.2) / 0.3, 0, 1)
    return mezclar(x, zumbido)


@sonido("arma_vacia")
def _():
    return metal(1800, 0.12, 2.0, 0.3) * 0.6


@sonido("disparo_pistola")
def _():
    x = mezclar(banda(ruido(0.3), 200, 7000) * caida(n_(0.3), 0.05), golpe_sordo(80, 0.4) * 0.8, metal(1600, 0.15, 2.0, 0.2) * 0.2)
    return reverb(x, 2.5, 0.5, 4000)


@sonido("disparo_escopeta")
def _():
    x = mezclar(banda(ruido(0.5), 80, 6000) * caida(n_(0.5), 0.09), golpe_sordo(50, 0.7) * 1.0)
    return reverb(x, 3.0, 0.55, 3500)


@sonido("recargar_pistola")
def _():
    return mezclar(en(metal(1300, 0.15, 1.5, 0.3) * 0.6, 0.0, 1.4), en(metal(900, 0.2, 1.2, 0.3) * 0.7, 0.7, 1.4),
                   en(metal(1600, 0.15, 1.6, 0.3) * 0.5, 1.15, 1.4))


@sonido("recargar_escopeta")
def _():
    x = np.zeros(n_(2.2))
    for k in range(2):
        x += en(metal(800, 0.2, 1.3, 0.3) * 0.6, 0.3 + k * 0.6, 2.2)
    return mezclar(x, en(metal(500, 0.3, 1.0, 0.4) * 0.8, 1.8, 2.2), en(golpe_sordo(150, 0.2) * 0.4, 1.85, 2.2))


@sonido("impacto_bala")
def _():
    return mezclar(banda(ruido(0.15), 1500, 8000) * caida(n_(0.15), 0.03), metal(2400, 0.3, 1.5, 0.3) * 0.3)


@sonido("impacto_carne")
def _():
    return mezclar(golpe_sordo(90, 0.25, 0.8), banda(ruido(0.2), 300, 2500) * caida(n_(0.2), 0.05) * 0.5)


@sonido("punzon")
def _():
    return mezclar(SONIDOS["impacto_carne"][0](), banda(ruido(0.1), 2000, 8000) * caida(n_(0.1), 0.02) * 0.4)


# ------------------------------------------------------------ Enemigos ---

@sonido("aislado_grunido")
def _():
    d = 1.4
    curva = np.linspace(rng.uniform(85, 105), 70, 6)
    return reverb(voz(d, 90, [(350, 4, 1.0), (850, 5, 0.5), (2300, 7, 0.2)], 0.05, 0.9, curva) * env(n_(d), 0.2, 0.6, 0.4, 0.5), 1.2, 0.3)


@sonido("aislado_alerta")
def _():
    d = 1.2
    curva = [160, 340, 300, 220]
    return reverb(voz(d, 200, [(700, 3, 1.0), (1300, 4, 0.6), (2800, 6, 0.3)], 0.08, 1.2, curva) * env(n_(d), 0.03, 0.4, 0.5, 0.5), 1.5, 0.35)


@sonido("aislado_muere")
def _():
    d = 1.6
    return reverb(voz(d, 120, [(450, 4, 1.0), (900, 5, 0.5)], 0.05, 0.8, [130, 110, 70, 50]) * env(n_(d), 0.05, 1.0, 0.2, 0.4), 1.5, 0.35)


@sonido("ataque_aislado_a")
def _():
    return mezclar(SONIDOS["aislado_alerta"][0](), golpe_sordo(70, 0.4) * 0.6)


@sonido("ataque_aislado_b")
def _():
    return mezclar(SONIDOS["aislado_alerta"][0]() * 0.8, golpe_sordo(60, 0.5) * 0.7)


@sonido("ataque_el_uniforme")
def _():
    return reverb(mezclar(SONIDOS["llaves_carrera"][0]() * 0.5, golpe_sordo(45, 0.8), paso_bajo(voz(1.2, 70, [(300, 4, 1.0), (700, 5, 0.4)], 0.0, 1.0), 900) * 0.5), 1.5, 0.4)


@sonido("ataque_policia_patrullero")
def _():
    d = 0.8
    grito = voz(d, 160, [(650, 4, 1.0), (1100, 5, 0.7), (2500, 7, 0.3)], 0.03, 0.4, [150, 190, 170])
    return reverb(mezclar(grito * env(n_(d), 0.03, 0.3, 0.6, 0.2), en(golpe_sordo(65, 0.5), 0.5, 1.2)), 1.0, 0.3)


@sonido("ataque_guardia_penitenciario")
def _():
    return SONIDOS["ataque_policia_patrullero"][0]()


@sonido("ataque_el_condenado")
def _():
    return mezclar(SONIDOS["condenado_grito"][0](), golpe_sordo(50, 0.8))


@sonido("ataque_la_sentencia")
def _():
    silbido = banda(ruido(0.6), 300, 4000) * np.linspace(0.1, 1.0, n_(0.6)) * 0.6
    return reverb(mezclar(silbido, en(metal(70, 2.5, 0.6, 1.2), 0.55, 3.0), en(golpe_sordo(35, 1.5), 0.55, 3.0)), 2.5, 0.5, 2000)


@sonido("condenado_grito")
def _():
    d = 1.4
    grito = voz(d, 300, [(900, 2, 1.0), (2200, 3, 0.7), (3500, 4, 0.4)], 0.12, 1.5, [260, 420, 380, 300])
    return reverb(mezclar(grito * env(n_(d), 0.01, 0.6, 0.3, 0.6), SONIDOS["susurro"][0]() * 0.5), 2.0, 0.5, 5000)


@sonido("vigilante_alerta")
def _():
    s = 2.5
    t = t_(s)
    whoop = paso_bajo(osc(400 + 600 * (t % 0.8) / 0.8, s, "sierra"), 2500) * env(n_(s), 0.02, 0.2, 0.8, 0.5) * 0.5
    return reverb(whoop, 4.0, 0.6, 3000)


@sonido("sentencia_rugido")
def _():
    d = 2.6
    rugido = voz(d, 55, [(250, 3, 1.0), (600, 4, 0.7), (1400, 5, 0.3)], 0.06, 2.0, [50, 70, 62, 45])
    rugido = np.tanh(rugido * 3.0)
    return reverb(mezclar(rugido * env(n_(d), 0.2, 1.2, 0.5, 0.9), golpe_sordo(32, 1.5) * 0.6), 3.0, 0.55, 1800)


def main():
    pedidos = sys.argv[1:]
    print("Generando sonidos en", DESTINO)
    for nombre, (fn, es_bucle) in SONIDOS.items():
        if pedidos and nombre not in pedidos:
            continue
        guardar(nombre, fn(), es_bucle)
    print("Listo:", len(pedidos) if pedidos else len(SONIDOS), "sonidos")


if __name__ == "__main__":
    main()
