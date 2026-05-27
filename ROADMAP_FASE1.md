# ROADMAP_FASE1 — Parla: MVP vendible (mes 0-2)

_Generado por worker `2026-05-13-1701-PARLA_DEEP_ROADMAP01` — 2026-05-13. Extiende `ROADMAP.md` y `ROADMAP_GEN01` (Fase 0)._

## Posicionamiento de esta fase

Fase 0 (ROADMAP_GEN01) deja un instalador funcional y latencia validada en hardware típico. **Fase 1 lo convierte en producto vendible**: empaquetado profesional con auto-update y firma de código, landing producto + página de precios pública, vídeo demo, anti-piracy mínimo, canal de soporte post-venta, y un test de stress real con múltiples usuarios concurrentes. Al final de Fase 1 cualquier pyme puede descargar la demo, ver el precio, probarla 7 días y comprar sin que Marc intervenga manualmente — pipeline preparado para outreach Fase 2.

## Objetivo de fase

Producto Parla en estado "listo para vender" — empaquetado profesional, landing pública, demo gratuita auto-servicio (sin email gate manual), pricing publicado, canal soporte operativo. Coste validación: €0 (sin contrataciones; solo tiempo de Marc + agentes).

## Duración estimada

6-8 semanas desde el cierre de Fase 0. Si Fase 0 cumple criterios fin de mayo 2026, Fase 1 va de aprox. 2026-06 a 2026-07.

## Criterios de éxito

- Instalador Windows MSI firmado (certificado código autenticado, sin warning SmartScreen tras instalación inicial).
- Paquete AppImage Linux con auto-update integrado (cliente recibe updates sin reinstalar).
- Paquete .deb para Ubuntu/Debian con apt repo propio.
- Página `marc_co/web/oido-pro.html` publicada con CTA principal "Descargar demo gratuita 7 días".
- Página de pricing pública con tres tiers: Individual (€19/usuario/mes), Equipo (€15/usuario/mes ≥3 usuarios), On-prem (€1.5-3k setup + €150-300/mes mantenimiento).
- Vídeo demo 90s embeded en landing (subtitulado ES/CA).
- Sistema licencia básico: clave de activación servidor → cliente, validación local con grace period 7 días offline.
- Test stress: 8 usuarios concurrentes sobre 1 mini-PC (NUC 13 o Beelink SER7) con latencia P95 <3s mantenida.
- Pack documentación cliente PDF: instalación, configuración hotkey, troubleshooting (ES + CA).
- Canal soporte operativo: email `soporte@oido.pro` (o similar) + bot Telegram para tickets.
- Sistema telemetría opt-in (privacy-by-design, anónimo, opt-out claro en setup).

## Trigger de paso a Fase 2

- Demo gratuita auto-servicio funciona: al menos 5 instalaciones reales desde landing (Marc + 4 testers externos, sin asistencia técnica).
- Pricing aceptado por feedback de 3 pymes target (ronda preliminar, ver Fase 2).
- 0 crashes críticos en 30 días post-empaquetado.

## Métricas de fase

- Instalaciones demo desde landing (número, target ≥5 manual + cualquier orgánico).
- Latencia P95 transcripción multi-usuario (segundos, target <3s a 8 usuarios concurrentes).
- Tasa éxito instalación: instalaciones completadas / descargas (target >80%).
- Crashes reportados via telemetría (target 0 críticos / 30 días).
- Tiempo carga landing (Lighthouse score >90).

## Tareas atómicas (borradores en working_dir)

| # | ID borrador | Título | est. min |
|---|---|---|---|
| F1-01 | `fase1_01_empaquetado_appimage_autoupdate` | Empaquetado AppImage Linux con auto-update (omanom-appimage-update o similar) | 60 |
| F1-02 | `fase1_02_paquete_deb_apt_repo` | Crear paquete .deb Ubuntu/Debian + apt repo propio (oido.pro/apt) | 50 |
| F1-03 | `fase1_03_instalador_windows_msi_firmado` | Instalador Windows MSI firmado con certificado código (DigiCert o similar) | 75 |
| F1-04 | `fase1_04_licencia_activacion_offline` | Sistema licencia: clave activación + validación local con grace offline 7 días | 90 |
| F1-05 | `fase1_05_landing_parla_html` | Landing producto en `marc_co/web/oido-pro.html` con CTA descarga demo | 60 |
| F1-06 | `fase1_06_pricing_page_publica` | Página pricing pública (3 tiers: individual, equipo, on-prem) | 45 |
| F1-07 | `fase1_07_video_demo_90s` | Producir vídeo demo 90s (screencast + voz Marc, subtítulos ES/CA) | 90 |
| F1-08 | `fase1_08_test_stress_8usuarios_concurrentes` | Test stress 8 usuarios concurrentes sobre NUC/Beelink (latencia P95 <3s) | 75 |
| F1-09 | `fase1_09_pack_documentacion_pdf_cliente` | Pack documentación cliente PDF (instalación + hotkey + troubleshooting, ES + CA) | 60 |
| F1-10 | `fase1_10_soporte_email_telegram_bot` | Canal soporte: email soporte@oido.pro + bot Telegram tickets básico | 60 |
| F1-11 | `fase1_11_telemetria_opt_in_anonima` | Sistema telemetría opt-in anónima (uso + crashes, privacy-by-design) | 60 |
| F1-12 | `fase1_12_newsletter_signup_landing` | Mailing list newsletter en landing (signup → CRM simple, ConvertKit/Brevo) | 40 |

**Total Fase 1: 12 borradores.**

## Riesgos específicos Fase 1

- **Certificado código Windows caro (~€300/año)** → Alternativa: arrancar con SmartScreen warning + instrucciones en landing ("Más información → Ejecutar de todas formas"). Comprar certificado solo si tracción real Fase 2 lo justifica. Decisión en Fase 2 tras primer cliente.
- **AppImage auto-update flaky en algunos distros** → Fallback documentado: descargar nueva versión manualmente; mensaje claro al usuario. No bloquea Fase 1.
- **Latencia degrada con 8 usuarios concurrentes** → Si test falla, capar oferta on-prem a "hasta N usuarios" según hardware. Mejor honesto que prometer y fallar.
- **Anti-piracy fácil de bypassear** → Aceptable Fase 1; el cliente target (pyme legal/contable/construcción) NO va a piratear software corporativo por riesgo cumplimiento. Reforzar en Fase 3 si necesario.

## Cross-link

- `ROADMAP.md` — visión general 3 fases ya generada por roadmap_generator.
- `ROADMAP_GEN01` (working_dir `2026-05-13-1225-ROADMAP_GEN01`) — Fase 0 tareas técnicas (20 borradores parla_001-020). No duplicar.
- `idea-125` — origen producto.
- `decisiones.md` 2026-05-13 — apuesta principal Marc + decisión internalizar (sin gestoría externa).
