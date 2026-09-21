"""
OpenROM ROM Renamer — DAT-based ROM identification and renaming.
Supports No-Intro and Redump DAT files (same XML format).
M5 Dev | GPL v3
"""

import os
import shutil
import xml.etree.ElementTree as ET
from collections.abc import Callable
from dataclasses import dataclass

# ── DAT storage ───────────────────────────────────────────────────────────────

def get_dats_dir() -> str:
    """Returns the directory where OpenROM stores imported DAT files."""
    from core.config import get_config_dir
    dats_dir = os.path.join(get_config_dir(), "dats")
    os.makedirs(dats_dir, exist_ok=True)
    return dats_dir

def import_dat(dat_path: str) -> dict:
    """
    Import a DAT file into OpenROM's config directory.
    Returns info dict with keys: name, source, system, game_count, stored_path
    Raises ValueError if the file is not a valid DAT.
    """
    if not os.path.isfile(dat_path):
        raise ValueError(f"File not found: {dat_path}")

    tree = ET.parse(dat_path)
    root = tree.getroot()

    header = root.find("header")
    if header is None:
        raise ValueError("Invalid DAT file: no <header> element found")

    name_el = header.find("name")
    url_el  = header.find("url")

    dat_name = name_el.text.strip() if name_el is not None else os.path.basename(dat_path)
    dat_url  = url_el.text.strip()  if url_el  is not None else ""

    source = "No-Intro" if "no-intro" in dat_url.lower() else \
             "Redump"   if "redump"   in dat_url.lower() else "Unknown"

    game_count = len(root.findall("game"))

    # Store with sanitized name
    safe_name = "".join(c if c.isalnum() or c in " .-_()" else "_" for c in dat_name)
    stored_path = os.path.join(get_dats_dir(), f"{safe_name}.dat")
    shutil.copy2(dat_path, stored_path)

    return {
        "name":        dat_name,
        "source":      source,
        "system":      dat_name,
        "game_count":  game_count,
        "stored_path": stored_path,
        "url":         dat_url,
    }

def list_dats() -> list[dict]:
    """
    Returns a list of all imported DATs with their metadata.
    Each dict has: name, source, game_count, stored_path
    """
    dats_dir = get_dats_dir()
    result = []
    for fname in sorted(os.listdir(dats_dir)):
        if not fname.endswith(".dat"):
            continue
        fpath = os.path.join(dats_dir, fname)
        try:
            info = _read_dat_header(fpath)
            info["stored_path"] = fpath
            result.append(info)
        except Exception:
            pass
    return result

def remove_dat(stored_path: str) -> None:
    """Remove an imported DAT file."""
    if os.path.isfile(stored_path):
        os.remove(stored_path)

def _read_dat_header(dat_path: str) -> dict:
    """Read header info from a DAT file without loading all games."""
    tree = ET.parse(dat_path)
    root = tree.getroot()
    header  = root.find("header")
    name_el = header.find("name") if header is not None else None
    url_el  = header.find("url")  if header is not None else None
    dat_name = name_el.text.strip() if name_el is not None else os.path.basename(dat_path)
    dat_url  = url_el.text.strip()  if url_el  is not None else ""
    source   = "No-Intro" if "no-intro" in dat_url.lower() else \
               "Redump"   if "redump"   in dat_url.lower() else "Unknown"
    game_count = len(root.findall("game"))
    return {"name": dat_name, "source": source, "game_count": game_count}


# ── CRC32 calculation ─────────────────────────────────────────────────────────

def calc_crc32(filepath: str, on_progress: Callable[[float], None] | None = None) -> str:
    """
    Calculate CRC32 of a file. Returns lowercase hex string e.g. 'dbef116c'.
    Calls on_progress(percent) periodically if provided.
    """
    import zlib
    crc = 0
    file_size = os.path.getsize(filepath)
    bytes_read = 0
    chunk_size = 1024 * 1024  # 1 MB

    with open(filepath, "rb") as f:
        while True:
            chunk = f.read(chunk_size)
            if not chunk:
                break
            crc = zlib.crc32(chunk, crc)
            bytes_read += len(chunk)
            if on_progress and file_size > 0:
                on_progress(bytes_read / file_size * 100)

    return format(crc & 0xFFFFFFFF, "08x")


# ── DAT lookup ────────────────────────────────────────────────────────────────

def load_dat_index(dat_path: str) -> dict[str, dict]:
    """
    Load a DAT file and return a dict indexed by CRC32 (lowercase hex).
    Each value is: {name, description, rom_name, size, md5, sha1}
    """
    tree  = ET.parse(dat_path)
    root  = tree.getroot()
    index = {}

    for game in root.findall("game"):
        game_name = game.get("name", "")
        desc_el   = game.find("description")
        desc      = desc_el.text.strip() if desc_el is not None else game_name

        for rom in game.findall("rom"):
            crc = (rom.get("crc") or "").strip().lower().zfill(8)
            if not crc:
                continue
            index[crc] = {
                "name":        game_name,
                "description": desc,
                "rom_name":    rom.get("name", ""),
                "size":        int(rom.get("size") or 0),
                "md5":         (rom.get("md5")  or "").lower(),
                "sha1":        (rom.get("sha1") or "").lower(),
            }

    return index


