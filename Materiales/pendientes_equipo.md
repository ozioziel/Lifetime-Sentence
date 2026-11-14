# LIFETIME SENTENCE — PENDIENTES PARA EL EQUIPO

Tareas que necesitan **personas** (grabar, probar, decidir, entregar, gestionar cuentas). El equipo decide quién hace cada una. Aquí solo se listan y se explican.
Se actualiza al cerrar cada etapa y cada bloque de la etapa 1. Última actualización: **2026-11-13 (planeación v1.4)**.

**Dónde está el proyecto:** etapa 1 de 7 (Preparación del juego), en curso. El bloque 1.1 está construido y verificado: **falta vuestro visto bueno** (tarea D-6). Godot está en pausa por decisión del creador mientras se producen los assets en Blender (`assets/`): 18 personajes, 4 kits, 8 escenarios y 8 planos, **pendientes de vuestra revisión** (tarea D-8). Ver `planeacion.md` §11.1 y `assets/LEEME.md`.

**Equipo:** Oziel Rodman Ramos Torrez · Christopher Barea Salazar.
**Fechas clave:** **cierre de entrega de la GUILD Game Jam 2026: 14 de noviembre de 2026.** Exhibición y premiación presencial: 21 de noviembre de 2026.

**Cómo usar este documento:** cambia el estado (`PENDIENTE` → `EN CURSO` → `HECHO`), escribe quién lo hizo si os sirve y deja los archivos en la carpeta indicada.

---

## 1. Decisiones abiertas (bloquean el desarrollo)

| # | Tarea | Por qué | Cómo | Estado |
|---|---|---|---|---|
| D-1 | Responder las rondas de preguntas | Cerrar el plan | `planeacion.md` §3 | HECHO (plan v1.0) |
| D-2 | Fecha de cierre de entrega | — | Confirmada: **14-11-2026** | HECHO |
| D-3 | Dar el «sí» para empezar el desarrollo | Inicio del desarrollo | Dado el 12-11-2026 («puedes empezar») | HECHO |
| D-6 | Dar el **visto bueno al aspecto PS1 y al movimiento** del bloque 1.1 | Todo el arte posterior se construye sobre esa base | 1) Mirar las capturas de `docs/capturas/bloque_1_1/`. 2) Abrir `entregas/pruebas/LifetimeSentence_prueba.exe` y recorrer la escena (controles y teclas `F1` a `F4` en `docs/COMO_EJECUTAR.md`). 3) Decir qué cambiaríais: intensidad de los efectos, luz, velocidad, encuadre | **PENDIENTE — ya se puede hacer** |
| D-8 | Revisar los **personajes y escenarios de Blender** | Todo el arte del juego sale de ahí; cuanto antes se corrija, menos se rehace | Mirar `assets/renders/` (8 planos y 2 alineaciones de personajes) y abrir los `.blend` que queráis con Blender 5.2. Decir qué no se parece a las referencias o qué cambiaríais (caras, proporciones, luz, encuadres). **La cabeza PS1 nueva ya está aprobada** (13-11-2026); falta revisar el resto. Los renders de los planos todavía muestran la cabeza anterior | **EN CURSO** |
| D-10 | **Jugar la demo completa y aprobar las etapas 2 a 6** (o pedir cambios) | Cierra los hitos H2–H6 | `entregas/LifetimeSentence.exe`; qué es jugable y qué no, en `docs/FUNCIONES_Y_LIMITACIONES.md`; decisiones a revisar en su §4 | PENDIENTE |
| D-9 | Dar **nombre a la hermana** de Elías | Los textos de la demo dicen «tu hermana»; con un nombre se pueden personalizar la carta y el final | Un nombre; opcionalmente edad y aspecto | PENDIENTE (no bloquea) |
| D-7 | Confirmar el **reparto del menú** entre las etapas 2 y 6 | Es una propuesta del equipo, no una decisión vuestra | `planeacion.md` §11.2 y §11.6 | PENDIENTE (al empezar la etapa 2) |
| D-4 | Gestionar el **plazo de la jam** (qué se entrega el 14-11, prórroga u otra vía) | El creador decidió encargarse; el plan de 4 capítulos no se recorta | Si necesitáis una build para entregar, pedídsela a Claude y se exporta con lo que exista | PENDIENTE |
| D-5 | Confirmar la **hora exacta** del cierre y la **plataforma** de entrega | Entregar tarde descalifica | Canales oficiales de la jam | PENDIENTE |

