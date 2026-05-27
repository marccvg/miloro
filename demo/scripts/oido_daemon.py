#!/usr/bin/env python3
"""Oído Digital — daemon de transcripción (demo portable).

Servicio de fondo que mantiene cargado `WhisperModel` en memoria y atiende
peticiones de transcripción vía Unix socket. El primer arranque tarda ~2-3 s
(carga del modelo); las transcripciones siguientes son inmediatas.

Protocolo (línea-por-línea, ASCII):
  cliente → daemon : "<wav_absoluto>\n"
  daemon  → cliente: "OK\t<chars>\t<preview_80>\t<texto_completo>\n"
                   o "ERR\t<razón>\n"

Estado (directorio configurable via OIDO_STATE_DIR; default:
  $XDG_RUNTIME_DIR/oido o /tmp/oido):
  oido.sock         socket Unix
  oido_daemon.pid   PID del daemon
  oido_daemon.log   trazas (apend)

Variables de entorno:
  WHISPER_MODEL          tiny|base|small|medium|large-v3 (default 'base' en demo).
  WHISPER_LANGUAGE       ISO 639-1 (default 'es'; vacío = autodetectar).
  WHISPER_CPU_THREADS    0=auto.
  WHISPER_BEAM_SIZE      default 1.
  WHISPER_VAD            '1' (default) filtra silencios; '0' transcribe todo.
  WHISPER_INITIAL_PROMPT  prompt de sesgo. Vacío para desactivar.
  OIDO_XCLIP             binario xclip (default 'xclip').
  OIDO_STATE_DIR         dir de estado (default auto).
"""
import os
import signal
import socket
import subprocess
import sys
import time
import traceback

STATE_DIR = os.environ.get(
    "OIDO_STATE_DIR",
    os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "oido"),
)
os.makedirs(STATE_DIR, exist_ok=True)
try:
    os.chmod(STATE_DIR, 0o700)
except OSError:
    pass

SOCK_PATH = os.path.join(STATE_DIR, "oido.sock")
PID_PATH = os.path.join(STATE_DIR, "oido_daemon.pid")
LOG_PATH = os.path.join(STATE_DIR, "oido_daemon.log")

MODEL_SIZE = os.environ.get("WHISPER_MODEL", "base")
LANGUAGE = os.environ.get("WHISPER_LANGUAGE", "es") or None
CPU_THREADS = int(os.environ.get("WHISPER_CPU_THREADS", "0"))
BEAM_SIZE = int(os.environ.get("WHISPER_BEAM_SIZE", "1"))
VAD_FILTER = os.environ.get("WHISPER_VAD", "1") != "0"
XCLIP_BIN = os.environ.get("OIDO_XCLIP", "xclip")

DEFAULT_INITIAL_PROMPT = (
    "Hola, esto es un dictado en español. "
    "¿Qué tal? ¡Perfecto!"
)
_prompt_env = os.environ.get("WHISPER_INITIAL_PROMPT")
INITIAL_PROMPT = DEFAULT_INITIAL_PROMPT if _prompt_env is None else _prompt_env


def log(msg: str) -> None:
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    sys.stderr.write(f"[{ts}] {msg}\n")
    sys.stderr.flush()


def cleanup() -> None:
    for p in (SOCK_PATH, PID_PATH):
        try:
            os.unlink(p)
        except FileNotFoundError:
            pass


def copy_to_clipboard(text: str) -> str:
    payload = text.encode("utf-8")
    errs = []
    for selection in ("clipboard", "primary"):
        try:
            subprocess.run(
                [XCLIP_BIN, "-selection", selection],
                input=payload,
                check=True,
                stderr=subprocess.PIPE,
                timeout=3,
            )
        except subprocess.CalledProcessError as e:
            errs.append(f"{selection}: rc={e.returncode}")
        except FileNotFoundError:
            errs.append(f"{XCLIP_BIN} no encontrado")
            break
        except subprocess.TimeoutExpired:
            errs.append(f"{selection}: timeout")
    return "; ".join(errs)


