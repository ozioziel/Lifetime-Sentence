# CONTEXTO ABSOLUTO DEL PROYECTO

# LIFETIME SENTENCE

**Documento maestro de contexto, concepto, dirección artística, narrativa, enemigos, jugabilidad y propuesta de micro-demo.**

- **Proyecto:** Lifetime Sentence.
- **Origen:** Game Jam con la temática **«Al otro lado de la ley»** y el enfoque **«punto de vista del ladrón»**.
- **Género:** terror psicológico, misterio, supervivencia, sigilo, persecuciones y exploración narrativa.
- **Referencias de enfoque:** terror psicológico de *Silent Hill* (manifestaciones simbólicas de culpa, sin copiar criaturas), supervivencia retro/PS1, cine de terror atmosférico y arquitectura brutalista.
- **Prioridad de presentación:** lograr una pieza audiovisual/tráiler especialmente artística e impactante. No se ha confirmado aquí el reglamento de evaluación de la Game Jam; esta prioridad procede de la intención del creador.
- **Objetivo de prueba inmediata:** que un agente de IA construya una **micro-demo de alrededor de un minuto** como demostración de capacidad artística y técnica, antes de comprometerse con el juego completo.
- **Estado:** preproducción conceptual; aún no se ha elegido motor, pipeline, repositorio, equipo, calendario técnico ni plataforma objetivo.
- **Idioma de este documento:** español. El nombre del juego es en inglés.

> **Cómo utilizar este documento:** contiene tanto decisiones expresamente adoptadas como ideas propuestas durante la conversación. Las etiquetas **[DECIDIDO]**, **[PROPUESTO]**, **[PENDIENTE]** y **[DESCARTADO]** evitan convertir sugerencias preliminares en requisitos supuestamente cerrados. Para la primera micro-demo, priorizar los elementos marcados como DECIDIDO y el apartado específico de demo; no intentar construir todo el juego.

---

## 0. RESUMEN EJECUTIVO — UNA PÁGINA

**Lifetime Sentence** es un videojuego de terror psicológico protagonizado por un ladrón que despierta en una prisión casi desierta, con cadáveres y señales de una masacre cuyo origen desconoce. Debe escapar mientras descubre pruebas y vive fragmentos jugables del pasado: el robo, una persecución policial, su captura, las autoridades corruptas y las decisiones que terminaron en su encarcelamiento.

Hay **dos realidades**: **PASADO** (mundo humano, relativamente verosímil, con policías, guardias y autoridades reales) y **PRESENTE** (una prisión fría, solitaria, opresiva y cada vez más distorsionada, con entidades que manifiestan culpa, miedo, castigo, autoridad y recuerdos). Una figura humana que persiguió al protagonista en el pasado puede reaparecer como un monstruo simbólico en el presente, **con una dinámica jugable distinta**, no solo otro modelo visual.

El gran golpe artístico consiste en alternar **claustrofobia** —celdas pequeñas, corredores cerrados, techos bajos y poca visibilidad— con **un único gran espacio interior de escala sobrecogedora** después de salir del bloque de celdas. Esta zona central, casi surrealista, provoca **megalofobia** mediante niveles y niveles de celdas, pasarelas, vacío vertical, luz escasa y una persona diminuta. **No toda la prisión debe ser gigantesca**, ni debe verse como una ciudad futurista.

**Estilo visual:** **3D low-poly retro PS1 con composición artística y puesta en escena cinematográfica**, texturas de baja resolución, niebla y grano, luces industriales frías, materiales viejos, concreto húmedo, rejas, óxido y ausencia de tecnología futurista. La cárcel debe dar miedo por **abandono, frío, silencio, soledad y encierro**, no por exhibir arquitectura de ciencia ficción.

**Enemigos conceptuales:** en el pasado, policías, policías tácticos, guardias penitenciarios, un interrogador, un verdugo penitenciario y el alcaide corrupto; en el presente, Los Aislados, El Uniforme, El Vigilante, El Condenado, La Sentencia y El Director. Son propuestas de roster para el juego completo, **no obligación de implementarlos todos**.

**Micro-demo inicial (~60 s):** despertar en celda del presente → pasillo claustrofóbico y pista → flashback de persecución policial **fuera de la prisión**, en callejón urbano lluvioso → vuelta al presente con manifestación de El Uniforme → revelación del enorme pabellón central → insinuación de La Sentencia → título. Debe ser ante todo una **prueba artística pequeña**, con movimiento/interacción/encuentro simples y varias escenas guionizadas si ayuda a mantener calidad.

---

## 1. ORIGEN DE LA IDEA Y TÍTULO

### 1.1. Premisa compartida por el creador [DECIDIDO]

La primera idea nació de esta combinación:

- Temática obligatoria: **«Al otro lado de la ley»**.
- Perspectiva narrativa: **«punto de vista del ladrón»**.
- Un ladrón está preso, pero no se sabe qué ocurrió antes.
- Algo terrible ha sucedido en la cárcel: hay numerosas personas muertas, incluidos presos y posiblemente guardias.
- El objetivo superficial es salir con vida.
- Debe haber persecuciones, terror y fragmentos que alternen presente y pasado para revelar cómo llegó allí.
- El final podría revelar que el protagonista tuvo alguna relación con la tragedia.
- Idea temática clave: **el criminal descubre que quienes debían hacer cumplir la ley son peores que él**.

### 1.2. Nombre [DECIDIDO]

**LIFETIME SENTENCE**.

Es el nombre elegido expresamente por el creador. Debe sustituir a todos los nombres provisionales anteriores.

Nombres que se exploraron y **no** son el título definitivo: «Sin Condena», «Culpable», «Lockdown», «Pabellón 0», «Veredicto», «Blackout», «Deadlock», «Breach», «Containment», «Shutdown», «Locked In», «Solitary», «No Parole», «Cellblock», «Inmate», «The Warden», «Last Shift», «Final Count», «False Verdict», «Afterlock», «Override» y «Red Protocol». El creador dijo que le gustaba especialmente **Lockdown**, pero **finalmente eligió Lifetime Sentence**.

### 1.3. Concepto expresado en una frase [PROPUESTO / CONSISTENTE]

> «En el pasado, un ladrón huye de la ley. En el presente, huye de la forma que su culpa le ha dado a la justicia».

Otras formulaciones útiles, sin fijarlas como guion literal:

> «No es solo una cárcel: es una estructura gigantesca que hace ver al protagonista como nada».

> «En el pasado sabes de qué huyes; en el presente no».

> «No luchas para ganar: luchas por conseguir tiempo y sobrevivir».

### 1.4. Tono argumental [DECIDIDO / PROPUESTO]

Terror serio y adulto; opresión institucional; culpa moral; ambigüedad; descubrimientos graduales; soledad. El protagonista **no debe resultar completamente inocente**. Debe haber tensión entre sus crímenes, la violencia del sistema y su responsabilidad real o percibida.

---

## 2. NARRATIVA COMPLETA — VISIÓN DE JUEGO ENTERO

> **Importante:** esta es la línea narrativa desarrollada en la conversación y aceptada como base. Los detalles concretos de causa-efecto, fechas, relaciones y final podrán ajustarse posteriormente. El **tráiler y la micro-demo NO deben revelar la gran verdad**.

### 2.1. Premisa [DECIDIDO]

El protagonista, un ladrón, despierta en su celda durante o después de un apagón. La puerta está abierta. La prisión está anormalmente silenciosa; no hay guardias en sus puestos. Los pasillos contienen cadáveres y señales de violencia. No recuerda lo sucedido recientemente ni cuánto tiempo estuvo inconsciente. Recuerda de manera incompleta que fue detenido después de un robo.

Encuentra llaves, fotografías, expedientes, grabaciones, cámaras y objetos que despiertan **flashbacks jugables**. Cada nuevo recuerdo lo acerca a la verdad, mientras la prisión del presente se transforma en un territorio psicológico de miedo y culpa.

### 2.2. Revelación progresiva sugerida [PROPUESTO]

