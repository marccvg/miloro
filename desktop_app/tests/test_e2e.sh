#!/usr/bin/env bash
# test_e2e.sh — suite de tests end-to-end para Parla
# Ejecutar ANTES de cualquier release o tras cambios en daemon/escuchar.sh
#
# Uso:
#   bash /home/Projects/parla/desktop_app/tests/test_e2e.sh
#   bash /home/Projects/parla/desktop_app/tests/test_e2e.sh --verbose
#
# Sale con código 0 si todo OK, ≠0 si algún test falla.

set -u
VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

PASS=0
FAIL=0
WARN=0
FAILED_TESTS=()

log_pass() { echo "  ✅ $1"; ((PASS++)); }
log_fail() { echo "  ❌ $1"; FAILED_TESTS+=("$1"); ((FAIL++)); }
log_warn() { echo "  ⚠️  $1"; ((WARN++)); }
log_info() { [[ $VERBOSE -eq 1 ]] && echo "      $1"; }

section() { echo ""; echo "=== $1 ==="; }

# ─── Test 1: dependencias sistema ───────────────────────────────────
section "1. Dependencias sistema"
for bin in arecord ffmpeg ydotool wl-copy wl-paste xclip python3 systemctl; do
    if command -v "$bin" >/dev/null 2>&1; then
        log_pass "$bin instalado"
    else
        log_fail "$bin NO encontrado"
    fi
done

# ─── Test 2: ficheros + permisos ────────────────────────────────────
section "2. Ficheros + permisos"
for f in /home/claude/scripts/oido_daemon.py /home/claude/scripts/oido_ptt.py /home/claude/scripts/escuchar.sh /home/scripts/audio_a_texto; do
    if [[ -r "$f" ]]; then
        log_pass "$f legible"
    else
        log_fail "$f NO legible"
    fi
done
[[ -x /home/claude/scripts/escuchar.sh ]] && log_pass "escuchar.sh ejecutable" || log_fail "escuchar.sh NO ejecutable"

# ─── Test 3: syntax Python + Bash ───────────────────────────────────
section "3. Syntax"
python3 -c "import ast; ast.parse(open('/home/claude/scripts/oido_daemon.py').read())" 2>/dev/null \
    && log_pass "oido_daemon.py syntax OK" || log_fail "oido_daemon.py syntax FAIL"
python3 -c "import ast; ast.parse(open('/home/claude/scripts/oido_ptt.py').read())" 2>/dev/null \
    && log_pass "oido_ptt.py syntax OK" || log_fail "oido_ptt.py syntax FAIL"
bash -n /home/claude/scripts/escuchar.sh 2>/dev/null \
    && log_pass "escuchar.sh syntax OK" || log_fail "escuchar.sh syntax FAIL"

# ─── Test 4: clipboard básico ───────────────────────────────────────
section "4. Clipboard funcional"
TEST_STR="test_ñ_ó_á_$(date +%s)"
if echo -n "$TEST_STR" | wl-copy 2>/dev/null; then
    sleep 0.2
    RECV=$(wl-paste 2>/dev/null)
    if [[ "$RECV" == "$TEST_STR" ]]; then
        log_pass "wl-copy/wl-paste roundtrip OK (UTF-8 preservado)"
    else
        log_fail "wl-paste devuelve distinto: got='$RECV' want='$TEST_STR'"
    fi
else
    log_warn "wl-copy falló (puede no estar en sesión Wayland activa)"
fi

# ─── Test 5: ydotool socket ─────────────────────────────────────────
section "5. ydotool socket"
YDOTOOL_SOCK="${XDG_RUNTIME_DIR:-/tmp}/.ydotool_socket"
if [[ -S "$YDOTOOL_SOCK" ]]; then
    log_pass "ydotoold socket presente en $YDOTOOL_SOCK"
else
    log_warn "ydotoold socket NO encontrado — autotype no funcionará. Arrancar ydotoold user-systemd"
fi

