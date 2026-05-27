# ROADMAP_FASE2 — Parla: primer cliente real (mes 2-4)

_Generado por worker `2026-05-13-1701-PARLA_DEEP_ROADMAP01` — 2026-05-13._

## Posicionamiento de esta fase

Fase 1 deja un producto autoservicio descargable. **Fase 2 lo lleva a un cliente pyme real pagando**. Se identifican 20 pymes target específicas Valencia/Castellón (despachos contables/legales/abogados pyme, sectores con alto volumen de redacción documental + sensibilidad GDPR), se ejecuta outreach personalizado (LinkedIn + email + llamada + visita presencial), se cierra al menos 1 cliente con contrato firmado, y se entrega setup on-prem + onboarding. El objetivo no es solo ingresos: es validar el ciclo comercial completo, generar caso estudio publicable, y aprender qué objeciones reales aparecen.

## Objetivo de fase

Cerrar 1 cliente Parla con contrato firmado + factura emitida + instalación on-prem operativa + onboarding usuarios completado. Generar caso estudio publicable. Documentar lecciones aprendidas del ciclo comercial para iterar pricing/posicionamiento.

## Duración estimada

8 semanas desde cierre Fase 1. Si Fase 1 cierra fin julio 2026, Fase 2 va de aprox. 2026-08 a 2026-09.

## Criterios de éxito

- Lista 20 pymes target Valencia/Castellón en CSV con: nombre empresa, sector, tamaño (empleados), contacto decisor (nombre + cargo + LinkedIn URL), email, teléfono, fuente.
- 20 contactos iniciales LinkedIn + email enviados (con seguimientos documentados).
- 3 plantillas cold outreach (A/B/C) testadas: ratio respuesta documentado.
- ≥5 reuniones demo presencial o videoconferencia agendadas (de las 20 → 5 = 25% conversión target).
- ≥1 cliente cerrado con contrato firmado + factura emitida.
- Setup on-prem cliente completado: hardware operativo, software instalado, latencia P95 <2s validada in-situ.
- Onboarding usuarios cliente: ≥3 usuarios cliente formados (sesión 1h, vídeo grabado).
- Soporte primer mes intensivo: checkpoints semanales, KPIs uso documentados, 0 incidencias críticas no resueltas.
- Caso estudio publicable redactado (con permiso firmado por cliente).
- Métricas baseline post-onboarding: usuarios activos diarios, transcripciones/día, NPS preliminar.

## Trigger de paso a Fase 3

- 1+ cliente pagando recurrentemente >60 días (validación retention real).
- Pipeline de 3+ leads adicionales activos (no agotamos 20 target sin demanda).
- Decisión Marc: invertir en escalado (multi-tenant cloud, integraciones) basado en métricas reales del cliente.

## Métricas de fase

- Conversión email/LinkedIn → reunión (%, target ≥10%).
- Conversión reunión → propuesta (%, target ≥40%).
- Conversión propuesta → contrato (%, target ≥25%).
- Tiempo lead → contrato firmado (días, baseline a establecer).
- LTV proyectado primer cliente (€, target ≥€3k año 1).
- NPS post-onboarding (target ≥40).
- Tickets soporte/usuario/mes (target ≤2 mes 1, ≤1 mes 2-3).

## Tareas atómicas (borradores en working_dir)

| # | ID borrador | Título | est. min |
|---|---|---|---|
| F2-01 | `fase2_01_lista_20_pymes_target_csv` | Identificar 20 pymes target Valencia/Castellón en CSV (decisor + email + LinkedIn) | 90 |
| F2-02 | `fase2_02_plantillas_cold_email_ab` | Crear 3 plantillas cold email Parla (A/B/C, con angle privacy/eficiencia/sectorial) | 60 |
| F2-03 | `fase2_03_outreach_linkedin_20_contactos` | Outreach LinkedIn 20 decisores (conexión + DM personalizado) | 90 |
| F2-04 | `fase2_04_script_seguimiento_cold_call` | Script seguimiento + cold call (objeciones frecuentes + respuestas) | 45 |
| F2-05 | `fase2_05_materials_demo_presencial_30min` | Materials demo presencial 30 min (slides + handout PDF + dispositivo demo portátil) | 90 |
| F2-06 | `fase2_06_pricing_cerrado_tabla_descuentos` | Pricing concreto cerrado + tabla descuentos (pronto pago, anual, multi-licencia) | 45 |
| F2-07 | `fase2_07_contrato_saas_pyme_plantilla` | Contrato SaaS/on-prem pyme plantilla legal (ES, AI Act mention, DPA GDPR) | 75 |
| F2-08 | `fase2_08_factura_billing_setup` | Factura plantilla + setup billing (Stripe o Holded; numeración correlativa AEAT) | 60 |
| F2-09 | `fase2_09_setup_onprem_primer_cliente` | Setup on-prem primer cliente (presencial Valencia o remoto guiado) | 180 |
| F2-10 | `fase2_10_onboarding_usuarios_cliente_1h` | Onboarding usuarios cliente (sesión 1h presencial/remota + vídeo grabado) | 90 |
| F2-11 | `fase2_11_soporte_primer_mes_intensivo` | Soporte primer mes intensivo (checkpoints semanales, KPIs uso) | 60 |
| F2-12 | `fase2_12_caso_estudio_publicable` | Caso estudio publicable (con permiso cliente, en marc_co/web/casos/) | 60 |
| F2-13 | `fase2_13_metricas_post_onboarding_dashboard` | Dashboard métricas post-onboarding (uso, churn risk, NPS) | 60 |

**Total Fase 2: 13 borradores.**

## Riesgos específicos Fase 2

- **0 conversiones de 20 contactos** → No fallo total: aprender de objeciones. Si la objeción principal es "no entendemos privacy local" → reforzar materials. Si es "muy caro" → testar tier más bajo (€9/usuario para freelancers individuales). Si es "no necesitamos dictado" → pivotar segmento (médicos pyme, periodistas).
- **Cliente pide custom development antes de firmar** → Política: custom solo si €5k+ pago upfront. Resistir ofrecer custom gratis para cerrar primer cliente (sienta precedente malo).
- **Setup on-prem se complica más de lo esperado** → Estimado 3h; si supera 6h, parar y diagnosticar. Documentar en playbook (mejora Fase 3). Aceptar que primer setup será doloroso.
- **Cliente reporta latencia >2s en su red real** → Causa probable hardware/red. Inversión Marc: traer NUC propio de respaldo para primera instalación.
- **Cliente quiere referencias y no tenemos** → Honestidad: "Eres nuestro primer cliente Valencia, por eso ofrecemos precio fundador con SLA reforzado los primeros 6 meses". A muchas pymes les gusta ser primeras.

## Decisiones que dependen de Marc (NO encolar sin OK)

- Validar lista 20 pymes target ANTES de outreach (filtrar por afinidad real con sectores que Marc conoce).
- Aprobar pricing definitivo cerrado.
- Aprobar plantillas cold email finales (la voz tiene que ser de Marc).
- Asistir presencialmente al primer setup on-prem (no se puede delegar al agente).

## Cross-link

- `ROADMAP_FASE1.md` — fase previa (producto vendible).
- `idea-070` SaaS Cockpit hosted — modelo SaaS de referencia para pricing.
- `idea-079` WP-Optimizer ES — patrón outreach vertical pyme local.
- `decisiones.md` 2026-05-13 — apuesta principal Parla.
