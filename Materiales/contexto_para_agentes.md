# LIFETIME SENTENCE — CONTEXTO PARA AGENTES DE IA

> **Para qué sirve este archivo.** Es un resumen **autocontenido** del proyecto para pegárselo a cualquier agente o asistente de IA (ChatGPT, Claude, etc.) y que entienda el estado del proyecto sin leer todo lo demás. Puedes pedirle, por ejemplo: «Resume este proyecto», «¿Qué tareas quedan para personas?» o «Explícame cómo está organizado el juego».
>
> **Última actualización:** 2026-11-12 · corresponde a `planeacion.md` **v1.2** (plan en 7 etapas; etapa 1 en curso, bloque 1.1 verificado).
> Si hay contradicción entre este archivo y `planeacion.md`, **manda `planeacion.md`**.

---

## 1. Ficha rápida

| Campo | Valor |
|---|---|
| Título | **LIFETIME SENTENCE** (definitivo, en inglés; el juego está en español) |
| Evento | **GUILD Game Jam 2026**. Temática: **«Al otro lado de la ley»**; enfoque: punto de vista del ladrón |
| Equipo | **Oziel Rodman Ramos Torrez** y **Christopher Barea Salazar** (2 personas) |
| Desarrollo asistido por IA | **Claude (Anthropic)**, vía Claude Code: planificación, código, modelos, texturas, animación, sonido y documentación. Arte conceptual de referencia: **ChatGPT (OpenAI)**. Todo uso de IA se declara (el reglamento lo exige) |
| Género | Terror psicológico, supervivencia, sigilo, persecuciones, exploración narrativa |
| Vista | Tercera persona dinámica |
| Estilo | 3D **low-poly retro PS1** con iluminación y composición cinematográficas |
| Motor | **Godot 4.7.2**, lenguaje **GDScript** |
| Plataforma | **Windows PC**, un único `.exe` |
| Controles | Teclado + ratón y mando |
| Idioma | Español |
| Fechas clave | **Cierre de entrega: 14 de noviembre de 2026.** Exhibición y premiación presencial: 21 de noviembre de 2026. El equipo gestiona el plazo; el plan de desarrollo no se recorta |

## 2. Estado actual (2026-11-14)

- **Fase:** producción, etapa 7 (revisión y entrega). **La demo completa está construida en Godot** y se juega de principio a fin: menú → capítulos I–IV con los recuerdos F1–F3 → final con El Director → «FIN DE LA DEMO» → créditos → menú. Las etapas 1–6 están hechas y **pendientes de la aprobación del creador** (tarea D-10).
- **Verificación:**
  - `--prueba-demo` recorre la demo entera con 0 errores: objetos, puzles, transiciones D5/D6, una muerte con «CONTINUAR», créditos y vuelta al menú.
  - `comprobar_scripts.gd` compila los ~75 scripts sin errores.
  - Rendimiento en el portátil del creador: 60 fps en calidad Baja en todos los niveles.
  - El `.exe` exportado (`entregas/LifetimeSentence.exe`, 130 MB) arranca sin Godot.
- **Arquitectura (resumen):**
  - Autoloads `Settings`, `Audio`, `RenderRig`, `Juego` (director), `Guardado`, `Interfaz` y `DebugTools`.
  - Niveles en `juego/niveles/<id>/`: escena generada por `juego/herramientas/niveles/construir_<id>.gd` sobre los `.glb` de Blender, más un script que hereda de `Nivel` con la lógica y las cinemáticas.
  - Componentes en `juego/componentes/` (interactuables con cerradura, puertas, escondites, mecanismos, espejos con reflejo real, lluvia, piezas de kit).
  - Enemigos en `juego/enemigos/`, con la base `Enemigo`: vista, oído, patrulla, NavigationAgent3D y ataques emparejados.
  - Textos en `juego/datos/`.
  - Sonido: 125 sonidos procedurales hechos con `assets/scripts/generar_audio.py`.
- **Desviaciones del plan** (para aprobar): `docs/FUNCIONES_Y_LIMITACIONES.md` §4. Las principales:
  - Al morir se vuelve al inicio del tramo o a la última pared.
  - Las puertas llevan a otras zonas con fundido a negro.
  - El Vigilante vigila desde el anillo de la torre.
  - Solo hay taquillas como escondite.
- **Falta:**
  - Pruebas con personas, incluido un mando físico (T-1 a T-4).
  - Voces grabadas (V-01 a V-11); hoy son subtítulos.
  - Nombre de la hermana (D-9).
  - Subir a GitHub con `docs/SUBIR_A_GITHUB.md`; Claude no hace commits.
