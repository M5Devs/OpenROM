import os
import struct
import platform

SUPPORTED_INPUT = {
    ".iso":  "ISO",
    ".bin":  "BIN",
    ".cue":  "CUE",
    ".gdi":  "GDI",
    ".img":  "IMG",
    ".ecm":  "ECM",
    ".chd":  "CHD",
    ".cso":  "CSO",
    ".zso":  "ZSO",
    ".rvz":  "RVZ",
    ".wia":  "WIA",
    ".wbfs": "WBFS",
    ".gcz":  "GCZ",
}

PLATFORM_MAP = {
    "ISO":  "ISO Image",
    "BIN":  "CD Image",
    "CUE":  "CD Cue Sheet",
    "GDI":  "Dreamcast GDI",
    "IMG":  "Disk Image",
    "ECM":  "ECM Compressed",
    "CHD":  "CHD Archive",
    "CSO":  "Compressed ISO",
    "ZSO":  "Compressed ISO",
    "XISO": "Xbox ISO",
    "RVZ":  "GameCube / Wii",
    "WIA":  "GameCube / Wii",
    "WBFS": "Wii",
    "GCZ":  "GameCube / Wii",
}

FORMAT_COLORS = {
    "ISO":     "#e94560",
    "BIN":     "#f9a825",
    "CUE":     "#f9a825",
    "GDI":     "#9c27b0",
    "IMG":     "#673ab7",
    "CHD":     "#00bcd4",
    "CSO":     "#4caf50",
    "ZSO":     "#4caf50",
    "ECM":     "#ff9800",
    "XISO":    "#e91e63",
    "RVZ":     "#3f51b5",
    "WIA":     "#5c6bc0",
    "WBFS":    "#7986cb",
    "GCZ":     "#9fa8da",
    "UNKNOWN": "#7a8a9a",
}

# ── Complete Conversion Map ──────────────────────────────────────────────────
CONVERSION_MAP = {
    "ISO":  ["CHD", "CSO", "ECM", "XISO", "RVZ"],
    "BIN":  ["CHD", "ECM"],
    "CUE":  ["CHD"],
    "GDI":  ["CHD"],
    "IMG":  ["CHD"],
    "CHD":  ["ISO", "BIN/CUE"],
    "CSO":  ["ISO"],
    "ZSO":  ["ISO"],
    "ECM":  ["ISO", "BIN"],
    "XISO": ["Files"],
    "RVZ":  ["ISO"],
    "WIA":  ["ISO"],
    "WBFS": ["ISO"],
    "GCZ":  ["ISO"],
}

COMMAND_TEMPLATES = {
    ("ISO",  "CHD"):     "chdman createdvd -i \"{in}\" -o \"{out}\"",
    ("ISO",  "CSO"):     "maxcso \"{in}\" -o \"{out}\"",
    ("ISO",  "ECM"):     "ecm \"{in}\" \"{out}\"",
    ("ISO",  "XISO"):    "extract-xiso -r \"{in}\"",
    ("ISO",  "RVZ"):     "nodtool convert \"{in}\" \"{out}\"",
    ("BIN",  "CHD"):     "chdman createcd -i \"{cue}\" -o \"{out}\"",
    ("BIN",  "ECM"):     "ecm \"{in}\" \"{out}\"",
    ("CUE",  "CHD"):     "chdman createcd -i \"{in}\" -o \"{out}\"",
    ("GDI",  "CHD"):     "chdman createcd -i \"{in}\" -o \"{out}\"",
    ("IMG",  "CHD"):     "chdman createdvd -i \"{in}\" -o \"{out}\"",
    ("CHD",  "ISO"):     "chdman extractdvd -i \"{in}\" -o \"{out}\"",
    ("CHD",  "BIN/CUE"): "chdman extractcd -i \"{in}\" -o \"{out_cue}\"",
    ("CHD",  "BIN"):     "chdman extractcd -i \"{in}\" -o \"{out_cue}\"",
    ("CSO",  "ISO"):     "maxcso --decompress \"{in}\" -o \"{out}\"",
    ("ZSO",  "ISO"):     "maxcso --decompress \"{in}\" -o \"{out}\"",
    ("ECM",  "ISO"):     "unecm \"{in}\" \"{out}\"",
    ("ECM",  "BIN"):     "unecm \"{in}\" \"{out}\"",
    ("XISO", "Files"):   "extract-xiso -x \"{in}\" -d \"{out}\"",
    ("RVZ",  "ISO"):     "nodtool convert \"{in}\" \"{out}\"",
    ("WIA",  "ISO"):     "nodtool convert \"{in}\" \"{out}\"",
    ("WBFS", "ISO"):     "nodtool convert \"{in}\" \"{out}\"",
    ("GCZ",  "ISO"):     "nodtool convert \"{in}\" \"{out}\"",
}

