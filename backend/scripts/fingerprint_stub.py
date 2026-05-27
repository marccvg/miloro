#!/usr/bin/env python3
"""Stub machine fingerprint para testing — Marc 2026-05-19.

La app cliente Tauri usará Rust nativo equivalente (CPU id + MAC + disk serial + OS install id).
Aquí cubrimos un subset estable per machine sin requerir privilegios.
"""

import hashlib
import platform
import uuid


def get_fingerprint() -> str:
    # CPU + MAC + OS info — algo estable per machine.
    cpu = platform.processor() or "unknown"
    mac = ":".join(
        ["{:02x}".format((uuid.getnode() >> i) & 0xFF) for i in range(0, 8 * 6, 8)][::-1]
    )
    osname = platform.system().lower()
    osrelease = platform.release()
    raw = f"{cpu}|{mac}|{osname}|{osrelease}"
    return hashlib.sha256(raw.encode()).hexdigest()


if __name__ == "__main__":
    print(get_fingerprint())