# ─── Test 6: daemon corriendo ───────────────────────────────────────
section "6. Daemon oido"
DAEMON_STATE=$(systemctl --user is-active oido-daemon.service 2>/dev/null)
if [[ "$DAEMON_STATE" == "active" ]]; then
    log_pass "oido-daemon.service activo"
else
    log_fail "oido-daemon.service NO activo (estado: $DAEMON_STATE)"
fi
PTT_STATE=$(systemctl --user is-active oido-ptt.service 2>/dev/null)
if [[ "$PTT_STATE" == "active" ]]; then
    log_pass "oido-ptt.service activo"
else
    log_fail "oido-ptt.service NO activo (estado: $PTT_STATE)"
fi
LINGER=$(loginctl show-user "$USER" 2>/dev/null | grep -i Linger | cut -d= -f2)
if [[ "$LINGER" == "yes" ]]; then
    log_pass "linger habilitado (sobrevive logout/reboot)"
else
    log_warn "linger NO habilitado — services no sobreviven logout. Ejecutar: sudo loginctl enable-linger $USER"
fi

# ─── Test 7: env vars críticas del daemon ───────────────────────────
section "7. Environment daemon"
ENV_OUTPUT=$(systemctl --user show oido-daemon.service 2>/dev/null | grep -i "^Environment=" | head -1)
for var in WAYLAND_DISPLAY DISPLAY WHISPER_MODEL WHISPER_LANGUAGE WHISPER_BEAM_SIZE; do
    if echo "$ENV_OUTPUT" | grep -q "$var="; then
        log_pass "$var configurado en service"
    else
        log_fail "$var FALTA en service"
    fi
done

# ─── Test 8: audio_a_texto standalone ───────────────────────────────
section "8. audio_a_texto CLI"
# Grabar 2s + transcribir + verificar output
TEST_WAV="/tmp/parla_test_$$.wav"
TEST_TXT="/tmp/parla_test_$$.txt"
if arecord -q -d 1 -f S16_LE -r 16000 -c 1 "$TEST_WAV" 2>/dev/null; then
    log_pass "arecord 1s grabó WAV"
    OUTPUT=$(/home/scripts/audio_a_texto --stdout "$TEST_WAV" 2>&1 | tail -1)
    if [[ -n "$OUTPUT" ]]; then
        log_pass "audio_a_texto transcribió (output: '${OUTPUT:0:60}')"
    else
        log_warn "audio_a_texto sin output (audio silencioso, esperado en test)"
    fi
    rm -f "$TEST_WAV" "$TEST_TXT"
else
    log_fail "arecord no pudo grabar"
fi

# ─── Test 9: socket daemon vivo ─────────────────────────────────────
section "9. Daemon socket Unix"
SOCK="${XDG_RUNTIME_DIR:-/tmp}/oido/oido.sock"
if [[ -S "$SOCK" ]]; then
    log_pass "Socket daemon presente en $SOCK"
else
    log_fail "Socket daemon NO encontrado — daemon no responde"
fi

# ─── Test 10: Flask backend (si esperamos que esté corriendo) ───────
section "10. Backend Flask Parla"
if curl -sf -m 2 http://localhost:4331/api/status >/dev/null 2>&1; then
    log_pass "Flask /api/status responde"
    STATUS=$(curl -sf -m 2 http://localhost:4331/api/status 2>/dev/null)
    log_info "Status: $STATUS"
else
    log_warn "Flask backend NO corriendo en :4331 (opcional)"
fi

# ─── Resumen ────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════"
echo "RESUMEN:"
echo "  ✅ PASS: $PASS"
echo "  ⚠️  WARN: $WARN"
echo "  ❌ FAIL: $FAIL"
if [[ $FAIL -gt 0 ]]; then
    echo ""
    echo "Tests fallados:"
    for t in "${FAILED_TESTS[@]}"; do
        echo "  - $t"
    done
    exit 1
fi
echo ""
echo "✅ TODOS LOS TESTS OK — sistema listo"
exit 0
