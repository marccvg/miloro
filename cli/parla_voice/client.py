"""Minimal client for the echo-voice daemon protocol."""
from __future__ import annotations

import socket
from dataclasses import dataclass
from pathlib import Path


@dataclass
class Response:
    ok: bool
    text: str = ""
    chars: int = 0
    preview: str = ""
    error: str = ""

    @classmethod
    def parse(cls, line: str) -> "Response":
        line = line.rstrip("\n")
        if not line:
            return cls(ok=False, error="empty response")
        parts = line.split("\t")
        if parts[0] == "OK" and len(parts) >= 4:
            try:
                chars = int(parts[1])
            except ValueError:
                chars = len(parts[3])
            return cls(ok=True, chars=chars, preview=parts[2], text=parts[3])
        if parts[0] == "ERR":
            return cls(ok=False, error="\t".join(parts[1:]) or "unknown")
        return cls(ok=False, error=f"unexpected: {line!r}")


def transcribe(socket_path: Path, wav_path: Path, *, timeout: float = 60.0) -> Response:
    """Send ``wav_path`` to the daemon and return its parsed response."""
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(timeout)
            s.connect(str(socket_path))
            s.sendall((str(wav_path) + "\n").encode("utf-8"))
            try:
                s.shutdown(socket.SHUT_WR)
            except OSError:
                pass
            buf = b""
            while True:
                chunk = s.recv(8192)
                if not chunk:
                    break
                buf += chunk
                if b"\n" in buf:
                    break
            return Response.parse(buf.decode("utf-8", errors="replace"))
    except (OSError, socket.timeout) as e:
        return Response(ok=False, error=f"connection: {e}")
