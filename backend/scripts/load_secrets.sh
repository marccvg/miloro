#!/bin/bash
# Marc 2026-05-19: secrets loader que NO expone la API key al agente.
# El agente Claude NO puede leer /home/marc/ (hard rule §2.2 privacidad).
# Este script lee el secret en runtime cuando Marc ejecuta el comando,
# inyecta en el environment y arranca el proceso target.
#
# Uso:
#   ./scripts/load_secrets.sh npm run dev
#   ./scripts/load_secrets.sh npm test
#   ./scripts/load_secrets.sh wrangler deploy
#
# Marc setup una sola vez:
#   mkdir -p /home/marc/.secrets
#   chmod 700 /home/marc/.secrets
#   echo "tu_api_key_aqui" > /home/marc/.secrets/resend_api_key
#   chmod 600 /home/marc/.secrets/resend_api_key
#   echo "onboarding@resend.dev" > /home/marc/.secrets/resend_from
#   chmod 600 /home/marc/.secrets/resend_from
#   # Opcional Stripe:
#   echo "sk_test_..." > /home/marc/.secrets/stripe_secret_key
#   echo "whsec_..." > /home/marc/.secrets/stripe_webhook_secret
#
# El agente Claude NO puede acceder /home/marc/.secrets/ (filesystem permissions
# + hard rule). Cuando Marc ejecuta este script, las keys se cargan SOLO en el
# proceso hijo (env vars heredables) y nunca se escriben a disk fuera de /home/marc/.

set -euo pipefail

SECRETS_DIR="/home/marc/.secrets"

if [ ! -d "$SECRETS_DIR" ]; then
    echo "❌ Directorio de secretos no existe: $SECRETS_DIR" >&2
    echo "   Marc debe crearlo: mkdir -p $SECRETS_DIR && chmod 700 $SECRETS_DIR" >&2
    exit 1
fi

# Carga secret con prefijo de proyecto preferido + fallback al nombre genérico.
# Convención: secrets multi-proyecto se prefixan (`miloro_*`, `paginaportada_*`).
# Secrets de cuenta CF compartida (`cf_api_token`) van sin prefijo.
load_secret_with_fallback() {
    local primary="$1"    # nombre preferido (con prefijo proyecto)
    local secondary="$2"  # fallback genérico (si proyecto único / migración)
    local var="$3"
    if [ -r "$SECRETS_DIR/$primary" ]; then
        export "$var"="$(cat "$SECRETS_DIR/$primary" | tr -d '\n\r ')"
        echo "✓ $var loaded from $primary" >&2
    elif [ -r "$SECRETS_DIR/$secondary" ]; then
        export "$var"="$(cat "$SECRETS_DIR/$secondary" | tr -d '\n\r ')"
        echo "✓ $var loaded from $secondary (fallback genérico)" >&2
    else
        echo "⚠ $primary / $secondary no encontrados — $var queda unset (modo mock si aplica)" >&2
    fi
}

# Keys específicas de MiLoro
load_secret_with_fallback "miloro_resend_api_key"        "resend_api_key"        "RESEND_API_KEY"
load_secret_with_fallback "miloro_resend_from"           "resend_from"           "RESEND_FROM"
load_secret_with_fallback "miloro_stripe_secret_key"     "stripe_secret_key"     "STRIPE_SECRET_KEY"
load_secret_with_fallback "miloro_stripe_webhook_secret" "stripe_webhook_secret" "STRIPE_WEBHOOK_SECRET"
load_secret_with_fallback "miloro_admin_token"           "admin_token"           "ADMIN_TOKEN"
load_secret_with_fallback "miloro_better_auth_secret"    "better_auth_secret"    "BETTER_AUTH_SECRET"

# Compartidos a nivel cuenta Cloudflare (1 cuenta CF para todos los proyectos)
load_secret_with_fallback "cf_api_token"      "cf_api_token"     "CLOUDFLARE_API_TOKEN"
load_secret_with_fallback "cf_account_id"     "cf_account_id"    "CF_ACCOUNT_ID"
load_secret_with_fallback "cf_pages_token"    "cf_pages_token"   "CF_PAGES_TOKEN"

# R2 S3-compatible API credentials (para rclone uploads — alternativa a wrangler r2 object put)
# Marc crea token en dashboard CF → R2 → Manage R2 API Tokens (Object Read & Write para miloro-releases)
load_secret_with_fallback "r2_access_key_id"     "r2_access_key_id"     "R2_ACCESS_KEY_ID"
load_secret_with_fallback "r2_secret_access_key" "r2_secret_access_key" "R2_SECRET_ACCESS_KEY"

# Si tenemos R2 keys, exporta el config rclone via env vars (sin necesidad de rclone config interactivo).
# El remote se llama "r2" y apunta a Cloudflare con endpoint S3 de la cuenta.
if [ -n "${R2_ACCESS_KEY_ID:-}" ] && [ -n "${R2_SECRET_ACCESS_KEY:-}" ]; then
  CF_ACCOUNT_HASH="${CF_ACCOUNT_ID:-b21270dceee2c78e0903355e804ab1e4}"
  export RCLONE_CONFIG_R2_TYPE=s3
  export RCLONE_CONFIG_R2_PROVIDER=Cloudflare
  export RCLONE_CONFIG_R2_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
  export RCLONE_CONFIG_R2_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"
  export RCLONE_CONFIG_R2_REGION=auto
  export RCLONE_CONFIG_R2_ENDPOINT="https://${CF_ACCOUNT_HASH}.r2.cloudflarestorage.com"
  echo "✓ rclone remote 'r2' configurado vía env (R2 S3 API)" >&2
fi

# Ejecutar comando target con env hereded
if [ "$#" -eq 0 ]; then
    echo "Uso: $0 <comando> [args...]" >&2
    echo "Ej:  $0 npm run dev" >&2
    echo "     $0 npm test" >&2
    echo "     $0 wrangler deploy" >&2
    exit 0
fi

exec "$@"
