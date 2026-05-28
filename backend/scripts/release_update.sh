#!/bin/bash
# Publica un manifest de release a KV MILORO_UPDATES para que Tauri updater lo sirva.
#
# Uso (Marc):
#   ./scripts/load_secrets.sh ./scripts/release_update.sh <channel> <version> [opciones]
#
# Channel: stable | beta
# Version: semver X.Y.Z (sin prefix 'v')
#
# Opciones por plataforma TOP-LEVEL (default que sirve el endpoint OLD a clientes pre-v0.0.14):
#   --linux-url=<url>       --linux-sig=<base64>
#   --windows-url=<url>     --windows-sig=<base64>
#   --darwin-x86-url=<url>  --darwin-x86-sig=<sig>
#   --darwin-arm-url=<url>  --darwin-arm-sig=<sig>
#
# Opciones por BUNDLE (v0.0.14+ — endpoint NEW con {{bundle_type}} devuelve estos):
#   --linux-deb-url=<url>      --linux-deb-sig=<sig>
#   --linux-appimage-url=<url> --linux-appimage-sig=<sig>
#   --linux-rpm-url=<url>      --linux-rpm-sig=<sig>
#   --windows-nsis-url=<url>   --windows-nsis-sig=<sig>
#   --windows-msi-url=<url>    --windows-msi-sig=<sig>
#
# Otras:
#   --notes='texto markdown release notes'
#   --pub-date=<ISO8601>  (default: now UTC)
#   --dry-run             (imprime manifest sin escribir KV)

set -euo pipefail

if [ $# -lt 2 ]; then
  cat <<'EOF' >&2
Uso: release_update.sh <channel> <version> [opciones]
  channel: stable | beta
  version: semver X.Y.Z
  --linux-url + --linux-sig (top-level — endpoint OLD)
  --linux-deb-url + --linux-deb-sig + ...-appimage-... + ...-rpm-... (bundles — endpoint NEW)
  --windows-url + --windows-sig (top-level)
  --windows-nsis-url + --windows-nsis-sig + ...-msi-... (bundles)
  --darwin-x86-url + --darwin-x86-sig
  --darwin-arm-url + --darwin-arm-sig
  --notes='...'
  --pub-date=<ISO8601>
  --dry-run
EOF
  exit 2
fi

CHANNEL="$1"
VERSION="$2"
shift 2

if [ "$CHANNEL" != "stable" ] && [ "$CHANNEL" != "beta" ]; then
  echo "ERROR: channel debe ser 'stable' o 'beta'" >&2; exit 2
fi
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
  echo "ERROR: version invalida '$VERSION'" >&2; exit 2
fi

PUB_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
NOTES=""
DRY=0
declare -A URLS SIGS BUNDLE_URLS BUNDLE_SIGS

# bundle_set <platform> <bundle_type> <url|sig> <value>
set_bundle() {
  local plat="$1" btype="$2" kind="$3" val="$4"
  local key="${plat}:${btype}"
  if [ "$kind" = "url" ]; then
    BUNDLE_URLS[$key]="$val"
  else
    BUNDLE_SIGS[$key]="$val"
  fi
}

for arg in "$@"; do
  case "$arg" in
    # Top-level (endpoint OLD)
    --linux-url=*)              URLS[linux-x86_64]="${arg#*=}" ;;
    --linux-sig=*)              SIGS[linux-x86_64]="${arg#*=}" ;;
    --windows-url=*)            URLS[windows-x86_64]="${arg#*=}" ;;
    --windows-sig=*)            SIGS[windows-x86_64]="${arg#*=}" ;;
    --darwin-x86-url=*)         URLS[darwin-x86_64]="${arg#*=}" ;;
    --darwin-x86-sig=*)         SIGS[darwin-x86_64]="${arg#*=}" ;;
    --darwin-arm-url=*)         URLS[darwin-aarch64]="${arg#*=}" ;;
    --darwin-arm-sig=*)         SIGS[darwin-aarch64]="${arg#*=}" ;;
    # Bundles Linux
    --linux-deb-url=*)          set_bundle linux-x86_64 deb url "${arg#*=}" ;;
    --linux-deb-sig=*)          set_bundle linux-x86_64 deb sig "${arg#*=}" ;;
    --linux-appimage-url=*)     set_bundle linux-x86_64 appimage url "${arg#*=}" ;;
    --linux-appimage-sig=*)     set_bundle linux-x86_64 appimage sig "${arg#*=}" ;;
    --linux-rpm-url=*)          set_bundle linux-x86_64 rpm url "${arg#*=}" ;;
    --linux-rpm-sig=*)          set_bundle linux-x86_64 rpm sig "${arg#*=}" ;;
    # Bundles Windows
    --windows-nsis-url=*)       set_bundle windows-x86_64 nsis url "${arg#*=}" ;;
    --windows-nsis-sig=*)       set_bundle windows-x86_64 nsis sig "${arg#*=}" ;;
    --windows-msi-url=*)        set_bundle windows-x86_64 msi url "${arg#*=}" ;;
    --windows-msi-sig=*)        set_bundle windows-x86_64 msi sig "${arg#*=}" ;;
    # Generic
    --notes=*)                  NOTES="${arg#*=}" ;;
    --pub-date=*)               PUB_DATE="${arg#*=}" ;;
    --dry-run)                  DRY=1 ;;
    *) echo "Flag desconocida: $arg" >&2; exit 2 ;;
  esac
