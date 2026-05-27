/**
 * Suite vitest para license server. Cubre activate / verify / deactivate /
 * dashboard / webhook (signature + idempotency) / rate limit / expired.
 *
 * Pool: @cloudflare/vitest-pool-workers (corre el handler en Miniflare con DB real D1 in-memory).
 */
import { SELF } from "cloudflare:test";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import worker from "../src/index";
import { createLicense, getLicense } from "../src/licenses";
import { signStripePayloadForTest } from "../src/stripe";
import type { Env } from "../src/types";
import { applySchema, fp, resetDb, testEnv } from "./setup";

const env: Env = testEnv();

beforeEach(async () => {
  await resetDb();
});

afterEach(async () => {
  // Limpieza defensiva (no estrictamente necesaria por beforeEach pero hace tests independientes).
});

// =====================================================================
// 1. Activate happy path — license valid + slot free
// =====================================================================
describe("activate", () => {
  it("creates device when license valid and slot free", async () => {
    const lic = await createLicense(env, { email: "test1@example.com", plan: "free" });
    const res = await SELF.fetch("http://x/api/license/activate", {
      method: "POST",
      body: JSON.stringify({ key: lic.key, fingerprint: fp("dev1"), hostname: "lap1", os: "linux" }),
    });
    expect(res.status).toBe(200);
    const body = (await res.json()) as { status: string; device_id: string };
    expect(body.status).toBe("ok");
    expect(body.device_id).toMatch(/^[0-9a-f-]+$/);
  });

  // =====================================================================
  // 2. Activate slot full — pro plan = 3 devices (decisión 2026-05-24),
  //    3 devices already used → 4º rechazado
  // =====================================================================
  it("rejects when slot full and lists existing devices", async () => {
    const lic = await createLicense(env, { email: "full@example.com", plan: "pro" });
    // Fill the 3 slots (Pro = 3 devices per PLAN_DEVICE_LIMITS).
    for (const i of [0, 1, 2]) {
      const r = await SELF.fetch("http://x/api/license/activate", {
        method: "POST",
        body: JSON.stringify({ key: lic.key, fingerprint: fp(`d${i}`), hostname: `h${i}`, os: "linux" }),
      });
      expect(r.status).toBe(200);
    }
    // 4º dispositivo debe ser rechazado.
    const res = await SELF.fetch("http://x/api/license/activate", {
      method: "POST",
      body: JSON.stringify({ key: lic.key, fingerprint: fp("d99"), hostname: "h99", os: "linux" }),
    });
    expect(res.status).toBe(403);
    const body = (await res.json()) as {
      status: string;
      error: string;
      devices_used: number;
      devices_max: number;
      devices: Array<{ hostname: string }>;
    };
    expect(body.error).toContain("slot full");
    expect(body.devices_used).toBe(3);
    expect(body.devices_max).toBe(3);
    expect(body.devices.length).toBe(3);
  });

  // =====================================================================
  // 3. Activate expired license → 403
  // =====================================================================
  it("rejects expired license", async () => {
    const lic = await createLicense(env, { email: "exp@example.com", plan: "standard" });
    // Forzar expiración pasada vía SQL directo.
    await env.DB.prepare(`UPDATE licenses SET expires_at = ? WHERE key = ?`)
      .bind(1000, lic.key)
      .run();
    const res = await SELF.fetch("http://x/api/license/activate", {
      method: "POST",
      body: JSON.stringify({ key: lic.key, fingerprint: fp("d1") }),
    });
    expect(res.status).toBe(403);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe("license expired");
  });

  // =====================================================================
  // 4. Activate idempotency — same fingerprint twice ok
  // =====================================================================
  it("is idempotent for same fingerprint", async () => {
    const lic = await createLicense(env, { email: "idem@example.com", plan: "standard" });
    const fpA = fp("same");
    const r1 = await SELF.fetch("http://x/api/license/activate", {
      method: "POST",
      body: JSON.stringify({ key: lic.key, fingerprint: fpA }),
    });
    const r2 = await SELF.fetch("http://x/api/license/activate", {
      method: "POST",
      body: JSON.stringify({ key: lic.key, fingerprint: fpA }),
    });
    expect(r1.status).toBe(200);
    expect(r2.status).toBe(200);
    const b1 = (await r1.json()) as { device_id: string };
    const b2 = (await r2.json()) as { device_id: string; idempotent?: boolean };
    expect(b2.device_id).toBe(b1.device_id);
    expect(b2.idempotent).toBe(true);
  });
});

