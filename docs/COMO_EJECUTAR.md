# Cómo ejecutar Lifetime Sentence

## Jugar (sin Godot)

1. Abrir `entregas/LifetimeSentence.exe` (Windows 10/11, 64 bits). No necesita instalación.
2. Si Windows SmartScreen avisa: «Más información» → «Ejecutar de todas formas».

Al arrancar salen las advertencias de fotosensibilidad y de contenido (se pasan con cualquier tecla) y después el menú.

## Abrir el proyecto en Godot

1. Ejecutar `C:\Users\jojoj\Desktop\ARCADE\Godot_v4.7.2-stable_win64.exe`.
2. Importar → `juego/project.godot`. La primera vez tarda unos minutos en importar los modelos y el sonido.
3. **F5** juega desde el principio (arranque → menú). **F6** ejecuta la escena abierta. Los niveles están en `juego/niveles/<id>/<id>.tscn`; al ejecutar uno con F6 se empieza en su punto «inicio».

## Controles

| Acción | Teclado y ratón | Mando |
|---|---|---|
| Moverse | W A S D / flechas | Palanca izquierda |
| Cámara | Ratón | Palanca derecha |
| Correr | Mayús | RB o L3 |
| Agacharse | C o Ctrl | B |
| Interactuar (mantener: mecanismos y saltar cinemáticas) | E | A |
| Apuntar / disparar / recargar | Clic derecho / clic izquierdo / R | LT / RT / X |
| Lanzar objeto | G | Y |
| Pausa | Esc | START |
| Pantalla completa / captura | F11 / F12 | — |

Las teclas se pueden reasignar en **Opciones → Teclas**.

## Opciones de arranque (para pruebas)

Se escriben después de `--`:

```bash
LifetimeSentence.exe -- --calidad=alto --pantalla-completa
```

| Opción | Qué hace |
|---|---|
| `--calidad=bajo` / `--calidad=alto` | Fuerza la calidad gráfica (sin guardarla) |
| `--ventana` / `--pantalla-completa` | Modo de ventana |
| `--nivel=cap2` o `--nivel=cap1:desde_f1` | Empieza directamente en un nivel y punto de entrada. Niveles: `cap1`, `f1`, `cap2`, `f2`, `cap3`, `f3`, `cap4`, `final` |
| `--recorrido=C:/carpeta [--niveles=cap1,f1]` | Carga cada nivel y guarda capturas desde el jugador y desde cada cámara de cinemática |
| `--capturas-tiempo=C:/carpeta\|5,20` | Guarda capturas a esos segundos (con los fps en la consola) y cierra |
| `--prueba-demo=C:/carpeta` | Prueba automática de la demo completa (solo desde el proyecto, no desde el `.exe`) |
| `--nivel=cap2 "--prueba-camino=C:/carpeta|Interactivos/A|Interactivos/B"` | Un bot va **andando** hasta cada objeto de la lista y lo usa como un jugador: comprueba que todo es alcanzable. Solo desde el proyecto |
| `--nivel=f1 --prueba-huida=C:/carpeta\|modo` | Un bot juega la persecución de F1 y dice si escapa y con cuánto margen. Modos: `normal`, `obstaculos`, `duda_1` (se para 1 s en el cruce). Solo desde el proyecto |
| `--desarrollo` | Activa las teclas de desarrollo en el `.exe`: F1 información, F2 época, F3 calidad, F4 efectos PS1 |

## Partidas guardadas y ajustes

Están en `%APPDATA%\Godot\app_userdata\Lifetime Sentence\`: `partida_1.json` a `partida_3.json`, `autoguardado.json` y `ajustes.cfg`. Para empezar de cero, borrar esos archivos.
