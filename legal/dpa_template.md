---
titulo: "Plantilla DPA — Acuerdo de tratamiento de datos para Parla"
tipo: plantilla_contractual
audiencia: cliente pyme (responsable del tratamiento)
creado: 2026-05-14
version: 1.0-draft
disclaimer: Plantilla informativa. No constituye asesoramiento legal. Antes de firmar revisar con abogado especialista en protección de datos.
---

# Plantilla DPA (Data Processing Agreement)

**Acuerdo de tratamiento de datos personales conforme al artículo 28 del Reglamento (UE) 2016/679 (RGPD).**

> **Importante:** Parla opera como herramienta **local en el equipo del cliente**. En la mayoría de casos prácticos **el proveedor de Parla no es encargado del tratamiento**, porque no procesa datos personales del cliente: el audio nunca sale del equipo. Esta plantilla está pensada para los escenarios en que el cliente, por política interna o requisito sectorial, exija un DPA firmado de todos modos — típicamente sectores sanitario, jurídico, financiero o público. En esos casos se firma una versión **muy ligera**, casi declarativa, reconociendo que la arquitectura del producto excluye el tratamiento por encargado.

**Disclaimer:** este documento es plantilla informativa. **No constituye asesoramiento legal.** Adáptelo con su abogado antes de firmar.

---

## Datos a cumplimentar antes de firmar

| Campo | Valor |
|---|---|
| **Responsable del tratamiento** (Cliente) | [Razón social, NIF, dirección, persona firmante] |
| **Proveedor** (Parla) | [Razón social del titular de Parla, NIF, dirección] |
| **Fecha de firma** | [DD-MM-AAAA] |
| **Versión del software Parla** | [p.ej. Parla 1.0.0] |
| **Modalidad contratada** | B2C Lifetime / B2B Pyme Setup / B2B Pyme Premium |

---

## Cláusula 1 — Objeto y naturaleza del tratamiento

El presente acuerdo regula las eventuales obligaciones del Proveedor en relación con datos personales del Responsable, en el marco del uso del software Parla, herramienta de transcripción local de voz a texto.

**El Proveedor declara y el Responsable acepta** que el software Parla procesa el audio capturado **exclusivamente en el dispositivo del Responsable** (laptop, mini-PC on-prem o estación de trabajo). El audio no se transmite a servidores del Proveedor ni a terceros. En consecuencia, **el Proveedor no actúa como encargado del tratamiento** respecto del audio ni de las transcripciones generadas.

Las funciones del Proveedor en virtud de la relación comercial se limitan a:

a) Suministro, actualización y soporte del software.
b) Soporte técnico bajo petición expresa del Responsable.
c) En caso de que el Responsable comparta voluntariamente datos personales para resolver una incidencia (p.ej. un fragmento de transcripción en un ticket), el Proveedor los tratará como **encargado puntual** según las cláusulas siguientes.

---

## Cláusula 2 — Datos personales potencialmente afectados (escenario de soporte)

| Tipo de dato | Origen | Finalidad | Conservación |
|---|---|---|---|
| Texto de transcripción adjuntado por el Cliente en un ticket | Iniciativa del Cliente | Resolución de la incidencia | Borrado a los 90 días del cierre del ticket |
| Datos de contacto del Cliente | Alta del servicio | Facturación y soporte | Plazos legales aplicables (6 años fiscal / mientras dure el contrato) |
| Logs técnicos del software (sin contenido de audio ni texto del usuario) | Generados localmente, enviados solo bajo solicitud | Diagnóstico | 30 días |

**El Proveedor no trata habitualmente audio del Cliente.** Si en un caso excepcional fuera necesario para depurar un fallo, se solicitará consentimiento expreso por escrito y se borrará tras la resolución.

---

## Cláusula 3 — Obligaciones del Proveedor (cuando actúe como encargado puntual)

El Proveedor se compromete a:

1. Tratar los datos únicamente para la finalidad expresamente solicitada por el Responsable.
2. Mantener confidencialidad sobre los datos a los que acceda, extensible al personal que intervenga.
3. Aplicar medidas técnicas y organizativas apropiadas (Art. 32 RGPD): control de acceso al ticketing, cifrado en reposo de los sistemas de soporte, registro de accesos.
4. No subcontratar el tratamiento sin autorización previa por escrito del Responsable. El Proveedor mantiene una lista actualizada de subencargados disponible bajo petición; a la firma de este DPA, **no hay subencargados que accedan a datos del Responsable**.
5. Asistir al Responsable en el cumplimiento de sus obligaciones (atención de derechos del interesado, EIPD, notificación de brechas).
6. Devolver o suprimir los datos al término del soporte, según elija el Responsable, salvo obligación legal de conservación.
7. Notificar al Responsable cualquier brecha de seguridad que afecte a sus datos en un plazo **máximo de 72 horas** desde su conocimiento.
8. Poner a disposición del Responsable la información necesaria para acreditar el cumplimiento del Art. 28 RGPD.

---

