/**
 * Email transactional via Resend (preferido si RESEND_API_KEY) o MailChannels (fallback gratis en Workers).
 *
 * Resend: 3k emails/mes gratis, API key requerido. Mejor deliverability.
 * MailChannels: gratis ilimitado para Cloudflare Workers (sin API key, requiere SPF DNS).
 *
 * Si ambos fallan, devolvemos { ok: false } pero NO lanzamos — email no debe romper webhook Stripe
 * (la licencia ya se creó, Marc puede reenviar key manualmente desde admin si falla email).
 */

export interface SendEmailArgs {
  to: string;
  subject: string;
  text: string;
  html?: string;
}

export interface SendResult {
  ok: boolean;
  provider: "resend" | "mailchannels" | "none";
  error?: string;
}

interface EmailEnv {
  RESEND_API_KEY?: string;
  EMAIL_FROM?: string;
}

const DEFAULT_FROM = "MiLoro <hola@miloro.app>";

export async function sendEmail(env: EmailEnv, args: SendEmailArgs): Promise<SendResult> {
  const from = env.EMAIL_FROM || DEFAULT_FROM;

  if (env.RESEND_API_KEY) {
    try {
      const r = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${env.RESEND_API_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          from,
          to: [args.to],
          subject: args.subject,
          text: args.text,
          html: args.html,
        }),
      });
      if (r.ok) return { ok: true, provider: "resend" };
      const detail = await r.text().catch(() => "");
      console.error("[email] resend failed", r.status, detail.slice(0, 200));
      return { ok: false, provider: "resend", error: `resend ${r.status}: ${detail.slice(0, 140)}` };
    } catch (e) {
      console.error("[email] resend exception", e);
      // Cae a MailChannels como fallback
    }
  }

  // MailChannels: gratis en Workers, no API key. Requiere SPF DNS configurado.
  try {
    const r = await fetch("https://api.mailchannels.net/tx/v1/send", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        personalizations: [{ to: [{ email: args.to }] }],
        from: parseFrom(from),
        subject: args.subject,
        content: [
          { type: "text/plain", value: args.text },
          ...(args.html ? [{ type: "text/html", value: args.html }] : []),
        ],
      }),
    });
    if (r.ok) return { ok: true, provider: "mailchannels" };
    const detail = await r.text().catch(() => "");
    console.error("[email] mailchannels failed", r.status, detail.slice(0, 200));
    return { ok: false, provider: "mailchannels", error: `mailchannels ${r.status}: ${detail.slice(0, 140)}` };
  } catch (e) {
    console.error("[email] mailchannels exception", e);
    return { ok: false, provider: "none", error: String(e) };
  }
}

function parseFrom(from: string): { email: string; name?: string } {
  // Acepta "Name <email@x>" o "email@x"
  const m = from.match(/^(.+)<(.+)>$/);
  if (m && m[1] && m[2]) {
    return { name: m[1].trim().replace(/^"|"$/g, ""), email: m[2].trim() };
  }
  return { email: from.trim() };
}

// =========================================================================
// Plantillas de email
// =========================================================================

export function welcomeEmail(args: {
  email: string;
  licenseKey: string;
  plan: "free" | "standard" | "pro";
  devicesMax: number;
}): SendEmailArgs {
  const planLabel = args.plan === "pro" ? "Pro" : args.plan === "standard" ? "Standard" : "Free";
  const features = args.plan === "pro"
    ? "audio ilimitado · todos los modelos · efecto máquina de escribir · soporte prioritario"
    : args.plan === "standard"
    ? "1 dispositivo · modelo medium · soporte estándar"
    : "1 dispositivo · modelo small · 30 min/día";

  const text = `¡Bienvenido a MiLoro ${planLabel}!

Tu clave de licencia:

${args.licenseKey}

Tu plan incluye:
${features}

CÓMO ACTIVAR:
1. Abre MiLoro en tu equipo (si no la tienes: https://miloro.app)
2. Click en "Tengo licencia" en la cabecera
3. Pega la clave de arriba y click "Verificar"
4. Listo — tu plan ${planLabel} está activo.

Tu dashboard online (ver dispositivos, gestionar suscripción):
https://miloro.app/dashboard?key=${args.licenseKey}

Soporte: soporte@miloro.app

Gracias por confiar en MiLoro.
— Marc`;

  const html = `<!doctype html>
<html><body style="font-family:-apple-system,BlinkMacSystemFont,sans-serif;max-width:560px;margin:2rem auto;padding:1.5rem;color:#1F2937;line-height:1.55">
<div style="text-align:center;margin-bottom:2rem">
  <h1 style="color:#16A34A;margin:0">🦜 MiLoro</h1>
  <p style="color:#78350F">¡Bienvenido al plan ${planLabel}!</p>
</div>

<p>Tu clave de licencia:</p>
<div style="background:#FFFBEB;border:2px solid #FCD34D;border-radius:8px;padding:1rem;text-align:center;font-family:ui-monospace,SF Mono,Menlo,monospace;font-size:1.1rem;letter-spacing:0.02em">
  <strong>${args.licenseKey}</strong>
</div>

<h3 style="margin-top:1.5rem">Tu plan incluye</h3>
<p>${features}</p>

<h3>Cómo activar (30 segundos)</h3>
<ol>
  <li>Abre MiLoro en tu equipo. ¿Aún no la tienes? <a href="https://miloro.app" style="color:#16A34A">Descárgala aquí</a>.</li>
  <li>En la cabecera, click <strong>"Tengo licencia"</strong>.</li>
  <li>Pega tu clave y click <strong>Verificar</strong>.</li>
  <li>Listo — tu plan ${planLabel} está activo.</li>
</ol>

<p style="margin-top:1.5rem">
  <a href="https://miloro.app/dashboard?key=${args.licenseKey}" style="display:inline-block;background:#16A34A;color:white;padding:0.7rem 1.2rem;border-radius:8px;text-decoration:none;font-weight:600">
    Abrir mi dashboard
  </a>
</p>

<p style="font-size:0.85rem;color:#78350F;border-top:1px solid #FCD34D;padding-top:1rem;margin-top:2rem">
  Soporte: <a href="mailto:soporte@miloro.app" style="color:#16A34A">soporte@miloro.app</a> · Marc Vicente García · Castellón, España
</p>
</body></html>`;

  return {
    to: args.email,
    subject: `🦜 Tu licencia MiLoro ${planLabel}`,
    text,
    html,
  };
}
