/**
 * Audit log helper — inserts into events table.
 * Patrón inspirado en fuck-loomis verifactu submissions table.
 */
import type { Env } from "./types";
import { nowS, uuid } from "./util";

export async function logEvent(
  env: Env,
  type: string,
  licenseKey: string | null,
  ip: string | null,
  payload: Record<string, unknown> = {},
): Promise<void> {
  try {
    await env.DB.prepare(
      `INSERT INTO events (id, license_key, type, payload_json, ip, ts) VALUES (?, ?, ?, ?, ?, ?)`,
    )
      .bind(uuid(), licenseKey, type, JSON.stringify(payload), ip, nowS())
      .run();
  } catch (e) {
    // No bloquear el response por fallo en audit. Pero loggear a stderr.
    console.error("audit log failed", { type, licenseKey, error: String(e) });
  }
}
