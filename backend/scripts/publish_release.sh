#!/bin/bash
# Master script: publica una nueva versión MiLoro END-TO-END.
#
# Marc ejecuta UN solo comando:
#   ./scripts/load_secrets.sh ./scripts/publish_release.sh <version> [--notes='markdown']
#
# Hace en orden:
#   1. Bumpea la versión en tauri.conf.json + Cargo.toml + package.json
#   2. Build firmado (./desktop/build_signed.sh) → AppImage + .sig
#   3. Upload AppImage.tar.gz al bucket R2 'miloro-releases'
#   4. Publish manifest a KV MILORO_UPDATES (canal stable)
#   5. Smoke test endpoint updater
#
# Requisitos previos:
#   - /home/marc/.secrets/miloro_r2_public_base con URL pública R2 (configurada en setup_r2_releases.sh)
#   - /home/marc/.secrets/cf_api_token con D1+KV+R2+Workers permission
#   - ~/.tauri/miloro-update.key + password en /home/marc/Escritorio/MARC/.../miloro_signing_key.txt

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Uso: $0 <version> [--notes='markdown release notes'] [--skip-build] [--skip-upload]" >&2
  exit 2
fi

VERSION="$1"
shift

NOTES="Bug fixes and improvements"
SKIP_BUILD=0
SKIP_UPLOAD=0
for arg in "$@"; do
  case "$arg" in
    --notes=*)     NOTES="${arg#*=}" ;;
    --skip-build)  SKIP_BUILD=1 ;;
    --skip-upload) SKIP_UPLOAD=1 ;;
    *) echo "Flag desconocida: $arg" >&2; exit 2 ;;
  esac
done

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
  echo "ERROR: version invalida '$VERSION' — esperaba semver X.Y.Z" >&2
  exit 2
fi

# Cargar R2 base URL
R2_BASE_FILE="/home/marc/.secrets/miloro_r2_public_base"
if [ ! -r "$R2_BASE_FILE" ]; then
  echo "ERROR: falta $R2_BASE_FILE" >&2
  echo "Ejecuta primero: ./scripts/load_secrets.sh ./scripts/setup_r2_releases.sh" >&2
  echo "y sigue las instrucciones del dashboard CF para crear el archivo." >&2
  exit 1
fi
R2_PUBLIC_BASE="$(cat "$R2_BASE_FILE" | tr -d '\n\r ' | sed 's|/$||')"
echo "R2 public base: $R2_PUBLIC_BASE"

BACKEND_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DESKTOP_DIR="$BACKEND_DIR/../desktop"
TAURI_CONF="$DESKTOP_DIR/src-tauri/tauri.conf.json"
CARGO_TOML="$DESKTOP_DIR/src-tauri/Cargo.toml"
PACKAGE_JSON="$DESKTOP_DIR/package.json"
# Tauri v2 Linux: AppImage directo (NO .tar.gz como en v1) + .sig correspondiente.
APPIMAGE="$DESKTOP_DIR/src-tauri/target/release/bundle/appimage/MiLoro_${VERSION}_amd64.AppImage"
APPIMAGE_SIG="$APPIMAGE.sig"

echo ""
echo "============================="
echo "  Publicar MiLoro v$VERSION"
echo "============================="

# --- 1. Bump version en los 3 archivos ---
echo ""
echo "--- 1. Bump version $VERSION ---"

# tauri.conf.json
python3 -c "
import json, sys
with open('$TAURI_CONF') as f: d = json.load(f)
d['version'] = '$VERSION'
with open('$TAURI_CONF', 'w') as f: json.dump(d, f, indent=2)
print('  tauri.conf.json -> $VERSION')
"

# Cargo.toml: linea 'version = \"...\"' bajo [package]
sed -i.bak -E "s|^version = \"[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?\"|version = \"$VERSION\"|" "$CARGO_TOML"
echo "  Cargo.toml -> $VERSION"

# package.json
python3 -c "
import json
with open('$PACKAGE_JSON') as f: d = json.load(f)
d['version'] = '$VERSION'
with open('$PACKAGE_JSON', 'w') as f:
    json.dump(d, f, indent=2)
    f.write('\n')