done

# Serializar arrays a TSV multi-líneas para pasarlos a Python sin escaping pain.
serialize_assoc() {
  # $1: nombre array. Imprime "key<TAB>value" por línea.
  local -n arr=$1
  for k in "${!arr[@]}"; do
    printf "%s\t%s\n" "$k" "${arr[$k]}"
  done
}

URLS_TSV=$(serialize_assoc URLS)
SIGS_TSV=$(serialize_assoc SIGS)
BUNDLE_URLS_TSV=$(serialize_assoc BUNDLE_URLS)
BUNDLE_SIGS_TSV=$(serialize_assoc BUNDLE_SIGS)

# Construir manifest con Python (mejor escaping que bash + jq con base64)
MANIFEST=$(
  VERSION="$VERSION" PUB_DATE="$PUB_DATE" NOTES="$NOTES" \
  URLS_TSV="$URLS_TSV" SIGS_TSV="$SIGS_TSV" \
  BUNDLE_URLS_TSV="$BUNDLE_URLS_TSV" BUNDLE_SIGS_TSV="$BUNDLE_SIGS_TSV" \
  python3 <<'PY'
import json, os, sys

def parse_tsv(s):
    out = {}
    for line in s.splitlines():
        if not line: continue
        k, _, v = line.partition('\t')
        if k: out[k] = v
    return out

urls = parse_tsv(os.environ.get('URLS_TSV',''))
sigs = parse_tsv(os.environ.get('SIGS_TSV',''))
bundle_urls = parse_tsv(os.environ.get('BUNDLE_URLS_TSV',''))
bundle_sigs = parse_tsv(os.environ.get('BUNDLE_SIGS_TSV',''))

platforms = {}
for plat in ("linux-x86_64", "windows-x86_64", "darwin-x86_64", "darwin-aarch64"):
    entry = {}
    # top-level url+sig (default — endpoint OLD)
    if urls.get(plat) and sigs.get(plat):
        entry["url"] = urls[plat]
        entry["signature"] = sigs[plat]
    elif urls.get(plat) or sigs.get(plat):
        sys.stderr.write(f"WARN: {plat} top-level tiene solo una de url/sig — skip top-level\n")
    # bundles per type (endpoint NEW)
    bundles = {}
    for key in bundle_urls:
        kp, _, btype = key.partition(":")
        if kp != plat: continue
        bu = bundle_urls.get(key)
        bs = bundle_sigs.get(key)
        if bu and bs:
            bundles[btype] = {"url": bu, "signature": bs}
        elif bu or bs:
            sys.stderr.write(f"WARN: {plat}/{btype} bundle tiene solo una de url/sig — skip\n")
    if bundles:
        entry["bundles"] = bundles
    if entry:
        platforms[plat] = entry

manifest = {
    "version": os.environ["VERSION"],
    "pub_date": os.environ["PUB_DATE"],
    "notes": os.environ.get("NOTES",""),
    "platforms": platforms,
}
print(json.dumps(manifest, indent=2))
PY
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

if ! grep -E '^\[\[kv_namespaces\]\]' "$(dirname "$0")/../wrangler.toml" >/dev/null; then
  echo "ERROR: KV namespace no bindeado en wrangler.toml" >&2
  exit 1
fi

echo "Escribiendo manifest a KV MILORO_UPDATES key='$CHANNEL' (--remote)..." >&2
TMP_MANIFEST=$(mktemp /tmp/miloro-manifest-XXXXXX.json)
trap "rm -f '$TMP_MANIFEST'" EXIT
printf '%s' "$MANIFEST" > "$TMP_MANIFEST"
wrangler kv key put --binding=MILORO_UPDATES --remote "$CHANNEL" --path="$TMP_MANIFEST"

echo "" >&2
echo "OK manifest publicado. Verifica con:" >&2
echo "  curl https://miloro.app/api/updater/linux-x86_64/0.0.1?channel=$CHANNEL                    (endpoint OLD)" >&2
echo "  curl https://miloro.app/api/updater/linux-x86_64/deb/0.0.1?channel=$CHANNEL                (endpoint NEW)" >&2
