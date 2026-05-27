# LAUNCH PACK — Parla (Oído Pro)

> Pack maestro "lanzamiento Parla en 4 semanas". Checklist por categoría con estado, owner, dependencias y enlace a la tarea atómica que materializa cada item.
>
> **Fecha emisión:** 2026-05-13
> **Ventana objetivo:** Semanas 1-4 desde decisión de "GO" de Marc (no antes de cerrar primer piloto B2B y nombre comercial — ver bloqueos al final).
> **Marca comercial:** "Parla" provisional. Final pendiente de `idea-129` (nombre + dominio + clearance).
>
> **Producto que se lanza:**
> - **B2C SaaS subscription** (`idea-130`) — app descargable Win/Mac/Linux, billing Stripe, datos voz local.
> - **B2B on-prem piloto pyme construcción** (`idea-131`) — primer cliente familiar de Marc.
>
> Los dos modelos comparten producto técnico (Whisper local + LLM post-proc + hotkey + salida cursor). Cambia el envoltorio comercial.

---

## Leyenda de estado

| Símbolo | Significado |
|:-:|---|
| ⬜ | Sin empezar |
| 🟨 | Borrador encolado (`tareas_borrador_*.md` listo, Marc revisa antes de promover) |
| 🟩 | En ejecución |
| ✅ | Hecho |
| ⏸️ | Bloqueado / depende de evento externo |
| ❌ | Descartado |

**Owner:** `marc` (decisión humana), `worker` (ejecutable por agente), `cliente` (fuera del control nuestro).

---

## 1. Legal / admin

> Marc decide cuándo aplica cada item según volumen real. Algunos (alta autónomo) sólo si llega ingreso recurrente; otros (T&C, política privacidad) son obligatorios desde primer pago.

| # | Item | Estado | Owner | Tarea atómica | Notas |
|:-:|---|:-:|:-:|---|---|
| 1.1 | Alta autónomo / SL (Marc gestiona) | ⏸️ | marc | — | No bloquea piloto si es opción B (setup €800 sin factura formal mientras se valida). Bloquea desde 2º cliente o B2C público. |
| 1.2 | Términos de servicio Parla (B2C + B2B) | 🟨 | worker | `tareas_borrador_01_terminos_servicio.md` | Cláusulas privacidad-local explícitas como diferencial. |
| 1.3 | Política de privacidad GDPR | 🟨 | worker | `tareas_borrador_02_politica_privacidad_gdpr.md` | Énfasis: datos voz NUNCA salen del PC del cliente. |
| 1.4 | Plantilla contrato B2B (setup + recurring) | 🟨 | worker | `tareas_borrador_03_contrato_b2b.md` | Versión piloto (familiar) + versión mercado. |
| 1.5 | Plantilla DPA (Data Processing Agreement) | 🟨 | worker | `tareas_borrador_04_dpa_template.md` | Para pymes que la pidan (legal, sanitario, gestoría). |
| 1.6 | Factura modelo + recibo IVA (B2B + B2C) | 🟨 | worker | `tareas_borrador_05_factura_recibo_iva.md` | Plantillas LibreOffice + cómo emitir desde Stripe Tax. |
| 1.7 | Whitepaper AI Act EU compliance | 🟨 | worker | `tareas_borrador_06_whitepaper_ai_act.md` | Diferencial comercial. Ya planteado en `idea-134`. |

**Bloqueador real:** items 1.2-1.6 deben pasar revisión legal pyme (1h, ~€80-200) antes de uso comercial real. Coste asumible. Marc agenda con abogado tras revisar borradores worker.

---

## 2. Marketing material

> Volumen mínimo para "tener algo decente que enseñar" sin sobre-producir. Iteración tras feedback piloto.

