"""Cross-backend "type at cursor" and clipboard helpers.

Backend selection:
  * Wayland → try ydotool (if ydotoold socket exists), then wtype, then xdotool
    via XWayland as a last resort.
  * X11    → xdotool.

Clipboard:
  * Tries xclip first (X11 / XWayland), then wl-copy (Wayland).
"""
from __future__ import annotations

import os
import shutil
import subprocess


def _is_wayland() -> bool:
    return bool(os.environ.get("WAYLAND_DISPLAY")) or os.environ.get("XDG_SESSION_TYPE") == "wayland"


def copy_to_clipboard(text: str) -> str:
    """Return empty string on success, otherwise a diagnostic message."""
    payload = text.encode("utf-8")
    errors: list[str] = []

    if shutil.which("xclip"):
        for selection in ("clipboard", "primary"):
            try:
                subprocess.run(
                    ["xclip", "-selection", selection],
                    input=payload,
                    check=True,
                    stderr=subprocess.PIPE,
                    timeout=3,
                )
            except subprocess.CalledProcessError as e:
                errors.append(f"xclip-{selection}: rc={e.returncode}")
            except subprocess.TimeoutExpired:
                errors.append(f"xclip-{selection}: timeout")
        if not errors:
            return ""

    if shutil.which("wl-copy"):
        try:
            subprocess.run(
                ["wl-copy"],
                input=payload,
                check=True,
                stderr=subprocess.PIPE,
                timeout=3,
            )
            return ""
        except subprocess.CalledProcessError as e:
            errors.append(f"wl-copy: rc={e.returncode}")
        except subprocess.TimeoutExpired:
            errors.append("wl-copy: timeout")

    if not errors:
        return "no clipboard backend (install xclip or wl-clipboard)"
    return "; ".join(errors)


def type_at_cursor(text: str) -> str:
    """Type ``text`` into the focused window. Returns "" on success."""
    if not text:
        return ""

    if _is_wayland():
        if shutil.which("ydotool"):
            sock = os.environ.get(
                "YDOTOOL_SOCKET",
                f"{os.environ.get('XDG_RUNTIME_DIR', '/tmp')}/.ydotool_socket",
            )
            if os.path.exists(sock):
                env = {**os.environ, "YDOTOOL_SOCKET": sock}
                try:
                    subprocess.run(
                        ["ydotool", "type", "--next-delay", "5", "--", text],
                        check=True,
                        env=env,
                        stderr=subprocess.PIPE,
                        timeout=30,
                    )
                    return ""
                except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
                    last = f"ydotool failed: {e}"
            else:
                last = f"ydotool socket missing at {sock}"
        else:
            last = "ydotool not installed"

        if shutil.which("wtype"):
            try:
                subprocess.run(
                    ["wtype", "--", text],
                    check=True,
                    stderr=subprocess.PIPE,
                    timeout=30,
                )
                return ""
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
                last = f"wtype failed: {e}"

        if shutil.which("xdotool") and os.environ.get("DISPLAY"):
            try:
                subprocess.run(
                    ["xdotool", "type", "--delay", "5", "--", text],
                    check=True,
                    stderr=subprocess.PIPE,
                    timeout=30,
                )
                return ""
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
                last = f"xdotool (XWayland) failed: {e}"

        return last or "no Wayland autotype backend (install ydotool or wtype)"

    if shutil.which("xdotool"):
        try:
            subprocess.run(
                ["xdotool", "type", "--delay", "5", "--", text],
                check=True,
                stderr=subprocess.PIPE,
                timeout=30,
            )
            return ""
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
            return f"xdotool failed: {e}"

    return "no autotype backend (install xdotool on X11)"
