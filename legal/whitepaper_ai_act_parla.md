---
titulo: "Whitepaper — Parla y el AI Act europeo"
tipo: whitepaper_legal
audiencia: pyme (cliente / decisor de compra)
creado: 2026-05-14
version: 1.0-draft
disclaimer: Este documento es informativo. No constituye asesoramiento legal. Para una valoración aplicable a su empresa consulte a un abogado especialista en IA y protección de datos.
---

# Parla y el AI Act europeo

**Cómo encaja Parla (dictado por voz local) con el Reglamento (UE) 2024/1689 sobre Inteligencia Artificial.**

> Este whitepaper está pensado para responsables de pymes, despachos profesionales y oficinas técnicas que se preguntan: "si compro Parla, ¿estoy en regla?". La respuesta corta es **sí, por diseño**. Las páginas que siguen explican por qué, sin jerga.

---

## 1. Qué es el AI Act, en una página

El **AI Act** (Reglamento (UE) 2024/1689) es la primera ley europea que regula los sistemas de inteligencia artificial. Se publicó en el Diario Oficial de la UE en julio de 2024 y entró en vigor el 1 de agosto de 2024. Su aplicación es progresiva:

| Fecha | Qué empieza a aplicar |
|---|---|
| 2 de febrero de 2025 | Prohibiciones (puntuación social, manipulación, reconocimiento biométrico en tiempo real en espacios públicos con excepciones, etc.). |
| 2 de agosto de 2025 | Obligaciones para modelos de IA de propósito general (GPAI). |
| 2 de agosto de 2026 | La mayoría de las obligaciones (transparencia, gobernanza, sanciones). |
| 2 de agosto de 2027 | Régimen pleno de sistemas de "alto riesgo". |

La lógica del reglamento es **proporcional al riesgo**. No todos los sistemas de IA se tratan igual:

| Nivel de riesgo | Ejemplo | Obligación principal |
|---|---|---|
| **Inaceptable** (prohibido) | Puntuación social tipo "crédito ciudadano". | Prohibido. |
| **Alto** | IA en sanidad, RR.HH., justicia, infraestructuras críticas. | Evaluación de conformidad, registro, supervisión humana, documentación técnica. |
| **Limitado** | Chatbots, generadores de imagen/voz sintética, IA conversacional. | Obligaciones de transparencia (informar al usuario de que interactúa con IA o que el contenido es generado). |
| **Mínimo** | Filtros antispam, asistentes ofimáticos, autocorrector, **dictado al cursor**. | Sin obligaciones específicas más allá del marco general. |

**Dónde se ubica Parla:** el dictado por voz al cursor — convertir tu propia voz, en tiempo real, en texto que se inserta donde estás escribiendo — es **una herramienta de productividad de riesgo mínimo**. No clasifica personas, no toma decisiones automatizadas con efecto jurídico, no genera contenido sintético que pueda confundir al receptor. Es un teclado más rápido.

---

## 2. Por qué Parla cumple por diseño

Parla no procesa tu voz en la nube. La transcripción ocurre **íntegramente en el equipo del cliente** (laptop o mini-PC on-prem en la oficina). Esto no es un detalle de marketing: es el eje arquitectónico del producto y tiene tres consecuencias legales directas.

### 2.1. Sin transferencias internacionales de datos personales

El audio de la voz de un trabajador es **dato personal** (Art. 4.1 RGPD) y, si se procesa de forma que permita identificar al hablante, puede llegar a considerarse **dato biométrico** (Art. 9 RGPD), de categoría especial.

- Con productos cloud (Wispr Flow, Otter, Dragon Anywhere): el audio sale del equipo y viaja a servidores típicamente fuera de la UE. Esto activa el régimen de transferencias internacionales (Cap. V RGPD), cláusulas contractuales tipo, evaluaciones de impacto, etc.
- Con Parla: el audio **nunca sale del equipo**. No hay transferencia. No hay tratamiento por encargado externo. No hay subencargados en EE.UU. La conversación termina antes de empezar.

### 2.2. Minimización de datos por arquitectura (Art. 5.1.c RGPD)

El RGPD obliga a tratar **solo los datos necesarios** para la finalidad. Parla cumple esto físicamente: el audio se descarta tras la transcripción, no se almacena, no se entrena ningún modelo con la voz del cliente. Lo único que persiste es el **texto transcrito** que el propio usuario decide guardar donde quiera (Word, correo, gestor documental).

### 2.3. Encaje natural en sectores regulados

Para abogados (secreto profesional, Art. 542 LOPJ), médicos (Art. 7 Ley 41/2002), gestorías (LOPDGDD + secreto profesional contable) o aseguradoras, el envío de audio de cliente a un proveedor cloud requiere documentación extensa: análisis de riesgo, DPA específico, posible auditoría. Con Parla local-only, ese análisis es **trivial**: no hay tratamiento por tercero.

