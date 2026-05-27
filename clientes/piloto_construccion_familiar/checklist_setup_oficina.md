---
titulo: Checklist setup en oficina del cliente — día instalación
tipo: instruccion
creado: 2026-05-14
actualizado: 2026-05-14
tags: [piloto, construccion, setup, instalacion, checklist]
---

# Checklist setup oficina — día de instalación

> **Lectura previa obligatoria:** este checklist asume que el piloto se monta **sobre los PCs de cada empleado** (modo más sencillo en Fase 0), sin mini-server on-prem. El mini-server se ofrece solo si tras el primer mes el cliente quiere ampliar a 5+ puestos. Más detalle en `acuerdo_simple.md` §"Modalidad de despliegue del piloto".

---

## ANTES de salir de casa — víspera (T-1 día)

### Bloque 1 — Confirmaciones

- [ ] Llamada o WhatsApp al familiar **24 h antes**: confirmar día, hora, dirección.
- [ ] Preguntar nº exacto de personas que probarán (suele variar entre llamada y día D).
- [ ] Preguntar sistema operativo de los PCs (Windows 10 / 11 / macOS — afecta al instalador).
- [ ] Preguntar marca/modelo de los ratones que usan (PTT funciona mejor con MX Master o similar; si son ratones básicos hay que llevar uno de repuesto).
- [ ] Preguntar si tienen políticas de IT / antivirus corporativo que puedan bloquear instalación (en pyme normalmente no, pero si tienen contrato con un informático externo, avisar a Marc).

### Bloque 2 — Material físico a llevar

- [ ] **Portátil de Marc** con el setup completo funcionando (demo de respaldo si falla algo).
- [ ] **2 ratones MX Master** (o equivalente con PTT) — uno para demostrar, otro de repuesto si algún PC del cliente lo necesita.
- [ ] **2 micrófonos USB** (Blue Yeti Nano o similar, ~€80 cada uno) — opcional, solo si los PCs del cliente tienen micrófono interno malo. Llevar igualmente.
- [ ] **3 cables USB-A largos** (1,5-2 m) por si los PCs tienen los puertos lejos de donde estará el micrófono.
- [ ] **Adaptador USB-C ↔ USB-A** (PCs antiguos solo USB-A; portátiles nuevos solo USB-C).
- [ ] **Hub USB** de 4 puertos (algunos PCs tienen solo 2 puertos libres).
- [ ] **Cable HDMI** + **adaptador a VGA** — por si hace falta enseñar algo en una pantalla del cliente o proyector.
- [ ] **Pendrive USB** con instalador offline del software (por si la wifi del cliente falla o no tiene Internet en ese momento).
- [ ] **Cargador portátil** del propio portátil (no asumir enchufe libre).
- [ ] **Libreta + bolígrafo** — para anotar feedback en directo, observaciones de cada usuario, dudas.

### Bloque 3 — Material digital a llevar (en el portátil de Marc)

- [ ] Instalador del producto **firmado** y empaquetado para Windows y macOS — versión congelada para este piloto, no la última en desarrollo (idem `idea-098`).
- [ ] **Glosario inicial construcción** (terminología: hormigón, encofrado, vigueta, replanteo, etc. — cross-link `idea-132`).
- [ ] **3 documentos contextuales** del sector como base de prueba: 1 parte de trabajadores en blanco, 1 presupuesto-tipo, 1 email-tipo a promotor.
- [ ] **`script_llamada.md`** (no para leer, para revisión rápida si el tema vuelve a entrar).
- [ ] **`propuesta_1pag.md`** impresa o en tablet por si entra el socio/jefe.
- [ ] **`acuerdo_simple.md`** impreso (2 copias firmables si el cliente lo pide).
- [ ] **`faq_anticipadas.md`** revisado en memoria — no leer durante la instalación, conocer las respuestas.
- [ ] **`metricas_piloto.md`** — para entender qué medir en las semanas siguientes.
- [ ] Plantilla de **hoja de feedback día 1** (impresa o en tablet) — ver §"Día de instalación, bloque 5".

### Bloque 4 — Sí o sí preguntar al cliente la víspera

- [ ] ¿Hay aparcamiento cerca? (no perder 30 min buscando sitio)
- [ ] ¿Algún horario en el que la oficina esté especialmente liada y haya que evitar?
- [ ] ¿La administrativa/secretaria sabe que voy? (evitar la "¿quién es este señor?" en recepción)

---

## DÍA D — Llegada y setup (cronograma 2-3 h)

### Bloque 5 — Llegada (0:00–0:15)

- [ ] Saludo al familiar y a quien esté en recepción.
- [ ] Saludo personal a las 2-3 personas que probarán el sistema (presentación humana antes que técnica).
- [ ] **Pedir 5 minutos para ver dónde trabaja cada uno** — observar setup real (¿pantalla grande? ¿doble monitor? ¿ratón propio? ¿micrófono?) antes de tocar nada.
- [ ] **Una pregunta clave a cada uno antes de instalar:** "¿qué tipo de texto escribes más en un día normal?". Esto orienta qué plantilla mostrar primero.

### Bloque 6 — Instalación técnica (0:15–1:00)

Por cada PC (orden: el más relevante primero — el que más escribe):