# ── Magic byte constants ─────────────────────────────────────────────────────

# CHD v4/v5 tag: "MComprHD" (8 bytes)
_CHD_MAGIC          = b"MComprHD"
_CHD_V4_HEADER_SIZE = 108
_CHD_V5_HEADER_SIZE = 124
# Offsets inside the CHD header (after the 8-byte tag + 4-byte header length + 4-byte version)
_CHD_VERSION_OFFSET = 12   # uint32 BE

# CHD v5 disk type flags (offset 16 in v5 = uint32 BE "flags")
# Bit 0 set → writable; bit 1 set → has parent.
# Disk type is encoded in the compression field[0] at offset 20:
#   0x00000000 = uncompressed (raw), but we distinguish CD vs DVD by unitbytes field
# CHD unitbytes offset in v5: 60 (uint32 BE). CD = 2448, DVD = 2048.
_CHD_V5_UNITBYTES_OFFSET = 60

# PS2 magic at start of ISO (Volume Descriptor)
_PS2_MAGIC  = b"PLAYSTATION"   # appears in PVD at 0x8000+
_PS1_MAGIC  = b"PlayStation"

# GameCube/Wii: GC magic at offset 0x1C, Wii magic at 0x18
_GC_MAGIC   = 0xC2339F3D
_WII_MAGIC  = 0x5D1C9EA3

# SYNC header for BIN sector sniffing
_CD_SYNC    = b'\x00' + b'\xff' * 10 + b'\x00'

# Xbox XDVDFS magic
_XBOX_MAGIC         = b"MICROSOFT*XBOX*MEDIA"
_XBOX_OFFSETS       = [0x10000, 0x2090000]


# ── Public helpers ───────────────────────────────────────────────────────────

def get_extension(filename: str) -> str:
    return filename.lower().rsplit('.', 1)[-1]


def get_output_name(input_file: str, new_ext: str) -> str:
    clean_ext = new_ext.lstrip('.')
    base = input_file.rsplit('.', 1)[0]
    if base.lower().endswith(f".{clean_ext.lower()}"):
        return base
    return f"{base}.{clean_ext}"


def get_badge_color(fmt: str) -> str:
    return FORMAT_COLORS.get(fmt.upper(), FORMAT_COLORS["UNKNOWN"])


def get_valid_targets(fmt: str) -> list:
    return CONVERSION_MAP.get(fmt.upper(), [])


def get_command_preview(fmt: str, target: str, filename: str = "game.iso") -> str:
    template = COMMAND_TEMPLATES.get((fmt.upper(), target.upper()))
    if not template:
        return f"{fmt} -> {target}"

    out = get_output_name(filename, target.lower().replace('/cue', ''))
    base = filename.rsplit('.', 1)[0]
    cue = base + ".cue"

    return template.format(
        **{"in": filename, "out": out, "cue": cue, "out_cue": cue}
    )


