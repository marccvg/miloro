/**
 * License + device repository (D1 queries).
 */
import type { DeviceRow, Env, LicenseRow, Plan } from "./types";
import { PLAN_DEVICE_LIMITS } from "./types";
import { nowS, uuid } from "./util";

export async function getLicense(env: Env, key: string): Promise<LicenseRow | null> {
  const row = await env.DB.prepare(`SELECT * FROM licenses WHERE key = ?`)
    .bind(key)
    .first<LicenseRow>();
  return row ?? null;
}

export async function getLicenseBySubscription(
  env: Env,
  subId: string,
): Promise<LicenseRow | null> {
  const row = await env.DB.prepare(
    `SELECT * FROM licenses WHERE stripe_subscription_id = ?`,
  )
    .bind(subId)
    .first<LicenseRow>();
  return row ?? null;
}

/**
 * Devuelve license Free activa más reciente para un email (idempotencia signup).
 * Returns null si no existe ninguna. status='free' es el indicador de Free tier.
 */
export async function getActiveFreeLicenseByEmail(
  env: Env,
  email: string,
): Promise<LicenseRow | null> {
  const row = await env.DB.prepare(
    `SELECT * FROM licenses
       WHERE email = ? AND plan = 'free' AND status = 'free'
       ORDER BY created_at DESC LIMIT 1`,
  )
    .bind(email)
    .first<LicenseRow>();
  return row ?? null;
}

export async function createLicense(
  env: Env,
  args: {
    email: string;
    plan: Plan;
    stripeCustomerId?: string;
    stripeSubscriptionId?: string;
    expiresAt?: number | null;
    status?: LicenseRow["status"];
  },
): Promise<LicenseRow> {
  const key = uuid();
  const status = args.status ?? (args.plan === "free" ? "free" : "active");
  const now = nowS();
  await env.DB.prepare(
    `INSERT INTO licenses
       (key, email, plan, devices_max, status, stripe_customer_id, stripe_subscription_id,
        created_at, expires_at, last_payment_at, cancelled_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL)`,
  )
    .bind(
      key,
      args.email,
      args.plan,
      PLAN_DEVICE_LIMITS[args.plan],
      status,
      args.stripeCustomerId ?? null,
      args.stripeSubscriptionId ?? null,
      now,
      args.expiresAt ?? null,
      args.plan === "free" ? null : now,
    )
    .run();
  const fresh = await getLicense(env, key);
  if (!fresh) throw new Error("createLicense: insert succeeded but read failed");
  return fresh;
}

export async function updateLicenseStatus(
  env: Env,
  key: string,
  status: LicenseRow["status"],
  extra: Partial<Pick<LicenseRow, "expires_at" | "last_payment_at" | "cancelled_at" | "plan" | "devices_max">> = {},
): Promise<void> {
  // Built dynamically but con prepared params (sin string concat de valores).
  const cols: string[] = ["status = ?"];
  const vals: unknown[] = [status];
  if (extra.expires_at !== undefined) {
    cols.push("expires_at = ?");
    vals.push(extra.expires_at);
  }
  if (extra.last_payment_at !== undefined) {
    cols.push("last_payment_at = ?");
    vals.push(extra.last_payment_at);
  }
  if (extra.cancelled_at !== undefined) {
    cols.push("cancelled_at = ?");
    vals.push(extra.cancelled_at);
  }
  if (extra.plan !== undefined) {
    cols.push("plan = ?");
    vals.push(extra.plan);
  }
  if (extra.devices_max !== undefined) {
    cols.push("devices_max = ?");
    vals.push(extra.devices_max);
  }
  vals.push(key);
  await env.DB.prepare(`UPDATE licenses SET ${cols.join(", ")} WHERE key = ?`)
    .bind(...vals)
    .run();
}

export async function listActiveDevices(env: Env, licenseKey: string): Promise<DeviceRow[]> {
  const rs = await env.DB.prepare(
    `SELECT * FROM devices WHERE license_key = ? AND deactivated_at IS NULL ORDER BY activated_at ASC`,
  )
    .bind(licenseKey)
    .all<DeviceRow>();
  return rs.results ?? [];
}

export async function getDevice(
  env: Env,
  licenseKey: string,
  fingerprint: string,
): Promise<DeviceRow | null> {
  const row = await env.DB.prepare(
    `SELECT * FROM devices WHERE license_key = ? AND fingerprint = ?`,
  )
    .bind(licenseKey, fingerprint)
    .first<DeviceRow>();
  return row ?? null;
}

export async function reactivateDevice(env: Env, deviceId: string): Promise<void> {
  const now = nowS();
  await env.DB.prepare(
    `UPDATE devices SET deactivated_at = NULL, last_seen = ?, activated_at = ? WHERE id = ?`,
  )
    .bind(now, now, deviceId)
    .run();
}

export async function insertDevice(
  env: Env,
  args: {
    licenseKey: string;
    fingerprint: string;
    hostname?: string | null;
    os?: string | null;
  },
): Promise<DeviceRow> {
  const id = uuid();
  const now = nowS();
  await env.DB.prepare(
    `INSERT INTO devices (id, license_key, fingerprint, hostname, os, activated_at, last_seen, deactivated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, NULL)`,
  )
    .bind(id, args.licenseKey, args.fingerprint, args.hostname ?? null, args.os ?? null, now, now)
    .run();
  const fresh = await getDevice(env, args.licenseKey, args.fingerprint);
  if (!fresh) throw new Error("insertDevice: insert succeeded but read failed");
  return fresh;
}

export async function touchDeviceLastSeen(env: Env, deviceId: string): Promise<void> {
  await env.DB.prepare(`UPDATE devices SET last_seen = ? WHERE id = ?`)
    .bind(nowS(), deviceId)
    .run();
}

export async function deactivateDevice(env: Env, deviceId: string): Promise<void> {
  await env.DB.prepare(`UPDATE devices SET deactivated_at = ? WHERE id = ?`)
    .bind(nowS(), deviceId)
    .run();
}

// ============================================================================
// Usage quota (Free 30 min/día) — tabla `usage`
// ============================================================================

/** Devuelve la fecha actual en formato 'YYYY-MM-DD' UTC. */
function todayUtc(): string {
  return new Date().toISOString().slice(0, 10);
}

/** Devuelve segundos usados HOY (UTC) por una licencia. 0 si no hay registro. */
export async function getUsageToday(env: Env, licenseKey: string): Promise<number> {
  const row = await env.DB.prepare(
    `SELECT seconds_used FROM usage WHERE license_key = ? AND date = ?`,
  )
    .bind(licenseKey, todayUtc())
    .first<{ seconds_used: number }>();
  return row?.seconds_used ?? 0;
}

/** Incrementa segundos usados hoy. Upsert atómico — crea row si no existe. */
export async function incrementUsage(
  env: Env,
  licenseKey: string,
  seconds: number,
): Promise<number> {
  const date = todayUtc();
  const safeSeconds = Math.max(0, Math.min(seconds, 7200)); // sanity cap: 2h por reporte
  await env.DB.prepare(
    `INSERT INTO usage (license_key, date, seconds_used) VALUES (?, ?, ?)
     ON CONFLICT (license_key, date) DO UPDATE SET seconds_used = seconds_used + excluded.seconds_used`,
  )
    .bind(licenseKey, date, safeSeconds)
    .run();
  return getUsageToday(env, licenseKey);
}
