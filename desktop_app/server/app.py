#!/usr/bin/env python3
# SKILL_DESC: Backend Flask del dogfooding Parla. Lee/escribe config del daemon oido vía systemctl, expone API REST que el mockup HTML consume. Marc usa la web como si fuese app real antes de empaquetar Tauri.
"""Parla desktop_app — backend Flask.

Endpoints:
    GET  /                       → sirve mockup HTML
    GET  /api/config             → config actual del daemon
    POST /api/config             → guarda config + restart daemon
    GET  /api/status             → estado daemon + ptt + uptime
    POST /api/test/record        → graba 5s + transcribe + devuelve texto
    GET  /api/logs               → últimas N líneas journalctl

Arranque manual:
    cd /home/Projects/parla/desktop_app
    pip install flask
    python3 server/app.py

Arranque automático (systemd-user):
    cp server/parla-config-server.service ~/.config/systemd/user/
    systemctl --user daemon-reload
    systemctl --user enable --now parla-config-server.service

URL local: http://localhost:4331/
"""
from __future__ import annotations

import json
import re
import subprocess
import time
from pathlib import Path

from flask import Flask, jsonify, request, send_from_directory

APP_ROOT = Path(__file__).resolve().parent.parent
MOCKUP_DIR = APP_ROOT / "mockup"
DAEMON_SERVICE_PATH = Path.home() / ".config/systemd/user/oido-daemon.service"
PTT_SERVICE_PATH = Path.home() / ".config/systemd/user/oido-ptt.service"
SERVICE_PATH = DAEMON_SERVICE_PATH  # legacy alias

# Routing: cada env var sabe a qué .service pertenece, porque el proceso
# que la consume puede ser daemon (oido_daemon.py) o ptt (escuchar.sh, lanzado
# por oido_ptt.py con env heredado de oido-ptt.service).
ENV_SERVICE = {
    "WHISPER_MODEL": ("oido-daemon.service", DAEMON_SERVICE_PATH),
    "WHISPER_LANGUAGE": ("oido-daemon.service", DAEMON_SERVICE_PATH),
    "WHISPER_TASK": ("oido-daemon.service", DAEMON_SERVICE_PATH),
    "WHISPER_BEAM_SIZE": ("oido-daemon.service", DAEMON_SERVICE_PATH),
    "WHISPER_VAD": ("oido-daemon.service", DAEMON_SERVICE_PATH),
    "WHISPER_INITIAL_PROMPT": ("oido-daemon.service", DAEMON_SERVICE_PATH),
    "OIDO_COPY_CLIPBOARD": ("oido-daemon.service", DAEMON_SERVICE_PATH),
    # autotype/typewriter viven en env de oido-ptt.service → heredados por escuchar.sh
    "OIDO_AUTOTYPE": ("oido-ptt.service", PTT_SERVICE_PATH),
    "OIDO_TYPEWRITER": ("oido-ptt.service", PTT_SERVICE_PATH),
}

ENV_PARSERS = {
    "WHISPER_MODEL": str,
    "WHISPER_LANGUAGE": str,         # "" = auto-detect, "es", "en", etc.
    "WHISPER_TASK": str,             # "transcribe" (default) o "translate" (→ inglés)
    "WHISPER_BEAM_SIZE": int,
    "WHISPER_VAD": lambda v: v == "1",
    "WHISPER_INITIAL_PROMPT": str,
    "OIDO_AUTOTYPE": lambda v: v == "1",
    "OIDO_TYPEWRITER": lambda v: v == "1",
    "OIDO_COPY_CLIPBOARD": lambda v: v == "1",
}

DEFAULTS = {
    "WHISPER_MODEL": "medium",
    "WHISPER_LANGUAGE": "es",
    "WHISPER_TASK": "transcribe",
    "WHISPER_BEAM_SIZE": 5,
    "WHISPER_VAD": False,
    "WHISPER_INITIAL_PROMPT": "",
    "OIDO_AUTOTYPE": True,
    "OIDO_TYPEWRITER": False,
    "OIDO_COPY_CLIPBOARD": True,
}