---

## 3. Comparativa: Parla vs alternativas cloud

> **Importante:** esta comparativa refleja la información pública de cada producto a fecha **2026-05-14**. Las prácticas pueden cambiar; comprobar siempre la política vigente del proveedor antes de decidir.

| Atributo | Parla (local) | Wispr Flow | Otter.ai | Dragon Anywhere (Nuance) |
|---|---|---|---|---|
| Procesamiento de audio | Local en el equipo del cliente | Cloud (servidores EE.UU.) | Cloud (servidores EE.UU.) | Cloud (servidores Microsoft) |
| Transferencia internacional | Ninguna | Sí (UE → EE.UU.) | Sí (UE → EE.UU.) | Sí (UE → EE.UU./otros) |
| Almacenamiento de audio | No (audio se descarta tras transcribir) | Variable según plan | Sí (archivo de transcripciones) | Variable |
| Uso del audio para entrenar modelos | No | Revisar política vigente | Revisar política vigente | Revisar política vigente |
| DPA estándar disponible | Sí (plantilla incluida) | Sí (anglosajón) | Sí (anglosajón) | Sí |
| Idioma del soporte legal | Castellano (factura ES, contrato ES) | Inglés | Inglés | Mixto |
| Análisis de impacto (EIPD) necesario | Trivial / no aplica | Recomendable | Recomendable | Recomendable |

**Lectura honesta:** las herramientas cloud no son ilegales. Pero exigen del cliente trabajo administrativo (DPA, EIPD, transferencia) que Parla evita por arquitectura. Para una pyme sin departamento legal interno, esa diferencia es **horas de gestoría / abogado ahorradas cada año**.

---

## 4. Obligaciones del cliente al usar Parla (resumen práctico)

Aunque Parla simplifique enormemente el cumplimiento, el cliente sigue siendo **responsable del tratamiento** de los datos que dicta. Lista corta:

1. **Informar a empleados** de que dispone de una herramienta de dictado local (política interna de uso). Modelo sugerido en `dpa_template.md`, sección "Política interna".
2. **Registro de actividades del tratamiento** (Art. 30 RGPD): incluir "Transcripción local de notas de voz" como actividad si el cliente está obligado a llevar el registro.
3. **Conservación**: las transcripciones que el cliente genere y guarde se rigen por sus propias políticas de retención (las que ya tenga para correos, documentos, expedientes).
4. **Acceso de terceros al equipo**: el equipo donde corre Parla es el punto de control. Encriptación de disco (BitLocker / FileVault / LUKS) y control de acceso del usuario son responsabilidad del cliente.

---

## 5. Lo que Parla NO afirma

Para evitar el marketing inflado al que la regulación de IA es alérgica, dejamos claro lo que Parla **no** afirma:

- ❌ No está "certificado AI Act" — el AI Act no tiene un sello de certificación general para riesgo mínimo. Quien diga lo contrario está mintiendo.
- ❌ No está "auditado RGPD por la AEPD" — la AEPD no audita productos comerciales de forma genérica; audita responsables del tratamiento en casos concretos.
- ❌ No es un "sistema de IA de alto riesgo cumplidor" — porque no es de alto riesgo, no necesita serlo.
- ✅ Sí cumple por arquitectura los principios estructurales del AI Act y del RGPD aplicables a una herramienta de productividad de riesgo mínimo.

---

## 6. Próximo paso para el cliente

Si está evaluando Parla para su empresa y necesita material legal:

1. Pida la **plantilla DPA** (`dpa_template.md`) si necesita firmarla con su responsable de cumplimiento.
2. Consulte las **10 preguntas legales más frecuentes** (`faq_legal_pyme.md`).
3. Si tiene un caso de uso específico de **sector regulado** (sanitario, jurídico, financiero), agendamos sesión técnica-legal de 30 minutos para revisar encaje.

---

**Disclaimer:** este documento es informativo y refleja el estado del Reglamento (UE) 2024/1689 y del RGPD a fecha de elaboración. **No constituye asesoramiento legal.** Para una valoración aplicable a la situación concreta de su empresa, consulte a un abogado especialista en IA y protección de datos. Parla no asume responsabilidad por decisiones tomadas únicamente con base en este documento.

**Contacto legal de Parla:** [pendiente — completar al cerrar Fase 1].

**Versión:** 1.0-draft · **Fecha:** 2026-05-14 · **Próxima revisión prevista:** 2026-11-14 o al publicarse acto delegado relevante del AI Act, lo que ocurra primero.
