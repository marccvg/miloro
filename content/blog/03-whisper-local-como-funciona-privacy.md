---
title: "Whisper local: cómo funciona y por qué importa para tu privacidad"
slug: whisper-local-como-funciona-privacy
date: 2026-05-14
draft: false
author: "Equipo Parla"
description: "Explicación clara de Whisper, el modelo de transcripción de OpenAI, ejecutándose en local. Qué hace, qué hardware necesita, qué modelos elegir y por qué procesar voz en tu propio equipo es la diferencia entre cumplir GDPR y no cumplirlo."
tags: [whisper, privacidad, gdpr, ia-local, transcripcion, tecnologia]
categories: [tecnologia, privacidad]
og_image: /og/03-whisper-local.png
canonical: https://parla.es/blog/whisper-local-como-funciona-privacy
---

# Whisper local: cómo funciona y por qué importa para tu privacidad

Cuando alguien explica que Parla transcribe "localmente con Whisper", muchas veces la conversación se queda ahí. Suena bien, suena seguro, pero si nadie pregunta qué hay debajo es difícil entender por qué la palabra **local** cambia tantas cosas a la vez. Este post desmonta la caja negra: qué es Whisper, cómo funciona ejecutándose en tu propio equipo, qué hardware necesita realmente y por qué este detalle técnico es la diferencia entre cumplir GDPR sin esforzarte y abrir un expediente cada lunes por la mañana.

## Qué es Whisper

Whisper es un modelo de **reconocimiento automático de habla** (ASR, *automatic speech recognition*) liberado por OpenAI en septiembre de 2022. A diferencia de la mayoría de modelos comerciales de transcripción anteriores, Whisper se publicó con **pesos abiertos**: cualquiera puede descargarlo, ejecutarlo sin pedir permiso, e integrarlo en sus propios productos. Esta decisión fue inusual para OpenAI y abrió la puerta a toda una generación de aplicaciones de dictado local que antes no eran viables.

Lo que hace, en una frase: convierte audio (tu voz) en texto, en 99 idiomas, sin necesidad de entrenarlo específicamente para tu caso de uso.

Lo que lo hace especial frente a sus predecesores:

- Robusto a **ruido ambiente** (entrenado con audio "sucio" de internet).
- Robusto a **acentos** (entrenado con 680.000 horas de audio multilingüe).
- Detecta **idioma automáticamente** y transcribe en el idioma hablado.
- Procesa **audio largo** en bloques de 30 segundos sin perderse.
- Puede ejecutarse **completamente offline** una vez descargado.

Esa última propiedad es la que sostiene productos como Parla.

## Cómo funciona, sin jerga

Sin entrar en matemáticas, el funcionamiento de Whisper se puede resumir en cuatro pasos:

1. **El audio entra**. Parla captura unos pocos segundos de audio cuando aprietas el botón.
2. **Se transforma en un espectrograma**. Es básicamente una "imagen" del sonido: el eje horizontal es tiempo, el vertical es frecuencia, los colores son intensidad. El cerebro humano hace algo parecido en la cóclea del oído.
3. **El espectrograma pasa por una red neuronal de tipo transformer**. Esta red ha "visto" decenas de miles de horas de audio durante su entrenamiento, y ha aprendido qué patrones acústicos se corresponden con qué palabras en cada idioma.
4. **La red emite tokens de texto** que se ensamblan en frases. El resultado se devuelve a Parla, que lo deposita donde tengas el cursor.

Todo este proceso ocurre **en tu equipo**. El audio no sale del ordenador. Ningún paquete de red se envía durante la transcripción. Si desconectas el cable de internet, Parla sigue funcionando exactamente igual.

## Las cinco versiones de Whisper (y cuál te toca)

OpenAI publicó Whisper en cinco tamaños, desde el más pequeño y rápido hasta el más grande y preciso. La elección importa: usar el modelo equivocado puede triplicar tu tasa de error o saturar tu CPU.

| Modelo | Parámetros | VRAM/RAM | Velocidad (CPU moderna) | Calidad ES |
|---|---|---|---|---|
| **tiny** | 39M | ~1 GB | 5x tiempo real | Baja (WER 18%) |
| **base** | 74M | ~1 GB | 4x tiempo real | Media (WER 13%) |
| **small** | 244M | ~2 GB | 1,5x tiempo real | **Buena (WER 7%)** |
| **medium** | 769M | ~5 GB | 0,5x tiempo real | Muy buena (WER 4%) |
| **large-v3** | 1.55B | ~10 GB | 0,2x tiempo real | Excelente (WER 3%) |

Las cifras de velocidad son aproximadas en una CPU moderna (Intel i5/Ryzen 5 de los últimos 3 años) sin GPU. Con GPU NVIDIA decente, los tiempos bajan un orden de magnitud.

Parla usa por defecto **Whisper-small** cuando detecta hardware modesto, y sube a **medium** automáticamente si el equipo tiene 16 GB de RAM o más. La razón: small es el punto dulce de calidad/velocidad para uso conversacional en castellano. Medium es notablemente mejor pero ya empieza a notarse la latencia en máquinas sin GPU.

## El hardware real que necesitas

