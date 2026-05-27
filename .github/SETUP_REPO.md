# GitHub Actions Setup — MiLoro builds Win + Mac automáticos

## Una sola vez — setup repo + secrets (~15 min)

### 1. Crear repo GitHub

```bash
cd /home/Projects/parla
git init -b main
git add .
git commit -m "Initial commit MiLoro"

# Crear repo PRIVADO en GitHub (https://github.com/new) — nombre: miloro
# Después conectar:
git remote add origin https://github.com/<TU_USUARIO>/miloro.git
git push -u origin main
```

⚠ **Repo PRIVADO** mientras esté en alpha (no quieres que se vea el code antes de release público).

### 2. Configurar secrets en repo

Ve a: `https://github.com/<TU_USUARIO>/miloro/settings/secrets/actions` → **"New repository secret"**

Crea estos **2 secretos** (necesarios para que el updater Tauri firme builds correctamente):

| Secret name | Valor |
|---|---|
| `TAURI_SIGNING_PRIVATE_KEY` | Contenido completo de `~/.tauri/miloro-update.key` (`cat ~/.tauri/miloro-update.key` en tu máquina y pega) |
| `TAURI_SIGNING_PRIVATE_KEY_PASSWORD` | Tu password de la key (lo tienes en `/home/marc/Escritorio/MARC/CONTRASENYES/CONTRASENYES/miloro_signing_key.txt`) |

⚠ **Si pierdes o cambias** estos values, los clientes ya instalados NO podrán recibir updates (firma no validará). Mantenlos consistentes.

### 3. Trigger primer build

**Opción A — vía tag (release oficial)**:
```bash
git tag v0.0.9
git push origin v0.0.9
```
GitHub Actions detecta el tag → arranca matrix build 4-platforms → crea Release automáticamente con los artefactos.

**Opción B — vía UI manual (testing)**:
- Ve a `https://github.com/<TU_USUARIO>/miloro/actions/workflows/build.yml`
- Click **"Run workflow"** → branch `main` → version `0.0.9` → "Run workflow"
- Tarda ~15-25 min los 4 builds en paralelo

### 4. Tras builds OK

GitHub Release tendrá:
- `MiLoro_0.0.9_amd64.AppImage` + `.sig` (Linux)
- `MiLoro_0.0.9_x64-setup.nsis.zip` + `.sig` (Windows)
- `MiLoro_0.0.9_universal.dmg` + `.app.tar.gz` + `.sig` (macOS Intel + Apple Silicon)

**Subir a R2 + publish manifest** (que es lo que usa el auto-updater Tauri):
```bash
cd /home/Projects/parla/backend

# Descarga assets desde GitHub release
gh release download v0.0.9 -D /tmp/miloro-release/

# Sube cada archivo a R2 con rclone
for f in /tmp/miloro-release/*; do
  ./scripts/load_secrets.sh rclone copy "$f" r2:miloro-releases/v0.0.9/ --progress --s3-no-check-bucket
done

# Publish manifest (necesita actualizar el script para incluir Windows + macOS URLs)
./scripts/load_secrets.sh ./scripts/release_update.sh stable 0.0.9 \
  --linux-url=https://pub-XXX.r2.dev/v0.0.9/MiLoro_0.0.9_amd64.AppImage \
  --linux-sig="$(cat /tmp/miloro-release/MiLoro_0.0.9_amd64.AppImage.sig)" \
  --windows-url=https://pub-XXX.r2.dev/v0.0.9/MiLoro_0.0.9_x64-setup.nsis.zip \
  --windows-sig="$(cat /tmp/miloro-release/MiLoro_0.0.9_x64-setup.nsis.zip.sig)" \
  --darwin-x86-url=https://pub-XXX.r2.dev/v0.0.9/MiLoro_0.0.9_universal.dmg \
  --darwin-x86-sig="$(cat /tmp/miloro-release/MiLoro_0.0.9_universal.dmg.sig)" \
  --notes='Release multi-OS automática via GitHub Actions'
```

(Future TODO: script wrapper que automatice este flujo completo `gh-to-r2.sh v0.0.9`.)

---

## Costes

GitHub Actions free tier:
- **Repos públicos**: minutos ilimitados
- **Repos privados**: 2000 min/mes free, después $0.008/min Linux, $0.016/min Win, $0.08/min Mac

Build matrix MiLoro tarda:
- Linux: ~6 min × 1× = 6 min
- Win: ~10 min × 2× (multiplier) = 20 min
- Mac x86: ~8 min × 10× (multiplier) = 80 min
- Mac ARM: ~6 min × 10× = 60 min

**Total ~166 min/release** en facturación. 12 releases/mes = 1992 min (justo dentro de free tier).

Si superas: ~$3-5/release adicional. Aún muy bajo para producto pago.

---

## Troubleshooting

### Build Linux falla en `libwebkit2gtk-4.1-dev`

Ubuntu 22.04 viene con `webkit2gtk-4.0`. Tauri 2 requiere `4.1`. Si actions/runners cambian Ubuntu version, ajustar:
- Cambiar `ubuntu-22.04` por `ubuntu-24.04` en la matrix
- O añadir PPA con `4.1`

### macOS build falla en signing

Si no hay `TAURI_SIGNING_PRIVATE_KEY` en secrets, el build sigue pero sin `.sig`. Updater rechazaría. Verifica que ambos secrets están en repo settings.

### Windows build "patchelf not found"

Patchelf es Linux-only, no debería pedirse en Windows. Si aparece, hay bug en tauri-cli — actualizar versión.

### Caché Rust corrupto tras cambio de versión

Borrar caché desde GitHub UI: Actions → Caches → Delete all.

---

## Workflow vs `publish_release.sh` local

| Tarea | Local (`publish_release.sh`) | GitHub Actions (`build.yml`) |
|---|---|---|
| Build Linux | ✅ rápido (incremental cache local) | ✅ from scratch ~6 min |
| Build Windows | ❌ no soportado | ✅ |
| Build macOS | ❌ no soportado | ✅ |
| Sign | ✅ con tu key local | ✅ con secrets repo |
| Upload R2 | ✅ rclone | ❌ (TODO: añadir al workflow) |
| Publish manifest KV | ✅ wrangler | ❌ (TODO) |

**Workflow actual**: para releases multi-OS, GitHub Actions hace builds y crea Release con assets. Tú descargas + subes a R2 + publish manifest a mano.

**Workflow futuro** (TODO): añadir job al final del workflow.yml que llame `wrangler` (con secrets `CLOUDFLARE_API_TOKEN`) + rclone (con secrets R2) para automatizar todo end-to-end. Cuando tengas pipeline maduro.
