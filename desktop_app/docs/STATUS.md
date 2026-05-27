# Estado proyecto Parla — 2026-05-16

## ✅ Lo que YA existe

### Infraestructura técnica (HEREDADA, funciona)
- `oido_daemon.py` — daemon Whisper preloaded en RAM (CPU int8)
- `oido_ptt.py` — listener tecla (Right Ctrl) → invoca escuchar.sh
- `escuchar.sh` — grabar arecord + transcribir vía socket Unix daemon + paste
- `audio_a_texto` — CLI alternativo para transcribir ficheros
- `rewriter.py` — post-procesado opcional con Phi-3 local
- `benchmark.py` — métricas calidad/velocidad de modelos

### Configuración actual VERIFICADA (Marc usa diariamente)
- Modelo: `medium` (CPU int8) — balance calidad/velocidad
- BEAM_SIZE: 5 (mejor que default 1)
- VAD: 0 (procesa todo sin recortar silencios)
- INITIAL_PROMPT: prompt rico con palabras tildadas + tecnicismos
- WAYLAND_DISPLAY + DISPLAY explícitos (fix env vars)
- Autotype: Ctrl+Shift+V + Ctrl+V (cubre terminales + editores)
- Save/restore clipboard (NO sacrifica copia previa usuario)
- Persistencia: enabled systemd-user + linger (sobrevive reinicios)

### Frontend / UX (NUEVO 2026-05-16)
- ✅ `desktop_app/mockup/index.html` — UI completa de la app (dark theme, una ventana)
- ✅ Servida en `http://localhost:4330` (puro HTML)
- ✅ Servida también en `http://localhost:4331` (conectada al backend Flask)

### Backend dogfooding (NUEVO 2026-05-16)
- ✅ `desktop_app/server/app.py` — Flask backend
- ✅ Endpoints: GET/POST /api/config, GET /api/status, POST /api/test/record, GET /api/logs
- ✅ Mockup HTML conectado al backend (loadConfig, saveConfig, testRecord, polling status)
- ✅ Lee/escribe `~/.config/systemd/user/oido-daemon.service` Environment vars
- ✅ `systemctl daemon-reload + restart` al guardar
- ✅ `parla-config-server.service` para arranque automático user-systemd

### Materiales producto (HEREDADOS Marc)
- `README.md`, `LAUNCH_PACK.md`, `ROADMAP.md` (legacy planificación)
- `pricing/` — análisis competencia + precio recomendado
- `legal/` — DPA template + whitepaper AI Act + FAQ legal
- `outreach/` — plantillas email B2B construcción (Fase 1 piloto)
- `clientes/piloto_construccion_familiar/` — material caso piloto
- `validacion/plan_pymes_piloto.md` — plan validación

### Idea documentada
- ✅ `idea-170-transcripcion-b2c-pago-unico.md` — pivote B2B→B2C, modelo dual 77€ Lite + 7€/mes Pro

## ⏳ Lo que FALTA hacer

### Fase 2 — Refinar dogfooding (1-2 sem uso Marc diario)
- [ ] Marc abre `http://localhost:4331` y configura desde web
- [ ] Marc usa diariamente, anota bugs en `docs/DOGFOOD_FEEDBACK.md`
- [ ] Mejorar UX según hallazgos:
  - [ ] Loading spinner mientras restart daemon
  - [ ] Toast notifications mejores (ahora básico)
  - [ ] Persistencia config en localStorage para offline UI
  - [ ] Detección y aviso si daemon no arrancado
  - [ ] Tray icon (notif bandeja) — opcional, baja prioridad
- [ ] Auto-launch: `parla-config-server.service` enable+start
- [ ] Desktop entry `.desktop` para abrir interfaz en Chrome app mode

### Fase 3 — Features Pro (justifican subscription)
- [ ] Configuración modelo dinámica (medium / large-v3 según tier)
- [ ] Multi-idioma simultáneo (config "ES+EN auto-detect entre los 2")
- [ ] Efecto typewriter (streaming output)
- [ ] Custom vocabulary (jerga sectorial sumada al initial_prompt)
- [ ] Multi-device (sync config entre 2-3 devices del mismo user)
- [ ] Comandos voz para acciones ("nueva línea", "guion bajo", etc.)

