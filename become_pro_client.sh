#!/bin/bash
# Orquesta el flow completo para que Marc se convierta en cliente Pro MiLoro.
#
# Marc ejecuta UN solo comando desde el root del repo:
#   ./become_pro_client.sh
#
# Pasos automatizados:
#   1. Instala AppImage + iconos + .desktop en ~/.local/ (sin sudo)
#   2. Emite license Free vía signup público + UPDATE D1 a Pro (3 devices, unlimited)
#   3. Imprime tu license key UUID lista para pegar en la app
#   4. Pregunta si lanzar la app ahora

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "============================="
echo "  MiLoro: Setup cliente Pro"
echo "============================="

# --- 1. Instalar app + .desktop + iconos ---
echo ""
echo "--- 1. Instalar app en ~/.local/ ---"
cd "$REPO_ROOT/desktop"
./install_local_user.sh

# --- 2. Emitir + upgrade license ---
echo ""
echo "--- 2. Emitir license Pro (vía signup público + UPDATE D1) ---"
cd "$REPO_ROOT/backend"

# El promote_to_pro requiere CLOUDFLARE_API_TOKEN (wrangler d1). Carga secrets primero.
./scripts/load_secrets.sh ./scripts/dev_promote_to_pro.sh

echo ""
echo "============================="
echo "  Listo"
echo "============================="
echo ""
echo "Copia la license key de arriba para pegar en la app."
echo ""
read -p "¿Lanzar la app MiLoro ahora? [Y/n] " ANSWER
ANSWER="${ANSWER:-Y}"
case "$ANSWER" in
  Y|y|YES|yes|Yes)
    APPIMAGE="$HOME/.local/bin/MiLoro.AppImage"
    if [ -x "$APPIMAGE" ]; then
      echo "Lanzando $APPIMAGE en background..."
      nohup "$APPIMAGE" >/tmp/miloro-app.log 2>&1 &
      echo "PID: $!"
      echo ""
      echo "Si la app no aparece tras 5s, revisa logs: tail -f /tmp/miloro-app.log"
      echo "Si crash, probablemente conflicto con oido-daemon. Prueba:"
      echo "  systemctl --user stop oido-daemon oido-ptt"
      echo "  $APPIMAGE"
    else
      echo "ERROR: no encuentro $APPIMAGE" >&2
      exit 1
    fi
    ;;
  *)
    echo "OK, lanzala cuando quieras con:"
    echo "  ~/.local/bin/MiLoro.AppImage"
    echo "o desde el menú GNOME → buscar 'MiLoro'."
    ;;
esac
