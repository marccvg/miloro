---
titulo: Pricing recomendado Parla — B2C + B2B Pyme + B2B Premium
tipo: ficha
creado: 2026-05-13
actualizado: 2026-05-13
tags: [parla, pricing, recomendacion, tco, comparativa]
---

# Pricing recomendado Parla

> Tres tiers, dos retóricas distintas: B2C usa precio fijo simple; B2B Pyme se vende como "setup + cuota servicio" porque ahí compite con consultoría/integración, no con SaaS.
>
> Tipo de cambio: **1 USD = 0,92 EUR** (snapshot 2026-05-13). Todos los precios B2B sin IVA; precios B2C con IVA incluido (consumidor final).

---

## Tier 1 — B2C Individual

| Modalidad | Precio | Incluye | Target |
|---|---|---|---|
| **Lifetime** | **€99** (IVA incl., pago único) | Software perpetuo + 12 meses de actualizaciones + transcripción local ilimitada + diccionarios ES/CA/VA + soporte email | Profesional liberal: autónomo, escritor, abogado particular, traductor, periodista |
| **Suscripción mensual** | **€9/mes** | Todo lo anterior + actualizaciones continuas + soporte prioritario | Usuario que prueba o uso temporal |
| **Suscripción anual** | **€79/año** (≈ €6,58/mes, ~27% descuento sobre mensual) | Mismo que mensual | Usuario fidelizado que prefiere no pagar lifetime |

**Anchor mental:** "menos que una cena fuera, y dura toda la vida". Lifetime es el push principal — convierte mejor que sub para pública objetivo que desconfía de SaaS.

**Por qué €99 lifetime y no €59-79 (como MacWhisper):**
- Diferencial: **soporte en castellano + factura española** (un autónomo necesita esto para deducir).
- Diferencial: **dialectos CA/VA + glosarios sectoriales** (legal, médico, técnico).
- Mantiene margen para descuentos puntuales (Black Friday €69, lanzamiento €79) sin canibalizar percepción de valor.

**Comparativa rápida B2C:**

| Producto | Coste año 1 | Coste año 3 |
|---|---|---|
| Wispr Flow Pro anual | $144 ≈ **€132** | $432 ≈ **€397** |
| Otter.ai Pro anual | $99,96 ≈ **€92** | $300 ≈ **€276** |
| SuperWhisper Pro mensual | $96 ≈ **€88** | $288 ≈ **€265** |
| **Parla Lifetime** | **€99** | **€99** ✓ |
| Parla Anual | €79 | €237 |

> **Punto de venta B2C:** lifetime gana frente a cualquier SaaS a partir del año 2.

---

## Tier 2 — B2B Pyme Setup (5-15 empleados)

| Componente | Rango | Mid-point recomendado |
|---|---|---|
| **Setup inicial** (1 vez) | €1.500 – €3.000 | **€2.250** |
| **Mantenimiento mensual** | €100 – €300/mes | **€200/mes** |
| **Hardware on-prem** (cliente compra directo, NO factura Parla) | €500 – €800 | — |

**Qué incluye el setup:**
- Instalación on-prem (1 server o NAS del cliente).
- Configuración hasta 15 puestos cliente (Windows / macOS).
- Glosario inicial vertical (sector del cliente: jurídico / contable / sanitario / construcción).
- Formación 2h al equipo (presencial o remoto).
- 3 meses de soporte incluidos en el setup.

**Qué incluye la cuota mensual (€100-300):**
- Actualizaciones de modelo y mejoras de software.
- Soporte por email/teléfono con SLA respuesta 48h.
- Backups remotos del diccionario corporativo (sólo metadatos, NO audio).
- 1 sesión trimestral de tuning del glosario.

**Heurística para decidir dentro del rango €100-300:**
- 5 empleados → €100/mes
- 10 empleados → €200/mes
- 15 empleados → €300/mes
- Equivale a **€20/empleado/mes**, anchor para conversación con cliente.

---

## Tier 3 — B2B Pyme Premium (15-50 empleados)

| Componente | Rango | Mid-point recomendado |
|---|---|---|
| **Setup inicial** (1 vez) | €5.000 – €10.000 | **€7.500** |
| **Mantenimiento mensual** | €400 – €800/mes | **€600/mes** |
| **Hardware on-prem** (cliente compra) | €1.000 – €2.500 | — |

**Qué añade sobre Tier 2:**
- Integración con software de gestión del cliente (ERP, CRM, gestor documental).
- Glosario vertical profundo con tuning iterativo (4 sesiones/año).
- SLA respuesta 24h, escalado 4h, garantía resolución 5 días laborables.
- Onboarding técnico extendido: 1 día presencial + soporte de migración.
- Hardware especificado y monitorizado (alertas de salud del server).
- Dashboard de uso (palabras transcritas / usuario, errores, tiempo ahorrado).

**Heurística:** **€15-20/empleado/mes** en el rango 15-50 empleados (economías de escala sobre Tier 2).

---

## Justificación TCO — comparativa 3 años

### Escenario A: pyme de 10 empleados, dictado individual

