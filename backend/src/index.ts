/**
 * Parla license server — Cloudflare Worker entry.
 * Marc 2026-05-19: MVP local-first. Endpoints: activate / verify / deactivate /
 * dashboard / issue (admin) / checkout / webhook stripe / health.
 *
 * Patrones reusados de fuck-loomis:
 *   - audit log granular (`events` table) — verifactu submissions pattern
 *   - middleware-style request handling — TenantInterceptor flavor
 *   - escapeXml (en util.ts) por si futura factura — verifactuService.ts
 */
import { logEvent } from "./audit";
import { sendEmail, welcomeEmail } from "./email";
import {
  createLicense,
  deactivateDevice,
  getActiveFreeLicenseByEmail,
  getDevice,
  getLicense,
  getLicenseBySubscription,
  getUsageToday,
  incrementUsage,
  insertDevice,
  listActiveDevices,
  reactivateDevice,
  touchDeviceLastSeen,
  updateLicenseStatus,
} from "./licenses";
import { checkActivateRateLimit, checkSignupRateLimit } from "./ratelimit";
import { getManifest, resolveUpdate, SUPPORTED_PLATFORMS } from "./updater";
import {
  claimWebhookEvent,
  priceIdToPlan,
  type StripeEventBasic,
  verifyStripeSignature,
} from "./stripe";
import {
  PLAN_DEVICE_LIMITS,
  PLAN_QUOTA_SECONDS_DAILY,
  quotaCheck,
  type ActivateBody,
  type CheckoutBody,
  type DeactivateBody,
  type Env,
  type IssueBody,
  type Plan,
  type VerifyBody,
} from "./types";
import {
  badRequest,
  clientIp,
  corsPreflight,
  forbidden,
  json,
  nextUtcMidnight,
  notFound,
  nowS,
  serverError,
  tooMany,
  unauthorized,
} from "./util";

// =========================================================================
// Helpers
// =========================================================================
function isPlan(s: unknown): s is Plan {
  return s === "free" || s === "standard" || s === "pro";
}

function isValidFingerprint(fp: unknown): fp is string {
  // SHA256 hex = 64 chars. Toleramos 32-128 (variantes) y solo hex/alnum básico.
  return typeof fp === "string" && fp.length >= 32 && fp.length <= 128 && /^[a-zA-Z0-9_-]+$/.test(fp);
}

function isUuid(s: unknown): s is string {
  return (
    typeof s === "string" &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s)
  );
}

async function readJson<T>(req: Request): Promise<T | null> {
  try {
    return (await req.json()) as T;
  } catch {
    return null;
  }
}

// =========================================================================
// Endpoint handlers
// =========================================================================

