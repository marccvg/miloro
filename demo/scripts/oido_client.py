#!/usr/bin/env python3
"""Oído Digital — cliente del daemon (demo portable).

Envía la ruta de un WAV al daemon vía socket Unix y recibe la respuesta
TSV en una línea.

Uso:
  oido_client.py <socket_path> <wav_path>

Exit code:
  0  respuesta recibida (sea OK o ERR; el contenido lo evalúa el caller).
  1  error de conexión / timeout / IO.
"""
import socket
import sys


def main() -> int:
    if len(sys.argv) != 3:
        print("uso: oido_client.py <socket> <wav>", file=sys.stderr)
        return 1
    sock_path, wav_path = sys.argv[1], sys.argv[2]
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(60)
            s.connect(sock_path)
            s.sendall((wav_path + "\n").encode("utf-8"))
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
            line = buf.decode("utf-8", errors="replace").rstrip("\n")
            sys.stdout.write(line)
            sys.stdout.write("\n")
            return 0
    except (OSError, socket.timeout) as e:
        print(f"oido_client error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
