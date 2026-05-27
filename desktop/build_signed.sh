#!/bin/bash
set -e
cd /home/Projects/parla/desktop

PASS_FILE="/home/marc/Escritorio/MARC/CONTRASENYES/CONTRASENYES/miloro_signing_key.txt"
KEY_FILE="$HOME/.tauri/miloro-update.key"

if [ ! -f "$KEY_FILE" ]; then
  echo "ERROR: no existe $KEY_FILE" >&2
  exit 1
fi
if [ ! -f "$PASS_FILE" ]; then
  echo "ERROR: no existe $PASS_FILE" >&2
  exit 1
fi

export TAURI_SIGNING_PRIVATE_KEY=$(cat "$KEY_FILE")
export TAURI_SIGNING_PRIVATE_KEY_PASSWORD=$(cat "$PASS_FILE")

echo "=== Build firmado MiLoro ==="
npm run tauri:build

echo ""
echo "=== Output bundle ==="
ls -la src-tauri/target/release/bundle/appimage/ 2>/dev/null || echo "(no se encontró bundle/appimage)"
