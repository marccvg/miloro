"""Audio recorder + toggle pipeline.

Drives ``arecord`` for capture, optionally runs a silence watchdog that auto-
stops after sustained quiet, then asks the daemon to transcribe, copies the
result to the clipboard and types it into the focused window.

State:
  recorder.pid   PID of the active ``arecord``
  recorder.lock  flock to serialise start/stop attempts
  stop.lock      flock to serialise stop transitions
  dictation.wav  current/last recording
"""
from __future__ import annotations

import array
import contextlib
import fcntl
import math
import os
import shutil
import signal
import subprocess
import sys
import time
import wave
from pathlib import Path

from parla_voice import daemon as daemon_module
from parla_voice.autotype import copy_to_clipboard, type_at_cursor
from parla_voice.client import transcribe
from parla_voice.config import Config
from parla_voice.notify import notify


def _log(cfg: Config, msg: str) -> None:
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {msg}\n"
    try:
        with cfg.recorder_log_path.open("a", encoding="utf-8") as f:
            f.write(line)
    except OSError:
        pass


def _read_pid(path: Path) -> int | None:
    try:
        return int(path.read_text().strip())
    except (OSError, ValueError):
        return None


def is_recording(cfg: Config) -> bool:
    pid = _read_pid(cfg.recorder_pid_path)
    if pid is None:
        return False
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


@contextlib.contextmanager
def _flock(path: Path, *, blocking: bool = False, timeout: float = 0.0):
    fd = os.open(path, os.O_RDWR | os.O_CREAT, 0o600)
    try:
        if blocking:
            deadline = time.time() + timeout if timeout else None
            while True:
                try:
                    fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    break
                except BlockingIOError:
                    if deadline is not None and time.time() >= deadline:
                        raise TimeoutError(f"flock timeout on {path}")
                    time.sleep(0.05)
        else:
            try:
                fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                yield False
                return
        yield True
    finally:
        try:
            fcntl.flock(fd, fcntl.LOCK_UN)
        except OSError:
            pass
        os.close(fd)


def _ensure_daemon_running(cfg: Config, boot_timeout: float = 30.0) -> bool:
    """If the daemon is not alive, spawn a detached one and wait for the socket."""
    if daemon_module.is_alive(cfg):
        return True

    if cfg.socket_path.exists():
        try:
            cfg.socket_path.unlink()
        except OSError:
            pass

    _log(cfg, "spawning daemon")
    try:
        subprocess.Popen(
            [sys.executable, "-m", "parla_voice", "daemon"],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
            close_fds=True,
        )
    except OSError as e:
        _log(cfg, f"failed to spawn daemon: {e}")
        return False

    waited = 0.0
    while waited < boot_timeout:
        if cfg.socket_path.is_socket() and daemon_module.is_alive(cfg):
            _log(cfg, f"daemon ready (waited={waited:.1f}s)")
            return True
        time.sleep(0.2)
        waited += 0.2
    _log(cfg, f"daemon did NOT start within {boot_timeout}s")
    return False


def _verify_wav(path: Path) -> bool:
    try:
        with wave.open(str(path), "rb") as w:
            return w.getnframes() >= 1
    except (OSError, wave.Error):
        return False


def start(cfg: Config) -> int:
    """Start recording. Returns 0 if started (or already running), 1 on failure."""
    if not shutil.which("arecord"):
        notify("⚠️ arecord missing", "Install alsa-utils to record audio", enabled=cfg.output.notify)
        return 1

    with _flock(cfg.recorder_lock_path, blocking=True, timeout=10) as got:
        if not got:
            _log(cfg, "start: could not acquire lock")
            return 1
        if is_recording(cfg):
            _log(cfg, "start: already recording")
            return 0

        with contextlib.suppress(FileNotFoundError):
            cfg.wav_path.unlink()
        with contextlib.suppress(FileNotFoundError):
            cfg.recorder_pid_path.unlink()

        _log(cfg, f"start device={cfg.audio.device} wav={cfg.wav_path}")
        proc = subprocess.Popen(
            [
                "arecord",
                "-q",
                "-D", cfg.audio.device,
                "-f", "S16_LE",
                "-c", "1",
                "-r", str(cfg.audio.sample_rate),
                str(cfg.wav_path),
            ],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
            close_fds=True,
        )
        cfg.recorder_pid_path.write_text(f"{proc.pid}\n")

    if cfg.recorder.autostop_silence > 0:
        notify(
            "🎙️ Listening...",
            f"Auto-stop after {cfg.recorder.autostop_silence:g}s of silence",
            enabled=cfg.output.notify,
        )
        _spawn_watchdog(cfg)
    else:
        notify("🎙️ Listening...", "Press the shortcut again to stop", enabled=cfg.output.notify)
    return 0


def _spawn_watchdog(cfg: Config) -> None:
    subprocess.Popen(
        [sys.executable, "-m", "parla_voice", "_watchdog"],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
        close_fds=True,
    )