// =====================================================================
// 5. Verify happy path + cache header
// =====================================================================
describe("verify", () => {
  it("returns plan + devices_used and sets cache header", async () => {
    const lic = await createLicense(env, { email: "v@example.com", plan: "pro" });
    const f = fp("vdev");
    await SELF.fetch("http://x/api/license/activate", {
      method: "POST",
      body: JSON.stringify({ key: lic.key, fingerprint: f }),
    });
    const t0 = Date.now();
    const res = await SELF.fetch("http://x/api/license/verify", {
      method: "POST",
      body: JSON.stringify({ key: lic.key, fingerprint: f }),
    });
    const elapsed = Date.now() - t0;
    expect(res.status).toBe(200);
    const body = (await res.json()) as { status: string; plan: string; devices_used: number; devices_max: number };
    expect(body.plan).toBe("pro");
    expect(body.devices_used).toBe(1);
    expect(body.devices_max).toBe(3); // pro = 3 devices (decisión 2026-05-24)
    // Latency reasonable (in-memory miniflare ~ms range — 500ms ceiling generoso para CI).
    expect(elapsed).toBeLessThan(500);
    expect(res.headers.get("cache-control")).toMatch(/max-age=\d+/);
  });

  it("rejects when device not activated", async () => {
    const lic = await createLicense(env, { email: "no@example.com", plan: "free" });
    const res = await SELF.fetch("http://x/api/license/verify", {
      method: "POST",
      body: JSON.stringify({ key: lic.key, fingerprint: fp("never") }),
    });
    expect(res.status).toBe(403);
  });
});

// =====================================================================
// 6. Deactivate frees slot
// =====================================================================
describe("deactivate", () => {
  it("frees slot so new device can activate", async () => {
    const lic = await createLicense(env, { email: "d@example.com", plan: "free" }); // max=1
    const fA = fp("A");
    const fB = fp("B");
    const a1 = await SELF.fetch("http://x/api/license/activate", {
      method: "POST",
      body: JSON.stringify({ key: lic.key, fingerprint: fA }),
    });
    expect(a1.status).toBe(200);
    const fullAttempt = await SELF.fetch("http://x/api/license/activate", {
      method: "POST",
      body: JSON.stringify({ key: lic.key, fingerprint: fB }),
    });
    expect(fullAttempt.status).toBe(403);
    const deact = await SELF.fetch("http://x/api/license/deactivate", {
      method: "POST",
      body: JSON.stringify({ key: lic.key, fingerprint: fA }),
    });
    expect(deact.status).toBe(200);
    const a2 = await SELF.fetch("http://x/api/license/activate", {
      method: "POST",
      body: JSON.stringify({ key: lic.key, fingerprint: fB }),
    });
    expect(a2.status).toBe(200);
  });
});

