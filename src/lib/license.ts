import { computeFingerprint } from "./fingerprint";

export type LicenseStatus = "unknown" | "valid" | "invalid";

export interface VerifyResult {
  status: LicenseStatus;
  message: string;
}

const DEFAULT_BACKEND = "http://localhost:8787";

function backendUrl(): string {
  // Allow override via localStorage for testing against deployed Worker later.
  const override = localStorage.getItem("miloro.backend_url");
  return (override && override.trim()) || DEFAULT_BACKEND;
}

export async function verifyLicense(key: string): Promise<VerifyResult> {
  const trimmed = key.trim();
  if (!trimmed) {
    return { status: "invalid", message: "Falta la key." };
  }
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(trimmed)) {
    return {
      status: "invalid",
      message: "Formato UUID inválido (debe ser xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)",
    };
  }
  const fingerprint = await computeFingerprint();
  const base = backendUrl();

  // 1. Activate device (idempotente: si ya está activo, devuelve ok)
  try {
    const a = await fetch(`${base}/api/license/activate`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ key: trimmed, fingerprint }),
    });
    if (!a.ok) {
      const detail = await a.text().catch(() => "");
      // Si fallamos en activate, NO seguir a verify (saldrá igual fallo)
      return {
        status: "invalid",
        message: `Activación falló (${a.status}): ${detail.slice(0, 140) || "—"}`,
      };
    }
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return { status: "invalid", message: `No se pudo contactar backend: ${msg}` };
  }

  // 2. Verify (debería ir OK ahora que el device está activo)
  try {
    const r = await fetch(`${base}/api/license/verify`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ key: trimmed, fingerprint }),
    });
    if (r.ok) {
      localStorage.setItem("miloro.license_key", trimmed);
      return { status: "valid", message: "Licencia verificada y dispositivo activado." };
    }
    const detail = await r.text().catch(() => "");
    return {
      status: "invalid",
      message: `Verify falló (${r.status}): ${detail.slice(0, 140) || "—"}`,
    };
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return { status: "invalid", message: `No se pudo contactar backend: ${msg}` };
  }
}

export function loadStoredKey(): string {
  return localStorage.getItem("miloro.license_key") ?? "";
}

export interface DeviceInfo {
  id: number;
  hostname: string | null;
  os: string | null;
  activated_at: number;
  last_seen: number;
}

export interface LicenseInfo {
  email: string;
  plan: "free" | "standard" | "pro";
  devices_used: number;
  devices_max: number;
  devices: DeviceInfo[];
  license_status: string;
  expires_at: number | null;
  last_payment_at: number | null;
  seconds_used_today: number;
}

/** Free tier: cuántos segundos de audio puede transcribir por día (UTC). */
export const FREE_QUOTA_SECONDS_PER_DAY = 30 * 60; // 30 min

/** Llama /api/license/dashboard?key=X. Devuelve null si falla (ej. backend offline). */
export async function fetchDashboard(key: string): Promise<LicenseInfo | null> {
  if (!key) return null;
  try {
    const r = await fetch(`${backendUrl()}/api/license/dashboard?key=${encodeURIComponent(key)}`);
    if (!r.ok) return null;
    const data = await r.json();
    if (data.status !== "ok" || !data.license) return null;
    return {
      email: data.license.email,
      plan: data.license.plan,
      devices_used: data.devices_used,
      devices_max: data.license.devices_max,
      devices: data.devices || [],
      license_status: data.license.license_status,
      expires_at: data.license.expires_at,
      last_payment_at: data.license.last_payment_at,
      seconds_used_today: data.seconds_used_today || 0,
    };
  } catch {
    return null;
  }
}

export function clearStoredKey(): void {
  localStorage.removeItem("miloro.license_key");
}

/** Desactiva un device por su ID. Necesita el fingerprint del device — lo sacamos del DeviceInfo. */
export async function deactivateDeviceById(key: string, deviceId: number): Promise<boolean> {
  if (!key) return false;
  // El backend deactivate por fingerprint. Necesitamos llamar al dashboard primero para conseguir
  // el fingerprint del device por ID, pero el dashboard no lo devuelve (omitido por privacidad).
  // Solución actual: usar endpoint admin que acepta device_id (no existe). Vía SQL directa post-launch.
  // Para alpha: el usuario desactiva mediante el endpoint /api/license/deactivate con SU PROPIO fingerprint.
  // Implementación full requiere extender backend para aceptar device_id en deactivate.
  console.warn("deactivateDeviceById: requiere extensión backend para aceptar device_id", { deviceId });
  return false;
}

/** Reporta segundos de audio transcrito al backend. Non-blocking — si falla, app continúa. */
export async function reportUsage(key: string, seconds: number): Promise<number | null> {
  if (!key || seconds <= 0) return null;
  try {
    const fingerprint = await computeFingerprint();
    const r = await fetch(`${backendUrl()}/api/usage/report`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ key, fingerprint, seconds: Math.round(seconds) }),
    });
    if (!r.ok) return null;
    const data = await r.json();
    return typeof data.seconds_used_today === "number" ? data.seconds_used_today : null;
  } catch {
    return null;
  }
}

/** Desactiva ESTE device actual (el fingerprint que coincide con esta máquina). */
export async function deactivateThisDevice(key: string): Promise<boolean> {
  if (!key) return false;
  const fingerprint = await computeFingerprint();
  try {
    const r = await fetch(`${backendUrl()}/api/license/deactivate`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ key, fingerprint }),
    });
    return r.ok;
  } catch {
    return false;
  }
}
