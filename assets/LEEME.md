# LIFETIME SENTENCE — ASSETS DE BLENDER

Personajes, kit de la prisión, escenarios y planos cinematográficos, hechos en **Blender 5.2** con estética PS1: pocos polígonos, texturas pixeladas y luz cinematográfica.
Godot queda en pausa por decisión del creador; estos archivos se exportarán al juego más adelante.

## Carpetas

| Carpeta | Contenido |
|---|---|
| `personajes/` | Un `.blend` por personaje: esqueleto, malla y sus **animaciones** (acciones), en una colección con su nombre |
| `animaciones/` | `manifiesto.json`: lista de animaciones por personaje, con duración, bucle, velocidad de diseño y parejas |
| `kit/` | Kits de piezas modulares: `kit_prision.blend` (celdas, puente, estandarte, sábana, tragaluz, fluorescente, torre), `kit_bloque_a.blend`, `kit_ciudad.blend` y `kit_interiores.blend` (muebles, quirófano, mecanismos, pantallas, rótulos) |
| `escenarios/` | Escenarios montados con piezas **enlazadas** de los kits (uno por archivo) |
| `escenas/` | Planos cinematográficos: enlazan un escenario y los personajes, con cámara y luces propias |
| `renders/` | Imágenes de revisión. `renders/personajes/` = láminas de cada personaje; `renders/animaciones/` = vídeos y hojas de las animaciones |
| `texturas/` | Texturas pixeladas generadas. `referencia/` = muestras recortadas de las imágenes de `Materiales/` |
| `scripts/` | Scripts de Python que generan todo lo anterior (reproducibles) |

## Cómo se conectan los archivos

```
kit/kit_*.blend     ──enlazado──►  escenarios/*.blend  ──enlazado──►  escenas/plano_*.blend
personajes/*.blend  ────────────enlazado (override o instancia)────►  escenas/plano_*.blend

escenarios/patio_central.blend ──colecciones enlazadas──► escenarios/prision_pasado.blend
```

- En el plano de la prisión en el pasado, los presos y guardias del fondo son **instancias de colección** (objetos vacíos que muestran un personaje enlazado): se pueden mover, girar o duplicar a mano y apenas pesan, pero no se pueden posar uno a uno.
- `prision_pasado.blend` no copia el patio: **enlaza** sus colecciones (muros, puentes, detalles y tragaluz) y solo añade luz cálida, polvo y mundo propios. Cualquier cambio en el patio aparece también en el pasado.

- Al **editar una pieza del kit** y guardar, se actualizan el escenario y los planos que la usan.
- Los muros del patio son objetos con modificadores **Array**. Para cambiar el número de plantas o el largo, se cambia «Count» en el modificador.
- En los planos, los personajes van como **library override**: se pueden posar en esa escena sin tocar su archivo original.
- Abrir los archivos con la carpeta `assets/` completa: las rutas son relativas.

## Estado (13-11-2026)

### Personajes (`personajes/`, 18 archivos)

| Época | Personaje | Archivo | Script |
|---|---|---|---|
| — | Elías Novak, preso | `elias_preso.blend` | `personajes.py` |
| — | Elías Novak, civil (pasado) | `elias_civil.blend` | `personajes.py` |
| Presente | El Uniforme | `el_uniforme.blend` | `personajes.py` |
| Presente | Los Aislados (2 variantes) | `aislado_a.blend`, `aislado_b.blend` | `elenco.py` |
| Presente | El Vigilante | `el_vigilante.blend` | `elenco.py` |
| Presente | El Condenado | `el_condenado.blend` | `elenco.py` |
| Presente | La Sentencia | `la_sentencia.blend` | `elenco.py` |
| Presente | El Director | `el_director.blend` | `elenco.py` |
| Pasado | Policía patrullero | `policia_patrullero.blend` | `elenco.py` |
| Pasado | Policía táctico | `policia_tactico.blend` | `elenco.py` |
| Pasado | Guardia penitenciario | `guardia_penitenciario.blend` | `elenco.py` |
| Pasado | Interrogador | `interrogador.blend` | `elenco.py` |
| Pasado | Verdugo | `verdugo.blend` | `elenco.py` |
| Pasado | Alcaide | `alcaide.blend` | `elenco.py` |
| Pasado | Presos genéricos (3 complexiones: media, robusta y calva, delgada y pelirroja) | `preso_generico_a.blend`, `_b`, `_c` | `elenco.py` |