// =====================================================================
// 7. Stripe webhook signature inválida → 400
// =====================================================================
describe("stripe webhook signature", () => {
  it("rejects with invalid signature", async () => {
    const payload = JSON.stringify({ id: "evt_test_bad", type: "checkout.session.completed", data: { object: {} } });
    const res = await SELF.fetch("http://x/api/webhook/stripe", {
      method: "POST",
      headers: { "stripe-signature": "t=999,v1=deadbeef" },
      body: payload,
    });
    expect(res.status).toBe(400);
  });

  // =====================================================================
  // 8. Webhook signature válida → license created + idempotency
  // =====================================================================
  it("processes checkout.session.completed and is idempotent", async () => {
    const payload = JSON.stringify({
      id: "evt_test_good_1",
      type: "checkout.session.completed",
      data: {
        object: {
          customer: "cus_test_1",
          subscription: "sub_test_1",
          customer_email: "buyer@example.com",
          metadata: { plan: "standard" },
        },
      },
    });
    const sig = await signStripePayloadForTest(payload, env.STRIPE_WEBHOOK_SECRET);
    const res1 = await SELF.fetch("http://x/api/webhook/stripe", {
      method: "POST",
      headers: { "stripe-signature": sig },
      body: payload,
    });
    expect(res1.status).toBe(200);
    const b1 = (await res1.json()) as { status: string; processed?: string };
    expect(b1.processed).toBe("checkout.session.completed");

    // Verifica que la license existe.
    const lookup = await env.DB.prepare(
      `SELECT * FROM licenses WHERE stripe_subscription_id = ?`,
    )
      .bind("sub_test_1")
      .first<{ email: string; plan: string; devices_max: number }>();
    expect(lookup?.email).toBe("buyer@example.com");
    expect(lookup?.plan).toBe("standard");
    expect(lookup?.devices_max).toBe(3); // standard legacy = 3 devices (decisión 2026-05-24)

    // Replay del mismo event_id — idempotent.
    const res2 = await SELF.fetch("http://x/api/webhook/stripe", {
      method: "POST",
      headers: { "stripe-signature": sig },
      body: payload,
    });
    expect(res2.status).toBe(200);
    const b2 = (await res2.json()) as { status: string; duplicate?: boolean };
    expect(b2.duplicate).toBe(true);

    // Solo hay 1 license, no 2.
    const count = await env.DB.prepare(
      `SELECT COUNT(*) AS c FROM licenses WHERE stripe_subscription_id = ?`,
    )
      .bind("sub_test_1")
      .first<{ c: number }>();
    expect(count?.c).toBe(1);
  });

  it("subscription.deleted marks license as cancelled", async () => {
    // Set up: crear license con sub id.
    const lic = await createLicense(env, {
      email: "cancel@example.com",
      plan: "pro",
      stripeSubscriptionId: "sub_cancel_me",
    });
    const payload = JSON.stringify({
      id: "evt_cancel_1",
      type: "customer.subscription.deleted",
      data: { object: { id: "sub_cancel_me" } },
    });
    const sig = await signStripePayloadForTest(payload, env.STRIPE_WEBHOOK_SECRET);
    const res = await SELF.fetch("http://x/api/webhook/stripe", {
      method: "POST",
      headers: { "stripe-signature": sig },
      body: payload,
    });
    expect(res.status).toBe(200);
    const fresh = await getLicense(env, lic.key);
    expect(fresh?.status).toBe("cancelled");
    expect(fresh?.cancelled_at).toBeGreaterThan(0);
  });

  it("invoice.payment_failed marks license as past_due", async () => {
    const lic = await createLicense(env, {
      email: "pd@example.com",
      plan: "standard",
      stripeSubscriptionId: "sub_payfail",
    });
    const payload = JSON.stringify({
      id: "evt_payfail_1",
      type: "invoice.payment_failed",
      data: { object: { subscription: "sub_payfail" } },
    });
    const sig = await signStripePayloadForTest(payload, env.STRIPE_WEBHOOK_SECRET);
    const res = await SELF.fetch("http://x/api/webhook/stripe", {
      method: "POST",
      headers: { "stripe-signature": sig },
      body: payload,
    });
    expect(res.status).toBe(200);
    const fresh = await getLicense(env, lic.key);
    expect(fresh?.status).toBe("past_due");
  });
});