def transcribe(model, wav_path: str) -> str:
    kwargs = dict(
        language=LANGUAGE,
        beam_size=BEAM_SIZE,
        vad_filter=VAD_FILTER,
    )
    if INITIAL_PROMPT:
        kwargs["initial_prompt"] = INITIAL_PROMPT
    segments, _info = model.transcribe(wav_path, **kwargs)
    return " ".join(s.text.strip() for s in segments).strip()


def serve(model) -> None:
    if os.path.exists(SOCK_PATH):
        os.unlink(SOCK_PATH)
    srv = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    srv.bind(SOCK_PATH)
    os.chmod(SOCK_PATH, 0o600)
    srv.listen(4)
    log(f"escuchando en {SOCK_PATH}")

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
            log(f"req={line!r}")
            if not line:
                conn.sendall(b"ERR\tlinea vacia\n")
                continue
            if not os.path.exists(line):
                conn.sendall(f"ERR\twav no existe: {line}\n".encode())
                continue
            if os.path.getsize(line) < 4096:
                conn.sendall(b"ERR\twav demasiado pequeno\n")
                continue
            t0 = time.time()
            try:
                text = transcribe(model, line)
            except Exception as e:
                log(f"transcribe excepcion: {e}\n{traceback.format_exc()}")
                conn.sendall(f"ERR\t{e}\n".encode())
                continue
            dt = time.time() - t0
            log(f"chars={len(text)} dt={dt:.2f}s")
            if not text:
                conn.sendall(b"ERR\ttranscripcion vacia\n")
                continue
            xclip_err = copy_to_clipboard(text)
            if xclip_err:
                log(f"xclip error: {xclip_err}")
            preview = text[:80].replace("\n", " ").replace("\t", " ")
            full = text.replace("\n", " ").replace("\t", " ")
            resp = f"OK\t{len(text)}\t{preview}\t{full}\n".encode()
            conn.sendall(resp)
        except Exception as e:
            log(f"loop excepcion: {e}\n{traceback.format_exc()}")
            try:
                conn.sendall(f"ERR\t{e}\n".encode())
            except OSError:
                pass
        finally:
            try:
                conn.close()
            except OSError:
                pass


def main() -> int:
    import fcntl
    pid_fd = os.open(PID_PATH, os.O_RDWR | os.O_CREAT, 0o600)
    try:
        fcntl.flock(pid_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        try:
            old = open(PID_PATH).read().strip()
        except OSError:
            old = "?"
        log(f"ya hay daemon vivo pid={old}; saliendo")
        os.close(pid_fd)
        return 0
    os.ftruncate(pid_fd, 0)
    os.write(pid_fd, f"{os.getpid()}\n".encode())
    os.fsync(pid_fd)

    def on_term(_signo, _frame):
        log("SIGTERM/SIGINT recibido, limpiando")
        cleanup()
        sys.exit(0)

    signal.signal(signal.SIGTERM, on_term)
    signal.signal(signal.SIGINT, on_term)

    prompt_repr = "(off)" if not INITIAL_PROMPT else f"{len(INITIAL_PROMPT)}c"
    log(f"arrancando daemon pid={os.getpid()} modelo={MODEL_SIZE} hilos={CPU_THREADS or 'auto'} vad={VAD_FILTER} prompt={prompt_repr}")
    t0 = time.time()
    try:
        from faster_whisper import WhisperModel
        model = WhisperModel(
            MODEL_SIZE,
            device="cpu",
            compute_type="int8",
            cpu_threads=CPU_THREADS,
        )
        log(f"modelo cargado en {time.time() - t0:.2f}s")
    except Exception as e:
        log(f"FATAL al cargar modelo: {e}\n{traceback.format_exc()}")
        cleanup()
        return 1

    try:
        serve(model)
    finally:
        cleanup()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
