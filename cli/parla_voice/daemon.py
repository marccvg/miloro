"""Whisper transcription daemon.

Keeps a ``faster_whisper.WhisperModel`` loaded in memory and exposes a tiny
line-based protocol over a Unix socket:

    client → daemon : "<wav_path>\n"
    daemon → client : "OK\t<chars>\t<preview_80>\t<full_text>\n"
                    or "ERR\t<reason>\n"

A flock on the PID file makes the daemon a singleton per state-dir.
"""
from __future__ import annotations

import fcntl
import os
import signal
import socket
import sys
import time
import traceback
from pathlib import Path

from parla_voice.config import Config


def _log(log_path: Path, msg: str) -> None:
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {msg}\n"
    sys.stderr.write(line)
    sys.stderr.flush()
    try:
        with log_path.open("a", encoding="utf-8") as f:
            f.write(line)
    except OSError:
        pass


def _cleanup(cfg: Config) -> None:
    for p in (cfg.socket_path, cfg.daemon_pid_path):
        try:
            p.unlink()
        except FileNotFoundError:
            pass


def _transcribe(model, wav_path: str, cfg: Config) -> str:
    kwargs = {
        "language": cfg.whisper.language or None,
        "beam_size": cfg.whisper.beam_size,
        "vad_filter": cfg.whisper.vad_filter,
    }
    if cfg.whisper.initial_prompt:
        kwargs["initial_prompt"] = cfg.whisper.initial_prompt
    segments, _info = model.transcribe(wav_path, **kwargs)
    return " ".join(s.text.strip() for s in segments).strip()


def _serve(model, cfg: Config) -> None:
    sock_path = cfg.socket_path
    if sock_path.exists():
        sock_path.unlink()

    srv = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    srv.bind(str(sock_path))
    os.chmod(sock_path, 0o600)
    srv.listen(4)
    _log(cfg.daemon_log_path, f"listening on {sock_path}")

    while True:
        conn, _ = srv.accept()
        try:
            conn.settimeout(60)
            buf = b""
            while not buf.endswith(b"\n"):
                chunk = conn.recv(4096)
                if not chunk:
                    break
                buf += chunk
                if len(buf) > 4096:
                    break
            line = buf.decode("utf-8", errors="replace").strip()
            _log(cfg.daemon_log_path, f"req={line!r}")

            if not line:
                conn.sendall(b"ERR\tempty request\n")
                continue
            if not os.path.exists(line):
                conn.sendall(f"ERR\twav not found: {line}\n".encode())
                continue
            if os.path.getsize(line) < 4096:
                conn.sendall(b"ERR\twav too small\n")
                continue

            t0 = time.time()
            try:
                text = _transcribe(model, line, cfg)
            except Exception as e:
                _log(cfg.daemon_log_path, f"transcribe error: {e}\n{traceback.format_exc()}")
                conn.sendall(f"ERR\t{e}\n".encode())
                continue
            dt = time.time() - t0
            _log(cfg.daemon_log_path, f"chars={len(text)} dt={dt:.2f}s")

            if not text:
                conn.sendall(b"ERR\tempty transcription\n")
                continue

            preview = text[:80].replace("\n", " ").replace("\t", " ")
            full = text.replace("\n", " ").replace("\t", " ")
            conn.sendall(f"OK\t{len(text)}\t{preview}\t{full}\n".encode())
        except Exception as e:
            _log(cfg.daemon_log_path, f"loop error: {e}\n{traceback.format_exc()}")
            try:
                conn.sendall(f"ERR\t{e}\n".encode())
            except OSError:
                pass
        finally:
            try:
                conn.close()
            except OSError:
                pass


def run(cfg: Config) -> int:
    """Run the daemon. Returns process exit code."""
    cfg.state_dir.mkdir(parents=True, exist_ok=True)

    pid_fd = os.open(cfg.daemon_pid_path, os.O_RDWR | os.O_CREAT, 0o600)
    try:
        fcntl.flock(pid_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        try:
            old = cfg.daemon_pid_path.read_text().strip()
        except OSError:
            old = "?"
        _log(cfg.daemon_log_path, f"daemon already running pid={old}; exiting")
        os.close(pid_fd)
        return 0

    os.ftruncate(pid_fd, 0)
    os.write(pid_fd, f"{os.getpid()}\n".encode())
    os.fsync(pid_fd)

    def _on_term(_signo, _frame):
        _log(cfg.daemon_log_path, "SIGTERM/SIGINT received, cleaning up")
        _cleanup(cfg)
        sys.exit(0)

    signal.signal(signal.SIGTERM, _on_term)
    signal.signal(signal.SIGINT, _on_term)

    prompt_repr = "(off)" if not cfg.whisper.initial_prompt else f"{len(cfg.whisper.initial_prompt)}c"
    _log(
        cfg.daemon_log_path,
        f"starting daemon pid={os.getpid()} model={cfg.whisper.model} "
        f"threads={cfg.whisper.cpu_threads or 'auto'} vad={cfg.whisper.vad_filter} prompt={prompt_repr}",
    )

    t0 = time.time()
    try:
        from faster_whisper import WhisperModel  # noqa: WPS433 (deferred import: heavy)
        model = WhisperModel(
            cfg.whisper.model,
            device="cpu",
            compute_type="int8",
            cpu_threads=cfg.whisper.cpu_threads,
        )
        _log(cfg.daemon_log_path, f"model loaded in {time.time() - t0:.2f}s")
    except Exception as e:
        _log(cfg.daemon_log_path, f"FATAL while loading model: {e}\n{traceback.format_exc()}")
        _cleanup(cfg)
        return 1

    try:
        _serve(model, cfg)
    finally:
        _cleanup(cfg)
    return 0


def is_alive(cfg: Config) -> bool:
    if not cfg.socket_path.is_socket():
        return False
    try:
        pid = int(cfg.daemon_pid_path.read_text().strip())
    except (OSError, ValueError):
        return False
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False
