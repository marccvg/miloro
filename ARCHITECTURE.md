# MiLoro — Arquitectura

> **Última actualización**: 2026-05-26 (post-deploy MVP Free)
> **Estado**: Free signup público live en producción. Pro €9 Stripe TEST listo. Compliance €49 parked.

Documento vivo. Cuando el código cambia, actualizar **aquí mismo** en la misma intervención. Linkear decisiones específicas a `/home/claude/memoria/decisiones.md` por fecha.

---

## 0. Stack en 1 vista

```
┌─────────────────────────────────────────────────────────────────┐
│                          USUARIO FINAL                           │
└─────────┬───────────────────────────────────────────┬────────────┘
          │                                            │
          ▼                                            ▼
  ┌──────────────┐                          ┌─────────────────┐
  │ Landing      │                          │ MiLoro Desktop  │
  │ miloro.app/  │                          │ App (Tauri 2)   │
  │ (HTML est.)  │                          │ Linux+Win+macOS │
  └──────┬───────┘                          └────────┬────────┘
         │ POST signup                                │ POST verify/activate/usage
         │                                            │
         ▼                                            ▼
  ┌────────────────────────────────────────────────────────────┐
  │       Cloudflare Worker  miloro-license-server             │
  │       Route: miloro.app/api/*                              │
  │       Source: /home/Projects/parla/backend/src/index.ts    │
  └──────┬─────────────────────────────────────────┬───────────┘
         │                                          │
         ▼                                          ▼
  ┌──────────────┐                          ┌─────────────────┐
  │ D1 SQLite    │                          │ Resend API      │
  │ parla_licenses│                          │ (welcome+notif)│
  │ id 2b23b2ba.. │                          │ from sandbox    │
  └──────────────┘                          └─────────────────┘
         │
         ▼
  ┌──────────────┐
  │ Stripe API   │ (TEST mode hasta Day-X UJI)
  │ subscriptions│
  └──────────────┘
```

**Principio rector**: Marc es **vendedor de software**, NO data processor cloud. La transcripción siempre ocurre **localmente** en el cliente — el Worker SOLO gestiona licencias, pagos y email. Audio nunca sale del equipo del usuario. (Decisión 2026-05-25 en `memoria/decisiones.md`.)

---

## 1. Componentes y paths

| Componente | Ubicación | Tech | Estado |
|---|---|---|---|
| **Backend Worker** | `/home/Projects/parla/backend/` | Cloudflare Worker + D1 + Workers KV (futuro) | Live `miloro.app/api/*` |
| **Landing** | `/home/Projects/parla/landing/` | HTML estático + Pages Functions | Live `miloro.app/` |
| **Desktop App** | `/home/Projects/parla/desktop/` | Tauri 2 + Svelte + Rust + whisper.cpp | Alpha Linux only |
| **Brand assets** | `/home/Projects/parla/brand/` | Iconos PNG/ICO loro Noto Color Emoji | Estable post-rebrand 2026-05-24 |
| **Legal templates** | `/home/Projects/parla/legal/` | Markdown DPA + privacy + terms | Borrador |
| **Specialist docs** | `/home/claude/specialists/miloro/` | runbook, inventory, env-map, roadmap | Sincronizado 2026-05-26 |

> **Nota histórica**: el directorio root sigue llamándose `parla/` aunque el producto se rebrandeó a MiLoro el 2026-05-24. Renombrar el directorio es disruptivo (rompe imports relativos, paths absolutos en scripts, git history). Decisión: dejar nombre interno, solo el producto user-facing es MiLoro.

---

## 2. Modelo de licencias

### Planes vivos hoy (decisión 2026-05-24 + 2026-05-25)

| Plan | Precio | Devices | Audio/día | Modelos Whisper | Status |
|---|---|---|---|---|---|
| **Free** | €0 | 1 | 30 min | hasta small | ✅ Live |
| **Pro** | €9/mes (o €72/año) | 3 | ilimitado | hasta large-v3 | ✅ Cableado, Stripe TEST. Live cuando Day-X UJI |
| ~~Standard~~ | (legacy) | 3 | ilimitado | medium | DB-only, NO en Checkout |
| **Compliance** | €49/mes | 5 | ilimitado | + plantillas sectoriales + DPA pack | 🟡 PARKED — pendiente arquitectura BYOK (idea-207 v2) |

