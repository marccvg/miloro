# Iconos — pendiente generar

Los iconos referenciados en `tauri.conf.json` no estan incluidos en este MVP
porque son binarios y `cargo tauri build` los exige. Generar con:

```bash
cd /home/Projects/parla/desktop
# Necesita un icono fuente 1024x1024 PNG
npx tauri icon /home/Projects/parla/brand/parla-logo-1024.png
```

Esto creara automaticamente:

- `32x32.png`
- `128x128.png`
- `128x128@2x.png`
- `icon.icns` (macOS)
- `icon.ico` (Windows)

Mientras tanto, `cargo tauri dev` deberia funcionar sin iconos (solo afecta
al bundling release).

Si no hay icono fuente en `/home/Projects/parla/brand/`, generar uno
provisional con ImageMagick:

```bash
convert -size 1024x1024 xc:'#2C5282' -gravity center \
  -pointsize 600 -fill white -annotate 0 'P' \
  /home/Projects/parla/desktop/parla-tmp-icon.png
npx tauri icon /home/Projects/parla/desktop/parla-tmp-icon.png
```
