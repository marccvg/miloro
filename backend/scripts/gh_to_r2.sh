#!/bin/bash
# gh_to_r2.sh — Sincroniza un GitHub release a R2 + publica manifest KV stable.
#
# Workflow target: tras `git tag v0.X.Y && git push origin v0.X.Y`, GitHub Actions
# (.github/workflows/build.yml) construye Linux + Win + Mac y crea Release con assets.
# Este script descarga esos assets, los sube a R2 con rclone, y publica el manifest
# stable apuntando a las URLs R2.
#
# Marc ejecuta UN solo comando tras GitHub Actions termine:
#   ./scripts/load_secrets.sh ./scripts/gh_to_r2.sh v0.0.10 [--notes='markdown']
#
# Requisitos:
#   - gh CLI (https://cli.github.com) autenticado con repo MiLoro
#   - rclone configurado con remote r2 (ya OK)
#   - CLOUDFLARE_API_TOKEN para wrangler kv put

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Uso: $0 <tag> [--notes='markdown']" >&2
  echo "Ej:  $0 v0.0.10 --notes='Nuevo: feature X'" >&2
  exit 2
fi

TAG="$1"
shift
VERSION="${TAG#v}"

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
  echo "ERROR: tag '$TAG' no es semver vX.Y.Z" >&2
  exit 2
fi

NOTES=""
for arg in "$@"; do
  case "$arg" in
    --notes=*) NOTES="${arg#*=}" ;;
    *) echo "Flag desconocida: $arg" >&2; exit 2 ;;
  esac
done

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI no instalado. sudo apt install gh + gh auth login" >&2
  exit 1
fi

R2_BASE_FILE="/home/marc/.secrets/miloro_r2_public_base"
if [ ! -r "$R2_BASE_FILE" ]; then
  echo "ERROR: falta $R2_BASE_FILE" >&2
  exit 1
fi
R2_PUBLIC_BASE="$(cat "$R2_BASE_FILE" | tr -d '\n\r ' | sed 's|/$||')"

BACKEND_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKDIR=$(mktemp -d /tmp/miloro-gh-$TAG-XXXXXX)
trap "rm -rf $WORKDIR" EXIT

echo "============================="
echo "  Sync GitHub $TAG → R2 → KV"
echo "============================="

# --- 1. Descargar todos los assets del release ---
echo ""
echo "--- 1. Descargar release $TAG de GitHub ---"
gh release download "$TAG" -D "$WORKDIR"
ls -lh "$WORKDIR" | head -20

# --- 2. Identificar archivos por platform ---
# Tauri 2 outputs typical names:
#   Linux:   MiLoro_X.Y.Z_amd64.AppImage + .sig + .deb + .rpm
#   Windows: MiLoro_X.Y.Z_x64-setup.exe + .sig + .msi + .sig
#   macOS:   MiLoro_X.Y.Z_universal.dmg + .app.tar.gz + .sig (Intel + ARM)

find_asset() {
  # find_asset <glob_pattern>
  find "$WORKDIR" -name "$1" -type f 2>/dev/null | head -1
}

LINUX_APPIMAGE=$(find_asset "MiLoro_${VERSION}_amd64.AppImage")
LINUX_SIG=$(find_asset "MiLoro_${VERSION}_amd64.AppImage.sig")

WIN_NSIS=$(find_asset "MiLoro_${VERSION}_x64-setup.exe")
WIN_NSIS_SIG=$(find_asset "MiLoro_${VERSION}_x64-setup.exe.sig")
# Si NSIS no, intentar MSI:
[ -z "$WIN_NSIS" ] && WIN_NSIS=$(find_asset "MiLoro_${VERSION}_x64_en-US.msi")
[ -z "$WIN_NSIS_SIG" ] && WIN_NSIS_SIG=$(find_asset "MiLoro_${VERSION}_x64_en-US.msi.sig")

MAC_X86_TARGZ=$(find_asset "MiLoro_x86_64.app.tar.gz")
MAC_X86_SIG=$(find_asset "MiLoro_x86_64.app.tar.gz.sig")
MAC_ARM_TARGZ=$(find_asset "MiLoro_aarch64.app.tar.gz")
MAC_ARM_SIG=$(find_asset "MiLoro_aarch64.app.tar.gz.sig")

