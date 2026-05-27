// Tauri updater manifest endpoint para MiLoro (catch-all version).
//
// URL pattern (configurado en tauri.conf.json):
//   https://miloro.app/updater/{{target}}-{{arch}}/{{current_version}}
//
// Ejemplos:
//   /updater/linux-x86_64/0.0.1
//   /updater/windows-x86_64/0.0.1
//   /updater/darwin-aarch64/0.0.1
//
// Respuesta:
//   - 204 No Content si current_version >= latest release (no update needed)
//   - 200 + JSON Tauri format si hay update disponible
//   - 404 si target/arch desconocido o no hay asset compatible

const GITHUB_OWNER = "marccvg";
const GITHUB_REPO = "miloro";

const ASSET_MATCHERS = {
  "linux-x86_64":   (name) => name.endsWith(".AppImage") && name.includes("amd64"),
  "linux-aarch64":  (name) => name.endsWith(".AppImage") && name.includes("arm64"),
  "windows-x86_64": (name) => name.endsWith(".msi") && (name.includes("x64") || name.includes("amd64")),
  "windows-aarch64":(name) => name.endsWith(".msi") && name.includes("arm64"),
  // macOS: buildeamos universal-apple-darwin → 1 solo .app.tar.gz sirve para ambas arch.
  "darwin-x86_64":  (name) => name.endsWith(".app.tar.gz"),
  "darwin-aarch64": (name) => name.endsWith(".app.tar.gz"),
  "darwin-universal":(name) => name.endsWith(".app.tar.gz"),
};

function compareVersions(a, b) {
  const pa = a.replace(/^v/, "").split(".").map((n) => parseInt(n, 10) || 0);
  const pb = b.replace(/^v/, "").split(".").map((n) => parseInt(n, 10) || 0);
  for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
    const da = pa[i] || 0;
    const db = pb[i] || 0;
    if (da !== db) return da - db;
  }
  return 0;
}

function jsonError(msg, status) {
  return new Response(JSON.stringify({ error: msg }), {
    status,
    headers: { "content-type": "application/json" },
  });
}

export async function onRequest({ params }) {
  // params.path es un array porque usamos [[path]] (catch-all)
  const parts = Array.isArray(params.path) ? params.path : [params.path];
  if (parts.length !== 2) {
    return jsonError(`expected /updater/{target-arch}/{version}, got /updater/${parts.join("/")}`, 400);
  }
  const [targetArch, version] = parts;

  const matcher = ASSET_MATCHERS[targetArch];
  if (!matcher) {
    return jsonError(`unknown target-arch: ${targetArch}`, 404);
  }

  let release;
  try {
    const resp = await fetch(
      `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases/latest`,
      { headers: { "user-agent": "miloro-updater-edge", "accept": "application/vnd.github+json" } }
    );
    if (!resp.ok) return jsonError(`github api ${resp.status}`, 502);
    release = await resp.json();
  } catch (e) {
    return jsonError(`github fetch failed: ${e}`, 502);
  }

  const latestVersion = (release.tag_name || "").replace(/^v/, "");
  if (!latestVersion) return jsonError("no tag_name in latest release", 502);

  if (compareVersions(latestVersion, version) <= 0) {
    return new Response(null, { status: 204 });
  }

  const assets = release.assets || [];
  const binary = assets.find((a) => matcher(a.name));
  if (!binary) {
    return jsonError(`no asset for ${targetArch} in release ${latestVersion}`, 404);
  }
  const sigAsset = assets.find((a) => a.name === `${binary.name}.sig`);
  if (!sigAsset) {
    return jsonError(`missing signature ${binary.name}.sig`, 502);
  }

  let signature;
  try {
    const sigResp = await fetch(sigAsset.browser_download_url, {
      headers: { "user-agent": "miloro-updater-edge" },
    });
    if (!sigResp.ok) return jsonError(`sig fetch ${sigResp.status}`, 502);
    signature = (await sigResp.text()).trim();
  } catch (e) {
    return jsonError(`sig fetch failed: ${e}`, 502);
  }

  const manifest = {
    version: latestVersion,
    pub_date: release.published_at,
    url: binary.browser_download_url,
    signature,
    notes: release.body || `MiLoro ${latestVersion}`,
  };

  return new Response(JSON.stringify(manifest), {
    status: 200,
    headers: {
      "content-type": "application/json",
      "cache-control": "public, max-age=300",
    },
  });
}
