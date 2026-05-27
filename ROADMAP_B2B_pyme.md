# ROADMAP — parla

_Generado por `roadmap_generator.py` desde [`idea-125-dictado-voz-cursor-pyme-es.md`](/home/claude/ideas/sistema/idea-125-dictado-voz-cursor-pyme-es.md) — 2026-05-13._

## Visión

Servicio dictado por voz al cursor para pymes españolas con privacidad local (EU AI Act compliant). Fase 0 empaqueta oido_daemon existente en producto instalable; Fase 1 valida modelo on-prem en 5-10 pymes Valencia; Fase 2 (condicional) co-brand hardware.

## Fases

### Fase 0 — Producto instalable (Windows/Linux) con Whisper + post-procesamiento

**Objetivo**: Empaquetar oido_daemon en app standalone con Whisper local, LLM post-procesado, hotkey configurable y salida al cursor. Validar latencia y accuracy en hardware típico pyme.

**Duración estimada**: 1-2 meses

**Criterios de éxito**:

- Instalador Windows ejecutable, app lanza sin errores, hotkey funciona
- Instalador Linux (AppImage) ejecutable, hotkey funciona en X11
- Whisper-base transcribe audio ≤3s en CPU típico pyme
- LLM post-procesamiento corrige gramática >80% en ES/CA/VA
- Salida texto directo al cursor (tested en 5 apps escritura)
- Demo gratuita 1 semana sin registro email
- Documentación setup y configuración hotkey (ES/CA/VA)

**Trigger paso a siguiente fase**: Fase 0 cumple criterios éxito + feedback Marc validado. 1 cliente Fase 1 potencial identificado.

**Métricas**:

- Latencia transcripción P95 (segundos)
- Accuracy gramática post-procesamiento (%)
- Crashes 0 en 1000 transcripciones test
- Idiomas soportados (ES, CA, VA)

### Fase 1 — Despliegue on-prem en hardware recomendado + validación pyme

**Objetivo**: Crear playbook deployment en NUC/Beelink/Jetson, validar latencia real en hardware cliente, cerrar 3-5 pymes Valencia (construcción, contables, legal) con modelo setup €1.5-3k + recurrencia €100-300/mes.

**Duración estimada**: 3-6 meses

**Criterios de éxito**:

- Playbook deployment ansible + documentación (testado 3x hardware diferente)
- Hardware pricing sheet con 4 opciones (NUC, Beelink, Jetson, RTX)
- Onboarding remoto video + guía (30 min setup)
- 3-5 clientes pyme cerrados con contrato / instalación completada
- Latencia P95 <2s en hardware cliente real
- Métricas uso mensual por cliente (transcripciones, usuarios, idiomas)

**Trigger paso a siguiente fase**: 5+ clientes en producción + €3-5k MRR recurrente validado. Feedback mercado + datos competencia Wispr Flow ES.

**Métricas**:

- Clientes pagando (número)
- MRR recurrente (€)
- Latencia P95 en hardware cliente (segundos)
- Churn mensual (%)
- Customer satisfaction (NPS o simple 1-5)

### Fase 2 — Co-brand hardware + escalada (condicional si Fase 1 tracciona)

**Objetivo**: Si 10+ clientes pagando + €5k+ MRR: partnership Logitech/Keychron ratón voice edition, o manufactura china own-brand. Expandir a ES completo + European markets.

**Duración estimada**: 12-18 meses

**Criterios de éxito**:

- Partnership letter-of-intent firmada (Logitech / Keychron / fabricante)
- CAD design ratón + especificación técnica (micrófono, conectividad)
- MOQ y pricing proyectado (unitario + margen)
- Roadmap hardware (timeline manufactura, certifications)

**Trigger paso a siguiente fase**: 50+ usuarios pagando + strong market validation. Presupuesto inversión hardware confirmado por Marc.

**Métricas**:

- Partnership firmado (bool)
- SKU hardware en diseño (fase)
- Proyección usuarios Y3 (número)
- Market share ES vs Wispr Flow, otros competidores (%)

