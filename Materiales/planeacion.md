# LIFETIME SENTENCE — PLANEACIÓN OFICIAL

**Demo jugable completa para Windows (Godot 4)**

| Campo | Valor |
|---|---|
| Versión | **1.6** |
| Fecha | 2026-11-14 |
| Fase actual | **Producción. Demo completa construida en Godot (etapas 1–6 hechas, pendientes de aprobación del creador). Etapa 7 — Revisión y entrega: EN CURSO.** Recorrido entero jugable (menú → capítulos I–IV con F1–F3 → final → créditos → menú), verificado con una prueba automática sin errores; `.exe` exportado en `entregas/`. Faltan las pruebas con personas (T-1 a T-4), las voces y la aprobación (§11). |
| Organización | **7 etapas** con un hito cada una (H1–H7): 1 Preparación del juego · 2 Capítulo I · 3 Capítulo II · 4 Capítulo III · 5 Capítulo IV · 6 Final de la demo · 7 Revisión y entrega (§11). |
| ⚠ Fechas clave | **Cierre de entrega de la GUILD Game Jam 2026: 14 de noviembre de 2026.** Exhibición y premiación presencial: 21 de noviembre de 2026. El creador gestiona el plazo y pide mantener el plan (J2). |
| Desarrollo autorizado | **SÍ, desde el 12-11-2026** («puedes empezar»). Cada etapa se cierra con la aprobación del creador antes de pasar a la siguiente. |
| Documento base | `contexto_absoluto_del_proyecto.md` (no se modifica; este archivo lo complementa) |
| Documentos relacionados | `pendientes_equipo.md` (tareas para personas) · `recursos_y_creditos.md` (assets, licencias, IA, créditos) · `herramientas_instaladas.md` (software usado o instalado) · `contexto_para_agentes.md` (resumen autocontenido para pasar a otro agente de IA) |

### Cómo leer este documento

- **[CONFIRMADO]**: decisión explícita del creador.
- **[PROPUESTO]**: propuesta del equipo; **no** se implementa sin aprobación.
- **[PENDIENTE]**: falta información o una decisión.
- **[DESCARTADO] / [POSPUESTO]**: rechazado, o fuera del alcance por ahora.
- **Prioridad ante conflictos:** decisiones registradas aquí (las más recientes primero) > `contexto_absoluto_del_proyecto.md` > imágenes.
- Las preguntas tienen identificador (p. ej. `G1`). Para responder basta con citarlo; «OK» acepta la propuesta.

### Registro de cambios

| Versión | Fecha | Cambio |
|---|---|---|
| **1.6** | 2026-11-14 | **Demo completa en Godot**, por encargo del creador («vamos a hacer el juego completo… que todo se vea cinematográfico»). Núcleo: director del juego (`Juego`: niveles, épocas y transiciones D5/D6, puntos de control, muerte → CONTINUAR, ruido y alarma, armas y objetos), guardado en 3 ranuras, audio por buses, interfaz completa (HUD mínimo S4, subtítulos, rótulos H5, documentos H3, pausa, opciones con reasignación de teclas, minijuegos de ganzúa K2/K6 y teclado). Jugador con el modelo y las animaciones de Elías (preso y civil), interacción, escondites, carrera que se agota, armas §7.1 y obstáculos del pasado K1. IA de El Uniforme (Recuento real), policía (goma elástica, silbato, refuerzos, linternas), guardias, Los Aislados (oído, convergencia), El Vigilante (foco con alarma), El Condenado (espejos con reflejo real) y La Sentencia (ruido, coberturas, escopeta). Ocho tramos montados sobre los escenarios de Blender con sus cinemáticas: Cap. I (alas A y B), F1 (callejón ampliado con cruce y verja), Cap. II (planta 10 y planta baja, fusibles y ascensor), F2 (sala 3 + oficinas y archivo), Cap. III (enfermería, espejos, archivo y caja de código), F3 (patio en el pasado), Cap. IV (jefe-puzle) y final con El Director. Menú cinematográfico C-21, advertencias C-22, créditos C-20 y pantalla de licencias Q3. 125 sonidos procedurales originales. Versión del Bloque A para el juego con la puerta de la celda separada (el escenario del plano aprobado no cambia). Prueba automática de la demo entera (0 errores) y `.exe` de 130 MB. Las desviaciones respecto a este plan están en `docs/FUNCIONES_Y_LIMITACIONES.md` §4 |
| 1.5 | 2026-11-13 | **Animaciones básicas v1 en Blender**, por encargo del creador («todas las animaciones necesarias básicas… para la v1»), sacadas de la jugabilidad de esta planeación:
- **Elías preso (28):** la lista AN3 completa más las armas (§7.1), guardar en la pared (§7.2), palanca y volante (capítulo IV) y cuatro muertes (K3).
- **Elías civil (14):** andar y correr al ritmo del pasado, mirar atrás corriendo, derribar, pasar por encima (K1), sentado en F2 y esconder la carpeta (F1).
- **Enemigos del presente, a pocos fotogramas (AN2):**
  - El Uniforme: patrulla, Recuento, persecución, agarre y aturdido.
  - Los Aislados, El Vigilante, El Condenado y El Director.
  - La Sentencia: arrastre, golpes, tambaleo y furia.
- **Humanos del pasado:** quieto, andar y correr; además, silbato, placaje y golpe en la mesa.
Son acciones a 30 fps guardadas en cada `.blend`, en el sitio y con los ciclos a la velocidad del perfil de movimiento de Godot (sin deslizamientos). Hay parejas sincronizadas para las muertes. Manifiesto en `assets/animaciones/manifiesto.json` y vídeos de revisión en `assets/renders/animaciones/`. Falta la revisión del creador y la integración en Godot. |
| 1.4 | 2026-11-13 | **Escenarios restantes en Blender**: kit de interiores (muebles, quirófano, mecanismos del jefe, pantallas, rótulos con fuente de píxeles propia) y cinco escenarios nuevos con su plano renderizado: **Enfermería** (capítulo III, con El Condenado), **comisaría y sala de interrogatorio** (F2), **sala de ejecución** (capítulo IV, La Sentencia y sus 3 mecanismos), **núcleo de control** (final, El Director) y **la prisión en el pasado** (F3: el Patio Central enlazado con luz cálida, presos y guardias). Tres **presos genéricos** para poblar el pasado (18 personajes en total). **Pulido de personajes:** manos con dedos y pulgar en todo el elenco y hoja de La Sentencia a escala de puerta de celda. **Dirección de arte confirmada por el creador [CONFIRMADO]:** estilo PS1 de Silent Hill 1, muy low-poly, con polígonos visibles, texturas medio pixeladas, mandíbula marcada y ojos que casi no se ven; nada de suavizar ni redondear la cara. Se descartó un intento de modelos más suaves y se construyó una **cabeza PS1 nueva**, modelada vértice a vértice, con pelo en casco facetado, para los 18 personajes. **El creador la aprobó** el 13-11-2026 al ver la cabeza de Elías: «Sí, así va bien». Los renders de los planos muestran todavía la cabeza anterior; los `.blend` ya enlazan la nueva. Adelanta el arte de etapas posteriores; falta la revisión del creador, las animaciones y la integración en Godot. |
| 1.3 | 2026-11-13 | **Producción de assets en Blender** por encargo del creador (Godot en pausa): carpeta `assets/` con 15 personajes con esqueleto (todo el elenco de las láminas), kits de prisión, Bloque A y ciudad, escenarios Patio Central, Bloque A y callejón, y tres planos cinematográficos renderizados. Avanza los bloques 1.2 (kit y Bloque A), 1.3 (protagonista), 1.5 (escenario de F1) y 1.6 (El Uniforme) en su parte de arte; falta integrarlos en Godot, las animaciones y la revisión del creador. Detalle en `assets/LEEME.md`. |
| 1.2 | 2026-11-12 | **Bloque 1.1 construido y verificado.** Primera ejecución real del proyecto: caja gris, capturas en las dos calidades, prueba automática de movimiento y cámara (16 comprobaciones correctas), medición de rendimiento en la Intel HD 520 y elección del renderizador **Forward+**, instalación de las plantillas de Windows y exportación de un `.exe` de prueba que arranca. Guías `docs/COMO_EJECUTAR.md` y `docs/GUIA_EQUIPO.md`. Estado actualizado en §10.3 y §11.1. Pendiente: visto bueno del creador. |
| 1.1 | 2026-11-12 | **Plan reorganizado en 7 etapas**, por encargo del creador: 1 Preparación del juego (agrupa las etapas 1–6 del plan v1.0), 2 Capítulo I, 3 Capítulo II, 4 Capítulo III, 5 Capítulo IV, 6 Final de la demo, 7 Revisión y entrega. Hitos H1–H7, criterios de cierre y referencias cruzadas ajustados (§11). Registrado el **inicio del desarrollo** y el **estado real de la etapa 1**: bloque 1.1 a medias, 33 archivos escritos y nada verificado todavía. Tabla de equivalencias con la numeración anterior (§11.8). |
| 1.0 | 2026-11-12 | **Ronda 3 respondida; plan cerrado.** Cierre de entrega el 14-11-2026; se mantiene el plan de 4 capítulos y el creador gestiona el plazo. Protagonista: **Elías Novak**; persona protegida: **su hermana menor**; la demo revela todo y **termina justo antes del dilema final**. Armas (§7.1) y guardado (§7.2) aprobados. Copias `.zip` de seguridad. Vídeo corto, más adelante. Nueva **guía narrativa** (§4.5). Propuesta de producción detallada de la antigua etapa 1, hoy bloque 1.1 de la etapa 1 (§11.1). |
| 0.3 | 2026-11-12 | **Respuestas de la ronda 2 registradas.** Lectura del **reglamento de la GUILD Game Jam 2026** (§1.4): exhibición el 21-11-2026, obligación de declarar la IA y los materiales previos, entregables exigidos. Propuestas de **armas** (§7.1) y **guardado manual** (§7.2). Nuevas contradicciones: revelarlo todo frente a la regla de no spoilers, armas frente a indefensión, guardado manual frente a autoguardado. Alcance para la entrega propuesto según el plazo (§5.0). Ronda 3. Creación de `contexto_para_agentes.md`. |
| 0.2 | 2026-11-12 | **Respuestas de la ronda 1 registradas.** Cambios de alcance: la micro-demo de 1 minuto pasa a ser una **demo completa sin límite de duración** y el **tráiler queda pospuesto**. Análisis de las nuevas láminas de enemigos (pasado y presente). Nuevo principio de **editabilidad para el equipo**. Estructura de la demo completa propuesta por capítulos. Ronda 2 de preguntas. Creación de `pendientes_equipo.md`, `recursos_y_creditos.md` y `herramientas_instaladas.md`. |
| 0.1 | 2026-11-12 | Creación. Análisis de `Materiales/`, interpretación, contradicciones, entorno técnico y ronda 1 de preguntas. |

---

## 1. Resumen del proyecto y objetivos

### 1.1. Qué es Lifetime Sentence

Terror psicológico en tercera persona, low-poly retro PS1 con composición cinematográfica, nacido de la Game Jam «Al otro lado de la ley» (punto de vista del ladrón). Un ladrón despierta en la **Penitenciaría Estatal N.º 314**, antigua, fría y casi vacía tras una masacre que no recuerda. Mientras intenta salir, objetos del presente le devuelven **recuerdos jugables**.

- **PASADO**: ciudad lluviosa, comisaría y la prisión cuando aún funcionaba. Personas reales. Se sobrevive **huyendo**, y siempre hay **un motivo concreto para escapar**. Si lo atrapan, ese motivo se pierde.
- **PRESENTE**: la prisión convertida en territorio de culpa. Las figuras del pasado vuelven como **manifestaciones** (El Uniforme, El Vigilante, Los Aislados, El Condenado, La Sentencia, El Director), cada una con reglas propias. Se sobrevive **quedándose quieto, ocultándose y entendiendo sus reglas**.

El golpe artístico es el contraste: **claustrofobia** en celdas y pasillos frente a **un pabellón interior monumental y cerrado** (Patio Central) que produce megalofobia.

### 1.2. Objetivos actuales

1. **Demo jugable completa** para Windows (Godot 4.7.2), con la duración que necesite: un tramo completo y cerrado del juego con capítulos, flashbacks, enemigos, puzles, muertes y final de demo. *(Estructura exacta: ver G1.)*
2. **Proyecto escalable y editable por el equipo**: escenas y objetos configurables desde el editor, fuentes de Blender incluidas y documentación de uso. No todo debe vivir en código.
3. **Documentación**: esta planeación, instrucciones de ejecución, modificación y exportación, créditos y licencias, registro de IA, pendientes del equipo y **comandos para subir el proyecto a GitHub** (con Git LFS para assets).
4. **Tráiler**: [POSPUESTO]. Se retomará cuando el creador lo indique; el plan v0.1 queda archivado en §9. La jam puede pedir un vídeo corto (J5).
5. **Entrega a la GUILD Game Jam 2026** antes del cierre de entrega, previo a la exhibición del 21-11-2026, con los archivos que exige el reglamento (§1.4). Alcance de la entrega: J2.

### 1.3. Lo que NO es

No es futurista, ni realismo genérico, ni una megaciudad. No copia criaturas de otros juegos. No es el juego completo: es una **demo completa** de su primera parte.

### 1.4. GUILD Game Jam 2026 — reglas relevantes

Fuente: reglamento oficial en Canva, enlace facilitado por el creador y leído el 2026-11-12.