1. El protagonista cometió un robo real, no inventado.
2. Lo robado podría incluir **documentos/pruebas comprometedoras** sobre autoridades y sistema judicial/penitenciario. La persecución no buscaba solo recuperar dinero: también ocultar información.
3. La prisión era utilizada para **silenciar, ejecutar o hacer desaparecer a prisioneros/testigos incómodos**, y autoridades dirigían encubrimientos.
4. Hubo un intento previo de fuga o acción del protagonista que **desencadenó involuntariamente un protocolo de ejecución/represión masiva**.
5. Por ello el protagonista **tuvo alguna responsabilidad** en la tragedia, aunque la intención criminal y responsabilidad directa del sistema fueran distintas.
6. Se puede revelar que un guardia que parecía amenazador estaba intentando **impedir la masacre o preservar pruebas**, en vez de asesinarlo. Esto reinterpreta retrospectivamente algunas persecuciones.
7. Salir de la prisión quizá requiere elegir entre **salvarse** o **exponer las pruebas**, incluida su propia culpabilidad.

No asumir que todos estos giros deban estar expuestos desde el principio: son secretos narrativos.

### 2.3. Actos del juego completo [PROPUESTO]

#### Acto I — Despertar / Escape

- La celda está abierta.
- Aprendizaje de movimiento, exploración e interacción.
- Pasillos oscuros, cadáveres y pruebas de masacre.
- Primer sonido extraño, visión lejana o persecución.
- Primer documento/fotografía que empieza a desbloquear recuerdos.

#### Acto II — El Crimen / Los Recuerdos

- Flashbacks de la vida anterior al encarcelamiento.
- Robo, persecución policial por callejones, escape de agentes y eventual captura.
- Contradicciones entre lo que recuerda y lo que muestran las pruebas.
- Descubrimiento de que fue perseguido por algo más que un robo normal.

#### Acto III — Los Verdaderos Criminales

- Evidencias de corrupción, abuso de poder y asesinatos encubiertos por autoridades.
- El entorno del presente manifiesta ideologías y culpa en formas monstruosas.
- El alcaide y la estructura de control se vuelven centrales.
- La masacre está ligada tanto a acciones institucionales como a una decisión previa del protagonista.

#### Acto IV — La Condena / Salida

- Llegada al núcleo de control o archivo.
- Confrontación moral y encuentro con la verdad.
- Posible elección final: huir sin revelar la verdad o exponerlo todo, aun incriminándose.
- Los finales alternativos son propuesta; **no forman parte de la primera micro-demo**.

### 2.4. Ambigüedad psicológica [DECIDIDO]

El creador aprobó un enfoque **similar en principio a Silent Hill**: los enemigos del presente **sí son manifestaciones simbólicas de culpa**. No se deben tratar únicamente como policías reales con una skin horror. Su presencia puede ser ambigua: representación de traumas, recuerdos, percepción distorsionada o fenómenos inexplicables. No es necesario explicar de inmediato si tienen naturaleza física/sobrenatural.

### 2.5. Regla de spoilers

En el tráiler: insinuar el robo, el encierro, la corrupción y el paralelismo de los enemigos, pero **NO** revelar claramente la relación del protagonista con la masacre, quién intentaba salvarlo ni cómo acaba la historia.

---

## 3. DOS LÍNEAS TEMPORALES / DOS MUNDOS

### 3.1. PASADO [DECIDIDO]

**Función:** mostrar cómo llegamos a prisión y a quién conocimos antes de que su recuerdo se deformara. **El pasado NO ocurre únicamente dentro de la cárcel**: la escena de referencia expresamente solicitada es una **persecución urbana bajo la lluvia**, antes del encarcelamiento.

- Contextos posibles: ciudad nocturna, callejones estrechos, calles lluviosas, edificios antiguos, comisaría/interrogatorios y prisión funcional.
- El mundo es más humano, reconocible y proporcionado.
- Policías y autoridades son personas físicas, aun si actúan de manera violenta/corrupta.
- Más movimiento, urgencia, adrenalina, persecuciones y obstáculos.
- Temperatura cromática: luces urbanas amarillas/ámbar, sodio, grises sucios; lluvia que refleja ocasionalmente rojo/azul policial (sin exageración futurista).
- Coherencia visual: **sigue siendo low-poly PS1**, con texturas dither/pixeladas y composición cinematográfica. No convertir el pasado en hiperrealismo ni mundo alegre.
- El protagonista puede tener **ropa civil oscura** antes del encarcelamiento. En recuerdos que ocurran ya dentro de prisión, usar uniforme de preso según cronología.

**Ejemplo de escena:** robo ya cometido; ladrón corre en un callejón mojado mientras dos policías humanos lo persiguen, iluminados por farolas y reflejos de luces policiales. Es reconocible, peligroso y terrenal.

### 3.2. PRESENTE [DECIDIDO]

**Función:** supervivencia, investigación, horror de la culpa, miedo a lo desconocido, manifestaciones y revelaciones del misterio.

- Prisión vieja, fría, casi vacía, muerta y deteriorada.
- Cadáveres, abandono y falta de actividad humana normal.
- Enemigos psicológicos, no solo humanos con efectos especiales.
- Mucho silencio y sonido ambiental.
- Alternancia entre zonas **claustrofóbicas** y un pabellón central interior **monumental**.
- Dominio de azul/gris frío, verde enfermizo, concreto apagado, negro, rojo de emergencia solo en momentos de peligro.
- Protagonista con **uniforme naranja de preso deteriorado**, cabello oscuro low-poly, postura cansada/vulnerable y silueta visible en tercera persona.

### 3.3. Contraste dramático

| Dimensión | PASADO | PRESENTE |
|---|---|---|
| Enemigo | Policía/guardia/verdugo humano | Manifestación distorsionada de ese referente |
| Pregunta | «¿Cómo me atraparon y qué hice?» | «¿Qué ocurrió y de qué soy culpable?» |
| Ritmo | Huida ágil / riesgo directo | Exploración lenta / tensión / sigilo |
| Lugares | Ciudad lluviosa, calles, comisaría, cárcel operativa | Prisión abandonada, celdas, pasillos, cámaras, gran pabellón |
| Estética | Ámbar sucio, amarillos apagados, grises | Azul frío, verde enfermo, negro, rojo de alarma |
| Amenaza | Instituciones y personas reales | Culpa, vigilancia, castigo, institución como imagen mental |
| Persecución | Policía convencional con conductas reconocibles | Criatura con reglas extrañas que hay que aprender |
| Audio | Radio policial, voces, tránsito lejano, lluvia | Ecos vacíos, metal, respiración, llaves, silencio |

### 3.4. Regla de diseño central [DECIDIDO]

**Un mismo símbolo/personaje humano del pasado puede tener un correlato monstruoso en el presente, y su mecánica jugable debe cambiar.** Ejemplo concreto elegido como dirección:

- **Pasado:** policía que corre tras el ladrón; se huye mediante velocidad, giros, rutas y obstáculos.
- **Presente:** **El Uniforme**, manifestación alta, rostro indescifrable, movimientos/patrones anormales; obliga a aprender una forma de evitarlo diferente, como romper contacto visual, esconderse o incluso permanecer inmóvil mientras observa (esto último es una posibilidad aún por validar).

Otra pareja:

- **Pasado:** verdugo penitenciario humano asociado al castigo.
- **Presente:** **La Sentencia**, entidad masiva, deformada, con arma de ejecución similar a un hacha, pero **no literal, no obvia a primera vista**: silueta y objeto deben sugerir castigo de manera perturbadora, no ser cosplay convencional de verdugo.

---

## 4. DIRECCIÓN ARTÍSTICA — CRITERIOS INNEGOCIABLES

### 4.1. Corrección expresa sobre imágenes tempranas [DECIDIDO]

La primera imagen conceptual de la megacárcel fue criticada expresamente por el creador porque:

- **Se veía demasiado futurista.**
- **No se veía suficientemente retro ni low-poly.**
- La prisión parecía un exterior/megaestructura tecnológica, más que una cárcel cerrada y aterradora.
- Le faltaban **claustrofobia, soledad, frío y miedo**.

**[DESCARTADO]**: rascacielos carcelarios futuristas, ciencia ficción espectacular, arquitectura de ciudad cyberpunk, paneles tecnológicos, alta fidelidad hiperrealista sin carácter, neones abundantes, grandes vacíos abiertos como si fueran exteriores de ciencia ficción.

**[DECIDIDO]**: la dirección corregida del moodboard PS1 de prisión vieja, encierro, luz fría, brutalismo, decadencia y gran pabellón **interior** sí le gustó al creador.

