class_name Documentos
extends RefCounted
## Textos de los documentos legibles (decisión H3). Editar aquí el texto de cualquier
## documento; el id es el que se pone en el componente Documento del nivel.
##
## Revelaciones por capítulo (§4.5.2): I = el robo fue real y había una carpeta;
## II = los papeles comprometen a las autoridades; III = la prisión silenciaba testigos y un
## guardia guardaba pruebas; IV = la fuga de Elías disparó el protocolo de ejecución.
## Formato: BBCode de RichTextLabel ([b], [i], [color], [center]...).

const TEXTOS := {
	# ------------------------------------------------------------- Capítulo I ---
	&"carta_hermana": {
		"titulo": "Carta doblada bajo el colchón",
		"texto": """Elías:

Con lo que me mandaste he pagado tres meses de tratamiento. El médico dice que vamos bien, que si sigo así en primavera podré volver al colegio.

No sé de dónde lo has sacado. No quiero saberlo.

Han venido dos hombres preguntando por ti. Muy educados. Uno me dio un caramelo. Les dije que no te veía desde Navidad.

Ven a verme cuando salgas. Prométemelo.

[right]— tu hermana[/right]""",
	},
	&"expediente_4827": {
		"titulo": "PENITENCIARÍA ESTATAL N.º 314 — FICHA DE INGRESO",
		"texto": """INTERNO: NOVAK, Elías
NÚMERO: 4827            BLOQUE: A    CELDA: A-7

DELITO: Robo con fuerza en domicilio particular
        (residencia del Consejero de Justicia).

OBJETOS SUSTRAÍDOS:
  - Efectivo: 4.000 (recuperado).
  - Reloj de oro (recuperado).
  - [b]Documentación oficial: NO RECUPERADA.[/b]

CONDENA: — (pendiente de resolución)

OBSERVACIONES:
  Régimen de aislamiento por orden de Dirección.
  No registrar visitas. No registrar correspondencia.
  Prioridad: recuperar la documentación.

[right]Firma: ilegible    Sello: DIRECCIÓN[/right]""",
	},
	&"parte_noche": {
		"titulo": "Parte de incidencias — Bloque A, turno de noche",
		"texto": """03:40  Se va la luz del pabellón. Solo quedan las de emergencia.
03:44  Los internos golpean las rejas. Pido instrucciones a Dirección. No contestan.
03:51  Megafonía: «Protocolo de Recuento». Nadie del turno sabe qué significa.
03:55  Ha llegado un hombre de uniforme que no conozco. Tiene todas las llaves.
04:02  Ha empezado por la celda A-1. Cuenta en voz alta.
04:06  He dejado de oír al de la A-1.
04:09  Si te mueves mientras cuenta, te ve.

[i]El resto de la hoja está arrancado.[/i]""",
	},
	# ------------------------------------------------------------ Capítulo II ---
	&"circular_recuento": {
		"titulo": "CIRCULAR INTERNA — DIRECCIÓN",
		"texto": """A todo el personal del Patio Central:

En caso de activarse el Protocolo de Recuento, el personal abandonará las pasarelas y se retirará a la torre.

La vigilancia de las plantas quedará a cargo del puesto de la torre. El foco tiene prioridad sobre cualquier otra orden. [b]Quien permanezca en el haz más de un instante será considerado fugado.[/b]

Los internos de las plantas inferiores ya han sido aislados. No abrir las puertas de servicio bajo ningún concepto.

[right]El Alcaide[/right]""",
	},
	&"nota_interrogatorio": {
		"titulo": "Nota mecanografiada, con un clip y una fotografía",
		"texto": """De: Archivo Central
A: Comisaría Central, sala 3

Asunto: interno 4827 (Novak)

Les recuerdo que el dinero no es el objetivo. El dinero está recuperado y nadie lo echa de menos.

Lo que se llevó de la caja fuerte del Consejero [b]no puede aparecer en ningún sitio[/b]. Contiene actas, firmas y cantidades de las obras de la Penitenciaría. Si llega a un periódico, caemos todos.

Usen los medios que consideren. Tiene una hermana.

[i]Grapada a la nota hay una fotografía: tú, esposado a una mesa de metal.[/i]""",
	},
	&"pared_aislados": {
		"titulo": "Escrito en la pared, con algo oscuro",
		"texto": """NOS BAJARON AQUÍ CUANDO EMPEZÓ

NO HAGAS RUIDO
NO HAGAS RUIDO
NO HAGAS RUIDO

ELLOS NO VEN
ELLOS OYEN

[i]Debajo, más pequeño:[/i] el ascensor viejo funciona si le devuelves los fusibles. son tres.""",
	},
	# ----------------------------------------------------------- Capítulo III ---
	&"registro_defunciones": {
		"titulo": "ENFERMERÍA — REGISTRO DE DEFUNCIONES",
		"texto": """Noche del 3 al 4.

01:40  Interno 3115 (celda B-2) ..... paro cardíaco.
02:05  Interno 2290 (celda A-9) ..... paro cardíaco.
02:30  Interno 4011 (celda C-1) ..... paro cardíaco.
03:15  Interno 3876 (celda A-5) ..... paro cardíaco.

No se practica autopsia por orden de Dirección.
Los cuerpos se entregan sin visita de familiares.

[i]Al margen, a lápiz:[/i] los cuatro iban a declarar el lunes. Los cuatro en el caso del Consejero.

[i]Y debajo, con otra letra:[/i] tapad los espejos en el orden en que se fueron. Si no, él sigue mirando.""",
	},
	&"nota_guardia": {
		"titulo": "Nota escondida dentro de un expediente",
		"texto": """Si alguien encuentra esto:

He hecho copias de todo. Las actas del Consejero, el registro de esta enfermería, la lista de los traslados. Están en la caja de seguridad del archivo.

La combinación son las celdas de los cuatro testigos, en el orden en que se los llevaron. Solo el número de cada celda.

No voy a dejar que lo hagan otra vez. Al chico del Bloque A le he dicho que esté preparado.

[right]— G., placa 31[/right]""",
	},
	# ------------------------------------------------------------ Capítulo IV ---
	&"orden_sentencia": {
		"titulo": "ORDEN DE DIRECCIÓN — PROTOCOLO «SENTENCIA»",
		"texto": """Motivo: intento de fuga del interno 4827 (Novak, E.), con la colaboración de un miembro del personal (placa 31).

El interno ha tenido acceso a información reservada. No puede descartarse que la haya compartido con otros internos.

Se ordena:
  1. Cierre total del establecimiento.
  2. Recuento de todos los pabellones.
  3. [b]Ejecución de la Sentencia sobre todos los internos que hayan tenido contacto con el 4827.[/b]
  4. El funcionario de la placa 31 queda suspendido de empleo.

El interno 4827 debe llegar con vida al despacho de Dirección.

[right]El Director[/right]""",
	},
}


static func obtener(id: StringName) -> Dictionary:
	if TEXTOS.has(id):
		return TEXTOS[id]
	push_warning("Documentos: no existe «%s»" % id)
	return {"titulo": String(id), "texto": "(documento sin texto)"}
