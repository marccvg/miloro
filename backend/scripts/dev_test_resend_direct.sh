#!/bin/bash
# Test directo contra Resend API saltándose el Worker.
# Aisla problema: key válida? + sandbox restrictions activas?
#
# Uso:
#   ./scripts/load_secrets.sh ./scripts/dev_test_resend_direct.sh [email_to]
# Default to: marcstarwars@gmail.com

set -euo pipefail

TO_EMAIL="${1:-marcstarwars@gmail.com}"
FROM_EMAIL="${RESEND_FROM:-MiLoro <onboarding@resend.dev>}"

if [ -z "${RESEND_API_KEY:-}" ]; then
  echo "ERROR: RESEND_API_KEY no cargado. Ejecuta via load_secrets.sh" >&2
  exit 1
fi

echo "POST https://api.resend.com/emails"
echo "  from: $FROM_EMAIL"
echo "  to:   $TO_EMAIL"
echo "  key:  $(echo "$RESEND_API_KEY" | head -c 6)...$(echo "$RESEND_API_KEY" | tail -c 4) (len=${#RESEND_API_KEY})"
echo ""

PAYLOAD=$(cat <<EOF
{
  "from": "$FROM_EMAIL",
  "to": "$TO_EMAIL",
  "subject": "MiLoro test directo curl",
  "text": "Si recibes este email, la key Resend funciona y el problema está en el Worker."
}
EOF
)

RESP=$(curl -sS -X POST 'https://api.resend.com/emails' \
  -H "Authorization: Bearer $RESEND_API_KEY" \
  -H 'Content-Type: application/json' \
  -d "$PAYLOAD")

echo "Respuesta Resend:"
echo "$RESP" | python3 -m json.tool 2>/dev/null || echo "$RESP"
