# Parla — Alpha Linux (familia + dogfooding)

Esta carpeta contiene la app de escritorio Parla en versión alpha Linux. Pensada para que **Marc + 1-3 familiares con Linux** la prueben antes del launch público.

## Setup en 1 comando

Desde un terminal limpio en cualquier Ubuntu/Debian/Mint reciente:

```bash
cd /home/Projects/parla/desktop
bash setup_dev_linux.sh
```

El script:

1. Detecta deps de sistema faltantes (WebKit2GTK 4.1, JavaScriptCore 4.1, GTK 3, libsoup-3.0, alsa-utils, wl-clipboard, xclip, xdotool, build-essential).
2. Pide `sudo apt install` SOLO si falta algo. Si todo está, no pide nada.
3. Instala Rust user-space en `~/.cargo/` si no está.
4. `npm install` para deps del frontend.
5. Arranca `npm run tauri:dev` (la app aparece como ventana).

## Setup manual (paso a paso)

Si prefieres no ejecutar el script automáticamente:

### 1. Dependencias del sistema (sudo)

```bash
sudo apt update
sudo apt install \
    libwebkit2gtk-4.1-dev libjavascriptcoregtk-4.1-dev \
    libgtk-3-dev libayatana-appindicator3-dev librsvg2-dev libssl-dev \
    pkg-config build-essential curl \
    alsa-utils wl-clipboard xclip xdotool
```

> **Ubuntu 22.04**: usa los paquetes `4.0` en lugar de `4.1` (`libwebkit2gtk-4.0-dev`, `libjavascriptcoregtk-4.0-dev`). Tauri 2.1 prefiere `4.1` pero acepta `4.0` con feature flag.

### 2. Rust (user-space, sin sudo)

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
```

### 3. Backend de transcripción

Por defecto, Parla usa el script `audio_a_texto` que ya tienes en `/home/scripts/`:

- **Default Marc dogfooding**: `/home/scripts/audio_a_texto` (faster-whisper, modelo `medium` ya descargado).
- **Alternativa cross-platform futura**: whisper.cpp compilado. Para activarla:

```bash
cd ~
git clone https://github.com/ggerganov/whisper.cpp
cd whisper.cpp && make
bash ./models/download-ggml-model.sh medium
# Luego en Settings de Parla:
#   whisperBin = $HOME/whisper.cpp/main
#   modelPath  = $HOME/whisper.cpp/models/ggml-medium.bin
```

### 4. Frontend

```bash
cd /home/Projects/parla/desktop
npm install
```

### 5. Arrancar

```bash
npm run tauri:dev
```

Primera ejecución compila el crate Rust (~5-10 min descargando deps). Sucesivas son inmediatas.

## Probar la app

1. Abre la ventana de Parla.
2. Si no hay licencia activa, pega un UUID licencia válido (Marc te lo da) y pulsa "Verificar".
3. Una vez verde, pulsa "Grabar 5s".
4. Habla durante 5 segundos en castellano/catalán/valenciano.
5. El texto aparecerá en el área de output. Pulsa "Copiar al portapapeles".

## License key para alpha (familiares)

En esta fase **no hay Stripe live** (pendiente Day-X UJI). Marc genera keys manualmente desde el license server local:

```bash
cd /home/Projects/parla/backend
npx wrangler d1 execute parla-licenses --command "INSERT INTO licenses (key, email, plan, devices_max, status, created_at) VALUES (lower(hex(randomblob(16))), 'familiar@ejemplo.com', 'pro', 3, 'active', strftime('%s', 'now'));"
```

Eso te imprime el UUID generado. Pásaselo a tu familiar.

## Empaquetar para distribuir (AppImage / .deb)

Cuando la app funcione local, generar binario único para repartir:

```bash
cd /home/Projects/parla/desktop
npm run tauri:build
# AppImage queda en src-tauri/target/release/bundle/appimage/Parla_0.0.1_amd64.AppImage
# .deb       en src-tauri/target/release/bundle/deb/Parla_0.0.1_amd64.deb
```

El AppImage es **autocontenido**: lo pasas por Drive/WeTransfer y el familiar lo ejecuta sin instalar nada.

**Requisito en máquina familiar**: solo necesita `arecord` + `wl-clipboard`/`xclip` + un wrapper transcripción accesible.

## Troubleshooting

| Síntoma | Posible causa | Solución |
|---|---|---|
| `error: failed to run custom build command for javascriptcore-rs-sys` | Falta `libjavascriptcoregtk-4.1-dev` | `sudo apt install libjavascriptcoregtk-4.1-dev libwebkit2gtk-4.1-dev` |
| `arecord: no se pudo lanzar` | Falta alsa-utils | `sudo apt install alsa-utils` |
| `whisper binary no existe: /home/scripts/audio_a_texto` | Script Marc no presente en máquina familiar | Empaquetar `audio_a_texto` + faster-whisper en el AppImage (tarea pendiente A10') |
| "Sin texto detectado" | Micrófono no captura | Comprobar mic default del SO + permiso app |
| Compilación se cuelga >15 min | Bajada de deps Rust grande | Normal primera vez. Sucesivas son rápidas. |

## Limitaciones conocidas (alpha)

- Solo Linux. Windows/macOS pendientes de build pipeline (tarea A10).
- Push-to-talk global hotkey NO implementado (tarea A5). En alpha solo botón "Grabar 5s" en la UI.
- Inyección de texto donde está el cursor NO implementada (tarea A6). En alpha se copia al portapapeles.
- Backend audio_a_texto requiere acceso a `/home/scripts/` — empaquetar para distribución es A10.

## Siguientes pasos

1. Marc ejecuta `bash setup_dev_linux.sh` en su máquina. Reporta errores.
2. Tras `npm run tauri:dev` funcionar: probar grabación de 5s end-to-end.
3. Si OK: `npm run tauri:build` → AppImage.
4. Compartir AppImage con 1-2 familiares Linux. Recoger feedback.
5. Si valida: arrancar A5 (hotkey global) + A6 (inyección texto) + A10 (build cross-platform).
