"""Argument parsing for the ``echo`` console script."""
from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
from pathlib import Path

from parla_voice import __version__, config as config_module, daemon, recorder


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="echo",
        description=(
            "echo-voice — local-first voice dictation: bind a hotkey to "
            "'echo toggle' and speak. The first dictation takes ~3s while the "
            "Whisper model loads; everything after is immediate."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Typical setup:\n"
            "  1. echo init-config        # write default config.toml\n"
            "  2. echo daemon &           # start the persistent transcriber (or use systemd-user)\n"
            "  3. Bind 'echo toggle' to a hotkey (e.g. Super+Z) in your desktop environment.\n"
            "  4. Press hotkey, speak, press hotkey again (or wait for silence auto-stop).\n"
        ),
    )
    parser.add_argument("--version", action="version", version=f"echo-voice {__version__}")
    parser.add_argument(
        "--config",
        type=Path,
        default=None,
        help=f"Path to config.toml (default: {config_module.default_config_path()})",
    )

    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("daemon", help="Run the persistent Whisper transcription daemon (foreground)")
    sub.add_parser("toggle", help="Start recording if idle, else stop+transcribe+type (bind to hotkey)")
    sub.add_parser("start", help="Start recording (no-op if already recording)")
    sub.add_parser("stop", help="Stop recording, transcribe, and deliver text")
    sub.add_parser("dictate", help="Alias for 'toggle'")
    sub.add_parser("status", help="Show daemon and recorder status")
    sub.add_parser("config", help="Print the active configuration as JSON")
    sub.add_parser("init-config", help="Write a default config.toml if none exists")
    sub.add_parser("doctor", help="Check system dependencies (ffmpeg, arecord, xclip, ...)")
    sub.add_parser("_watchdog", help=argparse.SUPPRESS)
    return parser


def _cmd_status(cfg) -> int:
    alive = daemon.is_alive(cfg)
    rec = recorder.is_recording(cfg)
    print(f"daemon:   {'running' if alive else 'stopped'} (socket={cfg.socket_path})")
    print(f"recorder: {'recording' if rec else 'idle'} (wav={cfg.wav_path})")
    print(f"state:    {cfg.state_dir}")
    print(f"config:   {cfg.config_path} {'(present)' if cfg.config_path.is_file() else '(absent, defaults in use)'}")
    return 0


def _cmd_init_config(cfg) -> int:
    target = cfg.config_path
    if target.exists():
        print(f"already exists: {target}", file=sys.stderr)
        return 1
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(config_module.SAMPLE_CONFIG_TOML, encoding="utf-8")
    print(f"wrote default config to {target}")
    return 0


def _cmd_config(cfg) -> int:
    print(json.dumps(config_module.as_dict(cfg), indent=2, ensure_ascii=False))
    return 0


def _cmd_doctor(cfg) -> int:
    checks = [
        ("python", sys.executable, True),
        ("ffmpeg", shutil.which("ffmpeg"), True),
        ("arecord", shutil.which("arecord"), True),
        ("xclip", shutil.which("xclip"), False),
        ("wl-copy", shutil.which("wl-copy"), False),
        ("xdotool", shutil.which("xdotool"), False),
        ("ydotool", shutil.which("ydotool"), False),
        ("wtype", shutil.which("wtype"), False),
        ("notify-send", shutil.which("notify-send"), False),
    ]
    failed_required = 0
    for name, path, required in checks:
        status = "ok " if path else "MISSING"
        tag = "(required)" if required else "(optional)"
        print(f"  {status}  {name:12s} {tag}  {path or ''}")
        if required and not path:
            failed_required += 1

    try:
        import faster_whisper  # noqa: F401
        print("  ok    faster-whisper (Python pkg)")
    except ImportError:
        print("  MISSING  faster-whisper — pip install faster-whisper")
        failed_required += 1

    is_wayland = bool(os.environ.get("WAYLAND_DISPLAY")) or os.environ.get("XDG_SESSION_TYPE") == "wayland"
    print(f"\nsession: {'Wayland' if is_wayland else 'X11'}")
    if failed_required:
        print(f"\n{failed_required} required dependency(ies) missing.", file=sys.stderr)
        return 1
    print("\nall required dependencies present.")
    return 0


COMMANDS = {
    "daemon": lambda cfg: daemon.run(cfg),
    "toggle": lambda cfg: recorder.toggle(cfg),
    "dictate": lambda cfg: recorder.toggle(cfg),
    "start": lambda cfg: recorder.start(cfg),
    "stop": lambda cfg: recorder.stop(cfg),
    "status": _cmd_status,
    "config": _cmd_config,
    "init-config": _cmd_init_config,
    "doctor": _cmd_doctor,
    "_watchdog": lambda cfg: recorder.watchdog(cfg),
}


def main(argv: list[str] | None = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)
    cfg = config_module.load(args.config)
    handler = COMMANDS[args.command]
    return handler(cfg)


if __name__ == "__main__":
    raise SystemExit(main())
