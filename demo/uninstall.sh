#!/usr/bin/env bash
# Oído Pro — desinstalador de la demo (Fase 0).
#
# Revertir todo lo que install.sh hizo:
#   - parar y deshabilitar el servicio systemd-user
#   - borrar la unit de ~/.config/systemd/user/
#   - quitar el atajo GNOME Super+Z (y restaurar el array previo si lo guardamos)
#   - borrar el directorio de instalación entero
#
# Uso:
#   ./uninstall.sh              borra $HOME/.local/share/oido-pro-demo
#   ./uninstall.sh --install-dir DIR
#   ./uninstall.sh --yes        sin preguntar
#
# No requiere sudo.

set -uo pipefail

INSTALL_DIR_OVERRIDE=""
ASSUME_YES=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --install-dir) INSTALL_DIR_OVERRIDE="$2"; shift 2 ;;
        --yes|-y) ASSUME_YES=1; shift ;;
        --help|-h)
            cat <<EOF
Uso: $0 [--install-dir DIR] [--yes]
Desinstala la demo: para systemd-user unit, retira atajo GNOME, borra el install.
EOF
            exit 0
            ;;
        *) echo "✗ opción desconocida: $1" >&2; exit 2 ;;
    esac
done

INSTALL_DIR="${INSTALL_DIR_OVERRIDE:-${OIDO_INSTALL_DIR:-$HOME/.local/share/oido-pro-demo}}"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
UNIT_FILE="$SYSTEMD_USER_DIR/oido-daemon.service"

GREEN=$'\e[32m'; YELLOW=$'\e[33m'; RED=$'\e[31m'; BOLD=$'\e[1m'; RST=$'\e[0m'
ok()   { printf "${GREEN}✓${RST} %s\n" "$*"; }
warn() { printf "${YELLOW}⚠${RST} %s\n" "$*"; }
err()  { printf "${RED}✗${RST} %s\n" "$*" >&2; }

if [[ ! -d "$INSTALL_DIR" && ! -f "$UNIT_FILE" ]]; then
    warn "nada que desinstalar (ni $INSTALL_DIR ni $UNIT_FILE existen)"
    exit 0
fi

if [[ $ASSUME_YES -eq 0 ]]; then
    printf "${BOLD}Se va a borrar:${RST}\n"
    [[ -d "$INSTALL_DIR" ]] && printf "  - $INSTALL_DIR (%s)\n" "$(du -sh "$INSTALL_DIR" 2>/dev/null | awk '{print $1}')"
    [[ -f "$UNIT_FILE" ]] && printf "  - $UNIT_FILE\n"
    printf "  - atajo GNOME Super+Z asociado a Oído Pro (si está)\n"
    read -r -p "¿Continuar? [y/N] " ans
    case "$ans" in
        y|Y|yes) : ;;
        *) err "cancelado"; exit 1 ;;
    esac
fi

# ───── 1) Servicio systemd-user ─────
if [[ -f "$UNIT_FILE" ]]; then
    systemctl --user stop oido-daemon.service 2>/dev/null && ok "servicio parado" \
        || warn "servicio no estaba activo"
    systemctl --user disable oido-daemon.service 2>/dev/null && ok "servicio deshabilitado" \
        || warn "servicio no estaba habilitado"
    rm -f "$UNIT_FILE"
    ok "unit eliminada: $UNIT_FILE"
    systemctl --user daemon-reload 2>/dev/null && ok "daemon-reload"
fi

# ───── 2) Atajo GNOME ─────
if command -v gsettings >/dev/null 2>&1; then
    SCHEMA_MK="org.gnome.settings-daemon.plugins.media-keys"
    SCHEMA_CUSTOM="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding"
    PATH_CUSTOM="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/oido-pro-demo/"

    BACKUP_FILE="$INSTALL_DIR/.gsettings_backup"
    if [[ -f "$BACKUP_FILE" ]]; then
        OLD=$(cat "$BACKUP_FILE")
        gsettings set "$SCHEMA_MK" custom-keybindings "$OLD" 2>/dev/null \
            && ok "lista de atajos GNOME restaurada (estado previo: $OLD)"
    else
        # Quitar nuestro path del array sin tocar otros.
        CURRENT=$(gsettings get "$SCHEMA_MK" custom-keybindings 2>/dev/null || echo "[]")
        NEW=$(python3 -c "
import sys, ast
cur = ast.literal_eval(sys.argv[1])
cur = [c for c in cur if c != '$PATH_CUSTOM']
print(repr(cur) if cur else '@as []')
" "$CURRENT" 2>/dev/null) || NEW="@as []"
        gsettings set "$SCHEMA_MK" custom-keybindings "$NEW" 2>/dev/null \
            && ok "atajo Super+Z retirado del array GNOME"
    fi

    # Reset de la entrada concreta (por si quedaba).
    gsettings reset-recursively "$SCHEMA_CUSTOM:$PATH_CUSTOM" 2>/dev/null \
        && ok "entrada de atajo reseteada"
fi

# ───── 3) Borrar install dir ─────
if [[ -d "$INSTALL_DIR" ]]; then
    rm -rf "$INSTALL_DIR"
    ok "borrado: $INSTALL_DIR"
fi

# ───── 4) State runtime ─────
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/oido"
if [[ -d "$STATE_DIR" ]]; then
    rm -rf "$STATE_DIR"
    ok "estado runtime limpiado: $STATE_DIR"
fi

printf "\n${GREEN}${BOLD}Desinstalación completa.${RST}\n"
printf "Si el daemon estaba cargado y queda algún proceso, refresca la sesión gráfica (logout/login).\n"