async function handleActivate(req: Request, env: Env): Promise<Response> {
  const ip = clientIp(req);

  if (!(await checkActivateRateLimit(env, ip))) {
    await logEvent(env, "rate_limit", null, ip, { endpoint: "activate" });
    return tooMany("too many activation attempts from this IP, retry in 1h");
  }

  const body = await readJson<ActivateBody>(req);
  if (!body || !isUuid(body.key) || !isValidFingerprint(body.fingerprint)) {
    await logEvent(env, "activate", null, ip, { ok: false, reason: "bad_body" });
    return badRequest("invalid body — need {key:uuid, fingerprint:hex}");
  }

  const lic = await getLicense(env, body.key);
  if (!lic) {
    await logEvent(env, "activate", body.key, ip, { ok: false, reason: "unknown_key" });
    return notFound("license key not found");
  }
  if (lic.status === "cancelled") {
    await logEvent(env, "activate", body.key, ip, { ok: false, reason: "cancelled" });
    return forbidden("license cancelled");
  }
  if (lic.expires_at && lic.expires_at < nowS()) {
    await logEvent(env, "activate", body.key, ip, { ok: false, reason: "expired" });
    return forbidden("license expired", { expires_at: lic.expires_at });
  }

  // ¿Existe ya este fingerprint? Si está activo, idempotente. Si deactivado, reactivar (re-issue id).
  const existing = await getDevice(env, lic.key, body.fingerprint);
  if (existing && existing.deactivated_at === null) {
    await touchDeviceLastSeen(env, existing.id);
    await logEvent(env, "activate", lic.key, ip, { ok: true, device_id: existing.id, idempotent: true });
    return json({ status: "ok", device_id: existing.id, idempotent: true });
  }
  if (existing && existing.deactivated_at !== null) {
    // Re-activar slot — pero solo si quedan slots libres (puede haberse llenado con otros).
    const active = await listActiveDevices(env, lic.key);
    if (active.length >= lic.devices_max) {
      await logEvent(env, "activate", lic.key, ip, { ok: false, reason: "slot_full" });
      return forbidden("device slot full", {
        devices_used: active.length,
        devices_max: lic.devices_max,
        devices: active.map((d) => ({
          id: d.id,
          hostname: d.hostname,
          os: d.os,
          last_seen: d.last_seen,
        })),
      });
    }
    await reactivateDevice(env, existing.id);
    await logEvent(env, "activate", lic.key, ip, { ok: true, device_id: existing.id, reactivated: true });
    return json({ status: "ok", device_id: existing.id, reactivated: true });
  }

  // Slot nuevo.
  const active = await listActiveDevices(env, lic.key);
  if (active.length >= lic.devices_max) {
    await logEvent(env, "activate", lic.key, ip, { ok: false, reason: "slot_full" });
    return forbidden("device slot full", {
      devices_used: active.length,
      devices_max: lic.devices_max,
      devices: active.map((d) => ({
        id: d.id,
        hostname: d.hostname,
        os: d.os,
        last_seen: d.last_seen,
      })),
    });
  }
  const dev = await insertDevice(env, {
    licenseKey: lic.key,
    fingerprint: body.fingerprint,
    hostname: body.hostname ?? null,
    os: body.os ?? null,
  });
  await logEvent(env, "activate", lic.key, ip, { ok: true, device_id: dev.id });
  return json({ status: "ok", device_id: dev.id });
}

async function handleVerify(req: Request, env: Env): Promise<Response> {
  const ip = clientIp(req);
  const body = await readJson<VerifyBody>(req);
  if (!body || !isUuid(body.key) || !isValidFingerprint(body.fingerprint)) {
    return badRequest("invalid body");
  }
  const lic = await getLicense(env, body.key);
  if (!lic) {
    await logEvent(env, "verify_failed", body.key, ip, { reason: "unknown_key" });
    return notFound("license key not found");
  }
  const dev = await getDevice(env, lic.key, body.fingerprint);
  if (!dev || dev.deactivated_at !== null) {
    await logEvent(env, "verify_failed", lic.key, ip, { reason: "device_not_active" });
    return forbidden("device not activated for this license");
  }
  if (lic.status === "cancelled" || lic.status === "past_due") {
    await logEvent(env, "verify_failed", lic.key, ip, { reason: `status_${lic.status}` });
    return forbidden(`license ${lic.status}`, { plan: lic.plan, status: lic.status });
  }
  if (lic.expires_at && lic.expires_at < nowS()) {
    await logEvent(env, "verify_failed", lic.key, ip, { reason: "expired" });
    return forbidden("license expired", { expires_at: lic.expires_at });
  }
  await touchDeviceLastSeen(env, dev.id);
  const active = await listActiveDevices(env, lic.key);
  const secondsUsedToday = await getUsageToday(env, lic.key);
  const quota = quotaCheck(lic.plan, secondsUsedToday);
  const ttl = Number(env.VERIFY_CACHE_TTL_S || "60");
  return json(
    {
      status: "ok",
      plan: lic.plan,
      license_status: lic.status,
      devices_used: active.length,
      devices_max: lic.devices_max,
      expires_at: lic.expires_at,
      seconds_used_today: secondsUsedToday,
      quota_seconds_daily: quota.quota_seconds_daily,
      quota_remaining_seconds: quota.remaining_seconds,
      quota_unlimited: quota.unlimited,
      quota_exceeded: !quota.allowed,
      quota_reset_at: quota.unlimited ? null : nextUtcMidnight(),
    },
    { headers: { "cache-control": `private, max-age=${ttl}` } },
  );
}

