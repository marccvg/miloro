---
slug: parla
titulo: Roadmap detallado Parla — desktop app B2C transcripción local
estado: dogfooding
created: 2026-05-18
actualizado: 2026-05-18
target_launch: 2026-07-15 (~2 sem post-Day-X)
pricing_def: Free / Standard €9/mes / Pro €19/mes con device limit + machine fingerprint
domain_def: parla.app + parla.es (~€24/año)
ref_idea: idea-170
---

# Roadmap detallado Parla — desktop app B2C transcripción local

> Este doc es la **fuente única de verdad** para no perder contexto entre sesiones. Cualquier cambio de plan se anota aquí + fecha.

## 0. Resumen ejecutivo

**Producto**: app desktop cross-platform (Linux/Windows/macOS) para transcribir voz a texto LOCALMENTE (sin internet, sin cloud) usando Whisper. Pago recurring con device limit anti-piratería.

**Precio**: Free (1 device, modelo small, 5 transcripciones/día) · Standard €9/mes (2 devices, medium) · Pro €19/mes (3 devices, large + diarización + cloud sync opt-in).

**Target**: profesionales y casuales que necesitan dictado fiable + privacy. Periodistas, abogados, estudiantes, médicos, freelancers.

**Diferencial vs competencia**: 100% local + cross-platform + sin suscripción cloud + machine fingerprint (no se piratea fácil compartiendo cuentas).

## 1. Estado actual real (2026-05-18)

### ✅ Lo que YA funciona (base técnica reutilizable)

| Componente | Path | Estado |
|---|---|---|
| `oido_daemon.py` | `/home/claude/scripts/oido_daemon.py` | ✅ funcional dogfooding Marc (con bug intermitente de memoria leak Whisper a 2.5GB tras horas) |
| `oido_ptt.py` listener | `/home/claude/scripts/oido_ptt.py` | ✅ funcional, **fix mic device hardcoded aplicado 2026-05-18** (ahora respeta GNOME default) |
| `escuchar.sh` bridge | `/home/claude/scripts/escuchar.sh` | ✅ + **fix bug "49000s" notify aplicado 2026-05-18** (cap 600s + cross-check soxi vs size) |
| `audio_a_texto.py` CLI | `/home/claude/scripts/audio_a_texto.py` | ✅ + fix mitigador OGG/Opus drift aplicado |
| `oido_watchdog.sh` | `/home/claude/scripts/oido_watchdog.sh` | ✅ auto-restart si daemon muere (instalado por Marc 2026-05-18 vía systemd-user timer 30s) |
| Versión Windows stage | `/home/claude/staging/windows_setup/` | 🟡 documentación setup, falta GUI |

### 🟡 Diseñado pero NO implementado (5 capas anti-cuelgue B2C)

Ver idea-170 sección "Refinement 2026-05-18b":

1. ✅ Watchdog OS-level (HECHO)
2. ❌ Health endpoint daemon (HTTP local `:5xxx/health` responde OK)
3. ❌ UX 3 escalones (1ª caída silenciosa retry → 2ª notify usuario → 3ª "click reset" botón)
4. ❌ Crash dump capturado a `~/.parla/crashes/` para diagnose
5. ❌ Kernel OOM safety net (cgroup limit RAM 1.5GB max)

### ❌ Lo que falta TODO (back-office + GUI + integración)

Ver §3 y §4 abajo.

## 2. Decisiones críticas pendientes Marc

| # | Decisión | Por qué importa | Mi recomendación |
|---|---|---|---|
| D1 | **Comprar parla.app + parla.es** | Bloqueante absoluto para producción | SÍ ya, ~€24/año Porkbun |
| D2 | Verificar parla.com disponibilidad | Defensivo + brand | Solo si <€50 marketplace |
| D3 | Stack contable cuando Day-X | Recurring SaaS necesita IVA | Holded (idea-175 deferred post-Day-X) |
| D4 | Cuenta Stripe live activar | Cobro real | Post-Day-X (Ley 53/1984 antes NO) |
| D5 | Cuenta Apple Developer Program ($99/año) | Code signing macOS obligatorio | Post-Day-X con ingresos |
| D6 | Certificado code signing Windows ($90-300/año) | Evita "Unknown publisher" warning Win | Post-Day-X con ingresos |
| D7 | Hosting license server | Cloudflare Workers + D1 free tier basta | Cloudflare (D1 ya elegido) |
| D8 | Email transaccional provider | Welcome/payment fail/expired | Resend (free 3k/mes) o Postmark (€10/10k) |
| D9 | Soporte tickets stack | Cuando 10+ clientes | Crisp.chat (free hasta plan paid) o email directo primero |
| D10 | Política de reembolsos pre-publicar | Stripe pide | 14 días pro-rata refund full (estándar EU) |

## 3. Backlog tareas — orden óptimo de implementación

### Bloque A — GUI Cross-platform (4 semanas)

| # | Tarea | Esfuerzo | Bloqueado por |
|---|---|---|---|
| A1 | Setup proyecto Tauri 2 + Svelte | 4h | nada |
| A2 | Integración whisper.cpp (Rust bindings) | 8h | A1 |
| A3 | Captura audio cross-platform (CPAL Rust) | 6h | A1 |
| A4 | UI mínima 1 ventana (settings + estado + probar grabación 5s) | 12h | A1 |
| A5 | Detección hotkey global cross-platform (replace evdev linux-only) | 8h | A3 |
| A6 | Inyección texto sistema (`enigo` Rust cross-platform replace `ydotool`) | 4h | A5 |
| A7 | **RAM detector + recomendación modelo** install wizard (idea-170 refinement 2026-05-18c) | 4h | A4 |
| A8 | Idioma auto-detect + multi-idioma simultáneo Fase 2 | 6h | A2 |
| A9 | Efecto typewriter streaming Pro tier | 4h | A2 |
| A10 | Build pipeline GitHub Actions (Linux + Win + macOS desde 1 codebase) | 8h | A1 |
| A11 | Code signing Linux (no needed) + Win + macOS (notarización Apple) | 4h | A10 + D5 + D6 |