echo ""
echo "Assets detectados:"
[ -n "$LINUX_APPIMAGE" ]  && echo "  ✓ Linux x86_64:   $(basename "$LINUX_APPIMAGE")" || echo "  ✗ Linux x86_64:   NO encontrado"
[ -n "$WIN_NSIS" ]        && echo "  ✓ Windows x86_64: $(basename "$WIN_NSIS")"       || echo "  ✗ Windows x86_64: NO encontrado"
[ -n "$MAC_X86_TARGZ" ]   && echo "  ✓ macOS x86_64:   $(basename "$MAC_X86_TARGZ")"  || echo "  ✗ macOS x86_64:   NO encontrado"
[ -n "$MAC_ARM_TARGZ" ]   && echo "  ✓ macOS aarch64:  $(basename "$MAC_ARM_TARGZ")"  || echo "  ✗ macOS aarch64:  NO encontrado"

if [ -z "$LINUX_APPIMAGE" ] && [ -z "$WIN_NSIS" ] && [ -z "$MAC_X86_TARGZ" ] && [ -z "$MAC_ARM_TARGZ" ]; then
  echo "ERROR: 0 assets encontrados. ¿GitHub Actions completó OK?" >&2
  exit 1
fi

# --- 3. Subir a R2 con rclone ---
echo ""
echo "--- 3. Upload assets a R2 ---"
RCLONE_FLAGS="--s3-no-check-bucket --retries 3 --low-level-retries 5 --progress"
upload() {
  local src="$1"
  local r2_path="$2"
  if [ -n "$src" ] && [ -f "$src" ]; then
    rclone copyto "$src" "r2:miloro-releases/$r2_path" $RCLONE_FLAGS
  fi
}

upload "$LINUX_APPIMAGE"  "v$VERSION/$(basename "$LINUX_APPIMAGE")"
upload "$LINUX_SIG"       "v$VERSION/$(basename "$LINUX_SIG")"
upload "$WIN_NSIS"        "v$VERSION/$(basename "$WIN_NSIS")"
upload "$WIN_NSIS_SIG"    "v$VERSION/$(basename "$WIN_NSIS_SIG")"
upload "$MAC_X86_TARGZ"   "v$VERSION/$(basename "$MAC_X86_TARGZ")"
upload "$MAC_X86_SIG"     "v$VERSION/$(basename "$MAC_X86_SIG")"
upload "$MAC_ARM_TARGZ"   "v$VERSION/$(basename "$MAC_ARM_TARGZ")"
upload "$MAC_ARM_SIG"     "v$VERSION/$(basename "$MAC_ARM_SIG")"

# --- 4. Construir args release_update.sh ---
echo ""
echo "--- 4. Publicar manifest stable (todas las platforms disponibles) ---"
ARGS=()
[ -n "$LINUX_APPIMAGE" ] && {
  ARGS+=("--linux-url=$R2_PUBLIC_BASE/v$VERSION/$(basename "$LINUX_APPIMAGE")")
  ARGS+=("--linux-sig=$(cat "$LINUX_SIG")")
}
[ -n "$WIN_NSIS" ] && [ -n "$WIN_NSIS_SIG" ] && {
  ARGS+=("--windows-url=$R2_PUBLIC_BASE/v$VERSION/$(basename "$WIN_NSIS")")
  ARGS+=("--windows-sig=$(cat "$WIN_NSIS_SIG")")
}
[ -n "$MAC_X86_TARGZ" ] && [ -n "$MAC_X86_SIG" ] && {
  ARGS+=("--darwin-x86-url=$R2_PUBLIC_BASE/v$VERSION/$(basename "$MAC_X86_TARGZ")")
  ARGS+=("--darwin-x86-sig=$(cat "$MAC_X86_SIG")")
}
[ -n "$MAC_ARM_TARGZ" ] && [ -n "$MAC_ARM_SIG" ] && {
  ARGS+=("--darwin-arm-url=$R2_PUBLIC_BASE/v$VERSION/$(basename "$MAC_ARM_TARGZ")")
  ARGS+=("--darwin-arm-sig=$(cat "$MAC_ARM_SIG")")
}
[ -n "$NOTES" ] && ARGS+=("--notes=$NOTES")

"$BACKEND_DIR/scripts/release_update.sh" stable "$VERSION" "${ARGS[@]}"

# --- 5. Smoke test ---
echo ""
echo "--- 5. Smoke test endpoints ---"
echo "[updater linux-x86_64 con version vieja]"
curl -sS "https://miloro.app/api/updater/linux-x86_64/0.0.1" | python3 -m json.tool 2>/dev/null | head -8 || true
echo ""
echo "[download linux 302]"
curl -sS -o /dev/null -w "HTTP %{http_code}\nLocation: %{redirect_url}\n" "https://miloro.app/api/download/linux"

echo ""
echo "============================="
echo "  $TAG sincronizada GitHub → R2 → KV"
echo "============================="
echo ""
echo "Tus clientes en cualquier OS detectarán $VERSION al próximo arranque (auto-update)."
