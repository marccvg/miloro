#!/usr/bin/env bash
# Parla desktop — setup dev Linux (alpha Marc + familiares Linux)
#
# Instala dependencias del SISTEMA (requiere sudo) y arranca la app en modo dev.
# Compatible con Ubuntu/Debian 22.04+ y derivados.
#
# Uso:
#   bash setup_dev_linux.sh           # instala + arranca dev
#   bash setup_dev_linux.sh --no-run  # solo instala, no arranca
#
# Una vez ejecutado, futuras ejecuciones (sin tocar deps):
#   cd /home/Projects/parla/desktop && npm run tauri:dev

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "── Parla setup dev Linux ──"

# ---- 1. Dependencias del sistema (Tauri requiere WebKit GTK) ----
NEEDED_PKGS=(
    libwebkit2gtk-4.1-dev
    libjavascriptcoregtk-4.1-dev
    libgtk-3-dev
    libayatana-appindicator3-dev
    librsvg2-dev
    libssl-dev
    pkg-config
    build-essential
    curl
    alsa-utils         # arecord para captura audio MVP
    wl-clipboard       # wl-copy para portapapeles Wayland
    xclip              # xclip para portapapeles X11
    xdotool            # inyección texto futura (A6)
)

MISSING=()
for p in "${NEEDED_PKGS[@]}"; do
    if ! dpkg -s "$p" >/dev/null 2>&1; then
        MISSING+=("$p")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    echo "Instalando: ${MISSING[*]}"
    sudo apt-get update
    sudo apt-get install -y "${MISSING[@]}"
else
    echo "Todas las deps de sistema ya instaladas. ✓"
fi

# ---- 2. Rust toolchain ----
if ! command -v cargo >/dev/null 2>&1 && ! [ -x "$HOME/.cargo/bin/cargo" ]; then
    echo "Instalando Rust toolchain (user-space, sin sudo)..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env"
fi
export PATH="$HOME/.cargo/bin:$PATH"
# Persistir PATH Rust en ~/.bashrc para que futuros terminales lo tengan
if [ -f "$HOME/.cargo/env" ] && ! grep -q "cargo/env" "$HOME/.bashrc" 2>/dev/null; then
    echo '. "$HOME/.cargo/env"' >> "$HOME/.bashrc"
    echo "  → Añadido cargo/env a ~/.bashrc para futuros terminales"
fi
echo "Rust: $(cargo --version)"

# ---- 3. audio_a_texto disponible? ----
if [ ! -x /home/scripts/audio_a_texto ] && [ ! -x "$HOME/scripts/audio_a_texto" ]; then
    echo "⚠️  No se encuentra /home/scripts/audio_a_texto"
    echo "    Es el backend de transcripción default en MVP."
    echo "    Si vas a usar whisper.cpp en su lugar:"
    echo "       1. cd ~ && git clone https://github.com/ggerganov/whisper.cpp"
    echo "       2. cd whisper.cpp && make"
    echo "       3. bash ./models/download-ggml-model.sh medium"
    echo "       4. Settings de Parla: whisperBin=/path/to/whisper.cpp/main · modelPath=/path/to/ggml-medium.bin"
fi

# ---- 4. npm deps ----
if [ ! -d node_modules ]; then
    echo "Instalando deps npm..."
    npm install
else
    echo "node_modules existe. ✓"
fi

# ---- 5. Arranque dev ----
if [ "${1:-}" = "--no-run" ]; then
    echo ""
    echo "Setup completado. Para arrancar:"
    echo "   cd $SCRIPT_DIR && npm run tauri:dev"
    exit 0
fi

echo ""
echo "Arrancando Parla en modo dev..."
echo "(Ctrl-C para parar)"
npm run tauri:dev
