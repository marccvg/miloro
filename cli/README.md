# parla-voice

**Local-first voice dictation for Linux.** Bind a hotkey, speak, and your words
appear at the cursor — in any app, any text field, online or offline.

- Powered by [`faster-whisper`](https://github.com/SYSTRAN/faster-whisper). Runs on CPU. No cloud calls, no telemetry.
- Persistent daemon keeps the model loaded — first dictation costs ~3 s, subsequent ones are instant.
- One small binary: `parla`. Works on GNOME, KDE, i3, sway, Hyprland (X11 and Wayland).
- MIT license.

```
┌─────────────┐    Super+Z      ┌────────────────┐   socket   ┌─────────────────┐
│  any app    │ ──────────────▶ │  parla toggle  │ ─────────▶ │  parla daemon   │
│  (textarea) │                 │  (arecord)     │            │  (Whisper)      │
└─────────────┘                 └────────────────┘            └─────────────────┘
       ▲                                                              │
       └──────────────────  xdotool / ydotool / wtype ────────────────┘
                            (types text at cursor)
```

## Install

```bash
# 1. System packages (Debian/Ubuntu):
sudo apt install ffmpeg alsa-utils xclip xdotool notify-osd
# On Wayland (GNOME 41+, KDE, sway), also install ydotool or wtype:
sudo apt install ydotool

# 2. Python package:
pip install parla-voice

# 3. Verify:
parla doctor
```

> The first run of `parla daemon` downloads the Whisper `base` model (~140 MB)
> into `~/.cache/huggingface/`. Subsequent runs are offline.

## Usage

### 1. Start the daemon

Foreground (for testing):

```bash
parla daemon
```

Or as a systemd-user service (auto-start at login):

```bash
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/parla-voice.service <<'EOF'
[Unit]
Description=parla-voice transcription daemon
After=default.target

[Service]
Type=simple
ExecStart=%h/.local/bin/parla daemon
Restart=on-failure

[Install]
WantedBy=default.target
EOF
systemctl --user daemon-reload
systemctl --user enable --now parla-voice.service
```

### 2. Bind a hotkey to `parla toggle`

**GNOME:** Settings → Keyboard → Shortcuts → Custom Shortcuts → Add:

- Name: `parla dictate`
- Command: `parla toggle`
- Shortcut: `Super+Z` (or whatever you like)

**KDE Plasma:** System Settings → Shortcuts → Custom Shortcuts → New → Global
Shortcut → Command/URL. Set Trigger to your key and Action to `parla toggle`.

**i3 / sway:**

```
bindsym $mod+z exec --no-startup-id parla toggle
```

**Hyprland:**

```
bind = SUPER, Z, exec, parla toggle
```

### 3. Press the hotkey, speak

- Press the hotkey → red recording notification.
- Speak.
- Press the hotkey again **or** stay silent for 2 s (auto-stop).
- Your text appears at the cursor and is also copied to the clipboard.

## Commands

```text
parla daemon         Run the persistent Whisper daemon (foreground)
parla toggle         Start/stop recording — bind this to your hotkey
parla start          Force start recording (no-op if already recording)
parla stop           Stop recording, transcribe, and deliver text
parla status         Show daemon + recorder status
parla doctor         Check that all system dependencies are present
parla config         Print the active configuration (JSON)
parla init-config    Write a default ~/.config/echo-voice/config.toml
```

> Nota interna (2026-05-14): el binario instalado se llama `parla`, pero los
> strings internos del argparse, los nombres de variables de entorno
> (`ECHO_*`) y el directorio de configuración (`~/.config/echo-voice/`)
> todavía conservan el nombre histórico `echo`. El rebrand del código
> interno (CLI prog, env vars, config dir, socket path) está pendiente como
> follow-up — ver `REPORT.md` del rebrand en cola.

## Configuration

Edit `~/.config/echo-voice/config.toml` (run `parla init-config` to scaffold it):

```toml
[whisper]
model = "base"            # tiny | base | small | medium | large-v3
language = "es"           # ISO-639-1; "" = auto-detect
cpu_threads = 0           # 0 = auto
beam_size = 1
vad_filter = true
initial_prompt = ""       # short prompt to bias decoding

[audio]
device = "default"        # arecord -D <device>
sample_rate = 16000

[recorder]
autostop_silence = 2      # seconds of sustained silence to auto-stop (0 disables)
silence_threshold = 300   # RMS threshold; lower = more sensitive
autostop_warmup = 1.5
autostop_max = 60         # hard cap (seconds)

[output]
autotype = true           # type into focused window
clipboard = true          # also copy to system clipboard
notify = true             # desktop notifications
```

Every value can be overridden with an environment variable:
`ECHO_MODEL=small`, `ECHO_LANGUAGE=en`, `ECHO_AUTOTYPE=0`, etc.
(Los nombres `ECHO_*` se conservan por compatibilidad pendiente de migración.)

## Choosing a model

| Model      | RAM    | CPU time (5 s clip) | Quality |
|------------|--------|---------------------|---------|
| `tiny`     | ~1 GB  | ~0.3 s              | ★★☆☆☆   |
| `base`     | ~1 GB  | ~0.5 s              | ★★★☆☆   |
| `small`    | ~2 GB  | ~1.2 s              | ★★★★☆   |
| `medium`   | ~5 GB  | ~3 s                | ★★★★★   |
| `large-v3` | ~10 GB | ~7 s                | ★★★★★   |

(Numbers approximate; measured on a recent i7 with int8 quantisation.)

## Privacy

Everything runs on your machine. The audio never leaves your laptop. There is no
analytics, no opt-in / opt-out cloud mode, and no network connection at runtime
once the model is cached.

## Troubleshooting

Run `parla doctor` first — it reports every missing dependency. Then:

- **No text appears at the cursor.** Check `parla doctor` — on Wayland you need
  `ydotool` (with `ydotoold` running) or `wtype`. The clipboard fallback always
  works.
- **`empty transcription`.** The VAD filter trimmed everything. Try
  `ECHO_VAD=0 parla toggle` or lower `silence_threshold` in `config.toml`.
- **Daemon won't start.** `~/.config/systemd/user/parla-voice.service` →
  `journalctl --user -u parla-voice.service`. El daemon también escribe a
  `$XDG_RUNTIME_DIR/echo-voice/daemon.log` (path heredado, pendiente de migrar).
- **Slow first dictation.** Expected — Whisper loads on the first request.
  Run `parla daemon` once at login (systemd-user unit above) and it stays warm.

## Contributing

Issues and PRs welcome at <https://github.com/therefactorlabs/parla-voice>.

## License

MIT — see [LICENSE](LICENSE).
