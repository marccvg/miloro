#!/bin/bash
# Crea los Stripe Prices de MiLoro Pro (€9/mes + €72/año) en TEST o LIVE.
#
# Uso (Marc):
#   cd /home/Projects/parla/backend
#   ./scripts/load_secrets.sh ./scripts/setup_stripe_prices.sh [--live] [--apply]
#
# Flags:
#   --live    crea en modo live (default: test). Requiere Day-X UJI cumplido.
#   --apply   sed wrangler.toml con los nuevos price IDs (default: solo imprime)
#
# Requisitos:
#   - STRIPE_SECRET_KEY cargado en env (load_secrets.sh)
#   - curl (sin Stripe CLI — usa REST API directa para no requerir login adicional)
#
# Outputs:
#   - stderr: IDs creados
#   - /home/marc/.secrets/stripe_price_ids_{test,live}.env (si dir existe)
#   - wrangler.toml actualizado in-place (solo con --apply)

set -euo pipefail

MODE="test"
APPLY=0
for arg in "$@"; do
  case "$arg" in
    --live)  MODE="live" ;;
    --apply) APPLY=1 ;;
    *) echo "Flag desconocida: $arg" >&2; exit 2 ;;
  esac
done

if [ -z "${STRIPE_SECRET_KEY:-}" ]; then
  echo "ERROR: STRIPE_SECRET_KEY unset. Carga via load_secrets.sh" >&2
  exit 1
fi

# Verificar que la key matchea el modo
if [ "$MODE" = "live" ] && [[ ! "$STRIPE_SECRET_KEY" =~ ^sk_live_ ]]; then
  echo "ERROR: --live pedido pero STRIPE_SECRET_KEY no empieza por sk_live_" >&2
  exit 1
fi
if [ "$MODE" = "test" ] && [[ ! "$STRIPE_SECRET_KEY" =~ ^sk_test_ ]]; then
  echo "WARN: modo test pedido pero key no empieza por sk_test_. Continuando..." >&2
fi

echo "==============================" >&2
echo "Stripe prices setup ($MODE)" >&2
echo "==============================" >&2

api() {
  # api <endpoint> <data...>
  local endpoint="$1"; shift
  local args=()
  for d in "$@"; do
    args+=("-d" "$d")
  done
  curl -sS -X POST "https://api.stripe.com/v1/$endpoint" \
    -u "$STRIPE_SECRET_KEY:" \
    "${args[@]}"
}

# Helper extracción ID con reporte de error claro
extract_id() {
  python3 <<'PYEOF'
import sys, json
raw = sys.stdin.read()
try:
    data = json.loads(raw)
except json.JSONDecodeError:
    sys.stderr.write(f"ERROR: respuesta Stripe no es JSON valido:\n{raw}\n")
    sys.exit(1)
if "id" in data:
    print(data["id"])
elif "error" in data:
    err = data["error"]
    msg = err.get("message", "(sin mensaje)")
    code = err.get("code", err.get("type", "(sin codigo)"))
    sys.stderr.write(f"ERROR Stripe API [{code}]: {msg}\n")
    sys.stderr.write(f"Respuesta completa:\n{json.dumps(data, indent=2)}\n")
    sys.exit(1)
else:
    sys.stderr.write(f"ERROR: respuesta Stripe sin 'id' ni 'error':\n{json.dumps(data, indent=2)}\n")
    sys.exit(1)
PYEOF
}

# 1. Crear producto MiLoro Pro
echo "--- Crear producto MiLoro Pro ---" >&2
PRODUCT_RESP=$(api "products" \
  "name=MiLoro Pro" \
  "description=Dictado por voz local sin limite. 3 devices. Modelos hasta large-v3." \
  "metadata[plan]=pro" \
  "metadata[origin]=miloro_setup_script")
PRODUCT_ID=$(echo "$PRODUCT_RESP" | extract_id)
echo "  product_id: $PRODUCT_ID" >&2

