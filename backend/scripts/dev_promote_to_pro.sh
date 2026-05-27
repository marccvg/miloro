#!/bin/bash
# DEV helper: emite/upgradea tu propia licencia a Pro ilimitado para dogfooding.
#
# Marc ejecuta:
#   ./scripts/load_secrets.sh ./scripts/dev_promote_to_pro.sh [email]
# Default email: marcstarwars@gmail.com
#
# Pasos:
#   1. Asegura que existe license para ese email (la crea Free vía signup público si no)
#   2. UPDATE D1 directo: plan=pro, devices_max=3, status=active, expires_at=NULL
#   3. Muestra la license key para pegar en la app MiLoro
#
# Útil porque sin ADMIN_TOKEN configurado, el endpoint /api/license/issue no funciona.

set -euo pipefail

EMAIL="${1:-marcstarwars@gmail.com}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "--- 1. Asegurar license Free existe para $EMAIL ---"
# Reset rate-limit por si acaso
wrangler d1 execute parla_licenses --remote \
  --command="DELETE FROM events WHERE type IN ('signup', 'signup_blocked') AND ts >= unixepoch() - 7200" \
  >/dev/null

# Signup público (idempotente: si ya existe, no duplica)
curl -sS -X POST "https://miloro.app/api/license/signup" \
  -H 'content-type: application/json' \
  --data "$(printf '{"email":"%s"}' "$EMAIL")" \
  | python3 -m json.tool

echo ""
echo "--- 2. Upgrade a Pro (plan=pro, devices_max=3, status=active) ---"
wrangler d1 execute parla_licenses --remote \
  --command="UPDATE licenses SET plan='pro', devices_max=3, status='active', expires_at=NULL WHERE email='$EMAIL'"

echo ""
echo "--- 3. Tu license key Pro (cópiala para pegar en MiLoro app) ---"
wrangler d1 execute parla_licenses --remote --json \
  --command="SELECT key, plan, devices_max, status, datetime(created_at, 'unixepoch') AS created FROM licenses WHERE email='$EMAIL' ORDER BY created_at DESC LIMIT 1" \
  | python3 -c "
import sys, json
data = json.loads(sys.stdin.read())
rows = data[0]['results']
if not rows:
    print('ERROR: no se encontró ninguna license para $EMAIL')
    sys.exit(1)
r = rows[0]
print('')
print('  Email:     $EMAIL')
print(f'  License:   {r[\"key\"]}')
print(f'  Plan:      {r[\"plan\"]}')
print(f'  Devices:   {r[\"devices_max\"]}')
print(f'  Status:    {r[\"status\"]}')
print(f'  Created:   {r[\"created\"]} UTC')
print('')
print('Cópiala y pégala en la app MiLoro → Settings → Licencia.')
"
