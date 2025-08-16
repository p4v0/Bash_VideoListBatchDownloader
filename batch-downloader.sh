#!/bin/bash

#----------------------------------------------------------------
# Script para descargar videos en lote usando yt-dlp
# 
# Descripción:
#   Lee un archivo de texto con URLs (una por línea) y descarga
#   cada video usando yt-dlp. Los archivos se numeran secuencialmente
#   según el orden en la lista.
#
# Uso:
#   ./batch-downloader.sh <archivo_urls.txt> <carpeta_de_salida>
#
# Características:
#   - Valida e instala automáticamente dependencias (yt-dlp, ffmpeg)
#   - Convierte rutas de Windows a formato WSL automáticamente
#   - Crea la carpeta de salida si no existe
#   - Nombra archivos con numeración secuencial
#   - Manejo de errores con terminación inmediata
#   - Evita sobrescribir archivos existentes (--no-overwrites)
#   - Continúa descargas parciales interrumpidas (--continue)
#
# Dependencias:
#   - yt-dlp: Herramienta principal para descarga de videos
#   - ffmpeg: Procesamiento de audio/video (requerido por yt-dlp)
#----------------------------------------------------------------

# strict error handling. El script termina si cualquier comando en él da error.
set -e

# --- Función para convertir rutas de Windows a WSL ---
convert_path() {
    local path="$1"
    # Si empieza con letra + :\
    if [[ "$path" =~ ^([A-Za-z]):\\ ]]; then
        drive_letter=$(echo "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]')
        # Quitar "X:\" del inicio y reemplazar "\" por "/"
        local_path=$(echo "$path" | sed -E 's#^[A-Za-z]:##' | tr '\\' '/')
        echo "/mnt/${drive_letter}${local_path}"
    else
        echo "$path"
    fi

}

# --- Instalar dependencias si faltan ---
check_dependencies() {
    # yt-dlp
    if ! command -v yt-dlp &>/dev/null; then
        echo "⚙️ yt-dlp no encontrado, instalando..."
        # bloque if para no mostrar stdout (2>&1) pero sí mostrar stderr si hay algun error con un comando.
        if ! (sudo apt update -y >/dev/null 2>&1 && \
              sudo apt install wget -y >/dev/null 2>&1 && \
              sudo wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -O /usr/local/bin/yt-dlp >/dev/null 2>&1 && \
              sudo chmod a+rx /usr/local/bin/yt-dlp); then
            echo "❌ Error instalando yt-dlp, mostrando salida completa:"
            sudo apt update -y && sudo apt install wget -y && \
            sudo wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -O /usr/local/bin/yt-dlp && \
            sudo chmod a+rx /usr/local/bin/yt-dlp
        fi
    fi

    # ffmpeg
    if ! command -v ffmpeg &>/dev/null; then
        echo "⚙️ ffmpeg no encontrado, instalando..."
        # bloque if para no mostrar stdout (2>&1) pero sí mostrar stderr si hay algun error con un comando.
        if ! (sudo apt update -y >/dev/null 2>&1 && \
              sudo apt install ffmpeg -y >/dev/null 2>&1); then
            echo "❌ Error instalando ffmpeg, mostrando salida completa:"
            sudo apt update -y && sudo apt install ffmpeg -y
        fi
    fi
}

# --- Validación de argumentos de entrada ---
if [ $# -ne 2 ]; then
    echo "Uso: $0 <ruta_lista_urls.txt> <carpeta_salida>"
    exit 1
fi

input_file=$(convert_path "$1")
output_dir=$(convert_path "$2")

# validación archivo con lista de URLs
if [ ! -f "$input_file" ]; then
    echo "Error: el archivo de entrada no existe -> $input_file"
    exit 1
fi

# Verificar e instalar dependencias
check_dependencies

# si la carpeta de salida no existe, crearla. Sino, solo usarla
mkdir -p "$output_dir"

# --- Procesar URLs con numeración manual ---
count=1
    # || [[ -n $url ]] es para procesar la última línea si no tiene salto de línea
while IFS= read -r url || [[ -n $url ]]; do
    # Eliminar posible CR al final (por archivos CRLF de Windows)
    url="${url%$'\r'}"
    # Para cada URL válida
    if [[ "$url" =~ ^https?:// ]]; then
        echo "📥 Descargando ($count): $url"
        # Ejecutar en modo silencioso (2>&1 no muestra stdout en la cli), pero si falla se ejecuta el mismo comando sin filtrar la salida para ver el error
        if ! yt-dlp --no-overwrites --continue -o "$output_dir/${count}.%(title)s[%(id)s].%(ext)s" "$url" >/dev/null 2>&1 ; then 
            echo "❌ Error al descargar: $url"
            echo "Mostrando salida completa:"
            yt-dlp --no-overwrites --continue -o "$output_dir/${count}.%(title)s[%(id)s].%(ext)s" "$url"
        fi

        # Validar si realmente se generó un archivo con el prefijo correspondiente
        downloaded_file=$(find "$output_dir" -maxdepth 1 -type f -name "${count}.*" | head -n1)
        if [[ -n "$downloaded_file" ]]; then
            echo "✅ Descargado ($count): $downloaded_file"
        else
            echo "❌ No se generó archivo para: $url"
        fi
    else
        echo "⚠️ Ignorando línea no válida ($count): $url"							  
    fi

    # aumenta contador (se válido o no la URL para numerar en el orden de las líneas)
    count=$((count+1))

# Fin de lectura de archivo, entrega el archivo al proceso de lectura (while)																			 
done < <(tr -d '\r' < "$input_file")



echo "✅ Descargas completadas en: $output_dir"

