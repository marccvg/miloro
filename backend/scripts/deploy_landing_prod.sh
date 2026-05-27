#!/bin/bash
# Deploy MiLoro landing → Cloudflare Pages (production).
#
# Uso (Marc):
#   cd /home/Projects/parla/backend
#   ./scripts/load_secrets.sh ./scripts/deploy_landing_prod.sh
#
# Flags:
#   --dry-run    lista comandos sin ejecutar
#   --branch=X   branch destino (default: main = production)
#
# Requisitos:
#   - wrangler login
#   - /home/marc/.secrets/cf_pages_token (opcional, fallback a wrangler login auth)
#   - Cloudflare Pages project "miloro-landing" creado (con miloro.app DNS apuntando)

set -euo pipefail

DRY=0
BRANCH="main"
for arg in "$@"; do
  case "$arg" in
    --dry-run)  DRY=1 ;;
    --branch=*) BRANCH="${arg#--branch=}" ;;
    *) echo "Flag desconocida: $arg" >&2; exit 2 ;;
  esac
done

run() {
  if [ "$DRY" = "1" ]; then
    echo "DRY: $*"
  else
    echo ">>> $*"
    "$@"
  fi
}

# Landing vive en /home/Projects/parla/landing
LANDING_DIR="$(dirname "$0")/../../landing"
if [ ! -d "$LANDING_DIR" ]; then
  echo "ERROR: landing dir no existe: $LANDING_DIR" >&2
  exit 1
fi
cd "$LANDING_DIR"

# Verificar wrangler auth (con o sin CF_PAGES_TOKEN)
if [ -n "${CF_PAGES_TOKEN:-}" ]; then
  export CLOUDFLARE_API_TOKEN="$CF_PAGES_TOKEN"
  echo "Usando CF_PAGES_TOKEN para auth"
elif ! wrangler whoami >/dev/null 2>&1; then
  echo "ERROR: ni CF_PAGES_TOKEN ni wrangler login disponibles" >&2
  echo "Opciones:" >&2
  echo "  a) wrangler login" >&2
  echo "  b) /home/marc/.secrets/cf_pages_token con token Pages-deploy" >&2
  exit 1
fi

# Build step opcional (actualmente landing es HTML estatico, no necesita build)
if [ -f "package.json" ] && grep -q '"build"' package.json; then
  echo "--- Build landing ---"
  run npm install --silent
  run npm run build
  DEPLOY_DIR="dist"
else
  echo "[skip] build (landing es HTML estatico)"
  DEPLOY_DIR="."
fi

# Crear proyecto Pages si no existe (non-interactive)
echo "--- Verificar proyecto Pages 'miloro-landing' ---"
if wrangler pages project list 2>/dev/null | grep -q "^.*miloro-landing"; then
  echo "  proyecto ya existe"
else
  echo "  proyecto no existe, creando..."
  run wrangler pages project create miloro-landing \
    --production-branch=main
fi

# Deploy
echo "--- Wrangler Pages deploy ---"
run wrangler pages deploy "$DEPLOY_DIR" \
  --project-name=miloro-landing \
  --branch="$BRANCH" \
  --commit-dirty=true

# Verificacion
if [ "$DRY" = "0" ]; then
  echo "--- Verificacion ---"
  sleep 6
  if curl -fsS https://miloro.app/ -o /dev/null -w "%{http_code}\n" | grep -q "^200"; then
    echo "OK Landing live: https://miloro.app/"
  else
    echo "WARN Landing no responde 200 en https://miloro.app/"
    echo "Puede ser propagacion CDN — vuelve a probar en 60s"
  fi
fi

echo ""
echo "Deploy completado. Landing live en https://miloro.app/"