### 4.2. Pilar visual [DECIDIDO]

Sentimientos buscados al observar una sola imagen:

1. **Opresión**: todo limita el movimiento.
2. **Claustrofobia**: espacios cerrados, bajos, húmedos, pasillos que asfixian.
3. **Megalofobia**: en una zona concreta, estructura de proporciones intimidantes.
4. **Soledad**: ausencia de vida normal; el protagonista es pequeño y está desamparado.
5. **Frío**: sensación térmica transmitida mediante luz, niebla, reflejos, sonido y materiales.
6. **Insignificancia**: el prisionero se reduce ante la institución.
7. **Decadencia**: el sistema y edificio parecen podridos/desgastados.
8. **Miedo institucional**: vigilancia, normas, autoridad sin rostro.
9. **Ambigüedad surreal**: arquitectura algo imposible, pero arraigada en una prisión real y antigua.

### 4.3. Estilo de renderizado [DECIDIDO]

**3D estilizado low-poly / PS1, con composición artística y luz cinematográfica.**

- Geometría intencionalmente simple, ángulos visibles y siluetas contundentes.
- Texturas de baja resolución y pixelado moderado.
- Dithering, grano, profundidad atmosférica y posible ligera inestabilidad de render estilo consola antigua.
- Materiales reconocibles: concreto, hierro, pintura, ladrillo, humedad.
- Buenas composiciones, encuadres y contraste por iluminación, sin convertirlo en fotorealismo.
- Distorsión cromática o aberración cromática leve, usada con moderación.
- Efectos de niebla/partículas **solo si rendimiento y tiempo lo permiten**.
- Evitar estética caricaturesca, demasiado limpia o fantasía futurista.

**Preferencias artísticas expresadas:**

- Se evaluaron A: realismo sucio, B: estilizado oscuro de composición artística, C: retro PSX artístico.
- El creador rechazó A como realismo pesado, pero pidió **suficiente legibilidad y calidad visual**; aprobó B en cuanto a composición artística y C en cuanto a low-poly retro.
- Por tanto, la mezcla final es **B + C**, con credibilidad espacial/material sin perseguir fotorrealismo.

### 4.4. Arquitectura y escala [DECIDIDO]

**El mapa no debe ser entero gigantesco.** La progresión espacial prevista:

- Empezar dentro de una celda minúscula.
- Continuar por pasillos angostos de celdas, techos bajos, recovecos y rejas.
- **Después de salir del bloque de celdas**, revelar una zona central gigantesca **interior y cerrada**: una nave/atrio/pabellón que hace sentir megalofobia.
- Ese volumen puede ser casi surreal: pisos de celdas apilados a alturas incómodas, corredores suspendidos, escaleras interminables, torre de observación, enorme vacío central, puentes entre muros y techo apenas visible.
- La perspectiva del jugador y los planos de cámara deben enfatizar un **personaje diminuto** frente a la estructura.
- Regresar luego a espacios cerrados y opresivos. El contraste es el efecto, no la gigantomanía constante.

**Referencias espaciales conceptuales:**

- Pasarela estrecha sobre vacío de muchos niveles.
- Celdas alineadas verticalmente hasta perderse en la oscuridad.
- Puerta de seguridad muy alta, pesada y desproporcionada.
- Torre de vigilancia interior con foco o farola puntual.
- Escalera o ascensor antiguo hacia plantas oscuras.
- Sala institucional cavernosa/casi catedralicia, pero hecha con materiales penitenciarios.

No convertir el conjunto en prisión al aire libre ni tecnología de otro siglo.

### 4.5. Paleta de color [DECIDIDO]

| Uso | Tonos / intención |
|---|---|
| PRESENTE | Gris azulado, azul oscuro, verde sucio/enfermizo, negro y blanco fluorescente gastado |
| PELIGRO / ALARMA | Rojo más intenso, pero **como acento**, no una prisión teñida permanentemente de rojo |
| PASADO | Ámbar apagado, amarillo de sodio, sepia/gris cálido, luces urbanas sucias |
| TEXTURAS | Marrones de óxido, beige de pintura envejecida, gris de concreto, metal frío |
| PERSONAJE | Naranja sucio del uniforme, contraste mínimo pero reconocible |

La distinción entre épocas debe percibirse inmediatamente por **temperatura de luz, actividad y sonido**.

### 4.6. Iluminación y atmósfera [DECIDIDO / SUJETO A VIABILIDAD]

- Fluorescentes parpadeantes, fríos, a veces defectuosos.
- Contraluces que permitan ver una silueta sin mostrar el rostro.
- Rayos de luz remotos en gran pabellón para enfatizar escala.
- Oscuridad real, pero que no impida al jugador distinguir recorridos importantes.
- Sombras largas de rejas, tubos, puertas y cuerpos.
- Niebla suave, vapor, humedad, charcos discretos y luz volumétrica **si el motor/presupuesto lo permiten**.
- Focos de vigilancia que hacen visible al protagonista y producen tensión.
- Alarmas rojas episódicas en encuentros o persecuciones.
- La fuente de luz visible debe ser verosímil: luminarias, tragaluces con rejas, linternas, torre de guardia; nada sci-fi.

### 4.7. Materiales [PROPUESTO COHERENTE]

Concreto frío con fisuras; pintura desconchada; muros ligeramente húmedos; hierro oxidado; barrotes; rejillas; vidrio reforzado; charcos; tuberías; carteles carcelarios desgastados; expedientes; sangre seca donde aporte a narrativa; sábanas o telas colgantes deterioradas. La arquitectura se siente como una **máquina antigua de castigo**.

### 4.8. Protagonista [DECIDIDO VISUALMENTE / PENDIENTE MODELADO FINAL]

- Joven/adulto ladrón, no héroe impecable.
- Cabello oscuro low-poly, figura humana normal, gesto vulnerable.
- **En el presente:** uniforme naranja de preso, sucio, arrugado/deteriorado; postura cansada, movimientos tensos.
- **En el pasado urbano:** ropa civil acorde a la persecución previa al arresto; debe seguir siendo claramente la misma persona.
- Rasgos, rostro exacto, edad y biografía detallada no están cerrados.
- El creador expresó que el diseño visual del protagonista de los primeros moodboards **le gustó mucho**. Mantener esa continuidad de silueta/ropa/rostro low-poly en posteriores referencias.

### 4.9. Cámara cinematográfica [DECIDIDO]

- **Jugabilidad:** cámara **en tercera persona dinámica**; puede acercarse en corredores estrechos y permitir apreciar altura y escala en el pabellón.
- **Tráiler:** cámara puede adoptar encuadres independientes de gameplay para dramatizar imágenes.
- Planos íntimos de manos, cerraduras, llaves, respiración, botas y barrotes.
- Planos generales monumentales con figura humana mínima.
- Planos altos/cenitales que muestren vacío y vulnerabilidad.
- Movimientos de cámara lentos para crear incertidumbre, cortes veloces en persecuciones.
- Evitar exceso de cámara temblorosa y jumpscares arbitrarios.

### 4.10. Sonido y música [PROPUESTO CON ALTA PRIORIDAD]

El sonido debe amplificar el **frío, la soledad y el espacio gigante**:

- Silencios casi absolutos interrumpidos por zumbidos eléctricos.
- Ventiladores, tuberías, goteras, pasos, respiración, ropa arrastrándose.
- Chirridos de puertas y llaves metálicas.
- Golpes lejanos con reverberación prolongada.
- Megafonía deteriorada, radios policiales en pasado.
- El arma o herramienta pesada de La Sentencia rozando el suelo.
- Persecuciones: estallido de ritmo industrial, sirenas, eco y latido; no música intensa constante.
- Flashbacks: actividad de voces, lluvia, tráfico y entorno humano que desaparece al regresar a prisión.

### 4.11. Logo, tipografía y branding [PROPUESTO]

- Nombre **LIFETIME SENTENCE** en mayúsculas o presentación fuerte.
- Tipografía severa, institucional, condensada o tipo expediente deteriorado.
- Material gráfico como fichas penitenciarias, sellos de sentencia, números de celda y marcas de registro.
- Pequeños acentos rojos, no neones.
- Introducción del título al final con corte a negro y diseño sonoro seco/perturbador.