- **Forma de trabajo:** cada etapa se explica, se implementa, se verifica, se documenta y el creador la aprueba.

## 3. Historia

### 3.1. Premisa

**Elías Novak**, un **ladrón** joven (moralmente ambiguo, no inocente), despierta en su celda de la **Penitenciaría Estatal N.º 314** durante un apagón. Es el **preso N.º 4827**. La prisión está en silencio y llena de cadáveres tras una masacre que no recuerda. Intenta escapar mientras objetos del presente le provocan **recuerdos jugables** de cómo llegó allí.

### 3.2. Dos épocas con reglas distintas

- **PASADO**: ciudad hispanohablante ficticia, finales de los 80 o los 90; noche lluviosa, comisaría, la prisión cuando funcionaba. Personas reales: policías, guardias, interrogador, verdugo, alcaide corrupto. **Se sobrevive huyendo.** Siempre hay un **motivo** para escapar; si lo arrestan, ese motivo se pierde (escena de consecuencia y reintento).
- **PRESENTE**: la prisión abandonada, fría, distorsionada por la culpa. Las figuras del pasado reaparecen como **manifestaciones simbólicas** con reglas propias. **Se sobrevive quedándose quieto, ocultándose y entendiendo sus reglas.**
- **Idea central:** *en el pasado corres de la ley; en el presente, la ley te obliga a quedarte quieto.*

### 3.3. Motivo y dilema

- Robó por dinero para **proteger a su hermana menor** (nombre por definir). Entre el botín había **papeles que comprometen a las autoridades**, y por eso lo persiguieron.
- Dilema final del juego (dirección del creador): **salvar a esa persona o salvar al mundo exponiendo las pruebas**. El creador cree que salvar a alguien dolería más.

### 3.4. Verdades ocultas (propuestas del documento base)

1. El robo fue real.
2. Los papeles comprometen a autoridades y al sistema judicial y penitenciario.
3. La prisión se usaba para silenciar y ejecutar a testigos incómodos.
4. Un acto del protagonista desencadenó sin querer un protocolo de ejecución masiva.
5. Por eso tiene parte de culpa en la masacre.
6. Un guardia que parecía hostil intentaba en realidad impedir la masacre.
7. Al final, elegir.

**Decisión del creador:** la demo completa **revela todo (1–6)** y **termina justo antes del dilema final**, sin elección. Esto sustituye a la regla original de no spoilers. El reparto de revelaciones por capítulo está en `planeacion.md` §4.5.

## 4. Dirección artística

- **Sí:** PS1 low-poly cuidado, texturas pixeladas de baja resolución, dithering, grano, niebla, luz fría, concreto húmedo, óxido, barrotes, brutalismo, decadencia, surrealismo arquitectónico, claustrofobia, soledad, frío.
- **No:** futurismo, ciencia ficción, cyberpunk, neones, realismo AAA, exteriores abiertos, iconografía religiosa, copiar criaturas de otros juegos.
- **Personajes (corrección del creador del 13-11-2026):** como en la PS1 de Silent Hill 1, muy low-poly.
  - Polígonos visibles y sombreado plano.
  - Texturas medio pixeladas.
  - Cara angulosa con la mandíbula marcada, nunca redonda.
  - Ojos pequeños en la sombra de las cejas, que casi no se ven.
  - Pelo en bloques facetados.
  - **No suavizar ni «embellecer»** los modelos: un intento con más polígonos y sombreado suave fue rechazado.
  - La cabeza estándar está en `assets/scripts/humano.py` (`CABEZA_PS1`).
- **Espacio:** casi todo es estrecho (celdas, pasillos). **Una sola** zona monumental interior y cerrada, el **Patio Central**: pabellón panóptico de unos 20 niveles, torre central, pasarelas sobre el vacío y tragaluz. Provoca megalofobia.
- **Paleta:**
  - Presente: gris azulado, azul oscuro, verde enfermizo, negro.
  - Pasado: ámbar de sodio, sepia.
  - Rojo solo como acento de peligro.
- **Referencias:** 8 imágenes en `Materiales/` generadas con ChatGPT. El creador pidió **copiar fielmente su estilo** y permite usarlas como material, acreditadas.
- **Render:** imagen interna de 480 × 270 ampliada sin suavizar, texturas de 64–128 px sin filtrar, vibración de vértices sutil, dithering, LUT por época. Preajustes gráficos «Bajo» y «Alto».

