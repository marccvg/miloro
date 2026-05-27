---
titulo: Competencia — pricing dictado por voz (B2C + B2B)
tipo: ficha
creado: 2026-05-13
actualizado: 2026-05-13
tags: [parla, pricing, competencia, mercado]
---

# Pricing competencia — dictado por voz (verificado 2026-05-13)

> Datos extraídos vía WebFetch a las páginas oficiales de cada producto. URL fuente al final de cada bloque. Tipo de cambio asumido: **1 USD = 0,92 EUR** (snapshot 2026-05-13). Precios sin IVA salvo nota en contra.

## Tabla resumen

| Producto | Modelo | B2C precio | B2B precio | Idiomas ES/CA/VA | Cloud/Local | EU compliance | Verificado |
|---|---|---|---|---|---|---|---|
| **Wispr Flow** | Free + SaaS | $0 (Basic, 2k palabras/sem) — $15/mes Pro ($12 anual) | $15/u/mes Pro; Enterprise custom | 100+ idiomas (incluye ES) | Cloud | HIPAA-ready; SOC 2 / ISO 27001 sólo Enterprise | wisprflow.ai/pricing |
| **SuperWhisper** | Free + Sub + Lifetime | $0 limitado — $8/mes Pro — Lifetime (no precio público) | Enterprise custom | 100+ (vía Whisper) | Local (Mac/Win/iOS) | Sí (procesamiento local) | superwhisper.com |
| **MacWhisper** | One-time license | ~€59 Pro (no verificado en esta vuelta) | — | 100+ (vía Whisper) | Local (sólo Mac) | Sí (local) | ⚠ fetch falló — ver REPORT.md |
| **Dragon Professional** (Nuance/Microsoft) | License + maintenance | Sin precio público | Sin precio público — sales contact | EN principal; ES via Dragon NaturallySpeaking | Cloud + On-prem híbrido | Variable | dragon.nuance.com (sin pricing) |
| **Otter.ai** | Freemium SaaS | $0 (300 min/mes) — $16,99/mes Pro ($8,33 anual) | $30/u/mes Business ($19,99 anual); Enterprise custom | EN, ES, FR sólo | Cloud | HIPAA add-on en Enterprise | otter.ai/pricing |
| **Parla** *(propuesta)* | Lifetime + Sub + Pyme | €99 lifetime / €9 mes / €79 año | €1.500-10.000 setup + €100-800/mes | **ES + CA + VA nativos** | **Local (on-prem)** | **EU AI Act + GDPR by design** | — |

---

## Detalle por producto

### Wispr Flow — wisprflow.ai/pricing
- **Basic (Free, billed annually):** 2.000 palabras/sem Mac/Win, 1.000 palabras/sem iPhone, ilimitado Android (tiempo limitado), 100+ idiomas, "Privacy mode" (Zero Data Retention), HIPAA-ready, diccionario custom y snippets.
- **Pro:** $15/usuario/mes (mensual) / $12/u/mes (anual, 20% descuento). Palabras ilimitadas todos los plataformas, command mode, early access, team collaboration.
- **Enterprise:** custom (contact sales). SOC 2 Type II, ISO 27001, HIPAA enforced, SSO/SAML, admin dashboards, bulk discounts.
- **Extras:** trial 14 días Pro sin tarjeta. Descuento estudiante 50%.
- **Lectura para Parla:** Wispr es el competidor más cercano en posicionamiento "dictado IA general". Cloud-first, sin ES/CA/VA nativo declarado, política de privacidad insuficiente para sector público / sanitario / legal en EU (Privacy Mode existe pero sólo en Enterprise enforced).

### SuperWhisper — superwhisper.com
- **Free:** voice-to-text básico, 15 minutos de prueba de features Pro.
- **Pro:** $8/mes (descuento estudiante 40%); anual con 2 meses gratis; opción Lifetime (precio no publicado en la página principal). Personal API key, modelos AI premium ilimitados, transcripción de archivos, traducción, soporte prioritario.
- **Enterprise:** custom. SOC 2, team billing, controles de acceso a modelos.
- **Plataformas:** Mac (Intel + Apple Silicon), Windows, iOS. **No Linux.**
- **Lectura:** competidor local en Mac/Win, lo más cercano a Parla en privacidad. No ES/CA/VA nativo declarado más allá de modelos genéricos Whisper. **Sin soporte para empresa española con factura y soporte en castellano.**

### MacWhisper — macwhisper.app *(fetch falló — datos a verificar)*
- ⚠ **No verificado en esta vuelta.** `WebFetch` a `macwhisper.app`, `www.macwhisper.app/`, `macwhisper.app/pricing` con timeout consistente. Distribuye también vía Gumroad (fuera de whitelist).
- Referencia pública pre-fetch (no citable hasta nueva verificación): one-time ~€59 Pro license, ~€79 versión avanzada, sólo macOS.
- **Lectura:** sólo Mac. Producto técnico fuerte pero sin venta empresa ni soporte ES.

### Dragon Professional — dragon.nuance.com
- **Sin pricing público.** La página actual de Nuance/Microsoft no muestra ningún precio — sólo "Contact us".
- Histórico: licencia perpetua ~$500 USD + maintenance; subscripción cloud-híbrida ~$30/u/mes en planes empresa.
- Idiomas: EN principal; ES disponible en versión "Dragon NaturallySpeaking" específica.
- **Lectura:** producto incumbente, fortísimo en sanidad y legal en EEUU. Precio opaco → cliente percibe "negociable", no comparable directo en página web. Para pyme española es prácticamente desconocido.

### Otter.ai — otter.ai/pricing
- **Basic (Free):** 300 min transcripción/mes, integración Zoom/Teams/Meet, AI Chat, 3 imports de fichero (vida), identificación speaker.
- **Pro:** $16,99/mes (mensual) / $8,33/mes (anual, 51% descuento). 1.200 min recording in-app, hasta 90 min/meeting, 10 imports/mes, workflows AI, Salesforce/HubSpot.
- **Business:** $30/u/mes (mensual) / $19,99/u/mes (anual, 33% descuento). Meetings + recordings ilimitados, hasta 4h/meeting, 3 meetings concurrentes, admin features.
- **Enterprise:** custom. Workflows ilimitados, Sales Notetaker, CRM integrations custom, SSO/SCIM, HIPAA add-on, API access.
- **Lectura:** Otter es **transcripción de reuniones**, no dictado. Compite parcialmente con Parla en sector "secretaría / actas legales". Mejor punto de comparación B2B para mostrar a una pyme que "ya pagas $30/u/mes a Otter, Parla te da más con privacidad local".

---

## Notas metodológicas

- **No copia literal:** las tablas resumen condiciones, no reproducen el texto de marketing de cada vendor.
- **Sin pricing oficial → "custom"**: Wispr Enterprise, SuperWhisper Enterprise, Dragon, Otter Enterprise. Para TCO usar el tier públicamente publicado más alto como proxy.
- **Discrepancia con la tabla original de la tarea:**
  - Wispr Flow: tarea decía $30/u/mes B2B; verificado $15/u/mes Pro ($12 anual). El $30 corresponde a Otter Business, no a Wispr.
  - MacWhisper: tarea decía $59; fetch falló — verificar en próxima iteración.
  - Dragon: tarea decía $15/mes B2C y $30/mes B2B; verificado **sin pricing público**.
- **Idiomas ES/CA/VA**: ningún competidor publicita soporte nativo para catalán o valenciano. Whisper-based products pueden transcribir CA pero sin tuning, glosario sectorial ni soporte de cliente en esos idiomas. **Diferenciador real para Parla.**