**Total A**: ~68h ≈ 8-10 días full-time

### Auth strategy (decisión 2026-05-17 — ver `/home/claude/notas/auth_2026_analysis_parla_papelaapp.md`)

**Stack auth elegido**: `better-auth` (open source, TS-first) + Cloudflare D1 + Resend magic link. Mismo stack que papel-a-app para consistencia.

**Por qué NO Keycloak**: requiere VPS dedicado JVM 2GB RAM + parches security mensuales + UI Java fea para tu cliente B2C. Rompe el "todo Cloudflare serverless €0". Enterprise SSO, no consumer SaaS.

**Por qué NO Clerk**: lock-in alto (UI components propietarios → migrar = reescribir flows 2-4 sem). Free hasta 50k MAU (sobra Y1-Y2) pero cliff cuando crezcas. Plan B aceptable si Marc quiere shipping express.

**Por qué better-auth**:
- Nativo Cloudflare Workers + D1 (V8 isolates, no Node) — 0 lock-in, código tuyo.
- Magic link built-in vía plugin (1 línea config).
- Google OAuth incluido si quieres (Fase 2 post-launch).
- GDPR EU: D1 EU region → data residency total.
- €0 infra hasta 5000+ users (sobra free tier Cloudflare).

**Schema D1 auth (añadir al schema §5)**: better-auth CLI genera tablas `user`, `session`, `account`, `verification` automáticas. Cruzar con `licenses.email = user.email` (no FK directa, mantenemos separación).

**Esfuerzo**: ~10h dev total auth. Bloque B abajo se simplifica: B3 se reduce a "endpoints license validate {fingerprint} usando session better-auth para auth del dueño", machine fingerprint sigue independiente (sigue siendo B4).

### Bloque B — License server + Stripe (1.5 semanas)

| # | Tarea | Esfuerzo | Status |
|---|---|---|---|
| B1 | Cloudflare account + Workers + D1 setup local (Wrangler dev) | 2h | ✅ **DONE 2026-05-19** (worker bg `ae006fc5856fee1d3`) |
| B2 | Schema D1: `licenses` + `devices` + `events` + `stripe_webhooks_seen` | 4h | ✅ **DONE 2026-05-19** (`backend/migrations/0001_init.sql`) |
| B3 | Endpoints Workers: `/api/license/{activate,verify,deactivate,issue}` + `/dashboard` + `/checkout/session` + `/webhook/stripe` + `/health` | 8h | ✅ **DONE 2026-05-19** (8 endpoints + 17 tests pasando) |
| B4 | Machine fingerprint generator (stub Python — cliente Tauri reemplazará con Rust nativo) | 4h | ✅ **DONE 2026-05-19** (`backend/scripts/fingerprint_stub.py`) |
| B5 | Stripe Subscriptions integration (checkout + webhooks sandbox) | 12h | ✅ **DONE 2026-05-19** (placeholders price_id — Marc swap al activar sandbox) |
| B6 | Stripe webhook → Workers actualiza D1 (active/cancel/past_due/payment_failed) | 8h | ✅ **DONE 2026-05-19** (HMAC SHA256 custom SubtleCrypto + idempotency) |
| B7 | Endpoint dashboard usuario `GET /api/license/dashboard?key=X` | 6h | ✅ **DONE 2026-05-19** |
| B8 | Anti-piratería extras: rate limit IP, fingerprint salt, audit log granular | 4h | 🟡 PARCIAL (rate limit ✅ + audit ✅, watermark email About app pendiente para Bloque A GUI) |

**Total B**: ~48h ≈ 6 días — **45h hechas hoy en ~1h worker bg** (✅ implementado, falta solo deploy + Resend cuenta Marc).

### Bloque C — Capas anti-cuelgue 2-5 (1 semana)

| # | Tarea | Esfuerzo |
|---|---|---|
| C1 | Health endpoint daemon (HTTP local `:5921/health` responde {"status":"ok","model":"medium","uptime_s":N,"transcriptions_total":N}) | 4h |
| C2 | UX 3 escalones recovery (Svelte) — primera caída silenciosa retry, segunda notify desktop, tercera modal "click reset" | 6h |
| C3 | Crash dump capture local `~/.parla/crashes/<ts>.log` con últimas 100 líneas stderr + version + OS | 3h |
| C4 | Kernel OOM safety (Linux cgroup v2 limit 1.5GB · Win Job Object · macOS resource limits) | 6h |
| C5 | Telemetría opt-in (anónimo): qué modelo, RAM detectada, errores frecuentes — POST a license server | 4h |

**Total C**: ~23h ≈ 3 días

### Bloque D — Landing + back-office mínimo (1 semana)

