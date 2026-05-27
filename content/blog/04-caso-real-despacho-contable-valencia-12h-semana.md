---
title: "Caso real: despacho contable de Valencia ahorra 12 horas a la semana con dictado por voz"
slug: caso-despacho-contable-valencia-12h-semana
date: 2026-05-14
draft: false
author: "Equipo Parla"
description: "Cómo Vega & Mestre Asesores, gestoría de 6 empleados en Valencia, redujo 12 horas semanales de redacción tras implantar Parla. Setup, métricas antes/después, errores cometidos y aprendizajes del despliegue."
tags: [caso-de-uso, gestoria, contable, pyme, productividad, valencia]
categories: [casos-de-uso]
og_image: /og/04-caso-valencia.png
canonical: https://parla.es/blog/caso-despacho-contable-valencia-12h-semana
---

# Caso real: despacho contable de Valencia ahorra 12 horas a la semana con dictado por voz

Hace tres meses, Mari Carmen Vega, socia de Vega & Mestre Asesores en Russafa (Valencia), nos llamó con una queja muy concreta: "Acabamos los viernes a las nueve de la noche, y lo único que estamos haciendo es escribir cosas que ya tenemos en la cabeza". Su despacho lleva 18 años llevando contabilidad de pymes hostelería y comercio del barrio. Seis empleados, unos 140 clientes activos, un volumen sostenido de actas, informes mensuales y comunicaciones con la AEAT.

Decidieron probar Parla durante un trimestre. Este es el cuaderno de bitácora honesto: lo que esperaban, lo que pasó realmente, lo que falló al principio y dónde acabaron los números.

> **Nota**: este caso refleja una composición típica de despacho contable mediano en zona urbana. Hemos generalizado nombres y algunos detalles operativos para respetar la confidencialidad del cliente. Las métricas reflejan el orden de magnitud real observado en el piloto.

## El despacho antes de Parla

Vega & Mestre tenía un flujo de trabajo bastante ortodoxo para una gestoría de su tamaño:

- **Software contable**: A3 ERP para contabilidad/facturación, una utilidad propia para gestión documental, y la suite ofimática habitual.
- **Volumen redacción**: aproximadamente **18.000 palabras semanales** entre los seis empleados, distribuidas en correos a clientes, informes mensuales, notas de visita y resúmenes para reuniones.
- **Velocidad de mecanografía**: variable. Mari Carmen y otro socio rondaban 45-50 wpm; tres administrativos junior, 35-40 wpm; una persona de soporte, 25 wpm (a dos dedos, autoaprendida).
- **Tiempo invertido en escribir** (estimación inicial del equipo): 18 horas/semana acumuladas entre todos.

Mari Carmen había probado Dragon NaturallySpeaking en 2019, abandonado a los tres meses por errores en castellano y por la sensación de que "todo iba a una nube americana". Desde entonces, escepticismo prudente con cualquier solución de voz.

## El setup que hicimos

Parla se desplegó en los seis equipos en un único día. Configuración real:

- **Hardware existente**: cinco portátiles HP ProBook (i5 de 11ª gen, 16 GB RAM) y un sobremesa Dell algo más antiguo (i5 de 8ª gen, 8 GB RAM).
- **Modelo Whisper desplegado**: `small` en el sobremesa antiguo, `medium` en los cinco portátiles modernos.
- **Trigger**: botón lateral del ratón configurable. Mari Carmen prefiere F8; tres administrativos prefieren botón ratón Logitech; dos optaron por tecla configurable.
- **Diccionario sectorial**: cargamos el glosario contable + nombres de clientes habituales + abreviaturas internas (sociedades clientes, modelos AEAT, etc.). Esto es crítico: sin diccionario sectorial, "modelo 303" se transcribe como "modelo 30 3" o "modelo trescientos tres".
- **Idioma principal**: castellano. Detección automática de catalán/valenciano para clientes de habla local.

El despliegue técnico llevó 2,5 horas en total. La formación a los seis usuarios, otras 3 horas distribuidas en dos sesiones.

## La curva de adaptación (la parte fea)

Los primeros cinco días fueron incómodos. Esto no nos lo inventamos: es lo que pasa en cualquier despliegue de dictado y conviene ser honestos.

**Día 1-2**: el equipo se encontraba dictando correos en susurros porque se sentían raros hablándole al ordenador en una oficina compartida. La productividad bajó respecto al baseline: dictar tímido produce frases entrecortadas que la IA no transcribe bien.

**Día 3**: Mari Carmen impuso una "norma del minuto": el primer minuto de cada tarea había que intentarlo dictando, aunque después se editara con teclado. Esto desbloqueó el uso.

**Día 4-5**: dos administrativos empezaron a "no notar que estaban dictando". Otros dos seguían volviendo al teclado por costumbre. Una persona (la de menor velocidad de escritura) ya estaba enganchada y producía un 80% más de correo diario.

**Semana 2**: cinco de los seis usaban Parla de forma rutinaria. Uno (el socio mayor) seguía resistiéndose por preferencia personal.

**Semana 3-4**: el equipo encontró su patrón. La regla informal que emergió: *"primer pase, dictar; revisión final, teclado"*.

## Las métricas a los 90 días

Estos son los números medidos antes/después en sesiones de tracking real (registros del propio Parla + cronometraje de tareas comparables):