## 2. Entrega en la Game Jam (exigido por el reglamento)

| # | Tarea | Detalle | Estado |
|---|---|---|---|
| E-1 | Subir la **versión jugable** (o enlace de descarga) a la plataforma oficial **antes del cierre (14-11-2026)** | El `.exe` lo prepara Claude en `entregas/`. Subirlo con margen: después del cierre no se puede modificar | PENDIENTE |
| E-2 | Rellenar **descripción breve, controles, lista de integrantes e instrucciones de ejecución** | Claude dejará los textos listos para copiar en `entregas/TEXTOS_ENTREGA.md` | PENDIENTE |
| E-3 | **Declarar el uso de IA y los recursos de terceros**, y los **materiales creados antes de la jam** | Obligatorio: la IA no declarada y los recursos sin licencia descalifican. Usar `recursos_y_creditos.md` como fuente | PENDIENTE |
| E-4 | Preparar un **vídeo corto** y un **repositorio accesible**, si la organización los pide | Vídeo: ver J5 en la planeación. Repositorio: comandos en `docs/SUBIR_A_GITHUB.md` (previstos para la etapa 7; se adelantan si los piden) | SI LO PIDEN |
| E-5 | Asistir a la **exhibición del 21-11-2026** | Si ganáis, al menos un integrante debe estar presente | PENDIENTE |
| E-6 | Mantener **copias de seguridad** | El reglamento las exige. Copiar la carpeta del proyecto (o los `.zip` de `respaldos/`, ver J4) a otro disco o a la nube | PENDIENTE |

## 3. Voces y audio grabado

Mientras no estén las grabaciones, el juego usa **sustitutos provisionales**. Cuando se entregue un archivo, se reemplaza sin tocar código.

**Formato:** WAV, 48 kHz, 24 bit (o 16 bit), **mono**. Habitación silenciosa, sin música ni eco. Micrófono a unos 20 cm. Tres tomas por línea con distinta intensidad. 1 s de silencio antes y después.
**Carpeta destino:** `fuentes_arte/audio_grabado/voces/` (ya existe).
**Cuándo hacen falta:** V-01 a V-06, V-09 y V-11 se usan en la etapa 1 (bloques 1.5 y 1.6) y se mezclan en la etapa 2. V-07 es de la etapa 3. V-08 es de las etapas 2 y 6. V-10 es de la etapa 3.
**Nombre de archivo:** `ID_toma.wav` (p. ej. `V-01_t2.wav`).
**Herramienta sugerida:** Audacity (gratuita, GPL). Si se instala, anotarlo en `herramientas_instaladas.md`.
**Prioridad para la jam (capítulo I):** V-01 a V-05, V-08 y V-09.

