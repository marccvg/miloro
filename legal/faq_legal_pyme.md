---
titulo: "FAQ legal pyme — Parla (dictado por voz local)"
tipo: faq_legal
audiencia: pyme decisora de compra
creado: 2026-05-14
version: 1.0-draft
disclaimer: Información orientativa. No constituye asesoramiento legal. Para casos concretos consultar abogado especialista.
---

# FAQ legal pyme — Parla

**Las 10 preguntas que más nos hacen los clientes pyme antes de firmar.**

> Lenguaje directo, sin abogadesco. Cuando una respuesta depende del caso concreto lo decimos explícitamente.

---

## 1. ¿Parla cumple el AI Act europeo?

**Sí, por arquitectura.** El AI Act clasifica los sistemas de IA por riesgo. Parla es una herramienta de productividad ofimática (dictado de tu propia voz al cursor) que cae en la categoría de **riesgo mínimo**: no clasifica personas, no toma decisiones automatizadas, no genera contenido sintético engañoso. La categoría de riesgo mínimo no tiene obligaciones específicas más allá del marco general.

Además, Parla procesa el audio **localmente en tu equipo**, lo que evita los aspectos del AI Act y del RGPD que más quebraderos dan a las pymes: transferencias internacionales, contratos con proveedores cloud, evaluaciones de impacto extensas.

**Lo que no diremos:** que Parla está "certificado AI Act". El AI Act no certifica productos de riesgo mínimo. Quien venda "sello AI Act" para un dictado por voz, miente.

---

## 2. ¿Y el RGPD? ¿Necesito hacer evaluación de impacto?

**En la mayoría de pymes, no.** La evaluación de impacto en protección de datos (EIPD, Art. 35 RGPD) es obligatoria cuando un tratamiento implica alto riesgo para los derechos de las personas. Un dictado local de notas que **nunca sale del equipo** no encaja en los supuestos típicos que activan EIPD.

**Excepciones a considerar:**

- Si dictas masivamente datos de categorías especiales (salud, religión, orientación política, etc.) y los almacenas estructurados, es razonable hacer EIPD por la naturaleza de los datos, no por Parla en sí.
- Si tu sector ya tiene EIPD obligatoria (sanitario al detalle, banca, biometría), Parla será solo una línea más en esa EIPD existente.

Tu DPO o asesor de protección de datos lo confirmará en 30 minutos.

---

## 3. ¿La voz de mis empleados es dato personal?

**Sí.** El audio que identifica a una persona es dato personal (Art. 4.1 RGPD). Si se procesa específicamente para identificar al hablante, se considera **dato biométrico** (Art. 9 RGPD), de categoría especial con régimen reforzado.

**Importante con Parla:** Parla no hace identificación biométrica. Transcribe la voz a texto y descarta el audio. No mantiene registros del hablante. Pero sigues siendo responsable de informar a los empleados de que dispones de un sistema de transcripción (modelo de política interna en la plantilla DPA).

---

## 4. ¿Necesito firmar un DPA con vosotros?

**Estrictamente, no, en el caso por defecto.** Un DPA (Art. 28 RGPD) regula el tratamiento que un encargado hace **por cuenta del responsable**. Parla no procesa tus datos: el audio y las transcripciones se quedan en tu equipo. No somos encargado del tratamiento.

**Pero te entendemos:** muchas pymes en sectores regulados (legal, sanitario, financiero) tienen política interna de pedir DPA a todo proveedor de software por seguridad procedimental. Para esos casos te facilitamos una **plantilla DPA ligera** (`dpa_template.md`) que refleja exactamente la situación: Parla no es encargado, salvo en escenario puntual de soporte donde compartas voluntariamente datos con nosotros, y para ese caso recoge las garantías estándar.

---

## 5. ¿Qué pasa si abro un ticket y os mando un fragmento de transcripción?

En ese momento puntual sí pasamos a tratar tus datos. Aplicamos:

- Tratamiento solo para resolver el ticket.
- Borrado a los 90 días del cierre.
- Acceso restringido al personal técnico que atiende el caso.
- Sin uso para entrenamiento ni analítica.

Si quieres evitarlo, anonimiza el fragmento antes de enviarlo (sustituye nombres y números por `XXXX`). Parla funciona igual de bien con texto anonimizado a efectos de diagnóstico.