async function handleDeactivate(req: Request, env: Env): Promise<Response> {
  const ip = clientIp(req);
  const body = await readJson<DeactivateBody>(req);
  if (!body || !isUuid(body.key) || !isValidFingerprint(body.fingerprint)) {
    return badRequest("invalid body");
  }
  const lic = await getLicense(env, body.key);
  if (!lic) return notFound("license key not found");
  const dev = await getDevice(env, lic.key, body.fingerprint);
  if (!dev || dev.deactivated_at !== null) {
    return json({ status: "ok", already: true });
  }
  await deactivateDevice(env, dev.id);
  await logEvent(env, "deactivate", lic.key, ip, { device_id: dev.id });
  return json({ status: "ok", freed_slot: true });
}

/**
 * POST /api/usage/report — la app reporta segundos de audio tras cada transcripción.
 * Body: { key, fingerprint, seconds }
 * Valida que key existe + device fingerprint coincide con device activo de esa licencia.
 * Incrementa el contador atómico de seconds_used para hoy (UTC).
 */
async function handleUsageReport(req: Request, env: Env): Promise<Response> {
  const ip = clientIp(req);
  const body = await readJson<{ key?: string; fingerprint?: string; seconds?: number }>(req);
  if (!body || !isUuid(body.key) || !isValidFingerprint(body.fingerprint)) {
    return badRequest("invalid body");
  }
  const seconds = Number(body.seconds);
  if (!Number.isFinite(seconds) || seconds < 0 || seconds > 7200) {
    return badRequest("invalid seconds (must be 0..7200)");
  }
  const lic = await getLicense(env, body.key);
  if (!lic) return notFound("license key not found");
  const dev = await getDevice(env, lic.key, body.fingerprint);
  if (!dev || dev.deactivated_at !== null) {
    return forbidden("device not active for this license");
  }
  // Quota enforcement: si ya está al límite o por encima, NO incrementamos y devolvemos 429.
  // (Pro/standard tienen unlimited=true → siempre pasa.)
  const currentUsed = await getUsageToday(env, lic.key);
  const currentQuota = quotaCheck(lic.plan, currentUsed);
  if (!currentQuota.unlimited && !currentQuota.allowed) {
    await logEvent(env, "quota_blocked", lic.key, ip, {
      plan: lic.plan,
      seconds_used_today: currentUsed,
      quota_seconds_daily: currentQuota.quota_seconds_daily,
      attempted_seconds: Math.round(seconds),
    });
    return tooMany(`daily quota exceeded for plan '${lic.plan}'`, {
      plan: lic.plan,
      seconds_used_today: currentUsed,
      quota_seconds_daily: currentQuota.quota_seconds_daily,
      quota_remaining_seconds: 0,
      quota_reset_at: nextUtcMidnight(),
    });
  }

  // No bloqueamos por status cancelled/past_due en report — solo verifica enforcement.
  // Aún así loggeamos para audit (uso "fantasma" tras cancel).
  const newTotal = await incrementUsage(env, lic.key, Math.round(seconds));
  const newQuota = quotaCheck(lic.plan, newTotal);
  await logEvent(env, "usage_report", lic.key, ip, {
    device_id: dev.id,
    seconds_reported: Math.round(seconds),
    seconds_used_today: newTotal,
    quota_exceeded: !newQuota.allowed,
  });
  return json({
    status: "ok",
    seconds_used_today: newTotal,
    quota_seconds_daily: newQuota.quota_seconds_daily,
    quota_remaining_seconds: newQuota.remaining_seconds,
    quota_unlimited: newQuota.unlimited,
    quota_exceeded: !newQuota.allowed,
    quota_reset_at: newQuota.unlimited ? null : nextUtcMidnight(),
  });
}

