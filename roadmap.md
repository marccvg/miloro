# Roadmap — Parla

Adaptado de `idea-125`. Tres fases con triggers y KPIs por fase. Fuente original en `/home/claude/ideas/sistema/idea-125-dictado-voz-cursor-pyme-es.md` — no modificar el original; este fichero es la vista operativa del proyecto.

## Fase 0 — Empaquetado software (1-2 meses)

**Objetivo**: convertir lo que YA funciona en el laptop de Marc (`oido_daemon` + PTT MX Master) en una app instalable y demostrable a clientes.

Entregables:

- App instalable Windows y Linux (Mac más tarde).
- Whisper local + LLM post-procesado (corrección gramática, formato).
- Hotkey configurable (botón ratón, tecla, combinación).
- Salida: texto directo al cursor donde esté.
- Instalador con setup wizard.

KPIs Fase 0:

- 1 instalador funcional Windows + 1 Linux.
- Demo grabada en vídeo de <3 min mostrando uso real.
- Latencia <2 s desde fin de habla hasta texto en pantalla en hardware típico pyme (i5 8ª gen, sin GPU).

Modelo precio orientativo: €15-25/usuario/mes (por validar en Fase 1).

### Triggers para arrancar Fase 0

- Primer cliente Fase 1 plan estratégico cerrado (track record real).
- Marc tiene 1-2 meses libres post-piloto inicial.
- Mercado Wispr Flow ES sigue vacío.

## Fase 1 — Setup llave en mano on-prem (3-6 meses)

**Objetivo**: vender setup completo en 3-5 pymes Valencia/Castellón. Modelo "servidor on-prem que NO fabricas".

Cliente compra mini-server existente (recomendado por nosotros, NO fabricado); nosotros instalamos, configuramos, mantenemos.

Hardware recomendado (cliente compra directo o revendemos con 15-20% margen):

| Hardware | Precio | Capacidad |
|---|:-:|---|
| Intel NUC 13 (CPU only) | €400-600 | Whisper-base + Phi-3 local, 5-10 usuarios |
| Beelink SER7 (Ryzen 7) | €500-700 | Más rápido CPU |
| NVIDIA Jetson Orin Nano | €500-800 | GPU real, Whisper-medium tiempo real |
| Mini-PC con RTX 3060 | €700-1000 | Premium |

Pricing:

- Setup inicial (1 vez): €1.500-3.000 configuración + entrenamiento usuarios.
- Mantenimiento mensual: €100-300/mes (€400-600 con SLA 24h).
- Hardware: cliente compra directo (recomendamos) o lo revendemos con margen.

Argumento principal de venta — privacy local:

> "Tus voces nunca salen de tu oficina. El servidor está en tu sala técnica, los datos jamás llegan a Internet. AI Act compliant por diseño."

Diferencial real vs Wispr Flow (cloud USA), Otter (cloud USA), Dragon (MS cloud).

Target: 3-5 pymes Valencia/Castellón (construcción, contables, despachos legales pequeños).

Económica orientativa año 2-3 a 10 clientes: €20-35k setup + €12-36k/año recurrente = €32-71k/año, sin gestión de hardware ni stock.

KPIs Fase 1:

- 3 pymes piloto con setup completo y al menos 30 días de uso real.
- 5+ usuarios activos diarios por pyme.
- NPS o equivalente >7/10.
- Tasa de retención mes 3 >80%.

### Triggers para pasar a Fase 2

- 50+ usuarios pagando.
- Feedback claro sobre qué hardware/forma factor pedirían.
- Caja suficiente para inversión MOQ co-brand (~€20-50k).

## Fase 2 — Co-brand hardware (12-18 meses, solo si Fase 1 tracciona)

**Objetivo**: cuando hay tracción real, ratón con micrófono integrado co-branded (NO LLM embarcado — el LLM sigue en el PC). Coste reducido vs LLM embarcado.

Opciones:

- Co-brand con Logitech / Keychron / Ajazz: SKU "voice edition" con su manufactura y nuestro firmware/marca.
- Manufactura china con marca propia si SaaS dio caja suficiente.

KPIs Fase 2:

- Acuerdo firmado con fabricante.
- Primera tirada vendida (objetivo orientativo: 500-1000 unidades).
- Margen por unidad >30%.

## Tareas atómicas próximas

Tareas que se desbloquean tras este `PARLA_INIT01`:

- **`PARLA_VALIDATION_PLAN01`** — plan estructurado de validación con 3-5 pymes locales (criterios de selección, guion entrevista, criterios go/no-go). Output en `validacion/`.
- **`PARLA_DEMO_PACKAGE01`** — paquete portable demo (instalador o script de arranque que permita enseñar el producto en un laptop ajeno en 2 min). Output en `demo/`.
- **`PARLA_PRICING_RESEARCH01`** — análisis pricing competidores (Wispr Flow, SuperWhisper, MacWhisper, Dragon, Otter) y estrategia €15-25/usuario/mes vs setup on-prem. Output en `pricing/`.

Estas tres son paralelizables. La de validación es la que más bloquea inversión seria — confirma que el hueco de mercado existe antes de Fase 0 grande.

## Anti-patrones registrados

De `idea-125`:

- **NO hacer hardware desde cero en Fase 0/1**. Whisper-medium ~1.5GB RAM no cabe en ratón sin SoC caro; manufactura ratón 12-18 meses + MOQ + €50-200k.
- **NO arrancar Fase 0 hasta tener 1 cliente Fase 1 plan estratégico cerrado**. Track record real antes que producto.
- **NO prometer latencias sin probar en hardware típico pyme** (PCs viejos sin GPU).

## Riesgos / mitigaciones

- **Wispr Flow saca versión ES** → aceleración a 6 meses. Mitigación: profundidad local (catalán, valenciano, jerga construcción/legal/contable ES).
- **Pyme target no entiende valor** → educación + demo gratuita primera semana.
- **Privacidad mal explicada → cliente prefiere ChatGPT cloud que ya conoce** → marketing "tus voces no salen del PC, EU AI Act compliant" muy claro y repetido.