---

## 6. ¿Tenéis servidores en EE.UU. o fuera de la UE?

**Nuestra arquitectura de producto no usa servidores para procesar tu voz: el procesamiento es local en tu equipo.** La infraestructura corporativa (web, facturación, ticketing) sí usa proveedores comerciales, pero **ninguno tiene acceso a audio ni transcripciones de los clientes**.

Listamos los proveedores de infraestructura corporativa en el DPA y notificamos cualquier cambio con 30 días de antelación.

---

## 7. Soy abogado / médico / asesor fiscal. ¿Hay problema con el secreto profesional?

**Al contrario: Parla es el escenario favorable.** El secreto profesional (Art. 542 LOPJ para abogados; Art. 7 Ley 41/2002 para sanitarios; deontología contable) penaliza la divulgación de información confidencial a terceros. Las herramientas cloud te obligan a explicar contractualmente cómo controlas que el proveedor cloud no acceda a esa información. Con Parla local, el control es físico: el audio no sale del equipo.

Para reforzar:

- Activa cifrado de disco (BitLocker en Windows, FileVault en macOS).
- Bloquea sesión al ausentarte.
- Si trabajas con expedientes muy sensibles, usa la modalidad on-prem (servidor en la propia oficina) en vez de instalación en laptop personal.

---

## 8. ¿Y si la AEPD me audita? ¿Qué documentación necesito tener?

Documentación razonable (no obligatoria al 100%, pero recomendable):

1. **Registro de actividades del tratamiento** (Art. 30 RGPD) con entrada "Transcripción local de notas de voz mediante Parla".
2. **Política interna de uso** firmada y comunicada al personal (modelo en plantilla DPA, Anexo I).
3. **DPA con Parla** si tu política interna te lo exige (plantilla disponible).
4. **Análisis básico**: por qué el tratamiento es de riesgo bajo (Parla es local; audio descartado; sin transferencias).
5. **Configuración técnica del equipo**: cifrado, control de acceso, copias de seguridad.

Con esa carpeta de 5 documentos cubres el 95% de lo que la AEPD pide en una inspección rutinaria para una herramienta de dictado.

---

## 9. ¿Qué hago si un empleado deja la empresa y dictó información sensible?

Tres aclaraciones:

1. **Parla no guarda las transcripciones.** Las transcripciones que existan están donde el empleado las pegó (documentos Word, correos, expedientes en gestor documental). Su gestión sigue el procedimiento normal de baja de empleado: revocación de accesos, copia/borrado de su carpeta personal.
2. **El audio no existe.** Parla descarta el audio inmediatamente tras transcribir. No hay "histórico de audios" del empleado.
3. **Si quieres revocar Parla en su equipo**, desinstala el software. No queda artefacto residual con datos.

---

## 10. ¿Cuánto cuesta el "cumplimiento" si os compro?

**El software ya incluye el cumplimiento por diseño.** No te cobramos por separado:

- ✅ Plantilla DPA: incluida con la licencia.
- ✅ Whitepaper AI Act: público en nuestra web.
- ✅ Modelo de política interna de uso: incluido en la plantilla DPA.
- ✅ FAQ legal (este documento): pública.

Si necesitas **sesión técnica-legal con nuestro equipo** para revisar tu caso concreto (típico en sectores regulados), está incluida en los planes B2B Pyme Setup y Premium. En B2C Lifetime no se incluye pero la podemos cotizar puntualmente.

**Coste externo opcional:** si tu abogado quiere revisar la plantilla DPA antes de firmarla, ronda los **€80-200 por una hora de consulta** con un especialista en IA/datos. Es buena inversión. No te diremos lo contrario.

---

## ¿Más preguntas?

- Whitepaper completo del encaje con AI Act: `whitepaper_ai_act_parla.md`.
- Plantilla DPA con cláusulas: `dpa_template.md`.
- Contacto legal: [pendiente — completar al cerrar Fase 1].

---

**Disclaimer:** las respuestas anteriores son orientativas y reflejan el estado normativo a fecha **2026-05-14**. **No constituyen asesoramiento legal.** Para situaciones específicas, especialmente en sectores regulados, consulte a un abogado especialista en protección de datos y derecho digital. Parla no asume responsabilidad por decisiones empresariales tomadas únicamente con base en esta FAQ.
