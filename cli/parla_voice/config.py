"""Config loader for echo-voice.

Reads ``~/.config/echo-voice/config.toml`` (or ``$ECHO_CONFIG``) and exposes a
single ``Config`` object. Environment variables override file values; CLI flags
override env vars. Defaults are sensible for a typical Linux desktop.

Schema (all keys optional):

    [whisper]
    model = "base"            # tiny | base | small | medium | large-v3
    language = "es"           # ISO-639-1; "" = auto-detect
    cpu_threads = 0           # 0 = auto
    beam_size = 1
    vad_filter = true
    initial_prompt = ""       # bias prompt; "" disables

    [audio]
    device = "default"        # arecord -D value
    sample_rate = 16000

    [recorder]
    autostop_silence = 2      # seconds of sustained silence to auto-stop (0 disables)
    silence_threshold = 300   # RMS threshold (audioop)
    autostop_warmup = 1.5     # seconds before watchdog starts
    autostop_max = 60         # hard cap (seconds)

    [output]
    autotype = true           # also type into focused window (xdotool/ydotool/wtype)
    clipboard = true          # copy to clipboard (xclip)
    notify = true             # desktop notifications (notify-send)
"""
from __future__ import annotations

import os
import sys
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Any

if sys.version_info >= (3, 11):
    import tomllib
else:  # pragma: no cover
    import tomli as tomllib  # type: ignore[no-redef]


def default_config_path() -> Path:
    override = os.environ.get("ECHO_CONFIG")
    if override:
        return Path(override).expanduser()
    xdg = os.environ.get("XDG_CONFIG_HOME") or "~/.config"
    return Path(xdg).expanduser() / "echo-voice" / "config.toml"


def default_state_dir() -> Path:
    override = os.environ.get("ECHO_STATE_DIR")
    if override:
        p = Path(override).expanduser()
    else:
        runtime = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"
        p = Path(runtime) / "echo-voice"
    p.mkdir(parents=True, exist_ok=True)
    try:
        os.chmod(p, 0o700)
    except OSError:
        pass
    return p


@dataclass
class WhisperConfig:
    model: str = "base"
    language: str | None = "es"
    cpu_threads: int = 0
    beam_size: int = 1
    vad_filter: bool = True
    initial_prompt: str = ""


@dataclass
class AudioConfig:
    device: str = "default"
    sample_rate: int = 16000


@dataclass
class RecorderConfig:
    autostop_silence: float = 2.0
    silence_threshold: int = 300
    autostop_warmup: float = 1.5
    autostop_max: float = 60.0


@dataclass
class OutputConfig:
    autotype: bool = True
    clipboard: bool = True
    notify: bool = True


@dataclass
class Config:
    whisper: WhisperConfig = field(default_factory=WhisperConfig)
    audio: AudioConfig = field(default_factory=AudioConfig)
    recorder: RecorderConfig = field(default_factory=RecorderConfig)
    output: OutputConfig = field(default_factory=OutputConfig)
    config_path: Path = field(default_factory=default_config_path)
    state_dir: Path = field(default_factory=default_state_dir)

    @property
    def socket_path(self) -> Path:
        return self.state_dir / "echo.sock"

    @property
    def daemon_pid_path(self) -> Path:
        return self.state_dir / "daemon.pid"

    @property
    def daemon_log_path(self) -> Path:
        return self.state_dir / "daemon.log"

    @property
    def recorder_log_path(self) -> Path:
        return self.state_dir / "recorder.log"

    @property
    def recorder_pid_path(self) -> Path:
        return self.state_dir / "recorder.pid"

    @property
    def recorder_lock_path(self) -> Path:
        return self.state_dir / "recorder.lock"

    @property
    def stop_lock_path(self) -> Path:
        return self.state_dir / "stop.lock"

    @property
    def wav_path(self) -> Path:
        return self.state_dir / "dictation.wav"