- [ ] Conectar al wifi de la oficina (pedir clave).
- [ ] Verificar permisos de administrador del PC (si no los tiene el empleado, pedir al jefe que esté disponible para autorizar — esto suele ser el principal cuello de botella).
- [ ] Instalar el daemon desde pendrive USB.
- [ ] Conectar micrófono USB si el interno es malo (prueba previa: dictar 1 frase, verificar latencia).
- [ ] Vincular botón PTT al ratón que use el empleado.
- [ ] Cargar glosario construcción.
- [ ] **Test offline**: desconectar wifi del PC y dictar 1 frase. Debe funcionar igual. **Esto es el punto de venta on-prem hecho ante sus ojos** — enseñarles que han desconectado y sigue funcionando.
- [ ] Reactivar wifi.

### Bloque 7 — Formación por usuario (1:00–2:00, 10-15 min cada uno)

Por cada empleado, en su propio puesto:

- [ ] Demostrar el flujo básico: cursor en Word → mantener botón PTT → "Buenos días, hemos comenzado los trabajos de encofrado en la obra de la calle Mayor número 14." → soltar botón → ver texto aparecer.
- [ ] Hacer que el empleado dicte él mismo **1 frase real** que escribiría hoy. No artificial.
- [ ] Mostrar corrección automática (mayúsculas, puntos).
- [ ] Mostrar cómo añadir una palabra al glosario (si dice "Caterpillar" y sale mal, cómo arreglarlo).
- [ ] Mostrar cómo desactivar momentáneamente (a veces no quieres que se active si te llaman).
- [ ] Dejar al empleado **probar él solo 2-3 minutos** mientras Marc observa en silencio. Anotar fricción real.

### Bloque 8 — Sesión grupal cierre (2:00–2:30)

- [ ] Reunir a los 2-3 usuarios + familiar + socio/jefe si está.
- [ ] **NO** hacer presentación. Conversación: "¿qué os ha parecido en estos 10 min?", "¿qué cosa concreta haríais con esto mañana?".
- [ ] Explicar el flujo de soporte durante el mes: "tenéis mi WhatsApp directo, cualquier cosa me decís y respondo en <24 h".
- [ ] Explicar qué métricas se medirán (ver `metricas_piloto.md`) — **sin pedirles que rellenen nada complicado**, Marc llamará cada semana.
- [ ] Acordar fecha de reunión de cierre (día +30).
- [ ] Si el familiar quiere firmar el `acuerdo_simple.md`, hacerlo aquí. Si prefiere "palabra de familia", anotar mentalmente y registrarlo en email a posteriori.

### Bloque 9 — Antes de marcharse (2:30–3:00)

- [ ] Dejar **1 hoja A4 impresa por puesto** con: cómo activar el dictado en 3 pasos + teléfono y email de Marc + cómo desinstalar si quisieran (sin condiciones).
- [ ] Foto/screenshot del setup (consentida) — para tener referencia técnica si hay que dar soporte remoto.
- [ ] Despedida humana. Si el familiar invita a comer, **aceptar** — el caso de estudio se construye también en la sobremesa.

---

## DESPUÉS — al volver a casa (mismo día o día siguiente)

### Bloque 10 — Higiene post-setup

- [ ] **Log de la sesión** en `/home/claude/logs/piloto_construccion_setup_<fecha>.md` con: configuración exacta de cada PC, problemas encontrados, soluciones aplicadas, feedback verbal en bruto.
- [ ] **Actualizar `metricas_piloto.md`** con la baseline observada (¿qué velocidad de teclado tienen? — si Marc se acuerda).
- [ ] **WhatsApp de agradecimiento** al familiar (1 línea, humano, no comercial).
- [ ] **Calendario:** poner recordatorio para llamada de seguimiento día +3 (chequear que no hay problemas en frío).
- [ ] **Calendario:** poner reunión de cierre día +30 (debería estar acordada ya, si no, agendarla por email).

### Bloque 11 — Material a revisar después

- [ ] ¿Funcionó el glosario construcción en términos reales que dictaron? Si no, ampliar antes del día +7.
- [ ] ¿Hubo algún término valenciano (estaca = "pal", ladrillo = "rajola") que sería conveniente añadir?
- [ ] ¿Algún empleado mostró fricción con el botón PTT del ratón? Si sí, valorar configuración alternativa con tecla del teclado.

---

## Errores a evitar el día D

- **No hacer "instalación silenciosa"** en plan informático que viene 30 min y se va. Cada empleado tiene que tocar el sistema con las manos en presencia de Marc. Si no toca, no se siente dueño, no lo usa al día siguiente.
- **No prometer features no implementadas** ("la semana que viene te activo la integración con Sage"). Solo prometer lo que está hecho. Cualquier feature aspiracional se anota como follow-up y se valora.
- **No instalar en el PC del jefe si no lo va a usar.** Mejor 3 PCs con uso real que 5 con uso decorativo. El piloto se mide por uso real, no por puestos instalados.
- **No quedarse callado durante la formación** observando. Pero **tampoco hablar mientras el empleado prueba** — esos 2-3 min en silencio observando son donde se aprende la fricción real.
- **No exportar audio del cliente, ni texto del cliente, fuera de su oficina.** Bajo ninguna circunstancia, ni para "depuración remota". Si hay un bug, se reproduce en local en casa de Marc con su propio audio.