| Métrica | Antes Parla | Después Parla (día 90) | Cambio |
|---|---|---|---|
| Palabras producidas/semana (equipo) | 18.000 | 24.500 | +36% |
| Tiempo total redacción/semana | 18 h | 6 h | **-12 horas/semana** |
| Tiempo redacción correos clientes | 9 h | 2,5 h | -72% |
| Tiempo redacción informes mensuales | 6 h | 2 h | -67% |
| Tiempo notas visita / acta breve | 3 h | 1,5 h | -50% |
| Sesiones agotadoras (>4 h teclado seguido) | 11/semana | 3/semana | -73% |
| Quejas por dolor de muñecas/cervical | 4/mes | 1/mes | -75% |

La cifra que más sorprendió a Mari Carmen no fue las **12 horas semanales ahorradas**: fue la reducción de **sesiones agotadoras**. El equipo termina los viernes notablemente menos cansado, y eso ha afectado positivamente al ambiente más allá del KPI productivo.

## Lo que no funcionó

Honestidad: hubo tres cosas que no salieron como esperábamos.

### 1. Tablas y números puros

Para introducir cifras en formularios de A3, dictar es más lento que teclear. El equipo intentó dictar números durante una semana y volvió al teclado para esas tareas. **Parla es para texto, no para introducción de datos numéricos en formularios**. Lo hemos documentado para futuros despliegues.

### 2. El sobremesa antiguo

El equipo viejo con Whisper-small tenía latencia de 600-700 ms en frases largas. La persona que lo usaba notó la diferencia frente a sus compañeros con equipos nuevos. Solución: reemplazo del sobremesa a los 45 días. El despacho lo aprovechó como excusa para una renovación de hardware que ya tocaba.

**Aprendizaje**: en despliegues nuevos, recomendamos auditar el hardware antes de prometer experiencia uniforme.

### 3. Catalán/valenciano con clientes mixtos

Tres clientes del despacho son catalanoparlantes y la correspondencia es bilingüe (catalán/castellano). La detección automática de idioma funciona bien, pero alterna entre idiomas en el mismo mensaje requiere pausar y reactivar el dictado para forzar el cambio. **No es seamless**. Es manejable, pero no perfecto. Lo tenemos en roadmap.

## Coste vs ahorro

Las cifras crudas del piloto:

**Coste Parla**: 6 licencias × €79 anual = **€474/año** (descuento equipo) o 6 × €99 lifetime = **€594 pago único**. Vega & Mestre eligió la opción lifetime.

**Ahorro estimado**: 12 horas/semana × 4 semanas × 11 meses (descontando agosto y vacaciones) = **528 horas/año recuperadas** distribuidas entre seis personas.

A coste medio empleado pyme con cargas sociales (~€22/h), son **€11.616/año** de capacidad recuperada. ROI a primer año: aproximadamente **19x**.

Lo que han hecho con esas horas: no han despedido a nadie (la idea era ganar capacidad, no recortar). Han admitido 14 clientes nuevos en el último trimestre sin contratar refuerzo. Es decir, el ahorro se convirtió en crecimiento.

## Qué cambió en el ambiente del despacho

Más allá de los números:

- Mari Carmen dice que las **reuniones con clientes** son ahora más fluidas: dicta la nota de visita en el momento, no la pospone al final del día.
- La administrativa con menor velocidad de mecanografía ha **dejado de pedir ayuda** a sus compañeros para correos largos. Ha recuperado autonomía.
- El socio mayor (el resistente inicial) lleva dos meses usándolo después de verlo en acción durante una visita de inspección AEAT donde su compañero dictó toda la acta de la visita "como si nada".

## Lo que un despacho similar debería esperar

Si tu gestoría o despacho profesional pequeño se reconoce en este caso (4-8 empleados, alta carga de correo y informes, sin requerimientos de transcripción de audio externo), las expectativas razonables a 90 días son:

- **Ahorro de 8-15 horas semanales** acumuladas (depende mucho del volumen base de redacción).
- **Reducción de fatiga** apreciable en el equipo.
- **Curva de adaptación de 1-2 semanas** con incomodidad real al principio.
- **ROI a primer año claramente superior a 10x** si tu equipo realmente escribe mucho.

Lo que **no** debes esperar:

- Que dictado sustituya teclado para todo. No lo hará. Convive.
- Que funcione perfecto con tablas, formularios o código.
- Que todos los empleados lo adopten al mismo ritmo. Habrá resistentes; respétalos.

## Cómo empezamos un piloto similar

El despliegue tipo Vega & Mestre lo hacemos en formato piloto de 30 días:

1. **Auditoría rápida de hardware** (1 día, remoto).
2. **Despliegue presencial o remoto asistido** (medio día).
3. **Formación equipo** (2 sesiones de 90 min).
4. **Acompañamiento primera semana** (canal directo de soporte).
5. **Revisión de métricas a 30 días** (sesión de 1 hora).

Si los números no salen a 30 días, devolución íntegra. No hemos tenido que devolver ninguno todavía, pero la oferta sigue en pie.

---

*¿Tu despacho se reconoce en este perfil? [Pide una demo presencial en Valencia, Barcelona o Madrid](/demo) o el [paquete portable de prueba](/demo#portable) si prefieres explorarlo a tu ritmo.*