# 2. Price mensual €9
echo "--- Crear price Pro Monthly (€9/mes) ---" >&2
PRICE_MONTHLY_RESP=$(api "prices" \
  "product=$PRODUCT_ID" \
  "currency=eur" \
  "unit_amount=900" \
  "recurring[interval]=month" \
  "nickname=Pro Monthly EUR" \
  "metadata[plan]=pro" \
  "metadata[cadence]=monthly")
PRICE_MONTHLY_ID=$(echo "$PRICE_MONTHLY_RESP" | extract_id)
echo "  price_monthly: $PRICE_MONTHLY_ID" >&2

# 3. Price anual €72 (33% descuento sobre 12 meses)
echo "--- Crear price Pro Annual (€72/ano = 2 meses gratis) ---" >&2
PRICE_ANNUAL_RESP=$(api "prices" \
  "product=$PRODUCT_ID" \
  "currency=eur" \
  "unit_amount=7200" \
  "recurring[interval]=year" \
  "nickname=Pro Annual EUR" \
  "metadata[plan]=pro" \
  "metadata[cadence]=annual")
PRICE_ANNUAL_ID=$(echo "$PRICE_ANNUAL_RESP" | extract_id)
echo "  price_annual:  $PRICE_ANNUAL_ID" >&2

# Output
echo "" >&2
echo "==============================" >&2
echo "PRICE IDs creados ($MODE):" >&2
echo "  STRIPE_PRICE_PRO_MONTHLY=$PRICE_MONTHLY_ID" >&2
echo "  STRIPE_PRICE_PRO_ANNUAL=$PRICE_ANNUAL_ID" >&2
echo "  STRIPE_PRODUCT_PRO=$PRODUCT_ID" >&2
echo "==============================" >&2

# Persist a /home/marc/.secrets/ (si existe el dir; Marc lo crea inicial)
SECRETS_DIR="/home/marc/.secrets"
if [ -d "$SECRETS_DIR" ] && [ -w "$SECRETS_DIR" ]; then
  OUT="$SECRETS_DIR/stripe_price_ids_${MODE}.env"
  cat > "$OUT" <<EOF
# Generado por setup_stripe_prices.sh el $(date -Iseconds)
# Modo: $MODE
STRIPE_PRICE_PRO_MONTHLY=$PRICE_MONTHLY_ID
STRIPE_PRICE_PRO_ANNUAL=$PRICE_ANNUAL_ID
STRIPE_PRODUCT_PRO=$PRODUCT_ID
EOF
  chmod 600 "$OUT"
  echo "OK Persistido en $OUT" >&2
fi

# Apply: sed wrangler.toml in-place
if [ "$APPLY" = "1" ]; then
  WRANGLER_TOML="$(dirname "$0")/../wrangler.toml"
  if [ ! -f "$WRANGLER_TOML" ]; then
    echo "ERROR: wrangler.toml no encontrado en $WRANGLER_TOML" >&2
    exit 1
  fi
  cp "$WRANGLER_TOML" "$WRANGLER_TOML.bak.$(date +%s)"
  # STRIPE_PRICE_PRO va al mensual €9 (caso B2C principal)
  sed -i "s|^STRIPE_PRICE_PRO = .*|STRIPE_PRICE_PRO = \"$PRICE_MONTHLY_ID\"|" "$WRANGLER_TOML"
  # STRIPE_PRICE_STANDARD reutilizado como Annual (decision 2026-05-24: standard slot disponible)
  sed -i "s|^STRIPE_PRICE_STANDARD = .*|STRIPE_PRICE_STANDARD = \"$PRICE_ANNUAL_ID\"|" "$WRANGLER_TOML"
  echo "OK wrangler.toml actualizado (.bak creado). Siguiente paso:" >&2
  echo "  ./scripts/load_secrets.sh ./scripts/deploy_backend_prod.sh" >&2
fi

echo ""
echo "Hecho. Dashboard Stripe: https://dashboard.stripe.com/${MODE/live/}/prices/$PRICE_MONTHLY_ID"