### 4.12. Simbolismo espacial [PROPUESTO]

- Rejas = encierro.
- Escaleras que parecen no acabar = imposibilidad de escapar de consecuencias.
- Mirillas/focos/cámaras = vigilancia.
- Celdas vacías, camas y ropa abandonada = deshumanización.
- Documentos/cintas/archivos = verdades ocultas.
- La prisión monumental = institución/castigo desproporcionado.
- Copias, reflejos, rostros ausentes = culpa y memoria fragmentada.

---

## 5. ENEMIGOS — FILOSOFÍA GLOBAL

### 5.1. Principio aprobado [DECIDIDO]

**Las criaturas del presente son manifestaciones de culpa de inspiración psicológica (enfoque similar a Silent Hill), con diseños propios.** La relación pasado/presente se expresa en:

1. Papel narrativo e ideología.
2. Forma/silueta/sonido.
3. **Mecánicas que cambian** entre la versión humana y su contraparte manifestada.
4. Descubrimientos mediante flashbacks que cambian la interpretación de encuentros previos.

No tienen que parecer personas disfrazadas. Especialmente La Sentencia debe resultar simbólica y perturbadora, sin comprensión inmediata.

### 5.2. Ideas y conceptos que representan [PROPUESTO]

- **Obediencia ciega**: cumplir órdenes sin cuestionar.
- **Vigilancia/control**: nunca se deja de observar a los reclusos.
- **Castigo absoluto**: dolor como supuesto fin de justicia.
- **Autoridad y corrupción**: la ley usada como instrumento de poder.
- **Deshumanización/abandono**: presos reducidos a cuerpos o números.
- **Culpa personal**: el protagonista no puede huir de sus actos.

Cada criatura debe diseñarse desde una emoción y mecánica, no simplemente para rellenar enemigos.

### 5.3. Criterios de diseño [DECIDIDO / PROPUESTO]

- Estética **low-poly retro PS1** tanto en humanos como monstruos.
- Basarse en elementos antiguos penitenciarios: uniformes, placas, cascos, botas, llaves, gorras, puertas, capuchas, ejecutores, expedientes, luces.
- Formas extrañas y ambiguas, proporciones imposibles o deformaciones parciales; no recurrir automáticamente a tentáculos gigantes, robotización o gore excesivo.
- En el presente, siluetas reconocibles a distancia, pero rostro/función no siempre inteligibles.
- La amenaza puede aparecer a través de **sonido, sombra y comportamiento** antes que una exposición frontal.
- No todos los enemigos necesitan un combate ni siquiera presencia física continua.

---

## 6. ROSTER CONCEPTUAL — PASADO

> **Alcance:** catálogo del juego imaginado, no todos requeridos para la micro-demo. Sus imágenes de referencia se generaron en una lámina específica.

| Tipo | Nombre | Aspecto / rol | Mecánica o presencia posible | Estado |
|---|---|---|---|---|
| Común | **Policía patrullero** | Agente humano, uniforme oscuro antiguo, porra/linterna/silbato | Persigue a pie, vigila callejones y responde a ruido | Propuesto |
| Fuerte | **Policía táctico** | Agente reforzado, casco/escudo, apariencia intimidante pero real | Persecución escalada o cierra accesos; evita rutas directas | Propuesto |
| Fuerte | **Guardia penitenciario** | Guardia de prisión con llaves y uniforme gastado | Patrulla celdas/pasillos; controla puertas, conoce rutas | Propuesto |
| Especial | **Interrogador** | Autoridad de oficinas, camisa/chaleco/corbata; coercitivo | Tensión mediante interrogatorio, información y decisiones; no necesariamente persecución física | Propuesto |
| Mini-jefe | **Verdugo penitenciario** | Ejecutor humano robusto asociado a sentencias y castigos | Encuentro puntual con arma/herramienta pesada similar a hacha | Propuesto |
| Jefe / poder | **Alcaide corrupto** | Máxima autoridad penitenciaria, ropa formal/uniforme | Usa subordinados, órdenes, control institucional y archivos; un jefe no necesariamente peleable | Propuesto |

**Nota de realismo:** los modelos del pasado pueden ser humanos convencionales, pero su papel criminal/institucional depende de la narrativa. El verdugo con hacha es una **licencia artística** que debe tener justificación en el mundo, no asumirse como práctica penitenciaria real.

---

## 7. ROSTER CONCEPTUAL — PRESENTE

| Tipo | Nombre | Ideología / sentido | Diseño visual | Dinámica propuesta | Estado |
|---|---|---|---|---|---|
| Común | **Los Aislados** | Abandono, pérdida de identidad, deshumanización | Restos de reclusos, facciones vagas, uniformes degradados, movimientos erráticos | Reaccionan a ruido; varios pueden converger | Propuesto |
| Stalker | **El Uniforme** | Obediencia ciega, represión, persecución policial | Figura alta y rígida; gorra/uniforme deforme; rostro oculto; llaves | Te rastrea por línea de visión, obliga a usar cobertura/sigilo; alternativa: quedarse inmóvil si te observa | Propuesto para demo |
| Stalker / vigilancia | **El Vigilante** | Control y observación constante | Muy delgado o asociado a focos, mirillas y torres; identidad indefinida | Zonas de luz/conos de vigilancia que hay que evitar | Propuesto |
| Especial | **El Condenado** | Culpa íntima del protagonista | Doble/reflejo del propio ladrón; gestos desfasados | Aparece donde ya pasaste; imita o altera movimientos; puede no atacar | Propuesto |
| Mini-jefe / jefe de área | **La Sentencia** | Castigo absoluto, expiación, violencia de autoridad | Masa humana pesada, desproporcionada, hacha/herramienta simbólica, sin diseño literal transparente | Avance lento e imparable; romper coberturas; puzle bajo presión | Propuesto, cameo demo |
| Jefe final conceptual | **El Director** | Institución corrupta y autoridad sin rostro | Alcaide deformado o estructura humana colosal, abrigo/uniforme severo | Cambia rutas, bloquea puertas, altera mecanismos y controla escenario | Propuesto para juego completo |

### 7.1. El Uniforme — desarrollo de mecánica [PROPUESTO PARA DEMO]

- **Pasado:** un policía humano corre hacia el protagonista durante persecución urbana.
- **Presente:** su correlato es un stalker de lógica no completamente humana.
- Sonido identificativo: llaves, botas y metal, quizá silencio súbito antes de aparición.
- **Modelo mínimo de IA para prueba:** patrulla → detecta → persigue → pierde de vista → busca brevemente → regresa o desaparece de forma guionizada.
- Mecánica especial posible: debe detenerse / no moverse cuando su mirada se fija en el personaje, además de esconderse. **No se decidió de forma definitiva** cuál será el patrón exacto.
- En la micro-demo basta un encuentro de unos segundos convincente, no un sistema de IA avanzado.

### 7.2. La Sentencia — desarrollo de jefe [PROPUESTO]

- Contraparte conceptual del verdugo humano.
- **Debe ser difícil de entender a primera vista**, como pidió expresamente el creador: el arma debe sugerir un hacha de ejecución sin verse como una herramienta corriente colocada en manos de un humano gigante.
- Silueta lenta, pesada, muy amenazante.
- Sonido de arrastre metálico.
- Puede tener una fase de puzle bajo presión: hay que activar mecanismos para abrir una puerta mientras él merodea, atraído por cada ruido. Sus golpes pueden romper coberturas.
- No hace falta matarlo; se sobrevive y se escapa.
- **Para la demo de un minuto:** mostrar un teaser breve: sonido, sombra, silueta parcial y corte a negro. No implementar pelea de jefe.

### 7.3. El Director [PROPUESTO, NO MVP]

- Correspondencia con alcaide corrupto.
- Jefe simbólico que representa el sistema y su arquitectura.
- Puede crear bloqueos, redirigir rutas, activar alarmas y distorsionar entorno.
- Mejor plantearlo como encuentro ambiental que como enemigo de barra de vida.
- Reservado a desarrollo posterior, no construir ahora.

### 7.4. Conservación del giro humano [PROPUESTO]

No todos los guardias reales deben ser malvados. Se planteó que uno de ellos, cuyo comportamiento parecía hostil, en realidad tratara de impedir la matanza o conservar pruebas. Esto es importante para no trivializar el mensaje: el juego no afirma simplemente «toda autoridad es monstruosa». La manifestación es una perspectiva de culpa/trauma, no diagnóstico moral transparente de cada persona real.