async function handleDashboard(req: Request, env: Env): Promise<Response> {
  const url = new URL(req.url);
  const key = url.searchParams.get("key");
  if (!key || !isUuid(key)) return badRequest("invalid key");
  const lic = await getLicense(env, key);
  if (!lic) return notFound("license not found");
  const devices = await listActiveDevices(env, lic.key);
  const secondsUsedToday = await getUsageToday(env, lic.key);
  const quota = quotaCheck(lic.plan, secondsUsedToday);
  return json({
    status: "ok",
    license: {
      key: lic.key,
      email: lic.email,
      plan: lic.plan,
      devices_max: lic.devices_max,
      license_status: lic.status,
      created_at: lic.created_at,
      expires_at: lic.expires_at,
      last_payment_at: lic.last_payment_at,
      cancelled_at: lic.cancelled_at,
      has_stripe_subscription: Boolean(lic.stripe_customer_id),
    },
    devices_used: devices.length,
    devices: devices.map((d) => ({
      id: d.id,
      hostname: d.hostname,
      os: d.os,
      activated_at: d.activated_at,
      last_seen: d.last_seen,
    })),
    seconds_used_today: secondsUsedToday,
    quota_seconds_daily: quota.quota_seconds_daily,
    quota_remaining_seconds: quota.remaining_seconds,
    quota_unlimited: quota.unlimited,
    quota_exceeded: !quota.allowed,
    quota_reset_at: quota.unlimited ? null : nextUtcMidnight(),
  });
}

/**
 * Endpoint público de descarga: redirige al binario latest según platform.
 * GET /api/download/{platform}[?format=appimage]
 *   platform: linux | windows | macos | macos-arm
 *
 * Lee el manifest stable del KV MILORO_UPDATES y hace 302 a la URL del platform.
 * Para Linux, por defecto sirve .deb (compatible con drivers Wayland modernos donde
 * el AppImage ha tenido crashes WebKit amarillos). AppImage opt-in vía ?format=appimage.
 * Si no hay manifest o platform no soportado → 404.
 */
async function handleDownload(req: Request, env: Env): Promise<Response> {
  const url = new URL(req.url);
  const parts = url.pathname.split("/").filter(Boolean);
  // /api/download/{platform}
  const platformArg = parts[2] ?? "";
  const platformMap: Record<string, string> = {
    linux: "linux-x86_64",
    "linux-arm": "linux-aarch64",
    windows: "windows-x86_64",
    "windows-arm": "windows-aarch64",
    macos: "darwin-x86_64",
    "macos-arm": "darwin-aarch64",
  };
  const platformKey = platformMap[platformArg];
  if (!platformKey) {
    return notFound(`platform '${platformArg}' not supported. Use: linux | windows | macos | macos-arm`);
  }
  const manifest = await getManifest(env.MILORO_UPDATES, "stable");
  if (!manifest) {
    return notFound("no release published yet");
  }
  const asset = manifest.platforms[platformKey];
  if (!asset) {
    return notFound(`platform '${platformArg}' not available in latest release v${manifest.version}`);
  }

  // Construimos la R2 key directamente por versión + platform + formato (NO derivamos
  // del asset.url del manifest, porque ese ahora apunta al wrapper updater .tar.gz/.zip
  // que el plugin Tauri necesita; pero los users hacen click en "Descargar alpha" y
  // esperan el raw .deb/.exe/.app.tar.gz que pueden abrir directo).
  const version = manifest.version;
  const format = url.searchParams.get("format");
  let filename: string;
  switch (platformArg) {
    case "linux":
      filename = format === "appimage"
        ? `MiLoro_${version}_amd64.AppImage`
        : `MiLoro_${version}_amd64.deb`;
      break;
    case "windows":
      filename = `MiLoro_${version}_x64-setup.exe`;
      break;
    case "macos":
    case "macos-arm":
      filename = "MiLoro.app.tar.gz";
      break;
    default:
      return notFound(`download for platform '${platformArg}' not implemented`);
  }
  const assetKey = `v${version}/${filename}`;

  // Si R2 está bindeado, proxy stream con Content-Disposition: attachment.
  // Esto fuerza al navegador a descargar (no "abrir con…"); evita que GNOME muestre
  // las "muchas carpetas" del .deb interno (control.tar + data.tar) en Archive Manager.
  if (env.MILORO_RELEASES) {
    const obj = await env.MILORO_RELEASES.get(assetKey);
    if (!obj) return notFound(`asset not in R2: ${assetKey}`);
    const filename = assetKey.split("/").pop() ?? "miloro-download";
    const headers = new Headers();
    headers.set("Content-Type", "application/octet-stream");
    headers.set("Content-Disposition", `attachment; filename="${filename}"`);
    headers.set("Content-Length", String(obj.size));
    headers.set("cache-control", "public, max-age=300");
    return new Response(obj.body, { status: 200, headers });
  }

  // Fallback (binding R2 no configurado): 302 a la URL pública del bucket.
  // Toma el host de asset.url y reescribe el path al assetKey calculado arriba.
  const fallbackUrl = new URL(asset.url);
  fallbackUrl.pathname = "/" + assetKey;
  return new Response(null, {
    status: 302,
    headers: { Location: fallbackUrl.toString(), "cache-control": "no-cache" },
  });
}

