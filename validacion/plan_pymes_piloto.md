# Plan de validación con pymes piloto — Fase 0

**Objetivo**: validar mercado de Parla con 3-5 pymes locales (Valencia/Castellón) **antes** de invertir tiempo serio en empaquetado profesional (Fase 0). Confirmar que el dolor (escritura lenta, mucho teclado) es real, que el precio (€15-25/usuario/mes o setup on-prem €1.500-3.000) es absorbible, y que la propuesta de privacidad local es valorada.

Si Fase 0 valida → arrancar Fase 1 con confianza. Si no valida → pivote (otro nicho, otro pricing, otro formato) o abandono argumentado.

---

## 1. Sectores priorizados y criterios de selección

Sectores donde el pain point es real (alto volumen de texto + perfiles que no son nativos digitales + sensibilidad a privacidad):

| Sector | Por qué buen piloto | Señales de fit |
|---|---|---|
| Despachos contables / asesorías pyme | Alto volumen de informes, escritos a Hacienda, comunicaciones cliente. Edad media >45. Privacy alta (datos fiscales clientes). | 10-30 empleados, sin departamento IT propio, cliente medio español/valenciano. |
| Despachos legales pyme (abogados, gestores) | Informes, escritos, contratos. Dictado ya cultural (Dragon). Privacy crítica (secreto profesional). | 5-20 empleados, especializados (familia, mercantil, laboral). |
| Constructoras pyme con admin propio | Partes de obra, presupuestos, comunicaciones con promotores. Perfiles 50+ que odian teclear. | 20-80 empleados (10-15 en oficina), idioma valenciano frecuente. |
| Agencias inmobiliarias medianas | Descripciones de inmuebles, comunicaciones con vendedores/compradores. Volumen alto. | 5-15 empleados, multi-oficina, propietario fundador con presencia. |
| Clínicas privadas pequeñas | Médicos dictan informes (uso Dragon o nada). Privacy LOPD-RGPD crítica. | 3-10 médicos, traumatología/reumatología/dermatología (mucho informe). |

Criterio de descarte rápido: empresas <5 empleados (no hay caso de uso multi-usuario, mejor ir a B2C); empresas >100 empleados (ciclo de venta largo, ya tienen IT, fuera de target Fase 1).

---

## 2. Lista de candidatos target (5-8 pymes)

> **Nota**: lista de **perfiles candidato** con criterios de búsqueda concretos. Marc valida/rellena cada fila con nombre real antes de contactar (vía LinkedIn Sales Navigator, directorios de colegios profesionales, o referencia personal). No se inventan datos de contacto reales aquí — eso entra en la fase de prospección de la semana 1.