---

## 8. JUGABILIDAD DEL JUEGO COMPLETO

### 8.1. Perspectiva y cámara [DECIDIDO]

**Tercera persona dinámica.** Ver al protagonista es importante para su identidad y composición del tráiler. La cámara se acerca en sitios angostos y puede mostrar grandes vacíos en el pabellón. Se consideraron primera persona, cámara fija retro/isométrica, pero la dirección adoptada fue tercera persona dinámica.

### 8.2. Bucle de juego [PROPUESTO CONSISTENTE]

**Explorar → descubrir pista → acceder a recuerdo → aprender verdad/mecánica → evitar amenaza → abrir camino → explorar.**

Las pruebas y los flashbacks impulsan tanto la historia como acciones concretas.

### 8.3. Cuatro interacciones principales contra enemigos [DECIDIDO COMO DIRECCIÓN]

1. **Esconderse:** celdas, muebles, rincones y cobertura, rompiendo línea de visión.
2. **Escapar:** correr, doblar esquinas, sortear objetos, cerrar puertas y seguir una ruta.
3. **Distraer:** lanzar objetos o activar fuentes de ruido, si el tiempo de desarrollo lo permite.
4. **Observar:** aprender patrones y reglas particulares de cada criatura.

### 8.4. Defensa [FAVORITO PROPUESTO, AÚN SIN CONFIRMACIÓN EXPLÍCITA]

Se compararon:

- **A. Indefensión total:** esconderse y huir, sin atacar.
- **B. Defensa limitada:** empujar, bloquear puertas, aturdir brevemente, usar muebles, ganar unos segundos sin matar monstruos.
- **C. Combate de supervivencia:** armas improvisadas contra comunes, jefes de reglas especiales.

La recomendación reiterada del asistente fue **B: defensa limitada**, y al usuario le gustó la dinámica general, pero **no hizo una elección explícita entre A/B/C**. Para el prototipo se puede asumir una **defensa mínima de no letalidad (bloquear una puerta o apartar un objeto)** sin implementar combate.

### 8.5. Diferencias de ritmo [DECIDIDO]

**Pasado:** acción de huida y persecuciones con lógica humana, adrenalina, rutas urbanas, movimiento ágil.

**Presente:** pausas, investigación, silencio, amenaza impredecible, esconderse, comprender la lógica de la manifestación y sobrevivir.

### 8.6. Acciones/movimiento [PROPUESTO]

- Caminar y correr.
- Control de cámara en tercera persona.
- Interactuar con objetos relevantes.
- Abrir/cerrar puertas.
- Esconderse o usar coberturas.
- Posiblemente agacharse.
- Eventualmente saltar/traspasar obstáculos en flashback urbano; **no está confirmado si habrá salto universal**.
- Defensa limitada según se confirme.
- Cambio de realidad por flashback, no necesariamente a voluntad.

### 8.7. Puzles e investigación [PROPUESTO]

- Documentos, fotografías, identificaciones, grabaciones/cámaras y objetos de presos/guardias.
- Puzles sencillos de cerraduras, códigos, llaves y mecanismos.
- Un objeto del presente puede activar recuerdo del pasado; el recuerdo revela contraseña/ruta, necesaria para actuar al volver.
- Inventario grande y sistemas complejos **no son prioritarios para la primera prueba**.

### 8.8. Enemigos como reglas de juego [PROPUESTO]

| Enemigo | Problema que plantea | Respuesta jugable |
|---|---|---|
| Los Aislados | No toleran ruido | Caminar lento o distraer |
| El Uniforme | Vigila / persigue | Ocultarse, romper visión, aprender condición especial |
| El Vigilante | Exposición a focos / zonas vigiladas | Moverse entre sombras y coberturas |
| El Condenado | Copia o contradice tus rutas | Descubrir patrones de espejos / movimientos |
| La Sentencia | Presión constante en espacio cerrado | Activar mecanismos / escapar antes de quedar atrapado |
| El Director | Modifica la propia prisión | Adaptar rutas y manipular sistemas, no combate directo |

### 8.9. Ejemplo de jefe como puzle bajo presión [PROPUESTO]

**La Sentencia:** entrar en sala de ejecuciones → escuchar hacha arrastrándose → aparecer entidad → activar tres mecanismos para desbloquear puerta → cada ruido atrae al jefe → coberturas van desapareciendo → huida corta y potente. Es un diseño conceptual para una versión mayor, **no para micro-demo de 60 s**.

### 8.10. Progresión y fracaso [PROPUESTO / PENDIENTE]

- Si el enemigo atrapa al jugador, retorno a un punto de control cercano; evitar castigo excesivo.
- Curva de dificultad y checkpoints por definir.
- Combate letal, inventario y sistemas complejos no se han aprobado.
- Las criaturas no deberían aparecer permanentemente: alternar presión y silencios para conservar el miedo.

---

## 9. MAPA Y DISEÑO DE NIVELES — VISIÓN MAYOR

### 9.1. Zonas conceptuales [PROPUESTO]

1. **Bloque de celdas:** despertar, tutorial, cadáveres, primeros ruidos, rejas.
2. **Corredores estrechos:** tensión, exploración, puertas y cobertura.
3. **Enfermería:** documentos, signos de ejecución/violencia, investigación y puzle.
4. **Sala de vigilancia:** cámaras, grabaciones, pistas y persecución.
5. **Pabellón central monumental (interior):** golpe visual de megalofobia, pasarelas, vacío vertical, celdas en altura, un enemigo diminuto al fondo.
6. **Sala de ejecución / sectores inferiores:** posible encuentro con La Sentencia.
7. **Núcleo de control / salida de emergencia:** verdad y desenlace.
8. **Flashback urbano:** callejón lluvioso donde ocurre la persecución policial; otros lugares del pasado podrían añadirse luego.

Esta es una lista de áreas **del juego proyectado**, no de nivel completo ya aprobado. Por costos y duración, la demo inicial solo utiliza **cuatro micro-zonas** (ver apartado 11).

### 9.2. Regla espacial importante [DECIDIDO]

La sensación de megalofobia se logra en **una parte específica** al salir de las celdas. No diseñar el nivel entero como un rascacielos o una megaciudad; un único gran atrio cerrado es suficiente y más poderoso si viene después de un pasillo sofocante.

### 9.3. Cámara y circulación [PROPUESTO]

- Pasillos diseñados para una cámara de tercera persona que no atraviese paredes.
- Contraste de escalas sin entorpecer control.
- Geometría simple para que sea fácil crear y pulir con IA.
- En demo, guiar al jugador con luz, sonido, encuadres y una ruta clara, en vez de un minimapa.

---

## 10. FLASHBACKS Y TRANSICIONES TEMPORALES

### 10.1. Función [DECIDIDO]

Los flashbacks no son mero video: en el juego completo deberían ser **experiencias controlables** que expliquen acontecimientos y cambien significado de amenazas. Para la demo pueden ser **breves y altamente guionizados**.

### 10.2. Disparadores [PROPUESTO]

- Fotografía de arresto.
- Identificación, llave o expediente.
- Grabación de cámara.
- Cadáver asociado a alguien del pasado.
- Lugar con fuerte carga emocional.

### 10.3. Tratamiento audiovisual [PROPUESTO]

- Al tocar una prueba, ruido/respiración/glitch o destello breve y transformación de escenario.
- La prisión destruida puede recomponerse momentáneamente al entrar en recuerdo.
- Un cuerpo del presente puede aparecer vivo en pasado.
- Movimiento o encuadre debe servir como **match cut**: llave en pasado → llaves de El Uniforme en presente.
- Pasado: cálido apagado, sonido vivo. Presente: frío desolado, ecos y silencios.
- Para la micro-demo, **no es obligatorio un morph 3D continuo**; un corte artístico con audio/efecto bien ejecutado cumple el objetivo.

### 10.4. Mecánica distintiva [DECIDIDO A NIVEL CONCEPTUAL]

El jugador conoce una autoridad humana en el pasado y luego una manifestación con comportamiento diferente en el presente. Conservar continuidad por sonidos, objetos o gestos, pero no explicar de inmediato el vínculo.

