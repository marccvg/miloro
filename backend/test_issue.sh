#!/bin/bash
# Test admin issue endpoint: crea una licencia y dispara welcome email.
# Uso: ./test_issue.sh <email> [plan]
#   plan: free | standard | pro (default: pro)

set -e

EMAIL="${1:?Falta email. Uso: ./test_issue.sh tu@email.com [plan]}"
PLAN="${2:-pro}"

TOKEN_FILE="/home/marc/Escritorio/MARC/CONTRASENYES/CONTRASENYES/miloro_admin_token.txt"
if [ ! -f "$TOKEN_FILE" ]; then
  echo "ERROR: no existe $TOKEN_FILE" >&2
  exit 1
fi
ADMIN=$(cat "$TOKEN_FILE")
if [ -z "$ADMIN" ]; then
  echo "ERROR: token vacío en $TOKEN_FILE" >&2
  exit 1
fi
echo "Token len: ${#ADMIN} chars"
echo "Issue licencia para: $EMAIL (plan: $PLAN)"
echo ""

curl -s -w "\nHTTP %{http_code}\n" \
  -X POST https://miloro.app/api/license/issue \
  -H "Authorization: Bearer $ADMIN" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"plan\":\"$PLAN\"}"