## 5. Personajes y enemigos

| Época | Nombre | Rol | Diseño / mecánica |
|---|---|---|---|
| — | **Elías Novak** (protagonista) | Jugador | Joven, pelo oscuro. Presente: uniforme naranja sucio N.º 4827. Pasado: chaqueta granate, camiseta blanca. Sin voz (solo respiración) |
| Pasado | Policía patrullero | Común | Azul marino, gorra, linterna, silbato que llama refuerzos; persigue a pie |
| Pasado | Policía táctico | Fuerte | Antidisturbios con escudo; cierra calles |
| Pasado | Guardia penitenciario | Fuerte | Camisa caqui, llaves, porra (pistola en algunas zonas) |
| Pasado | Interrogador | Especial | Camisa blanca, corbata roja, tirantes; presión psicológica |
| Pasado | Verdugo penitenciario | Mini-jefe | Delantal de cuero, hacha de ejecución (aparición) |
| Pasado | Alcaide corrupto | Jefe | Traje de tres piezas (aparición) |
| Presente | **Los Aislados** | Comunes | Presos demacrados y sin rostro; reaccionan al ruido y atacan en grupo |
| Presente | **El Uniforme** | Acechador | Policía altísimo con el rostro vacío y un aro de llaves. Mecánica **«Recuento»**: cuando sus llaves dejan de sonar, cuenta; si te mueves en su mirada, te atrapa. No se puede destruir |
| Presente | **El Vigilante** | Vigilancia | Delgadísimo, con una lámpara de torre por cabeza; sus focos barren y activan la alarma |
| Presente | **El Condenado** | Especial | Doble ensangrentado del protagonista; aparece en espejos; puzle de espejos |
| Presente | **La Sentencia** | Jefe | Capucha alta, abrigo largo con cinturón, hoja hecha con una puerta de celda. Jefe-puzle de 3 mecanismos; el ruido la atrae |
| Presente | **El Director** | Jefe final | Colosal, con abrigo y gorra; solo aparición en la demo |

**Regla de diseño:** cada figura humana del pasado tiene un correlato monstruoso en el presente **con una mecánica distinta** (policía → El Uniforme; verdugo → La Sentencia; alcaide → El Director).

## 6. Jugabilidad

- **Acciones:** caminar, correr, agacharse (**sin salto**). En el pasado, «pasar por encima» de obstáculos marcados. Interactuar, forzar cerraduras con **ganzúa** (la habilidad del ladrón), esconderse (celdas en sombra, catres, taquillas), lanzar objetos para distraer, leer documentos, recoger objetos clave.
- **Defensa:**
  - Pasado: sin armas; se derriban obstáculos y se cierran verjas.
  - Presente: armas escasas y ruidosas (punzón, pistola, escopeta) que **no matan a las manifestaciones principales**, solo compran segundos. Útiles de verdad contra los jefes. *(Aprobado.)*
- **Muerte:** animación medio violenta propia de cada enemigo → corte a negro → «CONTINUAR».
- **Guardado:** **manual**, en paredes con marcas de conteo de días (raya una marca más). Al morir se carga la última partida. Los flashbacks tienen su propio punto de control. *(Aprobado.)*
- **Dificultad:** media. **HUD** mínimo: punto de interacción y munición solo al apuntar. Sin barra de vida.
- **Menú principal cinematográfico:** la cámara recorre la prisión y los enemigos, con distorsiones pasado ↔ presente.
- **Advertencias** de fotosensibilidad y contenido al inicio.
- **Créditos finales:** «FIN DE LA DEMO» y después solo los dos nombres del equipo sobre secuencias del juego. Pantalla aparte de «Créditos y licencias» con atribuciones y declaración de IA.

## 7. Estructura de la demo y etapas de producción

### 7.1. Capítulos de la demo

| Bloque | Contenido |
|---|---|
| Cap. I **«Resiliencia»** | Despertar en la celda, ganzúa, Bloque A (celdas A1–A16) con cadáveres en aumento, cartel «SE BUSCA» con su cara → **F1 «La huida»** (calles lluviosas, esconder las pruebas antes de ser atrapado) → regreso → **El Uniforme** → puerta monumental → revelación del Patio Central |
| Cap. II «Patio Central» | Pabellón monumental, colgados, El Vigilante, Los Aislados, pistola → **F2 «El interrogatorio»** (comisaría) |
| Cap. III «Enfermería» | Escenario gore, El Condenado, expedientes → **F3 «El ingreso»** (la prisión en el pasado) |
| Cap. IV «La Sentencia» | Jefe-puzle, escopeta |
| Final | El Director → FIN DE LA DEMO → créditos |