/**
 * Endpoint updater Tauri.
 * GET /api/updater/{target}-{arch}/{current_version}[?channel=stable|beta]
 *
 * Devuelve:
 *   204 No Content → cliente está al día (no update)
 *   200 + JSON {version, pub_date, url, signature, notes} → update disponible
 *   400 → path/version inválido
 *
 * El manifest vive en KV namespace MILORO_UPDATES con key = channel.
 * Si KV no bindeado o manifest no existe → 204 (degradar a "no update").
 */
async function handleUpdater(req: Request, env: Env): Promise<Response> {
  const url = new URL(req.url);
  // Path esperado: /api/updater/{target}-{arch}/{current_version}
  // Ej: /api/updater/linux-x86_64/0.0.4
  const parts = url.pathname.split("/").filter(Boolean);
  if (parts.length !== 4 || parts[0] !== "api" || parts[1] !== "updater") {
    return badRequest("invalid updater path, expected /api/updater/{target-arch}/{current_version}");
  }
  const platformKey = parts[2] ?? "";
  const currentVersion = parts[3] ?? "";

  if (!SUPPORTED_PLATFORMS.has(platformKey)) {
    return badRequest(`platform '${platformKey}' not supported`);
  }
  // Validación versión: X.Y.Z[-suffix] simple
  if (!/^\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?$/.test(currentVersion)) {
    return badRequest(`invalid version '${currentVersion}', expected semver X.Y.Z`);
  }

  const channel = url.searchParams.get("channel") ?? "stable";
  if (channel !== "stable" && channel !== "beta") {
    return badRequest(`invalid channel '${channel}', expected stable|beta`);
  }

  const manifest = await getManifest(env.MILORO_UPDATES, channel);
  const update = resolveUpdate(manifest, currentVersion, platformKey);

  if (!update) {
    // No update → 204 No Content (lo que espera Tauri updater plugin)
    return new Response(null, { status: 204 });
  }

  return json(update, {
    headers: {
      // Cache 5 min para reducir load (cliente Tauri pregunta ~1×/día típicamente)
      "cache-control": "public, max-age=300",
    },
  });
}

/**
 * Endpoint PÚBLICO de signup Free (sin admin token).
 * Body: { email }
 * Idempotente: si el email ya tiene una Free activa, reusa la key (no duplica).
 * Rate-limited a 3/h por IP.
 * NUNCA devuelve la key en el response — sale por email (anti-enumeration).
 */
async function handleSignupFree(req: Request, env: Env): Promise<Response> {
  const ip = clientIp(req);

  if (!(await checkSignupRateLimit(env, ip))) {
    await logEvent(env, "signup_blocked", null, ip, { reason: "rate_limit" });
    return tooMany("too many signup attempts from this IP, retry in 1h");
  }

  const body = await readJson<{ email?: string }>(req);
  if (!body || typeof body.email !== "string") {
    await logEvent(env, "signup", null, ip, { ok: false, reason: "bad_body" });
    return badRequest("invalid body, need {email}");
  }
  const email = body.email.trim().toLowerCase();
  // Email validation simple: contiene @, longitud razonable, sin espacios.
  if (!email.includes("@") || email.length < 5 || email.length > 254 || /\s/.test(email)) {
    await logEvent(env, "signup", null, ip, { ok: false, reason: "bad_email" });
    return badRequest("invalid email format");
  }

  // Idempotencia: ¿ya tiene Free activa?
  let lic = await getActiveFreeLicenseByEmail(env, email);
  let idempotent = false;
  if (lic) {
    idempotent = true;
  } else {
    lic = await createLicense(env, { email, plan: "free" });
  }

  await logEvent(env, "signup", lic.key, ip, {
    plan: "free",
    idempotent,
  });

  // Manda welcome email (incluye la key). Si falla email, log warn pero devolvemos OK
  // — la license existe en DB, Marc puede reenviar manualmente via admin issue.
  const emailRes = await sendEmail(env, welcomeEmail({
    email,
    licenseKey: lic.key,
    plan: "free",
    devicesMax: lic.devices_max,
  }));
  if (!emailRes.ok) {
    // Persistimos el error en D1 para diagnose sin necesidad de wrangler tail
    await logEvent(env, "email_failed", lic.key, ip, {
      target: email,
      provider: emailRes.provider,
      error: emailRes.error ?? "(no detail)",
      flow: "signup_free",
    });
  }

  // Anti-enumeration: NO revelamos `idempotent` al cliente (sale solo en logs internos).
  // Mensaje idéntico para "creada" vs "ya existe" — atacante no puede inferir si un email
  // está registrado. email_sent sí se devuelve porque la app frontend lo necesita para UX.
  return json({
    status: "ok",
    plan: "free",
    email_sent: emailRes.ok,
    message: "Revisa tu email — tu licencia debería llegar en 30-60 segundos. Si no aparece, mira la carpeta de spam.",
  });
}