Todos tienen esqueleto (para animar o posar) y atlas de textura de 512 px. Alineaciones de revisión: `renders/alineacion_pasado.png`, `renders/alineacion_presente.png` y `renders/alineacion_figurantes.png`. Láminas individuales: `previsualizar.py`.

### Animaciones (v1, script `animaciones.py`)

Las animaciones básicas de la v1, sacadas de la jugabilidad de la planeación (lista AN3 del protagonista, muertes K3, armas §7.1, enemigos §7). Son **acciones** de Blender guardadas en el `.blend` de cada personaje. Cada una va en una pista NLA silenciada: no cambian la pose del archivo, así que los planos y los figurantes no se mueven. Al exportar a glTF o importar el `.blend` en Godot salen como animaciones separadas.

- **30 fps**, empiezan en el fotograma 0. Los ciclos terminan en `_loop` y Godot los importa en bucle.
- **En el sitio**: el personaje no avanza; Godot mueve el cuerpo.
  - Los ciclos de andar y correr están hechos para una velocidad concreta (la del perfil de movimiento de Godot), así los pies no patinan. Si el personaje va a otra velocidad, se escala la velocidad de reproducción.
  - Excepción: `pasar_por_encima`, en la que la cadera avanza 1,6 m.
- **Elías y los humanos** se mueven con fluidez. **Las manifestaciones del presente** van «a pocos fotogramas» (decisión AN2): una pose cada 4 fotogramas, sin interpolar.
- **Parejas sincronizadas**, cara a cara a la distancia indicada en el manifiesto:
  - `el_uniforme/agarrar` con `elias_preso/muerte_cuello`.
  - `policia_patrullero/placaje` con `muerte_placaje`.
  - `aislado/atacar` con `muerte_arrastrado`.
  - `la_sentencia/golpe_vertical` con `muerte_golpe`.

| Personaje | Animaciones |
|---|---|
| Elías preso (28) | `quieto_loop`, `andar_loop` (1,55 m/s), `correr_loop` (3,5), `agachado_loop`, `agachado_andar_loop` (0,95), `mirar_atras`, `levantarse` (del suelo, inicio del juego), `empujar`, `ganzua_loop`, `leer_loop`, `recoger`, `lanzar`, `esconderse`, `taquilla_loop`, `congelarse_loop` (Recuento), `marcar_pared` (guardar), `palanca`, `volante_loop`, `punzon_clavar`, `pistola_apuntar_loop`, `pistola_disparar`, `escopeta_apuntar_loop`, `escopeta_disparar`, `cegado`, `muerte_cuello`, `muerte_placaje`, `muerte_arrastrado`, `muerte_golpe` |
| Elías civil (14) | `quieto_loop`, `andar_loop` (2,3), `correr_loop` (5,4), `correr_mirando_atras_loop`, `mirar_atras`, `derribar`, `pasar_por_encima`, `ganzua_loop`, `empujar`, `leer_loop`, `recoger`, `sentado_loop` (interrogatorio), `esconder_objeto` (la carpeta de F1), `muerte_placaje` |
| El Uniforme (6) | `quieto_loop`, `andar_loop` (1,0), `recuento_loop`, `perseguir_loop` (2,4), `agarrar`, `aturdido` |
| Los Aislados (6 cada uno) | `quieto_loop`, `andar_loop` (0,7, cojeando), `correr_loop` (2,6), `atacar`, `escuchar`, `morir` |
| El Vigilante (4) | `quieto_loop` (barre con el foco), `andar_loop` (0,9), `alerta`, `aturdido` |
| El Condenado (3) | `quieto_loop`, `acechar_loop` (1,1), `atacar` |
| La Sentencia (6) | `quieto_loop`, `andar_loop` (0,8, arrastrando la hoja), `golpe_vertical`, `golpe_barrido`, `tambalearse`, `furia` |
| El Director (2) | `quieto_loop`, `mirar_abajo` |
| Policía patrullero (5) | `quieto_loop`, `andar_loop` (1,5), `correr_loop` (4,8), `silbato`, `placaje` |
| Policía táctico (2) | `quieto_loop` y `andar_loop` (1,2), con el escudo delante |
| Guardia (3) | `quieto_loop`, `andar_loop` (1,4), `correr_loop` (4,2) |
| Interrogador (3) | `quieto_loop` (apoyado en la mesa), `andar_loop` (1,0), `golpe_mesa` |
| Verdugo, alcaide y presos | `quieto_loop` y `andar_loop`; el alcaide, `quieto_loop` y `hablar` |

