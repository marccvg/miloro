#!/bin/bash
# Instala MiLoro AppImage + icono + .desktop en el usuario actual.
# Hace que la app aparezca en el menú GNOME, que notify-send muestre el icono loro,
# y que se pueda lanzar con dos clicks.
#
# Marc ejecuta:
#   ./install_local_user.sh
#
# Idempotente. Sin sudo. Solo escribe en ~/.local/.

set -euo pipefail

DESKTOP_DIR="$(cd "$(dirname "$0")" && pwd)"
ICON_SRC_DIR="$DESKTOP_DIR/../brand"
BUNDLE_DIR="$DESKTOP_DIR/src-tauri/target/release/bundle/appimage"

# Auto-detecta la AppImage más reciente (por mtime). Override con MILORO_VERSION=X.Y.Z si quieres una específica.
if [ -n "${MILORO_VERSION:-}" ]; then
  APPIMAGE_SRC="$BUNDLE_DIR/MiLoro_${MILORO_VERSION}_amd64.AppImage"
else
  APPIMAGE_SRC=$(ls -t "$BUNDLE_DIR"/MiLoro_*_amd64.AppImage 2>/dev/null | head -1)
fi

# Destinos en home
APP_INSTALL_DIR="$HOME/.local/bin"
ICON_INSTALL_DIR="$HOME/.local/share/icons/hicolor"
DESKTOP_INSTALL_DIR="$HOME/.local/share/applications"

# Verificar artifacts
if [ -z "$APPIMAGE_SRC" ] || [ ! -f "$APPIMAGE_SRC" ]; then
  echo "ERROR: no encuentro ningun AppImage en $BUNDLE_DIR" >&2
  echo "Ejecuta primero: cd $DESKTOP_DIR && ./build_signed.sh" >&2
  exit 1
fi
echo "Usando AppImage: $(basename "$APPIMAGE_SRC")"

# Crear directorios destino
mkdir -p "$APP_INSTALL_DIR" "$DESKTOP_INSTALL_DIR"

# Instalar AppImage
APP_DEST="$APP_INSTALL_DIR/MiLoro.AppImage"
cp "$APPIMAGE_SRC" "$APP_DEST"
chmod +x "$APP_DEST"
echo "OK AppImage instalada: $APP_DEST"

# Instalar iconos en jerarquía hicolor (estándar XDG)
for size in 16 32 48 64 128 256 512; do
  icon_src="$ICON_SRC_DIR/miloro-icon-${size}.png"
  if [ -f "$icon_src" ]; then
    icon_dest_dir="$ICON_INSTALL_DIR/${size}x${size}/apps"
    mkdir -p "$icon_dest_dir"
    cp "$icon_src" "$icon_dest_dir/miloro.png"
  fi
done
echo "OK Iconos instalados en $ICON_INSTALL_DIR"

# Generar .desktop file apuntando al AppImage real
DESKTOP_FILE="$DESKTOP_INSTALL_DIR/MiLoro.desktop"
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=MiLoro
GenericName=Dictado por voz local
Comment=Transcripción de voz 100% local con Whisper
Exec=$APP_DEST
Icon=miloro
Terminal=false
Categories=Utility;AudioVideo;Office;
Keywords=voice;speech;transcribe;whisper;dictation;
StartupWMClass=miloro-desktop
StartupNotify=true
EOF
chmod +x "$DESKTOP_FILE"
echo "OK Desktop file: $DESKTOP_FILE"

# Refrescar caches XDG (puede tardar 2-3s)
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$DESKTOP_INSTALL_DIR" 2>/dev/null || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache "$ICON_INSTALL_DIR" 2>/dev/null || true
fi

echo ""
echo "============================="
echo "  MiLoro instalada localmente"
echo "============================="
echo ""
echo "Lanzar la app:"
echo "  - Buscar 'MiLoro' en el menú de aplicaciones GNOME"
echo "  - O ejecutar:  $APP_DEST"
echo ""
echo "El icono loro aparecera tambien en notify-send de los scripts oido_*."
echo ""
echo "Para desinstalar:"
echo "  rm $APP_DEST $DESKTOP_FILE"
echo "  rm $ICON_INSTALL_DIR/*/apps/miloro.png"
