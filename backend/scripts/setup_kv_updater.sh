#!/bin/bash
# Setup completo del KV namespace para Tauri updater (B4) + redeploy + smoke test.
# Todo en uno, idempotente.
#
# Marc ejecuta UN solo comando:
#   ./scripts/load_secrets.sh ./scripts/setup_kv_updater.sh
#
# Pasos automatizados:
#   1. Detecta si MILORO_UPDATES KV namespace ya existe (lista namespaces)
#   2. Si no existe → lo crea con wrangler kv namespace create
#   3. Parsea el ID y parchea wrangler.toml in-place (sed) — backup .bak
#   4. Re-deploy backend con el binding nuevo
#   5. Smoke test curl → debe devolver 204 (no manifest aún)
#   6. Sugiere el comando para publicar primer manifest

set -euo pipefail

BACKEND_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WRANGLER_TOML="$BACKEND_DIR/wrangler.toml"

cd "$BACKEND_DIR"

# --- 1. Verificar wrangler auth ---
if ! wrangler whoami >/dev/null 2>&1; then
  echo "ERROR: wrangler no auth. Carga vía load_secrets.sh con CLOUDFLARE_API_TOKEN" >&2
  exit 1
fi
echo "wrangler auth: OK"

# --- 2. Detectar si MILORO_UPDATES ya existe ---
echo ""
echo "--- 1. Buscar namespace MILORO_UPDATES existente ---"
NS_LIST_JSON=$(wrangler kv namespace list 2>/dev/null || echo "[]")

EXISTING_ID=$(echo "$NS_LIST_JSON" | python3 -c "
import sys, json
try:
    data = json.loads(sys.stdin.read())
    if not isinstance(data, list):
        sys.exit(0)
    for ns in data:
        title = ns.get('title', '')
        if 'MILORO_UPDATES' in title:
            print(ns['id'])
            sys.exit(0)
except Exception:
    pass
" 2>/dev/null || echo "")

if [ -n "$EXISTING_ID" ]; then
  KV_ID="$EXISTING_ID"
  echo "  YA existe → reuso id: $KV_ID"
else
  echo "  no existe, creando..."
  CREATE_OUT=$(wrangler kv namespace create MILORO_UPDATES 2>&1)
  echo "$CREATE_OUT"
  KV_ID=$(echo "$CREATE_OUT" | python3 -c "
import sys, re
text = sys.stdin.read()
m = re.search(r'id\s*=\s*\"([a-f0-9]{32})\"', text)
if m:
    print(m.group(1))
" || echo "")
  if [ -z "$KV_ID" ]; then
    echo "ERROR: no pude parsear el id del output. Revisa manualmente." >&2
    exit 1
  fi
  echo "  creado → id: $KV_ID"
fi

# --- 3. Parchear wrangler.toml ---
echo ""
echo "--- 2. Parchear wrangler.toml con id $KV_ID ---"

# Backup
cp "$WRANGLER_TOML" "$WRANGLER_TOML.bak.$(date +%s)"

# Check si ya está bindeado con ese id (idempotencia)
if grep -E '^\[\[kv_namespaces\]\]' "$WRANGLER_TOML" >/dev/null && \
   grep -E "^id = \"$KV_ID\"" "$WRANGLER_TOML" >/dev/null; then
  echo "  ya estaba bindeado con ese id → skip patching"
else
  # Detectar formato exacto del bloque comentado
  if grep -E '^# \[\[kv_namespaces\]\]' "$WRANGLER_TOML" >/dev/null; then
    # Descomentar las 3 líneas + sustituir id
    sed -i \
      -e 's|^# \[\[kv_namespaces\]\]|[[kv_namespaces]]|' \
      -e 's|^# binding = "MILORO_UPDATES"|binding = "MILORO_UPDATES"|' \
      -e "s|^# id = \"TODO_PEGAR_KV_ID\"|id = \"$KV_ID\"|" \
      "$WRANGLER_TOML"
    echo "  descomentado bloque + id sustituido"
  elif grep -E '^\[\[kv_namespaces\]\]' "$WRANGLER_TOML" >/dev/null; then
    # Bloque ya descomentado pero con id wrong → sustituir id
    sed -i "s|^id = \"[a-f0-9]*\"|id = \"$KV_ID\"|" "$WRANGLER_TOML"
    echo "  id sustituido (bloque ya estaba descomentado)"
  else
    # Bloque no existe — añadirlo al final
    cat >> "$WRANGLER_TOML" <<EOF

[[kv_namespaces]]
binding = "MILORO_UPDATES"
id = "$KV_ID"
EOF
    echo "  añadido bloque al final"
  fi
fi

# Verificar resultado
if ! grep -E "^id = \"$KV_ID\"" "$WRANGLER_TOML" >/dev/null; then
  echo "ERROR: no consigo verificar que wrangler.toml tenga el id correcto" >&2
  echo "Revisa manualmente: cat $WRANGLER_TOML" >&2
  exit 1
fi
echo "OK wrangler.toml parcheado"

# --- 4. Re-deploy backend con binding nuevo ---
echo ""
echo "--- 3. Re-deploy backend ---"
"$BACKEND_DIR/scripts/deploy_backend_prod.sh" --no-migrate

# --- 5. Smoke test ---
echo ""
echo "--- 4. Smoke test endpoint updater ---"
HTTP_CODE=$(curl -sS -o /dev/null -w "%{http_code}" -m 10 https://miloro.app/api/updater/linux-x86_64/0.0.1)
if [ "$HTTP_CODE" = "204" ]; then
  echo "OK 204 No Content (correcto, no hay manifest publicado todavía)"
else
  echo "WARN esperaba 204, recibí $HTTP_CODE"
  curl -sS -m 10 https://miloro.app/api/updater/linux-x86_64/0.0.1
fi

# --- 6. Próximos pasos ---
echo ""
echo "============================="
echo "  KV updater setup completo"
echo "============================="
echo ""
echo "Para publicar tu PRIMER manifest (cuando tengas build firmado X.Y.Z):"
echo ""
echo "  ./scripts/load_secrets.sh ./scripts/release_update.sh stable X.Y.Z \\"
echo "    --linux-url='https://github.com/.../v/X.Y.Z/MiLoro_X.Y.Z_amd64.AppImage.tar.gz' \\"
echo "    --linux-sig=\"\$(cat /home/Projects/parla/desktop/src-tauri/target/release/bundle/appimage/MiLoro_X.Y.Z_amd64.AppImage.tar.gz.sig)\" \\"
echo "    --notes='Release notes'"
echo ""
