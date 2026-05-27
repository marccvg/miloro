# Términos y Condiciones de Servicio — Parla

**Última actualización:** 2026-05-21
**Titular del servicio:** Marc Vicente García (NIF pendiente alta autónomo) · `legal@parla.app` · Castellón, España

> ⚠️ **Borrador**: revisar con abogado/a antes de publicación. Adaptar denominación legal (autónomo / SL futura) cuando se constituya entidad.

---

## 1. Objeto y aceptación

Los presentes Términos regulan la relación entre Marc Vicente García ("**Parla**", "nosotros") y la persona física o jurídica ("**Usuario**", "tú") que descarga, instala o se suscribe al servicio **Parla — transcripción de voz local**.

La descarga e instalación de la aplicación, así como la contratación de cualquier plan de pago, implica la aceptación expresa de estos Términos en la versión publicada en `parla.app/terms` en el momento de la contratación.

## 2. Descripción del servicio

Parla es una aplicación de escritorio multiplataforma (Linux, Windows, macOS) que transcribe voz a texto **localmente** en el equipo del Usuario, sin enviar el audio a servidores externos. Se distribuye bajo modelo de **suscripción recurrente** con tres planes:

| Plan | Precio (IVA incluido cuando aplique) | Dispositivos | Modelo Whisper | Transcripciones |
|---|---|---|---|---|
| **Free** | 0 € | 1 | small (~500 MB) | 5 por día |
| **Standard** | 9 €/mes | 2 | medium (~1.5 GB) | Ilimitadas |
| **Pro** | 19 €/mes | 3 | large (~3 GB) + diarización + sincronización opcional | Ilimitadas |

Los precios anunciados son **finales para consumidor final** (IVA incluido cuando proceda). Para clientes empresariales con NIF intracomunitario válido se aplica inversión del sujeto pasivo.

## 3. Alta, identificación y verificación

- El alta se realiza con dirección de correo electrónico válida y verificación mediante enlace mágico (magic link) enviado por email.
- El Usuario garantiza la veracidad de los datos aportados.
- Una cuenta = una persona física o jurídica. La compartición de credenciales entre múltiples personas físicas distintas constituye incumplimiento contractual.

## 4. Límite de dispositivos y huella digital

Cada plan permite un número máximo de dispositivos activos simultáneamente (ver tabla §2). Para hacer cumplir este límite, la aplicación genera al instalarse una **huella digital del dispositivo** (hash SHA-256 de identificadores de hardware no personales) que se asocia a la licencia.

- Puedes **desactivar un dispositivo** desde el panel `parla.app/dashboard` en cualquier momento para liberar un slot.
- Si superas el límite del plan, la aplicación dejará de funcionar en el dispositivo sobrante hasta que liberes un slot o subas de plan.
- Cambios de hardware significativos (placa base, CPU) pueden invalidar la huella y requerir reactivación.

## 5. Pagos, renovaciones, fallos de pago

- Los pagos se procesan a través de **Stripe Payments Europe Ltd.** (Irlanda). Aceptamos tarjetas de débito/crédito y métodos SEPA.
- La suscripción se **renueva automáticamente** al final de cada periodo de facturación al mismo precio publicado (o al modificado con notificación previa de 30 días).
- En caso de **fallo de pago**, Stripe reintenta 3 veces en 7 días. Si persiste el fallo, la suscripción pasa a `past_due` y, a los 14 días, a `cancelled` con baja automática del servicio. Recibirás notificaciones por email en cada paso.
- Puedes **cancelar** en cualquier momento desde el panel. La cancelación es efectiva al final del periodo en curso (mantienes acceso hasta entonces).

## 6. Derecho de desistimiento (consumidores UE)

De acuerdo con la Directiva 2011/83/UE y el Real Decreto Legislativo 1/2007, los consumidores residentes en la Unión Europea disponen de **14 días naturales** desde la contratación inicial para desistir sin necesidad de justificación.

