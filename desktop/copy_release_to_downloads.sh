#!/bin/bash
# Copia AppImage + .sig de una release a ~/Descargas/ para upload manual vía dashboard CF R2.
# Necesario porque el file picker del navegador NO ve /home/Projects/ (pertenece a user claude).
#
# Uso:
#   ./copy_release_to_downloads.sh [version]
# Default version: lee de tauri.conf.json (la actual)

set -e

DESKTOP_DIR="$(cd "$(dirname "$0")" && pwd)"

# Detectar version: arg, o leer de tauri.conf.json
if [ $# -ge 1 ]; then
  VERSION="$1"
else
  VERSION=$(python3 -c "import json; print(json.load(open('$DESKTOP_DIR/src-tauri/tauri.conf.json'))['version'])")
fi

BUNDLE="$DESKTOP_DIR/src-tauri/target/release/bundle/appimage"
APPIMAGE="$BUNDLE/MiLoro_${VERSION}_amd64.AppImage"
SIG="$BUNDLE/MiLoro_${VERSION}_amd64.AppImage.sig"

if [ ! -f "$APPIMAGE" ]; then
  echo "ERROR: no existe $APPIMAGE" >&2
  echo "Build primero: cd $DESKTOP_DIR && ./build_signed.sh" >&2
  exit 1
fi

mkdir -p "$HOME/Descargas"
cp "$APPIMAGE" "$HOME/Descargas/"
cp "$SIG" "$HOME/Descargas/" 2>/dev/null || echo "  (sin .sig — build sin signing key?)"

echo ""
ls -lh "$HOME/Descargas/MiLoro_${VERSION}"*
echo ""
echo "Sube ambos archivos via dashboard:"
echo "  https://dash.cloudflare.com → R2 → miloro-releases → Upload"
echo "  Destination path / prefix: v${VERSION}/"