| # | Item | Estado | Owner | Tarea atómica | Notas |
|:-:|---|:-:|:-:|---|---|
| 2.1 | Landing page (ES + EN) | 🟨 | worker | `tareas_borrador_07_landing_es_en.md` | Hugo / Astro estático. Hosting Cloudflare Pages free. |
| 2.2 | Script vídeo demo 60-90s + storyboard | 🟨 | worker | `tareas_borrador_08_video_demo_script.md` | Marc graba con OBS, edita rápido en Kdenlive. |
| 2.3 | 5 screenshots producto en uso | 🟨 | worker | `tareas_borrador_09_screenshots.md` | Mockups + capturas reales del demo actual. |
| 2.4 | 3 testimonials (placeholder hasta pilotos cerrados) | ⏸️ | cliente | `tareas_borrador_10_testimonials_plan.md` | Bloqueado hasta T+30 días de primer piloto B2B real. |
| 2.5 | Logo + brand kit (colores, tipo, símbolo) | 🟨 | worker | `tareas_borrador_11_logo_brand_kit.md` | SVG mano, paleta. Diseñar 3 variantes, Marc elige. |
| 2.6 | Cards LinkedIn + Twitter (1080×1080 + 1200×675) | 🟨 | worker | `tareas_borrador_12_social_cards.md` | Para anuncio público lanzamiento. Plantilla en Penpot. |
| 2.7 | Press release español tech media | 🟨 | worker | `tareas_borrador_13_press_release.md` | El Referente, Hipertextual, Genbeta, Xataka pyme. |

**Restricción honesta:** sin marca cerrada (`idea-129`) no se publica landing ni cards. Borradores se preparan con placeholder "ECHO" + tipografía neutra; sustitución al final es 30 min.

---

## 3. Onboarding cliente B2B

> Aplica a primer piloto construcción (`idea-131`) y replicable a clientes 2-N.

| # | Item | Estado | Owner | Tarea atómica | Notas |
|:-:|---|:-:|:-:|---|---|
| 3.1 | Script primera llamada exploratoria | 🟨 | worker | `tareas_borrador_14_b2b_call_script.md` | 20 min. Cualificación + dolor + cierre demo. |
| 3.2 | Demo presencial guion (30 min) | 🟨 | worker | `tareas_borrador_15_b2b_demo_guion.md` | Estructura demo en cliente + checklist material. |
| 3.3 | Checklist setup on-prem (1 día) | 🟨 | worker | `tareas_borrador_16_b2b_setup_checklist.md` | NUC/Beelink, red, VPN, usuarios, backup. |
| 3.4 | Manual usuario PDF (15 páginas) | 🟨 | worker | `tareas_borrador_17_b2b_manual_pdf.md` | Trabajadores obra, oficina admin, dirección. |
| 3.5 | Vídeo tutorial usuarios finales (5 min) | 🟨 | worker | `tareas_borrador_18_b2b_video_tutorial.md` | Script + escenas, grabación tras setup real. |
| 3.6 | Plan soporte intensivo primer mes | 🟨 | worker | `tareas_borrador_19_b2b_soporte_mes1.md` | Cadencia visitas, canal preferente, escalado. |

**Restricción honesta:** todo el 3.1-3.6 es "borrador testable" — Marc lo refina durante piloto real. Lo que aquí se entrega es plantilla, no documento definitivo.

---

## 4. Onboarding cliente B2C

> Email automation desde el momento del checkout. Provider sugerido: Resend (~$0-20/mes según volumen). Listas en SQLite local mientras volumen <500 suscritos; migración a tool dedicada después.

| # | Item | Estado | Owner | Tarea atómica | Notas |
|:-:|---|:-:|:-:|---|---|
| 4.1 | Email welcome (T+0) | 🟨 | worker | `tareas_borrador_20_b2c_email_welcome.md` | Link descarga + license key + 3 tips iniciales. |
| 4.2 | Email setup ayuda (T+1 día) | 🟨 | worker | `tareas_borrador_21_b2c_email_dia1.md` | Vídeo install 90s + troubleshoot top 3 errores. |
| 4.3 | Email tip uso (T+3 días) | 🟨 | worker | `tareas_borrador_22_b2c_email_dia3.md` | Mostrar feature que el 60% no descubre solo. |
| 4.4 | Email feature avanzada (T+7 días) | 🟨 | worker | `tareas_borrador_23_b2c_email_semana1.md` | Diccionario personalizado, hotkey custom, etc. |
| 4.5 | Email upgrade prompt (T+30 días) | 🟨 | worker | `tareas_borrador_24_b2c_email_mes1.md` | Mensual → Lifetime €99 si usa >X horas/mes. |
| 4.6 | Cancellation flow respetuoso | 🟨 | worker | `tareas_borrador_25_b2c_cancellation_flow.md` | 1-click GDPR + survey opcional + recupera 10% con descuento. |

