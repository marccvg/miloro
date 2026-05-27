# MiLoro 🦜

> Dictado por voz local · 100% privado · cross-platform.

Tu loro de dictado: pulsa una tecla, habla, suelta. El texto se pega donde tengas el cursor. Tu voz **nunca sale de tu equipo** — Whisper se ejecuta localmente.

🌐 **Web**: [miloro.app](https://miloro.app) · 📥 [Descargar](https://miloro.app/get-started)

---

## Stack

- **Cliente desktop**: Tauri 2 + Svelte 5 + Rust + `whisper-rs` (whisper.cpp Rust bindings)
- **Backend licencias**: Cloudflare Worker + D1 SQLite + KV (manifest updater) + R2 (releases)
- **Pagos**: Stripe Subscriptions (modo test alfa; live post-Day-X)
- **Email transaccional**: Resend
- **Auto-update**: Tauri updater plugin + manifests firmados en KV `MILORO_UPDATES`
- **i18n**: 6 idiomas — ES (default), CA (🇦🇩 Andorra), EN, FR, IT, DE

## Estructura del repo

```
miloro/
├── README.md            (este fichero)
├── ARCHITECTURE.md      arquitectura técnica completa
├── ROADMAP.md           fases producto
├── desktop/             app Tauri (cliente desktop multi-OS)
│   ├── src/             frontend Svelte
│   └── src-tauri/       backend Rust + whisper.rs + model_manager.rs + ptt.rs
├── backend/             Cloudflare Worker (license server)
│   ├── src/             TypeScript Worker code
│   ├── scripts/         deploy + release scripts (publish_release, gh_to_r2, verify_release...)
│   └── wrangler.toml
├── landing/             miloro.app HTML estático (Cloudflare Pages)
├── .github/workflows/   GitHub Actions matrix Linux+Win+Mac builds
├── legal/               PRIVACY · TERMS · DPA · AI Act pack
├── content/             blog SEO
└── brand/               iconos loro 🦜 (Noto Color Emoji + tray dinámico)
```

## Planes

| Tier | Precio | Devices | Audio/día | Modelos Whisper |
|---|---|---|---|---|
| **Free** | €0 | 1 | 30 min | hasta `small` |
| **Pro** | €9/mes (€72/año) | 3 | ilimitado | hasta `large-v3` |

## Quick start desarrollo

Ver [ARCHITECTURE.md](ARCHITECTURE.md) para detalles. Prerequisitos:
- Rust ≥ 1.77, Node.js ≥ 20, Tauri CLI 2
- Linux deps: `sudo apt install cmake build-essential clang libclang-dev libwebkit2gtk-4.1-dev libappindicator3-dev`

```bash
# Frontend dev
cd desktop && npm install && npm run tauri:dev

# Backend dev local
cd backend && npm install && wrangler dev
```

## Release multi-OS

```bash
git tag v0.0.X && git push origin v0.0.X
# GitHub Actions construye Linux + Win + Mac×2 automáticamente
# Después sync a R2 + publish manifest stable:
cd backend && ./scripts/load_secrets.sh ./scripts/gh_to_r2.sh v0.0.X --notes='...'
./scripts/verify_release.sh 0.0.X
```

## Soporte

- 📧 soporte@miloro.app
- 🌐 [miloro.app](https://miloro.app)

## Licencia

Código propietario. © 2026 Marc Vicente García · Castellón, España.
