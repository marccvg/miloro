# parla-license-server (MVP local-first)

License server para [Parla](../ROADMAP.md) (desktop app B2C transcripción local).

Stack: **Cloudflare Workers TypeScript + D1 SQLite + Stripe**. Sin dominio, sin deploy, sin Stripe live — todo local con `wrangler dev` y test mode mock.

Patrones reusados (auditados): fuck-loomis `verifactuService` (audit log granular + idempotency table), `escapeXml` (en `src/util.ts` para futura factura), middleware-style request handling estilo `TenantInterceptor`.

---

## Pricing modelado

| Plan | Precio | Devices máx | Modelo Whisper | Status default |
|---|---|---|---|---|
| Free | €0 | 1 | small | `free` |
| Standard | €9/mes | 2 | medium | `active` (subscription) |
| Pro | €19/mes | 3 | large + diariz | `active` (subscription) |

Mapping a `STRIPE_PRICE_STANDARD` / `STRIPE_PRICE_PRO` configurable en `wrangler.toml`.

---

## Setup

```bash
cd /home/Projects/parla/backend
npm install
cp .dev.vars.example .dev.vars   # rellenar secrets locales
npm run db:migrate               # crea schema en .wrangler/state local
npm run dev                      # wrangler dev --local → http://127.0.0.1:8787
```

Tests:

```bash
npm test                         # vitest + miniflare in-memory D1
npm run typecheck                # tsc --noEmit
```

---

## Endpoints

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| GET | `/health` | – | Liveness check |
| POST | `/api/license/activate` | – | Body `{key, fingerprint, hostname?, os?}` → reserva slot device. Rate-limited 5/h/IP |
| POST | `/api/license/verify` | – | Body `{key, fingerprint}` → estado + plan (cacheable 60s) |
| POST | `/api/license/deactivate` | – | Body `{key, fingerprint}` → libera slot |
| GET | `/api/license/dashboard?key=<uuid>` | – | Resumen licencia + devices |
| POST | `/api/license/issue` | Bearer `ADMIN_TOKEN` | Admin: emite licencia Free/Standard/Pro sin Stripe (testing) |
| POST | `/api/checkout/session` | – | Body `{plan: 'standard'\|'pro', email?}` → URL Stripe Checkout |
| POST | `/api/webhook/stripe` | HMAC `stripe-signature` | Recibe eventos Stripe (idempotency via `stripe_webhooks_seen`) |

---

## Cómo probar manualmente

### 1. Emitir licencia Free (sin Stripe)

```bash
curl -s -X POST http://127.0.0.1:8787/api/license/issue \
  -H 'authorization: Bearer local-admin-token-change-me' \
  -H 'content-type: application/json' \
  -d '{"email":"marc@local","plan":"free"}'
# → {"status":"ok","key":"<uuid>","plan":"free","devices_max":1}
```

### 2. Activar device usando fingerprint stub

```bash
KEY="<uuid de paso 1>"
FP=$(python3 scripts/fingerprint_stub.py)
curl -s -X POST http://127.0.0.1:8787/api/license/activate \
  -H 'content-type: application/json' \
  -d "{\"key\":\"$KEY\",\"fingerprint\":\"$FP\",\"hostname\":\"$(hostname)\",\"os\":\"linux\"}"
# → {"status":"ok","device_id":"<uuid>"}
```

### 3. Verificar

```bash
curl -s -X POST http://127.0.0.1:8787/api/license/verify \
  -H 'content-type: application/json' \
  -d "{\"key\":\"$KEY\",\"fingerprint\":\"$FP\"}"
# → {"status":"ok","plan":"free","devices_used":1,"devices_max":1,...}
```

### 4. Dashboard

```bash
curl -s "http://127.0.0.1:8787/api/license/dashboard?key=$KEY" | jq
```

### 5. Liberar slot

```bash
curl -s -X POST http://127.0.0.1:8787/api/license/deactivate \
  -H 'content-type: application/json' \
  -d "{\"key\":\"$KEY\",\"fingerprint\":\"$FP\"}"
```

---

## Stripe sandbox setup (cuando Marc active cuenta test)