| # | Tarea | Esfuerzo |
|---|---|---|
| D1 | Landing parla.app (Astro + Cloudflare Pages) — hero + features + pricing + FAQ + download buttons | 12h |
| D2 | Política privacidad + términos servicio + GDPR DPA (plantillas adaptadas) | 4h (+ revisión legal opcional €200) |
| D3 | Dashboard usuario (logueado con email + license key) — ver devices, billing, descargar app, cambiar plan | 12h |
| D4 | Dashboard Marc admin (clientes, MRR, churn, alerts) — Streamlit local o Metabase | 8h |
| D5 | Email transaccional: welcome / payment failed / license expired (3 templates Resend) | 4h |
| D6 | FAQ + docs cliente en landing (markdown rendered) | 6h |
| D7 | Botón "contactar soporte" → email Marc directo (sin tickets sistema hasta 20+ clientes) | 1h |

**Total D**: ~47h ≈ 6 días

### Bloque E — Lanzamiento (1 semana)

| # | Tarea | Esfuerzo |
|---|---|---|
| E1 | Beta privada 5-10 usuarios (familia, amigos beta) — 14 días free Pro | feedback rounds |
| E2 | Fix bugs reportados beta | 8-16h variable |
| E3 | Launch público: Reddit r/SideProject, ProductHunt, IndieHackers, HN Show | 4h preparación |
| E4 | RRSS launch (idea-179): Instagram + LinkedIn posts + reels | 8h preparación contenido |
| E5 | Press kit: screenshots, demo video 60s, logo SVG | 6h |

**Total E**: ~30h ≈ 4 días + tiempo respuesta variable

### TOTAL ESFUERZO: ~216h = **~5.5 semanas full-time** o **11-13 semanas a 50% dedication**

## 4. Plan semanal pre-Day-X (revisado 2026-05-18: PRODUCTO PRIMERO, dominio al final)

**Cambio de estrategia (Marc 2026-05-18)**: NO comprar dominio hasta tener MVP funcional y validado. Durante desarrollo y testing usar **subdominios temporales gratuitos** de Cloudflare Pages (`<slug>.pages.dev`) o local-only. Solo comprar parla.app + parla.es cuando esté listo para vender.

**Razón**: evitar gasto + lock-in nombre antes de validar producto. Si rebrand durante desarrollo (probable), dominio comprado = pérdida.

| Semana | Foco | Entregables (sin dominio aún) |
|---|---|---|
| **W1** (19-25 may) | Bloque A1-A4 (Tauri setup + GUI shell) | App Tauri abre ventana, settings UI básica, sin license |
| **W2** (26 may-1 jun) | Bloque A2-A6 (engine + audio + hotkey) | Hotkey global cross-platform funciona, captura audio, llama Whisper local |
| **W3** (2-8 jun) | Bloque A7 (RAM detector) + A10 build pipeline | Builds binarios Linux+Win+macOS desde GitHub Actions |
| **W4** (9-15 jun) | Bloque B1-B5 (license server local + Stripe TEST) | Server corriendo en `localhost:5921` + activación fake + Stripe sandbox |
| **W5** (16-22 jun) | Bloque C1-C3 (capas anti-cuelgue 2-3) + B6-B8 | Health endpoint + UX recovery + crash dump + completar license server |
| **W6** (23-29 jun) | **VALIDACIÓN ALPHA local** | Marc + 2-3 familia testean app **local** sin dominio. Bugs identificados. Decidir GO/NO-GO para fase comercial |

**Day-X target: ~30 jun 2026** (fin UJI).

### Post-Day-X — fase comercial (cuando producto valida)

Solo SI Bloque W6 alpha valida calidad:
- **W7-8**: Bloque C4-C5 + D1-D3 (kernel OOM safety + landing + dashboard usuario) + **AHORA SÍ comprar parla.app + parla.es** + deploy landing a Cloudflare Pages real
- **W9-10**: Bloque D4-D7 (dashboard Marc + emails Resend + RRSS launch) + beta privada 10-20 usuarios
- **W11+**: Bloque E launch público + Stripe live + iteración cliente real

### Durante desarrollo (W1-W6): cómo testear sin dominio