| # | Perfil candidato | Ubicación | Sector | Tamaño aprox | Contacto inicial sugerido |
|---|---|---|---|---|---|
| 1 | Asesoría fiscal-contable familiar 2ª generación | Valencia ciudad o área metropolitana | Contable / asesoría pyme | 12-25 empleados | LinkedIn Sales Navigator: filtro "asesoría fiscal" + Valencia + 11-50 empleados. Contactar a socio director vía InMail. |
| 2 | Despacho legal mercantil/laboral pyme | Castellón ciudad | Legal pyme | 5-15 abogados | Colegio de Abogados de Castellón (directorio público) → filtrar despachos 5-15 letrados. Llamada directa a recepción pidiendo socio gestor. |
| 3 | Constructora pyme con obra residencial | Valencia/Castellón | Construcción | 30-80 empleados (8-15 en oficina) | Web de la empresa + LinkedIn del jefe de oficina técnica o aparejador jefe. Email directo. |
| 4 | Gestoría administrativa generalista (autónomos + pyme) | Provincia de Valencia (l'Horta) | Contable / legal | 8-20 empleados | LinkedIn: "gestoría administrativa" + área Valencia. Mensaje personalizado al titular colegiado. |
| 5 | Clínica privada multi-especialidad | Valencia o Castellón | Clínica privada pyme | 4-10 médicos titulares | Web de la clínica → contactar director médico o director gerente. Email + segunda llamada. |
| 6 | Inmobiliaria con 2-3 oficinas locales | Valencia ciudad | Agencia inmobiliaria | 8-15 agentes | LinkedIn del CEO/fundador. Acercamiento via referencia común si existe; si no, email frío con asunto específico. |
| 7 | Despacho legal especializado familia/herencias | Valencia | Legal pyme | 4-10 personas | Colegio de Abogados de Valencia + filtro Derecho Civil/Familia. Llamada directa. |
| 8 | Asesoría con presencia en valenciano | Castellón (interior, La Plana) | Contable / asesoría | 6-15 empleados | Referencia local (cámara de comercio, asociación AECTA). Cita presencial. |

**Notas operativas para la prospección**:

- **No contactar más de 2 candidatos del mismo sector el mismo día** — preservar el ancho de banda de respuestas para entender feedback por sector.
- **Mensaje inicial debe ser explícitamente NO-venta**: pedir 20 min para mostrar una herramienta en desarrollo y recoger su opinión. Frase clave: "no te voy a vender nada, te enseño esto y me dices si te parece útil".
- **Idioma**: empezar en castellano. Si el contacto cambia a valenciano espontáneamente, seguir en valenciano (refuerza el diferencial local).
- **Ángulo según sector**:
  - Contable/legal/clínica: privacidad de los datos del cliente.
  - Construcción/inmobiliaria: velocidad y reducción de fricción a la hora de pasar texto al ordenador.

---

## 3. Plan de demo

Dos formatos, según preferencia del candidato:

### 3.1 Demo virtual (videocall, 20 min)

Estructura:

1. **0-2 min** — agradecimiento + recordatorio "no es venta, es validación".
2. **2-5 min** — pregunta abierta sobre su día a día con texto: "¿cuánto tiempo al día calculas que pasáis escribiendo en el ordenador?". Escuchar antes de demostrar.
3. **5-12 min** — Marc comparte pantalla y dicta en directo con `oido_daemon`:
   - Documento contextual al sector del candidato (carta a Hacienda si es asesoría, parte de obra si es constructora, informe médico si es clínica).
   - Mostrar PTT con botón ratón (impacto visual alto).
   - Mostrar corrección automática (mayúsculas, puntos, signos).
   - Mostrar idioma castellano + valenciano (si el sector aplica).
4. **12-17 min** — el candidato hace 3 preguntas en alto mientras Marc transcribe. Mide latencia y precisión percibida.
5. **17-20 min** — cuestionario rápido (§4) + cierre. Agradecer y prometer seguimiento.

Material a llevar: presentación de 1 sola slide con propuesta de valor (3 bullets, sin logos), `oido_daemon` configurado, 2-3 plantillas de documento por sector.

### 3.2 Demo presencial (oficina del candidato, 30 min)

Igual estructura que la virtual pero con el candidato **probando 5 min** él mismo:

- Marc lleva portátil con setup completo + ratón con PTT.
- El candidato (o un empleado señalado por él) dicta 2-3 frases.
- Si es posible: dictar un texto que YA tenían que escribir hoy (parte de obra real, informe real anonimizado).

Métricas a medir **siempre**:

- Palabras/minuto del candidato escribiendo a teclado (baseline) vs dictando.
- Satisfacción 1-10 al final ("si esto estuviera disponible mañana, ¿cómo lo valorarías?").
- Willingness to pay (cuestionario §4 pregunta 6).

---

## 4. Cuestionario post-demo (10 preguntas)

Se aplica al final de la demo, máximo 5 min. Anotar respuestas en bruto, no resumir en el momento.

1. **Volumen**: ¿cuántas horas a la semana calculas que vosotros (o un empleado típico) pasáis escribiendo en el ordenador?
2. **Pain ranking**: del 1 al 10, ¿cuánto te frustra el ritmo al que escribes/escriben tus empleados?
3. **Soluciones actuales**: ¿usáis ya algo (Dragon, dictado del móvil, Google Docs voz)? ¿Por qué sí/no funciona?
4. **Pricing modelo SaaS**: si esto fuera una app que pagáis €20/usuario/mes (sin compromiso anual), ¿lo probarías para 1-2 personas el primer mes? (Sí / no / depende)
5. **Pricing modelo on-prem**: si fuera un setup completo (instalado y mantenido por nosotros, datos sin salir de tu oficina) por €2.000 inicial + €200/mes, ¿te interesaría? (Sí / no / depende)
6. **Anchor de precio**: ¿cuál sería el precio mensual por usuario que te parecería "barato"? ¿Y "caro pero asumible"? ¿Y "imposible"?
7. **Modalidad preferida**: ¿prefieres pagar por usuario (cloud/local app) o pagar un setup y luego mantenimiento (on-prem)?
8. **Privacidad**: en una escala 1-10, ¿cuánto pesa para ti que las voces y textos no salgan de tu oficina? ¿Por qué?
9. **Decisión de compra**: ¿quién aprueba un gasto de este tipo en vuestra empresa? ¿Tú? ¿Socios? ¿Comité? ¿Cuánto tiempo tardaría una decisión?
10. **Piloto pagado**: si te ofreciera un mes de prueba completa con setup incluido por €500-1.000 (no compromiso después), ¿lo aceptarías? Si no, ¿qué condiciones harían que sí?

---

## 5. Métricas de éxito Fase 0

| Métrica | Umbral mínimo (Fase 0 valida) | Umbral cómodo |
|---|---|---|
| Pymes contactadas | 8-10 | 12-15 |
| Demos realizadas (virtual o presencial) | 3 | 5 |
| Confirman interés serio (pregunta 4 o 5 = sí + pregunta 10 = sí o "depende del precio") | 2 | 3-4 |
| Aceptan piloto pagado (€500-1.000) | 1 | 2 |
| Satisfacción media demo (1-10) | ≥7 | ≥8 |
| Willingness to pay media (anchor "asumible" pregunta 6) | ≥€15/usuario/mes | ≥€20/usuario/mes |

**Decisión post-Fase 0**:

- ≥ umbral mínimo en TODAS las métricas → arrancar Fase 1 con el piloto pagado como primer cliente.
- Falla en 1-2 métricas → entender por qué (¿precio? ¿formato? ¿sector?) y reorientar antes de Fase 1.
- Falla en ≥3 métricas → considerar pivote (ver §7) o pausa.

---

## 6. Timeline (6 semanas)

| Semana | Actividad | Entregable |
|---|---|---|
| 1 | Prospección: rellenar tabla §2 con nombres reales, validar contactos en LinkedIn / colegios profesionales, redactar 3 plantillas de email/InMail por sector. | Lista nominal de 10-12 candidatos con contacto cualificado. |
| 2 | Outreach: enviar mensajes iniciales (5-7 por día max), agendar 5 demos. | 5 demos en calendario antes del día 14. |
| 3-4 | Ejecutar 5 demos (3-4 virtuales, 1-2 presenciales si caen cerca). Recoger cuestionarios. | 5 cuestionarios completos + notas de demo. |
| 5 | Análisis: tabular respuestas, calcular métricas §5, identificar el mejor candidato a piloto pagado. | Documento de feedback agregado + recomendación piloto. |
| 6 | Decisión: ¿Fase 1 GO? ¿Pivote? ¿Pausa? Si GO: cerrar piloto pagado con el mejor candidato. | Decisión escrita + contrato piloto (si aplica). |

---

## 7. Plan B — qué hacer si Fase 0 NO valida

Si la conclusión de la semana 5 es que el mercado pyme local no responde:

1. **Pivote de sector** (más fácil): probar mismos materiales con **autónomos profesionales** (abogados solos, médicos solos, peritos, traductores) — modelo B2C €15-25/mes sin setup on-prem. Coste reorientación bajo (1-2 semanas).

2. **Pivote geográfico**: probar Barcelona / Madrid con foco en despachos legales medianos (más maduros digitalmente, más pagar por software). Mismos materiales, otra prospección.

3. **Pivote de propuesta de valor**: si las respuestas indican que el dolor no es velocidad sino **calidad** (corrección, formato profesional, multilingüe), reorientar mensaje a "asistente de escritura para profesionales" en vez de "dictado rápido".

4. **Pausa / abandono argumentado**: si las 5 demos arrojan satisfacción media <5/10 o willingness to pay <€10, abandonar el proyecto. Documentar lecciones en `/home/claude/memoria/incidencias.md` y archivar `idea-125`. Sin coste hundido (Fase 0 son 6 semanas de tiempo, no inversión cash).

Decisión binaria GO/NO-GO al final de la semana 6 — **no entrar en Fase 1 sin métricas mínimas cumplidas**.

---

## 8. Riesgos de la validación

- **Sesgo de demo**: Marc dicta muy bien porque lleva meses usándolo; un empleado pyme novato tendrá curva de aprendizaje. **Mitigación**: cada demo presencial debe incluir 5 min en los que el candidato (no Marc) prueba; medir frustración real.
- **Sesgo de cortesía**: el candidato dice 7/10 por educación. **Mitigación**: pregunta 10 (piloto pagado) es el único filtro fiable — quien pone dinero valida; quien solo dice "bonito" no cuenta.
- **Confusión con productos cloud existentes**: el candidato puede pensar "ya tengo Google dictado en el móvil". **Mitigación**: en la demo enfatizar 3 diferenciales: corrección con LLM local, salida directa al cursor, sin Internet.
- **Privacy no es factor**: posible que la pyme media no priorice tanto la privacidad como Marc cree. **Mitigación**: pregunta 8 es diagnóstica — si la media sale ≤6, replantear el ángulo comercial (velocidad, no privacy).
- **Decision-maker ausente**: hablamos con socio joven, pero decide su padre. **Mitigación**: pregunta 9 identifica decisor; pedir contacto directo si el entrevistado no decide.
- **Pyme valenciana muy reacia a software**: existe el riesgo cultural. **Mitigación**: si sale, no es problema de Parla sino del segmento; pivote a B2C autónomo (§7.1).

---

## 9. Anexos pendientes

Se generan en la semana 1, no antes:

- `templates_outreach.md` — 3 plantillas de email/InMail por sector (contable, legal, construcción).
- `material_demo.md` — guion de demo paso a paso + 3 documentos contextuales por sector.
- `feedback_demos.md` — log de cada demo realizada con cuestionario + observaciones.

Estos artefactos viven en `validacion/` pero no se crean por adelantado (parsimonia — nacen cuando se necesitan).
