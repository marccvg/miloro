# ROADMAP_FASE3 — Parla: escalado (mes 4-12)

_Generado por worker `2026-05-13-1701-PARLA_DEEP_ROADMAP01` — 2026-05-13._

## Posicionamiento de esta fase

Fase 2 ha validado el ciclo comercial completo con 1+ cliente pagando recurrentemente y un pipeline de 3+ leads activos. **Fase 3 es escalado**: multi-tenant cloud opcional (idea-076 base), integraciones con software pyme ya instalado (A3 Contabilidad, FactuSOL, Sage), marketing organic (blog SEO + YouTube), partnerships con incubadoras locales (AERTIC, Espaitec), y versión equipo configurable para 10+ usuarios. Co-brand hardware (Logitech/Keychron) entra en evaluación SOLO si llegamos a 50+ usuarios pagando.

Esta fase es **condicional**: solo se ejecuta si Fase 2 cumple el trigger (1 cliente recurrente + 3 leads activos). Si Fase 2 falla, no se pasa a Fase 3 — se itera Fase 2 con aprendizajes o se pivota.

## Objetivo de fase

Crecer Parla de 1 cliente a 10 clientes recurrentes con €3-5k MRR. Validar canal organic + integraciones como motor de growth sostenible. Establecer fundación técnica (multi-tenant + API) para crecimiento Y2 a 50+ clientes.

## Duración estimada

8 meses desde cierre Fase 2. Si Fase 2 cierra fin septiembre 2026, Fase 3 va de aprox. 2026-10 a 2027-05.

## Criterios de éxito

- Multi-tenant cloud operativo (cliente puede elegir cloud vs on-prem; cloud con cifrado at-rest + DPA firmable).
- API REST público v1 documentada (transcripción endpoint + auth keys + rate limit).
- 1 integración A3 Contabilidad funcional (dictado → ticket A3, plugin homologado o vía hooks).
- 1 integración FactuSOL funcional (dictado → factura draft FactuSOL).
- 1 integración Sage50/Contaplus funcional.
- 10 posts blog SEO publicados en oido.pro/blog (keywords: "dictado voz español pyme", "alternativa Wispr Flow español", etc.).
- Canal YouTube con 10 vídeos demo + tutoriales (≥1.000 views totales).
- 1 partnership formal con AERTIC (Asoc. Empresarial TIC Castellón) o Espaitec (parque científico UJI).
- Versión Equipo (10+ usuarios) con consola admin web: gestión usuarios, métricas uso, billing centralizado.
- 10 clientes recurrentes pagando ≥30 días continuos.
- MRR ≥€3.000.

## Trigger Fase 4 (co-brand hardware)

- 50+ usuarios pagando (no clientes — usuarios finales).
- MRR ≥€5.000 estable 3+ meses.
- Demanda real de hardware integrado (≥5 clientes pidiendo botón dedicado).
- Caja disponible para MOQ inicial (≥€20k libre).
- Decisión explícita Marc tras ver datos.

## Métricas de fase

- Clientes recurrentes activos (número, target 10).
- MRR (€, target €3-5k).
- Churn mensual (%, target <5%).
- Posts blog publicados (número, target 10).
- Tráfico organic landing (sesiones/mes, target ≥1.000 mes 6).
- Conversión organic → trial (%, target ≥3%).
- Leads desde partnership AERTIC/Espaitec (número).
- Integraciones operativas (número, target 3).
- API requests/mes (uso, baseline a establecer).

## Tareas atómicas (borradores en working_dir)

| # | ID borrador | Título | est. min |
|---|---|---|---|
| F3-01 | `fase3_01_multi_tenant_cloud_arquitectura` | Diseñar arquitectura multi-tenant cloud (basado en idea-076) | 120 |
| F3-02 | `fase3_02_api_publico_rest_v1` | API REST público v1 (transcripción endpoint + auth + rate limit + docs) | 150 |
| F3-03 | `fase3_03_integracion_a3_contabilidad` | Integración A3 Contabilidad (dictado → ticket A3, plugin o hooks) | 180 |
| F3-04 | `fase3_04_integracion_factusol` | Integración FactuSOL (dictado → factura draft) | 150 |
| F3-05 | `fase3_05_integracion_sage50` | Integración Sage50/Contaplus | 150 |
| F3-06 | `fase3_06_blog_seo_10_posts` | Blog SEO 10 posts oido.pro/blog (keywords investigadas + calendario editorial) | 240 |
| F3-07 | `fase3_07_canal_youtube_10_videos` | Canal YouTube 10 vídeos demo + tutoriales | 300 |
| F3-08 | `fase3_08_partnership_aertic_espaitec` | Outreach + propuesta partnership AERTIC y Espaitec | 90 |
| F3-09 | `fase3_09_version_equipo_consola_admin` | Versión Equipo: consola admin web (usuarios + métricas + billing centralizado) | 240 |

**Total Fase 3: 9 borradores.**

## Riesgos específicos Fase 3

- **Multi-tenant rompe propuesta de valor "privacy local"** → Mitigación: cloud es opcional, no default. Posicionar como conveniencia para clientes pequeños (1-3 usuarios) que NO quieren hardware on-prem. Pricing cloud incluye DPA + cifrado at-rest auditable. Clientes con sensibilidad alta siguen yendo on-prem.
- **Integraciones requieren mantenimiento perpetuo** → Política: solo 3 integraciones core en Fase 3 (A3, FactuSOL, Sage). Resto son requests cliente con presupuesto custom o se evalúan en Y2. Documentar cada integración con tests automatizados para detectar breakage.
- **Blog SEO no rankea en 6 meses** → SEO es lento. KPIs intermedios: links indexados Google (target 10/10 posts), keywords trackeadas (target ≥3 keywords top-20 mes 6). Si fracasa SEO orgánico, evaluar Google Ads (presupuesto €200-500/mes test mes 6-8).
- **Partnership AERTIC/Espaitec no aporta leads** → Aceptable: aporta credibilidad + networking. Si 0 leads tras 6 meses partnership, no renovar acuerdo. Probar otras incubadoras (Lanzadera Valencia, Demium).
- **Canal YouTube genera 0 views** → Aceptable Y1: vídeos sirven como material comercial (link desde landing + emails). View count es secundario. Si Y2 sigue 0 views, parar inversión video.

## Decisiones que dependen de Marc

- Validar arquitectura multi-tenant ANTES de codificar (decisión clave: cloud propio AWS/GCP vs hosted Hetzner).
- Aprobar inversión integraciones (A3 puede requerir licencia partner, ~€500-2k/año).
- Aprobar inversión content (video producer freelance vs Marc graba directo: €0 o €500-1k/vídeo si externalizamos).
- Aprobar partnership terms con AERTIC/Espaitec.

## Cross-link

- `ROADMAP_FASE2.md` — fase previa (primer cliente).
- `idea-076` Multi-tenant clientes — base arquitectónica.
- `idea-054` Company OS — Parla es módulo concreto del Company OS conceptual.
- `idea-070` SaaS Cockpit hosted — patrón pricing/billing.
- `decisiones.md` 2026-05-13 — apuesta principal + decisión internalizar.
