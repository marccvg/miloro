---
titulo: Acuerdo simple piloto — gentleman's agreement 30-60 días
tipo: instruccion
creado: 2026-05-14
actualizado: 2026-05-14
tags: [piloto, construccion, acuerdo, contrato, legal-ligero]
---

# Acuerdo simple piloto Parla

> **Naturaleza:** acuerdo de palabra entre familia, formalizado en una página A4 firmada por ambas partes solo si el cliente lo pide expresamente. No es un contrato mercantil ni genera obligaciones legalmente exigibles más allá de lo aquí descrito. Su función es **dejar por escrito las reglas del juego para que nadie tenga que recordarlas de memoria al cabo de 30 días.**
>
> Si el familiar prefiere "palabra y ya está", Marc deja constancia en email (`email_seguimiento.md` Versión A ya cumple esta función) y archiva el email — sirve como prueba documental suficiente para algo de esta escala.

---

## Modalidad de despliegue del piloto

Dos opciones a presentar al cliente — se elige en la primera reunión, no por defecto:

### Modalidad LIGHT (recomendada Fase 0)

- Instalación **directa sobre los PCs de cada empleado** (2-3 puestos).
- Sin mini-server on-prem.
- **Coste hardware adicional:** 0 €.
- **Tiempo setup:** 2-3 h.
- **Limitación:** glosario y configuración no compartidos entre PCs. Si el cliente quiere ampliar a 5+ puestos tras el mes, se valora pasar a modalidad ON-PREM.

### Modalidad ON-PREM (solo si tras mes 1 amplían a 5+ puestos)

- **Mini-PC** (Intel NUC / Beelink / Jetson) en la oficina, ~€500-700.
- Hardware lo compra el cliente directo (NO se factura desde Parla — decisión 2026-05-13).
- Glosario corporativo compartido, backups centralizados.
- Setup adicional: 1 día.

**Para este piloto se asume modalidad LIGHT** salvo decisión contraria explícita.

---

## Versión imprimible (A4, 1 página)

> Si el cliente quiere firma física, imprimir este bloque, rellenar campos, firmar a mano.