Revisión: `renders/animaciones/<personaje>.mp4`, un vídeo por personaje con el nombre de cada animación sobreimpreso.

**Para llevarlas a Godot** (más adelante):
- Godot 4 importa el `.blend` directamente, o se exporta a `.glb` desde Blender con «Animation mode: Actions». Probado con Elías preso y El Uniforme: salen todas las animaciones con su duración.
- Los ciclos `_loop` se importan en bucle.
- En el `AnimationPlayer`, la velocidad de reproducción de andar y correr se escala con la velocidad real del cuerpo dividida entre la `velocidad` del manifiesto.
- Las armas (pistola, escopeta, punzón) se colocan como hijos de un `BoneAttachment3D` en el hueso `mano.R`: las poses ya las sujetan.
- En las parejas de muerte, los dos personajes se colocan cara a cara a la `distancia` del manifiesto antes de reproducirlas a la vez.

### Kits, escenarios y planos

| Asset | Archivo | Contenido | Script |
|---|---|---|---|
| Kit de la prisión | `kit/kit_prision.blend` | 4 variantes de módulo de celdas, puente, estandarte, sábana, tragaluz, fluorescente, torre | `kit_prision.py` |
| Kit del Bloque A | `kit/kit_bloque_a.blend` | Tramo de pasillo con celdas (2 variantes) y celda de Elías | `bloque_a.py` |
| Kit de la ciudad | `kit/kit_ciudad.blend` | Fachadas de ladrillo, farola de sodio, contenedor, cubo, caja, verja, coche patrulla, cartel «SE BUSCA», prisión en la colina, lluvia | `callejon.py` |
| Kit de interiores | `kit/kit_interiores.blend` | Cama de hospital, cuerpo tapado, mesa de operaciones, lámpara de quirófano, carrito, vitrina, gotero, espejo, mesa y silla metálicas, lámpara colgante, archivador, 3 mecanismos del jefe (palanca, volante, torno), lámpara roja, cadena, plataforma de ejecución con hoja, pilares, muro de pantallas, escritorio del Director, charco de sangre, 5 rótulos | `interiores.py` |
| Patio Central | `escenarios/patio_central.blend` | 18 plantas, 77 m de largo, puentes, torre, niebla | `patio_central.py` |
| Bloque A | `escenarios/bloque_a.blend` | Celda de Elías + 36 m de pasillo de celdas | `bloque_a.py` |
| Callejón (pasado) | `escenarios/callejon.blend` | Callejón lluvioso con patrulla y prisión al fondo | `callejon.py` |
| Enfermería (capítulo III) | `escenarios/enfermeria.blend` | 14 x 9 m: camas con cortinas, quirófano, vitrinas, espejos, sangre, fluorescentes (uno apagado) | `interiores.py` |
| Comisaría (F2) | `escenarios/comisaria.blend` | Sala de interrogatorio con espejo unidireccional, mesa, sillas y bombilla colgante | `interiores.py` |
| Sala de ejecución (capítulo IV) | `escenarios/ejecucion.blend` | 22 x 16 x 9 m: plataforma con hoja, pilares (algunos rotos para cubrirse), 3 mecanismos con lámpara roja, cadenas | `interiores.py` |
| Núcleo de control (final) | `escenarios/nucleo.blend` | Nave de 50 x 22 m: alfombra, pilares con luces rojas, estandartes, tarima, escritorio, muros de pantallas y escudo de la institución | `interiores.py` |
| Prisión en el pasado (F3) | `escenarios/prision_pasado.blend` | El Patio Central enlazado, con luz de tarde cálida y polvo | `prision_pasado.py` |
| Plano «Mirada» | `escenas/plano_patio_central.blend` | Contrapicado del Patio Central | `plano_patio.py` |
| Plano «Pasarela» | `escenas/plano_patio_pasarela.blend` | Generable con `--pasarela` | `plano_patio.py` |
| Plano del pasillo | `escenas/plano_pasillo.blend` | El Uniforme avanza; Elías mira atrás | `bloque_a.py` |
| Plano del callejón | `escenas/plano_callejon.blend` | Huida bajo la lluvia | `callejon.py` |
| Plano de la enfermería | `escenas/plano_enfermeria.blend` | Elías junto al quirófano; El Condenado avanza entre las camas | `interiores.py` |
| Plano del interrogatorio | `escenas/plano_comisaria.blend` | Picado de cámara de vigilancia: el interrogador se inclina sobre Elías | `interiores.py` |
| Plano de la ejecución | `escenas/plano_ejecucion.blend` | Elías agazapado tras un pilar roto; La Sentencia ante la plataforma | `interiores.py` |
| Plano del núcleo | `escenas/plano_nucleo.blend` | Elías frente a El Director, al fondo de la nave | `interiores.py` |
| Plano de la huida (pasado) | `escenas/plano_prision_pasado.blend` | Elías huye por la pasarela; los guardias lo persiguen; presos y guardias en el patio | `prision_pasado.py` |

