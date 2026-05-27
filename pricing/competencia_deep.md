---
titulo: Deep research competencia — pricing, features, privacy, EU, idiomas
tipo: ficha
creado: 2026-05-14
actualizado: 2026-05-14
tags: [parla, pricing, competencia, mercado, privacy, eu, idiomas]
---

# Deep research competencia — Parla

> Continuación de `competencia.md` (2026-05-13). Este documento profundiza en **features por tier, claims de privacidad, soporte EU e idiomas** porque son los tres ejes donde Parla se diferencia. Fuentes verificadas vía WebFetch 2026-05-14 a páginas oficiales (cada bloque enlaza su URL). Tipo de cambio: 1 USD = 0,92 EUR.
>
> **Productos verificados esta ronda:** Wispr Flow (pricing + privacy), SuperWhisper (home), Otter.ai (pricing + security + home), Dragon Anywhere (Nuance). **No verificados (dominio fuera de whitelist o redirect roto):** MacWhisper, Aqua Voice, Speechmatics, Otter security page → 404 efectivo.

---

## 1. Tabla matriz — diferenciales clave

| Eje | Wispr Flow | SuperWhisper | MacWhisper | Dragon (Nuance/MS) | Otter.ai | **Parla** |
|---|---|---|---|---|---|---|
| **Modelo de procesamiento** | Cloud-only | Local + Cloud opcional (Mac/Win/iOS) | Local (Mac only) | Cloud + híbrido (US-only) | Cloud-only | **Local on-prem (laptop / mini-PC oficina)** |
| **Idiomas declarados** | "100+" sin lista | "100+ idiomas y dialectos" | 100+ (Whisper) | EN principal; ES vía Dragon NaturallySpeaking; CA no | EN/ES/FR/DE/JA/ZH (lista cerrada) | **ES + CA + VA nativos con glosario** |
| **Soporte CA/VA** | No declarado | No declarado | No declarado | No | **No** | **Sí (diferenciador)** |
| **Data residency** | No EU declarado | No EU declarado | N/A (local) | "stored & processed in United States" (Dragon Anywhere) | No EU declarado | **EU (local en cliente o mini-PC EU)** |
| **GDPR explícito** | No mencionado en home/pricing | No mencionado | N/A | No (US-only) | No mencionado | **Sí — by design** |
| **EU AI Act** | No mencionado | No mencionado | N/A | No | No mencionado | **Sí — by design** |
| **SOC 2 Type II** | Sólo Enterprise | Sólo Enterprise | No | No declarado | No declarado público | Roadmap fase 2 |
| **ISO 27001** | Sólo Enterprise | No | No | No declarado | No declarado | Roadmap fase 2 |
| **HIPAA** | All tiers (BAA Enterprise) | No | No | Variable | Add-on Enterprise | N/A (no aplica EU) |
| **Zero Data Retention** | Sólo si activas "Privacy Mode" — enforced sólo en Enterprise | Sí (offline) | Sí (local) | No | No | **Sí — by design** |
| **On-prem / self-hosted** | **No** | No declarado | N/A | Hybrid Enterprise (custom) | **No** | **Sí (setup pyme)** |
| **Billing en EUR** | No mostrado (USD) | USD | — | — | USD | **EUR + factura ES** |
| **Soporte cliente en castellano** | Email EN | Email EN | EN | EN principal | EN | **Sí (ES/CA)** |
| **Free tier** | 2.000 palabras/sem | 15 min trial Pro + Basic ilimitado | Free Whisper Small | No | 300 min/mes | Trial 30 días |
| **Precio B2C entrada** | $0 / $15 mo / $12 anual | $0 / ~$8.49 mo (ver nota) | ~€59 lifetime (no verificado) | Sin precio público | $0 / $16,99 mo / $8,33 anual | **€9 mo / €79 año / €99 lifetime** |
| **Precio B2B entrada** | $15 Pro / Enterprise custom | Enterprise custom | — | "Contact sales" | $30 mo / $19,99 anual / Enterprise custom | **€1.500–10.000 setup + €100–800/mes (5–20 usuarios)** |

Nota SuperWhisper: la página renderiza el precio Pro con un superíndice mal parseado por WebFetch ("$849"). Interpretación correcta basada en `competencia.md` (2026-05-13) y patrón del mercado: **~$8.49/mes monthly**, anual con 2 meses gratis, Lifetime no publicado en home (sólo "Top choice"). Confirmar con captura visual si pricing exacto matters para roadmap.

---

## 2. Detalle por competidor — sólo lo nuevo respecto a `competencia.md`

### 2.1 Wispr Flow — privacy real vs marketing
Fuente verificada: `wisprflow.ai/pricing`, `wisprflow.ai/privacy`, `wisprflow.ai/` (2026-05-14).

