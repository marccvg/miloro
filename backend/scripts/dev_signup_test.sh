#!/bin/bash
# DEV helper: reset rate-limit de signup + test signup contra prod.
#
# Solo para desarrollo (cuando hay que retest muchas veces el mismo email).
# Marc ejecuta:
#   ./scripts/load_secrets.sh ./scripts/dev_signup_test.sh tu@email.com
#
# Encapsula los 2 pasos (DELETE events + test) en un solo comando,
# evitando el copy/paste de strings largas con caracteres especiales.

set -euo pipefail

# Email default Marc (override pasando arg: ./dev_signup_test.sh otro@email.com)
EMAIL="${1:-marcstarwars@gmail.com}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "--- 1. Reset rate-limit signup en D1 remote ---"
wrangler d1 execute parla_licenses --remote \
  --command="DELETE FROM events WHERE type IN ('signup', 'signup_blocked') AND ts >= unixepoch() - 7200"

echo ""
echo "--- 2. Lanzar test signup ---"
"$SCRIPT_DIR/test_signup.sh" "$EMAIL"

echo ""
echo "--- 3. Último error de email (si lo hubo) ---"
wrangler d1 execute parla_licenses --remote \
  --command="SELECT datetime(ts, 'unixepoch') as when_, payload_json FROM events WHERE type = 'email_failed' ORDER BY ts DESC LIMIT 1" \
  2>&1 | tail -20
