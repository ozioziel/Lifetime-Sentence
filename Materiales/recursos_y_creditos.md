# LIFETIME SENTENCE — RECURSOS, LICENCIAS, IA Y CRÉDITOS

Registro **obligatorio** de todo recurso usado en el proyecto: externo, propio o generado con IA. Ningún recurso entra al juego sin estar anotado aquí.
Última actualización: **2026-11-13**. No se ha incorporado ningún recurso de terceros. Todo lo creado hasta ahora es propio y está hecho con IA: se detalla en las secciones 3.1 (Godot) y 3.2 (Blender).

> **Uso para la GUILD Game Jam 2026.** El reglamento exige **declarar los recursos de terceros, el uso de IA y los materiales creados antes de la jam**. La IA no declarada y los recursos sin licencia son causa de **descalificación**. Este documento es la fuente para esa declaración (sección 5).

## Reglas (confirmadas por el creador)

1. **Prohibido**: recursos de pago, licencias **no comerciales (NC)**, recursos sin licencia verificable, recursos extraídos de juegos comerciales y servicios o modelos de IA de pago o con créditos.
2. **Preferente**: creación propia y **CC0**.
3. **Permitido**: **CC BY** y licencias equivalentes cuyo único requisito sea citar al autor. **Siempre se cita**, aunque la licencia no lo exija.
4. **Todo lo hecho con IA se declara** en los créditos y en este documento.
5. Para cada recurso externo se registran: archivo en el proyecto, autor, enlace de origen, licencia (con enlace), fecha de verificación, modificaciones y texto de atribución.

---

## 1. Recursos externos de terceros

*Vacío.*

| Archivo en el proyecto | Recurso / autor | Enlace | Licencia | Verificado | Modificado | Texto de atribución |
|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — |

## 2. Tipografías

*Vacío.* Solo fuentes con licencia **OFL**, Apache 2.0 o equivalentes.

| Fuente | Autor | Enlace | Licencia | Uso |
|---|---|---|---|---|
| — | — | — | — | — |

## 3. Contenido generado o asistido con IA

| Contenido | Herramienta de IA | Quién la operó | Estado / uso |
|---|---|---|---|
| Arte conceptual de referencia: 8 imágenes de `Materiales/` (moodboards, escenas y láminas de enemigos) | **ChatGPT (OpenAI)** | Equipo de Lifetime Sentence | Referencia de estilo **y material directo** (carteles, emblemas, texturas, recortes), autorizado en L3. Cada recorte usado se anotará en 3.1 |
| Planificación y documentación (`planeacion.md`, este documento, `pendientes_equipo.md`, `herramientas_instaladas.md`) | **Claude (Anthropic)**, vía Claude Code | Equipo + Claude | En uso |
| Código, escenas, shaders, modelos 3D, texturas, animaciones, sonido procedural y guías | **Claude (Anthropic)**, vía Claude Code, usando Godot, Blender y Python | Claude, bajo dirección del equipo | Se detallará **por archivo** a medida que se creen |

### 3.1. Detalle por recurso generado con IA

Creado en la **etapa 1, bloque 1.1** (base en Godot, estética PS1, movimiento y cámara). Todo es obra de Claude (Anthropic) bajo la dirección del equipo, sin partir de recursos de terceros. Todo se verificó en ejecución el 12-11-2026 (ver `planeacion.md` §11.1).