Definidos en `backend/src/types.ts`:
- `PLAN_DEVICE_LIMITS` — devices max por plan
- `PLAN_QUOTA_SECONDS_DAILY` — segundos/día (-1 = unlimited)
- `quotaCheck(plan, secondsUsedToday)` — helper puro

### Tier Compliance €49 (parked)

3 caminos abiertos a decidir cuando Free+€9 esté validado con primeros clientes:
- **A. Local puro** — LLM 2-4B local + plantillas + vault. Sin LLM cloud. Lento Q&A pero cero exposición legal.
- **B. BYOK (Bring Your Own Key)** ← **voto preferido** — cliente pone su key Anthropic/OpenAI; MiLoro tokeniza columnas client-side; POST directo cliente→provider; Marc nunca toca datos.
- **C. Drop** — solo Free+€9, "Compliance Pack" PDF €99 one-shot.

Ver `memoria/decisiones.md` entrada 2026-05-25 para motivación legal (rechazo data processor role).

---

## 3. Backend Worker — `miloro-license-server`

### Bindings (production)

```toml
# wrangler.toml resumen
name = "miloro-license-server"
routes = [{ pattern = "miloro.app/api/*", zone_name = "miloro.app" }]

[[d1_databases]]
binding = "DB"
database_name = "parla_licenses"
database_id = "2b23b2ba-28e6-4288-9bc2-123cdc5f1d8a"

# Env vars públicas (no secretas)
ENVIRONMENT = "production"
APP_ORIGIN = "https://miloro.app"
VERIFY_CACHE_TTL_S = "60"
ACTIVATE_RATE_LIMIT_PER_HOUR = "5"
STRIPE_PRICE_STANDARD = "price_test_..." # legacy slot
STRIPE_PRICE_PRO = "price_test_..."

# Secrets (wrangler secret put)
STRIPE_SECRET_KEY      # sk_test_... → sk_live_... cuando Day-X
STRIPE_WEBHOOK_SECRET  # whsec_...
RESEND_API_KEY         # re_... (Resend Full access)
EMAIL_FROM             # 'MiLoro <onboarding@resend.dev>' provisional, → @miloro.app cuando DNS Resend verificado
ADMIN_TOKEN            # opcional, bearer para /api/license/issue
```

### Endpoints catálogo

| Método | Path | Auth | Función | Rate limit |
|---|---|---|---|---|
| GET | `/api/health` | none | Service liveness check | — |
| POST | `/api/license/signup` | none (público) | Crea licencia Free idempotente + welcome email | **3/h por IP** |
| POST | `/api/license/issue` | Bearer ADMIN_TOKEN | Admin: crear licencia de cualquier plan | — |
| POST | `/api/license/activate` | none | Activa device con fingerprint en licencia | **5/h por IP** |
| POST | `/api/license/verify` | none | App verifica licencia activa + cuota | cache 60s |
| POST | `/api/license/deactivate` | none | Libera slot device | — |
| GET | `/api/license/dashboard?key=X` | key-as-auth | Info pública licencia + devices + cuota | — |
| POST | `/api/usage/report` | none | App reporta segundos audio tras transcripción | 429 si Free quota exceeded |
| POST | `/api/checkout/session` | none | Crea Stripe Checkout para Pro | — |
| POST | `/api/billing/portal` | none | Portal Stripe gestión suscripción | — |
| POST | `/api/webhook/stripe` | HMAC firma | Webhook Stripe (HMAC SHA-256 verificado) | idempotente vía `stripe_webhooks_seen` |
| GET | `/api/updater/{target}-{arch}/{ver}` | none (pubkey embedded en cliente) | Manifest Tauri updater. 204=al día / 200=update disponible | cache 300s |

### Helpers / módulos backend

