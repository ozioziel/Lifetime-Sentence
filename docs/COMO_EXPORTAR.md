# Cómo exportar el juego (Windows)

El juego se exporta a **un único `.exe`** con todos los datos dentro (C-02).

## Desde el editor

1. Abrir `juego/project.godot` con Godot 4.7.2.
2. **Proyecto → Exportar…** → preajuste **«Windows Desktop»** (ya configurado).
3. **Exportar proyecto…** → desmarcar «Exportar con depuración» → guardar como `entregas/LifetimeSentence.exe`.

## Desde la línea de órdenes

```bash
"C:/Users/jojoj/Desktop/ARCADE/Godot_v4.7.2-stable_win64.exe" --headless --path juego --export-release "Windows Desktop" ../entregas/LifetimeSentence.exe
```

## Qué incluye el preajuste

- `.pck` incrustado en el `.exe` (un solo archivo de unos 130 MB).
- Excluye las herramientas de desarrollo (`herramientas/`), la escena de prueba (`niveles/pruebas/`) y el maniquí provisional.
- Nombre, descripción, versión 1.0.0.0 y autores en los metadatos.

## Icono del archivo `.exe`

El juego ya usa `juego/icono.png` como icono de la ventana. Para que el **archivo** `.exe` también lo muestre en el Explorador, Godot necesita **rcedit** (herramienta gratuita de Electron, licencia MIT), que **no está instalada**:

1. Descargar `rcedit-x64.exe` desde su página oficial en GitHub (electron/rcedit).
2. Godot → Editor → Configuración del editor → Exportar → Windows → **rcedit** → ruta al archivo.
3. En el preajuste, activar **Modificar recursos**. El icono ya está asignado (`res://icono.ico`).

Si se instala, anotarlo en `Materiales/herramientas_instaladas.md`.

## Antes de entregar

- Probar el `.exe` en un PC sin Godot (H7).
- `juego/project.godot` y `export_presets.cfg` no deben cambiar sin motivo. Si se cambian controles o autoloads, usar `herramientas/configurar_proyecto.gd` (ver la guía del equipo).
