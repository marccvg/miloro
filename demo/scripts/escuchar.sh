#!/usr/bin/env bash
# Oído Digital — toggle de servicio de fondo (demo portable).
#
# Diseñado para invocarse como `start`/`stop`/`toggle`. En la demo se enlaza
# como atajo GNOME Super+Z en modo toggle: 1ª pulsación arranca arecord;
# 2ª pulsación detiene, transcribe, copia al portapapeles y (si OIDO_AUTOTYPE=1)
# escribe el texto en la ventana enfocada.
#
# Auto-stop por silencio: si OIDO_AUTOSTOP_SILENCE>0, el watchdog para
# automáticamente tras N segundos de silencio sostenido (recomendado en demo
# para que el usuario no tenga que pulsar dos veces).
#
# El daemon (oido_daemon.py) mantiene el modelo Whisper precargado.

set -uo pipefail

# Resuelve INSTALL_DIR como el padre del directorio del propio script.
# Estructura esperada:  $INSTALL_DIR/scripts/escuchar.sh, $INSTALL_DIR/.venv/...
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
INSTALL_DIR="$(dirname "$SCRIPT_DIR")"

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
STATE_DIR="$RUNTIME_DIR/oido"
mkdir -p "$STATE_DIR"
chmod 0700 "$STATE_DIR" 2>/dev/null || true

WAV_FILE="$STATE_DIR/dictado.wav"
PID_FILE="$STATE_DIR/oido.pid"
LOG_FILE="$STATE_DIR/oido.log"
DAEMON_SOCK="$STATE_DIR/oido.sock"
DAEMON_PID="$STATE_DIR/oido_daemon.pid"
DAEMON_LOG="$STATE_DIR/oido_daemon.log"
LOCK_FILE="$STATE_DIR/oido.lock"

PYTHON_BIN="$INSTALL_DIR/.venv/bin/python3"
DAEMON_PY="$SCRIPT_DIR/oido_daemon.py"
CLIENT_PY="$SCRIPT_DIR/oido_client.py"

SAMPLE_RATE=16000
AUDIO_DEVICE="${OIDO_AUDIO_DEVICE:-default}"
ARECORD_BIN="${OIDO_ARECORD:-arecord}"
DAEMON_BOOT_TIMEOUT="${OIDO_DAEMON_BOOT_TIMEOUT:-30}"

export OIDO_STATE_DIR="$STATE_DIR"
export HF_HUB_DISABLE_SYMLINKS_WARNING=1
export PYTHONWARNINGS="ignore"

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

notify() {
    notify-send -a "Oído Digital" -t 2500 "$1" "${2:-}" >/dev/null 2>&1 || true
}