```
backend/src/
├── index.ts        — Module Worker entry, routing
├── types.ts        — Env, plans, quotaCheck helper
├── util.ts         — nowS, uuid, json/badRequest/tooMany, clientIp, nextUtcMidnight
├── licenses.ts     — CRUD licencias + devices + usage (D1)
├── audit.ts        — logEvent → tabla events
├── email.ts        — sendEmail (Resend → fallback MailChannels) + welcomeEmail template
├── stripe.ts       — verifyStripeSignature (HMAC custom SubtleCrypto), priceIdToPlan
├── ratelimit.ts    — checkActivateRateLimit + checkSignupRateLimit (events-based)
├── updater.ts      — getManifest (KV) + resolveUpdate + compareSemver + SUPPORTED_PLATFORMS
└── schema.ts       — types compartidos
```

### Patrones aplicados

- **Idempotencia**:
  - `signup`: si email ya tiene Free activa → reusa key (no duplica).
  - `activate`: mismo fingerprint dos veces → devuelve mismo `device_id`.
  - `webhook stripe`: `stripe_webhooks_seen.event_id` PRIMARY KEY → replays no duplican.
- **Anti-enumeration**:
  - Signup público NO devuelve la `key` en response. Solo sale por email.
- **Rate-limiting events-based**: cuenta filas en `events` table por (IP, type, ts >= now-3600). No KV/DO necesario en MVP.
- **Cache verify**: `cache-control: private, max-age=60` reduce DB load app cliente.
- **Audit log granular**: cada acción crítica → fila en `events` con `payload_json`. Permite forensics post-hoc.

---

## 4. Schema D1 `parla_licenses`

Migrations en `backend/migrations/`:

### 0001_init.sql — tablas core

```sql
licenses              -- key (UUID), email, plan, devices_max, status, stripe_*, timestamps
devices               -- id, license_key FK, fingerprint, hostname, os, activated_at, last_seen
events                -- id, license_key, type, payload_json, ip, ts  -- audit log
stripe_webhooks_seen  -- event_id PK, received_at  -- idempotency
```

### 0002_usage.sql — quota tracking

```sql
usage (
  license_key TEXT,
  date TEXT,             -- 'YYYY-MM-DD' UTC
  seconds_used INTEGER,
  PRIMARY KEY (license_key, date)
)
```

Reset implícito por día (date cambia). `incrementUsage` usa `INSERT ... ON CONFLICT DO UPDATE` atómico.

### Event types observados en producción

`activate`, `verify`, `verify_failed`, `deactivate`, `usage_report`, `quota_blocked` (nuevo), `signup` (nuevo), `signup_blocked` (nuevo), `email_failed` (nuevo), `rate_limit`, `webhook`, `admin`.

---

## 5. Flujo Free signup (end-to-end live)

```
1. Usuario: visita https://miloro.app/get-started/
2. Frontend: form email → POST /api/license/signup {email}
3. Worker handleSignupFree:
   a. checkSignupRateLimit(env, ip) → 429 si >= 3/h IP
   b. valida formato email
   c. getActiveFreeLicenseByEmail(email)
      - existe → idempotent=true, reusa
      - no existe → createLicense(plan=free, devices_max=1, status='free')
   d. logEvent(signup, lic.key, ip)
   e. sendEmail(welcomeEmail(...)) vía Resend
      - ok=false → logEvent(email_failed, lic.key, ip, {error, provider, target})
   f. return {status, plan, email_sent, idempotent, message}
4. Frontend muestra "Revisa tu inbox"
5. Usuario recibe email con UUID license key + link descarga + dashboard URL
6. Usuario abre MiLoro app → pega key → POST /api/license/activate {key, fingerprint}
7. App periódicamente POST /api/license/verify {key, fingerprint} → recibe quota_remaining_seconds, etc.
8. Tras cada transcripción: POST /api/usage/report {key, fingerprint, seconds}
   - Si Free y seconds_used >= 1800 → 429 quota_blocked
9. Al día siguiente UTC → quota reset (row nueva en usage por (key, new_date))
```

---

## 6. Flujo Pro €9 (cableado, esperando Day-X UJI)

