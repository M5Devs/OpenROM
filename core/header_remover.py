# OpenROM — Universal ROM Compression Suite
# M5 Dev | GPL v3

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


def _verify_snes_internal_header(data: bytes, offset: int) -> bool:
    """
    Verify internal SNES ROM registration header at given offset.
    Checks if checksum + checksum complement == 0xFFFF and complement != 0.
    LoROM offset: 0x7FC0 (or 0x81C0 with copier header)
    HiROM offset: 0xFFC0 (or 0x101C0 with copier header)
    """
    if len(data) < offset + 0x40:
        return False
    # Checksum complement is at offset + 0x1C (2 bytes, little endian)
    # Checksum is at offset + 0x1E (2 bytes, little endian)
    complement = data[offset + 0x1C] | (data[offset + 0x1D] << 8)
    checksum   = data[offset + 0x1E] | (data[offset + 0x1F] << 8)

    if (checksum ^ complement) == 0xFFFF and complement != 0:
        return True
    return False


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
        # Check size % 1024 == 512 as baseline, then validate internal SNES registration header.
        rem = file_size % 1024
        try:
            with open(filepath, "rb") as f:
                header_data = f.read(0x10200)  # Read up to 0x10200 bytes for header check

            # Check if copier header exists (512 bytes prefix)
            has_copier_header_internal = (
                _verify_snes_internal_header(header_data, 0x81C0) or
                _verify_snes_internal_header(header_data, 0x101C0)
            )
            # Check if clean ROM without copier header
            has_clean_internal = (
                _verify_snes_internal_header(header_data, 0x7FC0) or
                _verify_snes_internal_header(header_data, 0xFFC0)
            )

            if has_copier_header_internal:
                return {
                    "system": "SNES",
                    "header_size": 512,
                    "has_header": True,
                    "confidence": "certain"
                }
            elif has_clean_internal:
                return {
                    "system": "SNES",
                    "header_size": 0,
                    "has_header": False,
                    "confidence": "certain"
                }
        except Exception:
            pass

        # Fallback to size check if internal registration header check is inconclusive
        if rem == 512:
            return {
                "system": "SNES",
                "header_size": 512,
                "has_header": True,
                "confidence": "likely"
            }
        elif rem == 0:
            return {
                "system": "SNES",
                "header_size": 0,
                "has_header": False,
                "confidence": "certain"
            }
        else:
            return {
                "system": "SNES",
                "header_size": 0,
                "has_header": False,
                "confidence": "unlikely"
            }

    elif system == "GB/GBC":
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
        # Only create backup if .bak file does NOT already exist to preserve original dump
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