**Plan confirmado:** los 4 capítulos (~45–60 min), desarrollados capítulo a capítulo. El equipo gestiona el plazo de la jam; si hace falta entregar, se exporta una build con lo que exista.

### 7.2. Las 7 etapas de producción

Cada etapa termina en un hito (H1 a H7), con una build de Windows que el creador prueba y aprueba. El detalle y los criterios de cierre están en `planeacion.md` §11.

| Etapa | Nombre | Qué se hace | Estado |
|---|---|---|---|
| 1 | Preparación del juego | Base en Godot con estética PS1, movimiento y cámara (bloque 1.1); kit de prisión y Bloque A (1.2); protagonista y animaciones (1.3); mecánicas del capítulo I (1.4); flashback «La huida» (1.5); El Uniforme (1.6). Todo listo y verificado por separado | **En curso** (bloque 1.1 hecho y verificado; falta el visto bueno del creador. Arte de los bloques 1.2, 1.3, 1.5 y 1.6 hecho en Blender, sin integrar) |
| 2 | Capítulo I — Resiliencia | Montar lo preparado en un capítulo jugable de principio a fin: recorrido, transiciones, sonido y pulido | Pendiente |
| 3 | Capítulo II — Patio Central | El capítulo y su flashback F2 | Pendiente |
| 4 | Capítulo III — Enfermería | El capítulo y su flashback F3 | Pendiente |
| 5 | Capítulo IV — La Sentencia | El capítulo, el jefe y la salida hacia el final | Pendiente |
| 6 | Final de la demo | Secuencia con El Director y créditos; termina justo antes del dilema | Pendiente |
| 7 | Revisión y entrega | Probar el recorrido completo, corregir, optimizar, exportación final para Windows y documentación de entrega | Pendiente |

El plan anterior (v1.0) tenía 11 etapas. Sus etapas 1 a 6 son hoy los bloques 1.1 a 1.6; la 7 es la etapa 2; la 8, la 3; la 9, la 4; la 10 se reparte entre las etapas 5 y 6; y la 11 es la etapa 7.

## 8. Técnica

- **Godot 4.7.2 + GDScript.** Arquitectura con autoloads (GameDirector, EraManager, AudioDirector, SaveSystem, Settings), **componentes reutilizables editables desde el Inspector**, datos en recursos `.tres` y niveles montados con un **kit modular**.
- **Blender 5.2** para modelado, rigging, animación y horneado. Los `.blend` se conservan para que el equipo los edite.
- **Assets de Blender ya hechos (carpeta `assets/`, guía en `assets/LEEME.md`).** Todo lo generan scripts de Python en `assets/scripts/` (reproducibles):
  - 18 personajes con esqueleto: Elías preso y civil, todo el elenco de enemigos y jefes, los humanos del pasado y 3 presos genéricos.
  - 4 kits modulares: prisión, Bloque A, ciudad e interiores.
  - 8 escenarios: Patio Central, Bloque A, callejón, enfermería, comisaría, sala de ejecución, núcleo de control y prisión en el pasado.
  - 8 planos cinematográficos renderizados en `assets/renders/`.
  - Los escenarios **enlazan** las piezas de los kits, y los planos enlazan los escenarios y los personajes (con override para posarlos). Regenerar con un script **sobrescribe** su `.blend`.
  - **Animaciones básicas v1** hechas con `assets/scripts/animaciones.py`.
    - Son acciones a 30 fps dentro de cada `.blend`, en el sitio, con los ciclos `_loop` a la velocidad del perfil de movimiento de Godot.
    - Las manifestaciones van «a pocos fotogramas».
    - Lista y parejas sincronizadas en `assets/animaciones/manifiesto.json`.
    - **Ejecutar `animaciones.py` después de regenerar personajes**: regenerar un personaje borra sus animaciones.
  - Faltan la integración en Godot y la revisión del creador.
- **Python/Pillow** para texturas procedurales y sonido. **FFmpeg** para audio y vídeo.
- **Equipo de pruebas del creador:** portátil con Intel HD 520, 8 GB RAM y pantalla de 1366 × 768. Debe poder probarse ahí; lo artístico tiene prioridad.
- **Renderizador:** Forward+, elegido con mediciones (es el único con niebla volumétrica). Dos calidades gráficas: BAJO y ALTO.
- **Repositorio:** sin commits durante el desarrollo. En la etapa 7 se entrega la secuencia de comandos `git` + **Git LFS** para subirlo a GitHub; **la ejecuta el equipo**. Ya existen `.gitignore` y `.gitattributes`.
- **Carpetas (ya creadas):** `Materiales/` (documentación), `docs/` (guías `COMO_EJECUTAR.md` y `GUIA_EQUIPO.md`), `assets/` (personajes, kits, escenarios y planos de Blender), `fuentes_arte/` (scripts de texturas de Godot), `juego/` (proyecto Godot), `entregas/`, `respaldos/`.

