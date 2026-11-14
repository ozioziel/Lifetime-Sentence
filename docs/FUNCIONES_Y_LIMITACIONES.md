# Lifetime Sentence — Funciones y limitaciones de la demo

*Versión 1.0 (14-11-2026). Documento de transparencia (planeación §5.3): qué es jugable, qué está guionizado y qué falta o se ha resuelto de otra forma.*

## 1. Recorrido completo

Menú cinematográfico → advertencias → **Cap. I «Resiliencia»** (Bloque A) → recuerdo **F1 «La huida»** → regreso al Bloque A, ala B → **Cap. II «Patio Central»** → recuerdo **F2 «El interrogatorio»** → **Cap. III «Enfermería»** → recuerdo **F3 «El ingreso»** → **Cap. IV «La Sentencia»** → **Final** con El Director → «FIN DE LA DEMO» → créditos → menú.

Duración aproximada de una primera partida: 35–50 minutos.

La prueba automática (`--prueba-demo`, ver `docs/GUIA_EQUIPO.md`) recorre la demo entera de principio a fin sin errores. Usa todos los objetos importantes, resuelve los puzles, pasa por todas las transiciones, prueba una muerte con «CONTINUAR» y termina en el menú. **No sustituye a jugarla**: la sensación, la dificultad y la claridad las tiene que juzgar una persona (tareas T-1 a T-4 de `pendientes_equipo.md`).

## 2. Qué es jugable (IA y sistemas reales)

| Sistema | Cómo funciona |
|---|---|
| Movimiento | Tercera persona relativa a la cámara. En el presente es lento, se agacha y tiene una carrera corta que se agota. En el pasado es ágil, no se agacha y puede pasar por encima de obstáculos y derribarlos. Sin salto (P4) |
| Cámara | Sobre el hombro, con zonas de encuadre por espacio y sin atravesar paredes |
| Interacción | Punto + botón (S4). Leer, coger, abrir, esconderse, accionar, guardar |
| Ganzúa (K2/K6) | Minijuego con el ratón, el teclado o el mando. En F2 va a contrarreloj |
| Guardado (K4/W2) | Paredes con marcas de conteo y 3 ranuras. Autoguardado al empezar cada capítulo y puntos de control dentro de los recuerdos |
| Muerte (K3/C-26) | Animación emparejada propia de cada enemigo → negro → «CONTINUAR» |
| El Uniforme (E2) | Patrulla con llaves. El Recuento es real: si te mueves dentro de su mirada mientras cuenta, te descubre; quieto, no. Persigue, saca de la taquilla al jugador si lo ha visto esconderse y lo agarra del cuello |
| Escondites (S2) | Taquillas con vista entre las rendijas |
| El Vigilante (K7) | Foco que barre la pasarela desde el anillo de la torre. Más de un segundo dentro del haz → alarma, luces rojas, megafonía y aparición de El Uniforme |
| Los Aislados (K5) | Ciegos. Oyen los pasos (andar, correr, agachado) y convergen en grupo hacia los ruidos. Las botellas los distraen. La pistola y el punzón los matan |
| Policía (E1) | Persecución de goma elástica, silbato, refuerzos por delante, tácticos que cortan calles y linternas. Los obstáculos saltados o derribados los frenan |
| Guardias (F3) | Conos de visión. El escolta de la fila se distrae a ratos |
| El Condenado (K8) | Solo se ve en los espejos (reflejo real en tiempo real), detrás del jugador. Ataca al tercer error del puzle |
| La Sentencia (K9) | Va hacia el ruido (los mecanismos hacen ruido), destroza coberturas y golpea. La escopeta la hace tambalearse |
| Armas (§7.1) | Punzón (3 usos, libra de un agarre). Pistola (6 + caja: aturde a las manifestaciones y mata a Los Aislados). Escopeta (2 + 4: hace tambalearse a La Sentencia). Sin mira automática; la munición solo se ve al apuntar. Sin armas en el pasado |
| Puzles | Ganzúas, fusibles del ascensor, espejos en orden (pista en el registro de defunciones) y teclado de código (pista en la nota del guardia) |
| Documentos (H3) | 10 documentos legibles, que se pueden releer desde la pausa |
| Épocas (D4–D6) | Presente frío y pasado ámbar. D5: el sonido entra antes que la imagen y se re-dithera. D6: golpe metálico y silencio absoluto |
| Opciones | Volumen general y por bus, subtítulos, calidad Baja/Alta, pantalla completa, sensibilidad, invertir Y, agacharse alterno, vibración y reasignación de teclas |