- **Landing**: HTML estático local (file://) o Cloudflare Pages random URL `parla-xyz.pages.dev` (gratis)
- **License server**: `localhost:5921` Workers dev modo + D1 local
- **Stripe**: modo TEST con `sk_test_*` keys (no requiere cuenta live ni dominio verificado)
- **Email**: Resend en modo dev (envía a tu email solo, no a otros)
- **Cliente alpha test**: comparte binario directamente via WeTransfer o Drive, no necesita web

## 5. Preguntas técnicas Marc — respuestas concretas

### ¿Cloudflare gestiona todo el back-end Parla?

**Casi todo, sí**. Stack 100% Cloudflare:
- **DNS**: dominio parla.app+.es → Cloudflare nameservers (gestión gratis)
- **Landing + dashboard usuario**: Cloudflare Pages (free tier 500 builds/mes)
- **License server**: Cloudflare Workers (free tier 100k requests/día) + D1 SQLite (free 5GB)
- **Storage telemetría / crash dumps**: R2 (sin egress, €0.015/GB/mes)
- **Email transaccional**: Resend (NO Cloudflare, free 3k/mes hasta scale up)
- **Pagos**: Stripe (NO Cloudflare, 1.5%+€0.25/transacción EU)

**Total infra/mes año 1**: €0-10 (todo free tier hasta scale). Año 2 con 200+ usuarios: €30-80/mes.

### ¿Cómo mantengo servidor 24/7?

Cloudflare Workers + D1 = **automático sin gestión tuya**. 99.99% SLA garantizado por Cloudflare. Deploys con `wrangler deploy`. No hay servidor que mantener (serverless).

Si en futuro necesitas Postgres para data más rica (data-coach clients): Hetzner VPS €5-10/mes con PostgreSQL gestionado. Pero NO necesario para Parla core.

### ¿BBDD esquemas?

**D1 (SQLite) schema mínimo Parla**:

```sql
CREATE TABLE licenses (
    key TEXT PRIMARY KEY,           -- UUID v4
    email TEXT NOT NULL,
    plan TEXT NOT NULL,              -- 'free' | 'standard' | 'pro'
    devices_max INTEGER NOT NULL,    -- 1 / 2 / 3
    status TEXT NOT NULL,            -- 'active' | 'past_due' | 'cancelled'
    stripe_customer_id TEXT,
    stripe_subscription_id TEXT,
    created_at INTEGER NOT NULL,
    expires_at INTEGER,              -- NULL = activa indefinido
    last_payment_at INTEGER,
    cancelled_at INTEGER
);
CREATE TABLE devices (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    license_key TEXT REFERENCES licenses(key) ON DELETE CASCADE,
    fingerprint TEXT NOT NULL,
    hostname TEXT,
    os TEXT,                         -- 'linux' | 'win' | 'macos'
    activated_at INTEGER NOT NULL,
    last_seen INTEGER NOT NULL,
    deactivated_at INTEGER
);
CREATE TABLE events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    license_key TEXT,
    type TEXT NOT NULL,              -- 'activate' | 'deactivate' | 'verify' | 'crash' | 'payment_*'
    ts INTEGER NOT NULL,
    payload_json TEXT
);
CREATE INDEX idx_devices_license ON devices(license_key);
CREATE INDEX idx_events_ts ON events(ts);
```

### GDPR

- **DPA con Cloudflare**: Cloudflare incluye standard contractual clauses (SCC) en su DPA público — Marc firma electrónicamente al crear cuenta
- **EU data residency**: Cloudflare Workers ejecutan globalmente; D1 europeo si seleccionas región EU al crear DB
- **Datos cliente**: email + machine fingerprint + crash dumps anónimos. NO datos de transcripción (todo local en cliente).
- **Política privacidad**: documento legal estándar adaptado (template €0) en parla.app/privacy
- **Cookies banner**: si landing usa Plausible analytics (no cookies tracking), NO necesita banner; si usa GA, sí
- **Derecho borrado GDPR**: endpoint `POST /license/delete {key, email}` → borra todo en 30 días

### Pagos

- **Stripe** (KYC tu identidad + cuenta bancaria autónomo):
  - Account Spain Standard (no Connect — no haces multi-vendor)
  - Stripe Tax para IVA EU automático (~0.4% fee extra)
  - Webhooks signed con secret → Workers verifica HMAC
  - Reembolsos: pro-rata 14 días first month (estándar EU)
- **Facturas a clientes**: Stripe genera automático + email PDF. Cumple normativa AEAT España.

## 6. Lo que necesito de Marc (físico/decisión)

Ordenado por urgencia y desbloqueo:

| Prioridad | Acción | Tiempo Marc | Desbloquea |
|---|---|---:|---|
| 🔴 W1 | Comprar parla.app + parla.es Porkbun | 10 min + tarjeta | DNS + landing |
| 🔴 W1 | Crear cuenta Cloudflare (gratis) + apuntar nameservers | 15 min | Pages + Workers + D1 |
| 🟡 W3 | Crear cuenta Resend (gratis) → API key | 5 min | Emails transaccionales |
| 🟡 W4 | Crear cuenta Stripe (modo test primero, live post-Day-X) | 30 min KYC | Cobros |
| 🟡 W5 | Verificar plantillas privacy + DPA + ToS antes publicar | 30 min lectura | Compliance GDPR |
| 🟢 Post-Day-X | Apple Developer Program ($99/año) | 30 min + pago | Code signing macOS |
| 🟢 Post-Day-X | Cert code signing Windows (Sectigo/DigiCert $90-300) | 60 min + pago | Sin warning "Unknown publisher" |
| 🟢 Post-Day-X | Alta autónomo Hacienda + IAE 731 (consultoría informática) | 1-2h gestoría | Facturar legal |

## 7. Riesgos críticos + mitigación

| Riesgo | Probabilidad | Mitigación |
|---|---|---|
| Apple notarización rechaza app (problema cert/permisos) | Media | Empezar Linux+Win, macOS Fase 2 |
| Whisper.cpp Rust bindings inestables CPU-only sin GPU | Media | Fallback a Python faster-whisper si problemas |
| Stripe cierra cuenta por alta tasa disputes | Baja | Refund pro-rata 14d generoso evita disputes |
| Cliente lo piratea masivamente compartiendo keys | Media | Device limit + fingerprint mitigan 90% |
| Memory leak Whisper en producción cliente | Alta | 5 capas anti-cuelgue (ver §1) imprescindibles |
| Competencia bajadas precio MacWhisper / Otter | Media | Diferencial "100% local + cross-platform + €9 entry" = barrera psicológica baja |

## 8. Notas evolutivas

- 2026-05-18: Roadmap creado tras sesión planning detallado Marc. Pricing simplificado Free/€9/€19 (NO tokens). Domain decidido parla.app+.es. 5 capas anti-cuelgue documentadas tras incidente daemon mudo hoy. Fix mic + watchdog HECHO.
- 2026-05-18b: pendiente capa 2-5 anti-cuelgue + GUI Tauri completa + license server + Stripe + landing + back-office mínimo + lanzamiento. Esfuerzo total 216h = 5.5 sem full-time.

## 9. Cross-link

- **idea-170** — idea madre Parla
- **idea-175** — Claude for Small Business (gestión facturas post-Day-X cuando hay clientes Parla)
- **idea-179** — RRSS lanzamiento
- **idea-180/181** — workflow inbox+chat per-proyecto (mejora gestión Marc, no producto)
- **specialists/parla/runbook.md** — operación día a día
- **specialists/parla/inventory.md** — dependencias técnicas

## 10. Arquitectura integrada — cómo se conecta TODO

Diagrama servidor → BBDD → facturas → auth → app cliente:

```
                                 ┌─────────────────────────────────┐
                                 │   Cliente final (Linux/Win/mac) │
                                 │   Parla.app (Tauri + whisper)   │
                                 └────────────────┬────────────────┘
                                                  │ HTTPS
                                                  │ + license key local + machine fingerprint
                                                  ▼
                       ┌──────────────────────────────────────────────────┐
                       │  CLOUDFLARE EDGE (gestión 24/7 automática)       │
                       │                                                  │
                       │  ┌──────────────┐  ┌──────────────────────────┐  │
                       │  │ Workers API  │←→│ D1 SQLite (licenses,    │  │
                       │  │ /activate    │  │  devices, events)        │  │
                       │  │ /verify      │  └──────────────────────────┘  │
                       │  │ /deactivate  │                                 │
                       │  └──────┬───────┘  ┌──────────────────────────┐  │
                       │         │ ←─────── │ R2 (crash dumps, opt-in │  │
                       │         │           │  telemetry)              │  │
                       │         │           └──────────────────────────┘  │
                       │         ▼                                         │
                       │  ┌──────────────────────────┐                    │
                       │  │ Pages: landing parla.app │                    │
                       │  │  + dashboard usuario     │                    │
                       │  └──────────────────────────┘                    │
                       └──────────────┬───────────────────────────────────┘
                                      │
                  ┌───────────────────┴───────────────────┐
                  │                                       │
                  ▼                                       ▼
        ┌──────────────────────┐               ┌──────────────────────┐
        │  STRIPE (pagos)      │               │  AUTH PROVIDER       │
        │  - Subscriptions     │               │  (ver Auth strategy) │
        │  - Webhooks → Worker │               │  - Magic link        │
        │  - Customer Portal   │               │  - Optional Google   │
        │  - Stripe Tax IVA EU │               │  - 2FA opcional Pro  │
        │  - Facturas auto AEAT│               └──────────────────────┘
        └──────────┬───────────┘
                   │
                   ▼
        ┌──────────────────────┐
        │  RESEND (emails)     │
        │  - Welcome           │
        │  - Magic link        │
        │  - Payment failed    │
        │  - License expired   │
        └──────────────────────┘
```

### Decisiones de arquitectura fundadoras

| # | Decisión | Por qué |
|---|---|---|
| 1 | **100% Cloudflare** stack backend | Serverless 24/7 sin gestión + free tier amplio + DDoS protection + EU regions |
| 2 | **D1 SQLite** vs Postgres | Menos features pero suficiente Parla (licenses + devices + events). Free 5GB. Cuando >5GB → Hyperdrive a Postgres Hetzner |
| 3 | **Stripe Subscriptions** vs ChargeBee/Lemon Squeezy | Mejor docs + market leader + Stripe Tax automatiza IVA EU |
| 4 | **Resend** vs Postmark/SendGrid | Free tier mayor (3k/mes vs 0/100), DX moderno |
| 5 | **Auth: ver §11 Auth strategy** (worker dedicado analizando) | Decisión clave pendiente |
| 6 | **Telemetría opt-in** R2 storage (anonymous) | Privacy-first + helpful diagnostic |

### Costes infraestructura forecast

| Mes | Usuarios paying | Cloudflare | Stripe (1.5%+0.25/tx) | Resend | TOTAL/mes |
|---|---|---|---|---|---|
| Mes 1 (post-launch) | 5 | €0 free | ~€2 | €0 free | **~€2** |
| Mes 6 | 50 | €0 free | ~€20 | €0 free | **~€20** |
| Mes 12 | 150 | €5 paid | ~€60 | €15 paid 5k+ | **~€80** |
| Mes 24 | 300 | €10 paid | ~€120 | €25 paid 10k+ | **~€155** |

Coste total año 2: ~€1.500/año vs revenue forecast ~€25k/año = **94% margen bruto SaaS**. Perfecto.

## 11. Auth strategy (DECIDIDO 2026-05-18 → en implementación 2026-05-19)

### Stack final elegido (mismo que papel-a-app — coherencia + reuse)

**`better-auth` + Cloudflare D1 + Workers + Resend (magic link)**

Análisis completo: `/home/claude/notas/auth_2026_analysis_parla_papelaapp.md` (314 líneas).

### Aplicación específica Parla

- License server B usa el mismo backend Workers que el auth. Tablas `licenses + devices + events` separadas de `users + session + verification`.
- Cliente desktop Tauri verifica licencia con `POST /api/license/verify {key, fingerprint}` — NO necesita login user (la licencia ES el auth).
- Dashboard usuario (parla.app/dashboard) sí usa magic link para que el dueño vea sus devices.

### Por qué NO Keycloak

VPS JVM dedicado innecesario para 1 endpoint cliente desktop. Sobre-engineering masivo.

### Estado implementación 2026-05-19

- ✅ Stack decidido + documentado
- ⏳ Worker bg `ae006fc5856fee1d3` implementando license server MVP local (D1 + endpoints activate/verify/deactivate + Stripe webhooks sandbox + fingerprint stub)
- ❌ Cuenta Resend pendiente (Marc 5 min)
- ❌ Cuenta Stripe LIVE pendiente (post-Day-X, KYC)

## 12. Auditoría seguridad pre-lanzamiento

Antes de Day-X+ lanzamiento público, ejecutar auditoría obligatoria:

### Self-audit (Marc + agente, 1-2 días)

1. **OWASP Top 10 check**:
   - Injection: SQL injection en D1 queries (usar prepared statements siempre)
   - Broken auth: session tokens HTTPS only + HttpOnly cookies + CSRF
   - Sensitive data: ¿qué se guarda en D1? ¿encryption-at-rest? (Cloudflare D1 cifra default)
   - XML/XXE: no aplica (REST API JSON only)
   - Broken access control: cada endpoint verifica ownership before mutation
   - Security misconfig: secrets en Cloudflare Workers secrets store (no env vars públicos)
   - XSS: en frontend cualquier input → escapeHtml siempre
   - Insecure deserialization: solo JSON parse safe (no pickle/yaml unsafe)
   - Components vulns: `npm audit` + `cargo audit` mensual
   - Logging: log accesos sospechosos sin loggear datos sensibles

2. **Stripe webhook signature verification** obligatoria (HMAC SHA256)

3. **License key generation**: UUID v4 (no secuencial), almacenar hash en D1 (no plain)

4. **Machine fingerprint**: salt server-side (no client-only) para evitar replay

5. **Rate limiting**: por IP + por user en endpoints sensibles (activate, login)

6. **Backups D1**: snapshot diario a R2 (Cloudflare ofrece auto-backup D1)

7. **DPA + Política privacidad**: legal review (template + revisión 30 min freelance €100-200)

### Audit externa (opcional, post-MVP cuando MRR >€500/mes)

- Tool automatizada gratis: **Detectify Free trial** o **OWASP ZAP** auto scan
- Bug bounty informal HackerOne free tier (limited)
- Pentest profesional: **€2k-€5k** (defer hasta producto consolidado)

### Compliance específica EU

- **GDPR**: cookies banner si tracking analytics; data export endpoint; data delete endpoint; DPA con sub-procesadores (Cloudflare, Stripe, Resend)
- **AI Act (si aplica)**: Whisper local NO entra en categorías AI Act high-risk. Disclaimer "uses AI" en T&C.
- **Reglamento PSD2** pagos: Stripe ya cumple SCA (3DS) automático
- **Estatuto consumidor EU**: 14 días refund garantizado (Stripe Customer Portal lo automatiza)

### Auditoría costes/responsabilidades

- Costes legal review pre-launch: **€100-200** (autónomo abogado tech)
- Coste anual Stripe Tax (auto IVA): incluido fees ~0.4%
- Coste anual DPO designado (Data Protection Officer): NO obligatorio Parla < 250 empleados, pero opcional autónomo Spain ~€100/año

## 13. QA / Testing por funcionalidad (review detallado pre-launch)

### 13.1 Capas de testing (pirámide)

| Capa | Qué cubre | Herramienta | Esfuerzo |
|---|---|---|---|
| **Unit (Rust)** | módulos `whisper_wrapper`, `audio_capture`, `fingerprint`, `hotkey`, `text_inject`, `license_client` | `cargo test` + tarpaulin coverage | 12h crear suite |
| **Unit (TS Workers)** | endpoints `/activate`, `/verify`, `/deactivate`, `/webhook/stripe`, `/dashboard` | `vitest` + `@cloudflare/vitest-pool-workers` | 8h |
| **Integration (Rust)** | flow completo PTT → captura → whisper → inyección texto en window real | `cargo test --features integration` + Xvfb | 10h |
| **E2E desktop** | Tauri app lanzada real + simulación hotkey + assert texto inyectado en gedit | `tauri-driver` + `webdriverio` (oficial Tauri) | 16h crear suite + 4h CI |
| **E2E license server** | flow: signup Stripe sandbox → webhook → activate → verify → deactivate (con D1 isolated) | wrangler local + scripts bash | 6h |
| **Load test** | 1000 verify/seg en license server (D1 readonly cache) | `k6` script | 4h |
| **Manual QA checklist** | 30 escenarios (ver §13.4) ejecutados Marc + 2 alpha testers | doc markdown checklist | 8h ejecutar |

**Total testing infra**: ~68h ≈ 1.5 sem dedicadas pre-launch.

### 13.2 Tests por funcionalidad (golden paths + edge cases)

#### F1 — Activación licencia
- ✅ Activar key válida → 200 + device registrado.
- ⚠️ Activar key expirada → 403 + msg human.
- ⚠️ Activar key sin slots libres → 403 + lista devices con opción `/deactivate`.
- ⚠️ Activar key con fingerprint inválido (no hex 64ch) → 400.
- ⚠️ Activar 2× misma key + fingerprint (idempotencia) → 200 + 1 device DB (no duplicado).
- ⚠️ Race condition: 3 requests simultáneas activate con last slot → solo 1 wins (D1 transaction).

#### F2 — Verify periódico (cada 7 días)
- ✅ Verify con cache hit → <50ms response.
- ⚠️ Verify con sub cancelada en Stripe pero D1 aún active → debe retornar 403 "subscription cancelled" (sync webhook eventual).
- ⚠️ Verify offline (sin internet) → app debe tener grace period 7 días cache local antes de bloquear.
- ⚠️ Replay attack: capturar request verify, mandarla con otro fingerprint → 403 server-side check.

#### F3 — Transcripción local (núcleo producto)
- ✅ Audio 5s ES → texto correcto >90% similarity vs ground truth.
- ✅ Audio 30s ES con ruido fondo (café) → texto coherente >70%.
- ⚠️ Audio 0.5s (silencio) → handle no-crash + msg "muy corto".
- ⚠️ Audio 10min (largo) → cap a 5min + warn user.
- ⚠️ Audio multi-idioma (ES+EN mid-sentence) → idioma detectado correcto (Pro tier).
- ⚠️ Whisper OOM con modelo large + RAM <8GB → fallback automático medium.
- ⚠️ Daemon crash mid-transcripción → watchdog restart + notify "audio perdido, retry".
- ⚠️ Mic device cambia en GNOME settings mientras app abierta → re-capture sin restart (regression test bug 2026-05-18).
- ⚠️ Notify "49000s" (regression test bug 2026-05-18) → siempre <600s.

#### F4 — Inyección texto sistema
- ✅ Inyectar en gedit/VSCode/browser → texto aparece tal cual.
- ⚠️ Inyectar con caracteres unicode raros (emoji, japonés) → no rompe `enigo`.
- ⚠️ Inyectar mientras app fullscreen game → fallback copy to clipboard + notify.
- ⚠️ Inyectar en password field → debería skip (privacy, no log).
- ⚠️ Hotkey conflict con app existente (ej. Ctrl+Shift+P de VSCode) → UI permite remap.

#### F5 — Stripe webhook idempotencia
- ✅ Webhook `customer.subscription.updated` 2× misma idempotency key → 1 sola UPDATE D1.
- ⚠️ Webhook `payment_failed` → status `past_due` + email cliente.
- ⚠️ Webhook signature inválida (replay attack) → 400 reject + log.
- ⚠️ Webhook event no manejado → 200 ack (no retry) + log warn.

#### F6 — Dashboard usuario
- ✅ Ver mis devices, kick remoto un device → device removido + app cliente pierde acceso en próximo verify.
- ⚠️ XSS test: nombre device contiene `<script>alert(1)</script>` → render escapado.
- ⚠️ CSRF test: POST /deactivate desde otro origin → bloqueado por SameSite cookie.

### 13.3 Bugs potenciales detectados a vigilar (preventivo)

| ID | Descripción | Severidad | Mitigación |
|---|---|---|---|
| B1 | Memory leak Whisper (ya visto 2.5GB tras 24h) | Alta | Watchdog OS-level + cgroup limit 1.5GB |
| B2 | Soxi devuelve duración inflada con WAV malformado (visto 2026-05-18) | Media | Cap 600s + cross-check size/32000 (HECHO) |
| B3 | Mic device hardcoded ignorando GNOME default (visto 2026-05-18) | Alta | Removed override (HECHO) — regression test |
| B4 | Hotkey collision OS-level con multi-app | Media | UI remap + detect conflict on first launch |
| B5 | License server DDoS con activate floods | Media | Cloudflare rate limit + Workers KV throttle |
| B6 | Stripe webhook race con verify (cancela en Stripe, verify aún OK x 30s) | Baja | Cache TTL bajo + eventual consistency aceptable |
| B7 | Cross-platform paths con caracteres especiales (Windows backslash) | Media | `std::path::PathBuf` always, never string concat |
| B8 | Crash dump escribe a disco lleno → loop crash | Baja | Skip write if free space <100MB + log stderr |
| B9 | Update Tauri rompe Whisper bindings (ABI incompat) | Media | Pin versions exactas + CI matrix test |
| B10 | Notarización Apple expira (cert anual) → app rota silenciosa Mac | Alta | Calendar alert 30d antes + auto-renew flow |

### 13.4 Manual QA checklist pre-launch (30 escenarios)

Lista checkbox markdown ejecutar 2 días antes go-live, Marc + 1-2 alpha testers:

1. Install fresh Linux Ubuntu 22 → app arranca → primer launch wizard funciona.
2. Install fresh Windows 11 → no Defender warning → arranca.
3. Install fresh macOS Ventura → notarización OK → arranca sin Gatekeeper alert.
4. Login con email + magic link → recibo email <30s → click → logueado.
5. Buy Standard plan Stripe test card → recibo email license key <1min.
6. Activate license → ver device en dashboard.
7. Transcripción primer test "Hola, esto es Parla" → texto correcto.
8. Kick device desde dashboard → app cliente bloquea próximo verify.
9. Cancelar sub Stripe Customer Portal → app sigue 7d grace → bloquea.
10-30. (Ver `/home/Projects/parla/QA_CHECKLIST.md` cuando se cree)

## 14. Reglas y normas generales (input limits + validations)

### 14.1 Límites duros (hard limits aplicados en código)

| Recurso | Límite | Razón | Validación |
|---|---|---|---|
| Audio capture chunk | 5 min (300s) | Whisper degrada calidad >5min + memory | `audio_capture.rs` cap + UI warn |
| Filename salida `.txt` | 255 chars + UTF-8 | FS Windows compat | sanitize regex `[^\w\-]` |
| Modelo Whisper local | small/medium/large | RAM <8GB / 8-16GB / >16GB | install wizard detect |
| Hotkey simultáneas | máx 3 (PTT, copy, lang-switch) | UX overload | settings UI cap |
| Devices por plan | 1/2/3 | Anti-piratería + valor pricing | server-side check |
| Email length signup | 320 chars (RFC) | Compat | regex validate |
| License key format | UUID v4 exacto | Anti-typo | regex `^[0-9a-f-]{36}$` |
| Crash dump size | máx 10MB | Anti disk-fill | truncate stderr |
| Transcripciones/día tier Free | 5 | Free tier abuse prevention | D1 counter daily reset |

### 14.2 Sanitización inputs

- **Inyección texto sistema** (`enigo`): NO sanitizar texto Whisper (es la salida del usuario, mantener fidelidad). Pero sí prevenir inyección de tecla escape sequences si Whisper alucina `[ESC]` (whitelist printable chars only).
- **Nombre device** en dashboard: escapeHtml strict (XSS).
- **Email signup**: trim + lowercase + RFC validate antes Magic Link.

### 14.3 Reglas comportamiento app

- **Telemetría OPT-IN obligatorio** (privacy first) — toggle en settings, default OFF.
- **Crash dumps OPT-IN** — primer launch wizard pregunta.
- **Update auto OPT-OUT permitido** — settings checkbox.
- **Notificaciones desktop**: respect OS "do not disturb" mode.
- **Audio capture indicator**: SIEMPRE LED visible mientras graba (privacy expectation).

## 15. Seguridad runtime — anti-bot, anti-abuse, hardening

### 15.1 Cloudflare protections (gratis, on by default)

- **DDoS L3/L4**: incluido free plan, mitiga floods volumétricos.
- **WAF managed rules**: free tier limited; paid €5/mes incluye OWASP ruleset.
- **Bot Fight Mode** free → bloquea bots conocidos User-Agent.
- **Cloudflare Turnstile** free unlimited → captcha invisible en signup/login (zero friction usuario real).

### 15.2 Anti-abuse específico Parla

- **License key brute force**: rate limit 5 intentos/IP/hora `/activate` → KV counter.
- **Stripe webhook signature**: HMAC SHA256 verify obligatorio antes mutate D1.
- **Magic link**: TTL 15min strict + 1 uso único + IP match (warn si IP cambia entre request y click).
- **Fingerprint replay**: salt server-side per device + hash chain (cada verify rota salt).
- **Watermark email comprador** en About → impide compartir license fácil (screenshot delata).
- **Crash dump scrubbing**: remover paths absolutos `/home/<user>/`, env vars, audio bytes raw — solo stacktrace + Rust panic msg.

### 15.3 OS-level hardening

- **Cgroup limit RAM 1.5GB** daemon → kernel OOM mata antes que freeze sistema.
- **Capabilities Linux**: drop `CAP_NET_ADMIN` etc. (no necesarios).
- **macOS sandbox**: aplicar entitlements mínimos (mic + accessibility + network).
- **Windows AppContainer**: si feasible (no break enigo).

### 15.4 Secrets management

- **Workers secrets**: Stripe webhook secret, Resend API key, Cloudflare account token → `wrangler secret put` (NO env vars públicos).
- **Cliente**: license key local en OS keyring (Linux Secret Service / Win Credential Manager / macOS Keychain), NO plain file.

### 15.5 Audit log (D1 `events` table)

Log de eventos sensibles para forense:
- `activate` / `deactivate` / `verify_failed` / `payment_failed` / `webhook_received` / `admin_action`
- Retención 90 días (GDPR) + scrubbing PII (solo license_id, no email).

## 16. Patrones rescatados de fuck-loomis (reutilizables Parla)

Análisis completo: `/home/claude/notas/fuck_loomis_patterns_para_parla_papelaapp.md` (488 líneas).

Parla es **desktop single-tenant** → uso reducido vs papel-a-app. Pero hay piezas útiles:

| Patrón | Path fuck-loomis | Aplicación Parla | Esfuerzo |
|---|---|---|---|
| **E2E runner orquestador** (bash + Xvfb + healthchecks + fixtures) | `tests_e2e/run_e2e.sh` + `tests_e2e/lib/*.sh` | Adaptar a Tauri-driver + Whisper fixtures audio | 6h |
| **kill_tree / wait_health** funciones bash | `tests_e2e/lib/process.sh` + `health.sh` | E2E desktop kill daemon + restart | 1h |
| **Structured JSON logging** | `docs/verifactu/adr/010-rgpd-data-policy.md` | Pino-equivalent Rust `tracing` con JSON layer | 2h |
| **GDPR scrubbing policy** | mismo ADR | Aplicar regla "no log paths absolutos, no audio bytes" | 1h |

**Total rescate Parla**: ~10h. Bajo ROI vs papel-a-app pero E2E runner sí ahorra reinventar.

## 17. Tamaño final roadmap

- Roadmap inicial (2026-05-18 mañana): ~280 líneas
- + §10-12 Arquitectura/Auth/Audit (2026-05-18 tarde): +160 líneas
- + §13-16 QA/Reglas/Seguridad/fuck-loomis (2026-05-18 noche): +~250 líneas
- **Total final: ~690 líneas** = documento maduro fuente única verdad

Esfuerzo total trabajo Parla revisado:
- Bloque A (GUI): 68h
- Bloque B (License + Stripe + auth better-auth): 48h (-10h vs original con better-auth)
- Bloque C (capas anti-cuelgue): 24h
- Bloque D-G (landing, dashboard, marketing, lanzamiento): 76h
- §13 QA testing infra: 68h
- §16 rescate fuck-loomis: 10h
- **TOTAL: ~294h ≈ 7-8 semanas full-time** (era 216h inicial — testing + QA suben significativamente)

