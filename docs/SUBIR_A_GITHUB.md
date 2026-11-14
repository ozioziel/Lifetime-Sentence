# Subir el proyecto a GitHub (lo ejecuta el equipo)

*Claude no hace commits (Q1). Esta es la secuencia exacta, en bloques de `add` + `commit` coherentes, con Git LFS para los archivos grandes (Q2, C-14).*

## 0. Antes de empezar (una sola vez)

- Crear el repositorio vacío en GitHub, **sin README**: github.com → New repository (G-1).
- Comprobar la cuota gratuita de Git LFS (G-3). El proyecto ocupa unos **150 MB** en LFS: modelos, texturas, audio, `.blend` y renders.
- El `.exe` **no** va al repositorio (`.gitignore`). Se sube como *Release* de GitHub o directamente a la plataforma de la jam.
- Tampoco van `respaldos/`, `juego/.godot/` (caché), el entorno de Python ni los `.rar` sueltos, como `assets.rar`.

## 1. Iniciar el repositorio y Git LFS

```bash
cd "C:/Users/jojoj/Desktop/proy/LifeTime Sentence"
```

```bash
git init -b main
```

```bash
git lfs install
```

```bash
git add .gitattributes .gitignore
git commit -m "Configuración del repositorio y Git LFS"
```

## 2. Commits por áreas

Cada bloque es un commit. Se puede copiar uno a uno. Los commits no llevan coautoría: el uso de IA ya se declara en `CREDITOS.md` y en los textos de entrega.

**Documentación y planeación**

```bash
git add Materiales/*.md CREDITOS.md docs/ entregas/TEXTOS_ENTREGA.md
git commit -m "Documentación, planeación, créditos y textos de entrega"```

**Arte conceptual de referencia (ChatGPT, OpenAI)**

```bash
git add Materiales/*.png
git commit -m "Arte conceptual de referencia (generado con ChatGPT, OpenAI)"
```

**Scripts de Blender y de sonido**

```bash
git add assets/scripts assets/LEEME.md assets/animaciones
git commit -m "Scripts de Blender (kits, personajes, escenarios, animaciones) y sonido procedural"```

**Arte de Blender**

```bash
git add assets/kit assets/personajes assets/escenarios assets/escenas assets/texturas
git commit -m "Arte de Blender: kits, personajes, escenarios, planos y texturas"```

**Renders y vídeos de revisión**

```bash
git add assets/renders
git commit -m "Renders y vídeos de revisión"
```

**Fuentes de arte y herramientas de instalación**

```bash
git add fuentes_arte herramientas
git commit -m "Fuentes de arte y herramientas de instalación"
```

**Proyecto de Godot: base**

```bash
git add juego/project.godot juego/export_presets.cfg juego/icono.png juego/icono.ico juego/autoload juego/render juego/herramientas
git commit -m "Proyecto de Godot: configuración, autoloads, render PS1 y herramientas"```

**Jugador, componentes, enemigos, interfaz y textos**

```bash
git add juego/jugador juego/personajes juego/componentes juego/enemigos juego/ui juego/datos
git commit -m "Jugador, componentes, enemigos, interfaz y textos del juego"```

**Assets importados (modelos, escenarios, texturas y audio)**

```bash
git add juego/assets
git commit -m "Assets del juego: modelos, escenarios, texturas y sonido"```

**Niveles**

```bash
git add juego/niveles
git commit -m "Niveles de la demo: capítulos I a IV, recuerdos y final"```

**Lo que quede (revisar antes con git status)**

```bash
git status
```

```bash
git add -A
git commit -m "Resto de archivos del proyecto"
```

## 3. Subir a GitHub

Sustituir `USUARIO/REPOSITORIO` por el vuestro:

```bash
git remote add origin https://github.com/USUARIO/REPOSITORIO.git
```

```bash
git push -u origin main
```

La primera subida tarda: sube unos 150 MB de LFS.

## 4. Comprobar

```bash
git lfs ls-files
```

Deben aparecer los `.glb`, `.png`, `.ogg`, `.blend` y `.mp4`. Si alguno no aparece, `.gitattributes` no se aplicó antes de añadirlo. Para corregirlo:

```bash
git lfs migrate import --include="*.glb,*.png,*.ogg,*.blend,*.mp4" --everything
```

## 5. Publicar el ejecutable (opcional)

GitHub → Releases → *Draft a new release* → etiqueta `v1.0` → adjuntar `entregas/LifetimeSentence.exe`.