// =====================================================================
// 9. Rate limit: 6th attempt en 1h debe ser bloqueada
// =====================================================================
describe("rate limit", () => {
  it("blocks 6th activate in 1h from same IP", async () => {
    // Crear 6 licenses para no chocar con slot full (cada activate usa una distinta).
    const keys: string[] = [];
    for (let i = 0; i < 6; i++) {
      const lic = await createLicense(env, { email: `rl${i}@x.com`, plan: "free" });
      keys.push(lic.key);
    }
    let lastStatus = 0;
    for (let i = 0; i < 6; i++) {
      const r = await SELF.fetch("http://x/api/license/activate", {
        method: "POST",
        headers: { "cf-connecting-ip": "1.2.3.4" },
        body: JSON.stringify({ key: keys[i], fingerprint: fp(`rl${i}`) }),
      });
      lastStatus = r.status;
    }
    expect(lastStatus).toBe(429);
  });
});

// =====================================================================
// 10. Health endpoint
// =====================================================================
describe("health", () => {
  it("returns ok", async () => {
    const res = await SELF.fetch("http://x/health");
    expect(res.status).toBe(200);
    const body = (await res.json()) as { status: string; service: string };
    expect(body.status).toBe("ok");
    expect(body.service).toBe("miloro-license-server"); // rebrand 2026-05-24
  });
});

// =====================================================================
// 11. Admin issue endpoint
// =====================================================================
describe("admin issue", () => {
  it("rejects without bearer token", async () => {
    const res = await SELF.fetch("http://x/api/license/issue", {
      method: "POST",
      body: JSON.stringify({ email: "x@x.com", plan: "free" }),
    });
    expect(res.status).toBe(401);
  });

  it("issues free license with valid token", async () => {
    const res = await SELF.fetch("http://x/api/license/issue", {
      method: "POST",
      headers: { authorization: "Bearer test-admin-token" },
      body: JSON.stringify({ email: "issued@x.com", plan: "free" }),
    });
    expect(res.status).toBe(200);
    const body = (await res.json()) as { status: string; key: string; devices_max: number };
    expect(body.status).toBe("ok");
    expect(body.devices_max).toBe(1);
  });
});

// =====================================================================
// 11.5. Public Free signup (NO admin token)
// =====================================================================
describe("public signup", () => {
  it("creates a free license without admin token + does NOT leak key or idempotent flag", async () => {
    const res = await SELF.fetch("http://x/api/license/signup", {
      method: "POST",
      body: JSON.stringify({ email: "newuser@x.com" }),
    });
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      status: string;
      plan: string;
      email_sent: boolean;
      message: string;
      idempotent?: unknown;
      key?: unknown;
    };
    expect(body.status).toBe("ok");
    expect(body.plan).toBe("free");
    expect(body.key).toBeUndefined();         // anti-enumeration: key solo por email
    expect(body.idempotent).toBeUndefined();  // anti-enumeration: no revelar si email ya existía

    // Verifica que la license existe en DB
    const dbRow = await env.DB.prepare(
      `SELECT plan, status, devices_max FROM licenses WHERE email = ?`,
    )
      .bind("newuser@x.com")
      .first<{ plan: string; status: string; devices_max: number }>();
    expect(dbRow?.plan).toBe("free");
    expect(dbRow?.status).toBe("free");
    expect(dbRow?.devices_max).toBe(1);
  });

  it("is idempotent server-side — same email twice creates only 1 row + logs flag", async () => {
    await SELF.fetch("http://x/api/license/signup", {
      method: "POST",
      body: JSON.stringify({ email: "dup@x.com" }),
    });
    const res2 = await SELF.fetch("http://x/api/license/signup", {
      method: "POST",
      body: JSON.stringify({ email: "dup@x.com" }),
    });
    expect(res2.status).toBe(200);

    // Response idéntico al primer signup (no revela idempotencia)
    const body = (await res2.json()) as { idempotent?: unknown };
    expect(body.idempotent).toBeUndefined();

    // Solo 1 row en DB → confirma idempotencia server-side
    const count = await env.DB.prepare(`SELECT COUNT(*) AS c FROM licenses WHERE email = ?`)
      .bind("dup@x.com")
      .first<{ c: number }>();
    expect(count?.c).toBe(1);

    // Pero EN EL LOG de eventos sí queda registrado idempotent=true (para Marc analytics)
    const event = await env.DB.prepare(
      `SELECT payload_json FROM events WHERE type = 'signup' ORDER BY ts DESC LIMIT 1`,
    ).first<{ payload_json: string }>();
    const payload = JSON.parse(event?.payload_json ?? "{}");
    expect(payload.idempotent).toBe(true);
  });

  it("rejects bad email format", async () => {
    const res = await SELF.fetch("http://x/api/license/signup", {
      method: "POST",
      body: JSON.stringify({ email: "noarroba" }),
    });
    expect(res.status).toBe(400);
  });

  it("rate-limits after 3 signups from same IP/hour", async () => {
    for (let i = 0; i < 3; i++) {
      const r = await SELF.fetch("http://x/api/license/signup", {
        method: "POST",
        headers: { "cf-connecting-ip": "9.9.9.9" },
        body: JSON.stringify({ email: `rl${i}@x.com` }),
      });
      expect(r.status).toBe(200);
    }
    // 4ª debe ser bloqueada
    const blocked = await SELF.fetch("http://x/api/license/signup", {
      method: "POST",
      headers: { "cf-connecting-ip": "9.9.9.9" },
      body: JSON.stringify({ email: "rl3@x.com" }),
    });
    expect(blocked.status).toBe(429);
  });
});

