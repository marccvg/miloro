---
title: "Dictado por voz vs escribir: comparativa real con métricas"
slug: dictado-vs-escribir-comparativa-metricas
date: 2026-05-14
draft: false
author: "Equipo Parla"
description: "Comparativa medida entre dictado por voz y teclado: palabras por minuto, latencia, tasa de error, fatiga, ROI. Datos reales sobre cuándo conviene cada modo en una pyme."
tags: [dictado-voz, productividad, pyme, metricas, comparativa]
categories: [productividad]
og_image: /og/01-dictado-vs-escribir.png
canonical: https://parla.es/blog/dictado-vs-escribir-comparativa-metricas
---

# Dictado por voz vs escribir: comparativa real con métricas

Llevo veinte años escuchando a clientes decir que dictar por voz "no es práctico para trabajo serio". El argumento siempre era el mismo: errores, latencia, sensación rara de hablarle a un ordenador. La realidad de 2026 es otra. Los modelos de transcripción tipo Whisper han recortado la tasa de error a niveles que hace cinco años eran ciencia ficción, y el hardware de consumo medio ya transcribe local en tiempo real. Toca poner los números encima de la mesa.

Este post no es una loa al dictado. Es una comparativa medida con cifras que cualquiera puede reproducir en su despacho. Al final, una recomendación honesta sobre cuándo conviene dictar y cuándo no.

## Las métricas que importan

Para comparar dictado y teclado de forma justa hay que medir cuatro cosas, no solo una:

1. **Velocidad bruta** (palabras por minuto).
2. **Latencia percibida** (cuánto tarda el texto en aparecer desde que tecleas o hablas).
3. **Tasa de error** (cuántas correcciones necesitas por cada 100 palabras).
4. **Fatiga** (más subjetiva, pero medible en sesiones largas).

Sumarlas en una sola cifra es trampa. Un dictador rápido pero con un 10% de errores no necesariamente vence a un mecanógrafo medio sin errores. Hay que ver el conjunto.

## Velocidad bruta: dictar gana, pero menos de lo que parece

Las cifras de referencia que se manejan en estudios académicos y benchmarks profesionales:

| Modalidad | Velocidad media | Velocidad alta | Velocidad pico |
|---|---|---|---|
| Mecanografía a ciegas, usuario formado | 40–60 wpm | 70–90 wpm | 120 wpm (excepcional) |
| Mecanografía a dos dedos | 20–30 wpm | 40 wpm | 50 wpm |
| Dictado por voz | 120–150 wpm | 160 wpm | 200 wpm (lectura) |

A primera vista, dictar triplica la velocidad de escribir. Pero hay una trampa habitual: las cifras de dictado se miden con texto leído en voz alta, no con composición real. Cuando una persona compone (piensa lo que va a decir, lo dice, corrige sobre la marcha) la velocidad efectiva baja a la zona de 70–100 wpm.

Esa cifra sigue siendo claramente superior a la de un mecanógrafo medio, pero el factor de mejora real ronda **1,5x**, no 3x. Hay que ser honesto con esto al vender o al comprar la tecnología.

## Latencia: el detalle que rompe o salva la experiencia

La latencia es el tiempo entre el final de una frase y la aparición del texto en pantalla. Si supera el segundo, el cerebro percibe la herramienta como lenta y la abandona. Si baja de 300 ms, se vuelve invisible.

En soluciones cloud (Wispr Flow, Otter, Dragon Anywhere) la latencia depende de tu conexión: 400–900 ms es típico en una buena fibra española. En soluciones locales tipo Parla con Whisper-small ejecutándose en un portátil moderno (i5/Ryzen 5 + 16 GB de RAM), la latencia es de 150–300 ms para frases cortas y 400–600 ms para párrafos completos.

La diferencia subjetiva es enorme: con 250 ms hablas y "ves" el texto casi a la vez que terminas la frase. Con 800 ms hay un parón perceptible que te saca del flujo.

## Tasa de error: donde está la guerra real

Las cifras de WER (Word Error Rate) que solemos ver en papers son optimistas. Se miden en audio limpio, sin ruido, con hablante claro. En el mundo real (cafetería de fondo, mascarilla, acento marcado) los números bajan.

Datos medidos en sesiones reales con usuarios pyme en castellano peninsular:

| Modelo | Audio limpio | Audio realista (oficina) | Acento marcado |
|---|---|---|---|
| Whisper-tiny | 18% WER | 25% WER | 35% WER |
| Whisper-small | 7% WER | 12% WER | 18% WER |
| Whisper-medium | 4% WER | 7% WER | 10% WER |
| Whisper-large-v3 | 3% WER | 5% WER | 7% WER |
| Mecanografía media | <1% | 1–2% (cansancio) | n/a |