```
─────────────────────────────────────────────────────────────────────
ACUERDO DE PILOTO PARLA
─────────────────────────────────────────────────────────────────────

Entre:
  Marc [APELLIDOS], DNI [_______________], en adelante "el proveedor"
y
  [EMPRESA CLIENTE S.L.], CIF [_______________], representada por
  [nombre del responsable], en adelante "el cliente"

Ambas partes acuerdan ejecutar una prueba piloto de la herramienta
Parla en las oficinas del cliente, en los siguientes términos:

1. DURACIÓN
   30 días naturales desde la fecha de instalación.
   Ampliable de mutuo acuerdo hasta 60 días.
   Fecha de instalación: [____ / ____ / 2026]
   Fecha de cierre prevista: [____ / ____ / 2026]

2. ALCANCE
   Instalación del software Parla en hasta 3 (tres) puestos de
   trabajo (PCs) del cliente, a designar por el cliente.
   Formación inicial de 10-15 min por usuario.
   Soporte por teléfono / WhatsApp / email durante el periodo, con
   respuesta en menos de 24 h en días laborables.

3. COSTE
   El piloto tiene coste 0 € para el cliente durante los 30 días.
   No hay obligación de continuar al término del periodo.

4. PROPIEDAD DE LOS DATOS
   Todos los audios, textos transcritos, glosarios corporativos y
   datos generados por el uso del software permanecen en los equipos
   del cliente. El proveedor NO accede a ellos durante el piloto
   (salvo intervención presencial autorizada por el cliente para
   resolver incidencias).
   El proveedor NO envía ningún dato del cliente fuera de la
   oficina, ni a servidores propios, ni a terceros.

5. COMPROMISOS DEL CLIENTE
   a) Facilitar acceso a los PCs y wifi de la oficina durante la
      instalación.
   b) Asignar a los empleados que vayan a usar el sistema durante
      el piloto.
   c) Mantener una conversación de cierre el día +30 con el
      proveedor para revisar resultados.
   d) Si el resultado es satisfactorio para ambas partes, autorizar
      al proveedor a usar la experiencia como CASO DE ESTUDIO en
      conversaciones comerciales con otros potenciales clientes,
      pudiendo mantener anonimato si el cliente lo solicita.
      (Esta autorización NO es condición para iniciar el piloto.)

6. COMPROMISOS DEL PROVEEDOR
   a) Realizar la instalación inicial sin coste.
   b) Atender soporte durante los 30 días según se ha descrito.
   c) Si al final del piloto el cliente decide NO continuar:
      desinstalación completa del software de los PCs del cliente,
      sin coste, sin condiciones, sin penalización.
   d) Confidencialidad sobre los datos del cliente, durante el
      piloto y después, indefinidamente.

7. QUÉ PASA DESPUÉS DEL DÍA 30
   En la reunión de cierre, las partes acuerdan una de tres vías:
     (A) CONTINUAR: pasar a contrato estándar de mantenimiento.
         El importe y condiciones se acordarán en ese momento, NO
         están prefijados en este acuerdo.
     (B) PAUSAR: el cliente conserva el software instalado pero
         sin soporte ni actualizaciones. Si en 6 meses decide
         retomar, se reactiva sin coste de setup.
     (C) DESINSTALAR: el proveedor retira el software. Sin coste.

8. EXCLUSIONES
   Este piloto NO incluye:
   - Adquisición de hardware adicional (micrófonos, mini-servers).
   - Integraciones con software de gestión del cliente (Sage, A3,
     etc.) — valorables como proyecto separado en fase posterior.
   - Garantía de funcionamiento perfecto durante el piloto: por
     definición un piloto sirve para encontrar fallos y corregirlos.

9. RESOLUCIÓN ANTICIPADA
   Cualquiera de las partes puede dar por terminado el piloto en
   cualquier momento, notificándolo por email o WhatsApp, sin
   penalización para ninguna parte.

10. NATURALEZA DEL ACUERDO
    Este documento refleja un acuerdo de buena fe entre las partes,
    sin pretensión de generar obligaciones contractuales más allá
    de las aquí descritas. Cualquier desarrollo comercial
    posterior se formalizará en su momento mediante el contrato
    correspondiente.


Firmado en [_______________], a [____] de [____________] de 2026.


    Por el proveedor                   Por el cliente

    __________________                 __________________
    Marc [APELLIDOS]                   [Nombre]
                                       [Cargo]

─────────────────────────────────────────────────────────────────────
```

---

## Versión "palabra de familia" (si NO se firma)

Si el familiar dice "no hace falta papel, palabra y ya está", Marc:

1. Envía un email a posteriori con asunto "Resumen del acuerdo del piloto" que reproduzca los puntos 1, 2, 3, 4, 6, 7, 9 del bloque firmable (omitiendo la palabra "acuerdo formal", reemplazando por "para que lo tengamos por escrito").
2. Pide al familiar que responda "ok" o equivalente. Ese "ok" + el email original son la traza documental.
3. Archiva email en local + copia a la carpeta `/home/Projects/parla/clientes/piloto_construccion_familiar/correspondencia/` (carpeta a crear cuando exista la primera respuesta).

---

## Lo que el acuerdo NO debe contener (decisión consciente)

- **Cláusulas de exclusividad.** El cliente puede tener cualquier otro proveedor.
- **Penalización por terminación.** Cero. Es un piloto.
- **Obligación de testimonio público.** El testimonio es deseado, pero NO condición.
- **NDA bidireccional fuerte.** Mutuamente innecesario en familia + escala pequeña. Si el cliente lo pide, se valora — pero no se promueve.
- **Garantías de SLA específicas en porcentaje.** El piloto es informal por diseño. SLA real solo en contrato post-piloto.
- **Pricing post-piloto.** Se conoce la cifra interna (€2.250 + €200/mes según `pricing_recomendado.md`), pero NO se mete en el documento del piloto — eso es conversación de mes +2.

---

## Cross-link

- `script_llamada.md` — paso previo: conseguir la reunión.
- `email_seguimiento.md` — paso 2: documentar por escrito antes de ir.
- `propuesta_1pag.md` — paso 3: material para reunión.
- `checklist_setup_oficina.md` — paso 4: instalación día D.
- Este documento → paso 5: formalización (opcional).
- `metricas_piloto.md` → paso 6: medición durante el mes.
- `faq_anticipadas.md` → soporte para todas las conversaciones.
- `/home/Projects/parla/pricing/pricing_recomendado.md` — tarifa real post-piloto (interno, no enseñar).
