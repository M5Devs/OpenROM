# OpenROM — Universal ROM Compression Suite
# M5 Dev | GPL v3 + Commons Clause

import os
import shutil


SUPPORTED_HEADERS = {
    "NES": {
        "magic": b"NES\x1a",    # iNES header
        "size": 16,
        "ext": [".nes"]
    },
    "SNES": {
        "size": 512,             # SMC/SFC copier header
        "ext": [".smc", ".sfc", ".fig", ".swc"]
    },
    "GB/GBC": {
        "size": 512,
        "ext": [".gb", ".gbc"]
    },
    "GBA": {
        "size": 0,               # GBA has no standard header
        "ext": [".gba"]
    },
}


def detect_header(filepath: str) -> dict | None:
    """
    Detect if a ROM file has a copier/system header.

    Returns:
      {
        "system": "NES"|"SNES"|"GB"|"GBA",
        "header_size": int,
        "has_header": bool,
        "confidence": "certain"|"likely"|"unlikely"
      }
      or None if no header detected / not applicable.
    """
    if not os.path.exists(filepath):
        return None

    ext = os.path.splitext(filepath)[1].lower()
    system = None

    for sys_name, sys_info in SUPPORTED_HEADERS.items():
        if ext in sys_info["ext"]:
            system = sys_name
            break

    if not system:
        return None

    try:
        file_size = os.path.getsize(filepath)
    except Exception:
        return None

    if system == "NES":
        try:
            with open(filepath, "rb") as f:
                magic = f.read(4)
            if magic == b"NES\x1a":
                return {
                    "system": "NES",
                    "header_size": 16,
                    "has_header": True,
                    "confidence": "certain"
                }
            else:
                return {
                    "system": "NES",
                    "header_size": 0,
                    "has_header": False,
                    "confidence": "certain"
                }
        except Exception:
            return None

    elif system == "SNES":
        # SNES detection logic:
        # File size % 1024 == 512 -> has copier header (512 bytes)
        # File size % 1024 == 0   -> no header
        # confidence: "certain" if size check passes, "likely" otherwise
        rem = file_size % 1024
        if rem == 512:
            return {
                "system": "SNES",
                "header_size": 512,
                "has_header": True,
                "confidence": "certain"
            }
        elif rem == 0:
            return {
                "system": "SNES",
                "header_size": 0,
                "has_header": False,
                "confidence": "certain"
            }
        else:
            has_hdr = (file_size > 512 and rem == 512)
            return {
                "system": "SNES",
                "header_size": 512 if has_hdr else 0,
                "has_header": has_hdr,
                "confidence": "likely"
            }

    elif system in ("GB/GBC", "GB"):
        rem = file_size % 1024
        if rem == 512:
            return {
                "system": "GB/GBC",
                "header_size": 512,
                "has_header": True,
                "confidence": "certain"
            }
        elif rem == 0:
            return {
                "system": "GB/GBC",
                "header_size": 0,
                "has_header": False,
                "confidence": "certain"
            }
        else:
            return {
                "system": "GB/GBC",
                "header_size": 0,
                "has_header": False,
                "confidence": "likely"
            }

    elif system == "GBA":
        return {
            "system": "GBA",
            "header_size": 0,
            "has_header": False,
            "confidence": "certain"
        }

    return None


def remove_header(
    filepath: str,
    output_dir: str = None,
    backup: bool = True
) -> str:
    """
    Remove copier header from a ROM file if present.

    Returns:
      Path of clean ROM.
    """
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"ROM file not found: {filepath}")

    info = detect_header(filepath)
    target_dir = output_dir or os.path.dirname(os.path.abspath(filepath)) or "."
    os.makedirs(target_dir, exist_ok=True)

    filename = os.path.basename(filepath)
    clean_path = os.path.join(target_dir, filename)

    # If backup is requested and outputting in place or same filename
    if backup and os.path.abspath(clean_path) == os.path.abspath(filepath):
        bak_path = filepath + ".bak"
        if not os.path.exists(bak_path):
            shutil.copy2(filepath, bak_path)

    if not info or not info.get("has_header") or info.get("header_size", 0) <= 0:
        # No header to remove — copy or keep as is
        if os.path.abspath(clean_path) != os.path.abspath(filepath):
            shutil.copy2(filepath, clean_path)
        return clean_path

    hdr_size = info["header_size"]

    # Write clean ROM excluding the header
    with open(filepath, "rb") as f_in:
        f_in.seek(hdr_size)
        data = f_in.read()

    with open(clean_path, "wb") as f_out:
        f_out.write(data)

    return clean_path