| ID | Personaje | Línea / sonido | Intención | Estado |
|---|---|---|---|---|
| V-01 | Policía patrullero | «¡Alto! ¡Policía!» | Grito corriendo, sin aliento | PENDIENTE |
| V-02 | Policía patrullero | «¡Por el callejón! ¡Córtenle el paso!» | Grito a compañeros | PENDIENTE |
| V-03 | Policía patrullero | «¡Al suelo! ¡Las manos donde las vea!» | Captura (escena de fracaso) | PENDIENTE |
| V-04 | Radio policial | «Central a unidades: sospechoso a pie, chaqueta granate, dirección norte…» | Voz plana de operadora u operador; se procesará como radio | PENDIENTE |
| V-05 | Radio policial | 4–6 frases sueltas de tráfico de radio (códigos, calles inventadas) | Fondo | PENDIENTE |
| V-06 | Policía táctico | «¡Unidad en posición! ¡Cierren la calle!» | Detrás de un escudo, voz amortiguada | PENDIENTE |
| V-07 | Interrogador | Las 7 líneas de `juego/datos/guion.gd` (`F2_INTERROGATORIO`) | Calmado y amenazante | PENDIENTE (guion escrito) |
| V-08 | Megafonía / El Director | Avisos de `MEGAFONIA_*` y las 10 líneas de `FINAL_DIRECTOR` en `juego/datos/guion.gd` | Voz cansada y distorsionada; El Director, grave y tranquilo | PENDIENTE (guion escrito) |
| V-09 | Protagonista | Respiraciones (calma, tensión, carrera), jadeos, quejidos, golpes, contener el aliento | Sin palabras | PENDIENTE |
| V-10 | Presos / Aislados | Murmullos, gemidos, respiración húmeda | Varias personas si es posible | PENDIENTE |
| V-11 | Hermana menor de Elías | 1–2 líneas para la escena de consecuencia de F1 (guion en la etapa 1, bloque 1.5) | Voz joven | PENDIENTE (guion por escribir) |

## 4. Pruebas

| # | Tarea | Cómo | Estado |
|---|---|---|---|
| T-1 | Probar la **build de cada hito** (H1 a H7) en el portátil principal | En H1 se prueban las escenas de prueba de cada elemento; desde H2, se juega de principio a fin. Anotar: fluidez, sitios donde os atascáis o no entendéis qué hacer, sustos que funcionan y que no | PENDIENTE — ya hay un `.exe` de prueba del bloque 1.1 |
| T-2 | Probar en **otro PC** (idealmente con gráfica dedicada) | Igual que T-1, más el preajuste «Alto» | PENDIENTE |
| T-3 | Probar con **mando** | Recorrido completo solo con mando. En el bloque 1.1 el mando solo se ha verificado con señales simuladas: hace falta probar uno físico | PENDIENTE — ya se puede hacer |
| T-4 | Prueba con **alguien que no conozca el proyecto** | Observar sin ayudar; anotar dudas y tiempos | PENDIENTE |

## 5. Repositorio y GitHub (etapa 7)

Claude **no hace commits**. En la etapa 7 (revisión y entrega) entregará `docs/SUBIR_A_GITHUB.md` con todos los comandos en orden; los ejecuta el equipo. Si la jam pide antes un repositorio, se puede adelantar.

| # | Tarea | Cómo | Estado |
|---|---|---|---|
| G-1 | Crear el **repositorio en GitHub** | github.com → New repository (privado o público, a decidir). Sin README inicial, para evitar conflictos | PENDIENTE |
| G-2 | Activar **Git LFS** en cada PC | Ya está instalado en el portátil principal (3.7.1). En cada PC, una sola vez: `git lfs install` | PENDIENTE |
| G-3 | Revisar la **cuota gratuita de Git LFS** | GitHub limita el almacenamiento y la transferencia de LFS en el plan gratuito; revisar en Settings → Billing antes de subir | PENDIENTE |
| G-4 | Dar acceso al resto del equipo | Settings → Collaborators | PENDIENTE |
| G-5 | Ejecutar la secuencia de `docs/SUBIR_A_GITHUB.md` | Cuando Claude la entregue | PENDIENTE |

## 6. Opcionales

| # | Tarea | Notas | Estado |
|---|---|---|---|
| O-1 | Animaciones de Mixamo | Solo si las CC0 o las hechas a mano no bastan. Requiere una cuenta de Adobe de un miembro y descarga manual; se registraría su licencia | NO NECESARIO por ahora |
| O-2 | Grabar ruidos reales (llaves, rejas, pasos sobre concreto, lluvia) | Ganan mucha autenticidad. Mismo formato que las voces, en `fuentes_arte/audio_grabado/sfx/` | OPCIONAL |