**Restricción honesta:** secuencia diseñada antes de tener 100 suscriptores es hipótesis. Ajustar tras ver tasas abrir/click reales.

---

## 5. Métricas / KPIs

> Dashboard "lo justo y necesario". SQLite local + Streamlit/Plotly script — no Grafana, no Datadog. Reporte mensual B2B se genera con script Python → PDF.

| # | Item | Estado | Owner | Tarea atómica | Notas |
|:-:|---|:-:|:-:|---|---|
| 5.1 | Métricas usuario (palabras, sesiones, retention) | 🟨 | worker | `tareas_borrador_26_metricas_usuario.md` | Telemetría opt-in (GDPR), agregada, sin contenido voz. |
| 5.2 | Métricas negocio (MRR, churn, CAC) | 🟨 | worker | `tareas_borrador_27_metricas_negocio.md` | Stripe webhooks → SQLite, dashboard simple. |
| 5.3 | Dashboard interno (Streamlit local) | 🟨 | worker | `tareas_borrador_28_dashboard_interno.md` | 1 vista MRR + 1 vista cohort retention + 1 lista clientes. |
| 5.4 | Reporte mensual B2B PDF auto-generado | 🟨 | worker | `tareas_borrador_29_reporte_mensual_b2b_pdf.md` | WeasyPrint, plantilla por cliente, mensual. |

**Restricción honesta:** las métricas B2C requieren telemetría — y eso implica consentimiento explícito por GDPR (incluso si datos no son personales). Diseñar opt-in claro desde primera versión.

---

## Bloqueos generales del LAUNCH

| Bloqueo | Tipo | Cómo se desbloquea | Owner |
|---|:-:|---|:-:|
| `idea-129` nombre comercial final + dominio | 🔴 | Marc decide nombre + compra dominio (.es + .com) | marc |
| `idea-131` primer cliente piloto cerrado | 🔴 | Marc contacta familiar pyme construcción, agenda reunión, cierra piloto opción A/B/C | marc |
| Revisión legal pyme (1h ~€80-200) | 🟡 | Marc agenda con abogado especialista IA/datos | marc |
| Cuenta Stripe / Lemon Squeezy activa | 🟡 | Marc abre cuenta business (requiere fiscal alta) | marc |
| Resend (o equivalente) cuenta + dominio verificado | 🟢 | Worker puede preparar config; Marc valida dominio | worker |

**Lectura honesta:** ninguno de los bloqueos 🔴 está en manos del worker. El pack se prepara para que **el día que Marc cierre piloto + nombre**, el lanzamiento sea cuestión de 1-2 semanas de orquestación, no de un mes empezando desde cero.

---

## Timeline realista (4 semanas desde GO de Marc)

> "GO" = Marc dice "adelante" tras revisar borradores + tener `idea-129` resuelta + `idea-131` con piloto en curso.

### Semana 1 — Legal + brand cerrados

- ⬜ Marc revisa borradores tareas 1.2-1.7 (legal) + 2.1 (landing) → comentarios
- ⬜ Worker integra comentarios, prepara versión 2
- ⬜ Marc agenda revisión legal pyme (1h)
- ⬜ `idea-129` cerrado: marca, dominio comprado, logo definitivo
- ⬜ Stripe / Lemon Squeezy abierto (alta fiscal Marc resuelta)

### Semana 2 — Material marketing publicable

- ⬜ Landing ES/EN publicada (Cloudflare Pages, dominio parla.<tld>)
- ⬜ Vídeo demo 60-90s grabado, editado, subido a YouTube no-listado
- ⬜ 5 screenshots producto definitivos
- ⬜ Cards LinkedIn + Twitter listas
- ⬜ Press release versión final, lista de medios

### Semana 3 — Onboarding B2C + métricas

- ⬜ 6 emails B2C escritos + integrados con Resend
- ⬜ Webhook Stripe → SQLite local funcionando
- ⬜ Dashboard Streamlit MRR/churn corriendo en mini-PC Marc
- ⬜ Cancellation flow probado end-to-end con cuenta test

### Semana 4 — Piloto B2B en marcha + soft launch B2C