## 3. Qué está guionizado (cinemáticas, todas saltables manteniendo Interactuar)

- **Cap. I**: despertar, primer plano del cartel, regreso de F1, aparición de El Uniforme y apertura de la puerta monumental.
- **F1**: el «¡Alto!» inicial, la verja final y la escena de fracaso.
- **Cap. II**: revelación con grúa, los colgados, la bajada en el ascensor y la nota.
- **F2**: el interrogatorio completo y la salida.
- **Cap. III**: llegada del ascensor, primer plano del gore y de la fotografía.
- **F3**: la llegada de la fila y el guardia de la placa 31. Después, la fila avanza sola: su recorrido está guionizado, la vigilancia es real.
- **Cap. IV**: presentación de La Sentencia, caída del rastrillo y huida final.
- **Final**: toda la escena con El Director (aparición, sin combate, G2).
- **Menú y créditos**: recorridos de cámara por escenarios reales del juego.

## 4. Decisiones de implementación que se apartan de la planeación (para aprobar)

| Tema | Planeación | Implementación | Motivo |
|---|---|---|---|
| Muerte en el presente | §7.2: se carga la última partida guardada | Se vuelve al punto más reciente entre la última pared usada, el **inicio del tramo** actual y el punto de control del recuerdo. En disco solo se escribe la pared, el inicio de capítulo y el recuerdo | Evitar repetir tramos largos en una demo de jam. Se puede volver al criterio estricto en `autoload/juego.gd` (`registrar_nivel`) |
| Ala B del Bloque A | Ala distinta | Mismo pasillo de Blender con otra iluminación, taquillas, más cadáveres y El Uniforme | Tiempo |
| Puertas a otras zonas | — | Puertas con fundido a negro (como en los survival horror de PS1): escalera de servicio, oficinas de la comisaría, archivo, despachos | Los escenarios de Blender son salas cerradas; así no hace falta abrir huecos |
| El Vigilante | Recorre las pasarelas | Da vueltas por el anillo de la torre y barre con el foco la pasarela de la planta 10 | Encaja con la geometría del patio y se lee mejor |
| Escondites | Celdas en sombra, catres y taquillas | Solo taquillas | Las celdas del Bloque A tienen las rejas modeladas cerradas |
| El Condenado | Puzle de espejos | Cubrir con sábanas los 4 espejos en el orden en que murieron los testigos | Usa la pista del registro de defunciones y da sentido narrativo |
| Puzle de código | Expedientes | Caja de seguridad con las celdas de los 4 testigos (2915) | Cruza dos documentos (registro + nota del guardia) |
| Salida del Cap. IV | — | Puerta de los «sectores inferiores» que se abre por tercios con cada mecanismo | Da progreso visible al jefe |
| Nombres | Hermana sin nombre (D-9) y guardia «G., placa 31» | Se usan «tu hermana» y «placa 31» en todos los textos | Pendiente de decisión del equipo |
| Voces | Grabadas por el equipo (V-01 a V-11) | Subtítulos en todas las líneas; la «voz» de cada personaje es su subtítulo | Faltan las grabaciones |
| Celda de Elías | Escenario de Blender aprobado | Versión **solo para el juego** (`bloque_a_juego`) con la puerta como pieza aparte y cerrada, el primer tramo sin solaparse con la celda y el extremo del pasillo cerrado | En el escenario original la celda se solapaba con la primera celda del pasillo, la reja estaba entornada y el extremo del pasillo quedaba abierto. El plano aprobado no cambia |

## 5. Limitaciones conocidas

- **Sin voces grabadas**: todo el diálogo está subtitulado. Las voces de V-01 a V-11 se pueden añadir sin tocar la lógica (ver `docs/GUIA_EQUIPO.md` §6).
- **Sonido sintetizado**: los 125 efectos y ambientes se generan por código. Son originales y coherentes, pero sencillos comparados con grabaciones reales (opcional O-2).
- **Rendimiento**: en el portátil del creador se mantienen 60 fps en calidad Baja en todos los niveles. En calidad Alta, el Patio Central baja a unos 30 fps.
- **Cadáveres y figurantes** sin colisión: se pueden atravesar.
- **El mando** solo se ha probado con señales simuladas; falta probar uno físico (T-3).
- **Icono del `.exe`**: el ejecutable no muestra el icono en el Explorador porque haría falta `rcedit` (no instalado; ver `docs/COMO_EXPORTAR.md`). La ventana del juego sí lo muestra.
- **Dificultad**: está ajustada a «media» (C-18) solo con la prueba automática. Falta ajustarla jugando.