// =====================================================================
// 11.6. Updater Tauri endpoint
// =====================================================================
describe("updater", () => {
  it("returns 204 when no KV manifest exists (graceful degrade)", async () => {
    // Test env no tiene MILORO_UPDATES bindeado → getManifest devuelve null → 204
    const res = await SELF.fetch("http://x/api/updater/linux-x86_64/0.0.4");
    expect(res.status).toBe(204);
  });

  it("rejects invalid platform with 400", async () => {
    const res = await SELF.fetch("http://x/api/updater/freebsd-mips/0.0.4");
    expect(res.status).toBe(400);
  });

  it("rejects invalid version format with 400", async () => {
    const res = await SELF.fetch("http://x/api/updater/linux-x86_64/notaversion");
    expect(res.status).toBe(400);
  });

  it("rejects invalid channel with 400", async () => {
    const res = await SELF.fetch("http://x/api/updater/linux-x86_64/0.0.4?channel=hacking");
    expect(res.status).toBe(400);
  });
});

// =====================================================================
// 12. Dashboard endpoint
// =====================================================================
describe("dashboard", () => {
  it("returns license summary + devices", async () => {
    const lic = await createLicense(env, { email: "dash@x.com", plan: "pro" });
    await SELF.fetch("http://x/api/license/activate", {
      method: "POST",
      body: JSON.stringify({ key: lic.key, fingerprint: fp("dash1"), hostname: "lap-marc", os: "linux" }),
    });
    const res = await SELF.fetch(`http://x/api/license/dashboard?key=${lic.key}`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      status: string;
      license: { plan: string; devices_max: number };
      devices_used: number;
      devices: Array<{ hostname: string }>;
    };
    expect(body.license.plan).toBe("pro");
    expect(body.license.devices_max).toBe(3); // pro = 3 devices (decisión 2026-05-24)
    expect(body.devices_used).toBe(1);
    expect(body.devices[0]?.hostname).toBe("lap-marc");
  });
});

// =====================================================================
// Sanity: worker default export is a Module Worker
// =====================================================================
describe("module worker shape", () => {
  it("exports fetch handler", () => {
    expect(typeof worker.fetch).toBe("function");
  });
});
