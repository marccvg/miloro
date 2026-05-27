/**
 * Rate limit basado en events table (sin necesidad de KV/DO en MVP).
 * Para producción real: migrar a Cloudflare Rate Limiting o DO (idea futura).
 */
import type { Env } from "./types";
import { nowS } from "./util";

export async function checkActivateRateLimit(env: Env, ip: string): Promise<boolean> {
  const limit = Number(env.ACTIVATE_RATE_LIMIT_PER_HOUR || "5");
  const sinceTs = nowS() - 3600;
  const row = await env.DB.prepare(
    `SELECT COUNT(*) AS c FROM events WHERE ip = ? AND type IN ('activate', 'rate_limit') AND ts >= ?`,
  )
    .bind(ip, sinceTs)
    .first<{ c: number }>();
  const count = row?.c ?? 0;
  return count < limit;
}

/**
 * Rate limit signup público: máx 3 por IP/hora.
 * Cuenta tanto signups exitosos como bloqueos previos.
 */
export async function checkSignupRateLimit(env: Env, ip: string): Promise<boolean> {
  const limit = 3;
  const sinceTs = nowS() - 3600;
  const row = await env.DB.prepare(
    `SELECT COUNT(*) AS c FROM events WHERE ip = ? AND type IN ('signup', 'signup_blocked') AND ts >= ?`,
  )
    .bind(ip, sinceTs)
    .first<{ c: number }>();
  const count = row?.c ?? 0;
  return count < limit;
}
