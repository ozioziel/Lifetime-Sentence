# LIFETIME SENTENCE — GUÍA DEL EQUIPO

Cómo está hecho el juego y cómo modificarlo. Casi todo lo habitual (textos, luces, enemigos, puzles, cámaras) se cambia desde el **Inspector de Godot** o en archivos de texto sencillos, sin programar.

Última actualización: 2026-11-14 (demo completa, versión 1.0).

---

## 1. Dónde está cada cosa

| Carpeta | Contenido |
|---|---|
| `Materiales/` | Planificación, referencias y registros. Empezar por `contexto_para_agentes.md` |
| `docs/` | Estas guías, más funciones y limitaciones, exportación y subida a GitHub |
| `assets/` | Arte de Blender (kits, personajes, escenarios, planos) y sus scripts. Ver `assets/LEEME.md` |
| `juego/` | **El proyecto de Godot** |
| `juego/autoload/` | Sistemas siempre cargados: `Settings`, `Audio`, `Juego`, `Guardado`, `Interfaz`, `DebugTools` |
| `juego/render/` | Estética PS1 (`RenderRig`, shaders, perfiles de época) |
| `juego/jugador/` | Elías: movimiento, cámara, interacción, armas, escondites, muerte |
| `juego/personajes/` | `modelo_personaje.gd`: cualquier personaje animado de Blender |
| `juego/componentes/` | Piezas reutilizables: puertas, documentos, escondites, mecanismos, espejos, lluvia… |
| `juego/enemigos/` | Base común (`enemigo.gd`) y cada manifestación |
| `juego/niveles/` | Un nivel por carpeta: escena `.tscn` + script con su lógica |
| `juego/ui/` | Arranque, menú, créditos, minijuegos |
| `juego/datos/` | **Textos**: documentos (`documentos.gd`), diálogos (`guion.gd`), créditos (`creditos.gd`) |
| `juego/assets/` | Modelos `.glb` exportados de Blender, texturas y sonido |
| `juego/herramientas/` | Herramientas de desarrollo: configurar el proyecto, construir niveles, comprobar scripts, prueba automática. No se exportan |
| `entregas/` | El `.exe` y los textos de entrega |

## 2. Cómo funciona el juego

- **Render PS1** (`RenderRig`): el 3D se dibuja a 480 × 270 y se amplía con píxel nítido; la interfaz va aparte, a resolución real. Las cámaras de los niveles son «virtuales»: `RenderRig` copia la activa.
- **Director del juego** (`Juego`): cambia de nivel con fundidos, aplica las épocas y las transiciones D5/D6, lleva el estado de la partida (objetos, banderas, armas, documentos), los puntos de control, la muerte → «CONTINUAR» y la señal de **ruido** que oyen los enemigos.
- **Niveles**: cada uno tiene un nodo raíz con un script que hereda de `niveles/nivel.gd`. Al cargarse, `Juego` coloca al jugador en el `PuntoEntrada` pedido y llama a `al_entrar(punto)`.
- **Interfaz**: HUD mínimo, subtítulos, rótulos de capítulo, «CONTINUAR», documentos, pausa, opciones, ranuras y minijuegos.
- **Audio**: `Audio.efecto(&"nombre")`, `Audio.efecto_3d(...)` y `Audio.ambiente(...)` buscan `juego/assets/audio/<nombre>.ogg`. Si falta un sonido, el juego sigue y avisa en la consola.

## 3. Recetas sin programar

### 3.1. Cambiar un texto

- **Documentos**: `juego/datos/documentos.gd`. Cada documento tiene `titulo` y `texto` (admite `[b]negrita[/b]`, `[i]cursiva[/i]`…).
- **Diálogos, megafonía, escenas de fracaso y final**: `juego/datos/guion.gd`. Cada línea es `[quién, texto, segundos]`.
- **Créditos y licencias**: `juego/datos/creditos.gd`.
- **Objetivos y pensamientos de Elías**: en el script de cada nivel (`juego/niveles/<id>/<id>.gd`), en las llamadas a `Interfaz.objetivo(...)` y `Interfaz.subtitulo(...)`, o en la propiedad `Comentario` de cada objeto.

### 3.2. Añadir un objeto con el que interactuar

Añade un `Node3D` al nivel y ponle uno de estos scripts de `juego/componentes/`. Todos tienen en el Inspector `Texto` (el verbo del aviso), `Radio`, `Animacion` (de Elías) y su `Velocidad Animacion`, `Sonido`, `Comentario`, `Una Vez`, `Metodo Nivel` (función del script del nivel a la que llamar) y una **Cerradura** opcional: ganzúa, objeto clave, código o bloqueada.

| Script | Para qué |
|---|---|
| `interactuable.gd` | Algo que se examina o que dispara lógica del nivel |
| `documento.gd` | Un documento legible (`Id Documento` = clave en `documentos.gd`) |
| `recogible.gd` | Objeto clave, punzón, pistola, escopeta, munición, botella o lata |
| `pared_marcas.gd` | Punto de guardado (pared con marcas de conteo) |
| `puerta.gd` | Puerta que gira o se desliza. `Hoja` = nodo que se mueve |
| `puerta_transicion.gd` | Puerta que lleva a otro sitio con fundido a negro (u otro nivel) |
| `escondite.gd` | Taquilla. Hijos: `Punto`, `Salida` y `Camara` |
| `mecanismo.gd` | Palanca o volante que se acciona manteniendo el botón; hace ruido |
| `obstaculo.gd` | Del pasado: pasar por encima o derribar |

Y como `Area3D`, `zona_disparador.gd` llama a una función del nivel cuando entra el jugador.