---

## 11. MICRO-DEMO INMEDIATA — PRUEBA DE IA DE ~60 SEGUNDOS

### 11.1. Objetivo real [DECIDIDO]

**Primero comprobar cómo lo hace la IA.** El creador pidió una demo «corta de 1 minuto aunque sea», muy artística. Esta es una prueba inicial, no la producción definitiva ni el juego entero.

**Criterio de éxito:** que un minuto permita entender la identidad: retro PS1, prisión fría, encierro, pasado/presente, persecución humana que se refleja en criatura simbólica, gran pabellón central, sonido inquietante. Preferir una secuencia pequeña, cohesionada y memorable a diez sistemas funcionales mal terminados.

**Ambigüedad operativa pendiente:** no se confirmó si el entregable debe ser estrictamente ejecutable/jugable durante 60 s, un recorrido guiado de 60 s dentro de un prototipo o un clip renderizado. La propuesta del asistente fue una **micro-demo interactiva con algunos eventos/cámaras guionizados**, a partir de la cual se puede capturar un video. El prompt futuro deberá precisar el formato técnico.

### 11.2. Guion de la micro-demo [PROPUESTO Y BIEN ALINEADO]

| Tiempo aproximado | Época / zona | Acción | Objetivo visual / mecánico |
|---|---|---|---|
| **00:00–00:10** | PRESENTE — celda | Despierta en su celda, luz fría, respiración, puerta entreabierta; caminar e interactuar | Establecer soledad, frío, claustrofobia y cámara tercera persona |
| **00:10–00:20** | PRESENTE — corredor | Pasillo estrecho; un cadáver o una marca; tocar un objeto significativo | Suspenso; disparar flashback sin explicación excesiva |
| **00:20–00:35** | PASADO — callejón urbano lluvioso | Ladrón civil huye de policía humano; doblar esquina, sortear obstáculo | Contraste entre persecución humana y horror actual; recordar: **NO dentro de la cárcel** |
| **00:35–00:45** | PRESENTE — corredor | Corte de vuelta; tintineo de llaves; aparición de El Uniforme; evitarlo u ocultarse brevemente | Mostrar manifestación y regla de sigilo distinta a la persecución pasada |
| **00:45–00:55** | PRESENTE — pabellón central | Tras salir de celdas se abre un gigantesco espacio interior de muchos niveles; el preso parece mínimo; silueta a distancia | **Momento héroe:** megalofobia, monumentalidad, encierro, frío, silencio |
| **00:55–01:00** | PRESENTE — teaser | Algo pesado se arrastra; vistazo parcial a La Sentencia; corte a negro y título LIFETIME SENTENCE | Amenaza memorable y cierre cinematográfico sin spoilers |

Esta cronología es un **storyboard de 60 segundos**. Si el agente no consigue implementar todas las interacciones en ese tiempo, priorizar el impacto de los planos y la claridad del contraste de épocas.

### 11.3. Micro-zonas mínimas [DECIDIDO COMO PLAN DE PRUEBA]

1. **Celda inicial**.
2. **Corredor de prisión del presente** (puede reutilizar geometría de la celda).
3. **Callejón urbano del pasado** (ciudad, noche, lluvia, patrulleros humanos).
4. **Pabellón central cerrado y monumental**.

Idealmente son escenas pequeñas; el gran pabellón puede ser una **pieza de entorno preparada para cámara** más que un mapa entero completamente explorable.

### 11.4. Personajes y enemigos mínimos

- **Protagonista**: una variante de preso naranja en presente; variante civil en pasado, mismo rostro/silueta.
- **Policía humano** para flashback, con persecución simple.
- **El Uniforme** en presente, stalker con aparición y detección básicas.
- **La Sentencia** solo como figura parcial o silueta de 2–3 s al cierre; no IA de jefe ni arena.

**No construir el roster completo.**

### 11.5. Mecánicas mínimas [PROPUESTO]

- Movimiento/control en tercera persona.
- Caminar / correr.
- Una interacción con objeto y/o puerta.
- Flashback o cambio de escena.
- Persecución simple del policía.
- Encuentro muy corto con El Uniforme: detección básica/ocultarse/romper visión.
- Cámara o evento guionizado para la revelación de escala.
- Sonidos y transición de cierre.

Opcionales si salen fáciles: agacharse, interacción con cobertura, golpe de puerta, lluvia, pequeñas partículas, parpadeo de luz.

### 11.6. Sistemas que se pueden simular o guionizar [DECIDIDO COMO ESTRATEGIA]

- La transición temporal.
- El plano de entrada al gran pabellón.
- Aparición de La Sentencia.
- Reacción/ciclo de El Uniforme durante 5–10 segundos.
- Cámaras espectaculares que no requieran un nivel completo.

**Importante:** no hacer pasar una escena puramente renderizada por funcional si luego se informa el resultado como «demo jugable». Ser transparentes sobre qué es interactivo y qué es guionizado.

### 11.7. Cosas explícitamente fuera de la primera prueba

- Jefes completos y barras de vida.
- Peleas complejas o árboles de ataque.
- Inventario elaborado.
- Gran cantidad de puzles/documentos.
- Múltiples rutas y mapa extenso.
- IA compleja para todos los monstruos.
- Todos los actos de la historia y finales alternativos.
- Sistema de misiones, estadísticas o progreso.
- Escenarios enteros del pasado más allá del callejón.
- Arquitectura futurista o realismo pesado.

### 11.8. Prioridades de la IA [DECIDIDO COMO ORIENTACIÓN]

**Máximas:** atmósfera, composición, coherencia artística, escala, iluminación, sonido, cámara y transiciones.

**Después:** personaje visible, movimiento básico, persecución/sigilo breve y cambio de épocas.

**Por último o no hacer:** IA complicada, combate, inventario, muchos enemigos, extensos mapas y sistema de juego completo.

### 11.9. Assets iniciales [PROPUESTO]

**Personajes:** ladrón modelo base (preso/civil), policía, El Uniforme, silueta de La Sentencia.

**Entornos:** celda, tramo de corredor, callejón lluvioso, atrio interior grande.

**Objetos:** rejas, puerta, fluorescentes, charcos/óxido, un cuerpo o indicio de masacre, foto/expediente, carteles, llaves, tuberías, un altavoz/cámara.

**Audio:** pasos, respiración, llaves, puerta, lluvia, radio policial, ambiente industrial, arrastre de metal, golpe musical/corte final.

**FX:** niebla sutil, parpadeo, transiciones/grano/dithering, luz volumétrica si viable, alarma opcional.

### 11.10. Verificación de calidad de la micro-demo

- [ ] Al menos una escena estrecha se siente **claustrofóbica**.
- [ ] El presente se percibe **frío, vacío y silencioso**.
- [ ] El estilo es **low-poly retro PS1**, no sci-fi/fotorrealista.
- [ ] El pasado es una **persecución urbana** (no otra sala de prisión).
- [ ] Se distinguen fácilmente las dos épocas visual y sonoramente.
- [ ] Hay al menos una persecución humana o demostración clara de su comportamiento.
- [ ] El Uniforme tiene **alguna diferencia mecánica real o escénica** respecto al policía.
- [ ] El personaje del presente lleva uniforme naranja y mantiene identidad visual.
- [ ] Hay un único pabellón **cerrado y descomunal**, visible en un plano memorable.
- [ ] La Sentencia solo se sugiere, sin develar el monstruo por completo.
- [ ] El audio aporta eco, silencio, llaves, tensión y final.
- [ ] El tramo dura **aproximadamente 1 minuto** (flexible si hace falta por interacción).
- [ ] El resultado tiene suficiente calidad para juzgar si conviene escalar el proyecto.

---

## 12. TRÁILER — PIEZA PRINCIPAL DE PRESENTACIÓN

### 12.1. Intención [DECIDIDO]

El creador expresó que **el tráiler es la prioridad creativa para competir**, y que no mostrarán demasiado juego, sino una selección de momentos. Por tanto, diseñar **imágenes memorables**, no solo un montón de mecánicas. No interpretar esto como obligación de montar un tráiler largo ahora: primero se quiere probar a la IA con la micro-demo.

### 12.2. Lenguaje cinematográfico [PROPUESTO]

