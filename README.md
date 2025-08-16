# VideoListDownloader

Script Bash para descargar videos en lote usando [yt-dlp](https://github.com/yt-dlp/yt-dlp) y [ffmpeg](https://ffmpeg.org/).

## Características

- Descarga videos desde una lista de URLs (archivo de texto, una URL por línea).
- Nombra los archivos descargados con numeración secuencial y metadatos.
- Instala automáticamente las dependencias necesarias (yt-dlp, ffmpeg) en sistemas basados en Debian/Ubuntu.
- Convierte rutas de Windows a formato WSL automáticamente.
- Evita sobrescribir archivos existentes y permite continuar descargas interrumpidas.
- Manejo de errores y validación de URLs.

## Requisitos

- Bash (WSL recomendado en Windows)
- Permisos de sudo para instalar dependencias
- Acceso a Internet

## Instalación

No requiere instalación. Solo descarga el script `batch-downloader.sh`.

## Uso

```bash
./batch-downloader.sh <archivo_urls.txt> <carpeta_de_salida>
```

- `<archivo_urls.txt>`: Archivo de texto con una URL de video por línea.
- `<carpeta_de_salida>`: Carpeta donde se guardarán los videos descargados.

Ejemplo:

```bash
./batch-downloader.sh lista.txt videos/
```

## Ejemplo de archivo de URLs

```
https://www.youtube.com/watch?v=abc123
https://vimeo.com/123456
```

## Salida

Los archivos descargados se guardan en la carpeta especificada, con nombres como:

```
1.TítuloDelVideo[abc123].mp4
2.TítuloDelVideo[123456].mp4
```

## Notas

- El script valida e instala automáticamente yt-dlp y ffmpeg si no están presentes.
- Las rutas de Windows se convierten automáticamente a formato WSL.
- Si una URL no es válida, se ignora y se muestra una advertencia.

## Licencia

MIT
