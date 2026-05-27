# Report — ECHO_COMPETITOR_DEEP_RESEARCH01

**Status:** done (parcial — whitelist limita 4 dominios)
**Duration:** ~20 min

## Lo que hice

- Verifiqué vía WebFetch las páginas oficiales de 4 competidores activos: Wispr Flow (`/pricing`, `/privacy`, `/`), SuperWhisper (`/`), Otter.ai (`/pricing`, `/security`, `/home`), Dragon Anywhere (`dragon.nuance.com/en-us/dragon-anywhere-mobile`).
- Extraje pricing exacto, features por tier, claims de privacidad/compliance, soporte EU (data residency, idiomas, billing), y disponibilidad on-prem para B2B.
- Identifiqué que `competencia.md` (2026-05-13) tenía la tabla pricing correcta pero faltaba detalle en privacy/EU/idiomas — la deep research va aquí.
- Creé `competencia_deep.md` con:
  - Matriz §1 de 13 ejes diferenciales Wispr/SuperWhisper/MacWhisper/Dragon/Otter/Parla.
  - Detalle §2 por competidor con citas literales relevantes (e.g. Dragon: "Speech Data...shall be stored and processed in the United States").
  - Análisis §4 de defensibilidad por eje diferencial (local-only, CA/VA, glosario vertical, on-prem pyme, EUR/factura, Linux, GDPR by design).
  - Recomendaciones §5 para pricing y comms (calculadora TCO Otter Business → Parla, slogan B2B, página EU privacy).
  - Lista §6 de pendientes para próxima ronda con dominios a añadir a whitelist.

## Verificación

- Acceptance: archivos en `/home/Projects/parla/pricing/` → PASS (`competencia_deep.md` 9.8 KB + `report.md` este).
- Tabla pricing real: PASS (4/5 competidores verificados con cita URL).
- Features: PASS (tiers Basic/Pro/Business/Enterprise documentados con quotas y feature gates).
- Privacy claims: PASS (Privacy Mode opt-in vs enforced en Wispr; SOC 2/ISO 27001 sólo Enterprise; HIPAA add-on; data residency US confirmada en Dragon).
- Soporte EU: PASS (verificado que ninguno declara EU residency en sus páginas públicas, sólo Wispr menciona "trust.wispr.ai" como portal sin entrar en regiones).
- Idiomas: PASS (Otter cerrado a EN/ES/FR/DE/JA/ZH; Wispr y SuperWhisper dicen "100+" sin lista; ninguno declara CA/VA).
- Foco diferencial Parla (local-only EU + ES/CA/VA + on-prem B2B): PASS — documentado §4 con grado de defensibilidad por eje.

## Follow-up sugerido (NO ejecutar — para el orquestador)

1. **Tarea de whitelist**: pedir a Marc whitelist explícita para `macwhisper.com`, `goodsnooze.com`, `speechmatics.com`, `withaqua.com`. Sin esos cuatro la matriz queda incompleta — Speechmatics especialmente es el competidor más peligroso (UK, posicionamiento EU compliance).
2. **Tarea ECHO_COMPETITOR_DEEP_RESEARCH02** una vez tengamos whitelist: re-fetch MacWhisper actual + Speechmatics + Aqua Voice + 1-2 nicho EU (búsqueda en ES: "transcripción local notarías España", "dictado médico on-prem"). Cierra el gap del análisis.
3. **Tarea ECHO_PRICING_PAGE01**: usar §1 y §5 de `competencia_deep.md` como input para diseñar la página comparativa pública de Parla (1-a-1 contra Wispr / SuperWhisper / Otter / Dragon).
4. **Tarea ECHO_TCO_CALCULATOR01**: implementar calculadora pyme Otter Business vs Parla mencionada en §5 (input: nº usuarios, output: ahorro 12/24/36 meses).
5. Aclarar el "$849" de SuperWhisper (parser issue con superíndice de céntimos) — captura visual o tarea de validación.

## Notas

- **Tipo de cambio**: asumido 1 USD = 0,92 EUR (consistente con `competencia.md`).
- **No modifiqué `competencia.md`** ni `pricing_recomendado.md` — son la base de 2026-05-13. El nuevo material va en `competencia_deep.md` para mantener trazabilidad.
- **`pricing_recomendado.md` sigue siendo válido** — la deep research no invalida el rango €9 mo / €79 año / €99 lifetime ni el setup B2B €1.500-10.000. Sí refuerza el argumento defensivo en §5.
- **No hubo escalación** pese a varios 404/redirects/whitelist-blocks — todos eran fetches opcionales (MacWhisper, Aqua, Speechmatics). Los 4 competidores principales sí se verificaron.
