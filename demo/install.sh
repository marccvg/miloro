#!/usr/bin/env bash
# Oído Pro — instalador portable de demo (Fase 0).
#
# Crea un install autocontenido en $HOME/.local/share/oido-pro-demo/ (o
# $OIDO_INSTALL_DIR si se exporta). No requiere sudo. Usa pip-en-venv y
# systemd-user, así que se puede deshacer completamente con uninstall.sh.
#
# Uso:
#   ./install.sh                instala todo
#   ./install.sh --dry-run      detecta deps, crea venv e instala
#                               faster-whisper en un dir bajo /tmp/, sin
#                               tocar systemd ni atajos GNOME del usuario
#   ./install.sh --help

set -uo pipefail

DRY_RUN=0
VERBOSE=0
INSTALL_DIR_OVERRIDE=""
ASSUME_YES=0

usage() {
    cat <<EOF
Uso: $0 [opciones]

Opciones:
  --dry-run            Detección de deps + venv + faster-whisper en
                       \$OIDO_DRYRUN_DIR (default /tmp/oido_pro_test).
                       NO crea unit systemd ni atajo GNOME.
  --install-dir DIR    Override del directorio de instalación.
                       Default: \$HOME/.local/share/oido-pro-demo
  --yes                No preguntar interactivamente; aceptar defaults.
  --verbose            Trazas extra (pip, etc.) por stdout.
  --help               Esta ayuda.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=1; shift ;;
        --install-dir) INSTALL_DIR_OVERRIDE="$2"; shift 2 ;;
        --yes|-y) ASSUME_YES=1; shift ;;
        --verbose|-v) VERBOSE=1; shift ;;
        --help|-h) usage; exit 0 ;;
        *) echo "✗ opción desconocida: $1" >&2; usage; exit 2 ;;
    esac
done

# ───── Localización del paquete (este script vive en demo/) ─────
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
SRC_SCRIPTS="$SCRIPT_DIR/scripts"
SRC_SHARE="$SCRIPT_DIR/share"

for required in oido_daemon.py oido_client.py escuchar.sh; do
    if [[ ! -f "$SRC_SCRIPTS/$required" ]]; then
        echo "✗ fichero fuente ausente: $SRC_SCRIPTS/$required" >&2
        exit 1
    fi
done

# ───── Destino ─────
if [[ $DRY_RUN -eq 1 ]]; then
    INSTALL_DIR="${OIDO_DRYRUN_DIR:-/tmp/oido_pro_test}"
elif [[ -n "$INSTALL_DIR_OVERRIDE" ]]; then
    INSTALL_DIR="$INSTALL_DIR_OVERRIDE"
else
    INSTALL_DIR="${OIDO_INSTALL_DIR:-$HOME/.local/share/oido-pro-demo}"
fi

VENV_DIR="$INSTALL_DIR/.venv"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
UNIT_FILE="$SYSTEMD_USER_DIR/oido-daemon.service"