- **Inicio:** lento, vacío, celda y pasillos, respiración y silencio.
- **Descubrimiento:** cuerpos/pistas/recuerdo.
- **Contraste:** persecución humana en el pasado vs aparición monstruosa en presente.
- **Golpe visual:** pabellón gigantesco en un plano general interior con preso diminuto.
- **Ruptura:** alarmas, cortes cortos, ruido, manifestaciones.
- **Cierre:** hacha/arrastre, figura apenas visible, negro, título.

Planos de alto valor:

- Protagonista apenas visible bajo miles de celdas.
- Ángulo cenital que aumenta soledad.
- Close-up de llave en mano de policía / llaves de El Uniforme.
- Puerta que se cierra al finalizar flashback, transformándose en reja corroída.
- Hacha/arma abstracta arrastrándose, sin revelar toda La Sentencia.

### 12.3. Qué vender con el tráiler

1. Identidad retro PS1 cuidada, no defecto técnico.
2. Claustrofobia y un salto de escala impactante.
3. Dos tiempos con atmósferas distintas.
4. Una ley humana y una ley convertida en culpa.
5. Misterio con amenaza simbólica.

### 12.4. Qué no mostrar

- El giro de responsabilidad del protagonista en masacre.
- La verdad sobre el guardia que intenta ayudar.
- Explicación de la naturaleza exacta de las manifestaciones.
- El alcaide/Director derrotado o el final completo.

---

## 13. INTERFAZ, CONTROLES Y EXPERIENCIA

**Orientación propuesta, aún no cerrada:**

- HUD mínimo; sin minimapa invasivo.
- Indicación discreta de «interactuar».
- Subtítulos opcionales y lectura clara de documentos.
- Menú de pausa sencillo.
- Cámara que evita clipping en celdas estrechas.
- Señales de rutas mediante luz, sonido y objetos, no flechas brillantes.
- Checkpoint antes de persecuciones si el alcance crece.
- Evitar pantallas de tutorial largas, especialmente en demo de un minuto.

No se especificaron teclas, mando, sensibilidad ni accesibilidad técnica; deben definirse al elegir el motor.

---

## 14. PLAN DE PRODUCCIÓN — QUÉ FALTA DECIDIR

### 14.1. Decisiones confirmadas

| Elemento | Estado | Resultado |
|---|---|---|
| Tema Game Jam | DECIDIDO | Al otro lado de la ley; POV del ladrón |
| Nombre | DECIDIDO | Lifetime Sentence |
| Género | DECIDIDO | Terror psicológico, misterio, supervivencia y persecución |
| Protagonista moralmente ambiguo | DECIDIDO | Ladrón, responsabilidad real por descubrir |
| Dos épocas | DECIDIDO | Pasado humano / presente manifestaciones |
| Manifestaciones de culpa | DECIDIDO | Inspiración conceptual tipo Silent Hill, diseño original |
| Correspondencia enemigos | DECIDIDO | Misma figura/ideología, mecánica diferente |
| Estética | DECIDIDO | PS1 low-poly artístico/cinematográfico |
| Evitar futurismo | DECIDIDO | Prisión antigua, cerrada, fría y solitaria |
| Claustrofobia | DECIDIDO | Predomina en celdas y corredores |
| Megalofobia | DECIDIDO | Una zona interior grande al salir de las celdas |
| Paleta | DECIDIDO | Presente frío; pasado ámbar sucio; rojo de alarma |
| Cámara | DECIDIDO | Tercera persona dinámica |
| Protagonista visual | DIRECCIÓN APROBADA | Civil pasado; uniforme naranja low-poly presente |
| Enfoque enemigo | DIRECCIÓN APROBADA | Sigilo, persecución, patrones, supervivencia |
| Demo de prueba | DECIDIDO | ~60 segundos, muy artística |
| Prioridad de presentación | DECIDIDO | Tráiler / material cinematográfico |

### 14.2. Propuestas que **no** deben confundirse con requisitos cerrados

- Catálogo exacto de seis enemigos por época.
- Duración final de juego (en un momento se propuso 10–15 min como posible Game Jam; **reemplazado en la prueba inmediata por ~1 min**).
- Defensa limitada opción B (preferencia del asistente; falta elección explícita del creador).
- Mecánica de «detenerse» ante El Uniforme.
- Puzle de tres mecanismos contra La Sentencia.
- Dos finales alternativos.
- Existencia de una capilla o iconografía religiosa. Los moodboards usaron cruces y salas tipo capilla, pero **el creador no exigió religión como eje**; evitar presentar eso como canon.
- Que todo el pasado suceda en prisión (contradice petición expresa de persecución exterior).
- Que La Sentencia sea un hachero humano simple (contradice carácter ambiguo/psicológico deseado).

### 14.3. Datos técnicos pendientes

- Motor gráfico: Godot, Unity, Unreal, Three.js/React u otro **sin decidir**.
- Entrega: ejecutable, build web, archivo de proyecto, video MP4 de captura o combinación **por decidir**.
- Plataforma y controles: PC/teclado/mando/web **por decidir**.
- Agente de IA y herramientas/skills disponibles **por decidir**.
- Número de integrantes y reparto de roles **por decidir**.
- Fecha límite, criterios de Game Jam y restricciones de assets/licencias **no verificados aquí**.
- Disponibilidad y licencia de modelos, sonidos, texturas **por decidir**.
- Si la demo de un minuto es libremente jugable o una secuencia controlada **por concretar en el prompt**.

### 14.4. Orden sugerido si se convierte en un plan técnico

1. Elegir motor/target y formato de entrega (mínima decisión necesaria).
2. Construir escena central con **look-dev retro PS1 y luz fría**: verificar que *se vea* como debe.
3. Implementar protagonista, cámara tercera persona y 1 puerta.
4. Crear pasillo/celda y ambiente de audio.
5. Crear callejón del pasado con perseguidor humano.
6. Crear transición temporal con colores y sonido diferenciados.
7. Crear El Uniforme con comportamiento muy básico o aparición guionizada.
8. Construir atrio central desde la cámara: escala sin mapear toda prisión.
9. Añadir teaser de La Sentencia y corte final.
10. Pulir iluminación, partículas moderadas, ritmo, sonido, exportar y verificar.

No es necesario escalar el roster, AI navmesh complejo ni construir toda la prisión antes de tener este resultado.

---

## 15. REFERENCIAS VISUALES GENERADAS EN LA CONVERSACIÓN

Se generaron varias imágenes. **No son capturas de un juego existente ni modelos 3D editables: son concept art para dirección visual.** El agente debe usarlas como referencias de estilo, no asumir que los objetos y textos que aparecen en ellas ya son parte del juego implementado.

### 15.1. Referencia rechazada / evitar dirección

- **`megaprison_central_el_preso_b_314.png`** — primera megaprision con apariencia demasiado futurista. **No usar como look final**. Útil únicamente para recordar la crítica: falta de retro PS1 y falta de encierro/soledad/frío.

### 15.2. Moodboards y presente aprobados como dirección general

- **`a_cinematic_horror_style_game_concept_shotboard_c.png`** — moodboard con prisión central elevada, protagonista naranja, low-poly, pasillos, entidad, paletas y materiales. Más cercano a lo que gustó.
- **`a_cinematic_moody_concept_art_game_promo_moodbo.png`** — moodboard adicional con arquitectura interior, zonas estrechas, amenaza, paleta; usar con ojo crítico en aspectos demasiado realistas.
- **`a_cinematic_retro_ps1_low_poly_survival_horror_sc.png`** — pasarela frente a atrio monumental frío y El Uniforme a distancia; buena referencia del pabellón central.
- **`a_cinematic_retro_ps1_style_horror_game_collage_s.png`** — panel de escenas del presente: pabellón gigantesco, cuerpo, La Sentencia, duplicación/reflejos, vigilancia y cuarto perturbador.
- **`a_gritty_retro_ps1_style_low_poly_pixelated_surv.png`** — persecución en corredor estrecho por guardia/figura; útil para claustrofobia y estética.

### 15.3. Pasado fuera de la prisión — petición específica

- **`a_cinematic_retro_low_poly_ps1_style_scene_with_h.png`** — ladrón en callejón de ciudad lluviosa perseguido por policías bajo luz ámbar y luces policiales; **principal referencia del PASADO**.
- **`a_cinematic_gritty_retro_ps1_style_low_poly_scene.png`** — persecución de guardias dentro de instalaciones penitenciarias; es una escena posible secundaria, pero no reemplaza la persecución **urbana exterior** solicitada como pasado de referencia.

