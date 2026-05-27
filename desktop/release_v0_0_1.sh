#!/bin/bash
set -e
cd /home/Projects/parla/desktop

BUNDLE="src-tauri/target/release/bundle"
APPIMAGE="$BUNDLE/appimage/MiLoro_0.0.1_amd64.AppImage"
DEB="$BUNDLE/deb/MiLoro_0.0.1_amd64.deb"
RPM="$BUNDLE/rpm/MiLoro-0.0.1-1.x86_64.rpm"

for f in "$APPIMAGE" "$APPIMAGE.sig" "$DEB" "$DEB.sig" "$RPM" "$RPM.sig"; do
  if [ ! -f "$f" ]; then
    echo "ERROR: falta $f" >&2
    exit 1
  fi
done

echo "=== Verificar gh auth ==="
gh auth status

echo ""
echo "=== Crear release v0.0.1 ==="
gh release create v0.0.1 \
  "$APPIMAGE" "$APPIMAGE.sig" \
  "$DEB" "$DEB.sig" \
  "$RPM" "$RPM.sig" \
  --title "MiLoro v0.0.1 — alpha Linux" \
  --notes "Primera alpha familia. Linux only.

**Recomendado:** descarga el AppImage (no requiere instalación).

\`\`\`bash
chmod +x MiLoro_0.0.1_amd64.AppImage
./MiLoro_0.0.1_amd64.AppImage
\`\`\`

También disponible .deb (Ubuntu/Debian) y .rpm (Fedora/RHEL).

Win/Mac próximamente."

echo ""
echo "=== Release URL ==="
gh release view v0.0.1 --json url,assets -q '{url, assets: [.assets[].name]}'