- ⬜ Setup piloto pyme construcción ejecutado (1-2 días setup + soporte primera semana)
- ⬜ Vídeo tutorial B2B grabado tras setup real
- ⬜ Manual PDF B2B refinado tras feedback usuarios obra
- ⬜ Soft launch B2C: post en LinkedIn personal + 1 comunidad ES (NO ProductHunt todavía)
- ⬜ Métricas semana 1 lanzamiento: descargas, conversions, errores reportados

**Post-lanzamiento (semanas 5-8):**

- Iteración B2C según feedback primeros 20-50 usuarios.
- Caso estudio piloto construcción a los 30 días.
- ProductHunt + HN ES + r/spaindev: cuando hay 3 testimonios reales (no antes).
- A/B test pricing (`idea-135`) cuando >100 visitas/semana landing.

---

## Anti-patrones detectados (qué NO hacer)

1. **Lanzar antes de cerrar nombre comercial.** Cambiar marca a posteriori implica re-emitir factura, contratos, landing, emails, manual. Coste oculto enorme.
2. **Publicar testimonials inventados o "compuestos".** Quema credibilidad si se descubre. Esperar 30 días piloto real es barato comparado.
3. **Sobre-producir vídeo demo (>1 día).** Marc graba con OBS+webcam+pantalla, edita 2h en Kdenlive. Si en 4 semanas el vídeo no se ha grabado, el problema no es producción.
4. **Empezar ProductHunt sin testimonios + sin landing pulida.** Una sola oportunidad por producto. Esperar a tener T+30 día de piloto real.
5. **Email automation con tool cara (Mailchimp, HubSpot) en mes 0.** Resend + SQLite + cron es suficiente hasta 500 suscritos. Después se evalúa.
6. **Dashboard métricas en cloud (Grafana, Datadog).** Streamlit local en mini-PC Marc cubre necesidad real, coste €0.
7. **Press release simultáneo a 20 medios.** Targeting selectivo: 3-5 medios donde un periodista escribe sobre pyme + IA y le mando email personalizado. Lluvia de spam = 0 publicaciones.
8. **Lifetime €99 con descuento "lanzamiento" €49.** Mata percepción de valor. Si lanzamos a €79, mantenemos. Si lanzamos a €99, mantenemos. Nada de yo-yo.

---

## Cross-link

- `/home/claude/ideas/sistema/idea-125-dictado-voz-cursor-pyme-es.md` — fuente original Oído Pro.
- `/home/claude/ideas/sistema/idea-129-*.md` — naming + dominio (BLOQUEA marketing).
- `/home/claude/ideas/sistema/idea-130-parla-b2c-saas-subscription.md` — modelo B2C.
- `/home/claude/ideas/sistema/idea-131-parla-b2b-on-prem-pyme-construccion.md` — piloto B2B.
- `/home/claude/ideas/sistema/idea-132-parla-vertical-pack-construccion.md` — pack vertical construcción.
- `/home/claude/ideas/sistema/idea-133-parla-marketing-organic-blog-seo-es.md` — marketing organic (post-lanzamiento).
- `/home/claude/ideas/sistema/idea-134-parla-legal-ai-act-compliance-pack.md` — pack legal AI Act.
- `/home/claude/ideas/sistema/idea-135-parla-pricing-test-ab.md` — A/B test pricing (mes 2+).
- `/home/claude/ideas/sistema/idea-136-parla-soporte-tier-community-vs-paid.md` — soporte tiers.
- `/home/claude/ideas/sistema/idea-137-parla-outreach-automatizado-pymes-sector.md` — outreach B2B sectorial.
- `/home/claude/ideas/sistema/idea-138-parla-cli-tool-developers.md` — CLI open-source (post-lanzamiento).
- `/home/Projects/parla/pricing/pricing_recomendado.md` — tiers pricing definitivos.
- `/home/Projects/parla/ROADMAP.md` — roadmap técnico producto (Fase 0/1/2).

## Generado por

Worker `2026-05-13-1813-ECHO_LAUNCH_PACK_ROADMAP01` — 2026-05-13. Los 29 borradores de tareas atómicas viven en `/home/claude/queue/work/2026-05-13-1813-ECHO_LAUNCH_PACK_ROADMAP01/tareas_borrador_*.md`. Marc revisa, ajusta acceptance, y promueve con `cp <borrador>.md /home/claude/queue/todo/` (asignando `id` con timestamp y eliminando `borrador: true`).
