import os
import platform

SUPPORTED_INPUT = {
    ".iso": "ISO",
    ".bin": "BIN",
    ".cue": "CUE",
    ".gdi": "GDI",
    ".img": "IMG",
    ".ecm": "ECM",
    ".chd": "CHD",
    ".cso": "CSO",
    ".zso": "ZSO",
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
}

FORMAT_COLORS = {
    "ISO":  "#e94560",
    "BIN":  "#f9a825",
    "CUE":  "#f9a825",
    "GDI":  "#9c27b0",
    "IMG":  "#673ab7",
    "CHD":  "#00bcd4",
    "CSO":  "#4caf50",
    "ZSO":  "#4caf50",
    "ECM":  "#ff9800",
    "XISO": "#e91e63",
    "UNKNOWN": "#7a8a9a",
}

# ── Complete Conversion Map ──────────────────────────────────────────────────
# Key: source format -> list of valid target formats
CONVERSION_MAP = {
    "ISO":  ["CHD", "CSO", "ECM", "XISO", "BIN"],
    "BIN":  ["CHD", "ECM", "ISO"],
    "CUE":  ["CHD"],
    "GDI":  ["CHD"],
    "IMG":  ["CHD"],
    "CHD":  ["ISO", "BIN/CUE"],
    "CSO":  ["ISO"],
    "ZSO":  ["ISO"],
    "ECM":  ["ISO", "BIN"],
    "XISO": ["ISO"],
}

COMMAND_TEMPLATES = {
    ("ISO", "CHD"): "chdman createdvd -i \"{in}\" -o \"{out}\"",
    ("ISO", "CSO"): "maxcso \"{in}\" -o \"{out}\"",
    ("ISO", "ECM"): "ecm \"{in}\" \"{out}\"",
    ("ISO", "XISO"): "extract-xiso -r \"{in}\"",
    ("ISO", "BIN"): "bchunk -v \"{in}\" \"{cue}\" \"{out_prefix}\"",
    ("BIN", "CHD"): "chdman createcd -i \"{cue}\" -o \"{out}\"",
    ("BIN", "ECM"): "ecm \"{in}\" \"{out}\"",
    ("BIN", "ISO"): "bchunk -v \"{in}\" \"{cue}\" \"{out_prefix}\"",
    ("CUE", "CHD"): "chdman createcd -i \"{in}\" -o \"{out}\"",
    ("GDI", "CHD"): "chdman createcd -i \"{in}\" -o \"{out}\"",
    ("IMG", "CHD"): "chdman createdvd -i \"{in}\" -o \"{out}\"",
    ("CHD", "ISO"): "chdman extractdvd -i \"{in}\" -o \"{out}\"",
    ("CHD", "BIN/CUE"): "chdman extractcd -i \"{in}\" -o \"{out_cue}\"",
    ("CHD", "BIN"): "chdman extractcd -i \"{in}\" -o \"{out_cue}\"",
    ("CSO", "ISO"): "maxcso --decompress \"{in}\" -o \"{out}\"",
    ("ZSO", "ISO"): "maxcso --decompress \"{in}\" -o \"{out}\"",
    ("ECM", "ISO"): "unecm \"{in}\" \"{out}\"",
    ("ECM", "BIN"): "unecm \"{in}\" \"{out}\"",
    ("XISO", "ISO"): "extract-xiso -x \"{in}\" -d \"{out}\"",
}

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
    """Return valid output formats for a given source format."""
    return CONVERSION_MAP.get(fmt.upper(), [])

def get_command_preview(fmt: str, target: str, filename: str = "game.iso") -> str:
    template = COMMAND_TEMPLATES.get((fmt.upper(), target.upper()))
    if not template:
        return f"{fmt} -> {target}"

    out = get_output_name(filename, target.lower().replace('/cue', ''))
    base = filename.rsplit('.', 1)[0]
    cue = base + ".cue"

    return template.format(
        **{"in": filename, "out": out, "cue": cue, "out_cue": cue, "out_prefix": base}
    )

def detect_file(filepath: str) -> dict:
    if not os.path.isfile(filepath):
        return {"error": f"File not found: {filepath}"}

    name = os.path.basename(filepath)
    ext_str = get_extension(name)
    ext = f".{ext_str}"
    size = os.path.getsize(filepath)

    fmt = SUPPORTED_INPUT.get(ext, "UNKNOWN")
    needs_ecm = (fmt == "ECM")
    plat = _guess_platform(filepath, fmt, size)

    chd_type = None
    if fmt == "CHD":
        chd_type = _guess_chd_type(size)

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
        cue = _find_pair(filepath, ".cue")
        result["paired_cue"] = cue

    if fmt == "CUE":
        bn = _find_pair(filepath, ".bin")
        result["paired_bin"] = bn

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

def _guess_platform(filepath: str, fmt: str, size: int) -> str:
    if fmt == "GDI":
        return "Dreamcast"
    if fmt in ("CSO", "ZSO"):
        return "PSP / PS2"
    if fmt == "XISO":
        return "Xbox"
    if fmt in ("ISO", "BIN", "IMG", "CUE"):
        mb = size / (1024 * 1024)
        if mb < 800:
            return "PS1"
        elif mb < 2000:
            return "PS2 / GC"
        else:
            return "PS2 / Xbox"
    return PLATFORM_MAP.get(fmt, "ROM File")

def _guess_chd_type(size: int) -> str:
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
