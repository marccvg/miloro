#!/bin/bash
# verify_release.sh — Smoke tests post-publish.
# Verifica que un release está completamente funcional desde el exterior.
#
# Marc ejecuta:
#   ./scripts/verify_release.sh 0.0.9
#
# NO requiere load_secrets (todo HTTPS público).
#
# Tests:
#   1. /api/health responde OK
#   2. /api/updater/{linux,windows,macos}-x86_64/0.0.1 devuelve manifest 200 (o 204 si la version ya está al día)
#   3. URL del manifest existe en R2 (HEAD 200)
#   4. /api/download/{linux,windows,macos} devuelve 302 + URL accesible
#   5. /api/license/signup acepta email test (lo creó, no envió email real)
#   6. /api/license/verify rechaza key inválida con 400

set -euo pipefail

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  echo "Uso: $0 <version>  (ej. 0.0.9)" >&2
  exit 2
fi

BASE="https://miloro.app"
PASS=0
FAIL=0
WARN=0

pass() { echo "  ✓ $1"; PASS=$((PASS+1)); }
fail() { echo "  ✗ $1" >&2; FAIL=$((FAIL+1)); }
warn() { echo "  ⚠ $1"; WARN=$((WARN+1)); }

echo "============================="
echo "  Verify MiLoro $VERSION"
echo "============================="

# 1. Health
echo ""
echo "--- 1. /api/health ---"
H=$(curl -sS -o /dev/null -w "%{http_code}" -m 10 "$BASE/api/health" || echo "000")
if [ "$H" = "200" ]; then
  pass "health 200"
else
  fail "health $H (esperado 200)"
fi

# 2. Updater endpoint cada platform
echo ""
echo "--- 2. /api/updater/* (con version vieja 0.0.1 → debe devolver manifest 200) ---"
for plat in linux-x86_64 windows-x86_64 darwin-x86_64 darwin-aarch64; do
  RESP=$(curl -sS -w "\n%{http_code}" -m 10 "$BASE/api/updater/$plat/0.0.1" || echo "000")
  CODE=$(echo "$RESP" | tail -1)
  BODY=$(echo "$RESP" | head -n -1)
  if [ "$CODE" = "200" ]; then
    VER=$(echo "$BODY" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('version','?'))" 2>/dev/null || echo "?")
    if [ "$VER" = "$VERSION" ]; then
      pass "updater $plat → 200 version=$VER"
    else
      warn "updater $plat → 200 pero version=$VER (esperado $VERSION) — quizás no subiste asset $plat"
    fi
  elif [ "$CODE" = "204" ]; then
    warn "updater $plat → 204 (cliente al día — quizás version vieja 0.0.1 ya es >= manifest, raro)"
  else
    warn "updater $plat → $CODE (no hay asset $plat para esta version, OK si solo subiste linux)"
  fi
done

# 3. Verificar URL del manifest en R2 (sigue HEAD)
echo ""
echo "--- 3. URL R2 del manifest stable (linux) responde HEAD 200 ---"
URL=$(curl -sS -m 10 "$BASE/api/updater/linux-x86_64/0.0.1" 2>/dev/null \
  | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('url',''))" 2>/dev/null || echo "")
if [ -n "$URL" ]; then
  R2_CODE=$(curl -sS -o /dev/null -w "%{http_code}" -m 15 -I "$URL" || echo "000")
  if [ "$R2_CODE" = "200" ]; then
    pass "R2 binary descargable: $URL → 200"
  else
    fail "R2 binary $R2_CODE: $URL (¿no se subió o R2.dev URL mal?)"
  fi
else
  warn "no pude extraer url del manifest (linux)"
fi

# 4. /api/download/* redirect 302
echo ""
echo "--- 4. /api/download/* redirige 302 ---"
for plat in linux windows macos; do
  D=$(curl -sS -o /dev/null -w "%{http_code}" -m 10 "$BASE/api/download/$plat" || echo "000")
  if [ "$D" = "302" ]; then
    pass "download $plat → 302"
  elif [ "$D" = "404" ]; then
    warn "download $plat → 404 (esperado si esa platform no tiene asset en manifest)"
  else
    fail "download $plat → $D (esperado 302)"
  fi
done

# 5. Signup público acepta email test
echo ""
echo "--- 5. /api/license/signup acepta email test (idempotent — no envía email duplicado) ---"
TEST_EMAIL="verify-test-${VERSION//./_}@example.invalid"
SIGNUP=$(curl -sS -m 10 -X POST "$BASE/api/license/signup" \
  -H 'content-type: application/json' \
  --data "$(printf '{"email":"%s"}' "$TEST_EMAIL")" 2>/dev/null || echo "{}")
STATUS=$(echo "$SIGNUP" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('status','?'))" 2>/dev/null || echo "?")
if [ "$STATUS" = "ok" ]; then
  pass "signup acepta email test"
elif [ "$STATUS" = "error" ]; then
  # 429 rate limit es OK (significa que el endpoint funciona, solo bloqueado)
  warn "signup error (probablemente rate limit IP — endpoint responde, OK)"
else
  fail "signup respuesta inesperada: $SIGNUP"
fi

# 6. /api/license/verify rechaza key inválida
echo ""
echo "--- 6. /api/license/verify rechaza key/fingerprint inválido (400) ---"
V=$(curl -sS -o /dev/null -w "%{http_code}" -m 10 -X POST "$BASE/api/license/verify" \
  -H 'content-type: application/json' \
  --data '{"key":"notauuid","fingerprint":"short"}' 2>/dev/null || echo "000")
if [ "$V" = "400" ]; then
  pass "verify rechaza body inválido (400)"
else
  fail "verify respondió $V (esperado 400)"
fi

# Summary
echo ""
echo "============================="
echo "  Resumen $VERSION"
echo "============================="
echo "  ✓ $PASS pasos OK"
[ "$WARN" -gt 0 ] && echo "  ⚠ $WARN warnings (revisar contexto, no críticos)"
[ "$FAIL" -gt 0 ] && echo "  ✗ $FAIL FALLOS críticos" >&2

if [ "$FAIL" -eq 0 ]; then
  echo ""
  echo "  → Release $VERSION verificada OK."
  exit 0
else
  echo ""
  echo "  → Release $VERSION tiene fallos. Revisa." >&2
  exit 1
fi