| Archivo | Tipo | Herramienta | Cómo se hizo | Fecha | Situación |
|---|---|---|---|---|---|
| `juego/assets/texturas/provisional/` (6 imágenes: `concreto`, `pared_celda`, `suelo`, `techo`, `metal_oxidado`, `metal_pintado`) | Texturas provisionales de 64 y 128 px | Claude + Python (numpy y Pillow) | Ruido procedural y reducción a una paleta corta, con el script de la fila siguiente | 12-11-2026 | Provisionales: se sustituyen en el bloque 1.2. Revisadas |
| `fuentes_arte/scripts/generar_texturas_provisionales.py` | Script de Python | Claude | Escrito por la IA | 12-11-2026 | Funciona: generó las 6 texturas |
| `juego/render/ps1_superficie.gdshader`, `ps1_comun.gdshaderinc`, `ps1_post.gdshader`, `escalado_nitido.gdshader` | Shaders (estética PS1) | Claude | Escritos por la IA para este proyecto | 12-11-2026 | Compilan y dibujan en los tres renderizadores |
| `juego/render/render_rig.gd`, `render_rig.tscn`, `perfil_epoca.gd`, `epoca_presente.tres`, `epoca_pasado.tres` | Sistema de render y perfiles de época | Claude | Escritos por la IA | 12-11-2026 | Verificado |
| `juego/jugador/` (`jugador.gd`, `jugador.tscn`, `camara_jugador.gd`, `maniqui.gd`, `perfil_movimiento.gd`, `movimiento_presente.tres`, `movimiento_pasado.tres`) | Jugador provisional, cámara y maniquí de cajas | Claude | Escritos por la IA. El maniquí son cajas, no un modelo | 12-11-2026 | Verificado. El maniquí se sustituye en el bloque 1.3 |
| `juego/componentes/` (`camera_zone.gd`, `camera_zone.tscn`, `luz_fluorescente.gd`, `luz_fluorescente.tscn`) | Componentes reutilizables | Claude | Escritos por la IA | 12-11-2026 | Verificado |
| `juego/autoload/settings.gd`, `juego/autoload/debug_tools.gd` | Ajustes y herramientas de prueba | Claude | Escritos por la IA | 12-11-2026 | Verificado |
| `juego/project.godot`, `juego/herramientas/configurar_proyecto.gd` | Configuración del proyecto y controles | Claude + Godot | El script lo escribió la IA; Godot generó `project.godot` al ejecutarlo | 12-11-2026 | Generado correctamente |
| `.gitignore`, `.gitattributes` | Configuración del repositorio | Claude | Escritos por la IA | 12-11-2026 | Listos; sin `git init` |
| `juego/assets/materiales/provisional/` (6 materiales) y `juego/assets/modelos/provisional/` (3 mallas de reja) | Materiales y mallas provisionales | Claude + Godot | Los materiales los escribió la IA; las mallas las genera `construir_caja_gris.gd` | 12-11-2026 | Verificado. Se sustituyen en el bloque 1.2 |
| `juego/niveles/pruebas/caja_gris.tscn` y `juego/herramientas/construir_caja_gris.gd` | Escena de prueba y su script constructor | Claude + Godot | El script lo escribió la IA; Godot generó la escena al ejecutarlo | 12-11-2026 | Verificado. Se sustituye en el bloque 1.2 |
| `juego/export_presets.cfg` | Configuración de exportación a Windows | Claude | Escrito por la IA | 12-11-2026 | Verificado: exporta un `.exe` que arranca |
| `herramientas/instalar_plantillas_windows.py` | Script de instalación | Claude | Escrito por la IA | 12-11-2026 | Verificado: instaló las plantillas |
| `docs/COMO_EJECUTAR.md`, `docs/GUIA_EQUIPO.md` | Documentación | Claude | Escritas por la IA | 12-11-2026 | Primer borrador |
| `docs/capturas/bloque_1_1/` (10 imágenes) | Capturas del juego | Godot | Capturas automáticas de la escena de prueba | 12-11-2026 | Para revisión del creador |
| `juego/autoload/` (`juego.gd`, `audio.gd`, `guardado.gd`, `interfaz.gd`, `settings.gd`, `debug_tools.gd`), `juego/ui/`, `juego/datos/` | Sistemas del juego, interfaz, menús, créditos y textos (documentos, guion) | Claude | Escritos por la IA; los textos narrativos siguen la biblia de §4.5 de la planeación | 14-11-2026 | En uso; verificados con la prueba automática |
| `juego/jugador/`, `juego/personajes/`, `juego/componentes/`, `juego/enemigos/` | Jugador, personajes animados, componentes (puertas, escondites, mecanismos, espejos, lluvia…) e IA de los enemigos | Claude | Escritos por la IA | 14-11-2026 | En uso |
| `juego/niveles/` (8 niveles) y `juego/herramientas/niveles/` (sus constructores), `juego/ui/fondo_cinematico.tscn` | Niveles montados sobre los escenarios de Blender, con luces, cámaras, cinemáticas y lógica | Claude + Godot | Los constructores los escribió la IA; Godot generó los `.tscn` al ejecutarlos | 14-11-2026 | En uso |
| `juego/assets/audio/` (125 `.ogg`) y `assets/scripts/generar_audio.py` | Efectos y ambientes de sonido | Claude + Python (numpy, scipy) + FFmpeg | **Síntesis procedural original** (ruido filtrado, osciladores, metal inarmónico, formantes, reverberación por convolución). Sin muestras de terceros | 14-11-2026 | En uso |
| `juego/icono.png`, `juego/icono.ico` | Icono del juego | Claude + Pillow | Dibujado por código (marcas de conteo y sello) | 14-11-2026 | En uso |
| `assets/escenarios/bloque_a_juego.blend` y `juego/assets/escenarios/bloque_a_juego.glb` | Versión del Bloque A para el juego | Claude + Blender | Mismas piezas del kit, con la puerta de la celda como objeto aparte y sin solapes; el escenario del plano aprobado no cambia | 14-11-2026 | En uso |
| `juego/assets/personajes/`, `kits/`, `escenarios/` (`.glb`) | Exportación de Blender a Godot | Claude + Blender | `assets/scripts/exportar_godot.py`; materiales convertidos al shader PS1 por `juego/herramientas/importar_ps1.gd` | 13/14-11-2026 | En uso |
| `docs/FUNCIONES_Y_LIMITACIONES.md`, `docs/COMO_EXPORTAR.md`, `docs/SUBIR_A_GITHUB.md`, `CREDITOS.md`, `entregas/TEXTOS_ENTREGA.md`; nuevas versiones de `docs/COMO_EJECUTAR.md` y `docs/GUIA_EQUIPO.md` | Documentación de entrega | Claude | Escrita por la IA | 14-11-2026 | Para revisión del equipo |