/**
 * Admin endpoint para emitir licencias manualmente (testing local, free tier, soporte).
 * Requiere bearer token === env.ADMIN_TOKEN.
 * TODO Marc: cuando exista UI admin, retirar este endpoint o limitarlo más.
 */
async function handleIssue(req: Request, env: Env): Promise<Response> {
  const auth = req.headers.get("authorization") || "";
  const m = auth.match(/^Bearer\s+(.+)$/i);
  if (!m || m[1] !== env.ADMIN_TOKEN || !env.ADMIN_TOKEN) {
    return unauthorized("admin token required");
  }
  const body = await readJson<IssueBody>(req);
  if (!body || typeof body.email !== "string" || !body.email.includes("@")) {
    return badRequest("invalid body, need {email, plan?}");
  }
  const plan: Plan = isPlan(body.plan) ? body.plan : "free";
  const lic = await createLicense(env, { email: body.email, plan });
  await logEvent(env, "admin", lic.key, clientIp(req), { action: "issue", plan });
  // Envía welcome email también para licencias admin-issued (Compliance, comps, freebies).
  const emailRes = await sendEmail(env, welcomeEmail({
    email: body.email,
    licenseKey: lic.key,
    plan,
    devicesMax: lic.devices_max,
  }));
  return json({ status: "ok", key: lic.key, plan, devices_max: lic.devices_max, email_sent: emailRes.ok });
}

/**
 * Crea Checkout Session Stripe. Stripe SDK funciona en Workers con httpClient fetch.
 * En tests (sin STRIPE_SECRET_KEY válida) devolvemos 503 con mensaje claro.
 */
async function handleCheckout(req: Request, env: Env): Promise<Response> {
  const body = await readJson<CheckoutBody>(req);
  if (!body || (body.plan !== "standard" && body.plan !== "pro")) {
    return badRequest("invalid body, need {plan: 'standard'|'pro', email?}");
  }
  if (!env.STRIPE_SECRET_KEY || env.STRIPE_SECRET_KEY.startsWith("sk_test_XXX")) {
    return json(
      {
        status: "stub",
        message: "Stripe SDK no configurada — placeholder secret. Marc swap STRIPE_SECRET_KEY.",
        plan: body.plan,
      },
      { status: 503 },
    );
  }

  const priceId =
    body.plan === "standard" ? env.STRIPE_PRICE_STANDARD : env.STRIPE_PRICE_PRO;
  if (!priceId || priceId.includes("placeholder")) {
    return json(
      { status: "stub", message: "Stripe price_id placeholder — Marc swap env var." },
      { status: 503 },
    );
  }
  // Import dinámico — evita cargar SDK en handlers que no la usan (tree-shaking).
  const { default: Stripe } = await import("stripe");
  const stripe = new Stripe(env.STRIPE_SECRET_KEY, {
    httpClient: Stripe.createFetchHttpClient(),
  });
  try {
    const session = await stripe.checkout.sessions.create({
      mode: "subscription",
      line_items: [{ price: priceId, quantity: 1 }],
      customer_email: body.email,
      success_url: `${env.APP_ORIGIN}/checkout/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${env.APP_ORIGIN}/checkout/cancelled`,
      metadata: { plan: body.plan },
    });
    return json({ status: "ok", url: session.url, session_id: session.id });
  } catch (e) {
    console.error("stripe checkout failed", e);
    return serverError("stripe checkout failed");
  }
}

