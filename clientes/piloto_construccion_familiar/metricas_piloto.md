---
titulo: Métricas del piloto — KPIs y plan de medición
tipo: instruccion
creado: 2026-05-14
actualizado: 2026-05-14
tags: [piloto, construccion, metricas, kpi, caso-estudio]
---

# Plan de métricas piloto construcción

> **Objetivo:** llegar al día +30 con datos defendibles que sirvan para (a) decisión GO/NO-GO del cliente y (b) construir caso de estudio publicable. Medir lo justo — exceso de medición es fricción para el cliente y discredita el piloto.

---

## Las 3 métricas que importan

Si tuviera que reducir a 3, son estas. Sin estas, el piloto no concluye nada.

### 1. Horas ahorradas reales por semana (proxy)

- **Cómo medirla:** auto-reporte del usuario al final de cada semana, 1 pregunta vía WhatsApp:
  > "Esta semana, ¿cuántas horas crees que te ha ahorrado el dictado en total? (Tu mejor estimación, sin pensarlo mucho.)"
- **Por qué auto-reporte y no telemetría:** medir telemétricamente "palabras transcritas" lleva a un número que no se traduce a euros. El usuario sí sabe traducir su percepción a horas. **Privacy bonus:** auto-reporte no requiere extraer datos del cliente.
- **Umbral éxito:** **≥3 h/semana ahorradas** por al menos 2 de los 3 usuarios. Por debajo de eso, el ahorro no compensa la fricción.
- **Reporte final:** suma 4 semanas. Convertir a €/mes ahorrados (coste medio empleado pyme construcción cargado: ~€18-22/h administrativa, ~€25-30/h jefe obra).

### 2. Satisfacción 1-10 (NPS-like)

- **Cómo medirla:** al final del piloto, pregunta única a cada usuario:
  > "Del 1 al 10, ¿cómo de satisfecho/a estás con el dictado tras este mes? (1 = horrible, 10 = no querría dejar de usarlo)"
- **Umbral éxito:** **media ≥7** entre los usuarios reales. ≥8 es excelente, ≤6 indica fricción real y posiblemente NO-GO.
- **Pregunta complementaria al jefe/socio** (si participó): "1-10, ¿lo recomendarías a otra pyme del sector?".

### 3. Intención de re-uso

- **Cómo medirla:** pregunta directa a quien decide en la pyme (socio / jefe / familiar):
  > "Si mañana se acabara el piloto y tuvieras que decidir hoy: ¿seguirías con esto pagando, no seguirías, o seguirías solo si hubiera cambios concretos?"
- **Umbral éxito:** **"seguiría pagando" o "seguiría con cambios concretos accionables"**. "No seguiría" sin razón concreta = NO-GO duro.
- **Sub-pregunta clave:** "¿Cuál sería el precio que te parecería justo por esto al mes para 3 puestos?". Esto valida el anchor de €200/mes del pricing recomendado.

---

## Métricas secundarias (medir si se puede sin fricción)

### 4. Uso real semanal

- **Cómo medirla:** telemetría LOCAL en el daemon (sin extraer del cliente) — contador de "veces activado el PTT por día" almacenado en log local.
- **Recogida:** Marc lo descarga visualmente en la reunión de cierre o el cliente envía screenshot del log. NO se transmite automáticamente.
- **Umbral éxito:** ≥10 activaciones/día por usuario activo durante las semanas 3 y 4. Si tras 2 semanas el uso baja, hay un problema (fricción, hábito no formado, fallo no reportado).

### 5. Errores y soporte

- **Cómo medirla:** Marc anota cada llamada/WhatsApp de soporte: usuario, fecha, síntoma, causa raíz, fix, tiempo de resolución.
- **Umbral aceptable:** <5 incidencias relevantes en el mes con resolución <24 h. >10 incidencias indica software no maduro para producción.

### 6. Velocidad teclado vs dictado (opcional, día 1)

- **Cómo medirla:** en la instalación, pedir al usuario que escriba un párrafo dado (~50 palabras) tecleando, cronometrar. Luego dictar el mismo. Anotar palabras/min.
- **Para qué:** anclar el "ahorro percibido" del usuario a un dato físico medible (de cara al caso de estudio: "Juan teclea a 28 ppm, dicta a 92 ppm — 3,3× más rápido").

### 7. Errores de transcripción percibidos

- **Cómo medirla:** en la llamada semanal, pregunta:
  > "Del 1 al 10, ¿cómo de bien entiende lo que dices? (Si te falla 1 palabra de 100, eso es un 9-10. Si te falla 1 de 10, eso es un 4-5.)"
- **Umbral éxito:** ≥8 medio. Por debajo de 7 indica problema de modelo o glosario insuficiente.

---

## Calendario de medición

