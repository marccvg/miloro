# Report — ECHO_PILOTO_CONSTRUCCION_MATERIALS01

**Status:** done
**Duration:** ~35 min
**Idea fuente:** idea-142 (estado `aceptada`)
**Working dir:** `/home/Projects/parla/clientes/piloto_construccion_familiar/`

## Lo que hice

Generados los 7 documentos pedidos por idea-142 en el directorio destino:

1. **`script_llamada.md`** (103 líneas) — guion 3 min para Marc con apertura/puente/oferta/cierre, matriz de reacciones del familiar, errores a evitar, y notas estratégicas (pricing interno NO se menciona en llamada).
2. **`email_seguimiento.md`** (145 líneas) — 3 versiones (A: cierre con fecha, B: hay que convencer al socio, C: pedido aplazar) + reglas de redacción + lo que NO incluir.
3. **`propuesta_1pag.md`** (83 líneas) — formato 1 A4 imprimible/exportable a PDF: qué es, para qué sirve en construcción, tabla comparativa vs Siri/Google/Dragon, oferta piloto, 3 vías post-piloto.
4. **`checklist_setup_oficina.md`** (132 líneas) — 11 bloques: víspera (confirmaciones, material físico + digital), día D (llegada, instalación PC a PC, formación por usuario, cierre grupal), post-setup (log, calendario seguimiento).
5. **`acuerdo_simple.md`** (181 líneas) — versión imprimible 10 cláusulas (duración, alcance, coste 0, propiedad datos, compromisos, qué pasa día +30, resolución anticipada, naturaleza no-contractual) + versión "palabra de familia" via email + lo que el acuerdo NO debe contener.
6. **`metricas_piloto.md`** (137 líneas) — 3 métricas core (horas ahorradas auto-reporte, satisfacción 1-10, intención re-uso) + 4 secundarias (uso, errores, velocidad teclado vs dictado, precisión percibida) + calendario semanal de toques + plan de caso de estudio + antipatrones de medición.
7. **`faq_anticipadas.md`** (167 líneas) — 10 preguntas probables (diferencia con Siri, qué pasa si me canso, privacidad, hardware, curva aprendizaje empleados, ahorro real, extender mes gratis, precio post-piloto, valenciano, integración Sage/A3/Presto) + 5 bonus + reglas de respuesta.

Total: 948 líneas (sin contar este report).

## Verificación

- **Acceptance 1 (7 documentos en path correcto):** PASS — `ls /home/Projects/parla/clientes/piloto_construccion_familiar/` muestra los 7 .md + este report.
- **Acceptance 2 (contenido alineado con idea-142):**
  - Apertura/Valor/Oferta/Cierre del script_llamada: PASS — bloques min 0:30, 1:15, 2:15, 2:45 cubren los 4 puntos.
  - Email post-llamada con detalles: PASS — 3 variantes según ramificación de la llamada.
  - Propuesta 1pag llevable a reunión: PASS — formato 1 A4, sin jerga, tabla comparativa.
  - Checklist setup oficina: PASS — qué llevar (Bloques 2-3) + qué pedir cliente (Bloques 1-4).
  - Gentleman's agreement 30-60 días: PASS — duración 30 ampliable a 60, sin contrato formal, no-penalización.
  - KPIs (horas, satisfacción, intención re-uso): PASS — métricas 1, 2, 3 son exactamente esas 3.
  - 10 FAQ anticipadas: PASS — 10 + 5 bonus.
- **Coherencia cross-link interna:** PASS — cada documento referencia los demás del paquete cuando aplica.
- **Coherencia con repo existente:** PASS — pricing alineado con `pricing/pricing_recomendado.md` Tier 2 (€2.250 setup + €200/mes), decisión hardware on-prem comprado por cliente (decisión 2026-05-13 `memoria/decisiones.md`), cross-link a idea-131 (B2B on-prem) e idea-132 (vertical pack construcción).

## Decisiones de diseño relevantes

- **Modalidad LIGHT por defecto** (instalación directa sobre PCs, sin mini-server) — minimiza fricción Fase 0. Mini-server se ofrece solo si tras mes 1 amplían a 5+ puestos. Documentado en `acuerdo_simple.md` §"Modalidad de despliegue".
- **Precio post-piloto NO en propuesta ni en email** — solo se cita rango (€100-300/mes) en FAQ #8 si el familiar pregunta directamente, y siempre con "lo concretamos al final del mes". Evita anchorear conversación comercial antes de tiempo.
- **Métricas vía auto-reporte WhatsApp**, no telemetría que extraiga datos del cliente — preserva la promesa de privacidad on-prem (consistente con feedback de privacidad de Marc).
- **Acuerdo formal opcional**, versión "palabra de familia + email" como default — encaja con el contexto familiar y no pone fricción legal en una conversación de buena fe.

## Follow-up sugerido (NO ejecutados)

- **`templates_outreach.md`** (validación 6 semanas con 5-8 pymes) — `validacion/plan_pymes_piloto.md` lo lista como pendiente para semana 1 de Fase 0. Distinto del piloto familiar (que ya está cualificado) pero del mismo flujo comercial.
- **Plantillas dictado vertical construcción** — idea-132 acepta crear: parte trabajadores, parte material, presupuesto rápido, email cliente, notas obra. Útiles **antes** del setup en la oficina para llevar 3 documentos contextuales (mencionados en checklist Bloque 3).
- **Glosario construcción ES/CA inicial** — idea-132. Lista de ~50-100 términos (hormigón, encofrado, vigueta, replanteo, pal, rajola, etc.) que el daemon debe absorber antes del día D.
- **Seguimiento_semanal.md plantilla** — mencionada en `metricas_piloto.md` pero NO creada (parsimonia: nace día +7 cuando hay primeros datos).
- **Actualizar estado idea-142** a `completada` y archivar a `ideas/archivo/2026/` — eso lo hace el orquestador, no el worker.

## Notas para el orquestador

- Ningún cambio fuera del working_dir.
- Ninguna escalación necesaria. Tarea íntegramente documental.
- Marc tiene el material listo "al despertar" como pedía la tarea — incluyendo respuestas internalizables a 15 preguntas distintas y un acuerdo imprimible cláusula a cláusula.
- El paquete asume `idea-131` Fase 0 (validación mercado) puede saltarse para este piloto familiar concreto, dado que ya hay match cualificado por relación personal. Marc decide si pre-valida con la lista de `plan_pymes_piloto.md` en paralelo o va directo al familiar.
