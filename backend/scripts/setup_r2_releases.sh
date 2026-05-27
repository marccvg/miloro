#!/bin/bash
# Setup one-time del bucket R2 'miloro-releases' para hostear AppImages.
#
# Marc ejecuta:
#   ./scripts/load_secrets.sh ./scripts/setup_r2_releases.sh
#
# Hace:
#   1. Crea bucket 'miloro-releases' (idempotente, ignora "already exists")
#   2. Imprime instrucciones para activar Public Access en dashboard (no hay CLI hoy)
#   3. Cuando Marc tenga el R2.dev URL público, lo guarda en /home/marc/.secrets/miloro_r2_public_base

set -euo pipefail

BUCKET="miloro-releases"

echo "--- 1. Crear bucket R2 '$BUCKET' ---"
if wrangler r2 bucket create "$BUCKET" 2>&1 | tee /tmp/r2-create.log; then
  echo "  OK creado"
elif grep -qi "already exists\|10004" /tmp/r2-create.log; then
  echo "  ya existía → skip"
else
  echo "  ERROR creando bucket — revisa /tmp/r2-create.log"
  exit 1
fi

echo ""
echo "============================="
echo "  Pasos manuales en dashboard CF (1 minuto)"
echo "============================="
cat <<EOF

1. Abre: https://dash.cloudflare.com → R2 → miloro-releases → Settings

2. **Public access** → "Allow access" → "R2.dev subdomain"
   Te dará una URL tipo:  https://pub-XXXXXXXXXXXXXXXXXX.r2.dev
   (NO necesitas custom domain todavía — esa URL funciona perfecto para test)

3. Cópiala y guarda en local:
   nano /home/marc/.secrets/miloro_r2_public_base
   (pega la URL completa, sin slash final)
   chmod 600 /home/marc/.secrets/miloro_r2_public_base

4. (OPCIONAL futuro) Custom domain downloads.miloro.app:
   Settings → Custom Domains → Connect Domain → "downloads.miloro.app"
   Cloudflare crea CNAME automático en tu zona miloro.app.
   Cuando esté listo, sustituye el contenido de miloro_r2_public_base por:
     https://downloads.miloro.app

5. Cuando los pasos 1-3 estén hechos, ejecuta:
   ./scripts/load_secrets.sh ./scripts/publish_release.sh 0.0.5

EOF
