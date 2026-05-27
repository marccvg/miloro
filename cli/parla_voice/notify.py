"""Thin wrapper around ``notify-send`` so the rest of the code stays clean."""
from __future__ import annotations

import shutil
import subprocess


def notify(title: str, body: str = "", *, enabled: bool = True, app: str = "echo-voice") -> None:
    if not enabled:
        return
    if not shutil.which("notify-send"):
        return
    try:
        subprocess.run(
            ["notify-send", "-a", app, "-t", "2500", title, body],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=2,
        )
    except (OSError, subprocess.SubprocessError):
        pass
