---
title: "AI Act EU: ¿afecta a tu pyme?"
slug: ai-act-eu-afecta-tu-pyme
date: 2026-05-14
draft: false
author: "Equipo Parla"
description: "Guía clara y sin jerga sobre el AI Act europeo aplicado a pymes españolas: qué se regula, qué plazos vienen, qué obligaciones tendrás si usas IA, y cómo reduce riesgos elegir herramientas locales por diseño."
tags: [ai-act, regulacion, pyme, gdpr, cumplimiento, eu]
categories: [regulacion]
og_image: /og/02-ai-act-pyme.png
canonical: https://parla.es/blog/ai-act-eu-afecta-tu-pyme
---

# AI Act EU: ¿afecta a tu pyme?

Si gestionas una pyme y has visto pasar titulares sobre el Reglamento Europeo de IA (AI Act) y no sabes si te concierne, este post es para ti. Vamos al grano: **sí, probablemente te afecta**, pero no como la mayoría piensa. La regulación es razonable, proporcional al riesgo, y la mayoría de pymes saldrá adelante sin grandes cambios. Eso sí, hay decisiones técnicas que hoy puedes tomar para no tener que rehacer nada cuando los plazos se vayan endureciendo.

Este artículo es un resumen práctico orientado a decisores no jurídicos. Para el documento técnico completo con citas a articulado, hemos publicado el [whitepaper "Parla y el AI Act europeo"](/legal/whitepaper-ai-act) (PDF, 18 páginas).

> **Aviso legal**: este post es informativo. No constituye asesoramiento legal. Para valoración aplicable a su empresa, consulte abogado especialista en IA y protección de datos.

## Qué es el AI Act, en cuatro líneas

El **Reglamento (UE) 2024/1689**, conocido como AI Act, es la primera ley europea que regula los sistemas de inteligencia artificial. Se publicó en julio de 2024 y entró en vigor el 1 de agosto de 2024. Su filosofía: regular **proporcional al riesgo**. No todos los sistemas de IA se tratan igual.

## Las cuatro categorías de riesgo

El reglamento clasifica los sistemas de IA en cuatro grupos. La categoría determina las obligaciones que aplican.

### 1. Riesgo inaceptable (prohibidos)

Se prohíben directamente. Algunos ejemplos:

- Sistemas de **puntuación social** al estilo chino.
- IA que **manipula el comportamiento** explotando vulnerabilidades (niños, personas con discapacidad).
- **Reconocimiento biométrico en tiempo real** en espacios públicos (con excepciones policiales muy limitadas).
- Categorización biométrica de personas por raza, opinión política, religión, etc.

**Aplicable a la pyme media**: prácticamente nunca. Estos casos los manejan grandes plataformas, no despachos ni gestorías.

### 2. Alto riesgo

Sistemas de IA usados en contextos sensibles: contratación de personal, educación, gestión migratoria, justicia, infraestructuras críticas, servicios esenciales. Tienen obligaciones fuertes: gestión de riesgos, supervisión humana, datasets de entrenamiento auditables, registro en base de datos UE.

**Aplicable a la pyme media**: depende del sector. Una gestoría laboral que use IA para **filtrar CVs automáticamente** ya entra aquí, por ejemplo. Un despacho de abogados que use IA para clasificar casos por probabilidad de éxito, también puede caer en esta categoría.

### 3. Riesgo limitado (obligaciones de transparencia)

Sistemas que **interactúan con personas** o **generan contenido**: chatbots, sistemas de transcripción que se publican, generación de imágenes. Obligación principal: informar al usuario de que está interactuando con una IA o que el contenido es generado.

**Aplicable a la pyme media**: si usas un chatbot en tu web, sí. Si usas dictado por voz para escribir un correo, **no**: el resultado lo firmas tú, no hay obligación de marcarlo como contenido IA.

### 4. Riesgo mínimo

La mayoría de aplicaciones de IA de uso común: filtros antispam, recomendaciones, asistentes de escritura, traductores, transcripción para uso interno. **No tienen obligaciones específicas** más allá del cumplimiento general (GDPR, ciberseguridad).

**Aplicable a la pyme media**: aquí caen el 90% de los usos cotidianos. Incluye herramientas como Parla cuando se usa para dictado al cursor.

## Plazos: lo que toca y cuándo

El despliegue del AI Act es escalonado:

| Fecha | Qué empieza a aplicar | Impacto pyme |
|---|---|---|
| **2 febrero 2025** | Prohibiciones (riesgo inaceptable) | Casi nulo en pyme normal |
| **2 agosto 2025** | Obligaciones para **modelos de IA de propósito general** (GPAI) — afecta a proveedores como OpenAI, Anthropic, Google | Indirecto: tus proveedores cumplen, tú no haces nada |
| **2 agosto 2026** | **Mayoría de obligaciones**: transparencia, gobernanza, sanciones | Sí: si usas IA en procesos sensibles |
| **2 agosto 2027** | Régimen pleno de sistemas de "alto riesgo" | Sí: revisión completa si tus usos son alto riesgo |

Es decir: en agosto de 2026 ya tienes que tener la casa en orden si usas IA en contextos sensibles. En agosto de 2027, plenamente.

## Sanciones: qué te juegas

Las sanciones del AI Act son del mismo orden que las del GDPR, y en algunos tramos superiores:

- Hasta **€35 millones o el 7% del volumen de negocios global** por usar sistemas prohibidos.
- Hasta **€15 millones o el 3% del volumen** por incumplir obligaciones de alto riesgo o GPAI.
- Hasta **€7,5 millones o el 1% del volumen** por suministrar información incorrecta a autoridades.

Para una pyme, el 7% del volumen es una cifra de cierre. Y el régimen sancionador no espera al 2027: las prohibiciones ya son aplicables.

## Las cinco preguntas que tienes que hacerte

Si quieres saber rápidamente si te afecta y en qué grado, contesta esto en una hoja:

### 1. ¿Usas IA?
Si usas un chatbot, un filtro de correo, una herramienta de transcripción, un asistente de redacción, una herramienta de análisis predictivo, un OCR moderno o cualquier producto con "AI" en el reclamo: sí, usas IA.

### 2. ¿Para qué procesos?
Procesos administrativos rutinarios (transcripción, redacción, traducción, filtrado) = riesgo mínimo. Procesos que afectan a personas (contratación, evaluación, scoring de clientes) = posiblemente alto riesgo.

### 3. ¿Dónde se procesan los datos?
**Cloud (servidores del proveedor)**: tienes obligaciones de tratamiento de datos GDPR. Si los datos salen de la UE, además, requisitos extra (cláusulas tipo, transfer impact assessment).
**Local (en tu propio equipo)**: el dato no sale. La superficie regulatoria se reduce drásticamente.

### 4. ¿El proveedor cumple GPAI?
Pregunta a tu proveedor si su modelo cumple las obligaciones GPAI vigentes desde agosto 2025. Si no sabe qué le estás preguntando, mala señal.

### 5. ¿Tienes documentado el uso?
Aunque tu uso sea de riesgo mínimo, tener documentado **qué IA usas, para qué, con qué datos y qué proveedor está detrás** te ahorrará disgustos en auditorías futuras. No es obligatorio explícitamente para riesgo mínimo, pero es buena práctica defensiva.

## Cómo elegir herramientas que reducen exposición regulatoria

No todas las decisiones técnicas tienen el mismo coste en términos de cumplimiento. Estas son las cuatro que más impacto tienen:

### 1. Local por diseño > cloud por diseño

Si los datos nunca salen de la máquina del empleado, no hay transferencia de datos a un tercero. Menos contratos, menos cláusulas, menos riesgo de fuga. Parla, por ejemplo, transcribe localmente: el audio del cliente nunca toca un servidor externo. Eso elimina una capa entera de complejidad GDPR.

### 2. Proveedor europeo > proveedor extra-UE

Aunque el AI Act es aplicable a todos los sistemas que operen en territorio europeo (incluidos proveedores estadounidenses, chinos, etc.), trabajar con un proveedor establecido en la UE simplifica la cadena: jurisdicción clara, soporte en idioma local, factura compatible.

### 3. Open-weight > propietario opaco

Los modelos abiertos (Whisper, Llama, Mistral) tienen ventajas regulatorias relevantes: puedes auditarlos, conoces sus limitaciones publicadas, y la responsabilidad de uso recae claramente en ti como deployer, no en una caja negra.

### 4. Documentación de uso desde el día 1

Mantén un registro sencillo: qué herramienta IA, para qué proceso, con qué datos, quién lo aprobó, qué evaluación de riesgo se hizo. Una hoja de cálculo es suficiente para empezar. Cuando el AI Act esté plenamente aplicable, tener esto te ahorrará semanas de trabajo.

## Parla y el AI Act: posición concreta

Parla es un sistema de dictado por voz **local**. El audio se transcribe en el equipo del usuario; no se envía a ningún servidor externo. Esta arquitectura tiene varias consecuencias regulatorias positivas:

- **Categoría de riesgo**: mínima. No hay decisión automatizada sobre personas, no hay biometría, no hay categorización.
- **GDPR**: el dato no sale del equipo del responsable de tratamiento. No hay encargado de tratamiento adicional.
- **GPAI**: usamos Whisper (open weights), un modelo con obligaciones GPAI cumplidas por su propietario y con documentación pública.
- **Transparencia**: el usuario sabe en todo momento que está dictando a una IA (la pulsación del botón es explícita).

Lo desarrollamos con detalle en el [whitepaper Parla y el AI Act](/legal/whitepaper-ai-act), pensado específicamente para que el responsable de cumplimiento de tu pyme tenga argumentos cuando le pregunten.

## Conclusión práctica

El AI Act no es el coco. Es proporcional, razonable y deja claro que la mayoría de usos de IA en pymes están en zona segura. Lo que sí hace es premiar las decisiones técnicas tomadas con cabeza: local mejor que cloud, abierto mejor que opaco, europeo mejor que extra-UE, documentado mejor que improvisado.

Si hoy estás eligiendo herramientas de IA para tu pyme, hazte esta pregunta: **"¿Qué tendría que cambiar si en agosto de 2026 me piden documentar qué hago con esto?"**. Si la respuesta es "nada, porque lo elegí pensando en eso", buena señal.

---

*¿Tu equipo legal te ha preguntado por el AI Act? Descarga el [whitepaper técnico Parla + AI Act](/legal/whitepaper-ai-act) y compártelo. O [habla con nosotros](/contacto) si quieres un análisis personalizado para tu sector.*
