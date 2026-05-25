/**
 * Machine fingerprint stub.
 *
 * Backend (parla/backend/src/index.ts:60) accepts: /^[a-zA-Z0-9_-]+$/ length 32..128.
 * btoa() yields '+/=' chars that FAIL that regex — so we use SHA-256 hex via WebCrypto.
 *
 * NOTE: this is a stub. Real fingerprint will be a Rust-side machine-id
 * (CPU serial + disk UUID + hostname) computed in src-tauri once we drop
 * the `idea-170` "hardware fingerprint" task. For MVP this is enough to
 * verify the round-trip against the backend.
 */
export async function computeFingerprint(): Promise<string> {
  const seed = [
    navigator.userAgent,
    String(screen.width),
    String(screen.height),
    navigator.language,
    String(navigator.hardwareConcurrency ?? 0),
    new Date().getTimezoneOffset().toString(),
  ].join("|");
  const bytes = new TextEncoder().encode(seed);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}
