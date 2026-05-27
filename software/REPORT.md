# Parla — PoC técnico Fase 0

**Generado**: 2026-05-15T09:09:46
**Decisión Marc 2026-05-14**: NO outreach al familiar piloto hasta validar este PoC.

## VEREDICTO

- **B2B vendible**: NO ❌ (req: P95 ≤ 4.0s con 4 voces, accuracy ≥ 90%)
- **B2C vendible**: NO ❌ (req: P95 ≤ 1.0s con 1 voz, accuracy ≥ 95%)

## Resultados completos

| Modelo | Quant | Voces | P50 | P95 | Accuracy ES | WER |
|---|---|---:|---:|---:|---:|---:|
| small | default | 1 | 2.449s | 2.592s | 95.1% | 0.049 |
| small | int8 | 1 | 1.924s | 2.16s | 95.1% | 0.049 |
| small | default | 4 | 4.425s | 24.754s | 41.5% | 0.585 |
| medium | default | 1 | 8.672s | 9.899s | 92.7% | 0.073 |
| medium | int8 | 1 | 4.649s | 4.743s | 92.7% | 0.073 |
| medium | default | 4 | 9.056s | 18.976s | 36.6% | 0.634 |

## Recomendaciones
- ❌ Hardware actual NO suficiente. Recomendaciones: NUC i7+ con 16GB RAM o GPU edge tipo Jetson.