```
1. Usuario: /signup/ form email
2. POST /api/checkout/session {plan: "pro", email} → Stripe Checkout URL
3. Redirect Stripe → pago tarjeta → success
4. Stripe webhook POST /api/webhook/stripe checkout.session.completed
   - verifyStripeSignature (HMAC SHA-256 custom SubtleCrypto)
   - claimWebhookEvent(event.id) — idempotency
   - getLicenseBySubscription o createLicense(plan=pro, devices_max=3, status=active)
   - sendEmail(welcomeEmail(pro)) con license key
5. Usuario recibe email → activa app → uso ilimitado
6. Stripe webhook subscription.updated/deleted/invoice.payment_failed → updateLicenseStatus
   - past_due → app sigue funcionando 7 días grace period
   - cancelled → app refuse start hasta nuevo pago
```

Activación a live mode = swap `sk_test_*` → `sk_live_*` en `/home/marc/.secrets/miloro_stripe_secret_key` + actualizar `STRIPE_PRICE_*` env vars en `wrangler.toml` con price IDs live (vía `setup_stripe_prices.sh --live --apply`).

---

## 7. Email transactional

### Provider strategy (`email.ts`)

```
sendEmail():
  if env.RESEND_API_KEY:
    POST resend.com/emails {from, to, subject, html, text}
    → 200 → return ok
    → 4xx → return error + log payload (truncado 200 chars)
  else:
    POST mailchannels.net/tx/v1/send  ← fallback, ROTO desde 2025 (401 free tier disabled)
    return error
```

### Estado producción

- **Provider activo**: Resend (key Marc cuenta personal, "Full access")
- **From actual**: `MiLoro <onboarding@resend.dev>` (sandbox Resend, pre-verificado, limitación: solo a email de cuenta Resend en free tier)
- **Pendiente clean**: verificar dominio `miloro.app` en Resend dashboard (DNS records MX + TXT SPF + TXT DKIM en Cloudflare) → permite from `hola@miloro.app` y enviar a cualquier dirección

### Templates

`welcomeEmail({email, licenseKey, plan, devicesMax})` — único template hoy. HTML responsive + text fallback. Tagline "🦜 Bienvenido al plan {Free|Pro|Compliance}". Soporte `alpha@miloro.app`. Footer compliance Marc Vicente García, Castellón.

---

## 8. Frontend landing

### Estructura `landing/`

```
landing/
├── index.html        — landing principal (hero + features + pricing 3 tiers + FAQ)
├── style.css         — paleta tropical (cream + verde loro + amarillo pico + rojo cabeza)
├── miloro-icon.png   — favicon + brand img
├── i18n.js + locales/— ES default + multi-idioma fase 2
├── get-started/      — signup Free público (NUEVO 2026-05-26)
│   └── index.html
├── signup/           — signup Pro €9 (cableado, redirige Stripe Checkout)
│   └── index.html
├── dashboard/        — info licencia (futuro fetch /api/license/dashboard)
├── checkout/         — Stripe success/cancel landing pages
├── functions/        — Cloudflare Pages Functions (extensibilidad futura)
│   └── updater/      — placeholder para B4 endpoint manifest
└── favicon.ico
```

### Hosting

- Cloudflare Pages project: `miloro-landing`
- Production branch: `main`
- Custom domain: `miloro.app` (apex + www)
- No build step (HTML estático). Deploy directo con `wrangler pages deploy .`

---

## 9. Desktop app Tauri (alpha Linux)

### Componentes

```
desktop/
├── src-tauri/        — Rust core, Tauri config, iconos, signing
│   ├── Cargo.toml    — package miloro-desktop, lib miloro_desktop_lib
│   ├── tauri.conf.json — productName MiLoro, identifier app.miloro
│   └── icons/        — multi-resolución parrot 🦜
├── src/              — Svelte UI
│   ├── App.svelte    — main, titlebar, brand, license-block, settings 3 columnas
│   └── lib/CustomSelect.svelte
├── index.html        — Vite entry
├── static/miloro-icon.png — servido por Vite
├── build_signed.sh   — wrapper Tauri build con clave firma (Marc keys)
├── release_v0_0_1.sh — wrapper gh release create
├── miloro-launcher.sh — wrapper sh + paths log ~/.local/share/miloro/
└── MiLoro.desktop    — XDG desktop entry
```