## 9. Reglas obligatorias

1. **Sin compras ni servicios, API o modelos de IA de pago o con créditos.**
2. Recursos externos: preferir creación propia y **CC0**. **CC BY** permitido citando siempre al autor. **Nunca NC** ni de pago. Nada sin licencia verificable ni extraído de juegos comerciales.
3. **Todo lo hecho con IA se declara.** En la jam, la «IA no declarada» y los «recursos sin licencia» son causa de descalificación.
4. Registrar cada recurso en `recursos_y_creditos.md` y cada herramienta instalada en `herramientas_instaladas.md`.
5. No modificar `contexto_absoluto_del_proyecto.md`; las decisiones se registran en `planeacion.md` como **CONFIRMADO / PROPUESTO / PENDIENTE**.
6. Todo debe poder entenderlo y modificarlo el equipo (escenas y objetos editables, no solo código).
7. Entregables exigidos por la jam: versión jugable o enlace, descripción breve, controles, lista de integrantes e instrucciones de ejecución, en la plataforma oficial. Pueden pedir un vídeo corto y un repositorio.

## 10. Mapa de documentos (`Materiales/`)

| Archivo | Contenido |
|---|---|
| `contexto_absoluto_del_proyecto.md` | Documento maestro original: historia completa, mundo, enemigos, arte y propuesta inicial. No se modifica |
| `planeacion.md` | **Documento oficial vivo**: decisiones, preguntas y respuestas, alcance, storyboard, mecánicas, arquitectura, fases, riesgos y pendientes |
| `pendientes_equipo.md` | Tareas que deben hacer personas: decisiones, grabación de voces (con guion y formato), pruebas, GitHub, entrega en la plataforma |
| `recursos_y_creditos.md` | Registro de assets, licencias, uso de IA y texto de créditos |
| `herramientas_instaladas.md` | Software detectado, instalado y descartado |
| `contexto_para_agentes.md` | Este resumen |
| 8 imágenes `.png` | Referencias visuales generadas con ChatGPT: moodboard, Patio Central, callejón del pasado, collage del presente, pasillo, prisión en el pasado, **lámina de enemigos del pasado**, **lámina de enemigos del presente** |

Fuera de `Materiales/` hay dos guías: `docs/COMO_EJECUTAR.md` (cómo abrir y probar el juego) y `docs/GUIA_EQUIPO.md` (cómo modificarlo desde el editor de Godot).

## 11. Preguntas abiertas

Ninguna bloqueante para el plan. Quedan detalles que se propondrán en su momento:

- **Etapa 1:** número de celda y paleta exacta (bloque 1.2), minijuego de ganzúa (1.4), nombre de la hermana y de la ciudad (1.5).
- **Etapa 2:** tipografías, y cómo se reparte el menú entre las etapas 2 y 6.
- **Antes de la etapa 3:** guiones de F2, F3 y el final.

Se hace una copia `.zip` de respaldo al cerrar cada etapa y cada bloque de la etapa 1. El vídeo corto queda para más adelante.

## 12. Glosario

- **Etapa, bloque e hito**: el plan tiene 7 etapas; la etapa 1 se divide en 6 bloques (1.1 a 1.6); cada etapa se cierra con un hito (H1 a H7).
- **Caja gris**: escena de prueba con geometría sencilla, sin arte definitivo, para probar el aspecto, el movimiento y la cámara.
- **Recuento**: mecánica de El Uniforme; cuando callan las llaves, no hay que moverse.
- **Resiliencia**: título del capítulo I.
- **F1 / F2 / F3**: flashbacks jugables 1, 2 y 3.
- **Patio Central**: el pabellón monumental (zona de megalofobia).
- **Marcas de conteo**: rayas de días en la pared; sirven como puntos de guardado.
- **Kit modular**: piezas 3D reutilizables (muros, celdas, pasarelas) para montar niveles en el editor.
- **PS1 / low-poly**: estética de la consola PlayStation original: geometría simple, texturas pixeladas, dithering y niebla.
