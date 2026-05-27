# Parla — Desktop GUI MVP

App desktop cross-platform (Linux MVP, Windows/macOS proximamente) para
transcripcion local de voz a texto usando Whisper. **MVP en Tauri 2 +
Svelte 5 + Rust.**

> Esta carpeta es el "Bloque A" del [roadmap Parla](../ROADMAP.md). NO
> contiene aun: hotkey global, inyeccion de texto al sistema, code signing,
> RAM detector, ni cross-platform audio (CPAL). Ver §"Que falta" abajo.

## Prerequisitos

- **Rust** >= 1.77 (`curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`)
- **Node.js** >= 20 (`nvm install 20`)
- **Tauri CLI 2**:
  ```bash
  cargo install tauri-cli --version "^2.0" --locked
  ```
- **Dependencias del sistema Linux** (Ubuntu/Debian):
  ```bash
  sudo apt install -y libwebkit2gtk-4.1-dev build-essential curl wget file \
    libxdo-dev libssl-dev libayatana-appindicator3-dev librsvg2-dev \
    alsa-utils libasound2-dev
  ```
- **whisper.cpp** compilado en `/opt/whisper.cpp/main` con un modelo
  (`ggml-base.bin` o mayor) en `/opt/whisper.cpp/models/`. Ajustable
  desde la UI -> Configuracion.

## Setup inicial

```bash
cd /home/Projects/parla/desktop

# Instalar deps front
npm install

# (opcional pero recomendado) generar iconos — ver src-tauri/icons/README.md
npx tauri icon path/to/parla-logo-1024.png

# Validar que compila Rust
cd src-tauri && cargo check && cd ..
```

## Ejecutar dev

```bash
# 1) En otra terminal: arrancar el license server local
cd /home/Projects/parla/backend
npm install   # primera vez
npm run dev   # Wrangler en http://localhost:8787

# 2) En esta carpeta: lanzar la GUI
cd /home/Projects/parla/desktop
cargo tauri dev
```

La primera ejecucion tarda varios minutos (compila Tauri + plugins). Vite
arranca en 1420 y Tauri abre la ventana automaticamente.

## Build release

```bash
cargo tauri build
# bundle en src-tauri/target/release/bundle/
#   - deb/  → .deb para Linux
#   - appimage/ → .AppImage portable
#   - rpm/  → .rpm para Fedora
```

NO ejecutar build en CI sin certificados de firma — los binarios sin firmar
disparan SmartScreen/Gatekeeper en Win/Mac.

## Flujo de uso

1. **Pegar license key** (UUID) emitida por el backend
   (`POST /api/admin/issue?plan=standard` con header `X-Admin-Token`).
2. **Verificar** -> la app envia `{key, fingerprint}` a `/api/license/verify`.
3. Tras verificacion OK, se desbloquea el boton **Grabar 5s**.
4. La app graba con `arecord`, llama a `whisper.cpp`, muestra el texto y
   ofrece **Copiar al portapapeles**.

## Como esta organizado el codigo

```
desktop/
├── package.json              ← deps frontend
├── vite.config.ts            ← puerto 1420 fijo (requisito Tauri)
├── tsconfig.json
├── svelte.config.js
├── index.html                ← entry HTML
├── src/                      ← Frontend Svelte 5 (runes)
│   ├── main.ts
│   ├── App.svelte            ← UI principal — 1 ventana, 1 boton
│   └── lib/
│       ├── fingerprint.ts    ← SHA-256 device fingerprint (stub)
│       ├── license.ts        ← cliente HTTP -> backend Workers
│       └── settings.ts       ← localStorage (paths whisper/modelo)
└── src-tauri/                ← Backend Rust
    ├── Cargo.toml
    ├── build.rs
    ├── tauri.conf.json       ← ventana 600x400, identifier app.parla
    ├── capabilities/default.json ← permisos clipboard
    └── src/
        ├── main.rs           ← thin entry
        └── lib.rs            ← #[command]s: start_recording, transcribe, copy_to_clipboard
```

## Contract con el backend

El frontend pega a:

- `POST http://localhost:8787/api/license/verify` con
  `{ key: <uuid>, fingerprint: <hex 64 chars> }`.

El fingerprint en MVP es `SHA-256(userAgent|screen|tz|cpus)` calculado en
JS — debe sustituirse por uno real (cpu serial + disk UUID + hostname)
en Rust antes de lanzar a clientes (idea-170, Bloque A6).

URL backend overridable en consola del webview:
```js
localStorage.setItem('parla.backend_url', 'https://parla-license.workers.dev');
```

## Que YA funciona (MVP)

- Ventana 600x400 con header "Parla" + status line.
- Input license key + verify roundtrip al backend.
- Boton Grabar 5s -> `arecord` (Linux only).
- Transcripcion via `whisper.cpp main` -> texto en la UI.
- Boton "Copiar al portapapeles" via plugin oficial Tauri.
- Settings persistidos en localStorage (path bin/modelo).

## Que FALTA (defer post-MVP)

| # | Tarea | Bloque roadmap |
|---|---|---|
| 1 | Audio cross-platform (sustituir `arecord` por `cpal` Rust) | A3 |
| 2 | Hotkey global (sustituir `evdev`/`xdotool` por `global-hotkey` Rust) | A5 |
| 3 | Inyeccion de texto al sistema (`enigo` cross-platform) | A6 |
| 4 | Fingerprint real (CPU serial + disk UUID en Rust) | A7 |
| 5 | RAM detector + cgroup limit | A8 (idea-170 refinement) |
| 6 | Crash dumps a `~/.parla/crashes/` | A9 |
| 7 | Code signing macOS ($99/año) + Windows ($90-300/año) | B (post Day-X) |
| 8 | Streaming transcripcion (chunks 30s) | C |
| 9 | UI estados (1ª caida silenciosa retry / 2ª notify / 3ª boton reset) | A10 |

## Troubleshooting

| Sintoma | Causa probable | Fix |
|---|---|---|
| `npm install` rompe en `@tauri-apps/api` | Node < 20 | `nvm use 20` |
| `cargo tauri dev` falla por `webkit2gtk` | Falta dep de sistema | `sudo apt install libwebkit2gtk-4.1-dev` |
| Backend HTTP CORS en license verify | Worker no envia CORS | Ya soportado, comprobar logs `wrangler dev` |
| `arecord: command not found` | Falta ALSA tools | `sudo apt install alsa-utils` |
| `whisper.cpp main: command not found` | No instalado | Compilar en `/opt/whisper.cpp/` y ajustar Settings |
| Ventana en blanco al arrancar | Vite no compilo | Revisar `npm run dev` logs y puerto 1420 libre |
| `fingerprint invalid` del backend | btoa() en lugar de hex | Ya arreglado (usa WebCrypto SHA-256) |

## Por que esta estructura

- **Tauri 2** (no 1): API estable, plugins separados (no monolitos),
  capabilities granulares, mobile-ready.
- **Svelte 5 + runes** (`$state`, `$effect`): minimo bundle JS, dev rapido,
  sin React/Vue bloat.
- **Rust commands en `lib.rs`**: separado de `main.rs` para que se pueda
  testear sin arrancar la app entera (`cargo test` futuro).
- **`#[command] async fn`**: tauri ejecuta cada command en un worker thread,
  no bloquea la UI durante `whisper.cpp` (proceso de varios segundos).

---

**Mantenedor**: Marc + agente Claude evolutivo. Cualquier cambio se anota
en `/home/Projects/parla/ROADMAP.md` Bloque A.