### Backend local del desktop (dogfooding Marc)

Live en `/home/claude/scripts/`:
- `oido_daemon.py` — Flask :4331 que mantiene modelo Whisper cargado en RAM
- `oido_ptt.py` — listener Right Ctrl
- `escuchar.sh` — bridge arecord → daemon → ydotool autotype + xclip
- `oido_watchdog.sh` — systemd timer 30s, restart si daemon muere
- `audio_a_texto.py` — CLI standalone

Notificaciones user-facing reescritas 2026-05-26: `notify-send -a "MiLoro"` (antes "Oído Digital").

### Estado v0.0.9 (2026-05-27)

- ~~**B4** Tauri updater endpoint~~ ✅ DONE 2026-05-26
- ~~**B5** System tray + autostart cross-OS (idea-194)~~ ✅ DONE — window close → hide al tray + PTT background
- ~~**idea-196** `enigo` Rust crate cross-OS autotype~~ ✅ DONE — Win/Mac usan enigo, Linux mantiene wl-copy+ydotool (sin popup Wayland)
- ~~**B2** Whisper embebido (whisper-rs)~~ ✅ DONE 2026-05-27 — app autosuficiente, no depende de oido-daemon python externo
- ~~**Quota Free** cableada end-to-end~~ ✅ DONE 2026-05-27 — reportUsage devuelve quota_exceeded + UI bloquea
- **B3** GitHub Actions matrix Linux+Win+macOS builds firmados — ✅ workflow listo en `.github/workflows/build.yml`, requiere Marc cree repo + push + configure secrets (`TAURI_SIGNING_PRIVATE_KEY` + password)
- **Code signing certs** (~$200/año Win + Mac) — pendiente Marc compra

---

## 10. Stripe integration

### Flow

```
1. Frontend POST /api/checkout/session {plan, email?}
2. Worker handleCheckout:
   - Si STRIPE_SECRET_KEY placeholder → 503 stub
   - Si STRIPE_PRICE_PRO placeholder → 503 stub
   - import dinámico stripe SDK + Stripe.createFetchHttpClient()
   - stripe.checkout.sessions.create(...) con success/cancel URLs
   - return {url: session.url}
3. Frontend redirect a Stripe-hosted checkout
4. Usuario paga (tarjeta TEST: 4242 4242 4242 4242)
5. Stripe → webhook POST /api/webhook/stripe checkout.session.completed
6. Worker handleStripeWebhook → crear license, mandar welcome email
```

### Setup (cuando Day-X)

```bash
./scripts/load_secrets.sh ./scripts/setup_stripe_prices.sh --live --apply
# Crea Pro Monthly €9 + Pro Annual €72 en LIVE mode
# Persiste IDs en /home/marc/.secrets/stripe_price_ids_live.env
# Sed wrangler.toml in-place con backup .bak
```

Webhook secret: dashboard Stripe → Developers → Webhooks → add endpoint `https://miloro.app/api/webhook/stripe` → copy signing secret (`whsec_*`) → guardar en `/home/marc/.secrets/miloro_stripe_webhook_secret`.

---

## 11. Secrets management

### Convención

Archivos en `/home/marc/.secrets/` (700, archivos 600). Agente Claude NO puede leer (hard rule §2.2 privacidad).

**Naming**:
- Prefijo proyecto: `miloro_*`, `paginaportada_*` para keys de servicios multi-proyecto (Resend, Stripe)
- Sin prefijo: keys de **cuenta Cloudflare** compartida (`cf_api_token`, `cf_account_id`)

### Archivos vivos hoy

```
/home/marc/.secrets/
├── miloro_resend_api_key        — re_... (Resend "miloro-prod" Full access)
├── miloro_resend_from           — 'MiLoro <onboarding@resend.dev>'
├── miloro_stripe_secret_key     — sk_test_... (→ sk_live_... post-Day-X)
├── miloro_stripe_webhook_secret — whsec_...
├── cf_api_token                 — Cloudflare API Token persistente
└── paginaportada_*              — keys del otro proyecto
```