def detect_file(filepath: str) -> dict:
    if not os.path.isfile(filepath):
        return {"error": f"File not found: {filepath}"}

    name    = os.path.basename(filepath)
    ext_str = get_extension(name)
    ext     = f".{ext_str}"
    size    = os.path.getsize(filepath)

    fmt      = SUPPORTED_INPUT.get(ext, "UNKNOWN")
    needs_ecm = (fmt == "ECM")

    # FIX #3 — open the file ONCE and pass the header buffer to all detectors
    header = _read_header(filepath, 0x210000)   # read up to ~2 MB (covers Xbox offset 0x10000 + PS2 PVD)

    plat     = _guess_platform(filepath, fmt, size, header)
    chd_type = _read_chd_type(filepath) if fmt == "CHD" else None

    result = {
        "format":           fmt,
        "platform":         plat,
        "size_bytes":       size,
        "size_str":         _human_size(size),
        "needs_ecm_decode": needs_ecm,
        "paired_cue":       None,
        "paired_bin":       None,
        "chd_type":         chd_type,
        "valid_targets":    get_valid_targets(fmt),
        "badge_color":      get_badge_color(fmt),
    }

    if fmt == "BIN":
        result["paired_cue"] = _find_pair(filepath, ".cue")

    if fmt == "CUE":
        result["paired_bin"] = _find_pair(filepath, ".bin")

    return result


def detect_folder(folder: str) -> list:
    results = []
    if not os.path.isdir(folder):
        return results
    for fname in os.listdir(folder):
        fpath = os.path.join(folder, fname)
        if not os.path.isfile(fpath):
            continue
        ext = f".{get_extension(fname)}"
        if ext in SUPPORTED_INPUT:
            info = detect_file(fpath)
            info["filepath"] = fpath
            info["filename"] = fname
            results.append(info)
    return results


from core.config import get_tool_path as _get_tool_path

def get_chdman_path() -> str:
    return _get_tool_path("chdman")

def get_tool_path(tool: str) -> str:
    return _get_tool_path(tool)


# ── Internal helpers ─────────────────────────────────────────────────────────

def _read_header(filepath: str, size: int) -> bytes:
    """Read up to `size` bytes from the start of a file. Returns b'' on error."""
    try:
        with open(filepath, "rb") as f:
            return f.read(size)
    except Exception:
        return b""


def _guess_platform(filepath: str, fmt: str, size: int, header: bytes) -> str:
    """
    FIX #1 — Proper platform detection using magic bytes first, size as last resort.

    Priority order:
      1. Format-specific overrides (GDI → Dreamcast, CSO/ZSO size heuristic, XISO)
      2. Magic byte detection from pre-read header buffer (no extra file I/O)
      3. Size-based fallback (kept as last resort only)
    """
    if fmt == "GDI":
        return "Dreamcast"
    if fmt in ("CSO", "ZSO"):
        return "PSP" if size < 2 * 1024 * 1024 * 1024 else "PSP / PS2"
    if fmt == "XISO":
        return "Xbox"

    if fmt in ("ISO", "BIN", "IMG", "CUE"):
        # Xbox: XDVDFS magic at fixed sector offsets (only readable for ISO/IMG)
        if fmt in ("ISO", "IMG") and _header_has_xbox_magic(header):
            return "Xbox"

        # PSP: UMD_DATA / PSP_GAME marker in first 64 KB
        if fmt in ("ISO", "IMG") and _header_has_psp_magic(header):
            return "PSP"

        # GameCube: magic word at offset 0x1C
        if fmt in ("ISO", "IMG") and _header_has_gc_magic(header):
            return "GameCube"

        # Wii: magic word at offset 0x18
        if fmt in ("ISO", "IMG") and _header_has_wii_magic(header):
            return "Wii"

        # PS2: "PLAYSTATION" in the ISO 9660 Primary Volume Descriptor (0x8000–0x8800)
        if _header_has_ps2_magic(header):
            return "PS2"

        # PS1: "PlayStation" marker — smaller volumes, CD-based
        if _header_has_ps1_magic(header):
            return "PS1"

        # ── Size-based last resort (BIN/CUE files can't be easily header-sniffed) ──
        mb = size / (1024 * 1024)
        if mb < 700:
            return "PS1"        # PS1 single disc ≤ ~650 MB
        elif mb < 8500:
            return "PS2 / GC"   # PS2 DVDs up to ~8.5 GB
        else:
            return "PS2 / Xbox"

    return PLATFORM_MAP.get(fmt, "ROM File")