### 3.2. Assets de Blender (carpeta `assets/`)

Creados el 12-11-2026 por encargo del creador («haz en Blender... todos los personajes y la cárcel»). Todo lo genera Claude (Anthropic) con scripts de Python para Blender 5.2; ver `assets/LEEME.md`.

| Archivo | Tipo | Herramienta | Cómo se hizo | Situación |
|---|---|---|---|---|
| `assets/scripts/*.py` | Generadores de personajes, kit, escenario y planos | Claude | Escritos por la IA | En uso |
| `assets/personajes/*.blend` (18 personajes: Elías preso y civil, El Uniforme, Los Aislados A y B, El Vigilante, El Condenado, La Sentencia, El Director, policía patrullero y táctico, guardia, interrogador, verdugo, alcaide y 3 presos genéricos) | Personajes low-poly con esqueleto (estilo PS1) | Claude + Blender | Cuerpo por anillos y cabeza modelada vértice a vértice (`CABEZA_PS1`). Pelo en casco facetado con mechones gruesos. Accesorios y atlas de 512 px pintado por código a media resolución, a partir de las láminas de enemigos | En revisión con el creador |
| Animaciones de los 18 personajes (acciones dentro de `assets/personajes/*.blend`), `assets/animaciones/manifiesto.json` y los vídeos de `assets/renders/animaciones/` | Animación por esqueleto | Claude + Blender | Poses calculadas por código (cinemática directa e IK de dos huesos) con `assets/scripts/animaciones.py`; sin captura de movimiento ni animaciones de terceros | En revisión con el creador |
| `assets/kit/kit_prision.blend`, `kit_bloque_a.blend`, `kit_ciudad.blend`, `kit_interiores.blend` | Kits modulares (prisión, Bloque A, ciudad, interiores) | Claude + Blender | Geometría y texturas por código; los rótulos usan una fuente de píxeles de 3 x 5 dibujada en el propio script | Hecho |
| `assets/escenarios/` (`patio_central`, `bloque_a`, `callejon`, `enfermeria`, `comisaria`, `ejecucion`, `nucleo`, `prision_pasado`) | Escenarios | Claude + Blender | Montados con piezas enlazadas de los kits | Hecho, en revisión |
| `assets/escenas/` (8 planos: patio, pasillo, callejón, enfermería, interrogatorio, ejecución, núcleo, huida en el pasado) | Planos cinematográficos | Claude + Blender | Escenario y personajes enlazados, cámara y luces propias | Hecho, en revisión |
| `assets/texturas/referencia/cartel_se_busca.png` | Cartel «SE BUSCA» del callejón | Claude + Blender | **Recorte del arte conceptual `43f1fd2b-...png` (ChatGPT, OpenAI)**, uso autorizado en L3 | En uso |
| `assets/texturas/personajes/`, `assets/texturas/escenario/` | Texturas pixeladas | Claude + Blender (numpy) | Ruido procedural y pintura por código | Hecho |
| `assets/texturas/referencia/` (camisa, piel y otras muestras) | Muestras de material | Claude + Pillow | **Recortes del arte conceptual de `Materiales/`, generado con ChatGPT (OpenAI)**; uso autorizado en L3. La camisa y la piel de Elías mezclan estas muestras con textura procedural | En uso |
| `assets/renders/` | Imágenes de revisión | Blender (EEVEE) | Renders de los planos y láminas de personajes | Para revisión del creador |