is_recording() {
    [[ -f "$PID_FILE" ]] || return 1
    local pid
    pid=$(cat "$PID_FILE" 2>/dev/null) || return 1
    [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

daemon_alive() {
    [[ -S "$DAEMON_SOCK" ]] || return 1
    [[ -f "$DAEMON_PID" ]] || return 1
    local pid
    pid=$(cat "$DAEMON_PID" 2>/dev/null) || return 1
    kill -0 "$pid" 2>/dev/null
}

ensure_daemon() {
    (
        flock -x -w 15 9 || { log "ensure_daemon: flock timeout"; exit 1; }
        if daemon_alive; then
            exit 0
        fi
        [[ -S "$DAEMON_SOCK" ]] && rm -f "$DAEMON_SOCK"
        log "arrancando daemon"
        setsid "$PYTHON_BIN" "$DAEMON_PY" </dev/null >>"$DAEMON_LOG" 2>&1 9>&- &
        disown $! 2>/dev/null || true
        local waited=0
        while (( waited < DAEMON_BOOT_TIMEOUT )); do
            if [[ -S "$DAEMON_SOCK" ]]; then
                log "daemon listo (waited=${waited})"
                exit 0
            fi
            sleep 0.2
            waited=$((waited + 1))
        done
        log "daemon NO arrancó (timeout=${DAEMON_BOOT_TIMEOUT}*0.2s)"
        exit 1
    ) 9>"$LOCK_FILE"
}

verify_wav() {
    "$PYTHON_BIN" - "$1" <<'PY' 2>>"$LOG_FILE"
import sys, wave
try:
    with wave.open(sys.argv[1], "rb") as w:
        if w.getnframes() < 1:
            sys.exit(2)
except Exception as e:
    sys.stderr.write(f"verify_wav: {e}\n")
    sys.exit(1)
PY
}

start_recording() {
    rm -f "$WAV_FILE"
    log "start device=$AUDIO_DEVICE wav=$WAV_FILE"
    setsid bash -c "echo \$\$ > '$PID_FILE'; exec '$ARECORD_BIN' -q -D '$AUDIO_DEVICE' -f S16_LE -c 1 -r '$SAMPLE_RATE' '$WAV_FILE'" \
        </dev/null >>"$LOG_FILE" 2>&1 &
    disown $! 2>/dev/null || true
    local waited=0
    while [[ ! -s "$PID_FILE" && $waited -lt 20 ]]; do
        sleep 0.05
        waited=$((waited + 1))
    done

    if [[ "${OIDO_AUTOSTOP_SILENCE:-0}" -gt 0 ]] 2>/dev/null; then
        notify "🎙️ Escuchando..." "Auto-stop tras ${OIDO_AUTOSTOP_SILENCE}s de silencio."
        ( silence_watchdog ) </dev/null >>"$LOG_FILE" 2>&1 &
        disown $! 2>/dev/null || true
    else
        notify "🎙️ Escuchando..." "Pulsa el atajo de nuevo para parar."
    fi
}

silence_watchdog() {
    local silence_secs="${OIDO_AUTOSTOP_SILENCE:-2}"
    local threshold="${OIDO_SILENCE_THRESHOLD:-300}"
    local warmup="${OIDO_AUTOSTOP_WARMUP:-1.5}"
    local max_secs="${OIDO_AUTOSTOP_MAX:-60}"
    local chunk_secs="0.5"
    local needed_chunks=$(( silence_secs * 2 ))

    log "watchdog: arrancado (silence=${silence_secs}s, threshold=${threshold}, warmup=${warmup}s, max=${max_secs}s)"

    sleep "$warmup"

    local consecutive_silence=0
    local started=$(date +%s)
    while true; do
        if ! is_recording; then
            log "watchdog: arecord ya no corre, saliendo"
            return
        fi
        local now elapsed
        now=$(date +%s)
        elapsed=$((now - started))
        if (( elapsed >= max_secs )); then
            log "watchdog: max_secs (${max_secs}) alcanzado, forzando stop"
            stop_and_transcribe
            return
        fi
        local rms
        rms=$("$PYTHON_BIN" - "$WAV_FILE" "$chunk_secs" "$SAMPLE_RATE" <<'PY' 2>/dev/null
import sys, os, audioop
wav, chunk_secs, sr = sys.argv[1], float(sys.argv[2]), int(sys.argv[3])
sw = 2
HEADER = 44
chunk_bytes = int(chunk_secs * sr * sw)
try:
    size = os.path.getsize(wav)
except OSError:
    print(0); sys.exit(0)
if size < HEADER + chunk_bytes:
    print(0); sys.exit(0)
with open(wav, "rb") as f:
    f.seek(size - chunk_bytes)
    data = f.read(chunk_bytes)
print(audioop.rms(data, sw) if data else 0)
PY
        )
        rms="${rms:-0}"
        if [[ "$rms" -lt "$threshold" ]] 2>/dev/null; then
            consecutive_silence=$((consecutive_silence + 1))
        else
            consecutive_silence=0
        fi
        if (( consecutive_silence >= needed_chunks )); then
            log "watchdog: silencio sostenido ${silence_secs}s (rms=$rms < $threshold), stop"
            stop_and_transcribe
            return
        fi
        sleep "$chunk_secs"
    done
}

stop_and_transcribe() {
    local ret
    (
        flock -n 9 || { log "stop ya en curso (flock), saliendo"; exit 0; }
        if [[ ! -f "$PID_FILE" ]]; then
            log "stop: pidfile ya borrado, saliendo"
            exit 0
        fi
        _stop_body
        exit $?
    ) 9>"$STATE_DIR/stop.lock"
    ret=$?
    return $ret
}

_stop_body() {
    local pid
    pid=$(cat "$PID_FILE")
    log "stop pid=$pid"
    kill -TERM "$pid" 2>/dev/null || true
    local waited=0
    while (( waited < 30 )); do
        kill -0 "$pid" 2>/dev/null || break
        sleep 0.1
        waited=$((waited + 1))
    done
    if kill -0 "$pid" 2>/dev/null; then
        log "arecord no terminó tras SIGTERM, forzando SIGKILL"
        kill -KILL "$pid" 2>/dev/null || true
        sleep 0.3
    fi
    rm -f "$PID_FILE"

    if [[ ! -s "$WAV_FILE" ]]; then
        log "wav vacío"
        notify "⚠️ Sin audio" "El WAV está vacío. Revisa el micro."
        return 1
    fi

    local size
    size=$(stat -c%s "$WAV_FILE" 2>/dev/null || echo 0)
    log "wav size=${size}B"

    if ! verify_wav "$WAV_FILE"; then
        log "wav corrupto"
        notify "⚠️ WAV corrupto" "Header inválido. Mira $LOG_FILE"
        return 1
    fi

    if ! ensure_daemon; then
        notify "⚠️ Daemon no arranca" "Mira $DAEMON_LOG"
        return 1
    fi

    notify "⏳ Transcribiendo..." "Procesando audio..."

    local resp
    resp=$("$PYTHON_BIN" "$CLIENT_PY" "$DAEMON_SOCK" "$WAV_FILE" 2>>"$LOG_FILE")
    if [[ -z "$resp" ]]; then
        log "respuesta vacía del daemon"
        notify "⚠️ Daemon mudo" "No respondió. Mira $DAEMON_LOG"
        return 1
    fi

    log "resp=${resp%$'\n'}"

    local status="${resp%%$'\t'*}"
    if [[ "$status" == "ERR" ]]; then
        local reason="${resp#ERR$'\t'}"
        reason="${reason%$'\n'}"
        case "$reason" in
            transcripcion\ vacia*)
                notify "⚠️ Transcripción vacía" "Mic mute, VAD agresivo o señal baja."
                ;;
            *)
                notify "⚠️ Error transcripción" "$reason"
                ;;
        esac
        return 1
    fi

    if [[ "$status" != "OK" ]]; then
        log "respuesta inesperada"
        notify "⚠️ Respuesta inesperada" "Mira $LOG_FILE"
        return 1
    fi

    local full
    IFS=$'\t' read -r _ chars preview full <<< "${resp%$'\n'}"
    log "ok chars=$chars"

    if [[ "${OIDO_AUTOTYPE:-1}" == "1" ]] && [[ -n "$full" ]]; then
        autotype "$full"
    fi

    notify "✅ Texto copiado" "$preview"
}