## Cláusula 4 — Obligaciones del Responsable

El Responsable se compromete a:

1. Determinar la finalidad y los medios del tratamiento de los datos generados con Parla (transcripciones).
2. Informar a los interesados (empleados, clientes finales si procede) del uso de Parla.
3. Implantar política interna de uso del software (modelo en Anexo I).
4. Garantizar seguridad física y lógica del equipo donde corre Parla: cifrado de disco, control de acceso, gestión de actualizaciones del sistema operativo.
5. Asegurar que, si comparte datos con el Proveedor para soporte, dichos datos están minimizados al estrictamente necesario.

---

## Cláusula 5 — Subencargados

A fecha de firma, el Proveedor **no utiliza subencargados** que tengan acceso a datos personales del Responsable. Cualquier futura incorporación requerirá comunicación previa con 30 días de antelación, dando al Responsable derecho a oponerse y, en su caso, resolver el contrato sin penalización.

Servicios de infraestructura del Proveedor (alojamiento de la web corporativa, sistema de facturación, herramienta de ticketing) se listan informativamente:

- [Hosting corporativo: por cumplimentar]
- [Facturación: por cumplimentar]
- [Ticketing: por cumplimentar]

Estos servicios **no acceden** a audio ni transcripciones del Cliente.

---

## Cláusula 6 — Transferencias internacionales

El Proveedor declara que **no realiza transferencias internacionales** de datos personales del Responsable fuera del Espacio Económico Europeo. El procesamiento del audio se efectúa exclusivamente en el equipo del Responsable.

Si el Responsable elige proveedores de infraestructura propios (p.ej. backup en cloud público) fuera del EEE, será responsable de implementar las garantías apropiadas (Cap. V RGPD).

---

## Cláusula 7 — Duración

Este acuerdo tiene la misma duración que el contrato principal de licencia o servicio entre las Partes. Las obligaciones de confidencialidad subsisten cinco (5) años tras la finalización.

---

## Cláusula 8 — Ley aplicable y jurisdicción

Este acuerdo se rige por la legislación española y, supletoriamente, por el RGPD. Las Partes se someten a los Juzgados y Tribunales de [ciudad sede del Proveedor], salvo que la legislación imperativa de protección al consumidor disponga otra cosa.

---

## Firmas

| Por el Responsable (Cliente) | Por el Proveedor (Parla) |
|---|---|
| Nombre: | Nombre: |
| Cargo: | Cargo: |
| Fecha: | Fecha: |
| Firma: | Firma: |

---

## Anexo I — Modelo de política interna de uso

**Política interna de uso de Parla (dictado por voz local)**

Esta empresa pone a disposición de su personal el software Parla para acelerar la redacción de documentos mediante dictado por voz al cursor.

**Cómo funciona Parla (resumen para empleados):**

- Parla escucha cuando mantienes pulsado un botón configurado (típicamente lateral del ratón). Cuando sueltas, transcribe lo dicho e inserta el texto donde está el cursor.
- **Tu voz no sale del equipo.** No se envía a internet. No se almacena. No se utiliza para entrenar modelos.
- El texto generado queda en el documento donde lo dictes (Word, correo, gestor documental). Su tratamiento posterior es el mismo que el de cualquier texto que escribas con el teclado.

**Buenas prácticas:**

1. Si dictas información confidencial de un cliente, mantén las mismas precauciones que tendrías al escribirla: no dejar el equipo desbloqueado, no dictar en espacios públicos donde puedan escucharte.
2. Si dictas datos personales de terceros, asegúrate de que el destino del texto (correo, documento) tiene los controles de acceso adecuados.
3. Si detectas algún comportamiento anómalo del software (errores, lentitud), notifica a [persona responsable].

**Derechos del personal:**

- El uso de Parla es **opcional**. Nadie está obligado a usarlo.
- La empresa **no monitoriza** lo que dictas. Parla no tiene función de envío de transcripciones a la empresa.
- Si te preocupa la privacidad, consulta al delegado de protección de datos (DPO) de la empresa: [contacto].

Firmado y publicado por la dirección, [fecha].

---

## Anexo II — Notificación de incidente (plantilla)

En caso de brecha de seguridad relevante en el software Parla, el Proveedor notificará al Responsable en un plazo máximo de **72 horas desde el conocimiento del incidente**, incluyendo al menos:

1. Naturaleza del incidente y datos afectados (en su caso).
2. Volumen aproximado de interesados afectados.
3. Consecuencias probables.
4. Medidas adoptadas o propuestas.
5. Punto de contacto para más información.

Canal de notificación: [correo legal de Parla, pendiente de habilitar].

---

**Disclaimer final:** esta plantilla es un punto de partida razonable para la mayoría de pymes españolas que utilicen Parla. **No sustituye la revisión por un abogado.** Sectores regulados (sanidad, banca, telecos, defensa) o tratamientos a gran escala pueden requerir cláusulas adicionales. Parla no asume responsabilidad por la firma de esta plantilla sin revisión legal independiente.
