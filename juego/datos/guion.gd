class_name Guion
extends RefCounted
## Líneas de diálogo, megafonía y textos de las cinemáticas. Cada línea es
## [quién, texto, segundos]. Quién vacío = sin nombre (voz en off, radio, ruido).
## Las voces grabadas por el equipo (pendientes_equipo.md, V-07 y V-08) se sincronizarán
## con estas mismas líneas; mientras tanto se muestran como subtítulos.

# -------------------------------------------------------------- Capítulo I ---
const MEGAFONIA_CAP1 := [
	["Megafonía", "Atención. Protocolo de Recuento en vigor. Permanezcan en sus celdas.", 4.5],
]

# ------------------------------------------------------- Recuerdo 1: huida ---
const F1_INICIO := [
	["Policía", "¡ALTO! ¡POLICÍA!", 2.2],
	["Radio", "Central a unidades: varón, chaqueta oscura, lleva una carpeta. Prioridad uno.", 4.0],
]
const F1_SILBATO := ["Policía", "¡Está aquí! ¡Refuerzos!", 2.0]
const F1_ESCONDIDA := [
	["", "(Ya no la tienes encima. Que la busquen.)", 3.0],
]
const F1_VERJA := [
	["Policía", "Se acabó, Novak.", 2.5],
	["Policía", "¿Dónde está la carpeta?", 2.5],
]
const F1_CONSECUENCIA := "Te quitan la carpeta.\nEsa misma noche, dos hombres muy educados llaman a la puerta de tu hermana."

# ------------------------------------------------- Recuerdo 2: interrogatorio ---
const F2_INTERROGATORIO := [
	["Interrogador", "Elías Novak. Cuatro mil y un reloj de oro. Eso dice la denuncia.", 4.0],
	["Interrogador", "El dinero me da igual. Quédatelo. Gástatelo en tu hermana.", 4.0],
	["Interrogador", "¿Dónde está la carpeta?", 2.6],
	["Interrogador", "Esos papeles no son tuyos. Ni siquiera sabes lo que firmaron.", 4.0],
	["Interrogador", "Tu hermana vive en la calle Olmos, ¿verdad? Tercero izquierda.", 4.0],
	["Interrogador", "Sería una pena que tuviera que mudarse.", 3.2],
	["Interrogador", "Voy a por un café. Tienes cinco minutos para recordar.", 3.8],
]
const F2_HUIDA := [
	["", "(Las esposas. El alambre que llevas en el forro.)", 3.5],
]
const F2_ALARMA := ["Policía", "¡Se ha escapado el de la sala tres!", 2.4]
const F2_CONSECUENCIA := "Te devuelven a la sala tres.\nEsta vez nadie va a por café."

# ------------------------------------------------------ Recuerdo 3: ingreso ---
const F3_INICIO := [
	["Guardia", "¡En fila! ¡La mirada en el suelo!", 2.8],
	["Guardia", "Bienvenidos a la 314. Aquí no se sale.", 3.4],
]
const F3_GUARDIA_AYUDA := [
	["Guardia (en voz baja)", "No me mires. Camina.", 2.6],
	["Guardia (en voz baja)", "Al fondo del patio hay una puerta de servicio. La llave no te la he dado yo.", 4.5],
]
const F3_CONSECUENCIA := "Te encuentran la llave.\nAl guardia que te la dio no se le vuelve a ver por el patio."

# ------------------------------------------------------------- Capítulo II ---
const MEGAFONIA_CAP2 := [
	["Megafonía", "Atención. El puesto de la torre tiene prioridad. No permanezcan en el haz.", 4.5],
]
const MEGAFONIA_ALARMA := ["Megafonía", "Interno fuera de su celda. Planta diez.", 3.0]

# ------------------------------------------------------------ Capítulo III ---
const CONDENADO_ERROR := ["", "(Algo se mueve detrás de ti. En el espejo.)", 2.6]

# ------------------------------------------------------------- Capítulo IV ---
const MEGAFONIA_CAP4 := [
	["Megafonía", "Interno cuatro ocho dos siete. La Sentencia ha sido dictada.", 4.2],
]
const CAP4_PISTA := ["", "(Tres mecanismos. Hacen ruido. Ella oye.)", 3.5]

# -------------------------------------------------------------------- Final ---
const FINAL_DIRECTOR := [
	["El Director", "Bienvenido, cuatro mil ochocientos veintisiete.", 4.0],
	["El Director", "Robaste por ella. Lo entiendo. Todos robamos por alguien.", 4.2],
	["El Director", "Pero en aquella caja fuerte había algo más que dinero. Había nombres. Firmas. Los nuestros.", 5.2],
	["El Director", "Te trajimos aquí para que lo olvidaras. Los que sabían algo dejaron de saber.", 4.8],
	["El Director", "Y una noche alguien te abrió la puerta. Un guardia. Placa treinta y uno.", 4.8],
	["El Director", "Tu fuga activó la Sentencia. Doscientos catorce internos. Y él, que se puso en medio.", 5.4],
	["El Director", "Todo esto también es tuyo, Elías.", 3.6],
	["El Director", "Ahora te ofrezco una salida.", 3.0],
	["El Director", "La carpeta vuelve a su sitio y tu hermana vive tranquila. O la carpeta sale de aquí... y ella paga por ti.", 6.2],
	["El Director", "Tu hermana o la verdad. No hay una tercera puerta.", 4.5],
]
