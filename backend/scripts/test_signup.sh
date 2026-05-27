#!/bin/bash
# Test end-to-end del flujo signup Free contra producción miloro.app.
#
# Uso:
#   ./scripts/test_signup.sh tu@email.com
#   ./scripts/test_signup.sh tu@email.com --staging   # contra dev local (TODO)
#
# Verifica:
#   - El endpoint responde 200
#   - email_sent: true (Resend acepto el POST)
#   - Imprime la respuesta completa para revisión humana

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Uso: $0 <email> [--staging]" >&2
  exit 2
fi

EMAIL="$1"
HOST="https://miloro.app"
[ "${2:-}" = "--staging" ] && HOST="http://localhost:8787"

echo "POST $HOST/api/license/signup  email=$EMAIL"
echo ""

# Construye el JSON sin caracteres conflictivos para shell paste
PAYLOAD=$(printf '{"email":"%s"}' "$EMAIL")

RESP=$(curl -sS -X POST "$HOST/api/license/signup" \
  -H 'content-type: application/json' \
  --data "$PAYLOAD")

echo "Respuesta:"
echo "$RESP" | python3 -m json.tool 2>/dev/null || echo "$RESP"
echo ""

# Parse status y email_sent
STATUS=$(echo "$RESP" | python3 -c "import sys, json; print(json.loads(sys.stdin.read()).get('status', 'unknown'))" 2>/dev/null || echo "parse_error")
EMAIL_SENT=$(echo "$RESP" | python3 -c "import sys, json; print(json.loads(sys.stdin.read()).get('email_sent', False))" 2>/dev/null || echo "false")

if [ "$STATUS" = "ok" ] && [ "$EMAIL_SENT" = "True" ]; then
  echo "OK status=ok + email_sent=true"
  echo "Revisa tu inbox de $EMAIL (puede tardar 30-60s + revisa spam)"
elif [ "$STATUS" = "ok" ] && [ "$EMAIL_SENT" = "False" ]; then
  echo "WARN status=ok pero email_sent=false. Resend rechazo el envio."
  echo "Causa probable: dominio del FROM no verificado en Resend."
  echo "Mira logs Worker: wrangler tail miloro-license-server --format=pretty"
else
  echo "ERROR status=$STATUS. Endpoint fallo."
fi
