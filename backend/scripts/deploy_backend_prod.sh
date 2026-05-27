#!/bin/bash
# Deploy MiLoro license server → Cloudflare Workers (production).
#
# Idempotente: secrets push siempre, migrations diff-only, deploy fresh.
#
# Uso (Marc):
#   cd /home/Projects/parla/backend
#   ./scripts/load_secrets.sh ./scripts/deploy_backend_prod.sh
#
# Flags:
#   --no-migrate   salta wrangler d1 migrations apply (útil si ya aplicadas)
#   --no-secrets   salta secret put (útil si secrets ya estables)
#   --dry-run      lista comandos sin ejecutar
#
# Requisitos:
#   - wrangler login (una sola vez)
#   - /home/marc/.secrets/{stripe_secret_key,stripe_webhook_secret,admin_token}
#   - wrangler.toml con database_id real en [[d1_databases]]

set -euo pipefail

DRY=0
DO_MIGRATE=1
DO_SECRETS=1
for arg in "$@"; do
  case "$arg" in
    --no-migrate) DO_MIGRATE=0 ;;
    --no-secrets) DO_SECRETS=0 ;;
    --dry-run)    DRY=1 ;;
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

cd "$(dirname "$0")/.."

# --- 1. Verificar secrets cargados en env ---
if [ "$DO_SECRETS" = "1" ]; then
  MISSING=()
  for v in STRIPE_SECRET_KEY STRIPE_WEBHOOK_SECRET; do
    [ -z "${!v:-}" ] && MISSING+=("$v")
  done
  if [ ${#MISSING[@]} -gt 0 ]; then
    echo "ERROR: secrets sin cargar: ${MISSING[*]}" >&2
    echo "Ejecuta vía: ./scripts/load_secrets.sh ./scripts/deploy_backend_prod.sh" >&2
    exit 1
  fi
  # ADMIN_TOKEN opcional (algunos endpoints internos)
  [ -z "${ADMIN_TOKEN:-}" ] && echo "  (ADMIN_TOKEN unset — endpoint /api/license/issue quedara sin auth)" >&2
fi

# --- 2. Verificar wrangler auth ---
if ! wrangler whoami >/dev/null 2>&1; then
  echo "ERROR: wrangler no autenticado. Ejecuta: wrangler login" >&2
  exit 1
fi
echo "wrangler auth: OK"

# --- 3. Verificar database_id no es placeholder ---
# Solo chequea la linea no-comentada `database_id = "..."`
if grep -E '^[[:space:]]*database_id[[:space:]]*=[[:space:]]*"TODO' wrangler.toml >/dev/null; then
  echo "ERROR: wrangler.toml todavia tiene database_id placeholder." >&2
  echo "Ejecuta primero: wrangler d1 create parla_licenses" >&2
  echo "Pega el database_id devuelto en wrangler.toml [[d1_databases]] database_id" >&2
  exit 1
fi

# --- 4. Push secrets (idempotente) ---
if [ "$DO_SECRETS" = "1" ]; then
  echo "--- Push secrets a Worker ---"
  # Uso printf '%s' (NO echo) para evitar trailing newline que algunos APIs
  # interpretan literal (Resend rechaza con 401 "API key invalid" si llega con \n).
  printf '%s' "$STRIPE_SECRET_KEY"     | run wrangler secret put STRIPE_SECRET_KEY
  printf '%s' "$STRIPE_WEBHOOK_SECRET" | run wrangler secret put STRIPE_WEBHOOK_SECRET
  if [ -n "${ADMIN_TOKEN:-}" ]; then
    printf '%s' "$ADMIN_TOKEN" | run wrangler secret put ADMIN_TOKEN
  fi
  # Resend (opcional pero necesario para emails reales en producción)
  if [ -n "${RESEND_API_KEY:-}" ]; then
    printf '%s' "$RESEND_API_KEY" | run wrangler secret put RESEND_API_KEY
  else
    echo "  (RESEND_API_KEY unset — emails caeran en MailChannels y FALLARAN)" >&2
  fi
  if [ -n "${RESEND_FROM:-}" ]; then
    # EMAIL_FROM es el nombre que usa el codigo (env.EMAIL_FROM). Mapeamos RESEND_FROM -> EMAIL_FROM.
    printf '%s' "$RESEND_FROM" | run wrangler secret put EMAIL_FROM
  fi
else
  echo "[skip] secrets push"
fi

# --- 5. Aplicar migraciones D1 (remote) ---
if [ "$DO_MIGRATE" = "1" ]; then
  echo "--- D1 migraciones (remote) ---"
  run wrangler d1 migrations apply parla_licenses --remote
else
  echo "[skip] D1 migrations"
fi

# --- 6. Deploy Worker ---
echo "--- Wrangler deploy ---"
run wrangler deploy

# --- 7. Health check ---
if [ "$DRY" = "0" ]; then
  echo "--- Health check ---"
  sleep 4
  HEALTH_URL="https://miloro.app/api/health"
  if curl -fsS "$HEALTH_URL" | grep -q '"status":"ok"'; then
    echo "OK Backend healthy: $HEALTH_URL"
  else
    echo "WARN Health check failed at $HEALTH_URL"
    echo "Comprueba manualmente: curl -sS $HEALTH_URL"
    exit 1
  fi
fi

echo ""
echo "Deploy completado. Worker live en https://miloro.app/api/*"
