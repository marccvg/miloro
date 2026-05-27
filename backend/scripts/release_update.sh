#!/bin/bash
# Publica un manifest de release a KV MILORO_UPDATES para que Tauri updater lo sirva.
#
# Uso (Marc):
#   ./scripts/load_secrets.sh ./scripts/release_update.sh <channel> <version> [opciones]
#
# Channel: stable | beta
# Version: semver X.Y.Z (sin prefix 'v')
#
# Opciones (todas opcionales; si una platform no se pasa, no se incluye en el manifest):
#   --linux-url=<url>     --linux-sig=<base64_signature>
#   --windows-url=<url>   --windows-sig=<base64_signature>
#   --darwin-x86-url=<url>      --darwin-x86-sig=<sig>
#   --darwin-arm-url=<url>      --darwin-arm-sig=<sig>
#   --notes='texto markdown release notes'
#   --pub-date=<ISO8601>  (default: now UTC)
#   --dry-run             (imprime manifest sin escribir KV)
#
# Las signatures son el contenido del fichero .sig que Tauri genera junto a cada
# bundle (ej. MiLoro_0.1.0_amd64.AppImage.sig). Sustituir con: $(cat MiLoro_0.1.0_amd64.AppImage.sig)
#
# Ejemplo workflow completo Marc tras publicar GH release:
#   ./scripts/load_secrets.sh ./scripts/release_update.sh stable 0.1.0 \
#     --linux-url='https://github.com/marc/miloro/releases/download/v0.1.0/MiLoro_0.1.0_amd64.AppImage.tar.gz' \
#     --linux-sig="$(cat /home/Projects/parla/desktop/src-tauri/target/release/bundle/appimage/MiLoro_0.1.0_amd64.AppImage.tar.gz.sig)" \
#     --notes='Fix: memory leak Whisper · Feature: vocabulario personalizado'

set -euo pipefail

if [ $# -lt 2 ]; then
  cat <<'EOF' >&2
Uso: release_update.sh <channel> <version> [opciones]

Channel: stable | beta
Version: semver X.Y.Z

Opciones por plataforma (cualquier subset):
  --linux-url=<url>           --linux-sig=<base64>
  --windows-url=<url>         --windows-sig=<base64>
  --darwin-x86-url=<url>      --darwin-x86-sig=<base64>
  --darwin-arm-url=<url>      --darwin-arm-sig=<base64>

  --notes='markdown release notes'
  --pub-date=<ISO8601>   (default: now UTC)
  --dry-run              (no escribir KV)
EOF
  exit 2
fi

CHANNEL="$1"
VERSION="$2"
shift 2

if [ "$CHANNEL" != "stable" ] && [ "$CHANNEL" != "beta" ]; then
  echo "ERROR: channel debe ser 'stable' o 'beta', no '$CHANNEL'" >&2
  exit 2
fi
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
  echo "ERROR: version invalida '$VERSION' — esperaba X.Y.Z" >&2
  exit 2
fi

# Defaults
PUB_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
NOTES=""
DRY=0
declare -A URLS SIGS

for arg in "$@"; do
  case "$arg" in
    --linux-url=*)       URLS[linux-x86_64]="${arg#*=}" ;;
    --linux-sig=*)       SIGS[linux-x86_64]="${arg#*=}" ;;
    --windows-url=*)     URLS[windows-x86_64]="${arg#*=}" ;;
    --windows-sig=*)     SIGS[windows-x86_64]="${arg#*=}" ;;
    --darwin-x86-url=*)  URLS[darwin-x86_64]="${arg#*=}" ;;
    --darwin-x86-sig=*)  SIGS[darwin-x86_64]="${arg#*=}" ;;
    --darwin-arm-url=*)  URLS[darwin-aarch64]="${arg#*=}" ;;
    --darwin-arm-sig=*)  SIGS[darwin-aarch64]="${arg#*=}" ;;
    --notes=*)           NOTES="${arg#*=}" ;;
    --pub-date=*)        PUB_DATE="${arg#*=}" ;;
    --dry-run)           DRY=1 ;;
    *) echo "Flag desconocida: $arg" >&2; exit 2 ;;
  esac
done

# Construir platforms object (solo platforms con URL+SIG)
PLATFORMS_JSON="{}"
for plat in linux-x86_64 windows-x86_64 darwin-x86_64 darwin-aarch64; do
  url="${URLS[$plat]:-}"
  sig="${SIGS[$plat]:-}"
  if [ -n "$url" ] && [ -n "$sig" ]; then
    PLATFORMS_JSON=$(python3 -c "
import sys, json
existing = json.loads(sys.argv[1])
existing['$plat'] = {'url': '$url', 'signature': '''$sig'''}
print(json.dumps(existing))
" "$PLATFORMS_JSON")
  elif [ -n "$url" ] || [ -n "$sig" ]; then
    echo "WARN: $plat tiene solo una de url/sig (necesita ambos para incluirse). Skip." >&2
  fi
done

# Construir manifest final
MANIFEST=$(python3 <<PYEOF
import json
manifest = {
    "version": "$VERSION",
    "pub_date": "$PUB_DATE",
    "notes": """$NOTES""",
    "platforms": $PLATFORMS_JSON,
}
print(json.dumps(manifest, indent=2))
PYEOF
)

echo "=============================" >&2
echo "Manifest channel=$CHANNEL version=$VERSION" >&2
echo "=============================" >&2
echo "$MANIFEST" >&2
echo "" >&2

if [ "$DRY" = "1" ]; then
  echo "[dry-run] manifest NO escrito a KV" >&2
  exit 0
fi

# Validar que el namespace KV está bindeado en wrangler.toml
if ! grep -E '^\[\[kv_namespaces\]\]' "$(dirname "$0")/../wrangler.toml" >/dev/null; then
  echo "ERROR: KV namespace no bindeado en wrangler.toml" >&2
  echo "Primero ejecuta: wrangler kv namespace create MILORO_UPDATES" >&2
  echo "y pega el id en wrangler.toml descomentando el bloque [[kv_namespaces]]" >&2
  exit 1
fi

# Escribir a KV remoto. wrangler 4.92+ NO acepta stdin para `kv key put`,
# requiere --path=<file> o valor posicional. Usamos tmpfile para multi-line JSON.
echo "Escribiendo manifest a KV MILORO_UPDATES key='$CHANNEL' (--remote)..." >&2
TMP_MANIFEST=$(mktemp /tmp/miloro-manifest-XXXXXX.json)
trap "rm -f '$TMP_MANIFEST'" EXIT
printf '%s' "$MANIFEST" > "$TMP_MANIFEST"
wrangler kv key put --binding=MILORO_UPDATES --remote "$CHANNEL" --path="$TMP_MANIFEST"

echo "" >&2
echo "OK manifest publicado. Verifica con:" >&2
echo "  curl https://miloro.app/api/updater/linux-x86_64/0.0.1?channel=$CHANNEL" >&2
echo "Debe devolver 200 con el JSON (si tu version actual < $VERSION) o 204 (si >=)." >&2
