import os
import subprocess

from core.detector import get_chdman_path


def verify_chd(filepath: str, on_log=None) -> bool:
    """Run chdman verify on a CHD file. Returns True if valid."""
    log = on_log or print
    if not os.path.isfile(filepath):
        log(f"[VERIFY] File not found: {filepath}")
        return False

    chdman = get_chdman_path()
    cmd = [chdman, "verify", "-i", filepath]
    log(f"[VERIFY] Checking {os.path.basename(filepath)}...")

    try:
        result = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        output = result.stdout.strip()
        for line in output.splitlines():
            log(f"  {line}")

        if result.returncode == 0:
            log("  ✅ CHD is valid")
            return True
        else:
            log("  ❌ CHD verification failed")
            return False
    except FileNotFoundError:
        log(f"  ❌ chdman not found at: {chdman}")
        return False


def get_chd_info(filepath: str) -> dict:
    """Return metadata dict from chdman info."""
    info = {}
    if not os.path.isfile(filepath):
        return info

    chdman = get_chdman_path()
    cmd = [chdman, "info", "-i", filepath]

    try:
        result = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        for line in result.stdout.splitlines():
            if ":" in line:
                key, _, val = line.partition(":")
                info[key.strip()] = val.strip()
    except Exception:
        pass
    return info