### Loader `load_secrets.sh`

`load_secret_with_fallback(primary, secondary, var_name)`:
1. Si existe `$SECRETS_DIR/$primary` → cargar
2. Sino si existe `$SECRETS_DIR/$secondary` → cargar (compat retro)
3. Sino → warning

Lee archivo, `tr -d '\n\r '` para limpieza trailing chars, exporta env var, exec del proceso hijo. Las keys nunca tocan disco fuera de `/home/marc/.secrets/`.

### Push a Worker (deploy_backend_prod.sh)

```bash
printf '%s' "$VAR" | wrangler secret put VAR_NAME
```

Importante: `printf '%s'` (NO `echo` que añade `\n` → algunas APIs lo interpretan literal → 401 invalid key).

---

## 12. Deploy pipeline

### Scripts en `backend/scripts/`

| Script | Función | Idempotente | Flags |
|---|---|---|---|
| `load_secrets.sh` | Carga secrets, exec comando hijo | ✅ | — |
| `deploy_backend_prod.sh` | secrets + migrations + deploy + health check | ✅ | `--no-migrate` `--no-secrets` `--dry-run` |
| `deploy_landing_prod.sh` | Pre-crea Pages project + deploy | ✅ | `--dry-run` `--branch=X` |
| `setup_stripe_prices.sh` | Crea Pro Monthly + Annual prices vía REST | ✅ (crea nuevos cada vez, no detecta existentes) | `--live` `--apply` |
| `test_signup.sh <email>` | Curl signup + parse response | ✅ | — |
| `dev_signup_test.sh [email]` | reset rate-limit D1 + test + lee email_failed | ✅ (DEV ONLY) | email arg opcional (default marcstarwars@gmail.com) |
| `dev_test_resend_direct.sh [to]` | Aisla Resend (saltea Worker) | ✅ | — |
| `fingerprint_stub.py` | Genera fingerprint reproducible para test | — | — |

### Comando deploy completo

```bash
cd /home/Projects/parla/backend

# Primera vez (full setup)
./scripts/load_secrets.sh ./scripts/setup_stripe_prices.sh --apply  # test mode
./scripts/load_secrets.sh ./scripts/deploy_backend_prod.sh
./scripts/load_secrets.sh ./scripts/deploy_landing_prod.sh

# Re-deploys subsiguientes (más rápidos)
./scripts/load_secrets.sh ./scripts/deploy_backend_prod.sh --no-migrate
./scripts/load_secrets.sh ./scripts/deploy_landing_prod.sh
```

---

## 13. Auth strategy

### Hoy (MVP Free)

**Sin auth de usuario**. License key UUID actúa como bearer-equivalente:
- Recibida por email tras signup
- Pega en app desktop → activa con fingerprint
- App POST verify periódicamente
- Dashboard público con `?key=X` (URL-as-auth, no ideal pero MVP)

### Futuro (post-MVP, idea-182)

Stack auth elegido: **better-auth** + Cloudflare D1 + Resend magic link.
- Misma DB `parla_licenses`, tablas `user`, `session`, `account`, `verification` auto-generadas por better-auth CLI
- Magic link sin password (UX moderna B2C)
- Google OAuth opcional fase 2
- GDPR EU: D1 EU region → data residency total

**Decisión 2026-05-17 (decisiones.md)**: NO Keycloak (sobre-engineering JVM), NO Clerk (lock-in UI propietario). better-auth = open source, TS-first, nativo Workers.

---

## 14. Hosting + costes infra (estimado año 1)

| Servicio | Plan | Coste/mes año 1 |
|---|---|---|
| Cloudflare Workers + D1 | Free tier (100k req/día + 5GB) | €0 |
| Cloudflare Pages | Free tier (500 builds/mes) | €0 |
| Cloudflare R2 (futuro: crash dumps) | Free tier (10GB + sin egress) | €0 |
| Resend transactional email | Free tier (3k emails/mes) | €0 |
| Stripe | Pay-per-tx (1.5% + €0.25 EU) | €0 fijo |
| Dominios `miloro.app` + futuros | Porkbun | €14/año = ~€1.20 |
| **TOTAL/mes año 1** | | **€1.20** |

