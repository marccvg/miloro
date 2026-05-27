# Plan dogfooding Parla — mockup HTML → app real Marc → producto vendible

## Visión global

Convertir el mockup visual en localhost:4330 en una **aplicación funcional** que Marc usa **diariamente como si fuese cliente comprador**. Itera defectos descubiertos en uso real. Cuando funcione perfecto → empaqueta con Tauri y vende.

**Ventaja clave**: validamos UX/funcionalidad SIN gastar 4 semanas en Tauri sin saber si la UI está bien. Dogfooding antes de Rust.

## Arquitectura dogfooding

```
┌──────────────────────────────────────┐
│  Marc abre Chrome → localhost:4331  │
│  (interfaz Parla HTML del mockup)   │
└────────────┬─────────────────────────┘
             │ fetch /api/config GET/POST
             │ fetch /api/test POST
             │ fetch /api/status GET
             ▼
┌──────────────────────────────────────┐
│  Backend Flask Python (puerto 4331) │
│  - Lee/escribe ~/.config/systemd/   │
│    user/oido-daemon.service          │
│  - systemctl --user restart al save │
│  - Llama a audio_a_texto para tests │
└────────────┬─────────────────────────┘
             │
             ▼
┌──────────────────────────────────────┐
│  Sistema actual (oido-daemon + ptt) │
│  YA funciona — solo lo configuramos │
│  desde la web                       │
└──────────────────────────────────────┘
```

## Fases

### Fase 1 — Backend mínimo Flask (4-6h)

`/home/Projects/parla/desktop_app/server/app.py`:

Endpoints:
- `GET /api/config` → lee Environment vars del .service, devuelve JSON `{model, language, hotkey, beam_size, vad, initial_prompt, autotype}`
- `POST /api/config` → recibe JSON, escribe nuevo .service, `systemctl --user daemon-reload && restart`
- `GET /api/status` → daemon active/inactive + ptt active/inactive + last log lines
- `POST /api/test/record` → graba 5s + transcribe + devuelve texto (sin pegar)
- `GET /api/logs` → últimas 20 líneas journalctl

### Fase 2 — Conectar mockup HTML al backend (2-3h)

Modificar `/home/Projects/parla/desktop_app/mockup/index.html`:
- Selector modelo + idioma → fetch POST /api/config al cambiar
- Toggle "Auto-pegar" → fetch POST
- Toggle "Efecto typewriter" → fetch POST
- Botón "Probar grabación 5s" → fetch POST /api/test/record + mostrar resultado en preview
- Status bar → polling cada 5s a /api/status

### Fase 3 — Persistencia config + UX refinada (2-3h)

- Estado se guarda en localStorage como cache
- Si backend devuelve config diferente al cache → sincronizar
- Validación inputs (modelo válido, idioma válido)
- Loading states (spinner mientras restart daemon)
- Toast notifications "Configuración guardada" / "Daemon reiniciado"

### Fase 4 — Auto-launch + tray icon (2-3h)

- Service systemd-user `parla-config-server.service` que arranca Flask al boot
- Atajo desktop entry `.desktop` para abrir interfaz en Chrome app mode
- (Opcional) icono bandeja con `gtk3` o `appindicator` que abre la web

### Fase 5 — Dogfooding 1-2 semanas (Marc usa diario)

- Marc usa diariamente como si fuese cliente
- Anota bugs/UX issues en `docs/DOGFOOD_FEEDBACK.md`
- Itera cada hallazgo
- Cuando "siento que esto es vendible" → siguiente fase

### Fase 6 — Empaquetado Tauri (1-2 semanas)

- Recrear UI HTML en Svelte (más mantenible)
- Backend Rust con `tauri::command` reemplazando los endpoints Flask
- Integrar `whisper.cpp` (Rust bindings) en vez de subprocess Python
- Builds: Linux AppImage + Windows MSI + macOS DMG
- Code signing macOS (€99/año Apple)
- Code signing Windows (opcional primer año, alerta SmartScreen aceptable)

### Fase 7 — License server + Stripe (1 semana)

- Cloudflare Workers + D1 (free tier)
- POST /activate → recibe license_key + machine_fingerprint → guarda → devuelve token
- App verifica token offline después de primera activación
- Stripe webhook → genera license_key UUID → email cliente

### Fase 8 — Landing + launch (3 días)

- Landing Astro en `parla.es` (o dominio elegido)
- Screenshots + demo video + comparison table vs MacWhisper/Otter
- ProductHunt + r/SideProject + LinkedIn launch

## Total tiempo Marc

- Fases 1-4 (dogfooding setup): **10-15h**
- Fase 5 (uso diario): **2 semanas tiempo calendario, ~0h dedicación nueva**
- Fases 6-8 (empaquetado + venta): **3-4 semanas**

**Total**: ~6 semanas calendario, ~50h trabajo Marc, primer producto vendible.

## Beneficio dogfooding

- Validamos UX REAL antes de gastar 4 sem en Tauri
- Marc encuentra bugs/UX issues que solo aparecen con uso continuo (no test)
- Cuando Marc dice "esto está vendible" → SABEMOS que está vendible
- Si dogfooding revela "esto no es vendible como creía" → pivote barato (no perdiste 4 semanas Rust)

## Decisión Marc requerida

1. ¿Arranco Fase 1 (backend Flask) ahora?
2. ¿Nombre producto definitivo? Sugerencias: **Parla** (ya tiene), **Dicta**, **Voxlocal**, **Hablar.app**, **Locuto**
3. ¿Dominio? Verifico disponibilidad con check_domain.py si me das uno o varios candidatos
4. Modelo precio confirmado: **77€ pago único + 7€/mes Pro**?