### Pendiente

- Escenarios: están todos los que pide la historia. Faltan los espacios de paso (pasillos de servicio, escaleras, celdas de aislamiento) cuando se diseñe cada nivel jugable.
- Personajes: la hermana de Elías (falta su nombre y su guion), colgados y cadáveres (variantes de pose de Los Aislados y del guardia).
- Calidad (pulido del 13-11-2026):
  - **Hecho:**
    - **Cabeza PS1 nueva para todo el elenco** (dirección del creador: estilo Silent Hill 1). Está modelada vértice a vértice en `humano.py` (tabla `CABEZA_PS1`): 12 lados, caras planas, mandíbula marcada en diagonal, nariz en cuña y arco de las cejas saliente que deja los ojos en sombra.
    - Textura de la cara a media resolución (pixelada) con ojos pequeños que apenas se ven.
    - Pelo en casco facetado y voluminoso (tabla `PELO_PS1`) con pocos mechones gruesos.
    - Orejas hexagonales.
    - Calvos con pelo rapado en herradura.
    - Todas las manos tienen palma, cuatro dedos y pulgar, en lugar de manoplas.
    - La hoja de La Sentencia es una puerta de celda de 1,6 x 0,7 m que arrastra por detrás, por el suelo.
    - En el núcleo, el foco del escudo ya no aparece en la niebla delante de El Director.
  - **Importante:** los renders de los planos (`renders/plano_*.png`) muestran la versión anterior de las cabezas. Los `.blend` de los planos enlazan a los personajes, así que ya muestran la versión nueva y se actualizarán al volver a renderizarlos.
  - **Queda:** los dedos no tienen huesos propios (se mueven con la mano entera), y la lámina de cabeza no encuadra bien a los personajes encorvados (Los Aislados).
  - **Interruptores de estilo** al principio de `humano.py`: `DETALLE_LADOS`, `DETALLE_ANILLOS`, `SOMBREADO_SUAVE`, `INTERPOLACION` y `REGIONES_DETALLE`. Hoy están en PS1 estricto, que es lo que pide el creador.
- Animaciones: están las básicas de la v1 (ver arriba). Faltan:
  - Las transiciones finas (arrancar, frenar, girar en el sitio); Godot las mezcla con fundidos.
  - Las animaciones de la hermana.
  - Los gestos de la cara (no hay huesos faciales).
  - Probar las parejas de agarre ya colocadas en Godot.

## Sonido procedural y versión del Bloque A para el juego (14-11-2026)

