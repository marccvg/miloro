# Oído Pro — demo

Dictado por voz a clipboard + auto-typing en cualquier ventana, **100 % local**.
Sin enviar audio a la nube, sin cuenta de usuario, sin tracking.

Esta es una **demo Fase 0**: funcional para validar la propuesta con pymes
piloto, no es el producto final.

---

## Qué hace

Pulsa **Super+Z** (la tecla "Windows" + Z). El sistema escucha por el
micrófono. Cuando dejas de hablar 2 segundos, transcribe lo dicho con
Whisper (modelo `base`), lo copia al portapapeles y lo **teclea** donde
tengas el cursor (Wayland vía `ydotool`, X11 vía `xdotool`).

El modelo Whisper queda cargado en RAM en un servicio de fondo, así que
después del primer arranque (2-3 s) las transcripciones son inmediatas.

---

## Requisitos

- **Ubuntu Linux 22.04+** (Wayland o X11, GNOME recomendado).
- **RAM:** 4 GB mínimo (modelo `base` ≈ 150 MB). Para `medium` (más preciso,
  más lento), 8 GB.
- **Micrófono.**
- Estos paquetes APT (instalación única vía `sudo apt`):
  ```
  python3 python3-venv ffmpeg alsa-utils xclip ydotool
  ```
  El instalador detecta cuáles faltan y te lo dice. **No hay que instalar
  nada de Python a mano — el script crea su propio entorno aislado.**

---

## Instalación

```bash
./install.sh
```

Eso es todo. El script:

1. Comprueba que tienes las dependencias del sistema.
2. Crea un entorno Python aislado en `~/.local/share/oido-pro-demo/.venv`.
3. Instala `faster-whisper` (descarga ~150 MB en la primera ejecución).
4. Copia los scripts del daemon a `~/.local/share/oido-pro-demo/scripts`.
5. Registra el servicio de fondo (`systemctl --user`).
6. Configura el atajo **Super+Z** en GNOME.

**No usa `sudo` en ningún paso**, vive 100 % en tu home.

### Probar sin instalar de verdad (dry-run)

Si quieres ver que todo se detecta y descarga bien antes de tocar nada
en tu sesión:

```bash
./install.sh --dry-run
```

Hace toda la parte de detección + venv + faster-whisper en
`/tmp/parla_test/`. No registra ni el servicio ni el atajo. Para
limpiar después: `rm -rf /tmp/parla_test`.

---

## Uso

1. Pon el cursor donde quieras que aparezca el texto (editor, navegador,
   chat…).
2. **Pulsa Super+Z**. Aparece una notificación "🎙️ Escuchando…".
3. Habla con normalidad.
4. Cuando hagas una pausa de ~2 s, la grabación se detiene sola.
   Notificación "⏳ Transcribiendo…", y a los pocos segundos "✅ Texto copiado"
   con un preview.
5. El texto se **escribe automáticamente** donde estaba el cursor.
   También queda en el portapapeles (Ctrl+V) por si la auto-escritura
   no funciona en alguna aplicación.

> 💡 Si prefieres modo manual (sin auto-stop), pulsa Super+Z una segunda
> vez para detener la grabación.

---

## Desinstalar

```bash
./uninstall.sh
```

Borra el directorio de instalación, el servicio systemd-user y el
atajo GNOME. **No deja rastro en el sistema.**

---

## Solución de problemas

### Pulso Super+Z y no pasa nada

- Comprueba que el servicio está vivo:
  `systemctl --user status oido-daemon`
- Si dice `inactive`, arráncalo: `systemctl --user start oido-daemon`
- Verifica el atajo en **Ajustes → Teclado → Ver y personalizar atajos**.
  Debería haber uno llamado "Oído Pro — dictado" con Super+Z.

### Notificación "⚠️ Sin audio"

- El micrófono no estaba grabando. Comprueba en **Ajustes → Sonido →
  Entrada** que el dispositivo correcto está seleccionado y que el
  nivel sube cuando hablas.
- Si tienes varios micros, fuerza uno concreto editando el atajo
  GNOME y añadiendo `OIDO_AUDIO_DEVICE=plughw:1,0` al comando.

### Notificación "⚠️ Transcripción vacía"

- El audio era muy bajo o el filtro de voz (VAD) lo descartó. Habla
  más alto o desactiva el VAD:
  `systemctl --user edit oido-daemon` y añade
  `Environment=WHISPER_VAD=0`.

### El texto se copia pero NO se escribe en la ventana

- Tu entorno gráfico no permite el auto-typer. En GNOME Wayland se
  necesita el **socket de `ydotoold`** activo. Soluciones:
  - Lanzar `ydotoold` como servicio (consulta `man ydotoold`).
  - Aceptar que el texto va al portapapeles y pegar con **Ctrl+V**.

### "Primera transcripción tarda mucho"

- Es el modelo cargándose en RAM (2-3 s). Las siguientes son inmediatas.
  El servicio mantiene el modelo cargado durante toda la sesión.

### Quiero más precisión (mejor reconocimiento)

- Edita el unit:
  ```
  systemctl --user edit oido-daemon
  ```
  Y añade:
  ```
  [Service]
  Environment=WHISPER_MODEL=medium
  ```
  Reinicia: `systemctl --user restart oido-daemon`.
  ⚠️ Necesitas ~2 GB de RAM extra. La carga inicial será 5-10 s.

---

## Limitaciones de esta demo (Fase 0)

- **Solo Linux Ubuntu / GNOME.** Mac y Windows en Fase 1.
- **Hotkey fija: Super+Z.** Configurable en Fase 1.
- **Sin post-procesado por LLM** (no corrige puntuación ni reformula).
  Solo transcripción cruda de Whisper.
- **Sin interfaz gráfica.** Todo CLI + notificaciones del sistema.
- **Sin telemetría ni licencia.** Esta demo no caduca ni reporta nada.

---

## Para integradores / curiosos

- Logs en vivo: `journalctl --user -u oido-daemon -f`
- Logs del toggle: `tail -f $XDG_RUNTIME_DIR/oido/oido.log`
- Disparo manual (sin atajo): `~/.local/share/oido-pro-demo/scripts/escuchar.sh toggle`
- Cliente para integrar en otras apps (envía un WAV, recibe transcripción):
  `~/.local/share/oido-pro-demo/.venv/bin/python3 \
   ~/.local/share/oido-pro-demo/scripts/oido_client.py \
   $XDG_RUNTIME_DIR/oido/oido.sock /ruta/al/audio.wav`