print('  package.json -> $VERSION')
"

# --- 2. Build firmado ---
if [ "$SKIP_BUILD" = "1" ]; then
  echo ""
  echo "[skip] build (--skip-build)"
else
  echo ""
  echo "--- 2. Build firmado MiLoro $VERSION (puede tardar 1-5 min) ---"
  (cd "$DESKTOP_DIR" && ./build_signed.sh)
fi

if [ ! -f "$APPIMAGE" ]; then
  echo "ERROR: no se generó $APPIMAGE" >&2
  exit 1
fi
if [ ! -f "$APPIMAGE_SIG" ]; then
  echo "ERROR: no se generó $APPIMAGE_SIG (build sin signing key?)" >&2
  exit 1
fi
SIG_CONTENT="$(cat "$APPIMAGE_SIG")"
echo ""
echo "Artifacts:"
echo "  $APPIMAGE ($(du -h "$APPIMAGE" | cut -f1))"
echo "  $APPIMAGE_SIG  ($(wc -c < "$APPIMAGE_SIG") bytes)"

# --- 3. Upload a R2 ---
if [ "$SKIP_UPLOAD" = "1" ]; then
  echo ""
  echo "[skip] upload R2 (--skip-upload)"
else
  echo ""
  echo "--- 3. Upload AppImage a R2 ---"
  R2_KEY="v$VERSION/MiLoro_${VERSION}_amd64.AppImage"

  # Prefiere rclone si está instalado + configurado (multipart auto + retry, robusto con red doméstica).
  # Fallback wrangler r2 object put (funciona pero falla con archivos >50MB intermitentemente).
  if command -v rclone >/dev/null 2>&1 && [ -n "${R2_ACCESS_KEY_ID:-}" ]; then
    echo "  usando rclone (multipart auto + retry)..."
    # --s3-no-check-bucket: tokens R2 restringidos a un bucket fallan al verificar
    # existencia previa al PUT (necesitan ListBucket en todos los buckets, no solo el target).
    RCLONE_FLAGS="--s3-no-check-bucket --retries 3 --low-level-retries 5"
    rclone copyto "$APPIMAGE"     "r2:miloro-releases/$R2_KEY"      --progress $RCLONE_FLAGS
    rclone copyto "$APPIMAGE_SIG" "r2:miloro-releases/${R2_KEY}.sig" $RCLONE_FLAGS
  else
    echo "  usando wrangler (rclone no disponible / R2 keys no configuradas)..."
    wrangler r2 object put "miloro-releases/$R2_KEY"     --file="$APPIMAGE"     --remote
    wrangler r2 object put "miloro-releases/${R2_KEY}.sig" --file="$APPIMAGE_SIG" --remote
  fi
  echo "  OK subido a r2://miloro-releases/$R2_KEY"
fi

LINUX_URL="$R2_PUBLIC_BASE/v$VERSION/MiLoro_${VERSION}_amd64.AppImage"

# --- 4. Publicar manifest ---
echo ""
echo "--- 4. Publicar manifest stable a KV MILORO_UPDATES ---"
"$BACKEND_DIR/scripts/release_update.sh" stable "$VERSION" \
  --linux-url="$LINUX_URL" \
  --linux-sig="$SIG_CONTENT" \
  --notes="$NOTES"

# --- 5. Smoke test ---
echo ""
echo "--- 5. Smoke test endpoint updater (con version vieja 0.0.1) ---"
RESP=$(curl -sS https://miloro.app/api/updater/linux-x86_64/0.0.1)
echo "$RESP" | python3 -m json.tool 2>/dev/null || echo "$RESP"

echo ""
echo "============================="
echo "  Release $VERSION PUBLICADA"
echo "============================="
echo ""
echo "Tu app instalada (cualquier version < $VERSION) detectará el update"
echo "al próximo arranque (autoUpdate=ON) o al click 'Buscar actualizaciones'."
echo ""
echo "Download URL pública: $LINUX_URL"