def _rms_int16(data: bytes) -> int:
    if not data:
        return 0
    samples = array.array("h")
    samples.frombytes(data[: (len(data) // 2) * 2])
    if not samples:
        return 0
    total = sum(s * s for s in samples)
    return int(math.sqrt(total / len(samples)))


def _tail_rms(wav_path: Path, chunk_seconds: float, sample_rate: int) -> int:
    sample_width = 2
    header = 44
    chunk_bytes = int(chunk_seconds * sample_rate * sample_width)
    try:
        size = wav_path.stat().st_size
    except OSError:
        return 0
    if size < header + chunk_bytes:
        return 0
    with wav_path.open("rb") as f:
        f.seek(size - chunk_bytes)
        data = f.read(chunk_bytes)
    return _rms_int16(data)


def watchdog(cfg: Config) -> int:
    """Auto-stop loop. Invoked as ``parla_voice _watchdog``."""
    silence_secs = cfg.recorder.autostop_silence
    threshold = cfg.recorder.silence_threshold
    warmup = cfg.recorder.autostop_warmup
    max_secs = cfg.recorder.autostop_max
    chunk_secs = 0.5
    needed_chunks = max(1, int(silence_secs / chunk_secs))

    _log(
        cfg,
        f"watchdog start (silence={silence_secs}s threshold={threshold} "
        f"warmup={warmup}s max={max_secs}s)",
    )
    time.sleep(warmup)

    consecutive_silence = 0
    started = time.time()
    while True:
        if not is_recording(cfg):
            _log(cfg, "watchdog: arecord gone, exiting")
            return 0
        if time.time() - started >= max_secs:
            _log(cfg, f"watchdog: max_secs ({max_secs}) reached, forcing stop")
            stop(cfg)
            return 0
        rms = _tail_rms(cfg.wav_path, chunk_secs, cfg.audio.sample_rate)
        if rms < threshold:
            consecutive_silence += 1
        else:
            consecutive_silence = 0
        if consecutive_silence >= needed_chunks:
            _log(cfg, f"watchdog: sustained silence rms={rms}<{threshold}, stop")
            stop(cfg)
            return 0
        time.sleep(chunk_secs)


def stop(cfg: Config) -> int:
    """Stop recording, transcribe, deliver."""
    with _flock(cfg.stop_lock_path) as got:
        if not got:
            _log(cfg, "stop: another stop in progress, skipping")
            return 0
        if not cfg.recorder_pid_path.exists():
            _log(cfg, "stop: no pid file, skipping")
            return 0
        return _stop_body(cfg)


def _stop_body(cfg: Config) -> int:
    pid = _read_pid(cfg.recorder_pid_path)
    if pid is None:
        _log(cfg, "stop: pid unreadable")
        cfg.recorder_pid_path.unlink(missing_ok=True)
        return 1

    _log(cfg, f"stop pid={pid}")
    with contextlib.suppress(ProcessLookupError, PermissionError):
        os.kill(pid, signal.SIGTERM)

    waited = 0.0
    while waited < 3.0:
        try:
            os.kill(pid, 0)
        except OSError:
            break
        time.sleep(0.1)
        waited += 0.1
    else:
        with contextlib.suppress(ProcessLookupError, PermissionError):
            os.kill(pid, signal.SIGKILL)
        time.sleep(0.3)

    cfg.recorder_pid_path.unlink(missing_ok=True)

    if not cfg.wav_path.exists() or cfg.wav_path.stat().st_size == 0:
        _log(cfg, "empty wav")
        notify("⚠️ No audio", "Recording is empty. Check your mic.", enabled=cfg.output.notify)
        return 1

    size = cfg.wav_path.stat().st_size
    _log(cfg, f"wav size={size}B")

    if not _verify_wav(cfg.wav_path):
        _log(cfg, "corrupt wav")
        notify("⚠️ Corrupt WAV", "Invalid header", enabled=cfg.output.notify)
        return 1

    if not _ensure_daemon_running(cfg):
        notify("⚠️ Daemon offline", f"See {cfg.daemon_log_path}", enabled=cfg.output.notify)
        return 1

    notify("⏳ Transcribing...", "Processing audio...", enabled=cfg.output.notify)
    resp = transcribe(cfg.socket_path, cfg.wav_path)
    if not resp.ok:
        _log(cfg, f"daemon error: {resp.error}")
        if resp.error.startswith("empty transcription"):
            notify("⚠️ Empty transcription", "Mic muted, aggressive VAD, or low signal.", enabled=cfg.output.notify)
        else:
            notify("⚠️ Transcription error", resp.error, enabled=cfg.output.notify)
        return 1

    _log(cfg, f"ok chars={resp.chars}")

    if cfg.output.clipboard:
        clip_err = copy_to_clipboard(resp.text)
        if clip_err:
            _log(cfg, f"clipboard: {clip_err}")
    if cfg.output.autotype:
        type_err = type_at_cursor(resp.text)
        if type_err:
            _log(cfg, f"autotype: {type_err}")
            notify("⚠️ Auto-type unavailable", type_err, enabled=cfg.output.notify)

    notify("✅ Text copied", resp.preview, enabled=cfg.output.notify)
    return 0


def toggle(cfg: Config) -> int:
    if is_recording(cfg):
        return stop(cfg)
    return start(cfg)