| Momento | Quién | Qué |
|---|---|---|
| **Día 0 (instalación)** | Marc en oficina | Métrica 6 (velocidad baseline), apuntar setup técnico de cada PC, foto del entorno. |
| **Día +3** | Marc llamada corta | "¿Funciona? ¿Algún problema bloqueante?" — solo detectar muerte temprana. |
| **Día +7** | Marc WhatsApp | Métrica 1 (horas) + Métrica 7 (precisión) por usuario. |
| **Día +14** | Marc llamada 10 min | Métricas 1 + 7. Pregunta abierta: "¿hay algo que falte o que sobre?". |
| **Día +21** | Marc WhatsApp | Métricas 1 + 7. |
| **Día +28** | Marc llamada | Pre-aviso reunión cierre. Pedir al usuario que para el día +30 piense en "lo bueno, lo malo y lo que cambiaría". |
| **Día +30** | Marc presencial | Reunión cierre: Métricas 2, 3, 4, 5, recoger feedback cualitativo, decisión GO/NO-GO. |

**Tiempo total de fricción para el cliente durante el mes:** ~20 min (3 WhatsApps de 1-2 min + 2 llamadas de 10 min + reunión final). Aceptable.

---

## Plantilla de seguimiento semanal (uso interno Marc)

Marc lleva una tabla simple en `/home/Projects/parla/clientes/piloto_construccion_familiar/seguimiento_semanal.md` (se crea día +7, no antes):

| Semana | Usuario | Horas ahorradas (auto) | Precisión 1-10 | Activaciones/día (telemetría) | Incidencias |
|---|---|---|---|---|---|
| 1 | Admin | | | | |
| 1 | Jefe obra | | | | |
| 1 | Otro | | | | |
| 2 | ... | | | | |

Si al cabo de 2 semanas alguna celda está vacía → llamar para conseguir el dato. **No** rellenarlo a ojo de buen cubero — peor que no medir es medir mal.

---

## Cómo se traduce todo esto a caso de estudio

Al cierre del piloto, si las métricas validan, el caso de estudio (anonimizable) se construye con:

- **Hook:** "Una pyme de construcción con N empleados, en 30 días, ahorró X horas/semana usando dictado por voz."
- **Contexto:** sector, tamaño, perfil de los usuarios (administrativa, jefe obra, director), tipo de documentos.
- **Datos duros:**
  - Ahorro semanal medio: X horas → X × 4 = Y h/mes → Y × €22/h = €Z/mes ahorrados.
  - ROI vs cuota mantenimiento Tier 2 (€200/mes) = €Z / €200 = N× retorno mensual.
  - Velocidad teclado vs dictado (de Métrica 6).
  - Satisfacción media (de Métrica 2).
- **Cita textual** del decisor: "[testimonio]" — solicitado en reunión de cierre y revisado por el cliente antes de publicar.
- **Privacy angle:** "Los audios y textos jamás salieron de la oficina. EU AI Act + GDPR cumplidos by design."

**Reglas para el caso de estudio:**

- Solo se publica con autorización escrita del cliente (clausula 5.d de `acuerdo_simple.md`).
- Si el cliente prefiere anonimato: "una pyme de construcción de [provincia], 30 empleados…" sin nombre.
- Si las métricas son negativas: NO se publica nada. Las métricas negativas son aprendizaje interno (alimentan iteración del producto), no contenido comercial.

---

## Antipatrones de medición a evitar

- **No medir nada y "tirar de feeling".** Al cabo de 30 días Marc se acordará selectivamente de lo positivo. Sin métricas, no hay caso de estudio.
- **Sobre-instrumentar telemétricamente.** Tentación: extraer cada activación, cada palabra. Mal: rompe la promesa de privacidad y satura el log. Solo telemetría local y agregada.
- **Pedir al usuario que rellene una hoja Excel cada día.** No la rellenará. Pregunta breve por WhatsApp 1 vez/semana, máximo.
- **Confundir uso con valor.** Un usuario puede activar el dictado 50 veces/día y aun así no estar satisfecho (por errores, por fatiga). La métrica 4 (uso) solo es válida cruzada con la 2 (satisfacción).
- **Decidir GO/NO-GO antes del día 30.** El primer mes tiene curva de aprendizaje. Decisiones definitivas solo con los 4 datapoints semanales completos.

---

## Cross-link

- `acuerdo_simple.md` — clausula 5.d sobre uso del caso de estudio.
- `faq_anticipadas.md` — pregunta sobre "¿cuánto me ahorrará?" se contesta con los rangos esperados aquí.
- `/home/Projects/parla/pricing/pricing_recomendado.md` — TCO y ROI a 3 años, usados para contextualizar el ahorro mensual real.
- `idea-132` — vertical pack construcción (glosario que se va enriqueciendo durante el piloto).