- `scripts/generar_audio.py` genera los 125 sonidos del juego (efectos y ambientes en bucle) con síntesis original (numpy + scipy) y los convierte a OGG con FFmpeg en `juego/assets/audio/`:

  ```bash
  python assets/scripts/generar_audio.py
  ```

  Para generar solo algunos, añadir sus nombres: `... generar_audio.py lluvia silbato`.
- `escenarios/bloque_a_juego.blend` es la versión del Bloque A **para el juego**. Usa las mismas piezas, pero la puerta de la celda es un objeto aparte y cerrado, el primer tramo no se solapa con la celda y el extremo del pasillo está cerrado. El escenario del plano aprobado (`bloque_a.blend`) no cambia. Se genera y se exporta así:

  ```bash
  blender --background --factory-startup --python assets/scripts/bloque_a.py -- --solo-juego
  ```

  ```bash
  blender --background --factory-startup --python assets/scripts/exportar_godot.py -- bloque_a_juego
  ```

## Regenerar (desde la carpeta del proyecto)

Blender está en `C:\Program Files\Blender Foundation\Blender 5.2\blender.exe`.

```bash
fuentes_arte\.venv\Scripts\python.exe assets\scripts\extraer_muestras.py
```

```bash
blender --background --factory-startup --python assets/scripts/personajes.py -- todos
```

```bash
blender --background --factory-startup --python assets/scripts/kit_prision.py
```

```bash
blender --background --factory-startup --python assets/scripts/patio_central.py
```

```bash
blender --background --factory-startup --python assets/scripts/plano_patio.py
```

```bash
blender --background --factory-startup --python assets/scripts/elenco.py -- todos
```

```bash
blender --background --factory-startup --python assets/scripts/bloque_a.py
```

```bash
blender --background --factory-startup --python assets/scripts/callejon.py
```

```bash
blender --background --factory-startup --python assets/scripts/interiores.py -- kit enfermeria comisaria ejecucion nucleo
```

```bash
blender --background --factory-startup --python assets/scripts/prision_pasado.py
```

```bash
blender --background --factory-startup --python assets/scripts/alineacion.py -- pasado presente figurantes
```

Con `--borrador` al final, los planos se renderizan a 640 x 360 (unos 2 minutos cada uno en este equipo).

Animaciones de todos los personajes (o solo de los que se nombren detrás de `--`), unos 20 segundos. **Hay que ejecutarlo siempre después de `personajes.py` o `elenco.py`**, porque regenerar un personaje borra sus animaciones:

```bash
blender --background --factory-startup --python assets/scripts/animaciones.py
```

Vídeo de revisión de las animaciones de un personaje (o, con `--hoja`, una hoja de poses en PNG; con `--solo nombre ...`, solo esas animaciones):

```bash
blender --background --factory-startup --python assets/scripts/revisar_animaciones.py -- elias_preso
```

Lámina de revisión de un personaje:

```bash
blender --background --factory-startup --python assets/scripts/previsualizar.py -- elias_preso
```

Primer plano de un detalle (cámara en x y z, mirando a tx ty tz, con lente opcional), con la misma luz de estudio:

```bash
blender --background --factory-startup --python assets/scripts/primer_plano.py -- elias_preso mano.png 0.75 -0.8 1.05 0.26 0.0 0.84 60
```

Lámina de la cabeza (frente, tres cuartos, perfil y espalda) en `renders/personajes/<nombre>_cabeza.png`:

```bash
blender --background --factory-startup --python assets/scripts/lamina_cabeza.py -- elias_preso elias_civil
```

**Atención:** regenerar con los scripts **sobrescribe** los `.blend`. Los retoques hechos a mano en un archivo se pierden si se vuelve a ejecutar su script. Conviene decidir para cada asset si se sigue generando por script o si pasa a editarse a mano.

## Origen del contenido

Todo es creación del proyecto con IA (Claude, mediante scripts de Blender y Python). Las muestras de `texturas/referencia/` proceden del arte conceptual generado con ChatGPT que está en `Materiales/`; su uso como material está autorizado por el creador (decisión L3). El registro está en `Materiales/recursos_y_creditos.md`.