### 3.3. Ajustar un enemigo

Selecciona el enemigo en el nivel (carpeta `Enemigos`) y cambia en el Inspector: velocidades, distancia y ángulo de visión, oído, memoria, `Ruta` (un nodo cuyos hijos son los puntos de patrulla) y espera en cada punto. Además:

- **El Uniforme**: intervalo y duración del Recuento, umbral de movimiento.
- **El Vigilante**: tolerancia (segundos en el haz), alcance, apertura y barrido del foco, punto de mira.
- **Policía**: tipo (patrullero, táctico, guardia), silbato, linterna y **goma elástica** (multiplicadores de velocidad cerca, a media distancia y lejos de Elías, que corre a 5,4 m/s). La huida de F1 se ajusta aquí y en `ventaja_inicial` (nodo raíz del nivel).
- **Los Aislados**: tacto (distancia a la que notan al jugador) y contagio (avisan a los demás).
- **La Sentencia**: duración de la furia.

### 3.4. Luces, niebla y encuadres

- Luminarias: `juego/componentes/luz_fluorescente.tscn` (estados estable, parpadeo leve, averiada o apagada). `Mostrar Tubo` = falso si el tubo ya está modelado en el escenario.
- Luces rojas de alarma: `componentes/luz_alarma.gd`. Se encienden al detectarte o al saltar la alarma.
- Niebla y luz ambiente: nodo `Entorno` de cada nivel.
- Encuadre de cámara: `componentes/camera_zone.tscn`.
- Aspecto de cada época: `render/epoca_presente.tres` y `epoca_pasado.tres`.

### 3.5. Movimiento de Elías

`juego/jugador/movimiento_presente.tres` y `movimiento_pasado.tres`: velocidades, aceleración y si puede agacharse. En el nodo `Jugador` de `jugador.tscn`: ruido de los pasos y aguante de la carrera en el presente.

### 3.6. Cinemáticas

En el script del nivel:

```gdscript
empezar_cinematica()                    # quita el control y pone las bandas 2.39:1
plano($Camaras/MiPlano)                 # corte a una cámara del nivel
await espera(2.0)                       # se acorta si el jugador mantiene E
await decir("Policía", "¡Alto!", 2.0)   # subtítulo + espera
terminar_cinematica()                   # devuelve el control
```

Las cámaras de cada nivel están en su nodo `Camaras`. Se pueden mover en el editor.

## 4. Construir o regenerar

| Qué | Cómo |
|---|---|
| Modelos y escenarios de Blender → Godot | `blender --background --factory-startup --python assets/scripts/exportar_godot.py` (ver `assets/LEEME.md`) |
| Sonido (125 sonidos procedurales) | `python assets/scripts/generar_audio.py` (o solo algunos: `... generar_audio.py lluvia silbato`) |
| Niveles | `Godot --headless --path juego --script res://herramientas/construir_niveles.gd -- cap1 f1 …` |
| Configuración del proyecto, controles y autoloads | `Godot --headless --path juego --script res://herramientas/configurar_proyecto.gd` |
| Comprobar que todos los scripts compilan | `Godot --headless --path juego --script res://herramientas/comprobar_scripts.gd` |
| Prueba automática de la demo entera | `Godot --path juego -- --prueba-demo=C:/carpeta` (deja `prueba.txt` y capturas) |
| Que un nivel se pueda recorrer a pie | `Godot --path juego -- --nivel=cap2 "--prueba-camino=C:/carpeta|Interactivos/Fusible1|Interactivos/EscaleraBajar"` (deja `camino.txt` y capturas). La prueba de la demo teletransporta y no detecta sitios inalcanzables |
| Dificultad de la huida de F1 | `Godot --path juego -- --nivel=f1 "--prueba-huida=C:/carpeta|normal"` (deja `huida_normal.txt` con el margen y capturas) |

**Atención**: los constructores de niveles **sobrescriben** el `.tscn`. Si se retoca un nivel a mano en el editor, ya no hay que regenerarlo, o hay que llevar los cambios también a su constructor (`juego/herramientas/niveles/construir_<id>.gd`).

Después de añadir clases nuevas (`class_name`) o archivos importados, abrir el editor una vez o ejecutar `Godot --headless --path juego --import`.

## 5. Reglas del proyecto

1. **Registrar** todo recurso externo, lo hecho con IA (`Materiales/recursos_y_creditos.md`) y toda herramienta instalada (`herramientas_instaladas.md`).
2. Nada de licencias no comerciales ni de pago. CC BY solo citando al autor.
3. No mover a mano la cámara de `RenderRig`: se mueven las cámaras virtuales.
4. Nombres en español y descriptivos.
5. Sin commits automáticos: el equipo sube el proyecto con `docs/SUBIR_A_GITHUB.md`.

## 6. Añadir las voces grabadas (V-01 a V-11)

1. Guardar cada voz en `juego/assets/audio/` (`.ogg` o `.wav`) con un nombre claro, por ejemplo `voz_interrogador_1.ogg`.
2. Donde se muestra la línea (`decir(...)` en el script del nivel o `Interfaz.subtitulo(...)`), añadir justo antes `Audio.efecto(&"voz_interrogador_1", 0.0, 1.0, &"Voces")`.
3. Ajustar los segundos de la línea en `datos/guion.gd` para que coincidan con la grabación.

## 7. Capas de física y render

Física: 1 mundo · 2 jugador · 3 enemigos · 4 interactuables · 5 zonas · 6 bloqueo de visión.
Render: 1 general · 11 «solo_espejo» (lo que solo se ve en los espejos, como El Condenado).