autotype() {
    local text="$1"
    if [[ -n "${WAYLAND_DISPLAY:-}" || "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
        if command -v ydotool >/dev/null 2>&1; then
            local sock="${YDOTOOL_SOCKET:-${XDG_RUNTIME_DIR:-/tmp}/.ydotool_socket}"
            if [[ -S "$sock" ]]; then
                log "autotype: ydotool (wayland, $sock) ${#text} chars"
                if YDOTOOL_SOCKET="$sock" ydotool type --next-delay 5 -- "$text" 2>>"$LOG_FILE"; then
                    return
                fi
                log "autotype: ydotool falló, intentando wtype"
            else
                log "autotype: socket ydotoold no existe ($sock); ydotoold no arrancado"
            fi
        fi
        if command -v wtype >/dev/null 2>&1; then
            log "autotype: wtype (wayland) ${#text} chars"
            if wtype -- "$text" 2>>"$LOG_FILE"; then
                return
            fi
            log "autotype: wtype falló"
        fi
        if command -v xdotool >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
            log "autotype: xdotool (xwayland fallback) ${#text} chars"
            if xdotool type --delay 5 -- "$text" 2>>"$LOG_FILE"; then
                return
            fi
            log "autotype: xdotool falló"
        fi
        notify "⚠️ Auto-type no disponible" "Instala ydotool (recomendado en GNOME Wayland) o wtype"
        log "autotype: ningún backend funcionó en Wayland"
        return
    fi
    if command -v xdotool >/dev/null 2>&1; then
        log "autotype: xdotool (x11) ${#text} chars"
        xdotool type --delay 5 -- "$text" 2>>"$LOG_FILE" || log "autotype: xdotool falló"
        return
    fi
    notify "⚠️ Auto-type no disponible" "Instala 'xdotool' con apt"
    log "autotype: xdotool no disponible en X11"
}

main() {
    case "${1:-toggle}" in
        start)
            if is_recording; then
                log "start: ya hay grabación viva pid=$(cat "$PID_FILE" 2>/dev/null), ignoro"
                return 0
            fi
            rm -f "$PID_FILE" 2>/dev/null
            start_recording
            ;;
        stop)
            if ! is_recording; then
                log "stop: no hay grabación viva, ignoro"
                return 0
            fi
            stop_and_transcribe
            ;;
        toggle|"")
            if is_recording; then
                stop_and_transcribe
            else
                rm -f "$PID_FILE" 2>/dev/null
                start_recording
            fi
            ;;
        *)
            echo "uso: $0 [start|stop|toggle]" >&2
            return 64
            ;;
    esac
}

main "$@"