## 4. Texto de créditos

### 4.1. Créditos finales del juego (C-20)

Tras «FIN DE LA DEMO», solo estos dos nombres, alternándose sobre secuencias del juego:

> **Oziel Rodman Ramos Torrez**
> **Christopher Barea Salazar**

### 4.2. Créditos y licencias (pantalla del menú, `CREDITOS.md` y también en los créditos finales) — *confirmado en Q3*

Cada atribución se reproduce **exactamente como la exija su autor o licencia** (texto, enlace, nombre de licencia, aviso de cambios). Si un autor pide algo concreto, prevalece sobre este formato.

Borrador:

> **LIFETIME SENTENCE — Demo**
> Creado por Oziel Rodman Ramos Torrez y Christopher Barea Salazar.
> Desarrollado con asistencia de inteligencia artificial: Claude (Anthropic) en programación, modelado 3D, texturas, animación, sonido y documentación. Arte conceptual de referencia generado con ChatGPT (OpenAI).
> Hecho con Godot Engine (licencia MIT) y Blender.
> Recursos de terceros: *(lista de la sección 1 con su atribución)*.
> Tipografías: *(lista de la sección 2)*.

### 4.3. Aviso legal de Godot

Godot Engine se distribuye bajo licencia MIT, que exige incluir su aviso de copyright en el juego exportado. Se añadirá a la pantalla de créditos y licencias.

## 5. Declaración para la GUILD Game Jam 2026 (borrador)

### 5.1. Materiales creados antes del inicio del desarrollo

*Confirmar con el equipo las fechas del periodo oficial (J1).*

| Material | Fecha | Herramienta | Notas |
|---|---|---|---|
| `contexto_absoluto_del_proyecto.md` (concepto, historia, enemigos, dirección de arte) | 11-11-2026 | Conversación con un asistente de IA | Documento de diseño |
| 8 imágenes de arte conceptual en `Materiales/` | 11-11-2026 | ChatGPT (OpenAI) | Referencias visuales y material autorizado (L3) |
| Planificación (`planeacion.md` y documentos asociados) | 12-11-2026 | Claude (Anthropic) | Sin código ni assets del juego |

### 5.2. Uso de IA

Ver sección 3. Se declarará: Claude (Anthropic) en código, modelos, texturas, animación, sonido y documentación; ChatGPT (OpenAI) en arte conceptual.

### 5.3. Recursos de terceros

Ver secciones 1 y 2. Por ahora, ninguno.