CYAN=$'\e[36m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; RED=$'\e[31m'; BOLD=$'\e[1m'; RST=$'\e[0m'

say() { printf "%s\n" "$*"; }
ok()  { printf "${GREEN}✓${RST} %s\n" "$*"; }
warn(){ printf "${YELLOW}⚠${RST} %s\n" "$*"; }
err() { printf "${RED}✗${RST} %s\n" "$*" >&2; }
hdr() { printf "\n${BOLD}${CYAN}── %s ──${RST}\n" "$*"; }

# ───── 1) Detección de dependencias ─────
hdr "Detectando dependencias del sistema"

MISSING=()
MISSING_OPTIONAL=()

# python3 >= 3.10
if ! command -v python3 >/dev/null 2>&1; then
    err "python3 no encontrado"
    MISSING+=("python3 (>=3.10)")
else
    PY_VER=$(python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])')
    PY_OK=$(python3 -c 'import sys; print(1 if sys.version_info >= (3,10) else 0)')
    if [[ "$PY_OK" == "1" ]]; then
        ok "python3 $PY_VER"
    else
        err "python3 $PY_VER (se requiere >=3.10)"
        MISSING+=("python3>=3.10")
    fi
fi

# python3-venv (módulo venv disponible)
if ! python3 -c 'import venv' 2>/dev/null; then
    err "módulo 'venv' no disponible (instala 'python3-venv' con apt)"
    MISSING+=("python3-venv")
else
    ok "python3-venv"
fi

# pip
if ! python3 -m pip --version >/dev/null 2>&1; then
    warn "pip no disponible globalmente (lo bootstraping con 'ensurepip' dentro de la venv)"
fi

# ffmpeg
if command -v ffmpeg >/dev/null 2>&1; then
    ok "ffmpeg ($(ffmpeg -version 2>&1 | head -1 | awk '{print $3}'))"
else
    err "ffmpeg no encontrado (apt install ffmpeg)"
    MISSING+=("ffmpeg")
fi

# arecord (alsa-utils)
if command -v arecord >/dev/null 2>&1; then
    ok "arecord (alsa-utils)"
else
    err "arecord no encontrado (apt install alsa-utils)"
    MISSING+=("alsa-utils")
fi

# xclip (clipboard)
if command -v xclip >/dev/null 2>&1; then
    ok "xclip"
else
    err "xclip no encontrado (apt install xclip)"
    MISSING+=("xclip")
fi

# auto-type (opcional pero recomendado)
if command -v ydotool >/dev/null 2>&1; then
    ok "ydotool (auto-type Wayland)"
elif command -v wtype >/dev/null 2>&1; then
    ok "wtype (auto-type Wayland alternativo)"
elif command -v xdotool >/dev/null 2>&1; then
    ok "xdotool (auto-type X11)"
else
    warn "ningún auto-typer disponible (ydotool/wtype/xdotool). El texto se copiará al portapapeles pero NO se escribirá solo donde está el cursor. Recomendado: 'apt install ydotool'"
    MISSING_OPTIONAL+=("ydotool")
fi

# systemctl --user (solo si NO es dry-run)
if [[ $DRY_RUN -eq 0 ]]; then
    if ! systemctl --user is-system-running >/dev/null 2>&1; then
        STATE=$(systemctl --user is-system-running 2>/dev/null || echo "indisponible")
        if [[ "$STATE" == "offline" || "$STATE" == "indisponible" ]]; then
            warn "systemd --user no operativo (estado: $STATE). El daemon se podrá lanzar manualmente, pero no quedará persistente entre logins."
            MISSING_OPTIONAL+=("systemd-user-bus")
        fi
    fi

    # gsettings (atajo GNOME)
    if ! command -v gsettings >/dev/null 2>&1; then
        warn "gsettings no encontrado. No se podrá registrar el atajo Super+Z automáticamente; tendrás que crearlo a mano desde Ajustes → Teclado."
        MISSING_OPTIONAL+=("gsettings")
    fi
fi

if [[ ${#MISSING[@]} -gt 0 ]]; then
    err "Dependencias OBLIGATORIAS ausentes:"
    for m in "${MISSING[@]}"; do printf "    - %s\n" "$m"; done
    say ""
    say "En Ubuntu: ${BOLD}sudo apt install python3 python3-venv ffmpeg alsa-utils xclip ydotool${RST}"
    exit 1
fi

# ───── 2) Crear estructura de install ─────
hdr "Preparando $INSTALL_DIR"

if [[ -d "$INSTALL_DIR" ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
        warn "dry-run: limpiando install previo en $INSTALL_DIR"
        rm -rf "$INSTALL_DIR"
    else
        if [[ $ASSUME_YES -eq 1 ]]; then
            warn "install previo detectado en $INSTALL_DIR — sobreescribiendo (--yes)"
            rm -rf "$INSTALL_DIR"
        else
            warn "ya existe $INSTALL_DIR"
            read -r -p "¿Sobreescribir? [y/N] " ans
            case "$ans" in
                y|Y|yes) rm -rf "$INSTALL_DIR" ;;
                *) err "abortado por el usuario"; exit 1 ;;
            esac
        fi
    fi
fi

mkdir -p "$INSTALL_DIR/scripts"
ok "directorio creado"

# ───── 3) Crear venv ─────
hdr "Creando venv en $VENV_DIR"

if ! python3 -m venv "$VENV_DIR" 2>/tmp/oido_venv_err; then
    err "fallo creando venv:"
    cat /tmp/oido_venv_err >&2
    exit 1
fi
ok "venv creado"

VENV_PY="$VENV_DIR/bin/python3"
VENV_PIP="$VENV_DIR/bin/pip"

# upgrade pip dentro de la venv (silencioso salvo --verbose)
if [[ $VERBOSE -eq 1 ]]; then
    "$VENV_PY" -m pip install --upgrade pip
else
    "$VENV_PY" -m pip install --quiet --upgrade pip 2>/dev/null || warn "no se pudo actualizar pip (continuando)"
fi
ok "pip listo ($("$VENV_PIP" --version 2>/dev/null | awk '{print $2}' || echo "?"))"

# ───── 4) Instalar faster-whisper ─────
hdr "Instalando faster-whisper (puede tardar 1–3 min)"

PIP_FLAGS=()
[[ $VERBOSE -eq 0 ]] && PIP_FLAGS+=("--quiet")

if ! "$VENV_PIP" install "${PIP_FLAGS[@]}" "faster-whisper"; then
    err "pip install faster-whisper FALLÓ"
    err "  Posibles causas: red restringida, índice PyPI no accesible, fuera de espacio."
    err "  Logs detallados con: $VENV_PIP install faster-whisper"
    exit 1
fi
WHISPER_VER=$("$VENV_PY" -c 'import faster_whisper; print(faster_whisper.__version__)' 2>/dev/null || echo "?")
ok "faster-whisper $WHISPER_VER instalado"

# ───── 5) Copiar scripts adaptados ─────
hdr "Copiando scripts al install"

cp "$SRC_SCRIPTS/oido_daemon.py" "$INSTALL_DIR/scripts/"
cp "$SRC_SCRIPTS/oido_client.py" "$INSTALL_DIR/scripts/"
cp "$SRC_SCRIPTS/escuchar.sh"    "$INSTALL_DIR/scripts/"
chmod +x "$INSTALL_DIR/scripts/escuchar.sh"
ok "oido_daemon.py, oido_client.py, escuchar.sh"

# ───── 6) Si --dry-run, terminamos aquí ─────
if [[ $DRY_RUN -eq 1 ]]; then
    hdr "Dry-run completado"
    say "Install simulado en: $INSTALL_DIR"
    say "Tamaño total: $(du -sh "$INSTALL_DIR" 2>/dev/null | awk '{print $1}')"
    say ""
    say "Verificación rápida del cliente (sin grabar audio):"
    say "  $VENV_PY $INSTALL_DIR/scripts/oido_client.py /tmp/nonexistent.wav 2>&1 || true"
    say ""
    say "Para borrar este dry-run: rm -rf $INSTALL_DIR"
    exit 0
fi

# ───── 7) Instalar unit systemd-user ─────
hdr "Registrando servicio systemd-user"

mkdir -p "$SYSTEMD_USER_DIR"
sed "s|__INSTALL_DIR__|$INSTALL_DIR|g" "$SRC_SHARE/oido-daemon.service.template" > "$UNIT_FILE"
ok "unit en $UNIT_FILE"

if systemctl --user daemon-reload 2>/dev/null; then
    ok "systemctl --user daemon-reload"
else
    warn "systemctl --user no responde; tendrás que ejecutarlo manualmente tras login gráfico"
fi

if systemctl --user enable oido-daemon.service 2>/dev/null; then
    ok "servicio habilitado al arranque de sesión"
fi
if systemctl --user restart oido-daemon.service 2>/dev/null; then
    ok "servicio arrancado"
else
    warn "no se pudo arrancar el servicio ahora (lo intentará al próximo login gráfico)"
fi

# ───── 8) Atajo GNOME Super+Z ─────
hdr "Registrando atajo GNOME Super+Z → dictado"

GSETTINGS_OK=0
if command -v gsettings >/dev/null 2>&1; then
    SCHEMA_MK="org.gnome.settings-daemon.plugins.media-keys"
    SCHEMA_CUSTOM="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding"
    PATH_CUSTOM="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/oido-pro-demo/"

    # Capturar el array previo de custom-keybindings para poder restaurar en uninstall.
    CURRENT=$(gsettings get "$SCHEMA_MK" custom-keybindings 2>/dev/null || echo "@as []")
    printf "%s\n" "$CURRENT" > "$INSTALL_DIR/.gsettings_backup"

    case "$CURRENT" in
        *"$PATH_CUSTOM"*)
            ok "atajo ya presente en la lista (reutilizando entrada)"
            ;;
        "@as []"|"[]")
            gsettings set "$SCHEMA_MK" custom-keybindings "['$PATH_CUSTOM']" \
                && GSETTINGS_OK=1
            ;;
        *)
            # Insertar PATH_CUSTOM en el array existente.
            NEW=$(python3 -c "
import sys, ast
cur = ast.literal_eval(sys.argv[1])
if '$PATH_CUSTOM' not in cur:
    cur.append('$PATH_CUSTOM')
print(repr(cur))
" "$CURRENT" 2>/dev/null)
            if [[ -n "$NEW" ]]; then
                gsettings set "$SCHEMA_MK" custom-keybindings "$NEW" \
                    && GSETTINGS_OK=1
            fi
            ;;
    esac

    gsettings set "$SCHEMA_CUSTOM:$PATH_CUSTOM" name "Oído Pro — dictado" 2>/dev/null
    # Variables que el atajo debe heredar:
    #   OIDO_AUTOSTOP_SILENCE=2 → para auto-stop al callar 2s.
    #   OIDO_AUTOTYPE=1 → auto-escritura en ventana enfocada.
    gsettings set "$SCHEMA_CUSTOM:$PATH_CUSTOM" command \
        "env OIDO_AUTOSTOP_SILENCE=2 OIDO_AUTOTYPE=1 $INSTALL_DIR/scripts/escuchar.sh toggle" 2>/dev/null
    gsettings set "$SCHEMA_CUSTOM:$PATH_CUSTOM" binding "<Super>z" 2>/dev/null

    if [[ $GSETTINGS_OK -eq 1 ]]; then
        ok "atajo Super+Z registrado"
    else
        warn "no se pudo modificar el array de custom-keybindings de GNOME — comprueba en Ajustes → Teclado → Atajos personalizados"
    fi
else
    warn "gsettings ausente — registra el atajo a mano:"
    say "  Ajustes → Teclado → Ver y personalizar atajos → Personalizados"
    say "  Comando: env OIDO_AUTOSTOP_SILENCE=2 OIDO_AUTOTYPE=1 $INSTALL_DIR/scripts/escuchar.sh toggle"
    say "  Binding: Super+Z"
fi

# ───── 9) Resumen ─────
hdr "Resumen"
ok "instalado en: $INSTALL_DIR"
ok "uninstall:    $SCRIPT_DIR/uninstall.sh"
say ""
say "${GREEN}${BOLD}Demo lista. Presiona Super+Z para activar dictado donde tengas el cursor.${RST}"
say ""
say "Truco: tras pulsar Super+Z, habla. La grabación se detiene sola tras 2s de silencio."
say "Si el daemon no estaba aún cargado, la primera transcripción tardará 2-3s; las siguientes serán inmediatas."