| Tema | Regla | Impacto en el proyecto |
|---|---|---|
| Calendario | Modalidad híbrida. **Exhibición final y premiación presencial el 21 de noviembre de 2026.** | **Cierre de entrega: 14-11-2026** (confirmado por el creador, J1). El creador gestiona el plazo (J2) |
| Equipos | De 2 a 5 integrantes; un representante | Equipo de 2: válido |
| Inicio | El desarrollo debe empezar **durante el periodo oficial** y responder a la temática revelada en la inauguración. No se acepta un juego hecho previamente | Todo el desarrollo ocurre ahora. Hay que declarar lo creado antes (arte conceptual del 11-11-2026, documentos) |
| Herramientas y recursos | Se permiten motores, librerías, plantillas, código propio y recursos con licencia. **Hay que declarar los materiales creados antes de la Jam y los recursos de terceros** | `recursos_y_creditos.md` sirve de base para la declaración |
| Propiedad | El equipo conserva los derechos; la organización puede exhibir el juego, capturas y vídeos | — |
| Contenido no permitido | Discriminación, acoso, **violencia dirigida**, odio, explotación sexual, actividades ilegales, ataques contra personas o comunidades | El terror y el gore de ficción no son «violencia dirigida», pero conviene **advertencias claras** y evitar cualquier lectura de ataque a grupos reales (ver §12) |
| Entrega obligatoria | **Versión jugable o enlace de descarga + descripción breve + controles + lista de integrantes + instrucciones de ejecución**, en la plataforma que se anuncie al inicio | Entregables asignados a la etapa 7 (revisión y entrega, §11.7) y a `pendientes_equipo.md` |
| Demostración | La organización **puede pedir un vídeo corto** y un **repositorio accesible** | El tráiler pospuesto podría volver a ser necesario como vídeo corto; los comandos de GitHub cubren el repositorio |
| Cierre | Cuenta la última versión enviada antes del cierre; no se puede modificar después | Entregar con margen |
| Criterios | Relación con la temática · jugabilidad y experiencia · creatividad e innovación · calidad técnica y funcionamiento · arte, sonido y presentación | «Calidad técnica y funcionamiento» penaliza un juego grande pero roto |
| Premiación | El ganador debe estar presente; si es de otro departamento, al menos un integrante | Tarea del equipo |
| Descalificación | Plagio, información falsa, juego previo, entrega fuera de plazo, modificación posterior, contenido prohibido, **recursos sin licencia**, **IA no declarada** | Registro de licencias e IA **obligatorio**, no opcional |
| Copias de seguridad | Los equipos deben mantener copias de seguridad | Sin commits durante el desarrollo (Q1) → copia `.zip` al cerrar cada etapa y cada bloque de la etapa 1 (J4, §11.0) |

---

## 2. Decisiones confirmadas

### 2.1. Encargo de producción y ronda 1 (2026-11-12)