### 15.4. Láminas del roster

- **`dossier_de_enemigos_de_la_penitenciaría.png`** — **PASADO**: policías patrulleros, policías tácticos, guardia penitenciario, interrogador, verdugo y alcaide. Lámina de diseño, variedad de siluetas y jerarquía.
- **`enemigos_y_jefes_presente.png`** — **PRESENTE**: Los Aislados, El Uniforme, El Vigilante, El Condenado, La Sentencia y El Director. Lámina de diseños para monstruos, jefes y simbolismo.

**Nota:** las láminas pueden contener erratas o pequeños detalles generados automáticamente en texto/vestuario. **El texto de este documento prevalece** sobre rótulos erróneos de las imágenes. Los modelos finales deberán ser reinterpretaciones originales y no copias exactas de seres de otros juegos.

### 15.5. Cómo usar estas referencias en otro entorno

Si se copia solo el `.md`, **las imágenes no viajan automáticamente**. Se recomienda usar el paquete ZIP adjunto, con el Markdown y un directorio `referencias/` que preserva los nombres y el contexto. Si se trabaja únicamente con texto, las descripciones de las secciones 3–7 y 15 son la especificación de respaldo.

---

## 16. INSTRUCCIONES PARA UN FUTURO AGENTE DE DESARROLLO

> Este apartado **no es todavía el prompt de ejecución** solicitado para más adelante. Es una guía de lectura y restricciones para que el agente comprenda el contexto cuando se le envíe un encargo.

### 16.1. Orden de prioridad

1. Seguir las decisiones explícitas del creador.
2. Validar identidad visual antes de expandir sistemas.
3. Obtener un minuto convincente, corto y coherente.
4. Mantener el contraste PASADO/PRESENTE.
5. Priorizar atmósfera/sonido/composición por encima de cantidad de contenido.
6. Usar código/estructuras simples y reproducibles y explicar qué quedó real frente a guionizado.

### 16.2. Requisitos estrictos del look

- **Sí:** low-poly retro PS1, stylized horror, grano, texturas modestas, luz fría, cárcel antigua, encierro, silencio, escala concentrada.
- **No:** megacárcel futurista, cyberpunk, torres sci-fi, neon, robots, realismo AAA, exceso de brillo, mood de acción superheroica, campos abiertos, enemigos genéricos sin sentido simbólico.
- **No:** convertir la escena de PASADO seleccionada para micro-demo en otra persecución dentro de la cárcel.
- **No:** generar bosses de golpe fáciles de reconocer como «policía gigante con hacha». Deben tener diseño simbólico; en demo basta teaser.

### 16.3. Integridad de narrativa

- El ladrón es moralmente ambiguo; no blanquearlo por defecto.
- Las autoridades corruptas son personajes/sistema del relato, pero el giro del guardia que intenta ayudar puede matizar.
- No revelar los giros en demo/tráiler.
- Las criaturas del presente son manifestaciones de culpa y la mecánica cambia respecto al pasado.

### 16.4. Qué mostrar al creador para evaluar la primera prueba

- Capturas o planos clave de celda, callejón, El Uniforme, pabellón central, La Sentencia.
- Breve identificación de lo implementado realmente vs lo guionizado.
- Archivo ejecutable/build o video según se acuerde.
- Instrucciones breves para abrirlo.
- Relación de dependencias y assets externos, si se usaron.
- Errores conocidos y propuestas de mejora **después** de probar el minuto.

---

## 17. CRONOLOGÍA DE DECISIONES Y CAMBIOS DE CRITERIO

1. **Inicio:** idear un juego de terror sobre ladrón encarcelado, cadáveres, escapatoria y flashbacks, con el giro de corrupción entre quienes representan la ley.
2. **Narrativa:** se desarrolló una historia de crimen real, secretos carcelarios, masacre y responsabilidad ambigua del protagonista; guardia inicialmente malinterpretado.
3. **Nombre:** se debatieron varias opciones inglesas/oscuras, especialmente «Lockdown», hasta elegir finalmente **Lifetime Sentence**.
4. **Arte/tráiler:** el usuario destacó que **el tráiler y el impacto artístico son la prioridad**.
5. **Megalofobia:** pidió una prisión gigantesca en **una zona central** luego de salir de las celdas, casi surreal, **no todo el mapa gigante**.
6. **Estilo:** se valoró composición estilizada más low-poly PS1, con legibilidad y una estética cuidada, no demasiado realismo.
7. **Primera imagen:** el usuario dijo que resultaba **futurista** y no suficientemente **low-poly/retro**, y exigió **claustrofobia, prisión cerrada, miedo, soledad y frío**.
8. **Corrección:** nuevas referencias PS1 frías, interiores y opresivas le gustaron.
9. **Enemigos:** decidió que el pasado tuviera autoridades humanas y el presente **manifestaciones de culpa** al estilo psicológico, con policía → figura parecida a policía y verdugo → entidad abstracta con arma tipo hacha.
10. **Referencias temporales:** solicitó imágenes completas de pasado/presente; corrigió expresamente que el **pasado** no debía limitarse a la cárcel, sino una **persecución exterior**.
11. **Roster:** se generaron dos láminas con todos los enemigos/jefes de pasado y presente.
12. **Jugabilidad:** eligió **tercera persona dinámica** y enfatizó que quería diseñar mecánicas frente a enemigos, no solo cámara.
13. **Mecánicas:** se propusieron esconderse, escapar, distraer, observar, defensa limitada y jefes como puzles bajo presión.
14. **Idea aceptada:** la dinámica de un mismo perseguidor **cambia entre pasado y presente**; gustó la correspondencia mecánica.
15. **Alcance inicial:** se planteó un vertical slice mayor, pero el creador lo redujo para **probar a la IA con una micro-demo muy artística de un minuto**.
16. **Pedido actual:** recopilar todo en este **«Contexto absoluto del proyecto»** antes de pedir el prompt de producción.

---

## 18. GLOSARIO RÁPIDO

- **Game Jam:** evento para crear un juego bajo restricciones de tiempo/tema.
- **Lifetime Sentence:** título definitivo.
- **Pasado:** mundo humano previo/contemporáneo al encarcelamiento; persecución urbana y hechos que llevaron a prisión.
- **Presente:** prisión abandonada y distorsionada por culpa/trauma.
- **Megalofobia:** temor ante estructuras u objetos de enorme escala; aplicado a **un pabellón interior**.
- **Claustrofobia:** tensión por espacios pequeños y cerrados; sensación predominante en la prisión.
- **PS1 / low-poly:** lenguaje visual de geometría simplificada, texturas pixeladas, dithering y niebla.
- **El Uniforme:** manifestación del policía/autoridad que persiguió al protagonista.
- **La Sentencia:** manifestación del castigo, correlato del verdugo, entidad pesada con herramienta similar a hacha.
- **El Vigilante:** vigilancia como presencia constante.
- **Los Aislados:** abandono y deshumanización de reclusos.
- **El Condenado:** doble/proyección de culpa del protagonista.
- **El Director:** autoridad/institución corrupta como jefe simbólico.
- **Vertical slice:** segmento pequeño que reúne aspectos representativos del juego; aquí una **prueba muy breve**.
- **Teaser:** aparición parcial para provocar misterio sin revelar diseño ni argumento.

---

## 19. FRASE GUÍA FINAL PARA EL EQUIPO

> **Lifetime Sentence** debe sentirse como una pesadilla penitenciaria retro y fría: un ladrón atraviesa corredores claustrofóbicos, revive una persecución humana del pasado y vuelve a enfrentarse a una versión monstruosa de la misma autoridad. Solo después de salir de las celdas descubre una sala carcelaria interior tan enorme que se siente diminuto y solo. El diseño es low-poly PS1, con iluminación y composición cinematográficas, sin futurismo. Las criaturas representan culpa, castigo y poder; no son monstruos aleatorios. Antes de construir un juego completo, el objetivo es probar con IA una **micro-demo artística de aproximadamente 60 segundos** y decidir a partir de ese resultado cómo continuar.

---

**Fin del contexto consolidado.**