**Excepción aplicable**: al iniciar el uso del servicio digital (descargar/instalar la app y activar la licencia) el Usuario **renuncia expresamente** al derecho de desistimiento sobre la prestación ya iniciada, en los términos del art. 103.m del RDL 1/2007.

**En la práctica**: si NO has activado la licencia en ningún dispositivo dentro de los 14 días, recibirás **reembolso íntegro** previa solicitud a `refund@parla.app`. Si ya has activado, se aplica la política de reembolso del documento `REFUND.md`.

## 7. Licencia de uso del software

- Parla concede al Usuario una licencia **no exclusiva, no transferible, revocable y limitada** para usar la aplicación según el plan contratado en el número de dispositivos permitidos.
- Queda prohibido:
  - Realizar ingeniería inversa, descompilar o desensamblar el software más allá de lo permitido por el art. 100 LPI.
  - Eludir o intentar eludir los mecanismos de licenciamiento, huella digital o validación.
  - Redistribuir, sublicenciar, vender, alquilar o ceder la licencia a terceros.
  - Usar la aplicación para fines ilegales o que infrinjan derechos de terceros.
- La violación de cualquier cláusula de esta sección autoriza a Parla a **suspender o cancelar el servicio sin reembolso**, sin perjuicio de las acciones legales que correspondan.

## 8. Limitación de responsabilidad

Parla se ofrece "**tal cual**" (as-is) sin garantías implícitas de comerciabilidad o adecuación a un propósito particular más allá de las inderogables por consumidor final EU.

En la máxima medida permitida por la ley aplicable:

- Parla **no garantiza** precisión 100% de las transcripciones — la calidad depende del modelo Whisper, la calidad del audio, el idioma, el acento, ruido ambiente y características del equipo del Usuario.
- Parla **no se responsabiliza** de pérdida de datos por fallo del equipo del Usuario, errores del SO o causas ajenas al funcionamiento del software cuando se usa según las indicaciones.
- La responsabilidad máxima de Parla frente al Usuario en cualquier caso queda limitada al **importe pagado por el Usuario durante los 12 meses anteriores** al evento que origine la reclamación.

**Esta limitación NO se aplica** en casos de dolo, culpa grave, daños a la salud o la vida, ni a derechos inderogables del consumidor según la legislación española y europea.

## 9. Servicio y disponibilidad

- La aplicación funciona localmente: su disponibilidad depende del equipo del Usuario.
- La infraestructura cloud (licencia, dashboard, emails) se hospeda en **Cloudflare Workers + D1**, con SLA objetivo del **99.9% mensual**. Esta infraestructura es necesaria para validar licencia periódicamente (cada 7 días); ante una caída prolongada (>72h), la app entra en **modo offline tolerante** durante 30 días manteniendo plena funcionalidad.
- Las ventanas de mantenimiento programadas (raras) se anuncian con 48h de antelación por email y banner en dashboard.

## 10. Modificación de los Términos

Podemos modificar estos Términos por motivos legales, regulatorios, de seguridad o de evolución del servicio. Cualquier cambio material será comunicado por email con **30 días naturales de antelación** previo a su entrada en vigor. Si el cambio te perjudica, podrás cancelar gratis antes de la entrada en vigor con reembolso pro-rata del periodo no consumido.

## 11. Ley aplicable y jurisdicción

Estos Términos se rigen por la **legislación española**. Para la resolución de cualquier controversia las partes se someten a los Juzgados y Tribunales de la ciudad de **Castellón de la Plana**, salvo cuando la legislación de consumidores otorgue al consumidor el derecho a someter la disputa a los tribunales de su propio domicilio dentro del EEE.

Plataforma europea de resolución de litigios online: [https://ec.europa.eu/consumers/odr](https://ec.europa.eu/consumers/odr).

## 12. Datos de contacto

- **Soporte técnico**: `support@parla.app`
- **Facturación**: `billing@parla.app`
- **Privacidad / GDPR**: `privacy@parla.app`
- **Cuestiones legales**: `legal@parla.app`

---

**Idiomas**: estos Términos están disponibles en castellano, catalán y valenciano. En caso de discrepancia interpretativa prevalece la versión castellana.