/**
 * Crea sesión del Customer Portal de Stripe — el usuario gestiona suscripción
 * (cambiar tarjeta, descargar facturas, cancelar) sin que tengamos que construir UI propia.
 * Auth: key de licencia (verificamos que existe + tiene stripe_customer_id).
 */
async function handleBillingPortal(req: Request, env: Env): Promise<Response> {
  const body = await readJson<{ key?: string }>(req);
  if (!body || typeof body.key !== "string") {
    return badRequest("invalid body, need {key}");
  }
  if (!env.STRIPE_SECRET_KEY || env.STRIPE_SECRET_KEY.startsWith("sk_test_XXX")) {
    return json(
      { status: "stub", message: "Stripe SDK no configurada — placeholder secret." },
      { status: 503 },
    );
  }
  const lic = await getLicense(env, body.key);
  if (!lic) return notFound("license not found");
  if (!lic.stripe_customer_id) {
    return badRequest("esta licencia no tiene suscripción Stripe asociada (admin-issued, no recurring)");
  }
  const { default: Stripe } = await import("stripe");
  const stripe = new Stripe(env.STRIPE_SECRET_KEY, {
    httpClient: Stripe.createFetchHttpClient(),
  });
  try {
    const session = await stripe.billingPortal.sessions.create({
      customer: lic.stripe_customer_id,
      return_url: `${env.APP_ORIGIN}/dashboard?key=${encodeURIComponent(body.key)}`,
    });
    return json({ status: "ok", url: session.url });
  } catch (e) {
    console.error("billing portal failed", e);
    return serverError("billing portal failed");
  }
}

/**
 * Webhook Stripe — verify HMAC + idempotency + dispatch por type.
 */
async function handleStripeWebhook(req: Request, env: Env): Promise<Response> {
  const sig = req.headers.get("stripe-signature");
  const raw = await req.text();
  if (!env.STRIPE_WEBHOOK_SECRET) {
    return serverError("webhook secret not configured");
  }
  const valid = await verifyStripeSignature(raw, sig, env.STRIPE_WEBHOOK_SECRET);
  if (!valid) {
    await logEvent(env, "webhook", null, clientIp(req), { ok: false, reason: "bad_signature" });
    return badRequest("invalid signature");
  }
  let event: StripeEventBasic;
  try {
    event = JSON.parse(raw) as StripeEventBasic;
  } catch {
    return badRequest("invalid json");
  }
  if (!event.id || !event.type) return badRequest("missing event fields");

  const fresh = await claimWebhookEvent(env, event.id);
  if (!fresh) {
    // Idempotent: ya procesado.
    return json({ status: "ok", duplicate: true });
  }

  try {
    await dispatchStripeEvent(env, event);
    await logEvent(env, "webhook", null, clientIp(req), {
      ok: true,
      type: event.type,
      event_id: event.id,
    });
    return json({ status: "ok", processed: event.type });
  } catch (e) {
    console.error("webhook dispatch failed", { type: event.type, error: String(e) });
    await logEvent(env, "webhook", null, clientIp(req), {
      ok: false,
      type: event.type,
      event_id: event.id,
      error: String(e),
    });
    return serverError("dispatch failed");
  }
}

