# LIFETIME SENTENCE — HERRAMIENTAS INSTALADAS Y UTILIZADAS

Registro de todo el software que usa el proyecto: lo que ya estaba en el equipo y lo que se instale. Así cualquier miembro del equipo puede reproducir el entorno.
Última actualización: **2026-11-12 (planeación v1.2)**.

**Regla:** antes de instalar una herramienta importante se consulta al creador. Toda instalación se anota aquí con versión, origen, licencia y motivo.

---

## 1. Ya instaladas en el portátil principal (detectadas el 2026-11-12)

| Herramienta | Versión | Ruta | Licencia | Uso en el proyecto |
|---|---|---|---|---|
| Godot Engine | 4.7.2 stable (win64) | `C:\Users\jojoj\Desktop\ARCADE\Godot_v4.7.2-stable_win64.exe` | MIT | Motor del juego |
| Plantillas de exportación de Godot | 4.7.2 (Linux) | `%APPDATA%\Godot\export_templates\4.7.2.stable\` | MIT | Las de Windows se instalaron el 12-11-2026 (ver §3) |
| Blender | 5.2 | `C:\Program Files\Blender Foundation\Blender 5.2\` | GPL | Modelado, rigging, animación, texturizado, horneado |
| FFmpeg | 9.0.2 (build «full» de gyan.dev) | En el PATH (WinGet) | GPL | Conversión y normalización de audio y vídeo |
| Python | 3.10 | `%LOCALAPPDATA%\Programs\Python\Python310\` | PSF | Generación procedural de texturas y sonido, scripts de Blender |
| scipy | 1.15.3 | En el Python del sistema | BSD | Filtros y convolución del sonido procedural (`assets/scripts/generar_audio.py`). Ya estaba instalada; no se ha instalado nada |
| Git | 2.54.0 | `C:\Program Files\Git\` | GPL v2 | Control de versiones |
| Git LFS | 3.7.1 | Incluido con Git | MIT | Archivos grandes (`.blend`, imágenes, audio, modelos) |

**No instaladas:** GitHub CLI, Audacity, LMMS.

## 2. Instalaciones previstas (autorizadas, aún no realizadas)

*Ninguna pendiente.*

## 3. Instalaciones realizadas

| Fecha | Herramienta | Versión | Origen | Instalado por | Ruta | Notas |
|---|---|---|---|---|---|---|
| 2026-11-12 | Entorno virtual de Python (`venv`) | Python 3.10 | Módulo estándar de Python | Claude | `fuentes_arte\.venv\` | Aísla las librerías del proyecto del resto del sistema. Está excluido del repositorio (`.gitignore`). Autorizado en R1. Etapa 1, bloque 1.1 |
| 2026-11-12 | Pillow | 12.3.0 | PyPI (`pip install pillow`) | Claude | Dentro de `fuentes_arte\.venv\` | Licencia MIT-CMU (HPND). Genera y procesa texturas. Autorizado en R1 |
| 2026-11-12 | numpy | 2.2.6 | PyPI (`pip install numpy`) | Claude | Dentro de `fuentes_arte\.venv\` | Licencia BSD. Ruido procedural para texturas; más adelante, síntesis de sonido. Autorizado en R1 |
| 2026-11-12 | Plantillas de exportación de Godot para Windows (64 bits) | 4.7.2 stable | Paquete oficial `Godot_v4.7.2-stable_export_templates.tpz`, de las publicaciones de godotengine/godot en GitHub | Claude | `%APPDATA%\Godot\export_templates\4.7.2.stable\` | Licencia MIT. Se instalaron solo los 4 archivos de Windows de 64 bits y `version.txt`: 105 MB descargados en lugar del paquete completo de más de 1 GB. Se hizo con `herramientas/instalar_plantillas_windows.py`. Autorizado en TE3. Etapa 1, bloque 1.1 |

**Cómo reproducir el entorno de Python en otro PC** (desde la carpeta del proyecto):

```bash
python -m venv fuentes_arte\.venv
```

```bash
fuentes_arte\.venv\Scripts\python.exe -m pip install pillow numpy
```

## 4. Uso temporal, sin instalar nada

| Fecha | Qué | Para qué |
|---|---|---|
| 2026-11-12 | Volcado de la referencia de clases de Godot 4.7.2 (`--doctool`) en una carpeta temporal fuera del proyecto | Comprobar la API exacta de esta versión antes de escribir código |

## 5. Herramientas evaluadas y descartadas

| Herramienta | Motivo |
|---|---|
| Generación 3D del conector de Blender | Puede consumir créditos de pago (regla C-09) |
| Generación de imágenes de Canva / Figma | Consume créditos |
| HeyGen | Servicio de pago |
| rcedit (Electron, MIT) | **No instalado.** Solo serviría para poner el icono al archivo `.exe` (ver `docs/COMO_EXPORTAR.md`). Pendiente de decisión del equipo |
| CapCut | Funciones de pago y condiciones de uso dudosas; no hace falta sin tráiler |
| Three.js | Innecesario: Godot cubre el render en tiempo real |
| Generadores de imagen locales (Stable Diffusion, etc.) | La GPU integrada Intel HD 520 no puede ejecutarlos |