Una pregunta que recibimos cada semana: "¿necesito una GPU cara para que esto funcione?".

**Respuesta corta**: no.

**Respuesta larga**:

- **Portátil pyme medio (i5 de 8ª generación o superior, 8 GB RAM)**: corre Whisper-small con latencia perfectamente usable (200-400 ms para frases cortas). Esta es la mayoría de instalaciones.
- **Portátil moderno (i7/Ryzen 7, 16 GB RAM)**: corre Whisper-medium sin notarlo. Es el punto dulce real.
- **Mac con Apple Silicon (M1 o superior)**: Whisper se ejecuta sobre Core ML/Metal y vuela. Es el mejor caso.
- **Mini-PC on-prem con GPU NVIDIA dedicada**: para despachos con varios usuarios concurrentes. Whisper-large en tiempo real para todo el equipo.

**Lo que no necesitas**: una RTX 4090, un servidor en rack, ni una suscripción a una nube de cómputo. Para usuario individual o pyme pequeña, el propio portátil del trabajador es suficiente.

## Por qué "local" no es marketing

Es habitual encontrar proveedores que dicen "procesamos localmente" cuando en realidad solo el captura es local y la transcripción se envía a sus servidores. Para distinguir un local real de un local de boquilla, hay tres test técnicos:

### Test 1: el desconecte de cable
Activa la herramienta. Desconecta el wifi y el cable Ethernet. Dicta una frase larga. Si se transcribe sin problema, es local de verdad. Si te da error o se queda colgada, no lo es.

### Test 2: el sniff de red
Con la herramienta capturando, abre Wireshark o un monitor de red simple. Dicta. Si ves tráfico saliendo durante la transcripción hacia servidores externos, no es local. Parla no genera tráfico durante la transcripción (solo lo genera al actualizar la app, periódicamente).

### Test 3: la auditoría de proceso
En sistemas Linux/macOS, `lsof -i` muestra qué conexiones abre cada proceso. El daemon de Parla no aparece en esa lista cuando está activo. Si el proceso de tu herramienta sí aparece con conexiones abiertas, está hablando con alguien.

Cualquier proveedor que diga "local" y no pase los tres tests, no es local.

## Por qué importa para tu privacidad

Aquí está el punto que justifica todo lo anterior. Cuando una herramienta envía tu audio a la nube para transcribir:

1. **Sales del perímetro GDPR de tu organización**. El proveedor cloud se convierte en encargado de tratamiento. Necesitas contrato de encargado, evaluación de transferencias si está fuera de UE, y declaración a tus clientes/empleados de que su voz se procesa por un tercero.
2. **Expones datos potencialmente sensibles**: nombres de clientes, importes, datos médicos si eres clínica, datos legales si eres abogado. Aunque el proveedor sea reputable, una brecha de seguridad ajena te salpica.
3. **Estás sujeto a las leyes del país del proveedor**. Cloud Act estadounidense, leyes de retención chinas, etc. Aunque tu contrato diga UE, la jurisdicción real del cómputo importa.

Con transcripción local en Parla, ninguno de los tres puntos aplica:

1. El audio nunca cruza el perímetro. No hay encargado de tratamiento externo. Tu DPO respira.
2. Los datos sensibles se transcriben en el mismo equipo donde ya viven (donde el usuario abriría el documento de todas formas). No hay nueva exposición.
3. La jurisdicción es la del país donde está el equipo. Punto.

Esta arquitectura no es un truco de marketing: es un cambio cualitativo en la superficie de riesgo. Por eso despachos legales, gestorías con datos financieros sensibles y clínicas se sienten cómodos con Parla cuando antes rechazaban cualquier transcripción "por compliance".

## La incomodidad pequeña: actualizar modelos

Lo único que sí requiere conexión a internet es la **descarga inicial** del modelo (entre 75 MB y 3 GB según versión) y las **actualizaciones puntuales** cuando OpenAI libera mejoras. Estas descargas son anuales en el peor caso. Y entre actualizaciones, Parla no necesita absolutamente nada de la red.

Hemos pensado este flujo desde el inicio para entornos sin internet (oficinas técnicas en obra, consultas médicas con red restringida): los modelos se pueden distribuir por USB, y Parla los reconoce automáticamente.

## Resumen para llevar

- **Whisper** es el modelo de transcripción de OpenAI, abierto, gratuito y de calidad de referencia.
- **Local** significa que la transcripción ocurre en el equipo del usuario, no en un servidor externo. Comprobable con tres tests sencillos.
- **Hardware**: cualquier portátil pyme de los últimos 5 años basta para Whisper-small. Sin GPU.
- **Privacidad**: local elimina la superficie de riesgo GDPR asociada al encargado de tratamiento cloud.
- **El compromiso**: descargas iniciales y actualizaciones puntuales son los únicos momentos en que se usa la red.

Si ves un producto de dictado que no puede explicar dónde corre el modelo, asume cloud. Si te lo explica con detalle y aguanta los tres tests, es de los nuestros.

---

*¿Quieres ver cómo se ejecuta Whisper localmente en tu hardware antes de comprar? Pide acceso al [paquete demo gratuito de 14 días](/demo) y mide tú mismo la latencia, la calidad y el uso de red.*