### Fase 4 — Empaquetado Tauri (2-3 sem)
- [ ] Reescribir frontend HTML en Svelte (mantenible)
- [ ] Backend Rust con `tauri::command` reemplazando Flask
- [ ] Integrar `whisper.cpp` Rust bindings (sin Python runtime)
- [ ] Captura audio con `cpal` o plugin Tauri mic
- [ ] Inyección texto con `enigo` cross-platform
- [ ] Builds: Linux AppImage + Windows MSI + macOS DMG
- [ ] Code signing macOS ($99/año, post-Day-X)
- [ ] Code signing Windows (opcional primer año)

### Fase 5 — License + monetización (1 sem)
- [ ] License server Cloudflare Workers + D1
- [ ] Generación UUID license keys
- [ ] Activation endpoint (key + machine fingerprint)
- [ ] Cliente Rust: verifica licencia online primera vez, después offline
- [ ] Stripe Checkout integration
- [ ] Webhook Stripe → genera license + email cliente
- [ ] Tier Lite (77€ único) vs Pro (7€/mes con large-v3 + features)

### Fase 6 — Landing + launch (3 días)
- [ ] Web pública `parla.<dominio>` (cuando Marc tenga dominio empresa)
- [ ] Screenshots app + demo video 60s
- [ ] Comparativa vs MacWhisper/Otter/Wisprflow
- [ ] Página descarga + activación
- [ ] ProductHunt + r/SideProject + LinkedIn launch
- [ ] Email outreach a periodistas/abogados (idea-167 sinergia)

## 📊 % avance Parla global

| Bloque | % | Notas |
|---|---|---|
| Engine transcripción (daemon + Whisper) | **95%** | Funciona, falta integrar whisper.cpp para Tauri |
| Captura audio (arecord) | **100%** | OK Linux; pendiente cpal Rust para Tauri |
| Inyección texto (ydotool + clipboard) | **95%** | OK Linux; pendiente enigo para Tauri |
| UI desktop (mockup) | **80%** | Diseño OK; falta loading states, toasts mejores |
| Backend dogfooding (Flask) | **75%** | Funcional; falta endpoint custom vocab, multi-idioma |
| Licensing | **0%** | Pendiente Cloudflare Workers |
| Pago Stripe | **0%** | Pendiente Day-X UJI |
| Empaquetado Tauri | **0%** | Pendiente dogfooding validado |
| Landing + marketing | **0%** | Pendiente nombre dominio post-Day-X |
| Features Pro | **20%** | Diseño hecho; código pendiente |

**Global Parla: ~40% MVP vendible**

**Bloqueante crítico**: Day-X UJI (para registrar dominio empresa, abrir Stripe, dar visibilidad pública).
**Bloqueante intermedio**: 1-2 sem dogfooding diario Marc para validar UX antes de Tauri.

## 🎯 Próximas 24h productivas (sin tu input adicional)

1. ✅ Backend Flask arrancado en :4331
2. ✅ Mockup conectado
3. ⏳ Tu dogfooding: abre :4331, prueba "Guardar config" (cambia modelo small→medium), prueba "Probar grabación 5s"
4. ⏳ Si todo OK → te activo systemd-user para que arranque automático al boot

## 🌐 URLs activas ahora

| URL | Qué es |
|---|---|
| http://localhost:4321 | Web personal Marc (Astro) |
| http://localhost:4322 | Plantilla maestra infantil |
| http://localhost:4323 | Plantilla negocio_basico |
| http://localhost:4325 | Editor self-service papel_a_app (presets duales NUEVO) |
| http://localhost:4328 | Demo cliente peluquería |
| http://localhost:4330 | Mockup Parla puro HTML |
| http://localhost:4331 | **Parla backend Flask + UI conectada ← USA ESTE** |