def _coerce(value: Any, target_type: type) -> Any:
    if value is None:
        return None
    if target_type is bool:
        if isinstance(value, str):
            return value.strip().lower() in ("1", "true", "yes", "on")
        return bool(value)
    if target_type is int:
        return int(value)
    if target_type is float:
        return float(value)
    if target_type is str:
        return str(value)
    return value


def _merge_section(section_obj: Any, raw: dict[str, Any]) -> None:
    for key, value in raw.items():
        if not hasattr(section_obj, key):
            continue
        current = getattr(section_obj, key)
        target_type = type(current) if current is not None else str
        try:
            setattr(section_obj, key, _coerce(value, target_type))
        except (TypeError, ValueError):
            pass


def load(path: Path | None = None) -> Config:
    """Build a Config from file + env overrides. Missing file → defaults."""
    cfg = Config()
    cfg.config_path = path or default_config_path()

    if cfg.config_path.is_file():
        with cfg.config_path.open("rb") as f:
            raw = tomllib.load(f)
        for section_name in ("whisper", "audio", "recorder", "output"):
            section_raw = raw.get(section_name) or {}
            if isinstance(section_raw, dict):
                _merge_section(getattr(cfg, section_name), section_raw)

    _apply_env_overrides(cfg)
    return cfg


def _apply_env_overrides(cfg: Config) -> None:
    env = os.environ
    mappings = {
        "ECHO_MODEL": (cfg.whisper, "model", str),
        "ECHO_LANGUAGE": (cfg.whisper, "language", str),
        "ECHO_CPU_THREADS": (cfg.whisper, "cpu_threads", int),
        "ECHO_BEAM_SIZE": (cfg.whisper, "beam_size", int),
        "ECHO_VAD": (cfg.whisper, "vad_filter", bool),
        "ECHO_INITIAL_PROMPT": (cfg.whisper, "initial_prompt", str),
        "ECHO_AUDIO_DEVICE": (cfg.audio, "device", str),
        "ECHO_SAMPLE_RATE": (cfg.audio, "sample_rate", int),
        "ECHO_AUTOSTOP_SILENCE": (cfg.recorder, "autostop_silence", float),
        "ECHO_SILENCE_THRESHOLD": (cfg.recorder, "silence_threshold", int),
        "ECHO_AUTOSTOP_WARMUP": (cfg.recorder, "autostop_warmup", float),
        "ECHO_AUTOSTOP_MAX": (cfg.recorder, "autostop_max", float),
        "ECHO_AUTOTYPE": (cfg.output, "autotype", bool),
        "ECHO_CLIPBOARD": (cfg.output, "clipboard", bool),
        "ECHO_NOTIFY": (cfg.output, "notify", bool),
    }
    for env_key, (section, attr, target_type) in mappings.items():
        if env_key in env:
            try:
                setattr(section, attr, _coerce(env[env_key], target_type))
            except (TypeError, ValueError):
                pass


SAMPLE_CONFIG_TOML = """\
# echo-voice configuration. Save at ~/.config/echo-voice/config.toml
# All sections optional; values shown are defaults.

[whisper]
model = "base"            # tiny | base | small | medium | large-v3
language = "es"           # ISO-639-1; "" = auto-detect
cpu_threads = 0           # 0 = auto
beam_size = 1
vad_filter = true
initial_prompt = ""       # short Spanish/English prompt to bias decoding

[audio]
device = "default"        # arecord -D <device>
sample_rate = 16000

[recorder]
autostop_silence = 2      # seconds of silence to auto-stop (0 disables)
silence_threshold = 300   # RMS threshold; lower = more sensitive
autostop_warmup = 1.5
autostop_max = 60

[output]
autotype = true           # type into focused window
clipboard = true          # also copy to system clipboard
notify = true             # desktop notifications via notify-send
"""


def as_dict(cfg: Config) -> dict[str, Any]:
    d = asdict(cfg)
    d["config_path"] = str(cfg.config_path)
    d["state_dir"] = str(cfg.state_dir)
    return d
