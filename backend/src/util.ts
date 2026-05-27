/**
 * Pequeñas utilidades compartidas (UUID, JSON responses, escapeXml, time).
 * Patrón escapeXml minado de fuck-loomis (verifactuService.ts).
 */

export function nowS(): number {
  return Math.floor(Date.now() / 1000);
}

export function uuid(): string {
  // crypto.randomUUID disponible en Workers.
  return crypto.randomUUID();
}

/**
 * CORS headers para que la app Tauri (origin `tauri://localhost`,
 * `http://localhost:1420` en dev) pueda hablar con el Worker desde otro origen.
 * En producción podemos restringir a parla.app si conviene; por ahora abierto.
 */
const CORS_HEADERS: Record<string, string> = {
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET, POST, OPTIONS",
  "access-control-allow-headers": "content-type, authorization",
  "access-control-max-age": "86400",
};

export function corsPreflight(): Response {
  return new Response(null, { status: 204, headers: CORS_HEADERS });
}

export function json(
  body: unknown,
  init: ResponseInit = {},
): Response {
  const headers = new Headers(init.headers);
  headers.set("content-type", "application/json; charset=utf-8");
  // Default no-store, pero solo si el caller no especificó cache-control.
  if (!headers.has("cache-control")) {
    headers.set("cache-control", "no-store");
  }
  // CORS aplicado a TODAS las respuestas JSON
  for (const [k, v] of Object.entries(CORS_HEADERS)) {
    headers.set(k, v);
  }
  return new Response(JSON.stringify(body), { ...init, headers });
}

export function badRequest(message: string, extra: Record<string, unknown> = {}): Response {
  return json({ status: "error", error: message, ...extra }, { status: 400 });
}

export function unauthorized(message = "unauthorized"): Response {
  return json({ status: "error", error: message }, { status: 401 });
}

export function forbidden(message: string, extra: Record<string, unknown> = {}): Response {
  return json({ status: "error", error: message, ...extra }, { status: 403 });
}

export function notFound(message = "not found"): Response {
  return json({ status: "error", error: message }, { status: 404 });
}

export function tooMany(message = "rate limited", extra: Record<string, unknown> = {}): Response {
  return json({ status: "error", error: message, ...extra }, { status: 429 });
}

/**
 * Próximo medianoche UTC en segundos epoch. Usado como `reset_at` para quota diaria.
 */
export function nextUtcMidnight(): number {
  const now = new Date();
  const tomorrow = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1, 0, 0, 0, 0));
  return Math.floor(tomorrow.getTime() / 1000);
}

export function serverError(message = "internal error"): Response {
  return json({ status: "error", error: message }, { status: 500 });
}

/**
 * XML escape (minado de fuck-loomis verifactuService).
 * Útil si en futuro generamos facturas. Lo dejo expuesto para reuso.
 */
export function escapeXml(input: string): string {
  return input
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

export function clientIp(req: Request): string {
  return (
    req.headers.get("cf-connecting-ip") ||
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ||
    "unknown"
  );
}

/** Hex encode arbitrary bytes (for HMAC compare). */
export function bytesToHex(bytes: Uint8Array): string {
  let s = "";
  for (let i = 0; i < bytes.length; i++) {
    const v = bytes[i]!;
    s += v.toString(16).padStart(2, "0");
  }
  return s;
}

/** Constant-time compare two hex strings of equal length. */
export function timingSafeEqualHex(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}