PTT_ENV_KEYS = {"OIDO_PTT_MAIN_KEY"}

app = Flask(__name__, static_folder=None)


def _read_env_file(path: Path) -> dict:
    """Parsea Environment=KEY=VALUE del .service file en path."""
    out: dict = {}
    if not path.exists():
        return out
    text = path.read_text(encoding="utf-8")
    for m in re.finditer(r"^Environment=([^=]+)=(.*)$", text, re.MULTILINE):
        key, val = m.group(1).strip(), m.group(2).strip()
        if key in ENV_PARSERS:
            try:
                out[key] = ENV_PARSERS[key](val)
            except Exception:
                pass
    return out


def read_service_env() -> dict:
    """Carga config desde el .service correcto según ENV_SERVICE."""
    config = dict(DEFAULTS)
    # Lee daemon + ptt; sobrescribe defaults solo para keys que existan en cada file.
    seen_paths: set = set()
    for _, path in ENV_SERVICE.values():
        if path in seen_paths:
            continue
        seen_paths.add(path)
        config.update(_read_env_file(path))
    return config


def _write_env_to_file(path: Path, kv: dict) -> None:
    text = path.read_text(encoding="utf-8")
    for key, val in kv.items():
        val_str = ("1" if val else "0") if isinstance(val, bool) else str(val)
        line = f"Environment={key}={val_str}"
        pattern = rf"^Environment={re.escape(key)}=.*$"
        if re.search(pattern, text, re.MULTILINE):
            text = re.sub(pattern, line, text, count=1, flags=re.MULTILINE)
        else:
            insert_at = re.search(r"^Environment=", text, re.MULTILINE)
            if insert_at:
                pos = insert_at.start()
                text = text[:pos] + line + "\n" + text[pos:]
            else:
                text = text.replace("[Service]\n", f"[Service]\n{line}\n", 1)
    path.write_text(text, encoding="utf-8")


def write_service_env(updates: dict) -> tuple[bool, str]:
    """Reparte updates entre oido-daemon.service y oido-ptt.service según ENV_SERVICE,
    escribe los .service implicados, y reinicia solo los servicios afectados."""
    # Agrupar updates por (service_unit, service_path)
    by_service: dict = {}
    for key, val in updates.items():
        target = ENV_SERVICE.get(key)
        if target is None:
            continue
        unit, path = target
        by_service.setdefault((unit, path), {})[key] = val

    if not by_service:
        return False, "no hay keys ruteables"

    # Validar existencia ANTES de tocar nada
    for (unit, path), _ in by_service.items():
        if not path.exists():
            return False, f"Service file no encontrado: {path}"

    # Escribir cada archivo
    for (unit, path), kv in by_service.items():
        _write_env_to_file(path, kv)

    # daemon-reload + restart solo de los services afectados
    try:
        subprocess.run(["systemctl", "--user", "daemon-reload"], check=True, timeout=10)
        for (unit, _), _ in by_service.items():
            subprocess.run(["systemctl", "--user", "restart", unit], check=True, timeout=10)
    except subprocess.CalledProcessError as e:
        return False, f"systemctl error: {e}"

    units = sorted({unit for (unit, _), _ in by_service.items()})
    return True, f"Configuración aplicada · reiniciados: {', '.join(units)}"


@app.route("/")
def index():
    return send_from_directory(MOCKUP_DIR, "index.html")


def read_ptt_key() -> str:
    """Lee OIDO_PTT_MAIN_KEY del oido-ptt.service."""
    if not PTT_SERVICE_PATH.exists():
        return "KEY_RIGHTCTRL"
    text = PTT_SERVICE_PATH.read_text(encoding="utf-8")
    m = re.search(r"^Environment=OIDO_PTT_MAIN_KEY=(.*)$", text, re.MULTILINE)
    return m.group(1).strip() if m else "KEY_RIGHTCTRL"