def _header_has_xbox_magic(header: bytes) -> bool:
    """Check XDVDFS magic at offset 0x10000. Offset 0x2090000 requires a seek — skipped here."""
    offset = 0x10000
    if len(header) >= offset + 20:
        return header[offset:offset + 20] == _XBOX_MAGIC
    return False


def _header_has_psp_magic(header: bytes) -> bool:
    return b"PSP_GAME" in header[:65536] or b"UMD_DATA" in header[:65536]


def _header_has_gc_magic(header: bytes) -> bool:
    """GameCube disc magic at offset 0x1C (4 bytes, big-endian)."""
    if len(header) >= 0x20:
        word = struct.unpack_from(">I", header, 0x1C)[0]
        return word == _GC_MAGIC
    return False


def _header_has_wii_magic(header: bytes) -> bool:
    """Wii disc magic at offset 0x18 (4 bytes, big-endian)."""
    if len(header) >= 0x1C:
        word = struct.unpack_from(">I", header, 0x18)[0]
        return word == _WII_MAGIC
    return False


def _header_has_ps2_magic(header: bytes) -> bool:
    """PS2 identifier in ISO 9660 PVD area starting at 0x8000."""
    pvd_area = header[0x8000:0x8800] if len(header) >= 0x8800 else b""
    return _PS2_MAGIC in pvd_area


def _header_has_ps1_magic(header: bytes) -> bool:
    """PS1 identifier somewhere in the first 64 KB."""
    return _PS1_MAGIC in header[:65536]


def _read_chd_type(filepath: str) -> str:
    """
    FIX #2 — Read the actual CHD header to determine CD vs DVD type.

    CHD v4/v5 header layout (big-endian):
      0x00  8 bytes  tag "MComprHD"
      0x08  4 bytes  header length (uint32)
      0x0C  4 bytes  version       (uint32)

    CHD v5 additional fields (offset from start):
      0x14  4 bytes  compression[0] (uint32) — 0 = uncompressed
      0x3C  4 bytes  unitbytes      (uint32) — bytes per hunk unit
                     2448 = CD sector size → CD type
                     2048 = DVD/HDD sector size → DVD type

    Falls back to size-based heuristic only if the header can't be read.
    """
    try:
        with open(filepath, "rb") as f:
            raw = f.read(128)

        if len(raw) < 16 or raw[:8] != _CHD_MAGIC:
            # Not a valid CHD — fall back to size
            return _chd_type_by_size(os.path.getsize(filepath))

        version = struct.unpack_from(">I", raw, 12)[0]

        if version == 5 and len(raw) >= 64:
            # v5: unitbytes at offset 60
            unitbytes = struct.unpack_from(">I", raw, 60)[0]
            if unitbytes == 2448:
                return "cd"
            elif unitbytes in (512, 2048, 4096):
                return "dvd"
            # Unknown unitbytes — fall through to size heuristic

        elif version == 4 and len(raw) >= 108:
            # v4: hunkbytes at offset 76 (uint32), unitbytes not stored directly.
            # Use flags at offset 16: bit 1 = CD image.
            flags = struct.unpack_from(">I", raw, 16)[0]
            if flags & 0x2:
                return "cd"
            return "dvd"

        # v3 or unknown — size fallback
        return _chd_type_by_size(os.path.getsize(filepath))

    except Exception:
        return _chd_type_by_size(os.path.getsize(filepath))


def _chd_type_by_size(size: int) -> str:
    """Last-resort size-based CHD type guess (kept as fallback only)."""
    mb = size / (1024 * 1024)
    return "cd" if mb < 900 else "dvd"


def _find_pair(filepath: str, target_ext: str) -> str | None:
    base = filepath.rsplit('.', 1)[0]
    candidate = base + (target_ext if target_ext.startswith('.') else f".{target_ext}")
    return candidate if os.path.isfile(candidate) else None


def _human_size(size: int) -> str:
    for unit in ("B", "KB", "MB", "GB"):
        if size < 1024:
            return f"{size:.1f} {unit}"
        size /= 1024
    return f"{size:.1f} TB"
