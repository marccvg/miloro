# Política de Privacidad — Parla

**Última actualización:** 2026-05-21
**Responsable del tratamiento:** Marc Vicente García (NIF pendiente alta autónomo) · `legal@parla.app` · Castellón, España
**DPO:** no designado (no obligatorio bajo art. 37 GDPR para este perfil de tratamiento)

> ⚠️ **Aviso al equipo Parla**: este documento es un **borrador estándar B2C SaaS EU** generado el 2026-05-21. Antes de publicar en parla.app debe ser **revisado por abogado/a especializado/a en protección de datos** (estimado €150-300 revisión). Los placeholders entre `<...>` deben rellenarse con datos definitivos.

---

## 1. Qué datos tratamos

Parla es una aplicación de transcripción de voz **100% local**. La transcripción ocurre en el equipo del usuario — los audios y los textos transcritos **nunca abandonan tu dispositivo**.

Los únicos datos que recibimos en nuestros servidores son:

| Categoría | Datos concretos | Finalidad | Base jurídica |
|---|---|---|---|
| **Identificación cliente** | Dirección de correo electrónico | Crear cuenta, enviar magic link de acceso, comunicar cambios contractuales | Ejecución de contrato (art. 6.1.b GDPR) |
| **Suscripción** | Plan contratado, estado de pago, fechas de renovación, ID interno Stripe | Cobro recurrente, gestión de licencias | Ejecución de contrato (art. 6.1.b) |
| **Activación de dispositivos** | Huella digital del equipo (hash SHA-256 de identificadores de hardware no personales: modelo CPU, MAC anonimizada, hostname), sistema operativo, fecha activación, fecha último uso | Cumplir límite de dispositivos según plan (anti-piratería) | Interés legítimo (art. 6.1.f) — prevención de uso fraudulento |
| **Incidencias técnicas** | Volcados de fallos anónimos (últimas 100 líneas de log de error + versión + SO), telemetría opt-in (modelo Whisper usado, RAM detectada, errores frecuentes) | Diagnóstico y mejora del producto | Consentimiento (art. 6.1.a) para telemetría · Interés legítimo para crash dumps mínimos |
| **Comunicaciones** | Cuerpo y metadatos de los correos de soporte que nos envíes | Atender tu consulta | Ejecución de contrato / Consentimiento |

**Datos que NO recibimos jamás:**
- Audios de tus dictados.
- Texto transcrito.
- Contenido de las ventanas donde escribes.
- Historial de uso detallado (qué transcribiste, cuándo, dónde).
- Información de tus contactos, archivos, calendario o cualquier dato del sistema.

## 2. Encargados del tratamiento (subprocesadores)

Cumpliendo el principio de transparencia (art. 28 GDPR), te informamos de los proveedores con los que tratamos tus datos:

| Proveedor | Datos compartidos | Localización servidores | DPA firmado |
|---|---|---|---|
| **Cloudflare, Inc.** (Workers + D1 + Pages) | Todos los datos descritos en §1 excepto correo electrónico transaccional | UE (región seleccionada al provisionar D1) | Standard Contractual Clauses incluidas en términos Cloudflare |
| **Stripe Payments Europe Ltd.** (Irlanda) | Email, ID cliente Stripe, importe transacciones | UE (Irlanda) | DPA aceptable en dashboard Stripe |
| **Resend Inc.** (correo transaccional) | Email + contenido del correo (magic link, recibo, aviso de fallo de pago) | UE/EEUU (Resend usa AWS región a elegir) | DPA disponible bajo solicitud a Resend |

NO se realizan transferencias internacionales fuera del EEE sin garantías adecuadas (SCC) o decisión de adecuación.

## 3. Plazos de conservación

- **Cuenta activa**: mientras mantengas suscripción activa o pasiva (cancelada pero recuperable durante 30 días).
- **Cuenta cancelada**: borrado completo de identificadores personales a los **30 días** desde la baja efectiva, salvo:
  - Datos fiscales requeridos por la AEAT: conservación de facturas durante **4 años** según art. 66.1 LGT.
  - Eventos de auditoría y logs de seguridad: **12 meses** desde la baja, después anonimizados.
- **Crash dumps y telemetría opt-in**: **6 meses** rolling window, anonimizados de forma irreversible.

## 4. Tus derechos

Bajo el GDPR (arts. 15-22) puedes ejercer:

- **Acceso**: solicitar copia de los datos que tenemos sobre ti.
- **Rectificación**: corregir datos inexactos.
- **Supresión** ("derecho al olvido"): pedir el borrado de tu cuenta y datos asociados.
- **Limitación**: pedir que dejemos de tratar tus datos temporalmente mientras se resuelve una reclamación.
- **Portabilidad**: recibir tus datos en formato JSON estructurado.
- **Oposición**: oponerte al tratamiento basado en interés legítimo.
- **Revocación del consentimiento** (telemetría): desde el panel de la app o por email a `privacy@parla.app`.

**Cómo ejercerlos**: envía un correo a `privacy@parla.app` desde la dirección registrada en tu cuenta. Plazo de respuesta: **30 días naturales** (art. 12.3 GDPR), prorrogables 2 meses adicionales en casos complejos.

**Autoridad de control**: si consideras que vulneramos tus derechos puedes presentar una reclamación ante la [Agencia Española de Protección de Datos (AEPD)](https://www.aepd.es) — C/ Jorge Juan, 6, 28001 Madrid.

## 5. Decisiones automatizadas

NO realizamos decisiones automatizadas con efectos jurídicos significativos sobre ti (art. 22 GDPR). El cobro recurrente, las renovaciones y las desactivaciones de dispositivos siguen reglas determinísticas pre-acordadas en estos términos.

## 6. Seguridad

Aplicamos medidas técnicas y organizativas razonables proporcionadas al riesgo (art. 32 GDPR):

- Cifrado en tránsito (TLS 1.3) en todas las comunicaciones con nuestros servidores.
- Cifrado en reposo en Cloudflare D1.
- Acceso a la consola administrativa restringido por 2FA.
- Logs de auditoría inalterables (append-only) de cualquier acceso a datos de cuenta.
- Verificación HMAC SHA-256 en webhooks Stripe (anti-replay).
- Política de mínimos privilegios: ningún proveedor recibe más datos de los estrictamente necesarios para su función.

## 7. Cookies

La landing parla.app **NO utiliza cookies de tracking**. Usamos analítica respetuosa con la privacidad (Plausible u opción equivalente sin cookies) para medir tráfico agregado.

La aplicación desktop **NO utiliza cookies** (no es navegador).

## 8. Menores

Parla está dirigido a mayores de **16 años**. Si tienes entre 14 y 16 años necesitas autorización paterna. Si descubrimos que hemos tratado datos de un menor sin autorización, los borraremos de inmediato.

## 9. Cambios a esta política

Cualquier modificación material será comunicada por email con **15 días naturales de antelación** y se publicará en parla.app/privacy con la nueva fecha de "Última actualización".

---

**Idiomas**: esta política está disponible en castellano, catalán y valenciano. En caso de discrepancia interpretativa prevalece la versión castellana.

**Versión inglesa**: a publicar en `parla.app/en/privacy` antes del primer cliente fuera de España.