Crecimiento 200+ users año 2: ~€30-80/mes (Resend paid tier + Workers paid tier si superas).

---

## 14-bis. Updater Tauri (B4 — implementado 2026-05-26)

### Cómo funciona

```
Cliente Tauri arranca → plugin updater consulta endpoint configurado:
  GET https://miloro.app/api/updater/{target}-{arch}/{current_version}[?channel=stable]

Worker handleUpdater:
  1. Parse path: extrae platform_key (ej. linux-x86_64) y current_version
  2. Valida platform contra SUPPORTED_PLATFORMS
  3. Valida version es semver X.Y.Z
  4. Valida channel (stable | beta)
  5. getManifest(env.MILORO_UPDATES, channel) ← lee KV
  6. resolveUpdate(manifest, currentVersion, platform_key):
     - manifest null → return null (no KV configurado)
     - compareSemver(manifest.version, currentVersion) <= 0 → null (cliente al día)
     - platform no soportada en manifest → null
     - else → { version, pub_date, notes, url, signature }
  7. Si null → 204 No Content (Tauri interpreta como "no update")
  8. Si update → 200 + JSON, cache-control 300s
```

### Publicación de nueva versión (Marc workflow)

1. **Build firmado**: `cd desktop && ./build_signed.sh` genera `.AppImage.tar.gz` + `.sig`
2. **GitHub release**: `./release_v0_0_1.sh` adaptado a `vX.Y.Z`
3. **Publicar manifest**:
   ```bash
   ./scripts/load_secrets.sh ./scripts/release_update.sh stable X.Y.Z \
     --linux-url=https://github.com/.../release.AppImage.tar.gz \
     --linux-sig="$(cat MiLoro_X.Y.Z_amd64.AppImage.tar.gz.sig)" \
     --notes='Markdown release notes'
   ```
4. Clientes existentes detectan update en su próximo arranque (o periódicamente per config Tauri).

### Setup KV (UNA SOLA VEZ Marc)

```bash
wrangler kv namespace create MILORO_UPDATES
# Pega el id en wrangler.toml descomentando bloque [[kv_namespaces]]
./scripts/load_secrets.sh ./scripts/deploy_backend_prod.sh --no-migrate
```

Sin KV bindeado → `/api/updater/*` devuelve siempre 204 (degradación segura, no rompe nada).

### Seguridad

- **Pubkey embedded en cliente** (`tauri.conf.json plugins.updater.pubkey`) — Tauri verifica firma del binary descargado contra esa pubkey ANTES de instalar. Si firma no valida → rechaza.
- **Privkey en `~/.tauri/miloro-update.key` Marc** (con passphrase) — NUNCA en repo.
- **Atacante MITM** que sirve manifest falso con URL maliciosa → el `.sig` no validará contra pubkey → cliente rechaza el binary.
- **Brute force endpoint** → cero impacto (sirve archivo público, no datos sensibles).

---

## 15. Cambios recientes (2026-05-25/26 sesión MVP)

Cronológico inverso. Para detalles ver `/home/claude/logs/sesion_2026-05-25_miloro_mvp_free_live.md`.

