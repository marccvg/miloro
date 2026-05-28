/**
 * Type definitions for parla license server.
 * Marc 2026-05-19.
 */

export interface Env {
  DB: D1Database;
  ENVIRONMENT: string;
  STRIPE_SECRET_KEY: string;
  STRIPE_WEBHOOK_SECRET: string;
  STRIPE_PRICE_STANDARD: string;
  STRIPE_PRICE_PRO: string;
  APP_ORIGIN: string;
  VERIFY_CACHE_TTL_S: string;
  ACTIVATE_RATE_LIMIT_PER_HOUR: string;
  ADMIN_TOKEN: string;
  // Email (opcional — fallback a MailChannels si no hay Resend)
  RESEND_API_KEY?: string;
  EMAIL_FROM?: string;
  // Updater Tauri (opcional — si no bindeado, /api/updater devuelve 204 always)
  MILORO_UPDATES?: KVNamespace;
  // R2 bucket releases (opcional — si bindeado, /api/download/* proxy stream con
  // Content-Disposition: attachment para forzar descarga en vez de "abrir con…"
  // en GNOME/Archive Manager).
  MILORO_RELEASES?: R2Bucket;
}

export type Plan = "free" | "standard" | "pro";
export type LicenseStatus = "active" | "past_due" | "cancelled" | "free";
export type OS = "linux" | "windows" | "macos";

export interface LicenseRow {
  key: string;
  email: string;
  plan: Plan;
  devices_max: number;
  status: LicenseStatus;
  stripe_customer_id: string | null;
  stripe_subscription_id: string | null;
  created_at: number;
  expires_at: number | null;
  last_payment_at: number | null;
  cancelled_at: number | null;
}

export interface DeviceRow {
  id: string;
  license_key: string;
  fingerprint: string;
  hostname: string | null;
  os: string | null;
  activated_at: number;
  last_seen: number;
  deactivated_at: number | null;
}

// Devices máximos por plan (decisión 2026-05-24 + idea-170).
// Free = 1, Pro €9 = 3, standard (legacy) = 3, Compliance futuro = 5.
export const PLAN_DEVICE_LIMITS: Record<Plan, number> = {
  free: 1,
  standard: 3,
  pro: 3,
};

// Quota diaria de segundos de audio por plan.
// -1 = ilimitado. Decisión 2026-05-24: Free = 30 min/día, Pro/standard = ilimitado.
export const PLAN_QUOTA_SECONDS_DAILY: Record<Plan, number> = {
  free: 1800,
  standard: -1,
  pro: -1,
};

export interface QuotaCheck {
  allowed: boolean;
  remaining_seconds: number; // -1 si unlimited
  unlimited: boolean;
  quota_seconds_daily: number; // -1 si unlimited
}

/**
 * Comprueba si el plan tiene quota disponible para hoy.
 * Si `unlimited`, siempre `allowed=true` y `remaining_seconds=-1`.
 */
export function quotaCheck(plan: Plan, secondsUsedToday: number): QuotaCheck {
  const limit = PLAN_QUOTA_SECONDS_DAILY[plan];
  if (limit === -1) {
    return { allowed: true, remaining_seconds: -1, unlimited: true, quota_seconds_daily: -1 };
  }
  const remaining = Math.max(0, limit - Math.max(0, secondsUsedToday));
  return {
    allowed: remaining > 0,
    remaining_seconds: remaining,
    unlimited: false,
    quota_seconds_daily: limit,
  };
}

export interface ActivateBody {
  key: string;
  fingerprint: string;
  hostname?: string;
  os?: OS;
}

export interface VerifyBody {
  key: string;
  fingerprint: string;
}

export interface DeactivateBody {
  key: string;
  fingerprint: string;
}

export interface IssueBody {
  email: string;
  plan?: Plan;
}

export interface CheckoutBody {
  plan: "standard" | "pro";
  email?: string;
}
