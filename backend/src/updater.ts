/**
 * Updater Tauri — manifest fetching + platform matching.
 *
 * Tauri v2 updater plugin hace GET a:
 *   /api/updater/{target}-{arch}/{current_version}
 * (configurado en desktop/src-tauri/tauri.conf.json → plugins.updater.endpoints)
 *
 * Server responde:
 *   - 204 No Content → cliente está al día, no update disponible
 *   - 200 + JSON → cliente debe actualizar. Formato:
 *     { version, pub_date, url, signature, notes }
 *
 * Marc publica nuevas versiones via:
 *   ./scripts/release_update.sh stable 0.1.0 --linux-url=... --linux-sig=... [--notes=...]
 * que escribe el manifest completo en KV namespace MILORO_UPDATES con key = channel (`stable`, `beta`).
 */

export interface PlatformAsset {
  signature: string;
  url: string;
}

export interface UpdateManifest {
  version: string;          // "0.1.0" semver
  pub_date: string;         // ISO 8601 UTC
  notes: string;            // release notes (markdown)
  platforms: Record<string, PlatformAsset>;
  // ej. platforms: {
  //   "linux-x86_64": { signature: "dW50cnVzd...", url: "https://github.com/.../release.AppImage.tar.gz" },
  //   "windows-x86_64": { signature: "...", url: "..." },
  //   "darwin-x86_64": { signature: "...", url: "..." },
  //   "darwin-aarch64": { signature: "...", url: "..." }
  // }
}

/**
 * Compara dos versiones semver simples (X.Y.Z).
 * Devuelve >0 si a > b, <0 si a < b, 0 si iguales.
 * Soporta pre-release suffixes (-beta, -rc1) tratándolos como menores que la release base.
 */
export function compareSemver(a: string, b: string): number {
  // Strip pre-release suffix para parse de números, pero peso menor si tiene suffix
  const normaliza = (v: string): { parts: number[]; isPre: boolean } => {
    const [base, pre] = v.split("-", 2);
    const parts = (base ?? "0").split(".").map((p) => {
      const n = parseInt(p, 10);
      return Number.isFinite(n) ? n : 0;
    });
    // Pad a 3 components (X.Y.Z)
    while (parts.length < 3) parts.push(0);
    return { parts, isPre: Boolean(pre) };
  };

  const na = normaliza(a);
  const nb = normaliza(b);
  for (let i = 0; i < 3; i++) {
    if ((na.parts[i] ?? 0) > (nb.parts[i] ?? 0)) return 1;
    if ((na.parts[i] ?? 0) < (nb.parts[i] ?? 0)) return -1;
  }
  // Versions base iguales — pre-release < release
  if (na.isPre && !nb.isPre) return -1;
  if (!na.isPre && nb.isPre) return 1;
  return 0;
}

/**
 * Lee el manifest del canal desde KV. Devuelve null si KV no bindeado o canal no existe.
 */
export async function getManifest(
  kv: KVNamespace | undefined,
  channel: string,
): Promise<UpdateManifest | null> {
  if (!kv) return null;
  const raw = await kv.get(channel);
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw) as UpdateManifest;
    // Validación mínima
    if (!parsed.version || !parsed.platforms) return null;
    return parsed;
  } catch {
    return null;
  }
}

/**
 * Decide si hay update disponible y devuelve el payload del platform target.
 * Returns null si no hay update (cliente al día) o si platform no soportada.
 */
export function resolveUpdate(
  manifest: UpdateManifest | null,
  currentVersion: string,
  platformKey: string,
): { version: string; pub_date: string; notes: string; url: string; signature: string } | null {
  if (!manifest) return null;
  if (compareSemver(manifest.version, currentVersion) <= 0) return null; // cliente al día
  const asset = manifest.platforms[platformKey];
  if (!asset) return null; // platform no soportada en este manifest
  return {
    version: manifest.version,
    pub_date: manifest.pub_date,
    notes: manifest.notes,
    url: asset.url,
    signature: asset.signature,
  };
}

/**
 * Targets soportados por Tauri (de la documentación oficial v2).
 * Mapping del `target-arch` que envía el cliente al key de `manifest.platforms`.
 */
export const SUPPORTED_PLATFORMS = new Set([
  "linux-x86_64",
  "linux-aarch64",
  "windows-x86_64",
  "windows-aarch64",
  "darwin-x86_64",
  "darwin-aarch64",
]);