## Tareas atómicas

| # | ID sugerido | Fase | Título | est. min | Deps |
|---|-------------|------|--------|----------|------|
| 1 | `oido-pro-01-auditar-daemon` | fase_0 | Auditar estado actual oido_daemon y dependencias | 30 | — |
| 2 | `oido-pro-02-disenar-arch-empaquetado` | fase_0 | Diseñar arquitectura empaquetado (Windows/Linux) | 35 | oido-pro-01-auditar-daemon |
| 3 | `oido-pro-03-integrar-whisper-local` | fase_0 | Integrar Whisper-base local (descargar modelos, wrapper) | 40 | oido-pro-02-disenar-arch-empaquetado |
| 4 | `oido-pro-04-integrar-llm-postproceso` | fase_0 | Integrar LLM post-procesamiento (corrección gramática ES/CA/VA) | 45 | oido-pro-03-integrar-whisper-local |
| 5 | `oido-pro-05-hotkey-configurable` | fase_0 | Implementar hotkey configurable (botón ratón, tecla personalizada) | 40 | oido-pro-02-disenar-arch-empaquetado |
| 6 | `oido-pro-06-salida-cursor-windows` | fase_0 | Implementar salida texto al cursor (Windows API) | 35 | oido-pro-02-disenar-arch-empaquetado |
| 7 | `oido-pro-07-salida-cursor-linux` | fase_0 | Implementar salida texto al cursor (Linux X11/Wayland) | 35 | oido-pro-02-disenar-arch-empaquetado |
| 8 | `oido-pro-08-instalador-windows` | fase_0 | Crear instalador Windows (NSIS o Inno Setup) | 45 | oido-pro-03-integrar-whisper-local, oido-pro-04-integrar-llm-postproceso, oido-pro-05-hotkey-configurable, oido-pro-06-salida-cursor-windows |
| 9 | `oido-pro-09-instalador-linux` | fase_0 | Crear instalador Linux (AppImage) | 40 | oido-pro-03-integrar-whisper-local, oido-pro-04-integrar-llm-postproceso, oido-pro-05-hotkey-configurable, oido-pro-07-salida-cursor-linux |
| 10 | `oido-pro-10-testing-latencia` | fase_0 | Testing latencia en hardware típico pyme (CPU modest) | 45 | oido-pro-03-integrar-whisper-local, oido-pro-04-integrar-llm-postproceso |
| 11 | `oido-pro-11-docs-usuario-es` | fase_0 | Documentación setup usuario (ES/CA/VA) | 35 | oido-pro-08-instalador-windows, oido-pro-09-instalador-linux |
| 12 | `oido-pro-12-demo-gratuita` | fase_0 | Crear demo gratuita funcionable (trial 1 semana, sin registro) | 30 | oido-pro-08-instalador-windows, oido-pro-09-instalador-linux |
| 13 | `oido-pro-13-playbook-deployment` | fase_1 | Crear playbook deployment on-prem (Ansible/script bash) | 45 | oido-pro-02-disenar-arch-empaquetado |
| 14 | `oido-pro-14-hardware-pricing-sheet` | fase_1 | Crear hardware pricing sheet (4 opciones NUC/Beelink/Jetson/RTX) | 30 | — |
| 15 | `oido-pro-15-onboarding-video` | fase_1 | Crear onboarding remoto (video tutorial + guía escrita) | 45 | oido-pro-13-playbook-deployment |
| 16 | `oido-pro-16-pricing-contrato` | fase_1 | Crear pricing sheet + contrato SaaS/on-prem simple | 35 | oido-pro-14-hardware-pricing-sheet |
| 17 | `oido-pro-17-customer-pipeline` | fase_1 | Outreach inicial a 5-10 pymes Valencia (construcción, contables, legal) | 45 | oido-pro-12-demo-gratuita, oido-pro-16-pricing-contrato |
| 18 | `oido-pro-18-testing-hw-real` | fase_1 | Testing latencia en hardware cliente real (NUC/Beelink) | 45 | oido-pro-13-playbook-deployment, oido-pro-10-testing-latencia |
| 19 | `oido-pro-19-llm-accuracy-ca-va` | fase_1 | Validación LLM post-procesamiento: accuracy CA/VA | 40 | oido-pro-04-integrar-llm-postproceso |
| 20 | `oido-pro-20-competitive-analysis` | fase_1 | Análisis competencia: Wispr Flow, SuperWhisper status 2026 | 35 | — |