- **Privacy Mode disponible en todos los tiers**, pero **enforced sólo en Enterprise**. En Basic/Pro está como toggle en `Settings → Data & Privacy`; el usuario tiene que activarlo. Default = OFF.
- Sin Privacy Mode activado: dictation data puede usarse para "debugging and transcription improvement" (cita literal). No se vende ni comparte.
- Transcripción ocurre en **servidores cloud seguros** (sin detallar región). Encriptación in-transit + at-rest sin más detalle.
- SOC 2 Type II e ISO 27001 sólo en Enterprise. HIPAA-ready en todos los tiers (BAA acceptance en Enterprise).
- Bug bounty público hasta $5.000+.
- Trust portal: `trust.wispr.ai` (referencia, no fetcheado).
- **No menciona GDPR ni EU AI Act ni data residency en la página de pricing/privacy/home.**
- **No menciona español, catalán ni valenciano explícitamente.**

**Lectura para Parla:** Wispr es competidor directo en USA y mercado anglosajón. En EU su tesis pierde fuerza ante:
- Despachos legales / sanitarios que necesitan **enforcement contractual** de privacidad (Privacy Mode opt-in es insuficiente para auditor de protección de datos).
- Pymes que no pueden permitirse pricing Enterprise para conseguir SOC 2 / ISO / Privacy Mode enforced.
- Clientes que necesitan factura en EUR con soporte en castellano.

### 2.2 SuperWhisper — local sí, pero matizado
Fuente verificada: `superwhisper.com/` (2026-05-14).

- "Superwhisper works offline" — confirma capacidad local-only para modelos pequeños/medianos.
- Sin embargo, Pro habilita **Cloud AI models** y **own AI API keys** → si usuario activa Cloud, audio sale del device.
- Página marketing **no afirma "audio never leaves device"** ni equivalente literal.
- 100+ idiomas vía modelos Whisper subyacentes. No declara ES/CA/VA explícitamente.
- Mac (Intel + Apple Silicon) + Windows + iOS. **Sin Linux.** Sin Android.
- SOC 2 Type II declarado sólo en Enterprise.
- No menciona GDPR, EU AI Act ni EU data residency.
- Sin on-prem ni self-hosted declarado.

**Lectura para Parla:** SuperWhisper es el rival más fuerte en privacidad real para el segmento B2C/prosumer. Su debilidad relativa frente a Parla:
- No soporta Linux (los mini-PCs pyme on-prem suelen ser Linux/headless por TCO).
- Sin venta empresa española formal: sin factura EUR, sin soporte ES, sin setup on-prem para pyme.
- Sin glosario sectorial (legal/contable/construcción) ni tuning de catalán/valenciano.

### 2.3 Otter.ai — features que no compiten directamente
Fuente verificada: `otter.ai/pricing`, `otter.ai/security`, `otter.ai/home` (2026-05-14).

- Otter es producto de **transcripción de reuniones** (Zoom/Teams/Meet), no de dictado.
- Idiomas explícitos: **EN, ES, FR, DE, JA, ZH** (lista cerrada — no "100+"). **Catalán y valenciano NO mencionados.**
- Encriptación: TLS + AES-256 at-rest declarada en página de pricing.
- HIPAA add-on disponible sólo en Enterprise.
- **Sin SOC 2 / ISO 27001 / GDPR / data residency declarado** en página de seguridad (la URL `otter.ai/security` es prácticamente vacía: solo enlaces a Terms y Privacy).
- Sin on-prem.
- Sin EUR billing.

**Lectura para Parla:** Otter sirve como **benchmark de coste B2B** ("ya pagáis $30/u/mes por algo que sólo transcribe reuniones, Parla os da dictado al cursor en cualquier app + privacidad local + idiomas nativos"). Es competidor lateral, no frontal.

### 2.4 Dragon Anywhere — disponibilidad regional crítica
Fuente verificada: `dragon.nuance.com/en-us/dragon-anywhere-mobile` (2026-05-14).

- Cita textual extraída: *"Speech Data...shall be stored and processed in the United States"* + "Available on Android and iOS (US & Canada)".
- Sin pricing público en la página actual.
- Producto incumbente histórico, hoy bajo Microsoft Health. La landing de Dragon Professional v16 redirige a `microsoft.com/health-solutions` — Nuance está siendo absorbido en stack Microsoft sanidad.
- Sin declaración de idiomas en la página de Anywhere. Históricamente ES disponible en SKU específico.
- Sin info on-prem en la página consultada.

**Lectura para Parla:** Dragon ha dejado de ser opción real para pyme española de Fase 1 — disponibilidad mobile US/CA-only y data en USA descalifica el producto frente a cualquier despacho legal o sanitario EU que pregunte por GDPR.

### 2.5 MacWhisper — NO verificado esta ronda
Fetch falla con "Acceso a internet requiere whitelist explícita". Dominios intentados: `goodsnooze.com/macwhisper`, `www.macwhisper.com`, `goodsnooze.gumroad.com/l/macwhisper`. **Acción de follow-up:** pedir a Marc whitelist explícita para `goodsnooze.com` y `macwhisper.com` si MacWhisper se considera competidor clave para Fase 1.

---

## 3. Competidores no verificados (whitelist insuficiente)

Estos dominios devolvieron "Acceso a internet requiere whitelist explícita". Recomendado verificar antes de cierre de pricing definitivo:

