#!/usr/bin/env bash
# MiLoro launcher — arranca el backend wrangler en background si no está corriendo,
# luego abre la app Tauri compilada.
#
# Pensado para usarse desde el icono escritorio (.desktop).
# Cuando deployemos el backend a Cloudflare cloud, este script se simplifica
# a "ejecuta el binario" (sin arrancar wrangler local).

set -e

MILORO_DESKTOP_DIR="/home/Projects/parla/desktop"
MILORO_BACKEND_DIR="/home/Projects/parla/backend"
APP_BIN_REL_PATH="src-tauri/target/release/miloro-desktop"
WRANGLER_LOG="$HOME/.local/share/miloro/wrangler.log"
WRANGLER_PID_FILE="$HOME/.local/share/miloro/wrangler.pid"

mkdir -p "$(dirname "$WRANGLER_LOG")"

# --- 1. Verificar que el backend está corriendo en :8787 ---
backend_alive() {
    curl -s --max-time 1 -o /dev/null -w "%{http_code}" http://localhost:8787/health 2>/dev/null | grep -q "^[12]"
}

if backend_alive; then
    echo "✓ Backend ya activo en :8787" >&2
else
    echo "↻ Arrancando backend wrangler en background..." >&2
    # Cargar PATH user (cargo, npm)
    [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
    cd "$MILORO_BACKEND_DIR"
    nohup npx wrangler dev > "$WRANGLER_LOG" 2>&1 &
    echo $! > "$WRANGLER_PID_FILE"

    # Esperar hasta 30s a que el backend esté listo
    for i in {1..30}; do
        sleep 1
        if backend_alive; then
            echo "✓ Backend listo (PID $(cat "$WRANGLER_PID_FILE"))" >&2
            break
        fi
    done
    if ! backend_alive; then
        notify-send -u critical "MiLoro" "No se pudo arrancar el backend. Revisa $WRANGLER_LOG" 2>/dev/null || \
            echo "ERROR: backend no arrancó. Revisa $WRANGLER_LOG" >&2
        exit 1
    fi
fi

# --- 2. Lanzar la app Tauri compilada ---
APP_BIN="$MILORO_DESKTOP_DIR/$APP_BIN_REL_PATH"
if [ ! -x "$APP_BIN" ]; then
    notify-send -u critical "MiLoro" "Binario no encontrado: $APP_BIN. ¿Has hecho 'npm run tauri:build'?" 2>/dev/null
    echo "ERROR: binario no encontrado en $APP_BIN" >&2
    exit 1
fi

exec "$APP_BIN" "$@"
