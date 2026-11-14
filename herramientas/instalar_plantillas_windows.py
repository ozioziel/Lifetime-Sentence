"""Instala las plantillas de exportación de Windows de Godot 4.7.2.

Las plantillas son los archivos que Godot necesita para generar el .exe del
juego. El paquete oficial completo pesa más de 1 GB porque incluye todas las
plataformas; este script descarga solo los archivos de Windows de 64 bits
leyendo el paquete por partes, sin bajarlo entero.

Origen (oficial): https://github.com/godotengine/godot/releases
Destino: %APPDATA%\\Godot\\export_templates\\4.7.2.stable\\

Uso:
    python herramientas\\instalar_plantillas_windows.py

Alternativa manual: en el editor de Godot, Editor > Administrar plantillas de
exportación > Descargar e instalar (baja el paquete completo).

Solo usa la biblioteca estándar de Python. Licencia de las plantillas: MIT.
"""
import io
import os
import sys
import urllib.error
import urllib.request
import zipfile

VERSION = "4.7.2"
ETIQUETA = f"{VERSION}-stable"
URL = (f"https://github.com/godotengine/godot/releases/download/{ETIQUETA}/"
       f"Godot_v{ETIQUETA}_export_templates.tpz")
DESTINO = os.path.join(os.environ["APPDATA"], "Godot", "export_templates", f"{VERSION}.stable")
NECESARIOS = (
    "version.txt",
    "windows_release_x86_64.exe",
    "windows_release_x86_64_console.exe",
    "windows_debug_x86_64.exe",
    "windows_debug_x86_64_console.exe",
)
AGENTE = {"User-Agent": "python-urllib"}


class ArchivoRemoto(io.RawIOBase):
    """Archivo de solo lectura que pide por HTTP únicamente los trozos que se leen."""

    def __init__(self, url: str) -> None:
        self._origen = url
        self._posicion = 0
        self.descargado = 0
        self._resolver()

    def _resolver(self) -> None:
        peticion = urllib.request.Request(self._origen, method="HEAD", headers=AGENTE)
        with urllib.request.urlopen(peticion, timeout=60) as respuesta:
            self._url = respuesta.geturl()
            self.tamano = int(respuesta.headers["Content-Length"])

    def seekable(self) -> bool:
        return True

    def readable(self) -> bool:
        return True

    def tell(self) -> int:
        return self._posicion

    def seek(self, desplazamiento: int, desde: int = io.SEEK_SET) -> int:
        if desde == io.SEEK_SET:
            self._posicion = desplazamiento
        elif desde == io.SEEK_CUR:
            self._posicion += desplazamiento
        else:
            self._posicion = self.tamano + desplazamiento
        return self._posicion

    def readinto(self, destino) -> int:
        cantidad = min(len(destino), self.tamano - self._posicion)
        if cantidad <= 0:
            return 0
        rango = {"Range": f"bytes={self._posicion}-{self._posicion + cantidad - 1}", **AGENTE}
        for intento in range(4):
            try:
                peticion = urllib.request.Request(self._url, headers=rango)
                with urllib.request.urlopen(peticion, timeout=120) as respuesta:
                    datos = respuesta.read()
                break
            except (urllib.error.URLError, TimeoutError, ConnectionError):
                if intento == 3:
                    raise
                self._resolver()  # El enlace temporal caduca: se pide uno nuevo.
        destino[:len(datos)] = datos
        self._posicion += len(datos)
        self.descargado += len(datos)
        return len(datos)


def main() -> int:
    print(f"Paquete oficial: {URL}")
    remoto = ArchivoRemoto(URL)
    print(f"Tamaño del paquete completo: {remoto.tamano / 1e6:.0f} MB (no se descarga entero)")
    os.makedirs(DESTINO, exist_ok=True)
    with zipfile.ZipFile(io.BufferedReader(remoto, buffer_size=8 * 1024 * 1024)) as paquete:
        por_nombre = {os.path.basename(i.filename): i for i in paquete.infolist()}
        faltan = [n for n in NECESARIOS if n not in por_nombre]
        if faltan:
            print("ERROR: el paquete no contiene:", ", ".join(faltan))
            print("Archivos de Windows disponibles:",
                  ", ".join(sorted(n for n in por_nombre if n.startswith("windows"))))
            return 1
        for nombre in NECESARIOS:
            info = por_nombre[nombre]
            ruta = os.path.join(DESTINO, nombre)
            print(f"  {nombre}  ({info.file_size / 1e6:.1f} MB)...", flush=True)
            with paquete.open(info) as origen, open(ruta + ".parcial", "wb") as salida:
                while True:
                    bloque = origen.read(1024 * 1024)
                    if not bloque:
                        break
                    salida.write(bloque)
            os.replace(ruta + ".parcial", ruta)
    print(f"Descargado en total: {remoto.descargado / 1e6:.0f} MB")
    print(f"Plantillas de Windows instaladas en: {DESTINO}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