def write_ptt_key(key: str) -> tuple[bool, str]:
    """Escribe nueva tecla en oido-ptt.service + restart."""
    if not PTT_SERVICE_PATH.exists():
        return False, "oido-ptt.service no encontrado"
    if not re.match(r"^KEY_[A-Z_0-9]+$", key):
        return False, f"key inválida: {key}"
    text = PTT_SERVICE_PATH.read_text(encoding="utf-8")
    text = re.sub(
        r"^Environment=OIDO_PTT_MAIN_KEY=.*$",
        f"Environment=OIDO_PTT_MAIN_KEY={key}",
        text, count=1, flags=re.MULTILINE,
    )
    PTT_SERVICE_PATH.write_text(text, encoding="utf-8")
    try:
        subprocess.run(["systemctl", "--user", "daemon-reload"], check=True, timeout=10)
        subprocess.run(["systemctl", "--user", "restart", "oido-ptt.service"], check=True, timeout=10)
    except subprocess.CalledProcessError as e:
        return False, f"systemctl: {e}"
    return True, "tecla aplicada"


@app.route("/api/config", methods=["GET"])
def api_get_config():
    cfg = read_service_env()
    cfg["OIDO_PTT_MAIN_KEY"] = read_ptt_key()
    return jsonify(cfg)


@app.route("/api/ptt-key", methods=["POST"])
def api_ptt_key():
    data = request.get_json(silent=True) or {}
    key = data.get("key", "").strip()
    if not key:
        return jsonify({"ok": False, "error": "key vacía"}), 400
    ok, msg = write_ptt_key(key)
    return jsonify({"ok": ok, "msg": msg, "key": key}), (200 if ok else 500)


@app.route("/api/config", methods=["POST"])
def api_post_config():
    updates = request.get_json(silent=True) or {}
    valid = {k: v for k, v in updates.items() if k in ENV_PARSERS}
    if not valid:
        return jsonify({"ok": False, "error": "no valid keys"}), 400
    ok, msg = write_service_env(valid)
    return jsonify({"ok": ok, "msg": msg, "applied": valid}), (200 if ok else 500)


@app.route("/api/status")
def api_status():
    def check(unit):
        r = subprocess.run(
            ["systemctl", "--user", "is-active", unit],
            capture_output=True, text=True, timeout=5,
        )
        return r.stdout.strip()

    return jsonify({
        "daemon": check("oido-daemon.service"),
        "ptt": check("oido-ptt.service"),
        "ts": int(time.time()),
    })


@app.route("/api/test/record", methods=["POST"])
def api_test():
    """Graba N segundos vía arecord + transcribe + devuelve texto."""
    seconds = int(request.json.get("seconds", 5)) if request.json else 5
    if seconds > 30:
        return jsonify({"ok": False, "error": "max 30s"}), 400

    tmp_wav = Path("/tmp/parla_test_record.wav")
    try:
        # Grabar
        subprocess.run(
            ["arecord", "-d", str(seconds), "-f", "S16_LE", "-r", "16000", "-c", "1", str(tmp_wav)],
            check=True, capture_output=True, timeout=seconds + 5,
        )
        # Transcribir vía audio_a_texto
        r = subprocess.run(
            ["/home/scripts/audio_a_texto", "--stdout", str(tmp_wav)],
            capture_output=True, text=True, timeout=60,
        )
        return jsonify({
            "ok": r.returncode == 0,
            "text": r.stdout.strip(),
            "stderr": r.stderr.strip()[:300],
        })
    except subprocess.CalledProcessError as e:
        return jsonify({"ok": False, "error": str(e), "stderr": e.stderr.decode()[:300] if e.stderr else ""}), 500
    except subprocess.TimeoutExpired:
        return jsonify({"ok": False, "error": "timeout"}), 500
    finally:
        tmp_wav.unlink(missing_ok=True)


@app.route("/api/logs")
def api_logs():
    n = int(request.args.get("n", 20))
    try:
        r = subprocess.run(
            ["journalctl", "--user", "-u", "oido-daemon", "-u", "oido-ptt", "-n", str(n), "--no-pager"],
            capture_output=True, text=True, timeout=10,
        )
        return jsonify({"ok": True, "log": r.stdout})
    except Exception as e:
        return jsonify({"ok": False, "error": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=4331, debug=False)
