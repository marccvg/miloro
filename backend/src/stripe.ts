/**
 * Stripe helpers: HMAC SHA256 webhook verify + plan mapping + idempotency.
 *
 * Workers no soporta Node `crypto.createHmac`, así que implementamos verify
 * con SubtleCrypto (constant-time compare via timingSafeEqualHex).
 *
 * Decisión 2026-05-19: NO usar la lib stripe SDK para `constructEvent` porque su
 * dependencia de Node crypto no funciona en Workers V8. Implementamos verify a mano
 * (es solo HMAC + comparación de timestamp).
 *
 * Para crear Checkout Sessions sí usamos la SDK (`stripe` instalada) en runtime Worker
 * configurando `httpClient: Stripe.createFetchHttpClient()`.
 */
import type { Env, Plan } from "./types";
import { bytesToHex, nowS, timingSafeEqualHex } from "./util";

const ENC = new TextEncoder();

export interface StripeEventBasic {
  id: string;
  type: string;
  data: { object: Record<string, unknown> };
  livemode?: boolean;
}

/**
 * Verifica firma Stripe webhook (algoritmo oficial — `t=<ts>,v1=<hmac>`).
 * tolerance: 5 minutos para evitar replay tardío.
 */
export async function verifyStripeSignature(
  body: string,
  signatureHeader: string | null,
  secret: string,
  toleranceS = 300,
): Promise<boolean> {
  if (!signatureHeader || !secret) return false;
  const parts = signatureHeader.split(",").map((s) => s.trim());
  let timestamp: string | null = null;
  const v1Signatures: string[] = [];
  for (const p of parts) {
    const idx = p.indexOf("=");
    if (idx < 0) continue;
    const k = p.slice(0, idx);
    const v = p.slice(idx + 1);
    if (k === "t") timestamp = v;
    else if (k === "v1") v1Signatures.push(v);
  }
  if (!timestamp || v1Signatures.length === 0) return false;
  const tsNum = Number(timestamp);
  if (!Number.isFinite(tsNum)) return false;
  if (Math.abs(nowS() - tsNum) > toleranceS) return false;

  const signedPayload = `${timestamp}.${body}`;
  const key = await crypto.subtle.importKey(
    "raw",
    ENC.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, ENC.encode(signedPayload));
  const expected = bytesToHex(new Uint8Array(sig));
  for (const candidate of v1Signatures) {
    if (timingSafeEqualHex(expected, candidate)) return true;
  }
  return false;
}

/**
 * Helper para tests: genera header `t=<ts>,v1=<hmac>` con un secret + body.
 */
export async function signStripePayloadForTest(
  body: string,
  secret: string,
  timestamp = nowS(),
): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    ENC.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, ENC.encode(`${timestamp}.${body}`));
  return `t=${timestamp},v1=${bytesToHex(new Uint8Array(sig))}`;
}

/**
 * Mapea price_id Stripe → plan. Si no matchea, undefined.
 */
export function priceIdToPlan(priceId: string | undefined, env: Env): Plan | undefined {
  if (!priceId) return undefined;
  if (priceId === env.STRIPE_PRICE_STANDARD) return "standard";
  if (priceId === env.STRIPE_PRICE_PRO) return "pro";
  return undefined;
}

/**
 * Idempotency check vía stripe_webhooks_seen table.
 * Devuelve `true` si es la primera vez que vemos el event_id (e insertamos),
 * `false` si ya estaba (no procesar de nuevo).
 */
export async function claimWebhookEvent(env: Env, eventId: string): Promise<boolean> {
  try {
    await env.DB.prepare(
      `INSERT INTO stripe_webhooks_seen (event_id, received_at) VALUES (?, ?)`,
    )
      .bind(eventId, nowS())
      .run();
    return true;
  } catch {
    // UNIQUE constraint violation → ya procesado.
    return false;
  }
}