async function dispatchStripeEvent(env: Env, event: StripeEventBasic): Promise<void> {
  const obj = event.data.object as Record<string, unknown>;
  switch (event.type) {
    case "checkout.session.completed": {
      // Creamos license cuando el checkout completa.
      const customer = (obj.customer as string | null) ?? null;
      const subscription = (obj.subscription as string | null) ?? null;
      const email = (obj.customer_email as string | null) ?? (obj.customer_details as { email?: string } | null)?.email ?? null;
      const metadata = (obj.metadata as { plan?: string } | null) ?? null;
      const plan: Plan = metadata?.plan === "pro" ? "pro" : "standard";
      if (!email) throw new Error("no email in checkout.session.completed");
      // ¿Existe ya un license para esta subscription? (retry safety).
      if (subscription) {
        const existing = await getLicenseBySubscription(env, subscription);
        if (existing) return;
      }
      const newLic = await createLicense(env, {
        email,
        plan,
        stripeCustomerId: customer ?? undefined,
        stripeSubscriptionId: subscription ?? undefined,
      });
      // Email bienvenida con la key. Si falla, log pero no rompemos el webhook.
      const emailRes = await sendEmail(env, welcomeEmail({
        email,
        licenseKey: newLic.key,
        plan,
        devicesMax: newLic.devices_max,
      }));
      if (!emailRes.ok) {
        console.error("[stripe-webhook] welcome email failed", emailRes);
      }
      return;
    }
    case "customer.subscription.updated": {
      const subId = obj.id as string;
      const items = obj.items as { data?: Array<{ price?: { id?: string } }> } | undefined;
      const priceId = items?.data?.[0]?.price?.id;
      const status = obj.status as string;
      const lic = await getLicenseBySubscription(env, subId);
      if (!lic) return; // license todavía no creada o no es nuestra.
      const newPlan = priceIdToPlan(priceId, env);
      const newStatus = status === "active" ? "active" : status === "past_due" ? "past_due" : status === "canceled" ? "cancelled" : lic.status;
      await updateLicenseStatus(env, lic.key, newStatus, {
        plan: newPlan,
        devices_max: newPlan ? PLAN_DEVICE_LIMITS[newPlan] : undefined,
      });
      return;
    }
    case "customer.subscription.deleted": {
      const subId = obj.id as string;
      const lic = await getLicenseBySubscription(env, subId);
      if (!lic) return;
      await updateLicenseStatus(env, lic.key, "cancelled", { cancelled_at: nowS() });
      return;
    }
    case "invoice.payment_succeeded": {
      const subId = obj.subscription as string | null;
      if (!subId) return;
      const lic = await getLicenseBySubscription(env, subId);
      if (!lic) return;
      await updateLicenseStatus(env, lic.key, "active", { last_payment_at: nowS() });
      return;
    }
    case "invoice.payment_failed": {
      const subId = obj.subscription as string | null;
      if (!subId) return;
      const lic = await getLicenseBySubscription(env, subId);
      if (!lic) return;
      await updateLicenseStatus(env, lic.key, "past_due");
      return;
    }
    default:
      // Ignorar tipos no relevantes para nuestro modelo.
      return;
  }
}

// =========================================================================
// Router
// =========================================================================
export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url);
    const path = url.pathname;
    const method = req.method.toUpperCase();
    // CORS preflight para cualquier OPTIONS
    if (method === "OPTIONS") {
      return corsPreflight();
    }
    try {
      if ((path === "/health" || path === "/api/health") && method === "GET") {
        return json({ status: "ok", service: "miloro-license-server", env: env.ENVIRONMENT, ts: nowS() });
      }
      if (path === "/api/license/activate" && method === "POST") return handleActivate(req, env);
      if (path === "/api/license/verify" && method === "POST") return handleVerify(req, env);
      if (path === "/api/license/deactivate" && method === "POST") return handleDeactivate(req, env);
      if (path === "/api/license/dashboard" && method === "GET") return handleDashboard(req, env);
      if (path === "/api/usage/report" && method === "POST") return handleUsageReport(req, env);
      if (path === "/api/license/signup" && method === "POST") return handleSignupFree(req, env);
      if (path === "/api/license/issue" && method === "POST") return handleIssue(req, env);
      if (path.startsWith("/api/updater/") && method === "GET") return handleUpdater(req, env);
      if (path.startsWith("/api/download/") && method === "GET") return handleDownload(req, env);
      if (path === "/api/checkout/session" && method === "POST") return handleCheckout(req, env);
      if (path === "/api/billing/portal" && method === "POST") return handleBillingPortal(req, env);
      if (path === "/api/webhook/stripe" && method === "POST") return handleStripeWebhook(req, env);
      return notFound(`no route for ${method} ${path}`);
    } catch (e) {
      console.error("unhandled error", { path, method, error: String(e) });
      return serverError(`unhandled: ${String(e)}`);
    }
  },
} satisfies ExportedHandler<Env>;