1. Crear cuenta Stripe en modo test.
2. Crear productos + precios recurring para Standard (€9/mes) y Pro (€19/mes). Anotar los `price_xxx` IDs.
3. Editar `wrangler.toml` reemplazando `STRIPE_PRICE_STANDARD` / `STRIPE_PRICE_PRO` con los `price_xxx` reales.
4. Configurar secret local:
   ```bash
   echo 'STRIPE_SECRET_KEY="sk_test_..."' >> .dev.vars
   echo 'STRIPE_WEBHOOK_SECRET="whsec_..."' >> .dev.vars
   ```
5. Para webhook local usar Stripe CLI:
   ```bash
   stripe listen --forward-to http://127.0.0.1:8787/api/webhook/stripe
   # imprime un whsec_... → poner en .dev.vars
   ```
6. Trigger eventos sintéticos:
   ```bash
   stripe trigger checkout.session.completed
   stripe trigger customer.subscription.deleted
   stripe trigger invoice.payment_failed
   ```

---

## Anti-piratería: machine fingerprint

`scripts/fingerprint_stub.py` produce hash SHA256 estable basado en CPU + MAC + OS. La app Tauri usará Rust equivalente con datos más estables (disk serial, OS install id) cuando exista (Bloque A roadmap).

Refuerzos contra share-de-key:

- `devices` table tiene `UNIQUE(license_key, fingerprint)` → mismo device no se cuenta 2 veces.
- `activate` cuenta slots activos (`deactivated_at IS NULL`) y rechaza si >= `devices_max`.
- Rate limit 5 activates/IP/hora (anti brute-force probar UUIDs).
- Audit log granular (`events` table) — análisis post-mortem si alguien viola TOS.
- Webhook idempotency (`stripe_webhooks_seen`) — evita doble cobro / doble creación.

---

## Deploy (BLOQUEADO hasta OK explícito Marc)

`npm run deploy` está saboteado intencionalmente. Para desplegar:

1. Marc autoriza explícitamente (decisión durable + entrada en `memoria/decisiones.md`).
2. Crear D1 remota: `wrangler d1 create parla_licenses` → pegar `database_id` en `wrangler.toml`.
3. Aplicar migraciones: `npm run db:migrate:remote`.
4. Subir secrets:
   ```bash
   wrangler secret put STRIPE_SECRET_KEY
   wrangler secret put STRIPE_WEBHOOK_SECRET
   wrangler secret put ADMIN_TOKEN
   ```
5. Editar `scripts/deploy` para quitar `&& exit 1` y luego `wrangler deploy`.

---

## Limitaciones MVP (post-Day-X iterar)

- Rate limit usa `events` table — para producción con tráfico real migrar a Cloudflare Rate Limiting o Durable Object con counter (~1h trabajo).
- Verify TTL 60s en header `cache-control` pero no hay edge cache real — la app cliente debe cachear el response.
- No hay re-issue de license key (si Marc pierde la suya, manual via admin DB).
- No email transaccional (welcome / cancelled / past_due) — pendiente decisión D8 (Resend vs Postmark).
- No portal cliente self-service para cambiar plan / cancelar — Marc lo hace via Stripe Customer Portal (URL en email).

---

## Estructura

```
backend/
├─ src/
│   ├─ index.ts        ← router + handlers
│   ├─ types.ts        ← interfaces D1 + bodies
│   ├─ util.ts         ← uuid, json, escapeXml, ip, hex, timing-safe compare
│   ├─ audit.ts        ← logEvent (events table)
│   ├─ ratelimit.ts    ← checkActivateRateLimit (events-based)
│   ├─ licenses.ts     ← repo D1: create/get/update/list devices
│   └─ stripe.ts       ← verify HMAC SHA256 + price→plan + idempotency
├─ migrations/
│   └─ 0001_init.sql
├─ test/
│   ├─ setup.ts        ← schema apply + fingerprint helper
│   └─ license.test.ts ← 12+ tests
├─ scripts/
│   └─ fingerprint_stub.py
├─ wrangler.toml
├─ tsconfig.json
├─ vitest.config.ts
└─ package.json
```