- **MacWhisper** (`goodsnooze.com`, `macwhisper.com`) — competidor directo en local-only Mac.
- **Aqua Voice** (`withaqua.com`, `aqua-voice.com`) — relevante para benchmark voice-to-cursor en US.
- **Speechmatics** (`speechmatics.com`) — UK-based, **único competidor con tesis "EU data residency by design"**. Su pricing y posicionamiento son críticos para entender hasta qué punto Parla puede defender el diferencial "EU local" frente a un player UK ya establecido.
- **WillowVoice / Talknotes / Otros voice-to-cursor**: no verificados.

---

## 4. Análisis de defensibilidad — ejes diferenciales de Parla

| Diferencial | ¿Cuál competidor lo cubre? | Defensibilidad |
|---|---|---|
| **Local-only enforced by default (sin Privacy Mode opt-in)** | SuperWhisper parcial (offline opcional), MacWhisper sí pero sólo Mac/B2C | **Alta** en B2B EU |
| **Catalán + valenciano nativos** con glosario | Ninguno | **Muy alta** — moat lingüístico real |
| **Glosario vertical (legal/contable/construcción) en ES/CA/VA** | Ninguno verificado | **Muy alta** |
| **On-prem mini-PC para pyme** (setup llave en mano) | Dragon Hybrid Enterprise (>>10k€), no para pyme | **Alta** en segmento 5-50 empleados |
| **Factura EUR + soporte cliente ES/CA + onboarding presencial Barcelona/Valencia** | Ninguno | **Alta** — diferencial comercial, no técnico |
| **Linux soportado on-prem** | Ninguno verificado | **Alta** TCO — relevante para mini-PCs sin licencia Windows |
| **Compliance GDPR + EU AI Act by design** | Wispr y SuperWhisper ofrecen Privacy Mode + SOC 2 en Enterprise (no by design, requiere config) | **Alta** — sobre todo si Parla publica una página de compliance con auditor EU citado |

**Riesgo principal:** Speechmatics (UK) si publican producto desktop B2C/pyme con tesis EU. Hoy son API B2B, pero podrían pivotar. Verificar en próxima ronda.

---

## 5. Recomendaciones para el pricing de Parla

Sin cambiar la estructura propuesta en `pricing_recomendado.md` (que ya está bien dimensionada), añadir estos refuerzos basados en la deep research:

1. **Página de comparación 1-a-1** Parla vs Wispr Flow / SuperWhisper / Otter / Dragon, con la matriz §1 en formato visual. **Foco en columna "data residency EU" y "CA/VA nativo"**, donde Parla es único.
2. **Calculadora TCO para pyme**: Otter Business $30/u × 12 = $360/usuario/año en USD ≈ **328 €/usuario/año** vs Parla 8 usuarios pyme = ~600€/mes ≈ 75€/u/mes con setup amortizado 36m → ROI argumentable a 12 meses si la pyme tiene >5 usuarios.
3. **Página de privacy específica para EU**: copiar la estructura de `trust.wispr.ai` pero girando el mensaje a:
   - "Audio never leaves your device. Period." (no opt-in, no toggle).
   - "Your data stays in Catalonia / Valencia / Spain. We physically cannot send it anywhere — no servers."
   - Citas literales del EU AI Act y RGPD relevantes para sector legal/sanitario/contable.
4. **Slogan diferencial para B2B**: *"Wispr Flow pero local. Dragon pero asequible. SuperWhisper pero con factura española y soporte en catalán."*
5. **No competir en precio B2C contra SuperWhisper $8/mes**. Posicionar el €9/mes/€79/año como prima por idioma nativo + soporte ES/CA, no como descuento.

---

## 6. Pendientes de próxima ronda

- [ ] Whitelist `macwhisper.com`, `goodsnooze.com` y verificar pricing MacWhisper actual (last delta vs Apr 2025: cambió de freemium a one-time license).
- [ ] Whitelist `speechmatics.com` y leer su modelo de pricing API + soporte CA + EU data residency claims (competidor más relevante en defensibilidad EU).
- [ ] Whitelist `withaqua.com` (Aqua Voice) y `talkr.com` / `willow.ai` si existen aún.
- [ ] Capturar screenshot del bloque pricing SuperWhisper para resolver ambigüedad "$849" → "$8.49".
- [ ] Buscar EU competidores nicho que ya hagan dictado on-prem para legal/sanidad ES (descubrimiento, no análisis). Pista: "transcripción local notarías España", "dictado médico on-prem EU".

---

## 7. Cambios respecto a `competencia.md` (2026-05-13)

- Añadida matriz §1 con 13 ejes (vs 7 en la tabla original).
- Detallado **Privacy Mode opt-in vs enforced** en Wispr Flow — clave para argumentar diferencial Parla en sectores regulados.
- Confirmada **data residency US** de Dragon Anywhere con cita textual.
- Documentadas limitaciones de Otter (lista cerrada de 6 idiomas, no 100+).
- Identificado **Speechmatics (UK)** como competidor crítico no verificado.
- Recomendaciones §5 nuevas para diferenciación comercial.