| Producto | Setup | Cuota | Subtotal 3 años | Notas |
|---|---|---|---|---|
| Wispr Flow Pro anual | $0 | $12/u/mes × 10 × 36 | $4.320 ≈ **€3.975** | Cloud, sin soporte ES |
| Wispr Flow Pro mensual | $0 | $15/u/mes × 10 × 36 | $5.400 ≈ **€4.970** | — |
| Otter.ai Business anual | $0 | $19,99/u/mes × 10 × 36 | $7.196 ≈ **€6.620** | Transcripción reuniones, no dictado puro |
| **Parla Tier 2 Pyme** | €2.250 | €200/mes × 36 | **€9.450** + €650 HW ≈ **€10.100** | On-prem + ES/CA/VA + EU compliance |

**Fórmula Parla Tier 2:**
```
TCO_3años = setup + (cuota_mensual × 36) + hardware_externo
          = 2.250 + 7.200 + 650
          = 10.100 €
```

**Lectura honesta:** Parla es **~2,5× más caro** que Wispr Pro anual a los 3 años en este escenario. La conversación con cliente debe pivotar sobre:
- **Privacidad / cumplimiento:** datos jamás salen de la empresa → EU AI Act + GDPR sin matices. Para sanitarios, abogados, gestorías, despachos contables → **no es opcional**, es habilitador legal.
- **Idioma:** dictado nativo CA/VA y glosario sectorial ES. Ningún cloud lo ofrece tuneado.
- **Soporte local:** factura española, llamadas en castellano, formación in situ.
- **Ahorro de horas reales:** si los 10 empleados dictan vs teclean 30 min/día → 30 min × 10 × 22 días = 110h/mes ahorradas. A €25/h coste empleado cargado = **€2.750/mes ahorrados**. Cuota Parla €200/mes ≈ **14× ROI mensual**.

### Escenario B: pyme de 25 empleados, sector legal (Tier 3 Premium)

| Producto | Subtotal 3 años | Notas |
|---|---|---|
| Wispr Flow Pro anual | $12 × 25 × 36 = $10.800 ≈ **€9.940** | Sin integración gestor jurídico |
| Otter.ai Business anual | $19,99 × 25 × 36 = $17.991 ≈ **€16.560** | Sin dictado puro |
| **Parla Tier 3 Premium** | €7.500 + €600×36 = €29.100 + €1.700 HW ≈ **€30.800** | Con integración + glosario legal + SLA 24h |

**Fórmula Parla Tier 3:**
```
TCO_3años = 7.500 + (600 × 36) + 1.700 = 30.800 €
```

Aquí Parla es **3× más caro** que Wispr — pero compite con **consultoría + Wispr + abogados que se quejan**, no sólo con Wispr.

Anchor de venta para sector legal:
- 1 brecha de confidencialidad cliente-abogado vía cloud = sanción RGPD potencial 4% facturación.
- Caso real esperable: bufete con €2M facturación → exposición €80k.
- Coste Parla Tier 3 3 años = €30k = **0,4× el riesgo evitado en un solo incidente**.

### Tabla "break-even" — palabras clave para Marc en venta

| # empleados | Tier sugerido | TCO 3 años Parla | TCO 3 años Wispr Pro anual | Diferencia | Comentario para cliente |
|---|---|---|---|---|---|
| 1-3 (autónomo) | B2C Lifetime | €99 | €119-€397 | Parla **ahorra** | Push: "no es SaaS, lo pagas una vez" |
| 5 | Tier 2 mínimo | €1.500 + €100×36 = €5.100 | €1.985 | +€3.100 | "Privacidad on-prem por 6€/empleado/mes extra" |
| 10 | Tier 2 mid | €10.100 (con HW) | €3.975 | +€6.100 | "ROI 14× mensual si ahorras 30 min/día/persona" |
| 15 | Tier 2 alto / Tier 3 bajo | €13.500 (T2) / €23.100 (T3) | €5.960 | +€7.500 – €17.000 | "Decidir: necesitas integración ERP? → T3" |
| 25 | Tier 3 mid | €30.800 | €9.940 | +€20.900 | "Sector regulado (legal/sanitario): brecha cloud = 4% facturación" |
| 50 | Tier 3 alto + custom | €40.000+ | €19.880 | +€20.000+ | "A esta escala negociar Tier custom" |

---

## Reglas de descuento

- **Lifetime B2C:** nunca por debajo de €69. Lanzamiento puede ser €79.
- **Setup B2B Pyme:** descuento máximo 20% (rebajar dentro del rango).
- **Cuota mensual B2B:** sin descuento los primeros 12 meses (es el coste de soporte real). A partir del año 2, descuento por permanencia anual hasta 15%.
- **Renovación HW:** a los 4-5 años, ofrecer "refresh" como setup parcial €500-1.000.

---

## Anti-objeciones esperadas

**"Wispr/Otter es más barato"** → "Sí, en cuota. Pero tus datos salen del despacho. Para tu sector eso es exposición regulatoria. El coste real de Wispr incluye el riesgo de auditoría RGPD que no pagas hasta que pagas mucho."

**"Por qué tan caro el setup"** → "Porque el software se queda contigo, no en nuestros servidores. Pagas la instalación una vez, no el alquiler perpetuo. Mira el TCO a 5 años: dejamos de ser caros."

**"Y si me canso al año"** → "B2B Pyme: software perpetuo. Si dejas la cuota mensual pierdes actualizaciones y soporte, pero sigues usándolo. No es SaaS rehén."

**"Whisper open-source es gratis"** → "Sí, y montarlo, mantenerlo, tunarlo a tu glosario, y atender al equipo cuando falla, también. Ese es exactamente nuestro servicio."