| ID | Decisión | Fuente |
|---|---|---|
| C-01 | Motor **Godot 4.7.2** (`Desktop\ARCADE\`) con **GDScript** | Encargo + TE1 |
| C-02 | Plataforma **Windows PC**; exportación a **un único `.exe`** al final | Encargo + TE4 |
| C-03 | Cámara **tercera persona dinámica**, **híbrida con zonas de cámara** (sobre el hombro en pasillos, abierta en exteriores, grúa en el pabellón) | Encargo + C1 |
| C-04 | **Demo completa sin límite de duración** («si dura 30 min, perfecto; si dura 2 horas, igual») | X1 |
| C-05 | **Tráiler pospuesto** | Sección TR |
| C-06 | Estética 3D low-poly retro PS1 + iluminación y composición cinematográficas. Intensidad PS1 según la propuesta A1 | Encargo + A1 |
| C-07 | **Replicar fielmente el estilo de las imágenes de referencia** («úsalas por completo, copia todo ese estilo») | A2 |
| C-08 | Las dos épocas difieren en mecánicas: **pasado = moverse para huir; presente = quedarse quieto u oculto** | Encargo + D1 |
| C-09 | Recursos: sin compras ni servicios de pago. CC0 preferente; **CC BY permitido citando siempre al autor**; **nunca NC ni de pago**. Todo se registra en `recursos_y_creditos.md` | Encargo + AN1 + AU3 |
| C-10 | **Declarar en los créditos todo lo hecho con IA.** La IA (Claude) participa en todo el desarrollo | AN1 + R2 |
| C-11 | Las herramientas instaladas se registran en `herramientas_instaladas.md`. Autorizado instalar las plantillas de exportación de Windows | TE3 |
| C-12 | Las tareas que requieren personas (voces, etc.) se documentan en `pendientes_equipo.md` para repartirlas en el equipo | AU2 |
| C-13 | **Escalabilidad y editabilidad**: el equipo debe entender y modificar todo. Objetos y escenas editables en el editor, no solo código | TE4 |
| C-14 | Al final: **comandos para subir a GitHub**, separados en `add` y `commit` coherentes, con soporte de assets grandes (Git LFS) | TE4 |
| C-15 | Rendimiento: no hace falta máxima fluidez; prima lo artístico, pero el creador debe poder probarla en su portátil | TE2 |
| C-16 | Herramientas: usar todo lo disponible (Blender sobre todo, Python, Pillow, etc.) eligiendo la adecuada para cada tarea. La mayoría de assets se hacen **desde cero** para reproducir las referencias | R1 + R3 |
| C-17 | Avisar al creador **antes** de actuar si surge cualquier inconveniente | R3 |
| C-18 | Dificultad **media** | X2 |
| C-19 | Idioma de interfaz y textos: **español** | X5 |
| C-20 | Créditos finales: «FIN DE LA DEMO» directo y después créditos breves con **solo dos nombres**, **Oziel Rodman Ramos Torrez** y **Christopher Barea Salazar**, que aparecen repetidamente mientras se ven secuencias del juego | N9 |
| C-21 | Menú principal **cinematográfico**: la cámara recorre escenarios de la cárcel y enemigos, con distorsiones y saltos momentáneos entre pasado y presente, en bucle | X3 |
| C-22 | Advertencias de fotosensibilidad y contenido al inicio (habrá bastante de ambos) | X4 |
| C-23 | Controles: **teclado + ratón y mando** | P3 |
| C-24 | **Se puede agachar; no hay salto** | P4 |
| C-25 | **Sin barra de vida** | P5 |
| C-26 | Al morir: **animación medio violenta** propia de cada muerte y pantalla **«Continuar»** | E4 |
| C-27 | **En el pasado siempre hay un motivo para escapar.** Si lo arrestan, ese motivo se pierde y sucede una «perdición de todo» (fracaso con consecuencia) | E4/E5 |

### 2.2. Narrativa y mundo (ronda 1)

| ID | Decisión |
|---|---|
| N1 | Secuencia base confirmada: celda → pasillo → objeto → persecución en el pasado → El Uniforme → pabellón → presencia de La Sentencia. Pasa a ser la **apertura** de la demo completa. |
| N2 | Disparador del primer recuerdo: **cartel «SE BUSCA» con su propia cara**, pegado imposiblemente en un muro de la prisión. |
| N3 | El primer flashback termina **acorralado ante una verja que se cierra** → corte a las rejas del presente. |
| N4 | Cadáveres: 2–3 al principio y **cada vez más**. Recursos tétricos: **personas colgadas**, etc. |
| N5 | Sin rótulos narrativos en la apertura; solo texto diegético. *(Documentos en la demo completa: ver H3.)* |
| N6 | Sin nombres en la apertura; número de preso en el uniforme. *(Número exacto: ver H1.)* |
| N7 | Ciudad hispanohablante ficticia, finales de los 80 o los 90. |
| N8 | La Sentencia se anuncia por arrastre, sombra y silueta parcial antes de mostrarse. |

### 2.3. Pasado y presente (ronda 1)

| ID | Decisión |
|---|---|
| D1 | Inversión mecánica confirmada como identidad del juego. |
| D2 | Pasado: carrera ágil y cámara suelta. Presente: caminar lento, carrera corta y ruidosa, respiración audible, cámara pegada. |
| D3 | El cambio de época siempre lo disparan objetos o lugares; nunca el jugador a voluntad. |
| D4 | Misma tubería PS1 y formato 16:9; cambian paleta, luz, grano y sonido. Sin VHS. |
| D5 | Presente → pasado: la lluvia entra antes que la imagen (J-cut) y el encuadre se re-dithera de frío a ámbar. |
| D6 | Pasado → presente: golpe metálico, corte seco a silencio absoluto y match cut de la verja a la reja. |

### 2.4. Personajes, enemigos y escenarios (ronda 1 + láminas)

| ID | Decisión |
|---|---|
| P1 | Protagonista **idéntico a las referencias**, con el ambiente igualado todo lo posible. |
| P2 | Sin diálogo del protagonista: respiración, jadeos, quejidos. |
| E1 | Policía con persecución «de goma elástica» y agentes y patrulla como escenografía. |
| E2 | **El Uniforme = híbrido sigilo + «Recuento»**: patrulla con llaves y, cuando callan, recuento (no te muevas dentro de su mirada). |
| E3 | **El Uniforme según la propuesta y la lámina del presente**: alto, uniforme azul marino, gorra de plato con placa, **rostro vacío**, aro de llaves, **sin hacha**. Animación a pocos fotogramas (propuesta AN2). |
| E6 | Siluetas inmóviles en pisos superiores del pabellón que desaparecen al volver a mirar. |
| E7 | La Sentencia: aprobada la propuesta **«El Mazo»**. ⚠ Conflicto con la lámina del presente: ver L1. |
| M1 | **La celda inicial está cerrada: hay un primer puzle para salir.** *(Tipo: ver K2.)* |
| M2 | Pasillo de 1,6 m de ancho y 2,4 m de techo, con recodo en L. |
| M3 | Pabellón central (Patio Central): planta octogonal o circular tipo panóptico, ~20 niveles, torre central, pasarelas y tragaluz. Pasarela jugable + grúa de cámara. |
| M4 | Callejón con la prisión visible sobre la colina al fondo. |
| M5 | **Sin iconografía religiosa**; iconografía institucional. |
| M6 | Estandartes rojos rasgados, pocos y desteñidos. |
| A1 | Render interno de 480 × 270 sin suavizado, texturas de 64–128 px, vibración de vértices sutil, dithering, grano y niebla. Iluminación cuidada. |
| A3 | Sangre seca y cadáveres en penumbra en general, **más un escenario gore** explícito. |
| A4 | Presente de madrugada con energía de emergencia: fluorescentes que fallan y luces rojas que se encienden al ser detectado. |
| A5 | Pasado: noche de lluvia intensa con luz de sodio. |
| C2–C4 | Quitar el control solo en momentos breves y saltables. 16:9 con bandas 2.39:1 en cinemáticas. Cámara lenta en el presente y nerviosa en el pasado. |
| AU1 | Casi sin música; diseño sonoro protagonista. Música y ritmo industrial donde el equipo de audio lo vea necesario. |
| AU2 | Voces grabadas por el equipo → listadas en `pendientes_equipo.md`. Mientras tanto, sustitutos provisionales. |

### 2.5. Ronda 2 (2026-11-12)

| ID | Decisión |
|---|---|
| G1 | **Demo amplia: 4 capítulos + final, 3 flashbacks** como objetivo del proyecto. *(Alcance para la entrega de la jam según el plazo: ver §5.0 y J2.)* |
| G2 | **Todos los enemigos de las láminas.** El Director y el alcaide solo como aparición. |
| G3 | Reglamento recibido y analizado (§1.4). Falta la fecha exacta de cierre de entrega (J1). |
| G4 | Flashbacks: **F1 «La huida»** (calles), **F2 «El interrogatorio»** (comisaría), **F3 «El ingreso»** (la prisión en el pasado). |
| G5 | **Motivo para escapar = pruebas robadas + proteger a una persona querida.** Dirección para el final del juego: el dilema **salvar a esa persona / salvar al mundo exponiendo las pruebas**. El creador cree que salvar a alguien dolería más. *(Quién es esa persona: N10.)* |
| G6 | Fracaso en el pasado = escena con la consecuencia → «Continuar» desde el punto de control del flashback. Sin ramificación. |
| G7 | **Revelar todo, absolutamente todo.** ⚠ Contradice la regla de spoilers del contexto absoluto → confirmar alcance en N11. |
| H1 | Penitenciaría Estatal N.º 314 · preso **N.º 4827** · Bloque A, celdas A1–A16. |
| H2 | El nombre del protagonista **no tiene por qué ser español** → elegir en N12. |
| H3 | Documentos legibles desde la pausa + inventario solo de objetos clave. |
| H4 | Colgados en las pasarelas del Patio Central; escenario gore en la Enfermería, explícito pero estático. |
| H5 | Rótulos de capítulo, sí. **El capítulo I se llama «Resiliencia»** (la mecánica de El Uniforme conserva su nombre interno, «Recuento»). |
| K1 | Sin botón de salto; «pasar por encima» contextual **solo en el pasado**. |
| K2 | **Puzle de la celda = ganzúa** con alambre del somier; mecánica reutilizable. |
| K3 | Muertes visibles hasta el impacto, corte a negro y «CONTINUAR». |
| K4 | **Guardado manual en lugares concretos; al morir solo se puede cargar.** *(Detalle propuesto en §7.2.)* |
| K5–K9 | Lanzar objetos para distraer · ganzúa en F2 con tiempo límite · focos de El Vigilante con alarma · El Condenado en espejos con puzle · La Sentencia como jefe-puzle de 3 mecanismos. |
| S1–S5 | Defensa B en el pasado (derribar, cerrar verjas) · escondites (celdas en sombra, catres, taquillas) · tipos de interacción · indicador punto + botón · detección por sonido y luz roja. |
| S+ | **Armas: pistola, cuchillo y escopeta**, útiles sobre todo contra jefes. *(Diseño propuesto en §7.1; contradicción con S1 «indefensión total» → W1.)* |
| AN2 / AN3 / AU4 | Aprobadas: manifestaciones a pocos fotogramas, lista de animaciones y firmas sonoras. |
| L1 | La Sentencia **híbrida**, pero **copiando la lámina** lo más fielmente posible: misma silueta (capucha alta, abrigo largo con cinturón y hebilla, cuchilla rectangular). Solo cambian la textura de la capucha (mantas de presidio con correas) y el arma (hoja hecha con una puerta de celda, con lomo de mazo). |
| L2 | **Logo híbrido**: serif de las láminas + marcas de conteo + estampado de sello, con menos sangre. |
| L3 | Las referencias pueden usarse **directamente como material** (carteles, emblema, texturas, recortes), acreditadas como generadas con ChatGPT (OpenAI). |
| L4 | Preajustes gráficos «Bajo» y «Alto», si es posible. |
| Q1 | **No hacer commits.** Al final se entrega la secuencia de comandos `git` (`add` / `commit` por bloques y subida a GitHub) para que el equipo la ejecute. |
| Q2 | Git LFS para `.blend`, imágenes, audio y modelos. |
| Q3 | Atribuciones **en los créditos finales y en la pantalla «Créditos y licencias»**, cumpliendo exactamente lo que exija cada autor y licencia. |
| Q4 | **No repartir tareas**: solo listarlas; el equipo se organiza. |
| Q5 | Guía completa para el equipo + **un `.md` de contexto para pasárselo a un agente de IA** → creado: `Materiales/contexto_para_agentes.md`. |

### 2.6. Ronda 3 (2026-11-12)

| ID | Decisión |
|---|---|
| J1 | **Cierre de entrega: 14 de noviembre de 2026.** El creador se encarga de la gestión del plazo con la organización. |
| J2 | **Se mantiene el plan acordado: demo amplia de 4 capítulos (G1).** No se reduce el alcance por la jam. Si el equipo necesita una build para entregar, se exporta con lo que exista en ese momento, a petición. |
| J3 | El creador da la entrevista por terminada. **Inicio autorizado el 12-11-2026** (ver C-28). |
| J4 | **Copia `.zip` del proyecto al cerrar cada etapa** en `respaldos/` (excluida del repositorio). Con el plan en 7 etapas, en la etapa 1 se hace además al cerrar cada bloque (§11.0). |
| J5 | Vídeo corto: más adelante. |
| N10 | La persona protegida es **su hermana menor**. |
| N11 | La demo completa revela **todo** (incluida su parte de culpa en la masacre y el guardia que intentaba salvarlo) y **termina justo antes del dilema final**, sin elección. |
| N12 | Protagonista: **Elías Novak**. |
| N13 | Sin documento aparte: la narrativa se desarrolla en una **sección de este archivo** (§4.5). |
| W1 | **Armas aprobadas** según §7.1 (punzón, pistola y escopeta limitados; no matan a las manifestaciones principales; sin armas en el pasado). |
| W2 | **Guardado aprobado** según §7.2 (marcas de conteo, cargar al morir, puntos de control propios en los flashbacks). |

### 2.7. Inicio del desarrollo y plan en 7 etapas (2026-11-12)

| ID | Decisión |
|---|---|
| C-28 | **Desarrollo autorizado** («puedes empezar»). El creador recuerda que hay muchas herramientas disponibles y que espera que se usen sobre todo Godot y Blender. |
| C-29 | **El plan de producción se organiza en 7 etapas**: 1 Preparación del juego · 2 Capítulo I — Resiliencia · 3 Capítulo II — Patio Central · 4 Capítulo III — Enfermería · 5 Capítulo IV — La Sentencia · 6 Final de la demo · 7 Revisión y entrega. Detalle, hitos y criterios de cierre en §11. |
| C-30 | **La etapa 1 agrupa las etapas 1 a 6 del plan v1.0**: base en Godot con estética PS1, movimiento y cámara, kit de prisión y Bloque A, protagonista y animaciones, mecánicas del capítulo I, flashback «La huida» y El Uniforme. Su objetivo es dejar estos elementos listos antes de montar el primer capítulo completo. |
| C-31 | **La etapa 2 integra** lo preparado en un capítulo I jugable de principio a fin (recorrido, transiciones, sonido y pulido). Las etapas 3, 4 y 5 desarrollan los capítulos II, III y IV con su flashback o su jefe. |
| C-32 | **La etapa 6** es la secuencia con El Director y los créditos; la demo termina justo antes del dilema final (ratifica N11). **La etapa 7** es la prueba del recorrido completo, la corrección, la optimización, la exportación final para Windows y la documentación de entrega. |

### 2.8. Heredadas del contexto absoluto (siguen vigentes)

Título definitivo **LIFETIME SENTENCE** · protagonista moralmente ambiguo · manifestaciones de culpa con diseño propio · regla «mismo referente humano → mecánica distinta» · pasado inicial **fuera** de la prisión · paleta (presente frío / pasado ámbar / rojo como acento) · megalofobia en **una** zona interior · sin futurismo · no revelar los grandes giros (responsabilidad en la masacre, guardia que ayudaba, naturaleza de las manifestaciones, final).

---

## 3. Preguntas y respuestas

> **Nota sobre la numeración.** Las preguntas de esta sección son un registro histórico: cuando hablan de «etapas» o «hitos» usan la numeración del plan v1.0 (11 etapas). La equivalencia con las 7 etapas actuales está en §11.8. Las decisiones vigentes están en §2.

### 3.1. Ronda 1 — respuestas registradas

| Sección | Resultado |
|---|---|
| N1–N8 | Confirmadas (ver §2.2). N4 ampliada: cadáveres en aumento y personas colgadas. **N9 modificada** (ver C-20). |
| D1–D6 | Confirmadas. |
| P1–P5 | Confirmadas, con modificaciones: P3 → teclado, ratón y mando; P4 → agacharse sí, salto no. |
| E1–E7 | E1, E2, E6 y E7 confirmadas; E3 confirmada junto con la lámina. **E4 y E5 modificadas** (ver C-26 y C-27). |
| **S1–S5** | **Sin respuesta → se repiten en la ronda 2.** |
| M1–M6 | Confirmadas; **M1 modificada** (puzle para salir de la celda). |
| A1–A5 | Confirmadas; **A2 modificada** (usar las referencias por completo); **A3 ampliada** (un escenario gore). |
| C1–C4 | Confirmadas. |
| AN1 | Cualquier fuente gratuita con créditos debidos y registro de lo hecho con IA. **AN2 y AN3 sin respuesta → ronda 2.** |
| AU1–AU3 | Confirmadas (AU2 al documento de pendientes; AU3: CC BY sí, citando siempre). **AU4 sin respuesta → ronda 2.** |
| X1–X5 | **X1 modificada** (demo completa sin límite), X2 = dificultad media, **X3 modificada** (menú cinematográfico), X4 sí, X5 español. |
| TR1–TR7 | Valoradas positivamente, pero el **tráiler queda pospuesto**. |
| TE1–TE6 | TE1 sí; TE2 prima lo artístico pero debe poder probarse; TE3 sí, registrando la instalación; TE4 un `.exe` + escalabilidad + GitHub; TE6 sí (se pueden crear más carpetas). TE5 → ver Q1. |
| R1–R6 | R1 usar todo lo disponible; **R2: la IA participa en todo**; R3 casi todo desde cero, Blender autorizado, avisar inconvenientes; R6 láminas añadidas. **R4 y R5 sin respuesta → ronda 2.** |

### 3.2. Ronda 2 — preguntas (enviada y respondida el 2026-11-12; respuestas en §2.5)

Se conservan las preguntas como registro. La columna «Respuesta» de esta sección **no se actualiza**: la decisión vigente está en §2.5.

#### G. Alcance de la demo completa

| ID | Pregunta | Propuesta | Respuesta |
|---|---|---|---|
| G1 ★ | **Estructura.** a) **Acto I corto**: capítulos 1–2, 2 flashbacks; enemigos Uniforme, Vigilante y Aislados (~25–35 min). b) **Demo amplia**: 4 capítulos + final, 3 flashbacks, casi todo el roster (~45–60 min) (ver §5). c) Otra. | **b)**, construida capítulo a capítulo y diseñada para que al terminar el capítulo 2 ya exista una demo cerrada y entregable si el tiempo apremia. | _pendiente_ |
| G2 ★ | **Enemigos incluidos.** Presente: Aislados, Uniforme, Vigilante, Condenado, Sentencia (jefe) y Director (solo aparición final). Pasado: patrullero, táctico, guardia, interrogador, verdugo y alcaide (solo aparición). ¿Quitar o añadir? | Todos, con ese reparto de peso. | _pendiente_ |
| G3 ★ | **Fecha límite** de la Game Jam, reglas sobre assets de terceros e IA, y si la demo será gratuita o comercial (era R5). La demo completa es un orden de magnitud más grande que la micro-demo y la fecha decide entre G1-a y G1-b. | — | _pendiente_ |
| G4 | **Flashbacks**: F1 «La huida» (calles lluviosas, patrulleros y tácticos), F2 «El interrogatorio» (comisaría, escapar del interrogador), F3 «El ingreso» (la prisión en el pasado, cálida y llena de guardias y presos; verdugo visto de lejos). ¿De acuerdo? | Esos tres. | _pendiente_ |
| G5 ★ | **El motivo para escapar** (C-27). a) Lleva **pruebas robadas** (una carpeta) que comprometen a las autoridades y debe esconderlas antes de que lo atrapen; b) protege a **una persona** (hermana o hija) a la que debe llegar o avisar; c) una deuda o amenaza; d) **mezcla a + b**: robó por dinero para alguien que le importa y entre el botín encontró papeles que lo convirtieron en objetivo. | **d)**. En F1 debe esconder la carpeta en un buzón o escondite; si lo arrestan antes, la carpeta se pierde y se ve la consecuencia. Insinúa la conspiración sin revelar los giros. | _pendiente_ |
| G6 | **«Perdición de todo» al fallar en el pasado**: a) fracaso con escena de consecuencia → «Continuar» desde el último punto de control del flashback; b) consecuencia permanente que cambia la historia (ramificación). | **a)**: la ramificación multiplica el trabajo y contradice que el pasado ya ocurrió. | _pendiente_ |
| G7 | **Profundidad narrativa**: ¿cuánta verdad revela la demo? | Hasta las revelaciones 1–2 del contexto §2.2 (robo real y papeles que comprometen a autoridades) e indicios de la 3 (la prisión silenciaba testigos). Nada de la 4–7. Final en suspenso. | _pendiente_ |

#### H. Narrativa e identidad

| ID | Pregunta | Propuesta | Respuesta |
|---|---|---|---|
| H1 | La lámina del pasado llama a la prisión **«Penitenciaría Estatal N.º 314»** y muestra el **«EXP. N.º 4827»**. Proponía «B-314» como número de preso, pero chocaría con el número de la prisión. | Prisión: **Penitenciaría Estatal N.º 314**. Número de preso: **4827** (el del expediente) en el uniforme. Bloque inicial: **Bloque A, celdas A1–A16** (rótulo de la lámina). | _pendiente_ |
| H2 | En la demo completa habrá expedientes y su nombre aparecerá. ¿Nombre del protagonista? | Propón uno, o elige: *Daniel Ferro*, *Iván Salcedo*, *Mateo Arce*, *Tomás Rivas*. | _pendiente_ |
| H3 | **Documentos e inventario.** ¿Hay notas y expedientes legibles? ¿Inventario? | Documentos legibles (expedientes, notas, recortes) en un archivo consultable desde la pausa. Inventario **solo de objetos clave** (llaves, ganzúa, fusible…), sin gestión de espacio. | _pendiente_ |
| H4 | **Colgados y escenario gore**: ¿dónde? | Colgados en las pasarelas del Patio Central, como siluetas en la niebla. Escenario gore en la **Enfermería**: camillas, instrumental y cuerpos abiertos. Explícito pero estático, sin animación de mutilación. | _pendiente_ |
| H5 | ¿Rótulos de capítulo (p. ej. «I — RECUENTO»)? | Sí: una tarjeta breve con tipografía de expediente al empezar cada capítulo. | _pendiente_ |

#### K. Mecánicas

| ID | Pregunta | Propuesta | Respuesta |
|---|---|---|---|
| K1 ★ | **Conflicto D1 frente a P4**: D1 incluía «saltar obstáculos bajos» en el pasado, pero P4 dice «sin saltos». a) ningún salto: se rodean obstáculos o se pasa agachado por debajo; b) **sin botón de salto**, pero «pasar por encima» contextual en obstáculos marcados (animación automática). | **b)** solo en el pasado. | _pendiente_ |
| K2 ★ | **Puzle de la celda** (M1): a) **ganzúa**: sacar un alambre del somier y forzar la cerradura con un minijuego (girar, sentir el pin por sonido y vibración del mando); b) código oculto en las marcas de conteo de días en la pared; c) desatornillar una rejilla. | **a)**: es la habilidad del ladrón, define su identidad y es reutilizable en toda la demo. Las marcas de conteo quedan como detalle visual. | _pendiente_ |
| K3 | **Muertes medio violentas** por enemigo: Uniforme (lo alza del cuello entre llaves), policía (placaje y esposas → consecuencia G6), Aislados (lo arrastran al suelo en grupo), Vigilante (el foco lo ciega y llega El Uniforme), Sentencia (golpe con corte a negro en el impacto). ¿Nivel? | Mostrar hasta el impacto y cortar a negro con sonido. Después «CONTINUAR». | _pendiente_ |
| K4 | **Guardado**: autoguardado en puntos de control y opción «Continuar» en el menú principal. | Sí. | _pendiente_ |
| K5 | **Distraer** lanzando objetos (botellas, latas) en el presente, sobre todo contra Los Aislados. | Sí. | _pendiente_ |
| K6 | ¿Ganzúa también en los flashbacks (forzar una puerta para escapar)? | Sí, una vez en F2 y con tiempo límite. | _pendiente_ |
| K7 | **El Vigilante**: torre o lámpara-cabeza; sus focos barren las pasarelas. Ser iluminado más de ~1 s activa la alarma, que atrae a El Uniforme y Los Aislados. | Sí. | _pendiente_ |
| K8 | **El Condenado** (doble): apariciones guionizadas en espejos y lugares por los que ya pasaste, más un puzle de espejos que exige moverse al revés que él. Sin ataque en la demo. | Sí. | _pendiente_ |
| K9 | **La Sentencia como jefe** (capítulo 4): puzle bajo presión con 3 mecanismos para abrir una puerta; el ruido la atrae, sus golpes destruyen coberturas y termina en una huida. | Sí. | _pendiente_ |

#### S. Sigilo, defensa e interacciones (sin respuesta en la ronda 1)

| ID | Pregunta | Propuesta | Respuesta |
|---|---|---|---|
| S1 ★ | Defensa. | Pasado: derribar cubos y cerrar verjas para ganar tiempo. Presente: **indefensión total**; solo esconderse, quedarse quieto y distraer. | _pendiente_ |
| S2 | Escondites. | Celdas abiertas en sombra, bajo catres (agachado) y taquillas. Sin animación especial salvo para taquillas. | _pendiente_ |
| S3 | Tipos de interacción. | Puertas, ganzúa, examinar y leer, recoger objetos clave, derribar, palancas y fusibles, esconderse y lanzar objetos. | _pendiente_ |
| S4 | Indicador de interacción. | Punto blanco pequeño + glifo de tecla o botón, sin texto. | _pendiente_ |
| S5 | Indicador de detección. | Ninguno visual; solo sonido y luz roja de emergencia. | _pendiente_ |

#### L. Arte

| ID | Pregunta | Propuesta | Respuesta |
|---|---|---|---|
| L1 ★ | **La Sentencia**: aprobaste «El Mazo», pero la lámina del presente muestra otro diseño (capucha alta, abrigo largo con cinturón y hebilla, cuchilla rectangular ensangrentada). a) El Mazo; b) la lámina tal cual; c) **híbrido**: silueta de la lámina (capucha alta y abrigo) con la capucha hecha de mantas de presidio atadas con correas y el arma convertida en mazo-hoja (puerta de celda afilada). | **c)**: conserva tu referencia y la aleja del arquetipo de verdugo de otros juegos. | _pendiente_ |
| L2 ★ | **Logo**: aprobaste la propuesta institucional (sello de sentencia), pero todas las referencias usan el serif desgastado con sangre, y la del presente añade **marcas de conteo** y una torre. a) sello institucional; b) estilo de las láminas; c) **híbrido**: el serif de las láminas + marcas de conteo + estampado de sello, con menos sangre. | **c)**. | _pendiente_ |
| L3 | **Uso directo de las referencias** (A2): entiendo que, además de copiar el estilo, puedo usarlas como material (carteles, emblema del estandarte, texturas y recortes), acreditadas como «generadas con ChatGPT (OpenAI)». ¿Correcto? ¿Quién las generó, para los créditos? | Sí, con esa atribución. | _pendiente_ |
| L4 | **Calidad gráfica**: preajuste «Bajo» para probar en tu portátil y «Alto» (niebla volumétrica, más luces y sombras) para equipos potentes. | Sí, seleccionable en Opciones. | _pendiente_ |
| AN2 | Animación a pocos fotogramas para las manifestaciones frente a la fluidez del protagonista. | Sí. | _pendiente_ |
| AN3 | Animaciones del protagonista: idle, caminar, correr, agachado (idle y andar), mirar atrás, levantarse, empujar, derribar, pasar por encima (K1), ganzúa, leer, recoger, lanzar, esconderse, congelarse y muertes (K3). ¿Falta algo? | Esa lista. | _pendiente_ |
| AU4 | Firmas sonoras: El Uniforme = llaves; silencio súbito = recuento; La Sentencia = arrastre + golpe de mazo; El Vigilante = zumbido eléctrico del foco; Los Aislados = respiración húmeda; corte a silencio al volver del pasado. | Sí. | _pendiente_ |

#### Q. Equipo, repositorio y documentación

| ID | Pregunta | Propuesta | Respuesta |
|---|---|---|---|
| Q1 ★ | **Git.** a) Inicio git **local** ya, hago un commit por etapa con mensajes claros, y al final te doy los comandos para crear el repositorio en GitHub y subirlo; b) sin git durante el desarrollo, y al final te doy una secuencia de `git add` y `git commit` por bloques para que la ejecutes tú. | **a)**: el historial queda bien separado y además permite volver atrás si algo se rompe. | _pendiente_ |
| Q2 | **Assets grandes**: la «extensión» que buscas es **Git LFS**, y ya está instalada (3.7.1). Cada miembro solo ejecuta `git lfs install` una vez. GitHub limita el almacenamiento y la transferencia gratuitos de LFS, así que conviene revisar la cuota de la cuenta. ¿Usamos LFS para `.blend`, `.png`, `.wav`, `.ogg` y `.glb`? | Sí. | _pendiente_ |
| Q3 ★ | **Créditos de terceros e IA.** Los créditos finales mostrarán solo los dos nombres (C-20). Las licencias CC BY y la declaración de IA tienen que verse en algún sitio: a) una pantalla «Créditos y licencias» en el menú principal + `CREDITOS.md`; b) una tarjeta final tras los nombres; c) ambas. | **a)** + una tarjeta breve al final: «Desarrollado con asistencia de IA — ver Créditos y licencias». | _pendiente_ |
| Q4 | **Roles del equipo**: ¿qué sabe hacer o prefiere cada uno (grabar voces, 3D, programación, pruebas, sonido)? Sirve para asignar `pendientes_equipo.md`. | — | _pendiente_ |
| Q5 | **Documentación de modificación**: una «Guía del equipo» (cómo añadir una pieza de escenario, un enemigo, un documento, cambiar un sonido o exportar) con convenciones de nombres. | Sí, en `docs/GUIA_EQUIPO.md`. | _pendiente_ |

### 3.3. Ronda 3 — preguntas (enviada y respondida el 2026-11-12; respuestas en §2.6)

#### J. Plazo y entrega de la jam

| ID | Pregunta | Propuesta | Respuesta |
|---|---|---|---|
| J1 ★ | **Fecha y hora exactas del cierre de entrega** (el reglamento solo da la exhibición del 21-11). ¿Ya se conoce la plataforma de entrega? ¿El periodo oficial ya empezó? | — | _pendiente_ |
| J2 ★ | **Alcance para la entrega de la jam.** Quedan como máximo 9 días, menos hasta el cierre de entrega. a) **Capítulo I «Resiliencia» completo y pulido** (~15–20 min: celda y ganzúa, Bloque A, F1, El Uniforme, guardado, muertes, menú cinematográfico, revelación del Patio Central y anuncio de La Sentencia → FIN DE LA DEMO). Los capítulos II–IV siguen después de la jam, porque el reglamento permite el desarrollo posterior. b) Capítulos I–II. c) Los 4 capítulos. | **a)**. En mi estimación, b) es arriesgada y c) no cabe en el plazo sin sacrificar calidad y funcionamiento, que el jurado puntúa. | _pendiente_ |
| J3 ★ | **Autorización para empezar la etapa 1 ya**: proyecto Godot, tubería visual PS1, movimiento, agacharse, cámara por zonas y prueba de rendimiento. No depende de ninguna pregunta abierta. El resto de preguntas se resuelve en paralelo. | Empezar hoy. | _pendiente_ |
| J4 | **Copias de seguridad** (el reglamento las exige y no habrá commits): un `.zip` del proyecto al cerrar cada etapa en `respaldos/`, excluido del repositorio. | Sí. | _pendiente_ |
| J5 | Si la organización pide un **vídeo corto**, ¿lo preparo al final con imágenes del juego (30–60 s)? | Sí, como última tarea y solo si sobra tiempo o lo exigen. | _pendiente_ |

#### N. Narrativa

| ID | Pregunta | Propuesta | Respuesta |
|---|---|---|---|
| N10 ★ | **¿A quién protege?** Lo necesita la escena de consecuencia de F1. a) hermana menor; b) hija pequeña; c) madre; d) pareja. | **a) hermana menor**: es vulnerable, encaja con un ladrón joven y el dilema final duele. | _pendiente_ |
| N11 ★ | **«Revelar todo»** contradice la regla del contexto («la demo no debe revelar la gran verdad»). a) La demo completa lo revela todo: su papel en la masacre, el guardia que intentaba salvarlo y el dilema final con elección; b) todo salvo la elección: termina justo ante el dilema; c) mantener la regla original. | **b)** para la demo completa. En la entrega de la jam (si J2 = a), el capítulo I revela solo lo que le corresponde. | _pendiente_ |
| N12 | **Nombre del protagonista** (no tiene que ser español). Opciones: *Elías Novak*, *Adrián Voss*, *Nicolás Varga*, *Julián Hale*, *Leo Marlowe*, o el que propongáis. | — | _pendiente_ |
| N13 | Para revelarlo todo hace falta un guion completo. ¿Escribo una **biblia narrativa** (personajes, cronología real, qué revela cada capítulo, documentos, final) para que la apruebes? | Sí, antes del capítulo II. Para el capítulo I bastan las piezas que ya están decididas. | _pendiente_ |

#### W. Armas y guardado

| ID | Pregunta | Propuesta | Respuesta |
|---|---|---|---|
| W1 ★ | **Sistema de armas** (§7.1). Aprobaste «indefensión total» en el presente (S1) y a la vez pides pistola, cuchillo y escopeta. ¿Apruebas este diseño, que las limita para conservar el miedo? | §7.1 | _pendiente_ |
| W2 | **Sistema de guardado** (§7.2): paredes con marcas de conteo donde guardar, partida perdida al morir hasta la última carga, los flashbacks con su propio punto de control. ¿Apruebas? | §7.2 | _pendiente_ |

---

## 4. Dirección narrativa, artística y técnica

### 4.1. Tema y sensaciones

**Tema:** *en el pasado corres de la ley; en el presente, la ley te obliga a quedarte quieto.*

Sensaciones por orden de aparición:

1. **Encierro**: celda cerrada y pasillos.
2. **Pérdida**: recuerdos vivos y regreso al silencio.
3. **Insignificancia**: el Patio Central.
4. **Degradación**: cada vez más cuerpos, colgados y gore.
5. **Castigo**: La Sentencia.
6. **Sistema**: El Director.

### 4.2. Dirección artística [CONFIRMADO: replicar las referencias]

| Aspecto | Presente | Pasado |
|---|---|---|
| Luz clave | Fluorescente frío intermitente + luz de luna por el tragaluz | Sodio ámbar (calle) / fluorescente cálido (comisaría, prisión antigua) |
| Acentos | Rojo de emergencia al ser detectado; estandartes desteñidos | Rojo y azul de patrulla |
| Paleta | Gris azulado, azul oscuro, verde enfermizo, negro | Ámbar sucio, sepia, gris cálido |
| Materiales | Concreto húmedo, pintura desconchada verde/beige, hierro oxidado, azulejo, sábanas colgando | Ladrillo mojado, asfalto, metal pintado, madera de oficina |
| Señalética | «BLOQUE A — CELDAS A1–A16», «PATIO CENTRAL I», «SILENCIO», números de celda | Carteles «SE BUSCA», rótulos de comisaría, «POLICÍA» |
| Sonido | Silencio, zumbido, goteo, eco largo | Lluvia, sirena, silbatos, radio, gritos |

**Fichas de diseño de personajes** (fuente: láminas de pasado y presente):

| Personaje | Diseño |
|---|---|
| Protagonista | Joven adulto, pelo oscuro despeinado. Presente: uniforme naranja (camisa de manga corta sobre camiseta blanca) sucio y con sangre. Pasado: chaqueta granate gastada, camiseta blanca, corte en la mejilla. |
| Policía patrullero | Azul marino, gorra de plato con placa, porra, linterna, **silbato que llama refuerzos**. |
| Policía táctico | Antidisturbios: casco, chaleco, escudo «POLICÍA», porra. |
| Guardia penitenciario | Camisa caqui, corbata, gorra, llaves, porra (pistola en algunas zonas). |
| Interrogador | Camisa blanca, corbata roja, tirantes, bigote. |
| Verdugo penitenciario | Gorra, camisa, delantal de cuero manchado, hacha de ejecución. |
| Alcaide corrupto | Traje oscuro de tres piezas, corbata roja, cadena de reloj. |
| Los Aislados | Presos demacrados en uniforme naranja hecho jirones, rostro borroso y pixelado; lentos y erráticos; atacan en grupo. |
| El Uniforme | Muy alto, uniforme azul marino, gorra con placa, **rostro vacío**, aro de llaves; no puede destruirse. |
| El Vigilante | Delgadísimo, con una **lámpara o garita de torre por cabeza**; observa desde lejos y alerta a otros. |
| El Condenado | Doble ensangrentado del protagonista, rostro pixelado; imita y anticipa sus movimientos. |
| La Sentencia | *Pendiente de L1.* |
| El Director | Colosal, abrigo largo oscuro, gorra con insignia, mano enorme, rostro pétreo. |

**Reglas visuales:** toda luz tiene fuente verosímil; silueta antes que detalle; el protagonista es la mancha más cálida del encuadre en el presente; iconografía institucional, no religiosa.

### 4.3. Herramientas: qué se usa para qué [CONFIRMADO: usar todo lo disponible]

| Herramienta | Uso |
|---|---|
| **Blender 5.2** | Modelado low-poly (personajes, kit modular de prisión, ciudad), UV, texturizado, rigging, animación, horneado de luz en color de vértice, exportación glTF. Los `.blend` se guardan para que el equipo los edite. |
| **Godot 4.7.2** | Todo lo jugable: escenas, niveles montados con piezas, iluminación, shaders PS1, IA, cinemáticas, audio, interfaz, exportación. |
| **Python + Pillow (+ numpy)** | Texturas procedurales (concreto, óxido, ladrillo), reducción a paleta PS1 y dithering, procesado por lotes, síntesis de sonido. |
| **FFmpeg** | Conversión y normalización de audio, y vídeo si vuelve el tráiler. |
| **Three.js** | No se necesita: Godot cubre el render en tiempo real. |

### 4.4. Principio de editabilidad [CONFIRMADO C-13]

- **Niveles montados en el editor** con piezas modulares (escenas `.tscn`: muro, celda, pasarela, puerta, farola…) que el equipo puede arrastrar, duplicar y recolocar.
- **Objetos de juego configurables desde el Inspector**: puerta (cerrada o abierta, llave requerida), objeto interactuable (texto, sonido), punto de control, zona de cámara, ruta de patrulla (`Path3D`), zona de recuerdo.
- **Datos en recursos `.tres`**: configuración de enemigos (velocidades, visión, sonidos), documentos (título y texto), flashbacks.
- **Fuentes de arte** (`.blend`, texturas de origen) incluidas en el repositorio con nombres claros.
- **Código GDScript comentado en español**, con documentación visible en el editor (`##`).
- **Guía del equipo** *(Q5)*.

### 4.5. Guía narrativa (biblia) [CONFIRMADO lo marcado; el resto PROPUESTO]

Se completará antes del capítulo II (N13: dentro de este archivo, sin documento aparte).

#### 4.5.1. Datos fijos [CONFIRMADO]

| Elemento | Valor |
|---|---|
| Protagonista | **Elías Novak**, joven adulto, ladrón. Moralmente ambiguo: no es inocente |
| Identidad penitenciaria | **Preso N.º 4827**, Bloque A (celdas A1–A16), **Penitenciaría Estatal N.º 314** |
| Persona protegida | **Su hermana menor** (nombre por definir en la etapa 1, bloque 1.5) |
| Motivo | Robó por dinero para su hermana. Entre el botín había **papeles que comprometen a las autoridades**, y eso lo convirtió en objetivo |
| Ambientación | Ciudad hispanohablante ficticia, finales de los 80 o los 90 |
| Revelación | La demo **revela todo**: el robo real, los papeles, la prisión que silenciaba testigos, que su acción disparó el protocolo de ejecución, su parte de culpa y el guardia que intentaba impedir la masacre |
| Final de la demo | **Justo antes del dilema**: salvar a su hermana o salvar al mundo exponiendo las pruebas. Sin elección → **FIN DE LA DEMO** |
| Regla de fracaso en el pasado | Si lo arrestan, el motivo se pierde y se ve la consecuencia → reintento del flashback |

#### 4.5.2. Reparto de revelaciones por capítulo [PROPUESTO]

| Capítulo | Qué descubre el jugador | Vehículo |
|---|---|---|
| I «Resiliencia» | **El robo fue real** y tenía que esconder algo (la carpeta) para proteger a su hermana | Cartel «SE BUSCA», F1 (esconder la carpeta), expediente de ingreso n.º 4827 |
| II «Patio Central» | **Los papeles comprometen a autoridades**: el interrogador no busca el dinero, busca la carpeta | F2 (interrogatorio), documentos del archivo |
| III «Enfermería» | **La prisión silenciaba y ejecutaba a testigos**. Indicios de **un guardia que intentaba conservar pruebas** | Enfermería gore, registros médicos falsificados, F3 (el ingreso, donde ese guardia aparece vivo) |
| IV «La Sentencia» + Final | **Su intento de fuga (o acción) disparó el protocolo de ejecución masiva**: tiene parte de culpa. El guardia murió intentando detenerlo. El Director (el sistema) le ofrece la salida: su hermana o la verdad | La Sentencia como castigo que «cobra» la culpa; megafonía del alcaide; última escena ante el dilema |

#### 4.5.3. Por escribir antes del capítulo II

Nombre de la hermana · guion de F2 (líneas del interrogador, V-07) · guion de F3 · nombre y papel del guardia que ayudaba · textos de documentos y expedientes · avisos de megafonía (V-08) · escena final ante el dilema.

---

## 5. Alcance de la demo completa [CONFIRMADO G1: 4 capítulos y final]

### 5.0. Alcance para la entrega de la jam [CONFIRMADO J2: se mantiene el plan de 4 capítulos; el creador gestiona el plazo]

*Se conserva el análisis original como registro:*

La demo amplia de 4 capítulos (G1) sigue siendo **el objetivo del proyecto**. El plazo de la jam (exhibición el 21-11-2026, entrega antes) obliga a decidir **qué parte se entrega**.

| Opción | Contenido entregado | Riesgo |
|---|---|---|
| **J2-a (propuesta)** | **Capítulo I «Resiliencia» completo y pulido**: menú cinematográfico, advertencias, celda y ganzúa, Bloque A, F1 «La huida», El Uniforme, guardado, muertes, documentos del capítulo, revelación del Patio Central, anuncio de La Sentencia → FIN DE LA DEMO → créditos | Bajo–medio |
| J2-b | Capítulos I y II (añade Patio Central jugable, El Vigilante, Los Aislados y F2) | Alto |
| J2-c | Los 4 capítulos | Muy alto: probablemente incompleto o con fallos, y el jurado puntúa la calidad técnica y el funcionamiento |

Después de la jam, el desarrollo continúa capítulo a capítulo con este mismo plan.

### 5.1. Estructura de la demo (opción G1-b, confirmada)

| Bloque | Contenido | Enemigos | Duración estimada (1.ª partida, dificultad media) |
|---|---|---|---|
| **Menú cinematográfico** | Recorrido de cámara por escenarios y enemigos, con distorsiones pasado ↔ presente. Opciones: Continuar / Nueva partida / Opciones / Créditos y licencias / Salir. | — | — |
| **Advertencias** | Fotosensibilidad y contenido. | — | — |
| **Cap. I — «Resiliencia»** (Bloque A) | Despertar → puzle de ganzúa → pasillos con cadáveres en aumento → cartel → **F1** → regreso → **El Uniforme** (Recuento) → puerta monumental | Uniforme | 12–18 min |
| **F1 — «La huida»** (calles lluviosas) | Motivo G5: esconder la carpeta. Patrulleros con silbato que llaman refuerzos, tácticos que cierran calles, derribar obstáculos, pasar por encima, cruces → verja | Patrullero, táctico | dentro del cap. I |
| **Cap. II — «Patio Central»** | Revelación monumental → colgados → **El Vigilante** barre pasarelas → **Los Aislados** en niveles inferiores (ruido, distraer) → restaurar energía de un ascensor antiguo (puzle de fusibles) → **F2** | Vigilante, Aislados, Uniforme | 12–15 min |
| **F2 — «El interrogatorio»** (comisaría) | Tensión con el interrogador → escapar por oficinas y archivos (ganzúa con tiempo límite, guardias) | Interrogador, patrulleros | dentro del cap. II |
| *Punto de corte seguro* | *Si la fecha apremia, aquí puede terminar una demo cerrada (G1-a) con el anuncio de La Sentencia.* | | |
| **Cap. III — «Enfermería»** | Investigación y documentos → **escenario gore** → **El Condenado** en espejos y puzle de espejos → puzle de código con expedientes → **F3** | Condenado, Aislados | 10–12 min |
| **F3 — «El ingreso»** (prisión en el pasado) | La prisión viva y cálida, con guardias y presos; escapar de un traslado; el verdugo visto de lejos | Guardias, verdugo (aparición) | dentro del cap. III |
| **Cap. IV — «La Sentencia»** | Sala de ejecución: puzle bajo presión con 3 mecanismos, coberturas destruidas y huida | Sentencia | 6–10 min |
| **Final** | Megafonía del alcaide / El Director; silueta colosal → **FIN DE LA DEMO** → créditos con los dos nombres sobre secuencias del juego | Director (aparición) | 2–3 min |
| **Total** | | | **~45–60 min** |

**Correspondencia con las etapas de producción (§11):**

| Bloque de la demo | Etapa |
|---|---|
| Cap. I «Resiliencia» y F1 «La huida» | **1** (se preparan sus piezas) y **2** (se monta el capítulo) |
| Cap. II «Patio Central» y F2 | **3** |
| Cap. III «Enfermería» y F3 | **4** |
| Cap. IV «La Sentencia» | **5** |
| Final, créditos y versión final del menú | **6** |
| Advertencias, pausa, opciones y primera versión del menú | **2** *(propuesto)* |
| Pruebas, exportación final y documentación de entrega | **7** |

El *punto de corte seguro* coincide con el hito **H3** (cierre de la etapa 3).

### 5.2. Fuera del alcance (demo completa)

Combate y armas, barras de vida, ramificación narrativa y finales alternativos, El Director como jefe jugable, mapa abierto, gestión de inventario, logros, otros idiomas, versión web y consola. **Tráiler: pospuesto.**

### 5.3. Transparencia jugable / guionizado

Se mantiene: cada cinemática se marca en el documento final de funciones y limitaciones. Las persecuciones, el Recuento, el Vigilante, Los Aislados y el jefe usan IA real.

---

## 6. Storyboard — Capítulo I «Resiliencia» [PROPUESTO v0.3]

*La etapa 1 prepara las piezas de este recorrido por separado; la etapa 2 lo monta de principio a fin. Los capítulos II, III y IV se detallarán al empezar sus etapas (3, 4 y 5).*

| # | Zona / época | Qué ocurre | Control | Cámara | Audio |
|---|---|---|---|---|---|
| 1.1 | Negro → celda A-? (PRESENTE) | Un fluorescente arranca y revela al preso **en el suelo**. | Cinemática (≤ 5 s, saltable) | Cenital fijo | Respiración, zumbido, gota |
| 1.2 | Celda cerrada | Explorar la celda: marcas de conteo de días en la pared. Arrancar un alambre del somier → **ganzúa** (K2) → la puerta cede. | **Jugable** (puzle 1) | Sobre el hombro, muy cerca | Metal, chasquidos de cerradura |
| 1.3 | Bloque A, pasillo | Rótulo «BLOQUE A — CELDAS A1–A16». 2–3 cadáveres, sangre seca, recodo. Documento opcional. **Cartel «SE BUSCA» imposible**, mojado y goteando. | **Jugable** | Baja, techo opresivo | Silencio, goteo |
| 1.4 | Transición D5 | Examinar el cartel: la lluvia entra antes que la imagen; re-dither de frío a ámbar. | Guionizado | Primer plano → el mismo cartel en la calle (match cut) | J-cut de lluvia |
| 1.5 | **F1 — calles lluviosas** (PASADO) | «¡Alto!». Objetivo: **esconder la carpeta** (G5). Silbato → refuerzos; tácticos cierran calles; derribar cubos; pasar por encima (K1); cruces. Si lo arrestan antes de esconderla → escena de consecuencia → **CONTINUAR**. Tras esconderla, acorralado ante la verja (captura inevitable). | **Jugable** | Abierta y nerviosa | Lluvia, sirena, silbatos, radio, charcos, latido |
| 1.6 | Transición D6 | Linterna que ciega, mano en la verja → **CLANG** → rejas oxidadas del presente, silencio absoluto. | Guionizado | Match cut verja → reja | Golpe → silencio |
| 1.7 | Bloque A, ala B | Más cadáveres. Llaves a lo lejos → **El Uniforme**. Las llaves callan: **RECUENTO**. Esconderse en celdas en sombra o bajo catres; quieto en el haz. Si te atrapa: lo alza del cuello → negro → **CONTINUAR**. | **Jugable** (sigilo) | Pegada; luz roja al detectar | Llaves → silencio → respiración contenida |
| 1.8 | Puerta monumental | Puerta de seguridad desproporcionada; un guardia muerto en el umbral. Lejos, un **arrastre metálico** (primer anuncio de La Sentencia). | Mixto | Contraluz | Mecanismo pesado, arrastre lejano |
| 1.9 | Patio Central | **Revelación**: pasarela, la cámara se aleja en grúa, preso diminuto, siluetas inmóviles en pisos altos → rótulo «II — PATIO CENTRAL» *(H5)*. | Jugable + toma automática | Grúa | Reverberación inmensa |

**Guardado (§7.2):** autoguardado al empezar el capítulo. Paredes con marcas de conteo en la celda (tras la ganzúa), en el Bloque A antes del cartel, al volver de F1 antes del ala B, y junto a la puerta monumental. F1 tiene punto de control interno al inicio y a mitad.
**Punzón (§7.1):** se encuentra en el Bloque A, en un cadáver, antes del encuentro con El Uniforme.

---

## 7. Mecánicas a implementar [CONFIRMADO en las rondas 1–3; el detalle de cada una se propone en su etapa]

*Reparto por etapas (§11): las mecánicas del capítulo I se preparan en la etapa 1 (bloques 1.1, 1.4, 1.5 y 1.6) y se integran en la etapa 2. Las de los capítulos II, III y IV se hacen en las etapas 3, 4 y 5. La columna «Capítulo» indica dónde aparece cada una por primera vez.*

| Mecánica | Detalle | Capítulo |
|---|---|---|
| Control en tercera persona | `CharacterBody3D`: caminar, correr, **agacharse**, sin salto. Perfil de movimiento por época (D2) | I |
| Cámara híbrida | `SpringArm3D` anticolisión + `CameraZone` editables | I |
| Interacción | Componente reutilizable configurable en el Inspector; indicador mínimo (S4) | I |
| **Ganzúa** | Minijuego de cerradura con sonido y vibración del mando; dificultad configurable por cerradura | I, II |
| Pasar por encima contextual | Solo en obstáculos marcados del pasado (K1) | F1–F3 |
| Esconderse | Celdas en sombra, bajo catres, taquillas | I+ |
| Lanzar objetos | Distracción por ruido (K5) | II+ |
| Cambio de época | `EraManager`: escena, LUT, paleta, audio, transiciones D5/D6 | I+ |
| Persecución humana | `NavigationAgent3D` + velocidad elástica; silbato → refuerzos; tácticos bloquean rutas | F1, F2 |
| Motivo del flashback | Objetivo por flashback; fracaso = escena de consecuencia + Continuar (G6) | F1–F3 |
| El Uniforme (Recuento) | PATRULLA → RECUENTO → DETECCIÓN → CAPTURA; recorre la prisión entera | I–IV |
| El Vigilante | Focos que barren; alarma que atrae a otros enemigos | II |
| Los Aislados | Reaccionan al ruido y convergen en grupo | II–III |
| El Condenado | Apariciones guionizadas + puzle de espejos | III |
| La Sentencia | Jefe-puzle con 3 mecanismos y coberturas destructibles | IV |
| Muertes | Animación por enemigo + pantalla «Continuar» | Todos |
| Guardado | **Manual** en paredes con marcas de conteo; al morir, cargar (K4, §7.2) | Todos |
| Armas | Punzón, pistola y escopeta, limitadas (§7.1, pendiente W1) | I (punzón), II (pistola), IV (escopeta) |
| Documentos e inventario clave | Según H3 | I+ |
| Menú cinematográfico | Recorrido de cámara por escenas reales del juego con distorsión temporal | Final |
| Opciones | Volumen por bus, sensibilidad, invertir Y, preajuste gráfico (L4), pantalla completa, reasignación básica de controles | I |

### 7.1. Sistema de armas [PROPUESTO — W1]

**Principio:** las armas **no convierten el juego en un shooter**. El presente sigue basándose en quedarse quieto y esconderse. Las armas son escasas, ruidosas y **no matan a las manifestaciones principales**: compran segundos. Sirven de verdad contra los jefes. **En el pasado no hay armas**: el ladrón huye, no pelea (refuerza D1).

| Arma | Dónde | Munición / usos | Efecto | Coste |
|---|---|---|---|---|
| **Punzón** (cuchillo carcelario improvisado) | Cap. I, en la celda o en un cadáver del Bloque A | 3 usos | **Defensa de agarre**: si un enemigo te atrapa y tienes el punzón, lo clavas y escapas en lugar de morir. Contra Los Aislados también sirve de golpe rápido | Gasta un uso; contra El Uniforme solo te libra una vez y se rompe |
| **Pistola** | Cap. II, en la funda de un guardia muerto (la lámina indica que los guardias la llevan en algunas zonas) | 6 balas + muy pocas cajas | Los Aislados caen (pueden morir). El Uniforme y El Vigilante quedan **aturdidos 3–4 s**, sin morir. La Sentencia: rompe cadenas o mecanismos en el jefe | **Cada disparo hace ruido**, atrae a todos los cercanos y puede activar la alarma |
| **Escopeta** | Cap. IV, antes de La Sentencia | 4–6 cartuchos | **Hace tambalearse a La Sentencia** y gana tiempo para activar los mecanismos; necesaria en la fase final | Recarga lenta; el ruido la enfurece |

**Control:** apuntar sobre el hombro (botón derecho del ratón o gatillo izquierdo), disparar o clavar, sin mira automática. La munición solo se ve al apuntar (HUD mínimo).

### 7.2. Sistema de guardado [PROPUESTO — W2, basado en K4]

- **Lugares de guardado**: paredes de celdas con **marcas de conteo de días**. Al interactuar, el protagonista raya una marca más con el alambre o el punzón, y queda guardado. Es un gesto propio que refuerza el tema de la condena perpetua.
- Guardar es **ilimitado** (sin consumibles), pero **solo en esas paredes**. Se colocan antes de cada peligro.
- **Al morir**: pantalla «CONTINUAR» → se carga la **última partida guardada**. No hay autoguardado en el presente.
- **3 ranuras** de guardado; «Cargar partida» y «Continuar» (la más reciente) en el menú principal.
- **Flashbacks**: no tienen paredes de guardado. Si fracasas, ves la escena de consecuencia y «Continuar» reinicia **el flashback desde su punto de control interno** (G6), sin volver a la última pared.
- **Autoguardado solo al empezar cada capítulo**, para no perder un capítulo entero.

---

## 8. Escenarios, personajes, enemigos y recursos [PROPUESTO]

### 8.1. Escenarios

| Escenario | Época | Capítulo |
|---|---|---|
| Celda + Bloque A (alas A y B) | Presente | I |
| Calles y callejones lluviosos, con la prisión en la colina | Pasado | I (F1) |
| Patio Central: pabellón monumental, torre, pasarelas, ascensor | Presente | II |
| Comisaría: sala de interrogatorio, oficinas, archivo | Pasado | II (F2) |
| Enfermería (escenario gore) y archivo de expedientes | Presente | III |
| Prisión en el pasado: patio cálido y pasillos activos | Pasado | III (F3) |
| Sala de ejecución / sectores inferiores | Presente | IV |
| Espacio final (megafonía, El Director) | Presente | Final |

### 8.2. Kit modular (Blender → Godot)

Muros de celda, barrotes, puertas (de barrotes, de seguridad, monumental), pasarelas, barandillas, escaleras, columnas, techos con fluorescentes, tuberías, catres, letrinas, taquillas, camillas, mesas, archivadores, megáfonos, estandartes, sábanas colgando, focos. En la ciudad: fachadas, farolas, escaleras de incendios, contenedores, cubos, verjas, patrulla y buzón.

### 8.3. Personajes

Protagonista (preso + civil), patrullero, táctico, guardia, interrogador, verdugo, alcaide (aparición), Aislados (2–3 variantes), El Uniforme, El Vigilante, El Condenado, La Sentencia, El Director (aparición) y cadáveres (poses estáticas y colgados).

### 8.4. Audio

Ver la lista del contexto §4.10, ampliada con silbatos, radio, megafonía, ganzúa, focos, Aislados, arrastre y mazo. Las voces dependen del equipo (`pendientes_equipo.md`).

### 8.5. Registro de recursos y licencias

Todo recurso externo y todo lo generado con IA se anota en **`recursos_y_creditos.md`** antes de incorporarse al proyecto.

---

## 9. Tráiler [POSPUESTO]

El creador decidió no producir el tráiler por ahora. El plan de la versión 0.1 (≈ 85 s; secuencia en motor grabada con Movie Maker y montada con FFmpeg; escenas cinemáticas identificadas) queda **archivado como referencia** para cuando se retome. La arquitectura del juego mantendrá cámaras y secuencias reutilizables para facilitarlo.

---

## 10. Arquitectura técnica en Godot 4 [PROPUESTO]

### 10.1. Carpetas

```
LifeTime Sentence/
├─ Materiales/                 # contexto, referencias, planeación y documentos de gestión (originales intactos)
├─ docs/                       # GUIA_EQUIPO.md, COMO_EJECUTAR.md, COMO_EXPORTAR.md, FUNCIONES_Y_LIMITACIONES.md
├─ fuentes_arte/               # .blend, texturas de origen, scripts de Blender (editables por el equipo)
│  ├─ blender/ personajes/ kit_prision/ ciudad/
│  └─ texturas_origen/
├─ juego/                      # proyecto Godot
│  ├─ project.godot
│  ├─ autoload/                # GameDirector, EraManager, AudioDirector, SaveSystem, Settings
│  ├─ render/                  # shaders PS1, LUT, RenderRig.tscn
│  ├─ componentes/             # Interactable, Door, Lock, Hideout, Checkpoint, CameraZone, MemoryTrigger...
│  ├─ jugador/                 # Player.tscn, cámara, animaciones
│  ├─ enemigos/                # uniforme/ vigilante/ aislados/ condenado/ sentencia/ policia/ ...
│  ├─ niveles/                 # cap1_bloque_a/ f1_calles/ cap2_patio/ f2_comisaria/ ...
│  ├─ kit/                     # piezas modulares .tscn listas para montar niveles
│  ├─ cinematicas/
│  ├─ ui/                      # menú cinematográfico, pausa, opciones, documentos, créditos, advertencias
│  ├─ datos/                   # .tres: enemigos, documentos, flashbacks
│  └─ assets/                  # modelos .glb, texturas, audio, fuentes
├─ herramientas/               # utilidades de instalación (plantillas de exportación de Windows)
├─ entregas/                   # LifetimeSentence.exe + LEEME; pruebas/ = builds de prueba
├─ .gitattributes              # reglas de Git LFS
└─ .gitignore                  # excluye .godot/ y exportaciones temporales
```

### 10.2. Sistemas

| Sistema | Implementación |
|---|---|
| GameDirector | Flujo de capítulos, puntos de control, muerte → Continuar, carga de escenas |
| SaveSystem | Autoguardado (capítulo, punto de control, objetos clave, documentos leídos) en `user://` |
| EraManager | Época activa → LUT, posproceso, entorno, perfil de movimiento; transiciones D5/D6 |
| AudioDirector | Buses Master/Ambiente/SFX/Voces/Música; reverb por zona; corte a silencio |
| RenderRig | Render interno 480 × 270 + escalado nítido + posproceso PS1 (cuantización, dithering, LUT, grano, viñeta, bandas) + preajustes Bajo/Alto |
| Componentes | Escenas pequeñas reutilizables con variables `@export` editables en el Inspector |
| Enemigos | Máquinas de estado legibles, con parámetros en recursos `.tres` |
| Cinemáticas | `AnimationPlayer` con cámaras, luces y eventos; saltables |
| Input | Acciones para teclado, ratón y mando; reasignables |

### 10.3. Rendimiento [CONFIRMADO C-15: prima lo artístico, debe poder probarse]

Render interno a baja resolución, luz horneada mayoritaria, niebla volumétrica solo en «Alto» e instancias para el pabellón.

**Renderizador elegido: Forward+** (bloque 1.1, 12-11-2026). Medición en el portátil del creador (Intel HD 520, ventana de 1280 × 720, imagen interna de 480 × 270, caja gris con 6 luces):

| Renderizador | Calidad BAJA: media / 1 % peor | Calidad ALTA: media / 1 % peor |
|---|---|---|
| **Forward+** (Vulkan) | 249 / 172 fps | 118 / 91 fps |
| Mobile (Vulkan) | 375 / 209 fps | 358 / 215 fps |
| Compatibility (OpenGL sobre ANGLE) | 267 / 170 fps | 199 / 118 fps |

Los tres superan de sobra los 60 fps en esta escena. Se elige Forward+ porque es el único con niebla volumétrica, que es lo que más acerca el aire frío y denso de las referencias, y porque no limita el número de luces por objeto. Los niveles definitivos pesarán más: hay que repetir la medición al cerrar los bloques 1.2 y 1.5. Si un equipo no admite Vulkan ni Direct3D 12, Godot pasa solo a Compatibility.

### 10.4. Repositorio [CONFIRMADO Q1/Q2]

**No se hacen commits durante el desarrollo.** Se prepararán `.gitignore` (estándar de Godot: `.godot/`, exportaciones) y `.gitattributes` (Git LFS para `.blend`, `.png`, `.jpg`, `.wav`, `.ogg`, `.glb`, `.ttf`/`.otf`). En la etapa 7 se entrega `docs/SUBIR_A_GITHUB.md` con la secuencia exacta: `git init`, `git lfs install`, bloques de `git add` + `git commit` por áreas (documentación, proyecto base, arte, audio, niveles…), `git remote add` y `git push`. **La ejecuta el equipo.** Copias de seguridad al cerrar cada etapa y cada bloque de la etapa 1: J4 (§11.0).

### 10.5. Exportación

Plantillas oficiales de Windows para 4.7.2 (autorizado, se registran en `herramientas_instaladas.md`). Se instalan en el bloque 1.1 de la etapa 1, para la exportación de prueba. La exportación final es de la etapa 7: un único `.exe` con `.pck` embebido, icono y metadatos.

---

## 11. Etapas de producción, hitos y criterios de cierre [CONFIRMADO: 7 etapas]

El plan se organiza en **7 etapas**, por decisión del creador (C-29, 12-11-2026). Sustituyen a las 11 etapas del plan v1.0; la equivalencia está en §11.8. Cada etapa termina en un **hito** (H1 a H7) con sus **criterios de cierre**. El apartado de cada etapa lleva su mismo número: la etapa 3 está en §11.3.

### 11.0. Resumen, hitos y forma de trabajo

| Etapa | Nombre | Qué se hace | Hito al cerrarla | Estado |
|---|---|---|---|---|
| **1** | **Preparación del juego** | Base en Godot con estética PS1, movimiento y cámara, kit de prisión y Bloque A, protagonista y animaciones, mecánicas del capítulo I, flashback «La huida» y El Uniforme. Cada elemento queda listo y verificado por separado | **H1** — piezas del capítulo I listas | **EN CURSO** (bloque 1.1 hecho, falta el visto bueno; 1.2 a 1.6 sin empezar) |
| **2** | **Capítulo I — Resiliencia** | Integrar lo preparado en un capítulo jugable de principio a fin: recorrido, transiciones, sonido y pulido | **H2** — capítulo I completo | Pendiente |
| **3** | **Capítulo II — Patio Central** | El capítulo y su flashback F2 «El interrogatorio» | **H3** — capítulo II completo *(punto de corte seguro)* | Pendiente |
| **4** | **Capítulo III — Enfermería** | El capítulo y su flashback F3 «El ingreso» | **H4** — capítulo III completo | Pendiente |
| **5** | **Capítulo IV — La Sentencia** | El capítulo, el encuentro con el jefe y la salida hacia el final | **H5** — capítulo IV completo | Pendiente |
| **6** | **Final de la demo** | Secuencia con El Director y créditos. La demo termina justo antes del dilema final (N11) | **H6** — demo completa de principio a fin | Pendiente |
| **7** | **Revisión y entrega** | Probar el recorrido completo, corregir errores, optimizar, exportación final para Windows y documentación de entrega | **H7** — demo entregable | Pendiente |

**Forma de trabajo en cada etapa:** explicar → consultar las decisiones importantes → implementar solo lo aprobado → ejecutar y verificar (capturas, recorridos automáticos, registros) → corregir → actualizar los documentos → mostrar el resultado → **pedir aprobación antes de pasar a la etapa siguiente**.

**Builds.** Al cerrar cada etapa se exporta una build de Windows que el creador prueba. La de la etapa 1 contiene las escenas de prueba de cada elemento; desde la etapa 2, el juego acumulado hasta ese capítulo.

**Copias de seguridad (J4).** Un `.zip` en `respaldos/` al cerrar cada etapa y, dentro de la etapa 1, al cerrar cada bloque.

**Documentos.** Al cerrar cada etapa o bloque se actualizan este archivo, `contexto_para_agentes.md`, `pendientes_equipo.md`, `recursos_y_creditos.md` y `herramientas_instaladas.md`.

### 11.1. Etapa 1 — Preparación del juego [HECHA — pendiente de aprobación]

**Objetivo:** dejar listos y verificados, cada uno en su escena de prueba, todos los elementos que necesita el capítulo I, **antes de montar el primer capítulo completo**. En esta etapa no se monta el recorrido: eso es la etapa 2.

La etapa agrupa las etapas 1 a 6 del plan v1.0, que pasan a ser sus seis **bloques** *(organización interna propuesta por el equipo)*:

| Bloque | Contenido | Entregable | Criterio de cierre del bloque | Estado (13-11-2026) |
|---|---|---|---|---|
| **1.1** | Base en Godot con estética PS1, movimiento y cámara | Proyecto Godot, tubería visual PS1, jugador provisional, cámara por zonas, caja gris de prueba, medición de rendimiento y exportación de prueba | Arranca sin errores; el creador aprueba el aspecto PS1 y la sensación de movimiento y cámara; la cámara no atraviesa paredes; funcionan teclado y mando; renderizador elegido con datos; el `.exe` de prueba arranca | **HECHO Y VERIFICADO.** Falta solo el visto bueno del creador (detalle abajo) |
| **1.2** | Kit de prisión y Bloque A | Piezas modulares (Blender → Godot); celda de Elías y Bloque A (alas A y B) compuestos e iluminados con el aspecto final | Coincide con las referencias; el equipo puede montar una sala con el kit siguiendo la guía | **Arte en Blender hecho** (`assets/kit/`, `assets/escenarios/bloque_a.blend`); falta exportarlo a Godot y la revisión del creador |
| **1.3** | Protagonista y animaciones | Elías Novak con sus dos vestuarios (preso N.º 4827 y civil) y las animaciones de la lista AN3 | Idéntico a las referencias; sin deslizamientos graves; sustituye al maniquí provisional | **Modelos y animaciones básicas hechos en Blender** (`assets/personajes/`, `assets/scripts/animaciones.py`): toda la lista AN3, armas y muertes K3. Falta la integración en Godot |
| **1.4** | Mecánicas del capítulo I | Interacción, ganzúa, escondites, documentos e inventario de objetos clave, punzón, muerte → «CONTINUAR» y guardado en marcas de conteo | Cada mecánica se completa sin instrucciones en su escena de prueba; guardar y cargar funciona | No iniciado |
| **1.5** | Flashback F1 «La huida» | Calles lluviosas, patrullero y táctico, persecución, motivo (esconder la carpeta), escena de consecuencia, cambio de época y transiciones D5 y D6 | Las dos épocas se distinguen al instante; la persecución se juega de principio a fin; el fracaso y su consecuencia se entienden | **Arte en Blender hecho** (callejón, ciudad, policías); falta la jugabilidad |
| **1.6** | El Uniforme | Modelo, animación a pocos fotogramas, mecánica «Recuento» y muerte | La regla se entiende sin tutorial; da miedo; la captura y «CONTINUAR» funcionan | **Modelo hecho**; faltan la animación y la mecánica |

**Puntos de control dentro de la etapa** *(propuesto)*. Cada bloque se muestra al creador al cerrarse. El bloque 1.1 necesita además su visto bueno expreso al aspecto PS1 y al movimiento, porque todo el arte posterior se construye encima. La aprobación formal de la etapa es el hito H1.

#### Estado del bloque 1.1 (revisión del 12-11-2026, 15:25)

El bloque está **construido y verificado en ejecución**. El proyecto se ha importado, se ha ejecutado con los tres renderizadores y se ha exportado a Windows, sin errores en la consola. Solo falta lo que depende del creador.

| # | Elemento | Estado | Cómo se verificó |
|---|---|---|---|
| 1 | Carpetas y archivos de git | **Hecho** | `.gitignore` y `.gitattributes` escritos. Sin `git init` ni commits (Q1) |
| 2 | Proyecto Godot, controles y ajustes | **Hecho y verificado** | El proyecto importa y arranca sin errores. La prueba automática envía una pulsación de la tecla `W` y un movimiento de la palanca izquierda, y el personaje avanza con ambos. Guardar y volver a leer un ajuste funciona |
| 3 | Tubería visual PS1 | **Hecho y verificado** | Los shaders compilan y dibujan en Forward+, Mobile y Compatibility. Capturas en `docs/capturas/bloque_1_1/` |
| 4 | Jugador provisional | **Hecho y verificado** | Prueba automática: anda, corre (unos 3 m/s de media en el tramo), se agacha, pasa bajo un hueco de 1,25 m, no puede levantarse debajo y se levanta al salir; de pie no cabe; las rejas y los muros lo detienen |
| 5 | Cámara por zonas | **Hecho y verificado** | 1.298 fotogramas comprobados durante el recorrido y **ninguno** con una pared entre la cámara y el punto que sigue. Las zonas cambian el encuadre (celda, pasillos y paso bajo) |
| 6 | Componentes de apoyo | **Hecho y verificado** | Luz fluorescente con sus estados; herramientas de prueba (teclas `F1` a `F12`, capturas, medición de fps y prueba de movimiento) |
| 7 | Caja gris de prueba | **Hecho** | `niveles/pruebas/caja_gris.tscn`: celda de 2 × 3 m, pasillo en L de 1,6 m, 7 frentes de reja, 6 luces, 4 zonas de cámara, 5 puntos de captura y una ruta de medición. 6 materiales y 3 mallas de reja provisionales |
| 8 | Capturas | **Hecho** | 10 capturas (5 puntos × 2 calidades) en `docs/capturas/bloque_1_1/` |
| 9 | Prueba de rendimiento | **Hecho** | Tabla en §10.3. Renderizador elegido: **Forward+** |
| 10 | Exportación de prueba | **Hecho y verificado** | Plantillas de Windows instaladas. `entregas/pruebas/LifetimeSentence_prueba.exe` (109 MB, un solo archivo) arranca, dibuja y se cierra sin errores |
| 11 | Documentación del bloque | **Hecho** | `docs/COMO_EJECUTAR.md` y primer borrador de `docs/GUIA_EQUIPO.md` |
| 12 | Copia de seguridad | **Hecho** | `respaldos/etapa1_bloque1_2026-11-12.zip` |
| 13 | Comentarios del código con la numeración antigua | **Hecho** | Corregidos |

**Añadido durante la verificación** (no estaba previsto y hacía falta):

- **El personaje se deshace en puntos cuando la cámara queda muy cerca.** En un pasillo de 1,6 m, al mirar hacia un lado, la pared empuja la cámara contra la espalda del personaje, y este tapaba la vista.
- **La cámara comprueba las paredes en el mismo fotograma en que gira**, en lugar de un paso de física después, para que nunca se vea a través de ellas.
- **Prueba automática de movimiento**, que recorre la escena con teclado y mando simulados y se puede repetir tras cada cambio.

**Falta para cerrar el bloque 1.1:**

| Qué | Quién |
|---|---|
| **Visto bueno al aspecto PS1 y a la sensación de movimiento y cámara** (tarea D-6): mirar las capturas y probar el `.exe` | Creador |
| Probar con un **mando físico** (tarea T-3). Hasta ahora solo se ha verificado con señales simuladas | Equipo |
| Los ajustes que pida el creador tras probarlo: intensidad de los efectos, luz, velocidades o encuadre | Claude |

**Instalado en este bloque:** entorno virtual de Python con Pillow 12.3.0 y numpy 2.2.6, y plantillas de exportación de Windows de Godot 4.7.2 (anotado en `herramientas_instaladas.md`).

**Limitaciones conocidas del bloque 1.1:**

- El maniquí, las texturas y la escena son provisionales: sirven para juzgar el aspecto general, no el arte final.
- La escena de prueba es pequeña. El rendimiento medido no garantiza el de los niveles definitivos.
- La caja gris está hecha con cajas CSG unidas en una sola malla, cómodas para prototipar. El kit del bloque 1.2 usará piezas separadas.
- Ninguna persona ha jugado todavía la escena: la sensación de control solo puede juzgarla el creador.

#### Criterios de cierre de la etapa 1 (hito H1)

- Los seis bloques cumplen su criterio de cierre.
- Cada elemento se puede probar por separado en una build de Windows con las escenas de prueba.
- No queda nada provisional que el capítulo I necesite: el maniquí, las texturas provisionales y la caja gris han sido sustituidos. Las voces pueden seguir con sustitutos (`pendientes_equipo.md`).
- Están decididos los detalles de esta etapa (§13): número de celda, paleta, minijuego de ganzúa, nombre de la hermana y nombre de la ciudad.
- `docs/GUIA_EQUIPO.md` explica cada componente creado; `recursos_y_creditos.md` y `herramientas_instaladas.md` están al día.
- Copia de seguridad hecha y **aprobación del creador**.

### 11.2. Etapa 2 — Capítulo I «Resiliencia» [HECHA — pendiente de aprobación]

**Objetivo:** integrar lo preparado en la etapa 1 en un capítulo jugable de principio a fin.

| Trabajo | Detalle |
|---|---|
| Recorrido completo | Montar el storyboard de §6 (pasos 1.1 a 1.9): celda → Bloque A → cartel → F1 → regreso → El Uniforme → puerta monumental → revelación del Patio Central |
| Transiciones | D5 y D6 integradas en el recorrido; cinemáticas de despertar, puerta monumental y revelación; rótulo «I — RESILIENCIA» (H5) |
| Sonido | Ambientes, efectos, firmas sonoras (AU4), mezcla y reverberación por zona; voces o sus sustitutos |
| Pulido | Iluminación final, niebla, lluvia y partículas; ritmo; colocación de los puntos de guardado; documentos del capítulo; dificultad media |
| Marco de juego *(propuesto)* | Advertencias iniciales (C-22), menú de pausa, opciones y primera versión del menú principal (C-21) |

**Criterios de cierre (hito H2):**

- El capítulo se juega de principio a fin sin ayuda externa y sin bloqueos.
- Guardar, cargar, morir y «CONTINUAR» funcionan en todo el recorrido.
- Las dos épocas se distinguen al instante y las transiciones funcionan dentro del recorrido.
- Sonido y mezcla completos, con voces grabadas o con sus sustitutos.
- Se cumple la lista de calidad del contexto absoluto (§11.10) en lo que toca al capítulo.
- Sin errores en consola; el rendimiento permite probar en el portátil del creador.
- Build de Windows del capítulo I, copia de seguridad, documentos al día y **aprobación del creador**.

### 11.3. Etapa 3 — Capítulo II «Patio Central» [HECHA — pendiente de aprobación]

**Requisito previo:** guion de F2, nombres y documentos aprobados (§4.5.3).

| Trabajo | Detalle |
|---|---|
| Patio Central | Pabellón monumental jugable: pasarelas, torre, ascensor antiguo y colgados (H4); grúa de cámara |
| Enemigos | El Vigilante (focos y alarma, K7), Los Aislados (ruido, K5) y El Uniforme recorriendo la zona |
| Mecánicas nuevas | Lanzar objetos, pistola (§7.1) y puzle de fusibles del ascensor |
| Flashback F2 «El interrogatorio» | Comisaría, interrogador, huida con ganzúa a contrarreloj (K6) y escena de consecuencia |

**Criterios de cierre (hito H3):**

- El capítulo II y F2 se juegan de principio a fin, enlazados con el capítulo I.
- El creador aprueba en capturas la sensación de megalofobia del Patio Central.
- Las reglas de El Vigilante y de Los Aislados se entienden sin tutorial.
- Build de Windows con los capítulos I y II, copia de seguridad, documentos al día y **aprobación del creador**.
- *Punto de corte seguro:* aquí existe una demo cerrada que se puede entregar si hace falta.

### 11.4. Etapa 4 — Capítulo III «Enfermería» [HECHA — pendiente de aprobación]

**Requisito previo:** guion de F3 y textos de los expedientes aprobados (§4.5.3).

| Trabajo | Detalle |
|---|---|
| Enfermería | Escenario gore, explícito pero estático (H4), y archivo de expedientes |
| El Condenado | Apariciones en espejos y puzle de espejos (K8) |
| Investigación | Documentos legibles y puzle de código con expedientes |
| Flashback F3 «El ingreso» | La prisión en el pasado, cálida y activa: guardias, traslado y el verdugo visto de lejos |

**Criterios de cierre (hito H4):**

- El capítulo III y F3 se juegan de principio a fin, enlazados con los anteriores.
- El escenario gore lleva su advertencia y respeta las reglas de contenido de la jam (§1.4).
- Los documentos revelan lo que les corresponde según §4.5.2.
- Build de Windows con los capítulos I a III, copia de seguridad, documentos al día y **aprobación del creador**.

### 11.5. Etapa 5 — Capítulo IV «La Sentencia» [HECHA — pendiente de aprobación]

| Trabajo | Detalle |
|---|---|
| Sala de ejecución | Escenario y sectores inferiores |
| La Sentencia | Jefe-puzle de 3 mecanismos, coberturas que se destruyen y atracción por el ruido (K9); diseño según L1 |
| Armas | Escopeta (§7.1) |
| Salida hacia el final | Huida y enlace con la secuencia final |

**Criterios de cierre (hito H5):**

- El encuentro con La Sentencia se supera sin tutorial con la dificultad media.
- La muerte y «CONTINUAR» funcionan durante el jefe.
- La salida enlaza con el punto donde empieza la secuencia final.
- Build de Windows con los capítulos I a IV, copia de seguridad, documentos al día y **aprobación del creador**.

### 11.6. Etapa 6 — Final de la demo [HECHA — pendiente de aprobación]

| Trabajo | Detalle |
|---|---|
| Secuencia con El Director | Megafonía del alcaide, silueta colosal y última revelación (§4.5.2) |
| Cierre | La demo termina **justo antes del dilema final**, sin elección (N11) → «FIN DE LA DEMO» |
| Créditos | Los dos nombres sobre secuencias del juego (C-20), tarjeta de IA y pantalla «Créditos y licencias» con las atribuciones y el aviso de Godot (Q3) |
| Menú principal *(propuesto)* | Versión final del menú cinematográfico, con todos los escenarios y enemigos (C-21) |

**Criterios de cierre (hito H6):**

- La demo se juega completa: menú → capítulos I a IV → final → créditos → menú.
- El final no muestra ni sugiere ninguna elección.
- Todas las atribuciones exigidas por las licencias y la declaración de IA aparecen en pantalla.
- Build de Windows de la demo completa, copia de seguridad, documentos al día y **aprobación del creador**.

### 11.7. Etapa 7 — Revisión y entrega [EN CURSO]

| Trabajo | Detalle |
|---|---|
| Pruebas | Recorrido completo con teclado y con mando, en el portátil y en otro PC, y con una persona ajena al proyecto (tareas T-1 a T-4 de `pendientes_equipo.md`) |
| Corrección | Errores, bloqueos y fallos de cámara, guardado o sonido |
| Optimización | Preajustes Bajo y Alto; tiempos de carga |
| Exportación final | Un único `.exe` para Windows, con icono y versión (C-02) |
| Documentación de entrega | `docs/COMO_EJECUTAR.md`, `docs/COMO_EXPORTAR.md`, `docs/GUIA_EQUIPO.md`, `docs/FUNCIONES_Y_LIMITACIONES.md` (qué es jugable y qué está guionizado), `CREDITOS.md`, `entregas/TEXTOS_ENTREGA.md` (descripción, controles, integrantes e instrucciones), declaración de IA y recursos, y `docs/SUBIR_A_GITHUB.md` |

**Criterios de cierre (hito H7):**

- El recorrido completo no tiene bloqueos ni errores en consola.
- El `.exe` final arranca en un PC que no tiene Godot instalado.
- La documentación de entrega está completa y los registros de recursos, IA y herramientas, al día.
- Copia de seguridad final y **aprobación del creador**.

### 11.8. Equivalencia con la numeración anterior (plan v1.0)

| Etapa del plan v1.0 | Ahora |
|---|---|
| 1 — Estructura, tubería PS1, movimiento y cámara | Etapa 1, bloque 1.1 |
| 2 — Kit modular de prisión y Bloque A | Etapa 1, bloque 1.2 |
| 3 — Protagonista y animaciones base | Etapa 1, bloque 1.3 |
| 4 — Mecánicas del capítulo I | Etapa 1, bloque 1.4 |
| 5 — F1 «La huida» | Etapa 1, bloque 1.5 |
| 6 — El Uniforme | Etapa 1, bloque 1.6 |
| 7 — Pulido del capítulo I | Etapa 2 |
| 8 — Capítulo II + F2 | Etapa 3 |
| 9 — Capítulo III + F3 | Etapa 4 |
| 10 — Capítulo IV + final | Etapas 5 y 6 |
| 11 — Pruebas, optimización, exportación y documentación | Etapa 7 |

| Hito del plan v1.0 | Ahora |
|---|---|
| — | **H1**: piezas del capítulo I listas (nuevo) |
| HITO 1: capítulo I completo y exportado | **H2** |
| HITO 2: demo cerrable (punto de corte seguro) | **H3** |
| HITO 3 | **H4** |
| HITO 4: demo completa | **H5** (capítulo IV) y **H6** (final y créditos) |
| — | **H7**: demo revisada y entregable (antes era el cierre de la etapa 11) |

### 11.9. Entrega a la jam

El cierre de entrega de la GUILD Game Jam 2026 es el **14-11-2026**. Por decisión del creador (J2), el plan no se recorta y él gestiona el plazo. Como apoyo, desde el cierre del bloque 1.1 el proyecto se puede exportar: si el equipo necesita una build, se genera con lo que exista en ese momento, y se adelantan los textos de entrega y la declaración de IA previstos en la etapa 7.

---

## 12. Riesgos técnicos, limitaciones y alternativas

| Riesgo | Impacto | Mitigación |
|---|---|---|
| **Plazo de la jam**: cierre de entrega el 14-11-2026; la demo amplia no cabe en ese plazo | Entregar algo incompleto en la jam | **Decisión del creador (J2):** mantener el plan de 4 capítulos; él gestiona el plazo. Mitigación técnica: proyecto exportable desde el cierre del bloque 1.1 de la etapa 1, para poder generar una build con lo que exista cuando se pida (§11.9) |
| Rondas de aprobación lentas frente al plazo | Días perdidos esperando | Aplicar por defecto las propuestas en decisiones no bloqueantes y avisar; reunir varias aprobaciones por mensaje |
| **IA no declarada o recursos sin licencia** (causas de descalificación) | Descalificación | `recursos_y_creditos.md` como declaración oficial; nada entra sin registro |
| Contenido sensible (gore, colgados, policía como monstruo) frente a las reglas de contenido | Rechazo del proyecto | Advertencias al inicio; los colgados se presentan como **ejecuciones institucionales**, no como autolesión; la crítica es al sistema corrupto de ficción (el giro del guardia que ayudaba la matiza); sin ataques a grupos reales |
| **Alcance muy grande** (demo de 45–60 min, roster casi completo) | No terminar | Siete etapas, cada una con su hito y su build; punto de corte seguro en H3; desarrollo posterior a la jam |
| **La etapa 1 es muy amplia** (seis bloques) | Arrastrar errores de base a todos los bloques | El bloque 1.1 ya está verificado en ejecución y tiene una prueba automática que se puede repetir; punto de control con el creador antes de construir arte definitivo; copia de seguridad por bloque |
| Intel HD 520 + 8 GB | Rendimiento bajo en niveles grandes con calidad ALTA | Medido en el bloque 1.1: 118 fps en ALTA y 249 en BAJA en la caja gris (§10.3). Hay margen, pero se vuelve a medir al cerrar los bloques 1.2 y 1.5. Preajustes gráficos, baja resolución interna, luz horneada |
| Personajes y animaciones hechos desde cero con IA | Calidad irregular frente a las referencias | Validar al protagonista en cuanto exista (etapa 1, bloque 1.3); estilo PS1 tolerante; base CC0 si una pieza no alcanza la calidad |
| Fidelidad a referencias generadas por IA (ChatGPT) | Las imágenes tienen luz «imposible» en tiempo real | Reproducir composición, paleta y materiales; aceptar diferencias de iluminación y documentarlas |
| Voces pendientes del equipo | Bloquear el pulido | Sustitutos provisionales; lista clara en `pendientes_equipo.md` |
| Cuota gratuita de Git LFS en GitHub | No poder subir todos los assets | Comprimir audio (OGG), revisar la cuota, alternativa de reparto de `.blend` |
| Gore y violencia | Clasificación y sensibilidad del público | Advertencias al inicio (C-22) |
| Licencias de terceros | Riesgo legal | Registro previo en `recursos_y_creditos.md`; nunca NC ni de pago |
| Parecido con otros juegos (verdugos, enfermeras, cabezas piramidales) | Problema creativo y legal | Diseños derivados de nuestras láminas; L1 |

---

## 13. Decisiones pendientes

**Bloqueantes para el plan:** ninguna.

**Para avanzar en la etapa 1:** el bloque 1.1 está construido y verificado (§11.1). Falta que el creador dé el visto bueno al aspecto PS1 y al movimiento; después empieza el bloque 1.2 (kit de prisión y Bloque A).

**Se decidirán en su etapa, con una propuesta del equipo:**

| Tema | Cuándo |
|---|---|
| Número de celda de Elías | Etapa 1, bloque 1.2 |
| Paleta exacta en valores hex | Etapa 1, bloque 1.2 |
| Diseño final del minijuego de ganzúa | Etapa 1, bloque 1.4 |
| Nombre de la hermana y guion de la escena de consecuencia de F1 | Etapa 1, bloque 1.5 |
| Nombre de la ciudad | Etapa 1, bloque 1.5 |
| Tipografía del logo y de la interfaz | Etapa 2 |
| Reparto del menú entre las etapas 2 (primera versión) y 6 (versión final) | Al empezar la etapa 2 (propuesto en §11.2 y §11.6) |
| Guiones de F2 y F3, documentos y guardia que ayudaba | Antes de la etapa 3 (§4.5.3) |
| Vídeo corto (J5) | Cuando el creador lo pida |

---

## Anexo A — Inventario de `Materiales/`

| Archivo | Contenido | Uso |
|---|---|---|
| `contexto_absoluto_del_proyecto.md` | Documento maestro | Base (no se modifica) |
| `1.png` | Moodboard «Dirección artística» (pabellón, paletas, hoja de personaje, materiales, arquitectura) | Dirección general; sin cruces (M5) |
| `1b065952-….png` | Pasarela junto a celdas frente al atrio monumental, figura en el puente | **Referencia principal del Patio Central** |
| `43f1fd2b-….png` | Callejón lluvioso, cartel «SE BUSCA», policías, patrulla, prisión en la colina | **Referencia principal de F1** |
| `94c42e3c-….png` | Collage del presente (El Uniforme, cadáver, figura con cuchilla, espejo, torre con megáfonos, celda) | Escenas del presente; sin símbolos ocultos (M5) |
| `ac3d34e8-….png` | Pasillo verde, guardia con hacha y llaves | Luz y claustrofobia del pasillo; el guardia con hacha **no** es El Uniforme |
| `c21d90ea-….png` | Prisión en el pasado, cálida, con policías y guardias | **Referencia de F3** |
| `Imagen de ChatGPT … 09_54_06 p.m-1.png` | **Lámina «Enemigos y jefes — Pasado»**: patrullero, táctico, guardia, interrogador, verdugo, alcaide; «Penitenciaría Estatal N.º 314», «EXP. N.º 4827» | Diseño de los humanos del pasado |
| `Imagen de ChatGPT … 09_54_07 p.m-2.png` | **Lámina «Enemigos y jefes — Presente»**: Aislados, Uniforme, Vigilante, Condenado, Sentencia, Director; Patio Central circular con estandarte de emblema, megáfono, espejo, expediente; rótulos «BLOQUE A — CELDAS A1–A16», «PATIO CENTRAL I»; iconos temáticos (esposas, mazo, torre, rejas, documento, siluetas) | Diseño de las manifestaciones y del Patio Central |

Las imágenes de referencia fueron **generadas con ChatGPT (OpenAI)**, según el nombre de archivo de las láminas. Se registra en `recursos_y_creditos.md`.

## Anexo B — Entorno técnico detectado (2026-11-12)

Windows 10 Pro 19045 · i5-6300U · 7,9 GB RAM · Intel HD 520 · pantalla de 1366 × 768 · Godot 4.7.2 (`Desktop\ARCADE\`), plantillas de exportación solo para Linux · Blender 5.2 · FFmpeg 9.0.2 · Python 3.10 · Git 2.54 · **Git LFS 3.7.1** · sin GitHub CLI. Detalle en `herramientas_instaladas.md`.

## Anexo C — Contradicciones

| # | Contradicción | Estado |
|---|---|---|
| 1 | Nombres de imágenes distintos e imágenes ausentes | **Resuelta**: láminas añadidas; las dos que faltan no son necesarias |
| 2 | Iconografía religiosa en las imágenes | **Resuelta** (M5: eliminarla) |
| 3 | La Sentencia literal en el collage | Aprobado «El Mazo», pero **nuevo conflicto con la lámina** → L1 |
| 4 | El Uniforme con hacha | **Resuelta**: la lámina lo confirma sin hacha |
| 5 | Tocado inconsistente de El Uniforme | **Resuelta**: gorra de plato (lámina) |
| 6 | El Uniforme vestido de guardia | **Resuelta**: uniforme policial azul marino (lámina) |
| 7 | Logo con sangre frente a logo institucional | Aprobado el institucional, pero las láminas insisten en el otro estilo → L2 |
| 8 | Apagón frente a fluorescentes encendidos | **Resuelta** (A4: energía de emergencia) |
| 9 | Cartel en español frente a policía estadounidense | **Resuelta** (N7: ciudad hispanohablante ficticia; las láminas rotulan «POLICÍA») |
| 10 | 60 s demasiado justos | **Resuelta** (X1: demo completa) |
| 11 | Tráiler | **Resuelta**: pospuesto |
| 12 | Look-dev antes que mecánicas | **Resuelta** en §11.1: el bloque 1.1 de la etapa 1 valida a la vez el aspecto y el movimiento |
| 13 | «Enfrentarse» frente a sin combate | Pendiente de S1 |
| 14 | Gore | **Resuelta** (A3: general contenido + un escenario gore) |
| 15 | «Saltar obstáculos» (D1) frente a «sin saltos» (P4) | **Nueva** → K1 |
| 16 | Número de preso «B-314» frente a «Penitenciaría Estatal N.º 314» | **Nueva** → H1 |
| 17 | Puerta de la celda entreabierta (contexto) frente a celda cerrada con puzle | **Resuelta** (M1) |
| 18 | «Sin texto» (N5) frente a documentos de la demo completa | **Resuelta** (H3: documentos legibles) |
| 15 → | (K1) | **Resuelta**: pasar por encima contextual, solo en el pasado |
| 16 → | (H1) | **Resuelta**: preso N.º 4827 |
| 19 | «Revelar todo» (G7) frente a «la demo no debe revelar la gran verdad» (contexto §2.1, §2.5) | **Nueva** → N11 |
| 20 | Armas (pistola, cuchillo, escopeta) frente a «indefensión total» en el presente (S1) y «sin combate» (contexto §11.7) | **Nueva** → W1 (diseño limitado §7.1) |
| 21 | Guardado manual (K4) frente a autoguardado propuesto en v0.2 | **Resuelta** a favor de K4; detalle en W2 |
| 22 | Demo amplia de 4 capítulos (G1) frente al plazo de la jam (21-11-2026) | **Nueva** → J2 |
| 23 | Dilema final «salvar a alguien / salvar al mundo» (G5) frente al original «salvarse / exponer las pruebas» (contexto §2.2) | Registrado como nueva dirección del creador; se detallará en la biblia narrativa (N13) |