- **v0.0.9 publicada (2026-05-27)**: Whisper embebido (whisper-rs + bindings whisper.cpp) — la app YA NO depende del oido-daemon python externo. Auto-descarga modelo Whisper (~466MB small) a `~/.local/share/miloro/models/` primera vez. Quota Free cableada end-to-end (reportUsage devuelve quota_exceeded, UI bloquea). idea-196 enigo Win/Mac confirmado in-place. B5 system tray confirmado in-place (window close → hide, PTT sigue background). B3 GitHub Actions workflow listo (`.github/workflows/build.yml` + `.github/SETUP_REPO.md`) pendiente Marc cree repo. Endpoint `/api/download/:platform` redirige al manifest stable. Landing miloro.app sin Compliance €49 (solo Free + Pro).
- **B4 Tauri updater (2026-05-26)**: endpoint `/api/updater/{target}-{arch}/{ver}` + script `release_update.sh` + manifest en KV `MILORO_UPDATES` + tauri.conf.json apunta al Worker. Pendiente: Marc crea KV + publica 1er manifest.
- **Anti-enumeration signup (2026-05-26)**: response NO devuelve `idempotent` ni `key`, mensaje neutro idéntico. Atacante no puede sondear qué emails están registrados. Flag idempotent sigue en logs internos D1 para analytics Marc.
- **Free signup público** desplegado: endpoint `/api/license/signup` + página `/get-started/` + rate-limit + idempotencia + welcome email Resend.
- **Quota Free 30min/día** enforcement backend (429 si exceeded) + exposed quota fields en verify/dashboard/usage_report.
- **PLAN_DEVICE_LIMITS** fix: Pro pasa de 1 → 3 devices (alineado con decisión 2026-05-24).
- **Decisión arquitectónica**: Marc rechaza rol data processor → idea-207 Compliance parked, tres caminos abiertos (A/B/C).
- **Scripts deploy** producidos: 3 deploy idempotentes + 3 dev helpers.
- **Secrets management** refactor: convención prefijos por proyecto + `printf '%s'` para evitar trailing `\n` que rompía Resend 401.
- **Rebrand interno** `notify-send "Oído Digital" → "MiLoro"` en scripts dogfooding Marc.
- **Backend deployment** primera vez en producción 2026-05-25 (`ecca8077` → versions sucesivas hasta `2d016df5`).
- **Landing deployment** primera vez en Cloudflare Pages 2026-05-25 (`miloro-landing` project).
- **Resend integrado** con key dedicada `miloro-prod` (Full access) + dominio sandbox `onboarding@resend.dev`.

---

## 16. Pendiente (orden de impacto)

| Bloque | Esfuerzo | Bloqueador | Impacto |
|---|---|---|---|
| Verificar miloro.app en Resend (DNS) | 15min + propagación | acción Marc dashboard | Limpio: from `hola@miloro.app` en vez sandbox |
| **B4 — Updater Tauri endpoint** | ~3h | nada | Pushar updates sin reinstall |
| **B5 — System tray + autostart cross-OS** | ~5h | nada | UX daemon mode (idea-194) |
| **idea-196 — `enigo` cross-OS autotype** | ~3h | nada | **BLOQUEA Win/Mac packaging** |
| **B3 — GitHub Actions matrix builds** | ~6h | idea-196 | Releases firmadas 3 OS |
| Code signing Win cert (~$90-300/año) | 30min + pago | acción Marc | Sin warning "Unknown publisher" |
| Apple Developer Program ($99/año) | 30min + pago | acción Marc | Notarización macOS |
| Stripe LIVE activate | post-Day-X UJI | Ley 53/1984 + alta autónomo | Cobros reales |
| **idea-207 BYOK Compliance €49** | 70h dev + 10h validación | Free+€9 funcionando + 3 psi entrevistados | Tier €49 monetizable |

---

## 17. Decisiones de referencia

Detalles + alternativas evaluadas + por qué — en `/home/claude/memoria/decisiones.md`:

- **2026-05-25**: Marc rechaza rol data processor → idea-207 Compliance pivot a BYOK/local-only/drop.
- **2026-05-24**: Pricing simplificado Free + Pro €9 (vs 3-tier original). Devices Pro = 3.
- **2026-05-24**: Rebrand Parla → MiLoro (theme tropical, dominios miloro.app + miloro.es).
- **2026-05-18**: Estrategia "producto primero, dominio al final" (revertida 2026-05-25 cuando se compró miloro.app).
- **2026-05-17**: Stack auth = better-auth (NO Keycloak, NO Clerk).

---

*Mantén este documento sincronizado con cada cambio arquitectónico. Si un componente queda obsoleto, retíralo aquí en la misma intervención.*
