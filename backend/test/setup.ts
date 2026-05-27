/**
 * Shared test helpers — schema setup, fingerprint generator, env getter.
 *
 * Nota: no podemos leer migrations/0001_init.sql con node:fs (pool corre en V8 Workers).
 * En su lugar usamos `INIT_SCHEMA_STATEMENTS` inline (src/schema.ts) que es duplicado
 * del .sql. Si modificas el .sql, actualiza también schema.ts.
 */
import { env } from "cloudflare:test";
import { INIT_SCHEMA_STATEMENTS } from "../src/schema";
import type { Env } from "../src/types";

export async function applySchema(): Promise<void> {
  const e = env as unknown as Env;
  for (const stmt of INIT_SCHEMA_STATEMENTS) {
    await e.DB.prepare(stmt).run();
  }
}

export async function resetDb(): Promise<void> {
  const e = env as unknown as Env;
  for (const t of ["usage", "events", "stripe_webhooks_seen", "devices", "licenses"]) {
    try {
      await e.DB.prepare(`DROP TABLE IF EXISTS ${t}`).run();
    } catch {
      /* ignore */
    }
  }
  await applySchema();
}

export function testEnv(): Env {
  return env as unknown as Env;
}

/** Stable fingerprint hex 64 chars derivado del seed (para tests reproducibles). */
export function fp(seed: string): string {
  let h = 0n;
  const PRIME = 1099511628211n;
  for (let i = 0; i < seed.length; i++) {
    h = (h ^ BigInt(seed.charCodeAt(i))) * PRIME;
    h &= (1n << 64n) - 1n;
  }
  let hex = h.toString(16).padStart(16, "0");
  while (hex.length < 64) hex += hex;
  return hex.slice(0, 64);
}