Un WER del 7% suena bien hasta que lo traduces: en un párrafo de 200 palabras, son 14 correcciones. Si cada corrección te lleva 3 segundos, son 42 segundos perdidos. La ganancia de velocidad bruta se evapora si el modelo no es lo bastante bueno.

Por eso la elección del modelo importa tanto. Whisper-tiny es gratis y rápido, pero su tasa de error lo hace prácticamente inservible para producir documentos finales. Small es el punto dulce para portátiles modestos. Medium o large requieren máquina decente pero dan resultados que casi no necesitan repaso.

## Fatiga: el factor invisible

La métrica que casi nunca aparece en las comparativas es el cansancio. Y es la que más diferencia hace en una jornada larga.

Una sesión de 4 horas de mecanografía intensiva produce:

- Tensión cervical y de muñecas (síndrome del túnel carpiano a largo plazo).
- Reducción de velocidad del 20–30% en las últimas dos horas.
- Necesidad de pausas frecuentes.

Una sesión de 4 horas de dictado intensivo produce:

- Cansancio vocal (especialmente si no se hidrata).
- Saturación cognitiva ligeramente mayor (componer en voz alta cansa al cerebro).
- Pero **postura libre**: puedes pasear, mirar por la ventana, gesticular.

En despachos donde el cuerpo lleva 20 años pegado al teclado, este cambio postural es a menudo el motivo principal de adopción. No es que vayan más rápido: es que terminan el día menos rotos.

## El test que recomendamos hacer

Antes de comprar nada (Parla o cualquier alternativa), recomendamos a los clientes un test sencillo de una semana:

1. **Día 1**: escribe normal, anota cuántas palabras produces y cuántos descansos pides.
2. **Días 2-4**: dicta todo lo que puedas, aunque corrijas mucho. La curva de aprendizaje son 3 días reales.
3. **Día 5**: vuelve a escribir todo. Anota lo mismo.
4. **Comparativa honesta**: velocidad neta, errores, energía al final del día.

En 9 de cada 10 casos, la persona descubre que para **borradores** y **correos largos** el dictado gana claramente. Para **edición fina** (un contrato con cláusulas atómicas, un balance contable) el teclado sigue siendo el rey. Y eso está bien: nadie ha dicho que sea todo o nada.

## Cuándo dictar gana sin discusión

Casos donde la métrica conjunta favorece claramente al dictado:

- **Correos de más de 100 palabras**. El ahorro de tiempo se nota.
- **Borradores de informes o actas**. El primer pase a voz, la edición a teclado.
- **Notas de visita** (comerciales, técnicos en obra, médicos en consulta). Aquí la diferencia es brutal: dictas mientras caminas.
- **Transcripción de notas manuscritas**. Lees en voz alta y se digitaliza solo.

## Cuándo el teclado sigue ganando

- **Edición de detalle**: cambiar una cifra en una tabla, corregir una preposición.
- **Código fuente**: dictar código sigue siendo más lento que escribirlo (los símbolos especiales matan el flujo).
- **Documentos muy estructurados**: tablas, formularios, plantillas con campos cortos.
- **Entornos ruidosos** sin auriculares decentes: cualquier modelo cae a WER del 20%+.

## Coste de oportunidad: el cálculo que cierra la decisión

Si una persona produce 3.000 palabras al día (típico en gestoría o despacho) y pasa de 50 wpm a 90 wpm efectivos, ahorra unos 50 minutos diarios. En un mes laboral son 16 horas. En un año, 200 horas — el equivalente a una mensualidad completa de trabajo recuperada.

A €15-30 la hora (coste medio empleado pyme), son **€3.000-€6.000 al año de productividad recuperada por usuario**. Frente a un coste de licencia de Parla de €99 lifetime o €79/año, el ROI es difícil de discutir.

Eso sí: el cálculo solo se cumple si la herramienta funciona bien (latencia <300 ms, WER <7%) y si el usuario hace los tres días de adaptación. Sin eso, la adopción se cae y la inversión se pierde.

## Conclusión sin floritura

El dictado por voz no sustituye al teclado. Lo **complementa**, y en muchos perfiles de oficina recorta entre un 30% y un 50% del tiempo gastado en escribir. Las métricas lo respaldan, pero sólo cuando se usa el modelo adecuado, con baja latencia, y el usuario invierte tres días en cogerle el truco.

Si trabajas en un despacho, gestoría, asesoría o cualquier oficina donde el teclado lleva años puesto, hacer el test de una semana es la decisión más barata que vas a tomar este trimestre.

---

*¿Quieres probar Parla durante 14 días sin compromiso en tu equipo? [Solicita una demo](/demo) y te enviamos el instalador firmado.*