# ── Scan results ──────────────────────────────────────────────────────────────

@dataclass
class RomScanResult:
    filepath:      str
    filename:      str
    crc32:         str          = ""
    matched:       bool         = False
    canonical_name: str         = ""   # game name from DAT
    rom_name:      str          = ""   # full rom filename from DAT
    dat_source:    str          = ""
    error:         str          = ""

    @property
    def suggested_filename(self) -> str:
        """Returns the canonical filename (rom_name from DAT) if matched."""
        if not self.matched or not self.rom_name:
            return self.filename
        return self.rom_name


# ── Main scan function ────────────────────────────────────────────────────────

def scan_folder(
    folder: str,
    dat_paths: list[str],
    on_progress: Callable[[str, float], None] | None = None,
    on_result:   Callable[[RomScanResult], None] | None = None,
) -> list[RomScanResult]:
    """
    Scan a folder of ROMs against one or more DAT files.

    Args:
        folder:      Path to folder containing ROM files
        dat_paths:   List of DAT file paths to match against
        on_progress: Callback(filename, percent) for progress updates
        on_result:   Callback(RomScanResult) called as each file finishes

    Returns:
        List of RomScanResult, one per ROM file scanned
    """
    if not os.path.isdir(folder):
        raise ValueError(f"Folder not found: {folder}")

    # Load all DAT indexes
    dat_indexes: list[tuple[dict, str, str]] = []  # (index, dat_name, source)
    skipped_dats: list[tuple[str, str]] = []

    for dp in dat_paths:
        try:
            header = _read_dat_header(dp)
            index  = load_dat_index(dp)
            dat_indexes.append((index, header["name"], header["source"]))
        except Exception as e:
            skipped_dats.append((os.path.basename(dp), str(e)))

    for dat_name, reason in skipped_dats:
        if on_progress:
            on_progress(f"[WARN] Skipped unreadable DAT: {dat_name} ({reason})", 0.0)

    # Collect ROM files
    extensions = {
        ".smc", ".sfc", ".nes", ".gba", ".gb", ".gbc",
        ".n64", ".z64", ".v64", ".ndd",
        ".md", ".gen", ".sms", ".gg", ".32x",
        ".pce", ".iso", ".bin", ".img", ".chd",
        ".ws", ".wsc", ".ngp", ".ngc",
        ".lnx", ".vb", ".vec", ".a26", ".a52", ".j64",
    }
    files = [
        f for f in sorted(os.listdir(folder))
        if os.path.splitext(f.lower())[1] in extensions
    ]

    results = []
    for i, fname in enumerate(files):
        fpath = os.path.join(folder, fname)

        result = RomScanResult(filepath=fpath, filename=fname)

        try:
            def _prog(pct: float, _fname=fname):
                if on_progress:
                    on_progress(_fname, pct)

            result.crc32 = calc_crc32(fpath, on_progress=_prog)

            # Search all DATs
            for index, dat_name, dat_source in dat_indexes:
                if result.crc32 in index:
                    entry = index[result.crc32]
                    result.matched        = True
                    result.canonical_name = entry["name"]
                    result.rom_name       = entry["rom_name"]
                    result.dat_source     = dat_source
                    break

        except Exception as e:
            result.error = str(e)

        results.append(result)
        if on_result:
            on_result(result)

    return results


# ── Rename ────────────────────────────────────────────────────────────────────

@dataclass
class RenameResult:
    original_path:  str
    new_path:       str
    success:        bool
    error:          str = ""

def rename_roms(
    results:    list[RomScanResult],
    dry_run:    bool = True,
    on_renamed: Callable[[RenameResult], None] | None = None,
) -> list[RenameResult]:
    """
    Rename ROM files to their canonical names from the DAT.

    Args:
        results: List of RomScanResult from scan_folder()
        dry_run: If True, simulate renames without touching files
        on_renamed: Callback called for each rename attempt

    Returns:
        List of RenameResult
    """
    rename_results = []

    for scan in results:
        if not scan.matched:
            continue
        if scan.filename == scan.suggested_filename:
            continue  # already correctly named

        folder    = os.path.dirname(scan.filepath)
        new_path  = os.path.join(folder, scan.suggested_filename)
        r = RenameResult(original_path=scan.filepath, new_path=new_path, success=False)

        try:
            if not dry_run:
                if os.path.exists(new_path) and new_path != scan.filepath:
                    r.error = f"Target already exists: {scan.suggested_filename}"
                else:
                    os.rename(scan.filepath, new_path)
            r.success = True
        except Exception as e:
            r.error = str(e)

        rename_results.append(r)
        if on_renamed:
            on_renamed(r)

    return rename_results