## Riesgos identificados

- **Wispr Flow lanza versión española antes de cierre Fase 1** → Acelerar timeline Fase 0 (2 meses → 6 semanas). Diferenciar por profundidad local (catalán, valenciano, jerga construcción/contables/legal). Validar mercado early (demo pilotos semana 4-6). Considerar pre-venta si Wispr Flow anunciado.
- **Pyme target no entiende valor 'privacidad local' vs. ChatGPT cloud** → Demo comparativa clara: 'Tus voces nunca salen de tu oficina vs. OpenAI guarda tu voz'. Marketing GDPR/EU AI Act compliance. Educación: webinar/PDF sobre datos sensibles (nóminas contables, datos clientes despachos).
- **Latencia Whisper >3s en CPU modest → experiencia mala** → Testing temprano (semana 6 Fase 0) en hardware real pyme. Si latencia excede specs: Whisper-tiny (más rápido, accuracy similar), cuantización LLM, caché resultados (si frase idéntica, reutilizar). SLA latencia <2s Fase 1 no-negociable.
- **Hardware on-prem (NUC/Beelink) stock agotado o precio sube** → Validar disponibilidad + precio actual ANTES de vender. Alternativas: Mini-PC genérico (Amazon, Newegg), local físicos Valencia (Tiendas IT). Contrato cliente: 'Hardware a cargo cliente, spec recomendada es NUC/Beelink, aprobamos alternativas compatibles'.
- **Dependencia MX Master (botón ratón) → no funciona con otros ratones** → Hotkey configurable (shift+F12, etc) como fallback. Si cliente tiene ratón diferente, tecla = solución. Fase 1: documentar compatibilidad ratones (MX Master OK, generic USB OK, wireless OK).
- **Soporte multiidioma (ES/CA/VA) requiere esfuerzo mantenimiento alto** → LLM prompt centralizado (1 fichero). Prompt-engr en persona bilingüe Marc o contratar. Test automation por idioma (dataset 50 frases por idioma). Fase 2 opcional: expandir a gallego/euskera si demanda.
- **Cliente cierra pyme o cambia de actividad → churn inesperado** → Contrato flexible 30 días. Mensual, no anual. Feedback anual: ¿qué problemas resolvemos? Pivote rápido. En Fase 2 expandir mercado (abogados, inmobiliarias, peluquería con citas).

## Métricas globales del proyecto

- Fases completadas on-time (Fase 0 en 1-2 meses, Fase 1 en 3-6 meses desde Fase 0)
- Latencia P95 transcripción + post-procesamiento (target: <3s Fase 0, <2s Fase 1)
- LLM accuracy corrección gramática ES/CA/VA (%)
- Hardware soportado validado (NUC, Beelink, Jetson, RTX)
- Clientes en Fase 1 cerrados (número, meta 3-5 año 1)
- MRR recurrente (€, meta €3-5k fin Fase 1)
- Churn mensual (%)
- Customer satisfaction / NPS
- Cobertura idiomas (ES, CA, VA minimum; gallego/euskera future)

## Cómo se generó

Este ROADMAP nace del prompt estructurado de `roadmap_generator.py`.
Idea fuente: `idea-125` (/home/claude/ideas/sistema/idea-125-dictado-voz-cursor-pyme-es.md).
Los borradores de tareas atómicas viven en el `working_dir` del worker que
ejecutó la generación. Marc revisa, ajusta acceptance, y promueve con
`cp <borrador>.md /home/claude/queue/todo/` (asignando `id` con timestamp
y eliminando el flag `borrador: true`).

